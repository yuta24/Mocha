import Foundation

public func cURL(_ request: URLRequest) -> String {
    guard let url = request.url
        , let method = request.httpMethod else {
            return "$ curl command could not be created"
    }

    var components = ["$ curl -v"]

    components.append("-X \(method)")

    for header in request.allHTTPHeaderFields ?? [:] {
        let escapedValue = header.value.replacingOccurrences(of: "\"", with: "\\\"")
        components.append("-H \"\(header.key): \(escapedValue)\"")
    }

    if let httpBodyData = request.httpBody {
        let httpBody = String(decoding: httpBodyData, as: UTF8.self)
        var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
        escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")

        components.append("-d \"\(escapedBody)\"")
    }

    components.append("\"\(url.absoluteString)\"")

    return components.joined(separator: " \\\n\t")
}
