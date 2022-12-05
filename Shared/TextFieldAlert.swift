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
                    .frame(height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 0.5)
                    )
                    
                    
                    Divider()
                    
                    HStack(alignment: .center) {
                        Button(role: .cancel, action: {
                            withAnimation {
                                self.isShowing.toggle()
                            }
                        }) {
                            Text("Cancel").padding(.horizontal)
                        }
                        
                        Divider().padding(.horizontal)
                        
                        Button(action: {
                            withAnimation {
                                var player = Player(name: name)
                                player.buyInHistory = [(Int(buyIn) ?? 0, String.currentTime)]
                                player.spent = Int(spent) ?? 0
                                players.insert(player, at: 0)
                                name = ""
                                buyIn = ""
                                spent = ""
                                self.isShowing.toggle()
                            }
                        }) {
                            Text("Add").padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .font(Font.body.bold())
                .background(Color(#colorLiteral(red: 0.2025598161, green: 0.1036325959, blue: 0.5211219394, alpha: 1)))
                .frame(
                    width: deviceSize.size.width*0.7,
                    height: 250
                )
                .shadow(radius: 1)
                .opacity(self.isShowing ? 1 : 0)
                
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
