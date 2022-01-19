//
//  HomeViewModel.swift
//  Gallery
//
//  Created by Dominik Kohlman on 05.01.2022.
//

import Combine
import Foundation

final class HomeViewModel: ObservableObject {

    // MARK: - Properties

    let loadData = PassthroughSubject<Void, Never>()
    let clearCache = PassthroughSubject<Void, Never>()

    @Published var showErrorAlert = false
    @Published var showCacheAlert = false
    @Published private(set) var state = State.loading

    private let homeService = HomeService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupBindings()
    }
}

extension HomeViewModel {

    enum State {
        case loading
        case loaded([FetchedDataResponse])
    }
}

// MARK: - Private Methods

private extension HomeViewModel {

    func setupBindings() {
        loadData
            .sink { [weak self] _ in
                guard let self = self else { return }

                self.homeService.mediumPhotos
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            guard case .failure(let error) = completion else { return }

                            self.showErrorAlert = true
                            print("🚨 \(error.errorDescription)")
                        },
                        receiveValue: { response in
                            self.showErrorAlert = false
                            self.showCacheAlert = false
                            self.state = .loaded(response)
                        }
                    )
                    .store(in: &self.cancellables)
            }
            .store(in: &cancellables)

        clearCache
            .sink(
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }

                    self.homeService.clearCache()
                        .receive(on: DispatchQueue.main)
                        .sink(
                            receiveCompletion: { completion in
                                guard case .failure(let error) = completion else { return }

                                self.showErrorAlert = true
                                print("🚨 \(error.errorDescription)")
                            },
                            receiveValue: { _ in
                                self.showErrorAlert = false
                                self.showCacheAlert = true
                            }
                        )
                        .store(in: &self.cancellables)
                }
            )
            .store(in: &cancellables)
    }
}
