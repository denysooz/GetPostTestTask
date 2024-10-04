//
//  MainViewModel.swift
//  GetPostTestTask
//
//  Created by Denis Dareuskiy on 3.10.24.
//

import Foundation
import Combine

class MainViewModel: ObservableObject {
    @Published var photos: [PhotoTypeDtoOut] = []
    @Published var isLoading = false
    
    var currentPage = 1
    private var hasMorePages = true
    private let networkService = NetworkService()
    
    init() {
        loadCachedPhotos()
    }

    func loadAllPhotos() {
        loadMorePhotos(page: currentPage)
    }

    func loadMorePhotos(page: Int) {
        guard !isLoading && hasMorePages else { return }
        isLoading = true
        
        networkService.fetchPages(page: page) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let page):
                    if page.content.isEmpty {
                        self?.hasMorePages = false // Нет больше страниц для загрузки
                    } else {
                        self?.photos.append(contentsOf: page.content)
                        self?.cachePhotos(self!.photos)
                        self?.currentPage += 1
                    }
                case .failure(let error):
                    print("Error fetching pages: \(error)")
                }
            }
        }
    }

    private func loadCachedPhotos() {
        if let data = UserDefaults.standard.data(forKey: "cachedPhotos") {
            let decoder = JSONDecoder()
            if let cachedPhotos = try? decoder.decode([PhotoTypeDtoOut].self, from: data) {
                self.photos = cachedPhotos
            }
        }
    }

    private func cachePhotos(_ photos: [PhotoTypeDtoOut]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(photos) {
            UserDefaults.standard.set(data, forKey: "cachedPhotos")
        }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "cachedPhotos")
        photos.removeAll() // Очищаем массив фотографий
        currentPage = 1 // Сбрасываем счетчик страниц
        hasMorePages = true // Разрешаем загрузку новых страниц
    }
}
