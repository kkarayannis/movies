import Combine
import XCTest
@testable import Movies

final class GenreListLoaderTests: XCTestCase {
    
    // Unit under test
    var genreListLoader: GenreListLoaderImplementation!
    
    // Dependencies
    var dataLoaderFake: DataLoaderFake!
    var cacheFake: CacheFake!
    var loggerFake: LoggerFake!
    
    var cancellable: AnyCancellable?

    override func setUpWithError() throws {
        try super.setUpWithError()
        dataLoaderFake = DataLoaderFake()
        cacheFake = CacheFake()
        loggerFake = LoggerFake()
        genreListLoader = GenreListLoaderImplementation(dataLoader: dataLoaderFake, logger: loggerFake, cache: cacheFake)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        cancellable?.cancel()
    }

    func testLoadingGenreList() throws {
        // Given the data loader has some data
        dataLoaderFake.data = try Helpers.genreListTestData()
        
        // When we load the genre list
        let expectation = expectation(description: "Loading genre list")
        var expectedGenreList: [Genre]?
        cancellable = genreListLoader.genresPublisher
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("We were not expecting an error")
                    expectation.fulfill()
                }
            }, receiveValue: { genres in
                expectedGenreList = genres
                expectation.fulfill()
            })
        
        wait(for: [expectation], timeout: 2)
        
        // Then we get a genre list with some entries
        XCTAssertGreaterThan(expectedGenreList?.count ?? 0, 0)
    }
    
    func testLoadingGenreListWithDecodingError() throws {
        // Given the data loader has some bogus data
        dataLoaderFake.data = "these are not the droids you are looking for".data(using: .utf8)
        
        // When we load the genre list
        let expectation = expectation(description: "Loading genre list")
        var expectedError: Error?
        cancellable = genreListLoader.genresPublisher
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    expectedError = error
                    expectation.fulfill()
                }
            }, receiveValue: { value in
                XCTFail("We were not expecting a valid object. Received: \(value)")
                expectation.fulfill()
            })
        
        wait(for: [expectation], timeout: 2)
        
        // Then we get an error
        XCTAssertNotNil(expectedError as? DecodingError)
    }
    
}
