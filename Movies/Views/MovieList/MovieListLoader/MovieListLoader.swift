import Combine
import Foundation

import Cache
import DataLoader

protocol MovieListLoader {
    func moviesPublisher(genreID: Int) -> AnyPublisher<GenreMoviesResponse, Error>
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
    
    func moviesPublisher(genreID: Int) -> AnyPublisher<GenreMoviesResponse, Error> {
        guard let url = URL(string: TMDB.Endpoint.genreMovies(genreID)) else {
            return Fail(error: DataLoaderError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return dataLoader.publisher(for: url)
            .mapError { [weak self] error in
                // Handle network error more granularly if needed here.
                self?.logger.log(error.localizedDescription, logLevel: .error)
                return DataLoaderError.networkError
            }
            .cache(PublisherCacheImplementation(key: (Self.movieListCacheKey + String(genreID)).base64, cache: cache))
            .tryMap {
                try JSONDecoder().decode(GenreMoviesResponse.self, from: $0)
            }
            .eraseToAnyPublisher()
    }
}
