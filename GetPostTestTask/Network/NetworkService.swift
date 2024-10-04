//
//  Network.swift
//  GetPostTestTask
//
//  Created by Denis Dareuskiy on 3.10.24.
//

import Foundation

class NetworkService {
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
}
