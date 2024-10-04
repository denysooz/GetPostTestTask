//
//  NetworkModel.swift
//  GetPostTestTask
//
//  Created by Denis Dareuskiy on 3.10.24.
//

import Foundation

struct PhotoDtoOut: Decodable {
    let id: String
}

struct PhotoTypeDtoOut: Decodable, Encodable, Equatable {
    let id: Int
    let name: String
    let image: String?
}

struct Page<T: Decodable>: Decodable { // Измените здесь
    let content: [T]
    let page: Int
    let pageSize: Int
    let totalElements: Int
    let totalPages: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode([T].self, forKey: .content)
        page = try container.decode(Int.self, forKey: .page)
        pageSize = try container.decode(Int.self, forKey: .pageSize)
        totalElements = try container.decode(Int.self, forKey: .totalElements)
        totalPages = try container.decode(Int.self, forKey: .totalPages)
    }
    
    private enum CodingKeys: String, CodingKey {
        case content, page, pageSize, totalElements, totalPages
    }
}
