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
    
    // mismatched after checkout
    // Positive: deficit i.e group win more than lose
    // Negative: surplus i.e group lose more than win
    private var groupDiff: Int {
        groupWin - abs(groupLose)
    }

    private func deleteUser(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
    }
    
    var body: some View {
        VStack(spacing: 10) {
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
                
                ForEach(players, id: \.name) { player in
                    HStack {
                        Text(String(player.name).fillSpace(limit: 5, alignment: .leading))
                            .bold()
                            .frame(width: 70)
                            .font(.system(size: 36, design: .monospaced))
                        
                        Group {
                            Text("\(player.totalBuyIn)".fillSpace(limit: 4))
                            Spacer()
                            Text("\(player.checkout)".fillSpace(limit: 4))
                            Spacer()
                            Text("\(player.current)".fillSpace(limit: 4))
                                .foregroundColor(player.winning ? Color.green : Color.red)
                            Spacer()
                            Text("\(player.misMatchAdjustment(groupWin: groupWin, groupLose: groupLose))".fillSpace(limit: 4))
                            Spacer()
                        }
                        .font(.system(size: 14, design: .monospaced))
                        
                            Text("\(player.afterFood(groupSpent: groupSpent, groupWin: groupWin, groupLose: groupLose))".fillSpace(limit: 5))
                                .bold()
                                .padding(.horizontal, 5)
                                .background(player.afterFood(groupSpent: groupSpent, groupWin: groupWin, groupLose: groupLose) > 0 ? Color.green : Color.red)
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
                .padding(.bottom, 10)
            }
            .listStyle(PlainListStyle())
            .border(isMismatched ? Color.red : Color.green, width: 2)
            .frame(minHeight: UIScreen.main.bounds.size.height * 0.55)
            
            HStack {
                Button {
                    isShowingResetAlert.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 65, height: 65)
                        Text("Reset")
                            .bold()
                            .foregroundColor(Color.white)
                    }
                }
                .alert("Are you sure to reset?", isPresented: $isShowingResetAlert) {
                    Button {
                        players = players.map { Player(name: $0.name) }
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
                            .frame(width: 150, height: 50)
                        Text("Add Player")
                            .foregroundColor(Color.white)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            
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
