import Combine
import Foundation

enum PublisherCacheError: Error {
    case noDataForKey
    case invalidContext
}

/// Caches elements from a publisher and produces a publisher for cached elements.
public protocol PublisherCache {
    /// Returns a publisher that publishes cached elements.
    var cachedDataPublisher: any Publisher<Data, Error> { get }
    
    /// Cache the latest element that a publisher emits
    /// - Parameter publisher: The publisher whose elements to cache.
    func cacheElements(from publisher: some Publisher<Data, Error>)
    
    var cachedData: Data? { get }
}

public final class PublisherCacheImplementation: PublisherCache {
    private let key: String
    private let cache: Cache
    
    private var subscription: AnyCancellable?
    public init(key: String, cache: Cache = CacheImplementation(fileManager: FileManager.default)) {
        self.key = key
        self.cache = cache
    }
    
    public func cacheElements(from publisher: some Publisher<Data, Error>) {
        subscription = publisher
            .sink(receiveCompletion: { completion in }) { element in
                try? self.cache.store(data: element, key: self.key)
            }
    }
    
    public var cachedDataPublisher: any Publisher<Data, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(PublisherCacheError.invalidContext))
                return
            }
            guard let data = try? self.cache.data(for: self.key) else {
                promise(.failure(PublisherCacheError.noDataForKey))
                return
            }
            
            promise(.success(data))
        }
    }
    
    public var cachedData: Data? {
        try? cache.data(for: self.key)
    }
}
