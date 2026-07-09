import Foundation

enum AzureConfig {
    // ضع قيمك هنا
    static let endpoint = "https://[YOUR-RESOURCE].cognitiveservices.azure.com"
    static let apiKey   = "[YOUR-FACE-API-KEY]"
    
    // Liveness endpoints
    static let detectURL = "\(endpoint)/face/v1.0/detect"
    
    // Parameters
    static let recognitionModel = "recognition_04"
    static let detectionModel   = "detection_04"
    static let livenessMode     = "passive"   // passive أو active
    static let returnAttributes = "liveness"
    
    // Polling
    static let operationLocationHeader = "Operation-Location"
    static let maxPollAttempts = 20
    static let pollInterval: TimeInterval = 1.5
}
