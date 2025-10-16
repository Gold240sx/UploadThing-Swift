# UploadThingSwift

A Swift SDK for [UploadThing](https://uploadthing.com) - the easiest way to add file uploads to your Swift applications.

## Features

- ✅ **SwiftUI Components** - Built-in UploadButton and UploadDropzone components
- ✅ **REST API Integration** - Direct uploads via UploadThing REST API
- ✅ **Two-Step Upload Flow** - Secure uploads via presigned S3 URLs
- ✅ **File Deletion** - Delete uploaded files via API
- ✅ **File Key Generation** - Built-in Sqids-based key generation
- ✅ **HMAC Signing** - Cryptographic signing with CryptoKit
- ✅ **Type-safe** - Full Swift type safety with comprehensive error handling
- ✅ **Async/Await** - Modern Swift concurrency support
- ✅ **Cross-platform** - Works on macOS 13.0+, iOS 16.0+ (includes iPadOS), tvOS 16.0+, visionOS 1.0+

## 1 - Installation

## Swift Package Manager
### 1A - Add it directly in Xcode

1. File → Add Package Dependencies
2. Enter the repository URL: 

    ```swift
    "https://github.com/yourusername/UploadThingSwift.git"
    ```

4. Select version and add to your target

### 1B - Or add it to your Package.swift

Add UploadThingSwift to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/UploadThingSwift.git", from: "1.0.0")
]
```

### 2 - Get Your Credentials

From [UploadThing Dashboard](https://uploadthing.com/dashboard)

- **Secret Key** (`sk_live_...`) - Your API key
- **App ID** - Your application identifier

### 3 - Initialize the Client

```swift
import UploadThingSwift

let uploadThing = UploadThing(
    apiKey: "sk_live_your_secret_key",
    appId: "your-app-id",
    region: .euWest1  // optional, defaults to .euWest1 (Frankfurt)
)
```
Now you have a choice between using the built in SwiftUI components (for easy integration #A) or incorporating the functionality into your own custom implementation (#B).

## 4A - Quick Start

### 5A - Built-in UI Components (Recommended for getting started)

The easiest way to get started is with the built-in SwiftUI components:

```swift
import SwiftUI
import UploadThingSwift

struct ContentView: View {
    var body: some View {
        VStack {
            // Upload Button
            UploadButton(
                config: UTUploadConfig(
                    maxFileSize: 16 * 1024 * 1024, // 16MB
                    maxFiles: 2,
                    allowedTypes: ["image/jpeg", "image/png", "image/gif"],
                    allowedExtensions: ["jpg", "jpeg", "png", "gif"]
                ),
                onFilesSelected: { files in
                    print("Selected \(files.count) files")
                    // Handle selected files
                },
                onError: { error in
                    print("Error: \(error)")
                }
            )
            
            // Upload Dropzone
            UploadDropzone(
                config: UTUploadConfig(),
                onFilesSelected: { files in
                    print("Dropped \(files.count) files")
                    // Handle dropped files
                },
                onError: { error in
                    print("Error: \(error)")
                }
            )
        }
    }
}
```

## 5B - Custom Implementation (Programmatic)

For more control over the upload process, use the programmatic API:

### 6B - Upload Files

```swift
// Prepare your file
let fileData = try Data(contentsOf: fileURL)
let file = UTFile(
    name: "my-image.png",
    data: fileData,
    mimeType: "image/png"
)

// Upload (automatic two-step process: API → S3)
let uploadedFiles = try await uploadThing.uploadFiles([file])

// Access your file
print("Uploaded to: \(uploadedFiles[0].url)")
// Example: https://utfs.io/f/abc123-def456.png
```

### 7B - Delete Files

```swift
// Delete by file key
try await uploadThing.deleteFile(fileKey: "abc123-def456")

// Delete by URL (extracts file key automatically)
let fileURL = URL(string: "https://utfs.io/f/abc123-def456")!
try await uploadThing.deleteFile(url: fileURL)
```

## How It Works

UploadThingSwift uses a **two-step upload flow** for maximum security and reliability:

1. **Request Permission**: SDK sends file metadata to UploadThing API
   - API validates your credentials
   - Returns presigned S3 URL with temporary access

2. **Upload to S3**: SDK uploads file to AWS S3
   - Uses presigned URL (no AWS credentials needed)
   - File is stored securely and made available via CDN

```
Your App → UploadThing API → Get Presigned URL
         ↓
Your App → AWS S3 → Upload File
         ↓
      Success! File available at utfs.io
```

## Advanced Configuration

### Regions

Choose the region closest to your users. Currently, all regions route through Frankfurt (fra1):

```swift
.euWest1        // Europe (Frankfurt) - Default
.usWest2        // US West
.apSoutheast1   // Asia Pacific
```

> **Note**: UploadThing currently uses a single ingestion endpoint (`fra1.ingest.uploadthing.com`) regardless of region setting. Region-specific endpoints may be added in the future.

### Content Disposition

Control how browsers handle the file:

```swift
.inline      // Display in browser (default)
.attachment  // Force download
```

### Access Control

Set file visibility:

```swift
.publicRead  // Anyone can access (default)
.private     // Only authenticated users can access
```

## API Reference

### `UploadThing`

Main client for interacting with UploadThing.

#### Methods

**`uploadFiles(_:customIds:contentDisposition:acl:) async throws -> [UTUploadedFile]`**

Uploads files using the REST API with automatic S3 upload.

Parameters

- `files`: Array of `UTFile` objects to upload
- `customIds`: Optional custom identifiers for each file
- `contentDisposition`: How browsers should handle the file (`.inline` or `.attachment`)
- `acl`: Access control (`.publicRead` or `.private`)

Returns: Array of `UTUploadedFile` with public URLs

**`deleteFile(fileKey:) async throws`**

Deletes a file by its file key.

Parameters

- `fileKey`: The unique file key of the file to delete

**`deleteFile(url:) async throws`**

Deletes a file by its public URL (automatically extracts file key).

Parameters

- `url`: The public URL of the file to delete

**`generatePresignedURLs(for:customIds:contentDisposition:acl:expiresIn:) async throws -> [UTPresignedURL]`**

Generates presigned URLs for client-side uploads (advanced use cases).

> **Note**: For most server-side Swift applications, use `uploadFiles()` instead.

### `UTFile`

Represents a file to upload.

```swift
UTFile(name: String, data: Data, mimeType: String?)
```

### `UTUploadedFile`

Information about an uploaded file.

```swift
struct UTUploadedFile {
    let key: String
    let name: String
    let size: Int
    let url: String
    let customId: String?
    let type: String
}
```

### `UTPresignedURL`

Presigned URL for client uploads.

```swift
struct UTPresignedURL {
    let url: URL           // Presigned URL for upload
    let fileKey: String    // Unique file identifier
    let publicURL: String  // Public URL after upload
}
```

## Error Handling

UploadThingSwift provides detailed error information:

```swift
do {
    let uploadedFiles = try await uploadThing.uploadFiles([file])
    print("Success! \(uploadedFiles.count) files uploaded")
} catch let error as UTError {
    switch error {
    case .invalidURL:
        print("❌ Invalid URL configuration")
    case .invalidAPIKey:
        print("❌ Invalid API key")
    case .uploadFailed(let message):
        print("❌ Upload failed: \(message)")
        // Example: "Upload failed (401): Invalid API key"
        // Example: "S3 upload failed"
    case .invalidFileKey:
        print("❌ Invalid file key generated")
    case .signatureGenerationFailed:
        print("❌ Could not generate HMAC signature")
    }
} catch {
    print("❌ Unexpected error: \(error.localizedDescription)")
}
```

### Common Error Scenarios

| Error | Cause | Solution |
|-------|-------|----------|
| `Invalid API key` | Wrong secret key | Check your `sk_live_...` key in dashboard |
| `Upload failed (400)` | Invalid request format | Ensure file data is valid |
| `Upload failed (401)` | Authentication failed | Verify API key and App ID |
| `S3 upload failed` | S3 upload rejected | Check file size limits |

## Examples

### Upload Multiple Files

```swift
let files = [
    UTFile(name: "doc1.pdf", data: pdf1Data, mimeType: "application/pdf"),
    UTFile(name: "doc2.pdf", data: pdf2Data, mimeType: "application/pdf"),
    UTFile(name: "image.png", data: imageData, mimeType: "image/png")
]

let uploadedFiles = try await uploadThing.uploadFiles(files)

for file in uploadedFiles {
    print("✅ \(file.name) uploaded to: \(file.url)")
}
```

### Upload with Custom IDs

Track uploads with your own identifiers:

```swift
let avatarFile = UTFile(
    name: "avatar.jpg", 
    data: imageData, 
    mimeType: "image/jpeg"
)

let uploadedFiles = try await uploadThing.uploadFiles(
    [avatarFile],
    customIds: ["user-123-avatar"]
)

// Access via custom ID
print("User avatar URL: \(uploadedFiles[0].url)")
print("Custom ID: \(uploadedFiles[0].customId ?? "none")")
```

### Upload and Delete Files

```swift
// Upload a file
let file = UTFile(name: "document.pdf", data: pdfData, mimeType: "application/pdf")
let uploadedFiles = try await uploadThing.uploadFiles([file])
let fileURL = uploadedFiles[0].url

print("File uploaded: \(fileURL)")

// Later, delete the file
try await uploadThing.deleteFile(url: URL(string: fileURL)!)
print("File deleted successfully")
```

### Upload Images from macOS/iOS

```swift
#if os(macOS)
import AppKit

func uploadImage(_ image: NSImage) async throws -> String {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ImageError", code: -1)
    }
    
    let file = UTFile(name: "image.png", data: pngData, mimeType: "image/png")
    let uploaded = try await uploadThing.uploadFiles([file])
    return uploaded[0].url
}
#else
import UIKit

func uploadImage(_ image: UIImage) async throws -> String {
    guard let imageData = image.pngData() else {
        throw NSError(domain: "ImageError", code: -1)
    }
    
    let file = UTFile(name: "image.png", data: imageData, mimeType: "image/png")
    let uploaded = try await uploadThing.uploadFiles([file])
    return uploaded[0].url
}
#endif
```

### SwiftUI Integration

```swift
import SwiftUI
import UploadThingSwift

struct FileUploadView: View {
    @State private var uploadStatus = "Ready"
    @State private var uploadedURL: String?
    
    let uploadThing = UploadThing(
        apiKey: "sk_live_...",
        appId: "your-app-id"
    )
    
    var body: some View {
        VStack {
            Text(uploadStatus)
            
            if let url = uploadedURL {
                Link("View File", destination: URL(string: url)!)
            }
            
            Button("Upload File") {
                Task {
                    await uploadFile()
                }
            }
        }
    }
    
    func uploadFile() async {
        uploadStatus = "Uploading..."
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let file = UTFile(name: "test.png", data: fileData, mimeType: "image/png")
            
            let uploaded = try await uploadThing.uploadFiles([file])
            uploadedURL = uploaded[0].url
            uploadStatus = "✅ Upload complete!"
        } catch {
            uploadStatus = "❌ Upload failed: \(error.localizedDescription)"
        }
    }
}
```

## Testing

The package includes comprehensive unit tests:

```bash
cd UploadThingSwift
swift test
```

Tests cover

- ✅ File key generation (Sqids)
- ✅ HMAC signature generation
- ✅ Client initialization
- ✅ URL construction
- ✅ Error handling

## Troubleshooting

### "Invalid API key" Error

```swift
// ❌ Wrong - using token instead of secret key
let uploadThing = UploadThing(
    apiKey: "eyJhcGlLZXkiOi...",  // This is a TOKEN
    appId: "MyApp"
)

// ✅ Correct - using secret key
let uploadThing = UploadThing(
    apiKey: "sk_live_13ebd79...",  // This is the SECRET KEY
    appId: "MyApp"
)
```

### Files Not Uploading

1. **Check credentials**: Verify your `sk_live_...` key and App ID
2. **Check file size**: UploadThing has file size limits per plan
3. **Check mime type**: Ensure you're providing the correct mime type
4. **Enable debug logging**: Add print statements to see detailed flow

```swift
do {
    print("📤 Starting upload...")
    let result = try await uploadThing.uploadFiles([file])
    print("✅ Success: \(result[0].url)")
} catch {
    print("❌ Error: \(error)")
}
```

### Network Issues

If you see "server with the specified hostname could not be found":

1. Check your internet connection
2. Verify DNS resolution: `nslookup fra1.ingest.uploadthing.com`
3. Check firewall/proxy settings
4. UploadThing API may be experiencing downtime (check status page)

## Requirements

- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+
- Swift 5.9+
- Xcode 15.0+ (for development)

## Performance

- **Upload Speed**: Limited by your network and UploadThing's infrastructure
- **File Key Generation**: ~0.001ms per file (Sqids algorithm)
- **HMAC Signing**: ~0.005ms per signature (CryptoKit)
- **Memory**: Minimal overhead, files are streamed

## Security

- ✅ **No AWS credentials exposed**: Uses presigned URLs
- ✅ **HMAC-SHA256 signing**: Cryptographic request signing
- ✅ **TLS/SSL**: All requests use HTTPS
- ✅ **Server-side validation**: UploadThing validates all uploads

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

```bash
git clone https://github.com/yourusername/UploadThingSwift.git
cd UploadThingSwift
swift build
swift test
```

## Changelog

### 1.2.3 (2025-01-16)

- ✅ **visionOS Support** - Added visionOS 1.0+ support for SwiftUI components
- ✅ **Platform Coverage** - Full support for macOS, iOS (includes iPadOS), tvOS, visionOS
- ✅ **Availability Updates** - Updated @available annotations for complete platform support

### 1.2.2 (2025-01-16)

- ✅ **Platform Coverage** - Full support for macOS, iOS (includes iPadOS), tvOS, watchOS
- ✅ **Availability Updates** - Updated @available annotations for complete platform support
- ✅ **Documentation** - Clarified that iOS includes iPadOS support

### 1.2.1 (2025-01-16)

- ✅ **SwiftUI Components** - Added UploadButton and UploadDropzone components
- ✅ **UTUploadConfig** - Configuration struct for SwiftUI components
- ✅ **Drag & Drop Support** - UploadDropzone supports drag and drop files
- ✅ **File Validation** - Built-in file type and size validation
- ✅ **Cross-platform UI** - Components work on macOS, iOS, tvOS, watchOS

### 1.1.0 (2025-10-16)

- ✅ **File Deletion** - Delete uploaded files via API
- ✅ **URL-based deletion** - Delete files by public URL
- ✅ **File key deletion** - Delete files by file key
- ✅ **Improved error handling** - Better deletion error messages

### 1.0.0 (2025-10-13)

- ✅ Initial release
- ✅ REST API integration
- ✅ Two-step upload flow (API → S3)
- ✅ File key generation with Sqids
- ✅ HMAC-SHA256 signing
- ✅ Comprehensive error handling
- ✅ Full unit test coverage

## License

MIT License - see LICENSE file for details

## Resources

- [UploadThing Documentation](https://docs.uploadthing.com)
- [UploadThing Dashboard](https://uploadthing.com/dashboard)
- [API Reference](https://docs.uploadthing.com/api-reference)
- [Swift Package Manager](https://swift.org/package-manager/)

## Support

For issues specific to this SDK

- 📧 Open an issue on GitHub
- 💬 Include debug logs and error messages
- 🐛 Provide minimal reproduction code

For UploadThing platform issues

- 📖 [UploadThing Documentation](https://docs.uploadthing.com)
- 💬 [UploadThing Discord](https://discord.gg/uploadthing)
- 🎫 [Support Tickets](https://uploadthing.com/support)

---

Made with ❤️ for the Swift community
