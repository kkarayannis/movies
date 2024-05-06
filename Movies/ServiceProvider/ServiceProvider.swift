import Foundation

import Cache
import DataLoader
import ImageLoader

protocol ServiceProvider {
    func provideDataLoader() -> DataLoader
    func providePageFactory() -> PageFactory
}

final class ServiceProviderImplementation: ServiceProvider {
    private let logger = LoggerImplementation()
    private let dataLoader = DataLoaderImplementation(urlSession: URLSession.shared)
    private let cache24h = CacheImplementation(fileManager: FileManager.default, expirationInterval: 86_400)
    private let cache = CacheImplementation(fileManager: FileManager.default)
    private lazy var imageLoader = ImageLoaderImplementation(dataLoader: dataLoader, cache: cache)
    private lazy var pageFactory = PageFactoryImplementation(
        genreListLoader: GenreListLoaderImplementation(dataLoader: dataLoader, logger: logger, cache: cache24h),
        movieListLoader: MovieListLoaderImplementation(dataLoader: dataLoader, logger: logger, cache: cache),
        imageLoader: imageLoader,
        logger: logger
    )
    
    func provideDataLoader() -> DataLoader {
        dataLoader
    }
    
    func providePageFactory() -> PageFactory {
        pageFactory
    }
}
