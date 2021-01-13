//
//  SwiftUIView.swift
//  Combine Tutorial
//
//  Created by Tariq Almazyad on 1/13/21.
//

import SwiftUI
import Combine

struct SwiftUIView: View {
    @StateObject private var viewModel = NetworkingViewModel()
    var body: some View {
        List(viewModel.user) { user in
            Text(user.login)
        }.alert(item: $viewModel.alertItem) { alertItem in
            Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}

struct UserObject: Codable, Identifiable {
    let login: String
    let id: Int
//    let username: String
}


final class NetworkingViewModel: ObservableObject{
    
    private var anyCancellable = Set<AnyCancellable>()
    @Published var alertItem: AlertItem?
    @Published var user = [UserObject]()
    
    
    init() {
        func request() {
            let url = URL(string: "https://api.github.com/users")!
        }
    }
    
    /*
     URLSession.shared.dataTaskPublisher(for: url)
     .compactMap{
             if let response =  ($0.response as? HTTPURLResponse)?.statusCode, response >= 400 {
                 print("Bad url \(response)")
                 return Data()
             }
             return $0.data
         }
         .decode(type: [UserObject].self, decoder: JSONDecoder())
         .replaceError(with: [.init(login: "There are no users", id: 0, username: "")])
         .receive(on: RunLoop.main)
         .eraseToAnyPublisher()
     .assign(to: \.user, on: self)
     .store(in: &anyCancellable)
     */
}

enum FailureReason: Error {
    case sessionFailed(error: URLError)
    case decodingFailed
    case other(Error)
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: Text
    let message: Text
    let dismissButton: Alert.Button
}

struct AlertContext {

    static let invalidURL = AlertItem(title: Text("Server Error"),
                                      message: Text("URL is not valid for request.\nPlease report this bug to the developer."),
                                      dismissButton: .default(Text("Ok")))
    static let invalidResponse = AlertItem(title: Text("Server Error"),
                                           message: Text("Invalid response from the server. Please try again later or contact the developer."),
                                           dismissButton: .default(Text("Ok")))
    static let connectionError = AlertItem(title: Text("Connection Error"),
                                           message: Text("Please check your connection and try again.\nIf this issue persists, please report it to the developer"),
                                           dismissButton: .default(Text("Ok")))
    static let invalidJSON = AlertItem(title: Text("Server Error"),
                                       message: Text("The data received from the server was invalid. Please contact support."),
                                       dismissButton: .default(Text("Ok")))
    
    static let darkModeOn = AlertItem(title: Text("Dark mode enabled"),
                                       message: Text(""),
                                       dismissButton: .default(Text("Ok")))
    static let lightModeOn = AlertItem(title: Text("Light mode enabled"),
                                       message: Text(""),
                                       dismissButton: .default(Text("Ok")))
}
