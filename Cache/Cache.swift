import Foundation

enum CacheError: Error {
    case cacheDirectoryMissing
    case cannotStoreData
}

/// Generic storage solution for caching data
public protocol Cache {
    func store(data: Data, key: String) throws
    func data(for key: String) throws -> Data?
}

public final class CacheImplementation: Cache {
    private var fileManager: FileManager
    private var expirationInterval: TimeInterval?
    
    public init(fileManager: FileManager, expirationInterval: TimeInterval? = nil) {
        self.fileManager = fileManager
        self.expirationInterval = expirationInterval
    }
    
    private var cachesDirectoryURL: URL {
        get throws {
            guard let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                throw CacheError.cacheDirectoryMissing
            }
            
            return url
        }
    }
    
    public func store(data: Data, key: String) throws {
        let encodedTimestampedData = try JSONEncoder().encode(TimestampedData(data: data))
        let path = try cachesDirectoryURL.appending(path: key, directoryHint: .notDirectory).path()
        let success = fileManager.createFile(atPath: path, contents: encodedTimestampedData)
        
        guard success else {
            throw CacheError.cannotStoreData
        }
    }
    
    public func data(for key: String) throws -> Data? {
        let path = try cachesDirectoryURL.appending(path: key, directoryHint: .notDirectory).path()
        guard let encodedTimestampedData = fileManager.contents(atPath: path) else { return nil }
        let timestampedData = try JSONDecoder().decode(TimestampedData.self, from: encodedTimestampedData)
        if let expirationInterval, abs(timestampedData.timestamp.timeIntervalSinceNow) >= expirationInterval  {
            return nil
        }
        return timestampedData.data
    }
}

struct TimestampedData: Codable {
    let timestamp: Date
    let data: Data
    
    init(data: Data) {
        self.timestamp = Date()
        self.data = data
    }
}
