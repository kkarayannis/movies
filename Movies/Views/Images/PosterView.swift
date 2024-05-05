import Combine
import SwiftUI

/// View that displays the images
struct PosterView: View {
    private let viewModel: ImageViewModel
    @State private var image: UIImage? = nil
    
    init(viewModel: ImageViewModel) {
        self.viewModel = viewModel
        
        image = nil
        viewModel.load()
    }
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
            } else {
                Color.gray
            }
        }
        .aspectRatio(500.0/750.0, contentMode: .fit)
        .onReceive(viewModel.$image) {
            image = $0
        }
    }
}
