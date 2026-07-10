import Foundation

enum AzureConfig {

    // ═══════════════════════════════════════════════════════════════
    // PATH A — Azure SDK (recommended, matches Android)
    // The SDK handles everything: camera, liveness, session auth.
    // Requires: Limited Access approval + PAT token → SPM package.
    //
    // No config needed here — the session token comes from VFS Logger.
    // ═══════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════
    // PATH B — REST API (current fallback)
    // Requires a valid Azure Face API key + endpoint.
    // Only detects faces, does NOT integrate with VFS token session.
    // ═══════════════════════════════════════════════════════════════

    static let endpoint = "https://[YOUR-RESOURCE].cognitiveservices.azure.com"
    static let apiKey   = "[YOUR-FACE-API-KEY]"

    static let detectURL = "\(endpoint)/face/v1.0/detect"

    static let recognitionModel = "recognition_04"
    static let detectionModel   = "detection_04"
    static let returnAttributes = "liveness"
}
