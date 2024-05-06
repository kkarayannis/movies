import Combine
import Foundation

/// Different caching strategies. Can affect the number of elements emiited as well as if the upstream publisher receives a subscriber.
public enum CachingStrategy {
    ///   - If the cache has a hit then only the cache's element is published and the upstream publisher never receives a subscriber. Useful
    ///   if we want to conserve bandwidth/backend resources.
    ///   - If the cache has a miss then only the upstream elements are published.
    case cacheFirst
    ///   - If the cache has a hit then the cache's element is published and then the upstream's element follows. Useful for showing content quickly
    ///   while making sure the content stays updated.
    ///   - If the cache has a miss then only the upstream elements are published.
    ///   - If for some reason the upstream publisher produces an element before the cache produces it's element, the cache's element is ignored (not published).
    ///   - The cache never emits any errors.
    ///   - The upstream publisher's errors are emitted but only if the cache hasn't emitted any elements. If it has, then this publisher finishes without an error.
    case staleWhileRevalidate
}

extension Publisher<Data, Error> {
    
    public func cache(_ cache: PublisherCache, strategy: CachingStrategy) -> AnyPublisher<Data, Error> {
        switch strategy {
        case .cacheFirst:
            return cacheFirst(cache)
        case .staleWhileRevalidate:
            return cacheStaleWhileRevalidate(cache)
        }
    }
    
    private func cacheFirst(_ cache: PublisherCache) -> AnyPublisher<Data, Error> {
        if let cachedElement = cache.cachedData {
            return Just(cachedElement)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        let upstream = self.share()
        cache.cacheElements(from: upstream)
        
        return upstream
            .eraseToAnyPublisher()
    }
    
    private func cacheStaleWhileRevalidate(_ cache: PublisherCache) -> AnyPublisher<Data, Error> {
        let upstream = self.share()
        cache.cacheElements(from: upstream)
        
        let cachePublisher = cache.cachedDataPublisher
            .ignoreError() // We don't care about errors due to a cache misses.
            .prefix(untilOutputFrom: upstream) // Only emit cached elements before the upstream publisher emits any elements.
        
        var hasEmittedElement = false
        return cachePublisher
            .merge(with: upstream)
            .handleEvents(receiveOutput: { _ in
                hasEmittedElement = true
            })
            .tryCatch { error in
                // If we have emitted an element we should ignore all errors and finish normally.
                guard hasEmittedElement else {
                    throw error
                }
                return Empty<Data, Error>()
            }
            .eraseToAnyPublisher()
    }
}

private extension Publisher {
    /// This ignores errors from a publisher without changing the failure type to `Never`.
    func ignoreError() -> AnyPublisher<Output, Failure> {
        map { Optional($0) }
        .replaceError(with: nil)
        .compactMap { $0 }
        .setFailureType(to: Failure.self)
        .eraseToAnyPublisher()
    }
}
