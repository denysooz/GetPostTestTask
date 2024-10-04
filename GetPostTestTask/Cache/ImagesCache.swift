//
//  ImageCache.swift
//  GetPostTestTask
//
//  Created by Denis Dareuskiy on 3.10.24.
//

import Foundation
import SwiftUI

class ImageCache {
    static let shared = ImageCache() // Создание синглтона
    private let cache = NSCache<NSString, UIImage>() // Объект NSCache
    
    private init() {}
    
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString) // Получение изображения из кэша
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString) // Сохранение изображения в кэш
    }
}
