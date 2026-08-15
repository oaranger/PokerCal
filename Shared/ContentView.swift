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

struct ContentView: View {
    @State private var players: [Player] = []
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
    
    private var groupWin: Int {
        players.lazy.filter(\.winning).map(\.current).reduce(0, +)
    }
    
    private var groupLose: Int {
        players.lazy.filter { !$0.winning }.map(\.current).reduce(0, +)
    }
    
    private var isMismatched: Bool {
        players.lazy.map(\.current).reduce(0, +) != 0
    }
    
    private var shouldShownFoodSection: Bool {
        for player in players {
            if player.spent > 0 {
                return true
            }
        }
        return false
    }
    
    private func deleteUser(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
    }
    
    var body: some View {
        let settlement = SettlementCalculator.calculate(players: players)

        VStack(spacing: 0) {
            Label("Today: \(currentDate)", systemImage: "calendar")
            List {
                HStack(spacing: 0) {
                    Text("Name")
                        .bold()
                        .frame(width: 70)
                    Text("Innn")
                        .padding(.leading, 10)
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
                    HStack(spacing: 0) {
                        Text(String(player.name).fillSpace(limit: 5, alignment: .leading))
                            .bold()
                            .frame(width: 70)
                            .font(.system(size: 20, design: .monospaced))

                        Group {
                            Text("\(player.totalBuyIn)".fillSpace(limit: 4))
                                .padding(.leading, 10)
                            Spacer()
                            Text("\(player.checkout)".fillSpace(limit: 4))
                            Spacer()
                            if isMismatched || shouldShownFoodSection {
                                Text("\(player.current)".fillSpace(limit: 4))
                                    .foregroundStyle(player.winning ? Color.green : Color.red)
                            } else {
                                Text("_".fillSpace(limit: 4))
                            }
                            Spacer()
                            if isMismatched {
                                Text("\(settlement.adjustment(for: player))".fillSpace(limit: 4))
                            } else {
                                Text("_".fillSpace(limit: 4))
                            }
                            Spacer()
                        }
                        .font(.system(size: 14, design: .monospaced))

                        Text("\(settlement.finalValue(for: player))".fillSpace(limit: 5))
                            .bold()
                            .padding(.horizontal, 5)
                            .background(settlement.finalValue(for: player) > 0 ? Color.green : Color.red)
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
                                .foregroundStyle(.orange)
                            Text("Total = \(players.map { $0.spent }.reduce(0, +))")
                        }
                        .frame(maxWidth: .infinity)
                        Divider()
                        VStack(alignment: .leading) {
                            ForEach(players) { player in
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
            .listStyle(.plain)
            .border(isMismatched ? Color.red : Color.green, width: 2)
            
            HStack {
                Button("Reset", systemImage: "arrow.counterclockwise") {
                    isShowingResetAlert.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .frame(width: 150, height: 45)
                .alert("Are you sure to reset?", isPresented: $isShowingResetAlert) {
                    Button {
                        for index in players.indices {
                            players[index].reset()
                        }
                    } label: {
                        Text("OK")
                    }
                    Button("Cancel", role: .cancel) {
                    }
                }
                
                Spacer()

                Button("Add Player", systemImage: "person.badge.plus") {
                    isAddingPlayer.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .frame(width: 150, height: 45)
            }
            .padding(.top, 10)
            .padding(.horizontal, 40)
            
        }
        .sheet(isPresented: $showingSheet) {
            print("Dismissing...")
            if let index = players.firstIndex(where: { $0.id == selectedPlayer.id }) {
                players[index] = selectedPlayer
            }
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

struct TextDecor: ViewModifier {
  let color: Color
  func body(content: Content) -> some View {
    content
      .padding(4)
      .background(color.opacity(0.2))
      .cornerRadius(8)
      .foregroundStyle(color)
      .font(.title3)
      .frame(maxWidth: .infinity)
      .fixedSize()
  }
}
