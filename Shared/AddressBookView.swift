//
//  AddressBookView.swift
//  BewerberAufgabe
//
//  Created by Oliver Epper on 03.02.22.
//

import SwiftUI

final class API {
    private var token: Token?

    lazy var decoder: JSONDecoder = {
        var decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    struct Token: Codable {
        let accessToken: String
    }

    struct Credentials: Codable {
        var username: String
        var password: String
    }

    static func contacts(token: Token, page: Int) async throws -> ([AddressBookEntry], Token) {
        let (contacts, response) = try await URLSession.shared.data(for: Self.contactsRequest(token: token.accessToken, page: page))
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            guard let username = KeychainWrapper.standard.string(forKey: ProcessInfo.processInfo.processName + "username"),
                  let password = KeychainWrapper.standard.string(forKey: ProcessInfo.processInfo.processName + "password") else {
                      throw CancellationError()
                  }
            let (tokenData, _) = try await URLSession.shared.data(for: Self.loginRequest(username: username, password: password))
            let token = try? API().decoder.decode(Token.self, from: tokenData)
            guard let token = token else {
                throw CancellationError()
            }
            return try await API.contacts(token: token, page: page)
        }
        do {
            let loaded = try API().decoder.decode(ContactsList.self, from: contacts)
            return (loaded.data, token)
        } catch {
            print(error)
        }
        return ([], token)
    }

    static func searchName(token: Token, name: String) async throws -> ([AddressBookEntry], Token) {
        let (contacts, response) = try await URLSession.shared.data(for: Self.searchNameRequest(token: token.accessToken, name: name))
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            guard let username = KeychainWrapper.standard.string(forKey: ProcessInfo.processInfo.processName + "username"),
                  let password = KeychainWrapper.standard.string(forKey: ProcessInfo.processInfo.processName + "password") else {
                      throw CancellationError()
                  }
            let (tokenData, _) = try await URLSession.shared.data(for: Self.loginRequest(username: username, password: password))
            let token = try? API().decoder.decode(Token.self, from: tokenData)
            guard let token = token else {
                throw CancellationError()
            }
            return try await API.searchName(token: token, name: name)
        }
        do {
            let loaded = try API().decoder.decode([AddressBookEntry].self, from: contacts)
            print(loaded)
            return (loaded, token)
        } catch {
            print(error.localizedDescription)
        }
        return ([], token)
    }

    static func searchNumber(token: Token, number: String) async throws -> ([AddressBookEntry], Token) {
        let (contacts, response) = try await URLSession.shared.data(for: Self.searchNameRequest(token: token.accessToken, number: number))
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            guard let username = KeychainWrapper.standard.string(forKey: ProcessInfo.processInfo.processName + "username"),
                  let password = KeychainWrapper.standard.string(forKey: ProcessInfo.processInfo.processName + "password") else {
                      throw CancellationError()
                  }
            let (tokenData, _) = try await URLSession.shared.data(for: Self.loginRequest(username: username, password: password))
            let token = try? API().decoder.decode(Token.self, from: tokenData)
            guard let token = token else {
                throw CancellationError()
            }
            return try await API.searchNumber(token: token, number: number)
        }
        do {
            let loaded = try API().decoder.decode([AddressBookEntry].self, from: contacts)
            print(loaded)
            return (loaded, token)
        } catch {
            print(error.localizedDescription)
        }
        return ([], token)
    }

    static private func loginRequest(username: String, password: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://starface.jamalu.de/api/login")!)
        request.allHTTPHeaderFields = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(Credentials(username: username, password: password))
        return request
    }

    static private func contactsRequest(token: String, page: Int) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "starface.jamalu.de"
        components.path = "/api/contacts"
        let queryItems = URLQueryItem(name: "page", value: page.description)
        components.queryItems = [queryItems]
        guard let url = components.url else { fatalError() }
        print(url)
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [
            "Accept": "application/json",
            "Authorization": "Bearer \(token)"
        ]
        request.httpMethod = "GET"
        return request
    }

    static private func searchNameRequest(token: String, name: String) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "starface.jamalu.de"
        components.path = "/api/contacts/search"
        let queryItems = URLQueryItem(name: "name", value: name)
        components.queryItems = [queryItems]
        guard let url = components.url else { fatalError() }
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [
            "Accept": "application/json",
            "Authorization": "Bearer \(token)"
        ]
        request.httpMethod = "GET"
        return request
    }

    static private func searchNameRequest(token: String, number: String) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "starface.jamalu.de"
        components.path = "/api/contacts/search"
        let queryItems = URLQueryItem(name: "phone_number", value: number)
        components.queryItems = [queryItems]
        guard let url = components.url else { fatalError() }
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [
            "Accept": "application/json",
            "Authorization": "Bearer \(token)"
        ]
        request.httpMethod = "GET"
        return request
    }
}

struct ContactsList: Codable {
    let data: [AddressBookEntry]
}

struct AddressBookEntry: Codable, Equatable, Hashable {
    let id: Int
    let firstName: String
    let lastName: String
    let phoneNumber: String

    func matches(query: String) -> Bool {
        let substrings = query.split(separator: " ")
        var matches = false
        substrings.forEach { queryPart in
            matches = self.firstName.contains(queryPart) || self.lastName.contains(queryPart) || self.phoneNumber.contains(queryPart)
        }
        return matches
    }
}

struct EntryView: View {
    var entry: AddressBookEntry

    var body: some View {
        VStack {
            HStack {
                Text(entry.firstName + " " + entry.lastName)
                Spacer()
            }
            HStack {
                Spacer()
                Text(entry.phoneNumber).font(.system(.subheadline, design: .monospaced))
            }
        }
        .font(.title)
        .padding()
    }
}

struct AddressBookView: View {
    @State private var searchText = ""
    @State private var entries: [AddressBookEntry] = []
    @State private var currentPage = 1
    @State private var token = API.Token(accessToken: .init())

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(searchResults, id: \.id) { entry in
                        EntryView(entry: entry).onAppear { appear(entry) }
                    }
                }
                .listStyle(.plain)
                HStack {
                    Spacer()
                    Text("Loaded: \(entries.count)")
                }
                .font(.caption)
                .padding()
            }
            .navigationTitle("Address Book")
        }
        .searchable(text: $searchText)
        .onAppear {
            loadPage(currentPage)
        }
        .onChange(of: searchText) { query in
            if query.isEmpty {
                entries = []
                loadPage(1)
            }
            if query.count > 2 {
                search(query)
            }
        }
    }

    private var searchResults: [AddressBookEntry] {
        if searchText.isEmpty {
            return entries
        } else {
            return entries.filter { $0.matches(query: searchText) }
        }
    }

    private func appear(_ entry: AddressBookEntry) {
        guard entries.count > 10 else { return }
        guard searchText.isEmpty else { return }
        if entries[entries.index(entries.endIndex, offsetBy: -10)] == entry {
            loadPage(currentPage + 1)
        }
    }

    private func loadPage(_ page: Int) {
        Task {
            do {
                let (loaded, token) = try await API.contacts(token: token, page: page)
                self.entries += loaded
                self.token = token
                self.currentPage = page
            } catch {
                print(error)
            }
        }
    }

    private func search(_ query: String) {
        Task {
            do {
                let (loadedNames, token) = try await API.searchName(token: token, name: query)
                let (loadedNumbers, _) = try await API.searchNumber(token: token, number: query)
                self.token = token
                guard query == searchText else { return }
                self.entries = loadedNames + loadedNumbers
            } catch {
                print(error)
            }
        }
    }
}

struct AddressBookView_Previews: PreviewProvider {
    static var previews: some View {
        AddressBookView()
    }
}
