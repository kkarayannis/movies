import Combine
import Foundation

import Cache
import XCTest

final class CachedPublisherTests: XCTestCase {
    
    // Unit under test
    var publisher: AnyPublisher<Data, Error>!
    
    // Dependencies
    var publisherCacheFake: PublisherCacheFake!
    let subject = PassthroughSubject<Data, Error>()
    
    var cancellable: AnyCancellable?
    
    override func setUp() {
        super.setUp()
        
        publisherCacheFake = PublisherCacheFake()
    }
    
    override func tearDown() {
        super.tearDown()
        
        cancellable?.cancel()
    }
    
    func testSavesElementsToCache_staleWhileRevalidate() {
        // Given a cached publisher
        publisher = subject
            .cache(publisherCacheFake, strategy: .staleWhileRevalidate)
        
        // and the cache has a cached element
        publisherCacheFake.cachedData = "Old news".data(using: .utf8)!
        
        // When the upstream publisher emits an element
        let expectation = expectation(description: "Async writing to cache")
        publisherCacheFake.expectationToFulfill = expectation
        
        let data = "Testing 1,2,3".data(using: .utf8)!
        subject.send(data)
        
        wait(for: [expectation], timeout: 2)
        
        // Then the element is stored in the cache
        XCTAssertEqual(publisherCacheFake.cachedData, data)
    }
    
    func testSavesElementsToCache_cacheFirst() {
        // Given the cache has a cached element
        let oldData = "Old news".data(using: .utf8)!
        publisherCacheFake.cachedData = oldData
        
        // and a cached publisher
        publisher = subject
            .cache(publisherCacheFake, strategy: .cacheFirst)
        
        // When the upstream publisher emits an element
        let expectation = expectation(description: "Async writing to cache")
        expectation.isInverted = true
        publisherCacheFake.expectationToFulfill = expectation
        
        let data = "Testing 1,2,3".data(using: .utf8)!
        subject.send(data)
        
        wait(for: [expectation], timeout: 2)
        
        // Then the new element is not stored in the cache
        XCTAssertEqual(publisherCacheFake.cachedData, oldData)
    }
    
    func testPublishesUpstreamElement_staleWhileRevalidate() {
        // Given a cached publisher
        publisher = subject
            .cache(publisherCacheFake, strategy: .staleWhileRevalidate)
        
        // and that we subscribe to the publisher
        let expectation = expectation(description: "Publishing element")
        var expectedData: Data?
        cancellable = publisher
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("We were not expecting an error")
                    expectation.fulfill()
                }
            }, receiveValue: { data in
                expectedData = data
                expectation.fulfill()
            })
        
        // When the upstream publisher emits an element
        let data = "Is this thing on?".data(using: .utf8)!
        subject.send(data)
        
        wait(for: [expectation], timeout: 2)
        
        // Then we expect to receive that element
        XCTAssertEqual(expectedData, data)
    }
    
    func testPublishesCachedElementAndThenUpstreamElement_staleWhileRevalidate() {
        // Given a cached element
        let cachedData = "(the mic is off)".data(using: .utf8)
        publisherCacheFake.cachedData = cachedData
        
        // and a cached publisher
        publisher = subject
            .cache(publisherCacheFake, strategy: .staleWhileRevalidate)
        
        // and that we subscribe to the publisher
        let expectation = expectation(description: "Publishing element")
        var expectedData = [Data]()
        cancellable = publisher
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("We were not expecting an error")
                    expectation.fulfill()
                }
            }, receiveValue: { data in
                expectedData.append(data)
            })
        
        // When the upstream publisher emits an element
        let data = "Hey, I think this is broken.".data(using: .utf8)!
        Task {
            // Delay the task by 0.1 second:
            try await Task.sleep(nanoseconds: 100_000_000)
            subject.send(data)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
        
        // Then we expect to receive that element
        XCTAssertEqual(expectedData, [cachedData, data])
    }
    
    func testPublishesCachedElementAndNotUpstreamElement_cacheFirst() {
        // Given a cached element
        let cachedData = "(the mic is off)".data(using: .utf8)
        publisherCacheFake.cachedData = cachedData
        
        // and a cached publisher
        publisher = subject
            .cache(publisherCacheFake, strategy: .cacheFirst)
        
        // and that we subscribe to the publisher
        let expectation = expectation(description: "Publishing element")
        var expectedData = [Data]()
        cancellable = publisher
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("We were not expecting an error")
                    expectation.fulfill()
                }
            }, receiveValue: { data in
                expectedData.append(data)
            })
        
        // When the upstream publisher emits an element
        let data = "Hey, I think this is broken.".data(using: .utf8)!
        Task {
            // Delay the task by 0.1 second:
            try await Task.sleep(nanoseconds: 100_000_000)
            subject.send(data)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
        
        // Then we expect to receive that element
        XCTAssertEqual(expectedData, [cachedData])
    }
    
    func testPublishesUpstreamError() {
        // Given a cached publisher
        publisher = subject
            .cache(publisherCacheFake, strategy: .staleWhileRevalidate)
        
        // and that we subscribe to the publisher
        let expectation = expectation(description: "Publishing element")
        var expectedError: Error?
        cancellable = publisher
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    expectedError = error
                    expectation.fulfill()
                }
            }, receiveValue: { data in
                XCTFail("We were not expecting an error")
                expectation.fulfill()
            })
        
        // When the upstream publisher emits an error
        subject.send(completion: .failure(TestError.generic))
        
        wait(for: [expectation], timeout: 2)
        
        // Then we expect to receive that element
        XCTAssertEqual(expectedError as? TestError, .generic)
    }
    
    func testPublishesCachedElementAndIgnoresUpstreamError() {
        // Given a cached element
        let cachedData = "(the mic is off)".data(using: .utf8)
        publisherCacheFake.cachedData = cachedData
        
        // and a cached publisher
        publisher = subject
            .cache(publisherCacheFake, strategy: .staleWhileRevalidate)
        
        // and that we subscribe to the publisher
        let expectation = expectation(description: "Publishing element")
        var expectedData = [Data]()
        cancellable = publisher
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("We were not expecting an error")
                    expectation.fulfill()
                }
            }, receiveValue: { data in
                expectedData.append(data)
            })
        
        // When the upstream publisher emits an element
        Task {
            // Delay the task by 0.1 second:
            try await Task.sleep(nanoseconds: 100_000_000)
            subject.send(completion: .failure(TestError.generic))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
        
        // Then we expect to receive that element
        XCTAssertEqual(expectedData, [cachedData])
    }
}

private enum TestError: Error {
    case generic
}
