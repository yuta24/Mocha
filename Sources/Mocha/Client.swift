import Foundation
import Combine

func makeURLRequest<R>(request: R, with baseURL: URL) -> URLRequest where R: Request {
    let url = baseURL.appendingPathComponent(request.path)
    var urlRequest = URLRequest(url: url)

    urlRequest.httpMethod = request.method.rawValue
    request.headers.forEach { key, value in
        urlRequest.setValue(value, forHTTPHeaderField: key)
    }
    if !request.queryPrameters.isEmpty, var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) {
        components.queryItems = [URLQueryItem]()
        for (key, value) in request.queryPrameters {
            switch value {
            case let values as [Any?]:
                components.queryItems?.append(contentsOf: values.compactMap {
                    if let value = $0 {
                        return URLQueryItem(name: key, value: "\(value)")
                    } else {
                     return nil
                    }
                })
            case let value:
                components.queryItems?.append(URLQueryItem(name: key, value: "\(String(describing: value))"))
            }
        }
        urlRequest.url = components.url
    }
    if !request.bodyParameters.isEmpty {
        let data = try! JSONSerialization.data(withJSONObject: request.bodyParameters, options: .init())
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = data
    }

    return urlRequest
}

open class Client {
    public enum Failure: Error {
        case network(Network.Failure)
        case decode(Error)
    }

    public let baseURL: URL
    public var network: Network

    public init(_ network: Network, with baseURL: URL) {
        self.baseURL = baseURL
        self.network = network
    }

    open func perform<R>(_ request: R, completionHandler: @escaping (Result<R.Response, Failure>) -> Void) where R: Request {
        network.perform(with: makeURLRequest(request: request, with: baseURL)) { (result) in
            switch result {
            case .success(let value):
                do {
                    let response = try request.parse(value.0)
                    completionHandler(.success(response))
                } catch let error {
                    completionHandler(.failure(.decode(error)))
                }
            case .failure(let error):
                completionHandler(.failure(.network(error)))
            }
        }
    }
}

extension Client {
    open func publisher<R>(for request: R) -> AnyPublisher<R.Response, Failure> where R: Request {
        NetworkPublisher(network: network, request: makeURLRequest(request: request, with: baseURL))
            .tryMap {
                do {
                    return try request.parse($0)
                } catch let error {
                    throw Failure.decode(error)
                }
            }
            .mapError { error -> Failure in
                switch error {
                case let error as Network.Failure:
                    return Failure.network(error)
                case let error as Client.Failure:
                    return Failure.decode(error)
                default:
                    fatalError()
                }
            }
            .eraseToAnyPublisher()
    }
}
