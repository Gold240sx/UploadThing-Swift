import Foundation
import CryptoKit

/// Cryptographic utilities for UploadThing
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public struct UTCrypto {
    
    /// Generate HMAC SHA256 signature for a URL
    /// - Parameters:
    ///   - urlString: The URL string to sign
    ///   - apiKey: The API key to use for signing
    /// - Returns: The hex-encoded signature
    public static func generateSignature(for urlString: String, apiKey: String) throws -> String {
        guard let urlData = urlString.data(using: .utf8),
              let keyData = apiKey.data(using: .utf8) else {
            throw UTError.signatureGenerationFailed
        }
        
        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: urlData, using: key)
        
        return signature.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Verify a signature
    /// - Parameters:
    ///   - signature: The signature to verify
    ///   - data: The data that was signed
    ///   - apiKey: The API key used for signing
    /// - Returns: True if the signature is valid
    public static func verifySignature(_ signature: String, for data: String, apiKey: String) -> Bool {
        guard let expectedSignature = try? generateSignature(for: data, apiKey: apiKey) else {
            return false
        }
        
        return signature.lowercased() == expectedSignature.lowercased()
    }
}

