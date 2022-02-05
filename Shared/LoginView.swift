//
//  LoginView.swift
//  BewerberAufgabe
//
//  Created by Oliver Epper on 05.02.22.
//

import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @Binding var savedUsername: String

    var body: some View {
        VStack {
            if savedUsername.isEmpty {
                TextField("Username", text: $username)
                SecureField("Password", text: $password)

                Button("Login") {
                    guard !username.isEmpty else { return }
                    guard !password.isEmpty else { return }
                    savedUsername = username
                    KeychainWrapper.standard.set(username, forKey: ProcessInfo.processInfo.processName + "username")
                    KeychainWrapper.standard.set(password, forKey: ProcessInfo.processInfo.processName + "password")
                }
            } else {
                Button("Logout") {
                    KeychainWrapper.standard.set(username, forKey: ProcessInfo.processInfo.processName + "username")
                    KeychainWrapper.standard.removeObject(forKey: ProcessInfo.processInfo.processName + "password")
                    savedUsername = ""
                }
            }
        }
        .font(.title)
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(savedUsername: .constant(""))
    }
}
