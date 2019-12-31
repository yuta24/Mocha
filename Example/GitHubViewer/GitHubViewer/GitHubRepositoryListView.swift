//
//  GitHubRepositoryListView.swift
//  GitHubViewer
//
//  Created by Yu Tawata on 2019/12/31.
//  Copyright © 2019 Yu Tawata. All rights reserved.
//

import SwiftUI
import Combine
import Mocha

struct Logging: Interceptor {
    func request(_ request: URLRequest) -> URLRequest {
        debugPrint(request)
        return request
    }

    func response(_ request: URLRequest, data: Data?, response: URLResponse?, error: Error?) {
        let json = try! JSONSerialization.jsonObject(with: data!, options: .fragmentsAllowed)
        debugPrint(json)
    }
}

class GitHubRepositoryListViewModel: ObservableObject {
    @Published var items = [GitHub.Repository]()

    private let client: GitHubClient
    private var cancellables = [AnyCancellable]()

    init(client: GitHubClient = .default) {
        self.client = client
        client.network.interceptors.append(Logging())
    }

    func fetch() {
        client.publisher(for: GitHub.GetRepositories())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    debugPrint(error)
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] in
                self?.items = $0
            })
            .store(in: &cancellables)
    }
}

struct GitHubRepositoryListView: View {
    @ObservedObject private var viewModel = GitHubRepositoryListViewModel()

    var body: some View {
        List(viewModel.items, id: \.id) {
            Text($0.fullName)
        }
        .onAppear {
            self.viewModel.fetch()
        }
    }
}

struct GitHubRepositoryListView_Previews: PreviewProvider {
    static var previews: some View {
        GitHubRepositoryListView()
    }
}
