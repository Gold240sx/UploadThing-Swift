import Foundation

/// File key generation utilities
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public struct UTFileKey {
    
    private static let defaultAlphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    private static let minLength = 12
    
    /// Generate a file key from app ID and file seed
    /// - Parameters:
    ///   - appId: The UploadThing app ID
    ///   - fileSeed: A unique seed for the file
    /// - Returns: The generated file key
    public static func generate(appId: String, fileSeed: String) throws -> String {
        // Encode app ID
        let encodedAppId = try encodeAppId(appId)
        
        // Encode file seed as URL-safe base64
        let encodedFileSeed = Data(fileSeed.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        return "\(encodedAppId)\(encodedFileSeed)"
    }
    
    /// Encode app ID using Sqids algorithm
    /// - Parameter appId: The app ID to encode
    /// - Returns: The encoded app ID
    static func encodeAppId(_ appId: String) throws -> String {
        // Shuffle alphabet based on app ID
        let shuffledAlphabet = shuffle(defaultAlphabet, seed: appId)
        
        // Hash the app ID
        let hash = djb2(appId)
        let absHash = abs(hash)
        
        // Encode the hash using Sqids
        return encodeSqids([UInt64(absHash)], alphabet: shuffledAlphabet, minLength: minLength)
    }
    
    // MARK: - DJB2 Hash
    
    /// DJB2 hash function
    /// - Parameter string: The string to hash
    /// - Returns: The hash value
    private static func djb2(_ string: String) -> Int {
        var hash: UInt32 = 5381
        
        for char in string.utf8 {
            hash = ((hash << 5) &+ hash) ^ UInt32(char)
        }
        
        return Int(Int32(bitPattern: hash))
    }
    
    // MARK: - Alphabet Shuffling
    
    /// Shuffle alphabet based on seed
    /// - Parameters:
    ///   - alphabet: The alphabet to shuffle
    ///   - seed: The seed string
    /// - Returns: Shuffled alphabet
    private static func shuffle(_ alphabet: String, seed: String) -> String {
        var chars = Array(alphabet)
        let seedNum = djb2(seed)
        
        for i in 0..<chars.count {
            let j = ((seedNum % (i + 1)) + i) % chars.count
            chars.swapAt(i, j)
        }
        
        return String(chars)
    }
    
    // MARK: - Sqids Encoding
    
    /// Simplified Sqids encoding (minimal implementation for UploadThing)
    /// - Parameters:
    ///   - numbers: Array of numbers to encode
    ///   - alphabet: Custom alphabet
    ///   - minLength: Minimum length of output
    /// - Returns: Encoded string
    private static func encodeSqids(_ numbers: [UInt64], alphabet: String, minLength: Int) -> String {
        let alphabetChars = Array(alphabet)
        let alphabetLength = UInt64(alphabetChars.count)
        
        guard !numbers.isEmpty, alphabetLength >= 2 else {
            return ""
        }
        
        // Simple encoding: convert number to base-N using custom alphabet
        var result = ""
        var num = numbers[0]
        
        if num == 0 {
            result = String(alphabetChars[0])
        } else {
            while num > 0 {
                let index = Int(num % alphabetLength)
                result = String(alphabetChars[index]) + result
                num /= alphabetLength
            }
        }
        
        // Pad to min length if needed
        while result.count < minLength {
            result = String(alphabetChars[0]) + result
        }
        
        return result
    }
}

