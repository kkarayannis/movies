@testable import Movies

import Foundation

enum TestError: Error {
    case generic
    case dataError
}

final class Helpers {
    static func genreListTestData() throws -> Data {
        let bundle = Bundle(for: Self.self)
        guard let url = bundle.url(forResource: "genres", withExtension: "json") else {
            throw TestError.dataError
        }
        return try Data(contentsOf: url)
    }
    
    static func responseGenreList() throws -> GenreListResponse {
        let data = try genreListTestData()
        let decoder = JSONDecoder()
        
        return try decoder.decode(GenreListResponse.self, from: data)
    }
}
