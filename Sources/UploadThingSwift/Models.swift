import Foundation
import SwiftUI

// MARK: - Regions

/// UploadThing regions
public enum UTRegion: String {
    case usWest2 = "us-west-2"
    case euWest1 = "eu-west-1"
    case apSoutheast1 = "ap-southeast-1"
    
    var alias: String {
        switch self {
        case .usWest2: return "fra1"        // All regions currently use fra1
        case .euWest1: return "fra1"        // Europe (Frankfurt)
        case .apSoutheast1: return "fra1"   // All regions currently use fra1
        }
    }
}

// MARK: - File

/// Represents a file to be uploaded
public struct UTFile {
    public let name: String
    public let data: Data
    public let mimeType: String
    
    public init(name: String, data: Data, mimeType: String? = nil) {
        self.name = name
        self.data = data
        self.mimeType = mimeType ?? UTFile.guessMimeType(from: name)
    }
    
    private static func guessMimeType(from filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "webp": return "image/webp"
        case "pdf": return "application/pdf"
        case "mp4": return "video/mp4"
        case "mp3": return "audio/mp3"
        case "wav": return "audio/wav"
        case "json": return "application/json"
        case "txt": return "text/plain"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Presigned URL

/// Presigned URL for uploading
public struct UTPresignedURL {
    public let url: URL
    public let fileKey: String
    public let publicURL: String
    
    public init(url: URL, fileKey: String, publicURL: String) {
        self.url = url
        self.fileKey = fileKey
        self.publicURL = publicURL
    }
}

// MARK: - Uploaded File

/// Information about an uploaded file
public struct UTUploadedFile: Codable {
    public let key: String
    public let name: String
    public let size: Int
    public let url: String
    public let customId: String?
    public let type: String
    
    public init(key: String, name: String, size: Int, url: String, customId: String?, type: String) {
        self.key = key
        self.name = name
        self.size = size
        self.url = url
        self.customId = customId
        self.type = type
    }
}

// MARK: - Content Disposition

/// Content disposition for uploaded files
public enum UTContentDisposition: String {
    case inline
    case attachment
}

// MARK: - Access Control

/// Access control for uploaded files
public enum UTACL: String {
    case publicRead = "public-read"
    case `private` = "private"
}

// MARK: - Errors

/// UploadThing errors
public enum UTError: Error, LocalizedError {
    case invalidURL
    case invalidAPIKey
    case uploadFailed(String)
    case invalidFileKey
    case signatureGenerationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidAPIKey:
            return "Invalid API key"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .invalidFileKey:
            return "Invalid file key"
        case .signatureGenerationFailed:
            return "Failed to generate signature"
        }
    }
}


