import Combine
import Foundation

extension Publisher<Data, Error> {
    
    /// This stores a publisher's latest element to a cache.
    /// - Note:
    ///   - If the cache has a miss then only the upstream elements are published.
    ///   - If the cache has a hit then the cache's element is published and then the upstream's element follows.
    ///   - If for some reason the upstream publisher produces an element before the cache produces it's element, the cache's element is ignored (not published).
    ///   - The cache never emits any errors.
    ///   - The upstream publisher's errors are emitted but only if the cache hasn't emitted any elements. If it has, then this publisher finishes without an error.
    public func cache(_ cache: PublisherCache) -> AnyPublisher<Data, Error> {
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
