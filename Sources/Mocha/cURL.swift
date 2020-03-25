import Foundation

public func cURL(_ request: URLRequest) -> String {
    var result = "curl -k "

    if let method = request.httpMethod {
        result += "-X \(method) \\\n"
    }

    if let headers = request.allHTTPHeaderFields {
        for (header, value) in headers {
            result += "-H \"\(header): \(value)\" \\\n"
        }
    }

    if let body = request.httpBody, !body.isEmpty, let string = String(data: body, encoding: .utf8), !string.isEmpty {
        result += "-d '\(string)' \\\n"
    }

    if let url = request.url {
        result += url.absoluteString
    }

    return result
}
