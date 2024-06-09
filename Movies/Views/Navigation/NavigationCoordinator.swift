import SwiftUI

import PageLoader

/// The view that is responsible for Navigation.
struct NavigationCoordinator: View {
    let rootPageType: PageType
    let pageLoaderFactory: PageLoaderFactory
        
    var body: some View {
        NavigationStack {
            pageLoaderFactory.createPageLoader(for: rootPageType)
                .navigationDestination(for: PageType.self, destination: { pageType in
                    pageLoaderFactory.createPageLoader(for: pageType)
                })
        }
    }
}
