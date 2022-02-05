//
//  DialView.swift
//  BewerberAufgabe
//
//  Created by Oliver Epper on 03.02.22.
//

import SwiftUI

enum ButtonState {
    case pressed
    case notPressed
}

struct PressedModifier: ViewModifier {
    @GestureState private var isPressed = false
    let changeState: (ButtonState) -> Void

    init(changeState: @escaping (ButtonState) -> Void) {
        self.changeState = changeState
    }

    func body(content: Content) -> some View {
        let drag = DragGesture(minimumDistance: 0)
            .updating($isPressed) { value, gestureState, transition in
                gestureState = true
            }

        return content
            .gesture(drag)
            .onChange(of: isPressed) { pressed in
                if pressed {
                    self.changeState(.pressed)
                } else {
                    self.changeState(.notPressed)
                }
            }
    }
}
struct DialPadButton<T>: View where T: View {
    @State private var pressed = false
    var key: String
    var caption: T?
    var border = true
    var action: ((String, Bool) -> Void)? = { _, _ in }

    var body: some View {
        ZStack {
            if border {
                RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor)
            }
            if caption == nil {
                VStack {
                    Text(key)
                }
            } else {
                caption
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .modifier(PressedModifier(changeState: { (state) in
            print(state)
            if state == .pressed {
                pressed = true
            } else {
                withAnimation(.easeOut(duration: 0.1)) {
                    pressed = false
                }
            }
        }))
        .simultaneousGesture(LongPressGesture().onEnded { _ in
            action?(key, true)
        })
        .simultaneousGesture(TapGesture().onEnded { _ in
            action?(key, false)
        })
        .scaleEffect(pressed ? 0.9 : 1)
    }
}

extension DialPadButton where T == VStack<Text> {
    init(key: String, action: @escaping (String, Bool) -> Void) {
        self.key = key
        self.action = action
        self.caption = VStack {
            Text(key)
        }
    }

}

struct DialPad: View {
    @Binding var number: String

    var body: some View {
        VStack {
            row(keys: "1","2","3")
            row(keys: "4","5","6")
            row(keys: "7","8","9")
            row(keys: "-","0","⌫")
        }
    }

    private func row(keys: String...) -> some View {
        HStack {
            ForEach(keys, id:\.self) { key in
                if key == "0" {
                    DialPadButton(key: key, caption: VStack {
                        Text(key)
                        Text("+").font(.subheadline)
                    }, action: press(key:longPress:))
                } else {
                    DialPadButton(key: key, action: press(key:longPress:))
                }
            }
        }
    }

    private func press(key: String, longPress: Bool) {
        switch (key, longPress) {
        case ("⌫", false):
            if number.count > 0 {
                number.removeLast()
            }
        case ("⌫", true):
            number = ""
        case ("0", false):
            if number == "0" {
                number = "+"
            } else {
                number += "0"
            }
        case ("0", true):
            number += "+"
        default:
            number += key
        }
    }
}

struct DialView: View {
    @State private var number = ""
    @State private var name = ""
    @State private var token = API.Token(accessToken: .init())

    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack {
                    ZStack {
                        Text("+4915123595397").foregroundColor(.clear)
                        Text(number)
                    }
                    ZStack {
                        Text("Oliver Epper").foregroundColor(.clear)
                        Text(name)
                    }.font(.subheadline)

                }
                Spacer()
            }
            DialPad(number: $number)
                .padding()
            DialPadButton(key: "key", caption: Image(systemName: "phone").scaleEffect(1.2777), border: false) { _, _ in if number.count > 0 { dial() } }
                .padding()
        }
        .onChange(of: number, perform: { number in
            if number.count > 4 {
                search(number)
            }
        })
        .font(.largeTitle)
        .padding()
    }

    private func dial() {
        print("Dialing \(number)", terminator: "")
        if name.count > 0 {
            print(" to reach \(name)")
        } else {
            print()
        }
    }

    private func search(_ query: String) {
        Task {
            do {
                let (entries, token) = try await API.searchNumber(token: token, number: query)
                self.token = token
                guard number == query else { return }
                guard entries.first?.phoneNumber == query else {
                    self.name = ""
                    return
                }
                self.name = [entries.first?.firstName, entries.first?.lastName].compactMap { $0 }.joined()
            } catch {
                print(error)
            }
        }
    }
}

struct DialView_Previews: PreviewProvider {
    static var previews: some View {
        DialView()
    }
}
