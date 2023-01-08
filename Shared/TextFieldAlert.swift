//
//  TextFieldAlert.swift
//  PokerCal
//
//  Created by Binh Huynh on 12/4/22.
//

import SwiftUI

struct TextFieldAlert<Presenting>: View where Presenting: View {

    @Binding var isShowing: Bool
    @Binding var players: [Player]
    
    @State private var name: String = ""
    @State private var buyIn: String = ""
    @State private var spent: String = ""
        
    let presenting: Presenting
    let title: String

    var body: some View {
        GeometryReader { (deviceSize: GeometryProxy) in
            ZStack {
                self.presenting
                    .disabled(isShowing)
                VStack(spacing: 12) {
                    Text(self.title)
                    Group {
                        TextField("Name", text: $name)
                        TextField("Buy In", text: $buyIn)
                        TextField("Spent", text: $spent)
                    }
                    .padding(.leading, 10)
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 0.5)
                    )
                    
                    HStack {
                        Button(action: {
                            self.isShowing.toggle()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(5.0)
                        }

                        Button(action: {
                            guard !name.isEmpty else { return }
                            var player = Player(name: name)
                            player.buyInHistory = [(Int(buyIn) ?? 0, String.currentTime)]
                            player.spent = Int(spent) ?? 0
                            players.insert(player, at: 0)
                            name = ""
                            buyIn = ""
                            spent = ""
                            self.isShowing.toggle()
                        }) {
                            Text("Add")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(5.0)
                        }
                    }
                }
                .padding()
                .font(Font.body.bold())
                .frame(
                    width: deviceSize.size.width*0.7,
                    height: 375
                )
                .shadow(radius: 1)
                .opacity(self.isShowing ? 1 : 0)
                .dimBG(condition: isShowing)
            }
        }
    }
}

extension View {
    func textFieldAlert(isShowing: Binding<Bool>,
                        players: Binding<[Player]>,
                        title: String) -> some View {
        TextFieldAlert(isShowing: isShowing,
                       players: players,
                       presenting: self,
                       title: title)
    }
}

extension View {
    @ViewBuilder
    func dimBG(condition: Bool) -> some View {
        if condition {
            ZStack {
                Color.black
                    .opacity(0.5)
                    .onTapGesture {
                        hideKeyboard()
                    }
                self
                    .background(Color.white)
                    .cornerRadius(16)
            }
        } else {
            self
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
