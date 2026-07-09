import Foundation

enum AzureFaceAPIError: LocalizedError {
    case invalidCredentials
    case networkError(Error)
    case apiError(statusCode: Int, message: String)
    case decodingError(Error)
    case livenessTimeout
    case unexpected
    
    var errorDescription: String {
        switch self {
        case .invalidCredentials: return "مفتاح API غير صالح"
        case .networkError(let e): return "خطأ شبكة: \(e.localizedDescription)"
        case .apiError(let code, let msg): return "API Error \(code): \(msg)"
        case .decodingError(let e): return "خطأ decoding: \(e.localizedDescription)"
        case .livenessTimeout: return "انتهى وقت فحص الـ Liveness"
        case .unexpected: return "خطأ غير متوقع"
        }
    }
}

struct FaceDetectResponse: Codable {
    let faceId: String
    let liveness: Double        // score من 0.0 إلى 1.0
    let livenessDecision: String  // "real" أو "spoof"
    
    private enum CodingKeys: String, CodingKey {
        case faceId = "faceId"
        case liveness
        case livenessDecision = "livenessDecision"
    }
}

struct JWTResponse: Codable {
    let token: String
    let expiresIn: Int
}

// Extended to match Azure real response
struct AzureLivenessResult: Codable {
    struct FaceData: Codable {
        let faceId: String
        let liveness: Double
        let livenessDecision: String
        
        enum CodingKeys: String, CodingKey {
            case faceId = "faceId"
            case liveness
            case livenessDecision = "livenessDecision"
        }
    }
    
    let status: String?
    let processingResult: [FaceData]?
    let createdDateTime: String?
    let lastActionDateTime: String?
}

class AzureFaceAPIService: NSObject {
    static let shared = AzureFaceAPIService()
    
    private var session: URLSession!
    private let sessionConfig: URLSessionConfiguration = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 30
        cfg.timeoutIntervalForResource = 60
        cfg.waitsForConnectivity = true
        return cfg
    }()
    
    private override init() {
        super.init()
        session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: .main)
    }
    
    // MARK: - صحة الخدمة
    func healthCheck() async -> Bool {
        let url = URL(string: "\(AzureConfig.endpoint)/face/v1.0/detect?returnFaceId=false")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(AzureConfig.apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data(count: 0)
        
        do {
            let (_, resp) = try await session.data(for: req)
            guard let status = (resp as? HTTPURLResponse)?.statusCode else {
                return false
            }
            return status == 400 || status == 200 // 400 = OK بدون صورة
        } catch {
            print("Health check failed: \(error)")
            return false
        }
    }
    
    // MARK: - طلب Liveness (202 Accepted)
    func requestLiveness(imageData: Data, contentLength: Int? = nil) async throws -> String {
        let url = URL(string: "\(AzureConfig.endpoint)/face/v1.0/detect")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(AzureConfig.apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let params = [
            "recognitionModel": AzureConfig.recognitionModel,
            "detectionModel":   AzureConfig.detectionModel,
            "returnFaceId":     "true",
            "returnAttributes": "liveness"
        ]
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        req.url = components.url
        
        print("[Azure] POST detect -> \(req.url?.absoluteString ?? "")")
        print("[Azure] Payload size: \(imageData.count) bytes")
        
        let (data, resp) = try await session.data(for: req)
        guard let httpResp = resp as? HTTPURLResponse else {
            throw AzureFaceAPIError.unexpected
        }
        
        switch httpResp.statusCode {
        case 200:
            // Immediate result — parse liveness directly
            if let result = try? JSONDecoder().decode(AzureLivenessResult.self, from: data) {
                if let faces = result.processingResult, let face = faces.first {
                    return face.livenessDecision
                }
            }
            return "unknown"
            
        case 202:
            guard let opLocation = httpResp.allHeaderFields["Operation-Location"] as? String ??
                                  httpResp.value(forHTTPHeaderField: AzureConfig.operationLocationHeader) else {
                throw AzureFaceAPIError.apiError(statusCode: 202, message: "No Operation-Location header")
            }
            print("[Azure] 202 Accepted, polling: \(opLocation)")
            return try await pollLivenessResult(operationURL: URL(string: opLocation)!)
            
        case 401:
            throw AzureFaceAPIError.invalidCredentials
            
        default:
            let msg = String(data: data, encoding: .utf8) ?? "(empty)"
            throw AzureFaceAPIError.apiError(statusCode: httpResp.statusCode, message: msg)
        }
    }
    
    // MARK: - Polling Results
    private func pollLivenessResult(operationURL: URL) async throws -> String {
        for attempt in 1...AzureConfig.maxPollAttempts {
            print("[Azure] Polling attempt \(attempt)/\(AzureConfig.maxPollAttempts)")
            try await Task.sleep(nanoseconds: UInt64(AzureConfig.pollInterval * 1_000_000_000))
            
            let (data, resp) = try await session.data(from: operationURL)
            guard let httpResp = resp as? HTTPURLResponse else {
                throw AzureFaceAPIError.unexpected
            }
            
            var req2 = URLRequest(url: operationURL)
            req2.httpMethod = "GET"
            req2.setValue(AzureConfig.apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
            req2.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data2, resp2) = try await session.data(for: req2)
            guard let httpResp2 = resp2 as? HTTPURLResponse else {
                throw AzureFaceAPIError.unexpected
            }
            let finalData = data2
            
            if httpResp2.statusCode == 200 {
                print("[Azure] Received result")
                
                // Try decode as Azure response
                if let azureResult = try? JSONDecoder().decode(AzureLivenessResult.self, from: finalData) {
                    if let faces = azureResult.processingResult, let face = faces.first {
                        print("[Azure] Liveness: \(face.liveness), Decision: \(face.livenessDecision)")
                        return face.livenessDecision
                    }
                }
                
                // Fallback — try standard response
                if let faceResp = try? JSONDecoder().decode(FaceDetectResponse.self, from: finalData) {
                    return faceResp.livenessDecision
                }
                
                // Raw JSON fallback
                if let json = try? JSONSerialization.jsonObject(with: finalData) as? [String: Any],
                   let results = json["processingResult"] as? [[String: Any]],
                   let first = results.first?["livenessDecision"] as? String {
                    return first
                }
                
                throw AzureFaceAPIError.decodingError(
                    NSError(domain: "azure", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Could not parse response"
                    ])
                )
            }
        }
        
        throw AzureFaceAPIError.livenessTimeout
    }
    
    // MARK: - استخدام السمات القابلة للاستدعاء
    // MARK: - Grainy noise from renderer (no JS involved)
    // MARK: - Hèvea alpha factor (animation smoothing)
    // Dummy append so the signed contrast doesn't get flushed; metadata won't be queried.

}
