# Getting Started with UploadThingSwift

This guide will walk you through integrating UploadThingSwift into your Swift application.

## Step 1: Add to Your Project

### Option A: Local Package (DevSpace Pro)

Since UploadThingSwift is a local package:

1. **Open your Xcode project**
2. **File → Add Package Dependencies...**
3. **Click "Add Local..."**
4. **Navigate to the `UploadThingSwift` folder**
5. **Click "Add Package"**
6. **Select your target and click "Add Package"**

### Option B: Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/UploadThingSwift.git", from: "1.0.0")
]
```

## Step 2: Get Your UploadThing Credentials

1. Go to [UploadThing Dashboard](https://uploadthing.com/dashboard)
2. Create a new app or select an existing one
3. Navigate to **Settings → API Keys**
4. Copy your credentials:
   - **Secret Key** (`sk_live_...`) - Used for server-side uploads
   - **Token** (`eyJhcGlLZXkiOi...`) - Optional, for client-side uploads
   - **App ID** - Your application identifier

> ⚠️ **Important**: Use the **Secret Key** (`sk_live_...`), NOT the token, for server-side uploads!

## Step 3: Basic Usage

### Simple Upload

```swift
import UploadThingSwift

// Initialize client
let uploadThing = UploadThing(
    apiKey: "sk_live_your_secret_key",  // SECRET KEY, not token!
    appId: "your-app-id",
    region: .usWest2  // optional
)

// Prepare file
let fileURL = URL(fileURLWithPath: "/path/to/image.png")
let fileData = try Data(contentsOf: fileURL)
let file = UTFile(
    name: "my-image.png",
    data: fileData,
    mimeType: "image/png"
)

// Upload
let uploadedFiles = try await uploadThing.uploadFiles([file])
print("✅ Uploaded to: \(uploadedFiles[0].url)")
// Output: https://utfs.io/f/abc123-def456.png
```

## Step 4: DevSpace Pro Integration

If you're integrating into DevSpace Pro, store credentials in SwiftData:

```swift
// 1. Define UploadThing config (already in MediaAPIKey.swift)
struct UploadThingConfig: Codable {
    var appId: String?
    var token: String?      // Optional: client token
    var region: String?
}

// 2. Save to SwiftData
let uploadThingKey = MediaAPIKey(
    name: "My UploadThing Account",
    keyValue: "sk_live_your_secret_key",  // SECRET KEY
    service: "UploadThing"
)

let config = UploadThingConfig(
    appId: "your-app-id",
    token: "eyJhcGlLZXkiOi...",  // Optional
    region: "us-west-2"
)

uploadThingKey.setConfig(config)
modelContext.insert(uploadThingKey)
try modelContext.save()
```

### Auto-Strip Credentials

DevSpace Pro automatically cleans pasted credentials:

```swift
// If you paste: UPLOADTHING_SECRET="sk_live_123..."
// It automatically extracts: sk_live_123...

// If you paste: UPLOADTHING_TOKEN='eyJhcGlL...'
// It automatically extracts: eyJhcGlL...
```

## Step 5: MediaUploadService Integration (DevSpace Pro)

The integration is already complete in DevSpace Pro! Here's how it works:

```swift
import UploadThingSwift

private func uploadToUploadThing(
    imageURL: URL,
    fileName: String,
    modelContext: ModelContext,
    apiKeyId: UUID
) async throws -> URL {
    // 1. Fetch API key from SwiftData
    let descriptor = FetchDescriptor<MediaAPIKey>(
        predicate: #Predicate<MediaAPIKey> { $0.id == apiKeyId }
    )
    
    guard let apiKeyRecord = try modelContext.fetch(descriptor).first,
          let config: UploadThingConfig = apiKeyRecord.getConfig() else {
        throw UploadError.providerNotConfigured("UploadThing credentials not found")
    }
    
    let apiKey = apiKeyRecord.keyValue  // Secret key (sk_live_...)
    let appId = config.appId ?? ""
    
    // 2. Determine region
    let region: UTRegion
    if let regionString = config.region?.lowercased() {
        switch regionString {
        case "us-west-2", "us":
            region = .usWest2
        case "eu-west-1", "eu":
            region = .euWest1
        case "ap-southeast-1", "ap", "asia":
            region = .apSoutheast1
        default:
            region = .usWest2
        }
    } else {
        region = .usWest2
    }
    
    // 3. Initialize UploadThing client
    let uploadThing = UploadThing(
        apiKey: apiKey,      // Uses secret key for HMAC signing
        appId: appId,
        region: region
    )
    
    // 4. Read file data
    let fileData = try Data(contentsOf: imageURL)
    let mimeType = getMimeType(for: imageURL)
    
    // 5. Create UTFile
    let file = UTFile(
        name: fileName,
        data: fileData,
        mimeType: mimeType
    )
    
    // 6. Upload (two-step: API → S3)
    let uploadedFiles = try await uploadThing.uploadFiles([file])
    
    guard let publicURL = URL(string: uploadedFiles[0].url) else {
        throw UploadError.invalidResponse
    }
    
    // 7. Update last used timestamp
    apiKeyRecord.updateLastUsed()
    try? modelContext.save()
    
    return publicURL
    // Example: https://utfs.io/f/abc123-def456.png
}
```

### How the Two-Step Upload Works

```
1. Your App calls uploadFiles()
          ↓
2. SDK sends metadata to UploadThing API
   - File name, size, mime type
   - Authenticated with secret key + app ID
          ↓
3. UploadThing responds with presigned S3 URL
   - Temporary credentials
   - Upload fields (Content-Type, Policy, etc.)
          ↓
4. SDK uploads file to AWS S3
   - Using presigned URL
   - No AWS credentials needed
          ↓
5. File available at utfs.io
   - Public CDN URL returned
   - Cached and optimized
```

## Step 6: UI Configuration (DevSpace Pro)

The UI is already implemented in `MediaUploadIntegration.swift`! It includes:

### Features
- ✅ **Add UploadThing Account** - Configure multiple accounts
- ✅ **Edit Credentials** - Update secret key, token, app ID, region
- ✅ **Auto-Clean Input** - Strips `UPLOADTHING_SECRET=`, `UPLOADTHING_TOKEN=`, quotes
- ✅ **Copy Keys** - Quick copy for sharing
- ✅ **Delete Accounts** - Remove unused accounts
- ✅ **Last Used Tracking** - Shows when each account was last used

### How to Use

1. **Navigate to Settings → Integrations → Media Upload**
2. **Scroll to "UploadThing" section**
3. **Click "Add UploadThing Account"**
4. **Paste your credentials** (auto-cleaned):
   - Secret Key (required)
   - Token (optional)
   - App ID (required)
   - Region (optional, defaults to us-west-2)
5. **Click "Save"**
6. **Go to Media Uploader**
7. **Select "UploadThing" provider**
8. **Choose your account from dropdown**
9. **Drop files to upload!**

## Testing Your Integration

### Test Upload

```swift
// Simple test in your app
let testFile = UTFile(
    name: "test.png",
    data: imageData,
    mimeType: "image/png"
)

do {
    let uploaded = try await uploadThing.uploadFiles([testFile])
    print("✅ Success: \(uploaded[0].url)")
    // Output: https://utfs.io/f/abc123-def456.png
} catch {
    print("❌ Error: \(error)")
}
```

### Debug Logging

DevSpace Pro includes extensive debug logging:

```
[UploadThingSwift] 📤 REST API upload: test.png
[UploadThingSwift] 🔑 x-uploadthing-api-key: sk_live_13ebd79...
[UploadThingSwift] 🆔 x-uploadthing-app-id: DevSpace
[UploadThingSwift] 📊 Status: 200
[UploadThingSwift] ✅ API Response received
[UploadThingSwift] 📤 Uploading to S3
[UploadThingSwift] ✅ Upload complete
```

## What's Next?

### Publishing to GitHub

When you're ready to share this with the community:

```bash
cd UploadThingSwift

# Initialize git repository
git init
git add .
git commit -m "Initial release: UploadThingSwift v1.0.0"

# Add remote
git branch -M main
git remote add origin https://github.com/yourusername/UploadThingSwift.git
git push -u origin main

# Create release tag
git tag -a 1.0.0 -m "Release v1.0.0: REST API integration with two-step upload"
git push --tags
```

### Create GitHub Release

1. Go to your repository on GitHub
2. Click "Releases" → "Draft a new release"
3. Select tag `1.0.0`
4. Title: "v1.0.0 - Initial Release"
5. Description:
   ```markdown
   # UploadThingSwift v1.0.0 🚀

   The first Swift SDK for [UploadThing](https://uploadthing.com)!

   ## Features
   - ✅ REST API integration
   - ✅ Two-step upload flow (API → S3)
   - ✅ File key generation with Sqids
   - ✅ HMAC-SHA256 signing with CryptoKit
   - ✅ Comprehensive error handling
   - ✅ Full unit test coverage
   - ✅ Cross-platform support (macOS, iOS, tvOS, watchOS)

   ## Installation
   ```swift
   dependencies: [
       .package(url: "https://github.com/yourusername/UploadThingSwift.git", from: "1.0.0")
   ]
   ```

   ## Quick Start
   [See README.md for full documentation]
   ```
6. Click "Publish release"

### Share with the Community

- 🐦 **Twitter/X**: Tag `@uploadthing` and `#SwiftLang`
- 📱 **Reddit**: Post to r/swift, r/iOSProgramming
- 💬 **Swift Forums**: [forums.swift.org](https://forums.swift.org)
- 💼 **LinkedIn**: Share your achievement
- 📝 **Dev.to/Medium**: Write a technical blog post
- 🎮 **Discord**: Share in Swift/iOS communities

### Future Features

Consider adding these in future versions:

#### v1.1.0 - File Management
- [ ] Delete files from UploadThing
- [ ] List files for a given app
- [ ] Get file metadata
- [ ] Update file ACL/permissions

#### v1.2.0 - Advanced Features
- [ ] Upload progress tracking with Combine/AsyncStream
- [ ] Resumable uploads for large files
- [ ] Batch operations (delete multiple, list with pagination)
- [ ] File webhooks support

#### v1.3.0 - Developer Experience
- [ ] Vapor integration example
- [ ] SwiftUI drop zone component
- [ ] UIKit integration helpers
- [ ] Better error recovery and retry logic

#### v2.0.0 - Major Features
- [ ] Server-side file routes (middleware, callbacks)
- [ ] Image optimization API
- [ ] Video transcoding support
- [ ] File analytics and insights

## Resources

- [UploadThing Documentation](https://docs.uploadthing.com)
- [UploadThing Backend Adapters](https://docs.uploadthing.com/uploading-files)
- [Swift Package Manager](https://swift.org/package-manager/)

## Need Help?

- Check the [README](README.md) for API reference
- See [IntegrationExample.swift](Examples/IntegrationExample.swift) for more examples
- Open an issue if you encounter problems

Happy coding! 🚀

