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
            .flatMap { [weak self] _ -> AnyPublisher<[FetchedDataResponse], HomeServiceError> in
                guard let self = self else {
                    return Fail(error: HomeServiceError.selfIsNil)
                        .eraseToAnyPublisher()
                }
                return self.homeService.mediumPhotos
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard
                        let self = self,
                        case .failure(let error) = completion
                    else {
                        return
                    }

                    self.showErrorAlert = true
                    print("🚨 \(error.errorDescription)")
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }

                    self.showErrorAlert = false
                    self.showCacheAlert = false
                    self.state = .loaded(response)
                }
            )
            .store(in: &cancellables)

        clearCache
            .flatMap { [weak self] _ -> AnyPublisher<Void, HomeServiceError> in
                guard let self = self else {
                    return Fail(error: HomeServiceError.selfIsNil)
                        .eraseToAnyPublisher()
                }
                return self.homeService.clearCache()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard
                        let self = self,
                        case .failure(let error) = completion
                    else {
                        return
                    }

                    self.showErrorAlert = true
                    print("🚨 \(error.errorDescription)")
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }

                    self.showErrorAlert = false
                    self.showCacheAlert = true
                }
            )
            .store(in: &cancellables)
    }
}
