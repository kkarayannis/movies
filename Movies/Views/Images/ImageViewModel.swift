import Combine
import SwiftUI

import ImageLoader

final class ImageViewModel {
    let url: URL?
    private let imageLoader: ImageLoader
    
    @Published var image: UIImage?
    private var cancellable: Cancellable?
    
    init(url: URL?, imageLoader: ImageLoader) {
        self.url = url
        self.imageLoader = imageLoader
    }
    
    func load() {
        guard let url else {
            return
        }
        cancellable = imageLoader.loadImage(for: url)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                self?.image = $0
            })
    }
}
