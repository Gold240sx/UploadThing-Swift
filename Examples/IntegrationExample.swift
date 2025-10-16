import Foundation
import SwiftUI
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

// MARK: - SwiftUI Components Example

/// Example SwiftUI view showing how to use UploadButton and UploadDropzone
@available(macOS 13.0, *)
struct UploadComponentsExample: View {
    @State private var uploadedFiles: [UTUploadedFile] = []
    @State private var errorMessage: String?
    @State private var isUploading = false
    
    private let uploadThing = UploadThing(
        apiKey: "sk_live_your_secret_key",
        appId: "your-uploadthing-app-id"
    )
    
    var body: some View {
        VStack(spacing: 30) {
            Text("UploadThingSwift Components")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // UploadButton Example
            VStack(alignment: .leading, spacing: 12) {
                Text("UploadButton Component")
                    .font(.headline)
                
                UploadButton(
                    config: UTUploadConfig(
                        maxFileSize: 16 * 1024 * 1024, // 16MB
                        maxFiles: 2,
                        allowedTypes: ["image/jpeg", "image/png", "image/gif"],
                        allowedExtensions: ["jpg", "jpeg", "png", "gif"]
                    ),
                    onFilesSelected: { files in
                        uploadFiles(files)
                    },
                    onError: { error in
                        errorMessage = error
                    }
                )
            }
            
            // UploadDropzone Example
            VStack(alignment: .leading, spacing: 12) {
                Text("UploadDropzone Component")
                    .font(.headline)
                
                UploadDropzone(
                    config: UTUploadConfig(
                        maxFileSize: 32 * 1024 * 1024, // 32MB
                        maxFiles: 5,
                        allowedTypes: ["image/jpeg", "image/png", "image/gif", "image/webp"],
                        allowedExtensions: ["jpg", "jpeg", "png", "gif", "webp"]
                    ),
                    onFilesSelected: { files in
                        uploadFiles(files)
                    },
                    onError: { error in
                        errorMessage = error
                    }
                )
            }
            
            // Upload Status
            if isUploading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Uploading files...")
                        .font(.caption)
                }
            }
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Uploaded Files List
            if !uploadedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Uploaded Files:")
                        .font(.headline)
                    
                    ForEach(uploadedFiles, id: \.key) { file in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(file.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(file.url)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Delete") {
                                deleteFile(file)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func uploadFiles(_ files: [UTFile]) {
        Task {
            await MainActor.run {
                isUploading = true
                errorMessage = nil
            }
            
            do {
                let uploadedFiles = try await uploadThing.uploadFiles(files)
                
                await MainActor.run {
                    self.uploadedFiles.append(contentsOf: uploadedFiles)
                    isUploading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Upload failed: \(error.localizedDescription)"
                    isUploading = false
                }
            }
        }
    }
    
    private func deleteFile(_ file: UTUploadedFile) {
        Task {
            do {
                try await uploadThing.deleteFile(fileKey: file.key)
                
                await MainActor.run {
                    uploadedFiles.removeAll { $0.key == file.key }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Delete failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Usage Examples for Components

/// Example showing how to use UploadButton in your SwiftUI app
@available(macOS 13.0, *)
func uploadButtonExample() {
    // Basic usage
    UploadButton(
        onFilesSelected: { files in
            print("Selected \(files.count) files")
            // Handle selected files
        },
        onError: { error in
            print("Error: \(error)")
        }
    )
    
    // Custom configuration
    UploadButton(
        config: UTUploadConfig(
            maxFileSize: 10 * 1024 * 1024, // 10MB
            maxFiles: 1,
            allowedTypes: ["image/jpeg", "image/png"],
            allowedExtensions: ["jpg", "jpeg", "png"]
        ),
        onFilesSelected: { files in
            print("Selected files: \(files.map { $0.name })")
        },
        onError: { error in
            print("Upload error: \(error)")
        }
    )
}

/// Example showing how to use UploadDropzone in your SwiftUI app
@available(macOS 13.0, *)
func uploadDropzoneExample() {
    // Basic usage
    UploadDropzone(
        onFilesSelected: { files in
            print("Dropped \(files.count) files")
            // Handle dropped files
        },
        onError: { error in
            print("Error: \(error)")
        }
    )
    
    // Custom configuration for documents
    UploadDropzone(
        config: UTUploadConfig(
            maxFileSize: 50 * 1024 * 1024, // 50MB
            maxFiles: 10,
            allowedTypes: ["application/pdf", "text/plain", "application/msword"],
            allowedExtensions: ["pdf", "txt", "doc", "docx"]
        ),
        onFilesSelected: { files in
            print("Selected documents: \(files.map { $0.name })")
        },
        onError: { error in
            print("Upload error: \(error)")
        }
    )
}

