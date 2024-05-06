import Combine
import Foundation

import Cache
import DataLoader

protocol MovieListLoader {
    func moviesPublisher(genreID: Int, page: Int) -> AnyPublisher<GenreMoviesResponse, Error>
}

final class MovieListLoaderImplementation: MovieListLoader {
    private static let movieListCacheKey = "movie-list"
    let dataLoader: DataLoader
    let logger: Logger
    let cache: Cache
    
    init(dataLoader: DataLoader, logger: Logger, cache: Cache) {
        self.dataLoader = dataLoader
        self.logger = logger
        self.cache = cache
    }
    
    func moviesPublisher(genreID: Int, page: Int) -> AnyPublisher<GenreMoviesResponse, Error> {
        guard let url = URL(string: TMDB.Endpoint.genreMovies(genreID, page: page)) else {
            return Fail(error: DataLoaderError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return dataLoader.publisher(for: url)
            .mapError { [weak self] error in
                // Handle network error more granularly if needed here.
                self?.logger.log(error.localizedDescription, logLevel: .error)
                return DataLoaderError.networkError
            }
            .transformIf(page == 1) { // Only cache first page
                $0.cache(
                    PublisherCacheImplementation(key: (Self.movieListCacheKey + String(genreID)).base64, cache: cache),
                    strategy: .staleWhileRevalidate
                )
            }
            .tryMap {
                try JSONDecoder().decode(GenreMoviesResponse.self, from: $0)
            }
            .eraseToAnyPublisher()
    }
}

private extension Publisher {
    func transformIf(_ condition: Bool, transform: (any Publisher<Output, Failure>) -> any Publisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
        if condition {
            return transform(self)
                .eraseToAnyPublisher()
        }
        
        return self
            .eraseToAnyPublisher()
    }
}
