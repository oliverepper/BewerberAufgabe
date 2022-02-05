//
//  ContentView.swift
//  Shared
//
//  Created by Oliver Epper on 03.02.22.
//

import SwiftUI


struct ContentView: View {
    @AppStorage("username") private var savedUsername = ""

    var body: some View {
        if savedUsername.isEmpty {
            LoginView(savedUsername: $savedUsername)
        } else {
            TabView {
                DialView()
                    .tabItem {
                        Image(systemName: "phone")
                        Text("Dial")
                    }
                AddressBookView()
                    .tabItem {
                        Image(systemName: "book")
                        Text("Address Book")
                    }
                LoginView(savedUsername: $savedUsername)
                    .tabItem {
                        Image(systemName: "lock")
                        Text("Login")
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
