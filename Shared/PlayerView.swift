//
//  Player.swift
//  PokerCal
//
//  Created by Binh Huynh on 12/4/22.
//

import SwiftUI

struct PlayerView: View {
    @Binding var player: Player
    @State private var input: String = ""
    @State private var inputType: InputType = .buy
    @FocusState var isFocused: Bool
    
    enum InputType: Int {
        case buy = 0
        case checkout = 1
        case spent = 2
    }
    
    private func delete(at offsets: IndexSet) {
        player.buyInHistory.remove(atOffsets: offsets)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            
            HStack {
                Text("\(player.name)")
                    .font(Font.largeTitle)
                    .bold()
                Spacer()
                Text("("+String(player.current)+")")
                    .font(Font.title2)
                    .foregroundStyle(player.winning ? Color.green : Color.red)
                    .opacity(0.8)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Buy In ")
                    Text(String(player.totalBuyIn))
                        .font(Font.title)
                        .background(Color.red)
                        .opacity(0.8)
                    Text("Check Out")
                    Text(String(player.checkout))
                        .font(Font.title)
                        .background(Color.green)
                        .opacity(0.8)
                    Spacer()
                    
                }
                HStack {
                    Text("Spent (food/drink)")
                    Text(String(player.spent))
                        .font(Font.title2)
                }
            }
            List() {
                ForEach(player.buyInHistory) { entry in
                    HStack {
                        Text("\(entry.amount)")
                        Spacer()
                        Text(entry.timestamp)
                    }
                }
                .onDelete(perform: delete)
            }
            Picker("Type of input", selection: $inputType) {
                Text("Buy").tag(InputType.buy)
                Text("Checkout").tag(InputType.checkout)
                Text("Spent").tag(InputType.spent)
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 15)

            HStack(spacing: 20) {
                TextField("", text: $input)
                    .frame(height: 56)
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0))
                    .focused($isFocused)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16).stroke(isFocused ? Color.blue : Color.gray, lineWidth: 1)
                    )
                    .numericKeyboard()
                    
                Button("Add") {
                    guard let newValue = Int(input) else { return }

                    // Only buy-in requires value > 0
                    if inputType == .buy && newValue <= 0 {
                        return
                    }

                    // Checkout and spent can be 0 or positive
                    if newValue < 0 {
                        return
                    }

                    let newEntry = BuyInEntry(amount: newValue)
                    switch inputType {
                    case .buy:
                        player.buyInHistory.insert(newEntry, at: 0)
                    case .checkout:
                        player.checkout = newValue
                    case .spent:
                        player.spent = newValue
                    }
                    input = ""
                }
                .font(.headline)
                .frame(width: 100, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .foregroundStyle(Color.red)
            }
        }
        .padding()
        .toolbar {
#if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button {
                        isFocused = false
                    } label: {
                        Text("Done")
                            .bold()
                    }
                }
            }
#endif
        }
    }
    
}

extension View {
    @ViewBuilder
    func numericKeyboard() -> some View {
#if os(iOS)
        keyboardType(.numberPad)
#else
        self
#endif
    }
}
