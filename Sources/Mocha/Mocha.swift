import Foundation
import Combine

struct Mocha {
    var text = "Hello, World!"
}

public protocol Retrier: AnyObject {
    func retry(_ request: URLRequest, completionHandler: @escaping (Result<Void, Error>) -> Void)
}

public protocol Interceptor {
    func request(_ request: URLRequest) -> URLRequest
    func response(_ request: URLRequest, data: Data?, response: URLResponse?, error: Error?)
}

open class Network {
    public enum Failure: Error {
        case request(Error)
        case unauthorize(Error)
        case server(Int, Data)
        case unsupport(HTTPURLResponse)
    }

    public var retrier: Retrier?
    public var interceptors = [Interceptor]()

    private let session: URLSession
    private let queue: DispatchQueue
    private var tasks = [URLSessionTask]()

    public init(session: URLSession, queue: DispatchQueue = DispatchQueue(label: "com.bivre.mocha", qos: .userInitiated)) {
        self.session = session
        self.queue = queue
    }

    @discardableResult
    open func perform(with request: URLRequest, completionHandler: @escaping (Result<(Data, HTTPURLResponse), Failure>) -> Void) -> URLSessionTask {
        let request = interceptors.reduce(request, {
            $1.request($0)
        })

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            self?.queue.async { [weak self] in
                self?.interceptors.forEach {
                    $0.response(request, data: data, response: response, error: error)
                }
                self?.responseHandler(request, data: data, response: response, error: error, completionHandler: completionHandler)
            }
        }
        tasks.append(task)

        task.resume()

        return task
    }

    func responseHandler(_ request: URLRequest, data: Data?, response: URLResponse?, error: Error?, completionHandler: @escaping (Result<(Data, HTTPURLResponse), Failure>) -> Void) {
        switch (data, response as? HTTPURLResponse, error) {
        case (.some(let data), .some(let response), .none):
            switch response.statusCode {
            case 200...299:
                completionHandler(.success((data, response)))
            case 400...499:
                retrier?.retry(request, completionHandler: { [weak self] result in
                    switch result {
                    case .success:
                        self?.perform(with: request, completionHandler: completionHandler)
                    case .failure(let error):
                        completionHandler(.failure(.unauthorize(error)))
                    }
                })
            case 500...599:
                completionHandler(.failure(.server(response.statusCode, data)))
            default:
                completionHandler(.failure(.unsupport(response)))
            }
        case (_, _, .some(let error)):
            completionHandler(.failure(.request(error)))
        default:
            fatalError()
        }
    }
}

extension Network {
    open func publisher(for request: URLRequest) -> NetworkPublisher {
        NetworkPublisher(network: self, request: request)
    }
}

public struct NetworkSubscription: Subscription {
    public let combineIdentifier: CombineIdentifier
    public let task: URLSessionTask

    public func request(_ demand: Subscribers.Demand) {
    }

    public func cancel() {
        task.cancel()
    }
}

public struct NetworkPublisher: Publisher {
    public typealias Output = Data
    public typealias Failure = Network.Failure

    let network: Network
    let request: URLRequest

    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let task = network.perform(with: request) { result in
            switch result {
            case .success(let value):
                _ = subscriber.receive(value.0)
                subscriber.receive(completion: .finished)
            case .failure(let error):
                subscriber.receive(completion: .failure(error))
            }
        }

        subscriber.receive(subscription: NetworkSubscription(combineIdentifier: CombineIdentifier(), task: task))
    }
}
