//
//  Poll.swift
//  LivePolls
//
//  Created by Marcus Buexenstein on 2023/08/16.
//

import Foundation

struct Poll: Codable, Identifiable, Hashable {
    enum CodingKeys: CodingKey {
        case id, name, createdAt, updatedAt, lastUpdatedOptionId
    }
    
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var totalCount: Int {
        options.reduce(0) { $0 + $1.count }
    }
    var options: [Option] = []
    var lastUpdatedOptionId: UUID?
    var lastUpdatedOption: Option? {
        guard let lastUpdatedOptionId else { return nil }
        return options.first { $0.id == lastUpdatedOptionId }
    }
    
    init(
        id: UUID = UUID(),
        name: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        options: [Option] = [],
        lastUpdatedOptionId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.options = options
        self.lastUpdatedOptionId = lastUpdatedOptionId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.createdAt, forKey: .createdAt)
        try container.encode(self.updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(self.lastUpdatedOptionId, forKey: .lastUpdatedOptionId)
    }
    
    init(dictionary: [String: Any]) throws {
        let decoder = JSONDecoder.postgrest
        
        self = try decoder.decode(Poll.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}
