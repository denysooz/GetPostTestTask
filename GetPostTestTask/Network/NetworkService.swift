//
//  Network.swift
//  GetPostTestTask
//
//  Created by Denis Dareuskiy on 3.10.24.
//

import Foundation
import SwiftUI
import Combine

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
}

struct PostResponse: Codable {
    let id: String
    // Уберите message, если он не возвращается
    var headers: [String: String]? // Для хранения заголовков
}

class NetworkService {
    func fetchPages(page: Int) -> AnyPublisher<Page<PhotoTypeDtoOut>, Error> {
        guard let url = URL(string: "https://junior.balinasoft.com/api/v2/photo/type?page=\(page)") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: Page<PhotoTypeDtoOut>.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func fetchPages(page: Int, completion: @escaping (Result<Page<PhotoTypeDtoOut>, Error>) -> Void) {
        guard let url = URL(string: "https://junior.balinasoft.com/api/v2/photo/type?page=\(page)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let page = try decoder.decode(Page<PhotoTypeDtoOut>.self, from: data)
                completion(.success(page))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func uploadPhoto(name: String, photoID: Int, image: UIImage, completion: @escaping (Result<PostResponse, Error>) -> Void) {
        guard let url = URL(string: "https://junior.balinasoft.com/api/v2/photo") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()

        // Формирование данных для отправки
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(name)\r\n".data(using: .utf8)!)
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            data.append(imageData)
        }
        
        data.append("\r\n".data(using: .utf8)!)
        
        // Добавляем typeId
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"typeId\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(photoID)\r\n".data(using: .utf8)!)
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let task = URLSession.shared.uploadTask(with: request, from: data) { (responseData, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
                }
                return
            }
            
            // Логируем статус и заголовки для отладки
            print("Response status code: \(httpResponse.statusCode)")
            let headers = httpResponse.allHeaderFields as? [String: String] ?? [:]
            print("Response headers: \(headers)")

            // Декодируем ответ
            do {
                let postResponse = try JSONDecoder().decode(PostResponse.self, from: responseData!)
                DispatchQueue.main.async {
                    completion(.success(postResponse)) // Успешная загрузка с данными ответа
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    private func fetchUpdatedData(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://junior.balinasoft.com/api/v2/photo/type") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // Декодирование обновленных данных
                let _ = try JSONDecoder().decode(Page<PhotoTypeDtoOut>.self, from: data)
                // Здесь вы можете обновить ваше состояние или модель в соответствии с новыми данными
                // Например, viewModel.photos = updatedData.content
                completion(.success(())) // Успешно обновили данные
            } catch {
                completion(.failure(error)) // Ошибка при декодировании
            }
        }.resume()
    }
}
