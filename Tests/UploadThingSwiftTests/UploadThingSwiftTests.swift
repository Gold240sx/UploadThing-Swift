import XCTest
@testable import UploadThingSwift

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
final class UploadThingSwiftTests: XCTestCase {
    
    // MARK: - File Key Tests
    
    func testFileKeyGeneration() throws {
        let appId = "test-app-id"
        let fileSeed = "test-file-seed"
        
        let fileKey = try UTFileKey.generate(appId: appId, fileSeed: fileSeed)
        
        XCTAssertFalse(fileKey.isEmpty, "File key should not be empty")
        XCTAssertGreaterThanOrEqual(fileKey.count, 12, "File key should be at least 12 characters")
    }
    
    func testAppIdEncoding() throws {
        let appId = "my-test-app"
        let encoded = try UTFileKey.encodeAppId(appId)
        
        XCTAssertFalse(encoded.isEmpty)
        XCTAssertEqual(encoded.count, 12, "Encoded app ID should be exactly 12 characters")
    }
    
    // MARK: - Crypto Tests
    
    func testSignatureGeneration() throws {
        let urlString = "https://example.com/upload?file=test.txt"
        let apiKey = "test-api-key"
        
        let signature = try UTCrypto.generateSignature(for: urlString, apiKey: apiKey)
        
        XCTAssertFalse(signature.isEmpty, "Signature should not be empty")
        XCTAssertEqual(signature.count, 64, "SHA256 signature should be 64 hex characters")
    }
    
    func testSignatureVerification() throws {
        let urlString = "https://example.com/upload?file=test.txt"
        let apiKey = "test-api-key"
        
        let signature = try UTCrypto.generateSignature(for: urlString, apiKey: apiKey)
        
        XCTAssertTrue(
            UTCrypto.verifySignature(signature, for: urlString, apiKey: apiKey),
            "Valid signature should verify successfully"
        )
        
        XCTAssertFalse(
            UTCrypto.verifySignature("invalid-signature", for: urlString, apiKey: apiKey),
            "Invalid signature should fail verification"
        )
    }
    
    // MARK: - Model Tests
    
    func testUTFileCreation() {
        let name = "test.txt"
        let data = Data("Hello, World!".utf8)
        
        let file = UTFile(name: name, data: data)
        
        XCTAssertEqual(file.name, name)
        XCTAssertEqual(file.data, data)
        XCTAssertEqual(file.mimeType, "text/plain")
    }
    
    func testMimeTypeGuessing() {
        let testCases: [(String, String)] = [
            ("image.jpg", "image/jpeg"),
            ("photo.png", "image/png"),
            ("doc.pdf", "application/pdf"),
            ("video.mp4", "video/mp4"),
            ("audio.mp3", "audio/mp3"),
            ("data.json", "application/json"),
            ("unknown.xyz", "application/octet-stream")
        ]
        
        for (filename, expectedMime) in testCases {
            let file = UTFile(name: filename, data: Data())
            XCTAssertEqual(file.mimeType, expectedMime, "Mime type for \(filename) should be \(expectedMime)")
        }
    }
    
    func testUTRegionAlias() {
        XCTAssertEqual(UTRegion.usWest2.alias, "fra1")
        XCTAssertEqual(UTRegion.euWest1.alias, "fra1")
        XCTAssertEqual(UTRegion.apSoutheast1.alias, "fra1")  // All regions currently use fra1
    }
    
    // MARK: - Integration Tests
    
    func testUploadThingInitialization() {
        let uploadThing = UploadThing(
            apiKey: "test-key",
            appId: "test-app",
            region: .usWest2
        )
        
        XCTAssertNotNil(uploadThing)
    }
    
    // Note: Actual upload tests would require valid API credentials
    // and are better suited for integration testing
}

