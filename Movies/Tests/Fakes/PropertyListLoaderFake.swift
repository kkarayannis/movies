@testable import Movies

import Combine
import XCTest

final class GenreListLoaderFake: GenreListLoader {    
    var genres: [Genre]?
    var error: Error?
    
    var genresPublisher: AnyPublisher<[Genre], Error> {
        guard genres != nil || error != nil else {
            XCTFail("Both genres and error are nil")
            return Empty<[Genre], Error>()
                .eraseToAnyPublisher()
        }
        
        if let error {
            return Fail(error: error)
                .eraseToAnyPublisher()
        } else if let genres {
            return Just(genres)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return Empty<[Genre], Error>()
            .eraseToAnyPublisher()
    }
}
