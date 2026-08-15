//
//  Player.swift
//  PokerCal
//
//  Created by Binh Huynh on 12/4/22.
//

import SwiftUI

struct BuyInEntry: Codable, Equatable {
    var amount: Int
    var timestamp: String
    
    static func == (lhs: BuyInEntry, rhs: BuyInEntry) -> Bool {
        return lhs.amount == rhs.amount &&
        lhs.timestamp == rhs.timestamp
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
        self.buyInHistory = buyInHistory.map { BuyInEntry(amount: $0, timestamp: String.currentTime) }
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
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.buyInHistory == rhs.buyInHistory
            && lhs.checkout == rhs.checkout
            && lhs.spent == rhs.spent
    }

    func misMatchAdjustment(groupWin: Int, groupLose: Int) -> CGFloat {
        switch (groupWin - abs(groupLose) > 0, winning) {
        // group win more than lose, winning
        case (true, true):
            let newGroupWin = abs(groupLose)
            return CGFloat(newGroupWin) * (CGFloat(current) / CGFloat(groupWin))
        // group win more than lose, losing
        case (true, false):
            return CGFloat(current)
        // group lose more than win, losing
        case (false, false):
            let newGroupLose = -groupWin
            return CGFloat(newGroupLose) * CGFloat(current) / CGFloat(groupLose)
        // group lose more than win, winning
        case (false, true):
            return CGFloat(current)
        }
    }
    
    func afterFood(groupSpent: Int, adjustedGroupWin: Int, adjustment: Int) -> CGFloat {
        let postMisMatchAdjustment = CGFloat(adjustment)
        guard adjustedGroupWin > 0 else { return postMisMatchAdjustment }

        let adjustedGroupWin = CGFloat(adjustedGroupWin)
        let groupSpent = CGFloat(groupSpent)
        let spent = CGFloat(spent)

        if adjustment > 0 {
            return postMisMatchAdjustment
                - (postMisMatchAdjustment / adjustedGroupWin) * groupSpent
                + spent
        }
        return postMisMatchAdjustment + spent
    }
}
