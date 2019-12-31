//
//  GitHub.swift
//  GitHubViewer
//
//  Created by Yu Tawata on 2019/12/30.
//  Copyright © 2019 Yu Tawata. All rights reserved.
//

import Foundation
import Mocha

class GitHubClient: Client {
    static let `default` = GitHubClient(Network(session: .shared), with: URL(string: "https://api.github.com")!)
}

enum GitHub {}

extension GitHub {
    struct Repository: Decodable, Identifiable {
        let id: Int64
        let name: String
        let fullName: String
    }

    struct GetRepositories: Request {
        typealias Response = [Repository]

        var path: String { "/repositories" }
        var method: HTTPMethod { .get }
        var headers: [String : String] { [:] }
        var queryPrameters: [String : Any?] { [:] }
        var bodyParameters: [String : Any] { [:] }

        func parse(_ data: Data) throws -> GitHub.GetRepositories.Response {
            do {
                let decorder = JSONDecoder()
                decorder.keyDecodingStrategy = .convertFromSnakeCase
                return try decorder.decode(Response.self, from: data)
            } catch let error {
                throw Client.Failure.decode(error)
            }
        }
    }
}
