import Combine
import XCTest

import Cache

final class PublisherCacheFake: PublisherCache {
    var cancellable: AnyCancellable?
    
    var expectationToFulfill: XCTestExpectation?
    func cacheElements(from publisher: some Publisher<Data, Error>) {
        cancellable = publisher.sink(receiveCompletion: { _ in }, receiveValue: { [weak self] element in
            self?.expectationToFulfill?.fulfill()
            self?.cachedData = element
        })
    }
    
    var cachedDataPublisher: any Publisher<Data, Error> {
        if let cachedData {
            return Just(cachedData)
                .setFailureType(to: Error.self)
        } else {
            return Empty<Data, Error>()
        }
    }
    
    var cachedData: Data?
}
