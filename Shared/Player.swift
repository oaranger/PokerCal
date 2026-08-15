//
//  Player.swift
//  PokerCal
//
//  Created by Binh Huynh on 12/4/22.
//

import Foundation

struct BuyInEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var amount: Int
    var timestamp: String

    init(
        id: UUID = UUID(),
        amount: Int,
        timestamp: String = Date().formatted(date: .omitted, time: .standard)
    ) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case id, amount, timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        amount = try container.decode(Int.self, forKey: .amount)
        timestamp = try container.decode(String.self, forKey: .timestamp)
    }
}

struct Player: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var buyInHistory: [BuyInEntry]
    var checkout: Int
    var spent: Int

    init(name: String, buyInHistory: [Int] = [50], checkout: Int = 0, spent: Int = 0) {
        self.name = name
        self.checkout = checkout
        self.spent = spent
        self.buyInHistory = buyInHistory.map { BuyInEntry(amount: $0) }
    }
    
    var totalBuyIn: Int {
        buyInHistory.map { $0.amount }.reduce(0, +)
    }
    
    var current: Int {
        checkout - totalBuyIn
    }
    
    var winning: Bool {
        current >= 0
    }
    
    mutating func reset() {
        buyInHistory = []
        checkout = 0
        spent = 0
    }
    
}
