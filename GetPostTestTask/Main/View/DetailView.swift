//
//  DetailView.swift
//  GetPostTestTask
//
//  Created by Denis Dareuskiy on 3.10.24.
//

import SwiftUI
import UIKit

struct DetailView: View {
    let photo: PhotoTypeDtoOut
    @State private var image: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                Text("Loading...")
                    .onAppear {
                        loadImage()
                    }
            }
            Text(photo.name)
                .font(.title)
                .padding()
        }
        .navigationTitle(photo.name)
    }
    
    private func loadImage() {
        isLoading = true
        let cacheKey = photo.name // Используйте уникальный ключ для кэширования

        // Проверка кэша
        if let cachedImage = ImageCache.shared.getImage(forKey: cacheKey) {
            self.image = cachedImage
            isLoading = false
            return
        }

        // Загрузка изображения из сети
        guard let urlString = photo.image, let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let loadedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            // Сохранение в кэш
            ImageCache.shared.setImage(loadedImage, forKey: cacheKey)

            DispatchQueue.main.async {
                self.image = loadedImage
                isLoading = false
            }
        }.resume()
    }
}

#Preview {
    DetailView(photo: PhotoTypeDtoOut(id: 1, name: "foo", image: "baa"))
}
