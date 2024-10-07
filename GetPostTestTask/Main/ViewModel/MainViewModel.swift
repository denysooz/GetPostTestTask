//
//  MainViewModel.swift
//  GetPostTestTask
//
//  Created by Denis Dareuskiy on 3.10.24.
//

import Foundation
import Combine
import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    @Published var photos: [PhotoTypeDtoOut] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingInitial: Bool = false
        @Published var alertStatus: String?
        @Published var alertHeaders: String?
        @Published var alertMessage: String?
        @Published var showAlert: Bool = false
    var hasMorePages: Bool = true
    var currentPage: Int = 1
    private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService() // Предполагается, что у вас есть сервис для сетевых запросов

    func loadAllPhotos() {
        print("Начинается загрузка всех фотографий")
        loadMorePhotos(page: currentPage)
    }

    func loadMorePhotos(page: Int) {
        guard !isLoading && hasMorePages else { return }
        isLoading = true

        // Выполнение сетевого запроса в фоновом потоке
        networkService.fetchPages(page: page)
            .receive(on: DispatchQueue.main) // Возвращаемся на главный поток для обновления UI
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    print("Error fetching pages: \(error)")
                    // Можно уведомить пользователя об ошибке здесь
                }
            } receiveValue: { [weak self] page in
                guard let self = self else { return }
                if page.content.isEmpty {
                    self.hasMorePages = false
                } else {
                    self.photos.append(contentsOf: page.content)
                    self.currentPage += 1
                    self.cachePhotos(page.content) // Кэшируем загруженные фотографии
                    
                    // Выводим сообщение о количестве загруженных фотографий
                    print("Все фотографии загружены, текущее количество: \(self.photos.count)")
                }
            }
            .store(in: &cancellables)
    }

    private func cachePhotos(_ photos: [PhotoTypeDtoOut]) {
        let currentCachedPhotos = loadCachedPhotos()
        var updatedPhotos = currentCachedPhotos

        for photo in photos {
            if !updatedPhotos.contains(where: { $0.id == photo.id }) {
                updatedPhotos.append(photo)
            }
        }

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(updatedPhotos) {
            UserDefaults.standard.set(data, forKey: "cachedPhotos")
        }
    }

    private func loadCachedPhotos() -> [PhotoTypeDtoOut] {
        if let data = UserDefaults.standard.data(forKey: "cachedPhotos") {
            let decoder = JSONDecoder()
            if let cachedPhotos = try? decoder.decode([PhotoTypeDtoOut].self, from: data) {
                return cachedPhotos
            }
        }
        return []
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "cachedPhotos")
        photos.removeAll()
        currentPage = 1
        hasMorePages = true
    }

    func uploadPhoto(name: String, photoID: Int, image: UIImage) {
        networkService.uploadPhoto(name: name, photoID: photoID, image: image) { [weak self] (result: Result<PostResponse, Error>) in
            switch result {
            case .success(let postResponse):
                self?.alertStatus = "Success"
                self?.alertHeaders = "Response Headers: \(postResponse.headers?.description ?? "No headers")"
                self?.alertMessage = "ID: \(postResponse.id)"
                self?.showAlert = true
            case .failure(let error):
                self?.alertStatus = "Error"
                self?.alertHeaders = "No headers"
                self?.alertMessage = error.localizedDescription
                self?.showAlert = true
            }
        }
    }
}
