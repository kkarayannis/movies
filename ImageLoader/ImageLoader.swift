import Foundation
import Combine
import SwiftUI

import Cache
import DataLoader

/// Loads images from the network.
public protocol ImageLoader {
    func loadImage(for url: URL) -> AnyPublisher<UIImage, Error>
}

enum ImageLoaderError: Error {
    case imageDecodingError
}

public final class ImageLoaderImplementation: ImageLoader {
    private let dataLoader: DataLoader
    private let cache: Cache
    
    public init(dataLoader: DataLoader, cache: Cache) {
        self.dataLoader = dataLoader
        self.cache = cache
    }
    
    public func loadImage(for url: URL) -> AnyPublisher<UIImage, Error> {
        dataLoader.publisher(for: url)
            .mapError { error in
                // Handle network error more granularly if needed here.
                return DataLoaderError.networkError
            }
            .cache(
                PublisherCacheImplementation(key: url.absoluteString.base64, cache: cache),
                strategy: .staleWhileRevalidate
            )
            .tryMap {
                guard let image = UIImage(data: $0 ) else {
                    throw ImageLoaderError.imageDecodingError
                }
                return image
            }
            .eraseToAnyPublisher()
    }
}

private extension String {
    var base64: String {
        Data(utf8).base64EncodedString()
    }
}
