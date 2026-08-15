//
//  ContentView.swift
//  Shared
//
//  Created by Binh Huynh on 12/3/22.
//

import SwiftUI

extension String {
    func fillSpace(limit: Int, alignment: Alignment = .trailing) -> Self {
        if limit > count {
            let arraySpace = Array(repeating: " ", count: limit - count).joined()
            if alignment == .trailing {
                return "\(arraySpace)" + self
            } else {
                return self + "\(arraySpace)"
            }
        }
        return self
    }
}

extension View {
    @ViewBuilder
    func monoFontSpace() -> some View {
        if #available(iOS 16, *) {
            self
                .monospaced()
        } else {
            self
        }
    }
}

struct ContentView: View {
    @State private var players: [Player] = [
        Player(name: "Binh", buyInHistory: [50,100], checkout: 120, spent: 20),
        Player(name: "Hieu", buyInHistory: [100], checkout: 120),
        Player(name: "Tai", checkout: 150, spent: 30),
        Player(name: "Hoang", buyInHistory: [50,50], checkout: 50, spent: 10),
        Player(name: "Do", buyInHistory: [100, 100], checkout: 350),
        Player(name: "Long", buyInHistory: [50,50], spent: 5)
    ]
    @State private var showingSheet = false
    @State private var selectedPlayer: Player = Player(name: "random")
    @State private var isAddingPlayer: Bool = false
    @State private var isShowingResetAlert: Bool = false
    
    init() {
        _players = State(initialValue: Self.loadPlayers())
    }
    
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // Example: Mar 1, 2025
        formatter.timeStyle = .none    // Only show the date, not time
        return formatter.string(from: Date())
    }
    
    private var groupSpent: Int {
        players.filter { $0.spent > 0 }.map { Int($0.spent) }.reduce(0,+)
    }
    
    private var groupWin: Int {
        players.filter { $0.winning }.map { $0.current }.reduce(0,+)
    }
    
    private var groupLose: Int {
        players.filter { !$0.winning }.map { $0.current }.reduce(0, +)
    }
    
    private var isMismatched: Bool {
        players.map { $0.current }.reduce(0,+) != 0
    }
    
    private var groupDeficit: Int {
        groupWin - abs(groupLose)
    }
    
    private var groupSurplus: Int {
        return 0
    }
    
    private var shouldShownFoodSection: Bool {
        for player in players {
            if player.spent > 0 {
                return true
            }
        }
        return false
    }
    
    // mismatched after checkout
    // Positive: deficit i.e group win more than lose
    // Negative: surplus i.e group lose more than win
    private var groupDiff: Int {
        groupWin - abs(groupLose)
    }

    private func balancedRoundedValues(
        _ exactValues: [(id: UUID, value: CGFloat)]
    ) -> [UUID: Int] {
        let candidates = exactValues.enumerated().map { index, item in
            let lowerValue = Int((item.value / 5).rounded(.down)) * 5
            return (
                id: item.id,
                lowerValue: lowerValue,
                remainder: item.value - CGFloat(lowerValue),
                order: index
            )
        }

        var values = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0.lowerValue) })
        let lowerTotal = candidates.reduce(0) { $0 + $1.lowerValue }
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

    private var mismatchAdjustments: [UUID: Int] {
        guard isMismatched else { return [:] }

        let exactAdjustments = players.map { player in
            (
                id: player.id,
                value: player.misMatchAdjustment(groupWin: groupWin, groupLose: groupLose)
            )
        }
        return balancedRoundedValues(exactAdjustments)
    }

    private func adjustment(for player: Player) -> Int {
        guard isMismatched else { return player.current }
        return mismatchAdjustments[player.id] ?? player.current
    }

    private var finalValues: [UUID: Int] {
        let adjustedGroupWin = players.reduce(0) { total, player in
            total + max(0, adjustment(for: player))
        }
        let exactFinalValues = players.map { player in
            let valueAfterFood = player.afterFood(
                groupSpent: groupSpent,
                adjustedGroupWin: adjustedGroupWin,
                adjustment: adjustment(for: player)
            )
            return (id: player.id, value: valueAfterFood)
        }
        return balancedRoundedValues(exactFinalValues)
    }

    private func finalValue(for player: Player) -> Int {
        finalValues[player.id] ?? 0
    }

    private func deleteUser(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Label("Today: \(currentDate)", systemImage: "calendar")
            List {
                HStack() {
                    Text("Name")
                        .bold()
                        .frame(width: 70)
                    Text("Innn")
                    Spacer()
                    Text("Outt")
                    Spacer()
                    Text("Diff")
                    Spacer()
                    Text("Adju")
                    Spacer()
                    Text("Final")
                }
                .font(.system(size: 16, design: .monospaced))
                .background(Color.yellow)
                
                ForEach(players) { player in
                    HStack {
                        Text(String(player.name).fillSpace(limit: 5, alignment: .leading))
                            .bold()
                            .frame(width: 70)
                            .font(.system(size: 20, design: .monospaced))
                        
                        Group {
                            Text("\(player.totalBuyIn)".fillSpace(limit: 4))
                            Spacer()
                            Text("\(player.checkout)".fillSpace(limit: 4))
                            Spacer()
                            if isMismatched {
                                Text("\(player.current)".fillSpace(limit: 4))
                                    .foregroundColor(player.winning ? Color.green : Color.red)
                                Spacer()
                                Text("\(adjustment(for: player))".fillSpace(limit: 4))
                                Spacer()
                            } else {
                                Text("_".fillSpace(limit: 4))
                                Spacer()
                                Text("_".fillSpace(limit: 4))
                                Spacer()
                            }
                        }
                        .font(.system(size: 14, design: .monospaced))
                        
                            Text("\(finalValue(for: player))".fillSpace(limit: 5))
                                .bold()
                                .padding(.horizontal, 5)
                                .background(finalValue(for: player) > 0 ? Color.green : Color.red)
                                .cornerRadius(4)
                                .fixedSize()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPlayer = player
                        showingSheet = true
                    }
                }
                .onDelete(perform: deleteUser)
                
                if shouldShownFoodSection {
                    HStack() {
                        HStack {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Total = \(players.map { $0.spent }.reduce(0, +))")
                        }
                        .frame(maxWidth: .infinity)
                        Divider()
                        VStack(alignment: .leading) {
                            ForEach(players, id:\.name) { player in
                                if player.spent > 0 {
                                    Text("\(player.name) \(player.spent)")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(2)
                }
                
                HStack {
                    Spacer()
                    Text("Win \(groupWin)")
                        .modifier(TextDecor(color: .green))

                    Text("Lose \(groupLose)")
                        .modifier(TextDecor(color: .pink))
                    
                    if isMismatched {
                        if groupWin > abs(groupLose) {
                            Text("Deficit \(groupWin - abs(groupLose))")
                                .bold()
                                .modifier(TextDecor(color: .red))
                        } else {
                            Text("Surplus \(abs(groupLose) - groupWin)")
                                .bold()
                                .modifier(TextDecor(color: .red))
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 5)
            }
            .listStyle(PlainListStyle())
            .border(isMismatched ? Color.red : Color.green, width: 2)
            .frame(minHeight: UIScreen.main.bounds.size.height * 0.5)
            
            HStack {
                Button {
                    isShowingResetAlert.toggle()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                            .fill(Color.red)
                            .frame(width: 150, height: 45)
                        Text("Reset")
                            .foregroundColor(Color.white)
                    }
                }
                .alert("Are you sure to reset?", isPresented: $isShowingResetAlert) {
                    Button {
                        players = players.map { Player(name: $0.name, buyInHistory: []) }
                    } label: {
                        Text("OK")
                    }
                    Button("Cancel", role: .cancel) {
                    }
                }
                
                Spacer()
                
                Button {
                    isAddingPlayer.toggle()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
                            .fill(Color.blue)
                            .frame(width: 150, height: 45)
                        Text("Add Player")
                            .foregroundColor(Color.white)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 40)
            
        }
        .sheet(isPresented: $showingSheet) {
            print("Dismissing...")
            let index = players.firstIndex { player in
                player.name == selectedPlayer.name
            } ?? 0
            players[index] = selectedPlayer
        } content: {
            VStack {
                PlayerView(player: self.$selectedPlayer)
                Button("Dismiss") {
                    showingSheet.toggle()
                }
                .padding(.bottom)
                .font(Font.largeTitle)
            }
        }
        .opacity(isAddingPlayer ? 0.2 : 1)
        .textFieldAlert(isShowing: $isAddingPlayer, players: $players, title: "Add a player")
        .onChange(of: players) { _ in
            savePlayers()
        }
    }
    
    // ** Save players to UserDefaults **
    func savePlayers() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(players) {
            UserDefaults.standard.set(encoded, forKey: "savedPlayers")
        }
    }
    
    // ** Load players from UserDefaults **
    static func loadPlayers() -> [Player] {
        if let savedData = UserDefaults.standard.data(forKey: "savedPlayers") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([Player].self, from: savedData) {
                return decoded
            }
        }
        return []
    }
}

extension View {
    func addToBottom<Content: View>(content: () -> Content) -> some View {
        ZStack(alignment: .bottom) {
            self
            content()
                .padding()
        }
    }
}


struct TextDecor: ViewModifier {
  let color: Color
  func body(content: Content) -> some View {
    content
      .padding(4)
      .background(color.opacity(0.2))
      .cornerRadius(8)
      .foregroundColor(color)
      .font(.title3)
      .frame(maxWidth: .infinity)
      .fixedSize()
  }
}
