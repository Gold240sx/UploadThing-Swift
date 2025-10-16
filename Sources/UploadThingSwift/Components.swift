import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Upload Configuration

/// Configuration for upload components
public struct UTUploadConfig {
    public let maxFileSize: Int // in bytes
    public let maxFiles: Int
    public let allowedTypes: [String] // MIME types
    public let allowedExtensions: [String]
    
    public init(
        maxFileSize: Int = 16 * 1024 * 1024, // 16MB default
        maxFiles: Int = 2,
        allowedTypes: [String] = ["image/jpeg", "image/png", "image/gif", "image/webp"],
        allowedExtensions: [String] = ["jpg", "jpeg", "png", "gif", "webp"]
    ) {
        self.maxFileSize = maxFileSize
        self.maxFiles = maxFiles
        self.allowedTypes = allowedTypes
        self.allowedExtensions = allowedExtensions
    }
}

// MARK: - Upload Button Component

/// A salmon-colored button component for file uploads
@available(macOS 13.0, iOS 16.0, tvOS 16.0, visionOS 1.0, *)
public struct UploadButton: View {
    @State private var isHovered = false
    @State private var selectedFiles: [UTFile] = []
    @State private var showingFilePicker = false
    @State private var errorMessage: String?
    
    private let config: UTUploadConfig
    private let onFilesSelected: ([UTFile]) -> Void
    private let onError: (String) -> Void
    
    public init(
        config: UTUploadConfig = UTUploadConfig(),
        onFilesSelected: @escaping ([UTFile]) -> Void,
        onError: @escaping (String) -> Void = { _ in }
    ) {
        self.config = config
        self.onFilesSelected = onFilesSelected
        self.onError = onError
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Container with solid border
            VStack(spacing: 16) {
                // Salmon-colored button
                Button(action: {
                    showingFilePicker = true
                }) {
                    Text("Choose File(s)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "#F67271"))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
                
                // Allowed content text
                Text(allowedContentText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: config.maxFiles > 1
        ) { result in
            handleFileSelection(result)
        }
    }
    
    private var allowedContentText: String {
        let sizeText = formatFileSize(config.maxFileSize)
        let filesText = config.maxFiles == 1 ? "file" : "files"
        let typesText = config.allowedExtensions.joined(separator: ", ").uppercased()
        
        return "\(typesText) up to \(sizeText), max \(config.maxFiles) \(filesText)"
    }
    
    private var allowedContentTypes: [UTType] {
        config.allowedExtensions.compactMap { ext in
            switch ext.lowercased() {
            case "jpg", "jpeg": return .jpeg
            case "png": return .png
            case "gif": return .gif
            case "webp": return UTType(filenameExtension: "webp")
            case "pdf": return .pdf
            case "mp4": return .mpeg4Movie
            case "mp3": return .mp3
            case "wav": return .wav
            default: return UTType(filenameExtension: ext)
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            validateAndProcessFiles(urls)
        case .failure(let error):
            onError("Failed to select files: \(error.localizedDescription)")
        }
    }
    
    private func validateAndProcessFiles(_ urls: [URL]) {
        errorMessage = nil
        
        // Check max files
        if urls.count > config.maxFiles {
            let error = "Too many files selected. Maximum allowed: \(config.maxFiles)"
            errorMessage = error
            onError(error)
            return
        }
        
        var validFiles: [UTFile] = []
        
        for url in urls {
            do {
                let fileData = try Data(contentsOf: url)
                let fileName = url.lastPathComponent
                let fileExtension = url.pathExtension.lowercased()
                
                // Validate file size
                if fileData.count > config.maxFileSize {
                    let error = "File '\(fileName)' is too large. Maximum size: \(formatFileSize(config.maxFileSize))"
                    errorMessage = error
                    onError(error)
                    return
                }
                
                // Validate file extension
                if !config.allowedExtensions.contains(fileExtension) {
                    let error = "File '\(fileName)' has an unsupported format. Allowed: \(config.allowedExtensions.joined(separator: ", "))"
                    errorMessage = error
                    onError(error)
                    return
                }
                
                // Validate MIME type
                let mimeType = UTFile(name: fileName, data: fileData).mimeType
                if !config.allowedTypes.contains(mimeType) {
                    let error = "File '\(fileName)' has an unsupported type. Allowed: \(config.allowedTypes.joined(separator: ", "))"
                    errorMessage = error
                    onError(error)
                    return
                }
                
                let file = UTFile(name: fileName, data: fileData, mimeType: mimeType)
                validFiles.append(file)
                
            } catch {
                let error = "Failed to read file '\(url.lastPathComponent)': \(error.localizedDescription)"
                errorMessage = error
                onError(error)
                return
            }
        }
        
        selectedFiles = validFiles
        onFilesSelected(validFiles)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Upload Dropzone Component

/// A dropzone component with dashed border and upload icon
@available(macOS 13.0, iOS 16.0, tvOS 16.0, visionOS 1.0, *)
public struct UploadDropzone: View {
    @State private var isHovered = false
    @State private var isDragOver = false
    @State private var selectedFiles: [UTFile] = []
    @State private var showingFilePicker = false
    @State private var errorMessage: String?
    
    private let config: UTUploadConfig
    private let onFilesSelected: ([UTFile]) -> Void
    private let onError: (String) -> Void
    
    public init(
        config: UTUploadConfig = UTUploadConfig(),
        onFilesSelected: @escaping ([UTFile]) -> Void,
        onError: @escaping (String) -> Void = { _ in }
    ) {
        self.config = config
        self.onFilesSelected = onFilesSelected
        self.onError = onError
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Dropzone container with dashed border
            VStack(spacing: 20) {
                // Upload icon
                Image(systemName: isDragOver ? "arrow.down.doc.fill" : "square.and.arrow.up.fill")
                    .font(.system(size: 48))
                    .foregroundColor(isDragOver ? .blue : .gray)
                    .modifier(SymbolEffectModifier(isActive: isDragOver))
                
                // Main instruction
                Text(isDragOver ? "Drop files here" : "Drag & Drop Files")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDragOver ? .blue : Color(hex: "#1F2937"))
                
                // Allowed content info
                Text(allowedContentText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Orange upload button
                Button(action: {
                    showingFilePicker = true
                }) {
                    Text("Upload \(selectedFiles.count == 0 ? config.maxFiles : selectedFiles.count) file\(selectedFiles.count == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color(hex: "#F77316"))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
            }
            .padding(24)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isDragOver ? Color.blue : Color.gray.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            )
            .cornerRadius(12)
            .scaleEffect(isDragOver ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isDragOver)
            .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                handleDrop(providers)
            }
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: config.maxFiles > 1
        ) { result in
            handleFileSelection(result)
        }
    }
    
    private var allowedContentText: String {
        let sizeText = formatFileSize(config.maxFileSize)
        let filesText = config.maxFiles == 1 ? "file" : "files"
        let typesText = config.allowedExtensions.joined(separator: ", ").uppercased()
        
        return "\(typesText) up to \(sizeText), max \(config.maxFiles) \(filesText)"
    }
    
    private var allowedContentTypes: [UTType] {
        config.allowedExtensions.compactMap { ext in
            switch ext.lowercased() {
            case "jpg", "jpeg": return .jpeg
            case "png": return .png
            case "gif": return .gif
            case "webp": return UTType(filenameExtension: "webp")
            case "pdf": return .pdf
            case "mp4": return .mpeg4Movie
            case "mp3": return .mp3
            case "wav": return .wav
            default: return UTType(filenameExtension: ext)
            }
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                    defer { group.leave() }
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    } else if let url = item as? URL {
                        urls.append(url)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                validateAndProcessFiles(urls)
            }
        }
        
        return true
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            validateAndProcessFiles(urls)
        case .failure(let error):
            onError("Failed to select files: \(error.localizedDescription)")
        }
    }
    
    private func validateAndProcessFiles(_ urls: [URL]) {
        errorMessage = nil
        
        // Check max files
        if urls.count > config.maxFiles {
            let error = "Too many files selected. Maximum allowed: \(config.maxFiles)"
            errorMessage = error
            onError(error)
            return
        }
        
        var validFiles: [UTFile] = []
        
        for url in urls {
            do {
                let fileData = try Data(contentsOf: url)
                let fileName = url.lastPathComponent
                let fileExtension = url.pathExtension.lowercased()
                
                // Validate file size
                if fileData.count > config.maxFileSize {
                    let error = "File '\(fileName)' is too large. Maximum size: \(formatFileSize(config.maxFileSize))"
                    errorMessage = error
                    onError(error)
                    return
                }
                
                // Validate file extension
                if !config.allowedExtensions.contains(fileExtension) {
                    let error = "File '\(fileName)' has an unsupported format. Allowed: \(config.allowedExtensions.joined(separator: ", "))"
                    errorMessage = error
                    onError(error)
                    return
                }
                
                // Validate MIME type
                let mimeType = UTFile(name: fileName, data: fileData).mimeType
                if !config.allowedTypes.contains(mimeType) {
                    let error = "File '\(fileName)' has an unsupported type. Allowed: \(config.allowedTypes.joined(separator: ", "))"
                    errorMessage = error
                    onError(error)
                    return
                }
                
                let file = UTFile(name: fileName, data: fileData, mimeType: mimeType)
                validFiles.append(file)
                
            } catch {
                let error = "Failed to read file '\(url.lastPathComponent)': \(error.localizedDescription)"
                errorMessage = error
                onError(error)
                return
            }
        }
        
        selectedFiles = validFiles
        onFilesSelected(validFiles)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Symbol Effect Modifier

struct SymbolEffectModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        if #available(macOS 14.0, iOS 17.0, tvOS 17.0, visionOS 1.0, *) {
            content
                .symbolEffect(.bounce, value: isActive)
        } else {
            content
        }
    }
}
