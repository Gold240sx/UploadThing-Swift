import Foundation
import UploadThingSwift

/// Example: Integrating UploadThingSwift with DevSpace Pro

@available(macOS 13.0, *)
class UploadThingMediaService {
    
    private let uploadThing: UploadThing
    
    init(apiKey: String, appId: String) {
        self.uploadThing = UploadThing(
            apiKey: apiKey,
            appId: appId,
            region: .usWest2
        )
    }
    
    // MARK: - Server-Side Upload
    
    /// Upload a file directly from the server
    func uploadFile(at url: URL, customId: String? = nil) async throws -> UTUploadedFile {
        let fileData = try Data(contentsOf: url)
        let fileName = url.lastPathComponent
        
        let file = UTFile(
            name: fileName,
            data: fileData
        )
        
        let uploadedFiles = try await uploadThing.uploadFiles(
            [file],
            customIds: customId.map { [$0] },
            contentDisposition: .inline,
            acl: .publicRead
        )
        
        return uploadedFiles[0]
    }
    
    // MARK: - Batch Upload
    
    /// Upload multiple files at once
    func uploadFiles(_ urls: [URL]) async throws -> [UTUploadedFile] {
        var files: [UTFile] = []
        
        for url in urls {
            let fileData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            
            let file = UTFile(
                name: fileName,
                data: fileData
            )
            files.append(file)
        }
        
        return try await uploadThing.uploadFiles(files)
    }
    
    // MARK: - Client-Side Upload (Presigned URLs)
    
    /// Generate presigned URLs for client uploads
    func generatePresignedURLs(
        for fileMetadata: [(name: String, size: Int, type: String)]
    ) async throws -> [UTPresignedURL] {
        // Create placeholder files with empty data
        // (actual data will be uploaded by the client)
        let files = fileMetadata.map { metadata in
            UTFile(
                name: metadata.name,
                data: Data(count: metadata.size),
                mimeType: metadata.type
            )
        }
        
        return try await uploadThing.generatePresignedURLs(for: files)
    }
}

// MARK: - Usage Examples

@available(macOS 13.0, *)
func exampleUsage() async throws {
    let service = UploadThingMediaService(
        apiKey: "your-uploadthing-api-key",
        appId: "your-uploadthing-app-id"
    )
    
    // Example 1: Upload a single file
    let fileURL = URL(fileURLWithPath: "/path/to/image.jpg")
    let uploadedFile = try await service.uploadFile(at: fileURL, customId: "user-avatar-123")
    print("Uploaded to: \(uploadedFile.url)")
    
    // Example 2: Upload multiple files
    let urls = [
        URL(fileURLWithPath: "/path/to/image1.jpg"),
        URL(fileURLWithPath: "/path/to/image2.jpg"),
        URL(fileURLWithPath: "/path/to/image3.jpg")
    ]
    let uploadedFiles = try await service.uploadFiles(urls)
    print("Uploaded \(uploadedFiles.count) files")
    
    // Example 3: Generate presigned URLs for client upload
    let fileMetadata = [
        (name: "photo.jpg", size: 1024000, type: "image/jpeg"),
        (name: "document.pdf", size: 512000, type: "application/pdf")
    ]
    let presignedURLs = try await service.generatePresignedURLs(for: fileMetadata)
    
    for presignedURL in presignedURLs {
        print("Client upload to: \(presignedURL.url)")
        print("Public URL: \(presignedURL.publicURL)")
    }
}

// MARK: - Integration with MediaUploadService

/// Example: How to integrate with your existing MediaUploadService.swift

extension UploadThingMediaService {
    
    /// Upload with SwiftData tracking (similar to your current MediaUploadService)
    func uploadWithTracking(
        imageURL: URL,
        itemName: String,
        modelContext: Any // Replace with actual ModelContext type
    ) async throws -> (url: String, fileKey: String) {
        let uploadedFile = try await uploadFile(at: imageURL, customId: itemName)
        
        // Create MediaItem in SwiftData (similar to your current implementation)
        // let mediaItem = MediaItem(...)
        // modelContext.insert(mediaItem)
        // try modelContext.save()
        
        return (url: uploadedFile.url, fileKey: uploadedFile.key)
    }
}

