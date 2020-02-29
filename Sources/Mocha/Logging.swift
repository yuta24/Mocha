//
//  File.swift
//  
//
//  Created by Yu Tawata on 2020/02/06.
//

import Foundation

public struct cURLRequestLogging: Interceptor {
    public init() {
    }

    public func request(_ request: URLRequest) -> URLRequest {
        debugPrint(cURL(request))
        return request
    }

    public func response(_ request: URLRequest, data: Data?, response: URLResponse?, error: Error?) {
    }
}

public struct JSONResponseLogging: Interceptor {
    public init() {
    }

    public func request(_ request: URLRequest) -> URLRequest {
        return request
    }

    public func response(_ request: URLRequest, data: Data?, response: URLResponse?, error: Error?) {
        guard let data = data else {
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) else {
            return
        }

        debugPrint(json)
    }
}
