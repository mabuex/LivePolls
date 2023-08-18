//
//  Option.swift
//  LivePolls
//
//  Created by Marcus Buexenstein on 2023/08/16.
//

import Foundation

struct Option: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var count: Int
    var pollId: UUID
    
    init(id: UUID = UUID(), name: String, count: Int = 0, pollId: UUID = UUID()) {
        self.id = id
        self.name = name
        self.count = count
        self.pollId = pollId
    }
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(Option.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}
