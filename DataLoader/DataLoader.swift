import Foundation
import Combine

public enum DataLoaderError: Error {
    case invalidURL
    case networkError
}

public enum DataLoaderMethod: String {
    case get = "GET"
}

/// Loads data from the network.
public protocol DataLoader {
    func loadData(for url: URL, parameters: [String: Any]?, method: DataLoaderMethod) -> AnyPublisher<Data, URLError>
}

public extension DataLoader {
    func publisher(for url: URL) -> AnyPublisher<Data, URLError> {
        loadData(for: url, parameters: nil, method: .get)
    }
}

public final class DataLoaderImplementation: DataLoader {
    private let urlSession: URLSession
    
    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    public func loadData(
        for url: URL,
        parameters: [String: Any]?,
        method: DataLoaderMethod
    ) -> AnyPublisher<Data, URLError> {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let parameters, !parameters.isEmpty {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }
        
        return urlSession.dataTaskPublisher(for: request)
            .map { data, _ in
                return data
            }
            .eraseToAnyPublisher()
    }
}
