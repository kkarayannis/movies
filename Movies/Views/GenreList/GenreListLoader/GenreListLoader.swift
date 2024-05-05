import Combine
import Foundation

import Cache
import DataLoader

protocol GenreListLoader {
    var genresPublisher: AnyPublisher<[Genre], Error> { get }
}

final class GenreListLoaderImplementation: GenreListLoader {
    private static let genreListCacheKey = "genre-list"
    let dataLoader: DataLoader
    let logger: Logger
    let cache: Cache
    
    init(dataLoader: DataLoader, logger: Logger, cache: Cache) {
        self.dataLoader = dataLoader
        self.logger = logger
        self.cache = cache
    }
    
    var genresPublisher: AnyPublisher<[Genre], Error> {
        guard let url = URL(string: TMDB.Endpoint.genres) else {
            return Fail(error: DataLoaderError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return dataLoader.publisher(for: url)
            .mapError { [weak self] error in
                // Handle network error more granularly if needed here.
                self?.logger.log(error.localizedDescription, logLevel: .error)
                return DataLoaderError.networkError
            }
            .cache(PublisherCacheImplementation(key: Self.genreListCacheKey.base64, cache: cache))
            .tryMap {
                try JSONDecoder().decode(GenreListResponse.self, from: $0).genres
            }
            .eraseToAnyPublisher()
    }
}
