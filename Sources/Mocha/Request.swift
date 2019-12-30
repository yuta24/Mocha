import Foundation

public enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
    case patch  = "PATCH"
}

public protocol Request {
    associatedtype Response

    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryPrameters: [String: Any?] { get }
    var bodyParameters: [String: Any] { get }

    func parse(_ data: Data) throws -> Response
}
