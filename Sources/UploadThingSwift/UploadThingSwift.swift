import Foundation
import CryptoKit

/// Main UploadThing Swift SDK client
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public actor UploadThing {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let appId: String
    private let region: UTRegion
    
    // MARK: - Initialization
    
    /// Initialize UploadThing client
    /// - Parameters:
    ///   - apiKey: Your UploadThing API key
    ///   - appId: Your UploadThing app ID
    ///   - region: The region for your app (default: .us-west-2)
    public init(apiKey: String, appId: String, region: UTRegion = .usWest2) {
        self.apiKey = apiKey
        self.appId = appId
        self.region = region
    }
    
    // MARK: - Server-Side Upload (REST API)
    
    /// Upload files directly using UploadThing REST API
    /// - Parameters:
    ///   - files: Array of file data to upload
    ///   - customIds: Optional custom IDs for each file
    ///   - contentDisposition: Content disposition (inline or attachment)
    ///   - acl: Access control (public-read or private)
    /// - Returns: Array of uploaded file information
    public func uploadFiles(
        _ files: [UTFile],
        customIds: [String]? = nil,
        contentDisposition: UTContentDisposition = .inline,
        acl: UTACL = .publicRead
    ) async throws -> [UTUploadedFile] {
        var uploadedFiles: [UTUploadedFile] = []
        
        for (index, file) in files.enumerated() {
            let uploadedFile = try await uploadFileViaAPI(
                file,
                customId: customIds?[safe: index],
                contentDisposition: contentDisposition,
                acl: acl
            )
            uploadedFiles.append(uploadedFile)
        }
        
        return uploadedFiles
    }
    
    /// Upload a single file using REST API
    private func uploadFileViaAPI(
        _ file: UTFile,
        customId: String?,
        contentDisposition: UTContentDisposition,
        acl: UTACL
    ) async throws -> UTUploadedFile {
        // Create JSON payload with base64 encoded file
        struct UploadRequest: Codable {
            struct FileToUpload: Codable {
                let name: String
                let type: String
                let size: Int
                let customId: String?
                let data: String  // base64 encoded
            }
            let files: [FileToUpload]
            let acl: String?
            let contentDisposition: String?
        }
        
        let base64File = file.data.base64EncodedString()
        
        let uploadRequest = UploadRequest(
            files: [
                UploadRequest.FileToUpload(
                    name: file.name,
                    type: file.mimeType,
                    size: file.data.count,
                    customId: customId,
                    data: base64File
                )
            ],
            acl: acl.rawValue,
            contentDisposition: contentDisposition.rawValue
        )
        
        let encoder = JSONEncoder()
        let body = try encoder.encode(uploadRequest)
        
        // Create request to UploadThing API
        var request = URLRequest(url: URL(string: "https://api.uploadthing.com/v6/uploadFiles")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-uploadthing-api-key")
        request.setValue(appId, forHTTPHeaderField: "x-uploadthing-app-id")
        request.httpBody = body
        
        print("[UploadThingSwift] 📤 REST API upload: \(file.name)")
        print("[UploadThingSwift] 🔑 x-uploadthing-api-key: \(apiKey.prefix(15))...")
        print("[UploadThingSwift] 🆔 x-uploadthing-app-id: \(appId)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UTError.uploadFailed("Invalid HTTP response")
            }
            
            print("[UploadThingSwift] 📊 Status: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("[UploadThingSwift] ❌ Error: \(errorMessage)")
                throw UTError.uploadFailed("Upload failed (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            print("[UploadThingSwift] ✅ API Response received")
            
            // Parse response - UploadThing returns presigned S3 URLs
            struct UploadResponse: Codable {
                struct FileData: Codable {
                    let url: String  // S3 upload URL
                    let fields: [String: String]  // S3 form fields
                    let key: String
                    let fileUrl: String  // Final public URL
                    let fileName: String
                }
                let data: [FileData]
            }
            
            let decoder = JSONDecoder()
            let uploadResponse = try decoder.decode(UploadResponse.self, from: data)
            
            guard let uploadData = uploadResponse.data.first else {
                throw UTError.uploadFailed("No upload data in response")
            }
            
            print("[UploadThingSwift] 📤 Uploading to S3: \(uploadData.url)")
            
            // Step 2: Upload file to S3 using presigned POST
            try await uploadToS3(
                url: uploadData.url,
                fields: uploadData.fields,
                fileData: file.data,
                fileName: file.name,
                contentType: file.mimeType
            )
            
            print("[UploadThingSwift] ✅ Upload complete: \(uploadData.fileUrl)")
            
            return UTUploadedFile(
                key: uploadData.key,
                name: file.name,
                size: file.data.count,
                url: uploadData.fileUrl,
                customId: customId,
                type: file.mimeType
            )
            
        } catch let error as UTError {
            throw error
        } catch {
            throw UTError.uploadFailed("Network error: \(error.localizedDescription)")
        }
    }
    
    /// Upload file to S3 using presigned POST
    private func uploadToS3(
        url: String,
        fields: [String: String],
        fileData: Data,
        fileName: String,
        contentType: String
    ) async throws {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        // Add all form fields first (required by S3)
        for (key, value) in fields.sorted(by: { $0.key < $1.key }) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add file last
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw UTError.uploadFailed("S3 upload failed")
        }
    }
    
    // MARK: - File Deletion
    
    /// Delete a file from UploadThing
    /// - Parameter fileKey: The file key of the file to delete
    public func deleteFile(fileKey: String) async throws {
        var request = URLRequest(url: URL(string: "https://api.uploadthing.com/v6/deleteFile")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-uploadthing-api-key")
        request.setValue(appId, forHTTPHeaderField: "x-uploadthing-app-id")
        
        // UploadThing API expects fileKeys array, not fileKey
        let body = ["fileKeys": [fileKey]]
        request.httpBody = try JSONEncoder().encode(body)
        
        print("[UploadThingSwift] 🗑️ Deleting file: \(fileKey)")
        print("[UploadThingSwift] 🔑 x-uploadthing-api-key: \(apiKey.prefix(15))...")
        print("[UploadThingSwift] 🆔 x-uploadthing-app-id: \(appId)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UTError.uploadFailed("Invalid HTTP response")
            }
            
            print("[UploadThingSwift] 📊 Delete Status: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("[UploadThingSwift] ❌ Delete Error: \(errorMessage)")
                throw UTError.uploadFailed("Delete failed (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            print("[UploadThingSwift] ✅ File deleted successfully")
            
        } catch let error as UTError {
            throw error
        } catch {
            throw UTError.uploadFailed("Network error: \(error.localizedDescription)")
        }
    }
    
    /// Delete a file by URL (extracts file key from URL)
    /// - Parameter url: The public URL of the file to delete
    public func deleteFile(url: URL) async throws {
        // Extract file key from UploadThing URL
        // URL format: https://utfs.io/f/{fileKey}
        let pathComponents = url.pathComponents
        guard let fileKey = pathComponents.last, !fileKey.isEmpty else {
            throw UTError.invalidFileKey
        }
        
        try await deleteFile(fileKey: fileKey)
    }
    
    // MARK: - Presigned URLs
    
    /// Generate presigned URLs for client-side uploads
    /// - Parameters:
    ///   - files: Array of file metadata
    ///   - customIds: Optional custom IDs
    ///   - contentDisposition: Content disposition
    ///   - acl: Access control
    ///   - expiresIn: URL expiration time in seconds (default: 3600)
    /// - Returns: Array of presigned URLs
    public func generatePresignedURLs(
        for files: [UTFile],
        customIds: [String]? = nil,
        contentDisposition: UTContentDisposition = .inline,
        acl: UTACL = .publicRead,
        expiresIn: TimeInterval = 3600
    ) async throws -> [UTPresignedURL] {
        var presignedURLs: [UTPresignedURL] = []
        
        for (index, file) in files.enumerated() {
            // Generate file key
            let fileSeed = UUID().uuidString + "-" + file.name
            let fileKey = try generateFileKey(fileSeed: fileSeed)
            
            // Generate presigned URL
            let presignedURL = try generatePresignedURL(
                fileKey: fileKey,
                fileName: file.name,
                fileSize: file.data.count,
                fileType: file.mimeType,
                customId: customIds?[safe: index],
                contentDisposition: contentDisposition,
                acl: acl,
                expiresIn: expiresIn
            )
            
            presignedURLs.append(presignedURL)
        }
        
        return presignedURLs
    }
    
    // MARK: - Private Methods
    
    private func generateFileKey(fileSeed: String) throws -> String {
        // Encode app ID using Sqids
        let encodedAppId = try UTFileKey.encodeAppId(appId)
        
        // Encode file seed as base64
        let encodedFileSeed = Data(fileSeed.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        return "\(encodedAppId)\(encodedFileSeed)"
    }
    
    private func generatePresignedURL(
        fileKey: String,
        fileName: String,
        fileSize: Int,
        fileType: String?,
        customId: String?,
        contentDisposition: UTContentDisposition,
        acl: UTACL,
        expiresIn: TimeInterval
    ) throws -> UTPresignedURL {
        let expiresAt = Date().addingTimeInterval(expiresIn)
        let expiresTimestamp = Int64(expiresAt.timeIntervalSince1970 * 1000)
        
        // Build URL with query parameters
        var components = URLComponents(string: "https://\(region.alias).ingest.uploadthing.com/\(fileKey)")!
        
        var queryItems = [
            URLQueryItem(name: "expires", value: String(expiresTimestamp)),
            URLQueryItem(name: "x-ut-identifier", value: appId),
            URLQueryItem(name: "x-ut-file-name", value: fileName),
            URLQueryItem(name: "x-ut-file-size", value: String(fileSize)),
            URLQueryItem(name: "x-ut-content-disposition", value: contentDisposition.rawValue),
            URLQueryItem(name: "x-ut-acl", value: acl.rawValue)
        ]
        
        if let fileType = fileType {
            queryItems.append(URLQueryItem(name: "x-ut-file-type", value: fileType))
        }
        
        if let customId = customId {
            queryItems.append(URLQueryItem(name: "x-ut-custom-id", value: customId))
        }
        
        components.queryItems = queryItems
        
        // Generate signature - sign the full URL with query params but without signature
        guard let urlString = components.url?.absoluteString else {
            throw UTError.invalidURL
        }
        
        let signature = try UTCrypto.generateSignature(for: urlString, apiKey: apiKey)
        components.queryItems?.append(URLQueryItem(name: "signature", value: "hmac-sha256=\(signature)"))
        
        guard let signedURL = components.url else {
            throw UTError.invalidURL
        }
        
        // Construct public URL
        let publicURL = "https://utfs.io/f/\(fileKey)"
        
        return UTPresignedURL(
            url: signedURL,
            fileKey: fileKey,
            publicURL: publicURL
        )
    }
    
    private func uploadFile(_ file: UTFile, to presignedURL: UTPresignedURL) async throws {
        // Create multipart form data as per UploadThing docs
        // https://docs.uploadthing.com/uploading-files
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: presignedURL.url)
        request.httpMethod = "PUT"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        var body = Data()
        
        // Add file data with form field name "file"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(file.name)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(file.data)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UTError.uploadFailed("Invalid HTTP response")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                // Try to get error message from response
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw UTError.uploadFailed("Upload failed with status \(httpResponse.statusCode): \(errorMessage)")
            }
        } catch let error as UTError {
            throw error
        } catch {
            throw UTError.uploadFailed("Network error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

