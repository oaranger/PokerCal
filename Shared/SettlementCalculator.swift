import Foundation

struct SettlementResult {
    let adjustments: [UUID: Int]
    let finalValues: [UUID: Int]

    func adjustment(for player: Player) -> Int {
        adjustments[player.id] ?? player.current
    }

    func finalValue(for player: Player) -> Int {
        finalValues[player.id] ?? 0
    }
}

enum SettlementCalculator {
    static func calculate(players: [Player]) -> SettlementResult {
        let groupWin = players.lazy.filter(\.winning).map(\.current).reduce(0, +)
        let groupLose = players.lazy.filter { !$0.winning }.map(\.current).reduce(0, +)
        let isMismatched = players.lazy.map(\.current).reduce(0, +) != 0

        let adjustments: [UUID: Int]
        if isMismatched {
            let exactAdjustments = players.map { player in
                (
                    id: player.id,
                    value: mismatchAdjustment(
                        for: player,
                        groupWin: groupWin,
                        groupLose: groupLose
                    )
                )
            }
            adjustments = balancedRoundedValues(exactAdjustments)
        } else {
            adjustments = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0.current) })
        }

        let groupSpent = players.lazy.map { max(0, $0.spent) }.reduce(0, +)
        let adjustedGroupWin = adjustments.values.lazy.filter { $0 > 0 }.reduce(0, +)
        let playerCount = players.count

        let exactFinalValues = players.map { player in
            let adjustment = adjustments[player.id] ?? player.current
            let foodShare: Double

            if adjustedGroupWin > 0, adjustment > 0 {
                foodShare = Double(adjustment) / Double(adjustedGroupWin) * Double(groupSpent)
            } else if adjustedGroupWin == 0, playerCount > 0 {
                // With no winner, split food costs evenly so reimbursements still balance.
                foodShare = Double(groupSpent) / Double(playerCount)
            } else {
                foodShare = 0
            }

            return (
                id: player.id,
                value: Double(adjustment) - foodShare + Double(max(0, player.spent))
            )
        }

        return SettlementResult(
            adjustments: adjustments,
            finalValues: balancedRoundedValues(exactFinalValues)
        )
    }

    private static func mismatchAdjustment(
        for player: Player,
        groupWin: Int,
        groupLose: Int
    ) -> Double {
        let winnersHaveDeficit = groupWin > abs(groupLose)

        switch (winnersHaveDeficit, player.winning) {
        case (true, true):
            guard groupWin != 0 else { return 0 }
            return Double(abs(groupLose)) * Double(player.current) / Double(groupWin)
        case (true, false), (false, true):
            return Double(player.current)
        case (false, false):
            guard groupLose != 0 else { return 0 }
            return Double(-groupWin) * Double(player.current) / Double(groupLose)
        }
    }

    private static func balancedRoundedValues(
        _ exactValues: [(id: UUID, value: Double)]
    ) -> [UUID: Int] {
        let candidates = exactValues.enumerated().map { index, item in
            let lowerValue = Int((item.value / 5).rounded(.down)) * 5
            return (
                id: item.id,
                lowerValue: lowerValue,
                remainder: item.value - Double(lowerValue),
                order: index
            )
        }

        var values = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0.lowerValue) })
        let lowerTotal = candidates.lazy.map(\.lowerValue).reduce(0, +)
        let incrementsNeeded = min(candidates.count, max(0, -lowerTotal / 5))

        let rankedCandidates = candidates.sorted {
            if $0.remainder == $1.remainder {
                return $0.order < $1.order
            }
            return $0.remainder > $1.remainder
        }

        for candidate in rankedCandidates.prefix(incrementsNeeded) {
            values[candidate.id, default: candidate.lowerValue] += 5
        }

        return values
    }
}
