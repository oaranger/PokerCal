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
    @State private var validationMessage: String?
    @FocusState private var focusedField: Field?
        
    let presenting: Presenting
    let title: String

    private enum Field {
        case name, buyIn, spent
    }

    private func resetForm() {
        name = ""
        buyIn = ""
        spent = ""
        validationMessage = nil
        focusedField = nil
    }

    private func addPlayer() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "Enter a player name."
            return
        }

        guard let buyInAmount = buyIn.isEmpty ? 0 : Int(buyIn), buyInAmount >= 0 else {
            validationMessage = "Buy-in must be zero or a positive whole number."
            return
        }

        guard let spentAmount = spent.isEmpty ? 0 : Int(spent), spentAmount >= 0 else {
            validationMessage = "Spent must be zero or a positive whole number."
            return
        }

        players.insert(
            Player(
                name: trimmedName,
                buyInHistory: [buyInAmount],
                spent: spentAmount
            ),
            at: 0
        )
        resetForm()
        isShowing = false
    }

    var body: some View {
        GeometryReader { (deviceSize: GeometryProxy) in
            ZStack {
                self.presenting
                    .disabled(isShowing)
                VStack(spacing: 12) {
                    Text(self.title)
                    TextField("Name", text: $name)
                        .focused($focusedField, equals: .name)
                        .textFieldStyle(.roundedBorder)
                    TextField("Buy In", text: $buyIn)
                        .focused($focusedField, equals: .buyIn)
                        .numericKeyboard()
                        .textFieldStyle(.roundedBorder)
                    TextField("Spent", text: $spent)
                        .focused($focusedField, equals: .spent)
                        .numericKeyboard()
                        .textFieldStyle(.roundedBorder)

                    if let validationMessage {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                    
                    HStack {
                        Button(action: {
                            resetForm()
                            self.isShowing = false
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(5.0)
                        }

                        Button(action: {
                            addPlayer()
                        }) {
                            Text("Add")
                                .font(.headline)
                                .foregroundStyle(.white)
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
                .background(Color.gray)
                .dimBG(condition: isShowing)
                .visible(when: isShowing)
            }
        }
    }
}

extension View {
    func textFieldAlert(
        isShowing: Binding<Bool>,
        players: Binding<[Player]>,
        title: String
    ) -> some View {
        TextFieldAlert(
            isShowing: isShowing,
            players: players,
            presenting: self,
            title: title
        )
    }
}

extension View {
    @ViewBuilder
    func dimBG(condition: Bool) -> some View {
        if condition {
            ZStack {
                Color.black
                    .opacity(0.2)
                self
                    .background(Color.white)
                    .cornerRadius(16)
            }
        } else {
            self
        }
    }
}

struct ConditionalVisibilityModifier: ViewModifier {
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        Group {
            if isVisible {
                content
            } else {
                content.hidden()
            }
        }
    }
}

extension View {
    func visible(when isVisible: Bool) -> some View {
        modifier(ConditionalVisibilityModifier(isVisible: isVisible))
    }
}
