//
//  ContentView.swift
//  Shared
//
//  Created by Binh Huynh on 12/3/22.
//

import SwiftUI

struct ContentView: View {
    @State private var players: [Player] = [
        Player(name: "Binh", buyInHistory: [50,100], checkout: 120, spent: 20),
        Player(name: "Hieu", buyInHistory: [100], checkout: 120),
        Player(name: "Taii", checkout: 150, spent: 30),
        Player(name: "Hoang", buyInHistory: [50,50], checkout: 50, spent: 10),
        Player(name: "Dooo", buyInHistory: [100, 100], checkout: 350),
        Player(name: "Long", buyInHistory: [50,50], spent: 0)
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
                HStack(spacing: 6) {
                    Text("Name")
                        .frame(width: 70)
                    Text("Innn")
                    Text("Outt")
                    Text("Diff")
                    Text("Adjust")
                    Text("Food")
                }
                .font(Font.body.bold())
                .background(Color.yellow)
                
                ForEach(players, id: \.name) { player in
                    HStack {
                        Text(player.name)
                            .bold()
                            .frame(width: 70)
                        Text("\(player.totalBuyIn)")
                        Spacer()
                        Text("\(player.checkout)")
                        Spacer()
                        Text("\(player.current)")
                            .foregroundColor(player.winning ? Color.green : Color.red)
                        Spacer()
                        Text("\(player.misMatchAdjustment(groupWin: groupWin, groupLose: groupLose))")
                        Spacer()
                        Text("\(player.afterFood(groupSpent: groupSpent, groupWin: groupWin, groupLose: groupLose))")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPlayer = player
                        showingSheet = true
                    }
                }
                .onDelete(perform: deleteUser)
            }
            .border(isMismatched ? Color.red : Color.green, width: 2)
            .padding(5)
            
            .frame(minHeight: UIScreen.main.bounds.size.height * 0.55)
            .padding(.bottom, 60)
            .addToBottom {
                HStack {
                    Button {
                        isShowingResetAlert.toggle()
                    } label: {
                        Text("Reset")
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
                        Text("Add Player")
                    }
                }
            }
            
            HStack {
                Text("Win \(groupWin)").background(Color.green)
                Text("Lose \(groupLose)").background(Color.red)
                if isMismatched {
                    if groupWin > abs(groupLose) {
                        Text("Deficit \(groupWin - abs(groupLose))").bold().border(Color.red)
                    } else {
                        Text("Surplus \(abs(groupLose) - groupWin)").bold().border(Color.red)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Food/Drink")
                List {
                    ForEach(players, id:\.name) { player in
                        if player.spent > 0 {
                            HStack {
                                Text("\(player.name)")
                                Spacer()
                                Text("\(player.spent)")
                            }
                        }
                    }
                }
            }
            .padding(2)
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

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}




