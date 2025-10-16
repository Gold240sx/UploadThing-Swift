import Foundation
import UploadThingSwift

/// Example: Working UploadThingSwift Integration
/// This example shows the exact working implementation used in DevSpace Pro

@available(macOS 13.0, *)
class UploadThingMediaService {
    
    private let uploadThing: UploadThing
    
    init(apiKey: String, appId: String, region: UTRegion = .usWest2) {
        self.uploadThing = UploadThing(
            apiKey: apiKey,
            appId: appId,
            region: region
        )
    }
    
    // MARK: - Working Upload Method
    
    /// Upload a file using the working implementation
    /// This matches the exact method used in DevSpace Pro's MediaUploadService
    func uploadFile(at imageURL: URL, fileName: String) async throws -> UTUploadedFile {
        // Read file data
        let fileData = try Data(contentsOf: imageURL)
        let mimeType = getMimeType(for: imageURL)
        
        print("📤 Uploading '\(fileName)' to UploadThing...")
        print("📊 Size: \(fileData.count) bytes, Type: \(mimeType)")
        print("🔧 USING WORKING UPLOAD METHOD: uploadToUploadThing")
        
        // Create UTFile
        let file = UTFile(
            name: fileName,
            data: fileData,
            mimeType: mimeType
        )
        
        // Upload using UploadThingSwift SDK
        do {
            let uploadedFiles = try await uploadThing.uploadFiles([file])
            
            guard let uploadedFile = uploadedFiles.first else {
                throw UploadError.invalidResponse
            }
            
            print("✅ Upload successful: \(uploadedFile.url)")
            return uploadedFile
        } catch let error as UTError {
            print("❌ UploadThing error: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Working Delete Method
    
    /// Delete a file using the working implementation
    func deleteFile(url: URL) async throws {
        print("🗑️ Deleting file: \(url.absoluteString)")
        
        try await uploadThing.deleteFile(url: url)
        
        print("✅ File deleted successfully")
    }
    
    // MARK: - Helper Methods
    
    private func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "svg":
            return "image/svg+xml"
        case "webp":
            return "image/webp"
        case "pdf":
            return "application/pdf"
        case "mp4":
            return "video/mp4"
        case "mp3":
            return "audio/mp3"
        case "wav":
            return "audio/wav"
        case "json":
            return "application/json"
        case "txt":
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: - Error Types

enum UploadError: Error, LocalizedError {
    case invalidResponse
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}

// MARK: - Usage Examples

@available(macOS 13.0, *)
func exampleUsage() async throws {
    let service = UploadThingMediaService(
        apiKey: "sk_live_your_secret_key",
        appId: "your-uploadthing-app-id"
    )
    
    // Example 1: Upload a single file (working method)
    let fileURL = URL(fileURLWithPath: "/path/to/image.jpg")
    let uploadedFile = try await service.uploadFile(at: fileURL, fileName: "my-image.jpg")
    print("✅ Uploaded to: \(uploadedFile.url)")
    print("📁 File key: \(uploadedFile.key)")
    
    // Example 2: Delete the uploaded file
    let fileURLToDelete = URL(string: uploadedFile.url)!
    try await service.deleteFile(url: fileURLToDelete)
    print("🗑️ File deleted successfully")
}

// MARK: - Complete Working Example

/// This shows the exact working implementation from DevSpace Pro
@available(macOS 13.0, *)
func completeWorkingExample() async throws {
    // Initialize with your credentials
    let service = UploadThingMediaService(
        apiKey: "sk_live_your_secret_key",  // Your UploadThing secret key
        appId: "your-app-id",              // Your UploadThing app ID
        region: .usWest2                    // Optional: .usWest2, .euWest1, .apSoutheast1
    )
    
    // Upload a file
    let imageURL = URL(fileURLWithPath: "/path/to/your/image.png")
    let uploadedFile = try await service.uploadFile(at: imageURL, fileName: "uploaded-image.png")
    
    print("🎉 Upload successful!")
    print("📤 Public URL: \(uploadedFile.url)")
    print("🔑 File Key: \(uploadedFile.key)")
    print("📊 File Size: \(uploadedFile.size) bytes")
    print("📝 File Name: \(uploadedFile.name)")
    
    // Later, delete the file
    let deleteURL = URL(string: uploadedFile.url)!
    try await service.deleteFile(url: deleteURL)
    print("🗑️ File deleted successfully")
}

