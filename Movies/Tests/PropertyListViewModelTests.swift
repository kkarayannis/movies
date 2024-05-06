@testable import Movies

import Combine
import Foundation
import XCTest

import PageLoader

final class GenreListViewModelTests: XCTestCase {
    
    // Unit under test
    var viewModel: GenreListViewModel!
    
    // Dependencies
    var genreListLoaderFake: GenreListLoaderFake!
    var loggerFake: LoggerFake!
    
    var cancellable: AnyCancellable?
    
    override func setUp() {
        super.setUp()
        
        genreListLoaderFake = GenreListLoaderFake()
        loggerFake = LoggerFake()
        viewModel = GenreListViewModel(
            genreListLoader: genreListLoaderFake,
            logger: loggerFake
        )
    }
    
    override func tearDown() {
        super.tearDown()
        
        cancellable?.cancel()
    }
    
    func testLoadItems() throws {
        // Given the loader will return a genre list
        genreListLoaderFake.genres = try Helpers.responseGenreList().genres
        
        // and that we subscribe to the genresPublisher
        let expectation = expectation(description: "Loading items")
        var expectedItems: [Genre]?
        cancellable = viewModel.genresPublisher
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("We were not expecting an error")
                    expectation.fulfill()
                }
            }, receiveValue: { items in
                expectedItems = items
                expectation.fulfill()
            })
        
        // When we load the genres
        viewModel.loadGenres()
        
        wait(for: [expectation], timeout: 2)
        
        // Then we get some genres
        XCTAssertGreaterThan(expectedItems?.count ?? 0, 0)
    }
    
    func testLoadItemsSetsTheStateToLoaded() throws {
        // Given the loader will return a genre list
        genreListLoaderFake.genres = try Helpers.responseGenreList().genres
        
        // and that we subscribe to the pageStatePublisher
        let expectation = expectation(description: "Page state loading")
        var expectedState: PageLoaderState?
        cancellable = viewModel.pageStatePublisher
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("We were not expecting an error")
                    expectation.fulfill()
                }
            }, receiveValue: { state in
                expectedState = state
                expectation.fulfill()
            })
        
        // When we load the genres
        viewModel.loadGenres()
        
        wait(for: [expectation], timeout: 2)
        
        // Then we get a loaded state
        XCTAssertEqual(expectedState, .loaded)
    }
    
    func testLoadItemsSetsTheStateToError() throws {
        // Given the loader will produce an error
        genreListLoaderFake.error = TestError.generic
        
        // and that we subscribe to the pageStatePublisher
        let expectation = expectation(description: "Page state loading")
        var expectedState: PageLoaderState?
        cancellable = viewModel.pageStatePublisher
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("We were not expecting an error")
                    expectation.fulfill()
                }
            }, receiveValue: { state in
                expectedState = state
                expectation.fulfill()
            })
        
        // When we load the genres
        viewModel.loadGenres()
        
        wait(for: [expectation], timeout: 2)
        
        // Then we get a loaded state
        XCTAssertEqual(expectedState, .error)
    }
}
