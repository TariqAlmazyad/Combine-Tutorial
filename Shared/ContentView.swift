//
//  ContentView.swift
//  Shared
//
//  Created by Tariq Almazyad on 1/13/21.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Enter username"), footer: inlineErrorForUsername()) {
                        TextField("Username", text: $userViewModel.user.name)
                    }
                    
                    Section(header: Text("Enter password"), footer: inlineErrorForPassword()) {
                        TextField("password", text: $userViewModel.password)
                        TextField("password again", text: $userViewModel.passwordAgain)
                    }
                    Section {
                        
                        Button(action: {}, label: {
                            HStack{
                                Spacer()
                                Text("Create Account")
                                Spacer()
                            }.padding()
                            .foregroundColor(userViewModel.isFormValid ? .white : .gray)
                            .background(userViewModel.isFormValid ? Color(#colorLiteral(red: 0.05797722191, green: 0.4053273201, blue: 0.2976796925, alpha: 1)) : Color.red.opacity(0.4))
                            .clipShape(Capsule())
                            
                        }).buttonStyle(BorderlessButtonStyle())
                        .disabled(!userViewModel.isFormValid)
                        
                    }.listRowBackground(Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)))
                    
                }// end of Form
                .navigationBarTitle("Login", displayMode: .large)
                
            }// end of VStack
        }// end of NavigationView
    }
    
    fileprivate func inlineErrorForUsername() -> Text {
        Text(userViewModel.inlineErrorForUsername)
            .foregroundColor(userViewModel.isUserValid ? .green : .red)
    }
    
    fileprivate func inlineErrorForPassword() -> Text {
        Text(userViewModel.inlineErrorForPassword)
            .foregroundColor(userViewModel.isPasswordValid ? .green : .red)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}


enum PasswordStatus {
    case empty
    case notStrongEnough
    case repeatedPasswordWrong
    case valid
}


enum isUsernameValid {
    case isEmpty
    case tooShort
    case valid
}

struct User: Equatable {
    var name: String = ""
    
}


class UserViewModel: ObservableObject {
    // User property validation
    @Published var user = User()
    @Published var inlineErrorForUsername: String = ""
    @Published var isUserValid: Bool = false
    
    // password property validation
    @Published var password: String = ""
    @Published var passwordAgain: String = ""
    @Published var inlineErrorForPassword: String = ""
    @Published var isPasswordValid: Bool = false
    
    // Form Validation
    @Published var isFormValid: Bool = false
    
    private static let predicate = NSPredicate(format: "SELF MATCHES %@","^(?=.*[a-z])(?=.*[$@$#!%*?&]).{6,}$")
    
    @Published var anyCancellable = Set<AnyCancellable>()
    
    init() {
        userValidator()
        passwordValidator()
        formValidator()
    }
    
    // [1] monitor username status while user is typing
    private var usernameStatusPublisher: AnyPublisher<isUsernameValid, Never>{
        $user
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .removeDuplicates()
            .compactMap{
                if $0.name.isEmpty { return isUsernameValid.isEmpty }
                if $0.name.count <= 3 { return isUsernameValid.tooShort }
                return isUsernameValid.valid
            }
            .eraseToAnyPublisher()
    }
    
    // [2] after [1], we check whether user is valid or not
    private func userValidator(){
        usernameStatusPublisher
            .dropFirst() // hide the validator upon launch for first time
            .receive(on: RunLoop.main)
            .map{
                switch $0 {
                case .isEmpty:
                    self.isUserValid = false
                    return "Username can not be empty"
                case .valid:
                    self.isUserValid = true
                    return "username is valid"
                case .tooShort:
                    self.isUserValid = false
                    return "username is too Short"
                }
            }// assign the switch result to inlineErrorForUsername
            .assign(to: \.inlineErrorForUsername, on: self)
            // once we are done , we store it in anyCancellable to avoid any memory leak
            .store(in: &anyCancellable)
        
    }
    
    private var passwordStatusPublisher: AnyPublisher<PasswordStatus, Never>{
        Publishers.CombineLatest($password, $passwordAgain)
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .map{
                // 1- check if the 2 passwords are empty
                if $0.isEmpty && $1.isEmpty {return PasswordStatus.empty }
                // 2- check if the password is less than 6 digits
                if $0.count <= 6 {return PasswordStatus.notStrongEnough}
                // 3- check if the 2 passwords are equal
                if $0 != $1 {return PasswordStatus.repeatedPasswordWrong }
                // 4- check if the password is strong
                if !Self.predicate.evaluate(with: $0)
                    && !Self.predicate.evaluate(with: $0) {return PasswordStatus.notStrongEnough }
                
                return PasswordStatus.valid
            }
            .eraseToAnyPublisher()
    }
    
    private func passwordValidator(){
        passwordStatusPublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .map{
                switch $0{
                case .empty:
                    self.isPasswordValid = false
                    return "Password can not be empty"
                case .notStrongEnough:
                    self.isPasswordValid = false
                    return "Password is not strong enough"
                case .repeatedPasswordWrong:
                    self.isPasswordValid = false
                    return "Passwords are not matched!"
                case .valid:
                    self.isPasswordValid = true
                    return "Password is valid"
                }
            }
            .assign(to: \.inlineErrorForPassword, on: self)
            .store(in: &anyCancellable)
    }
    
    private var isFormValidPublisher: AnyPublisher<Bool, Never>{
        Publishers.CombineLatest(usernameStatusPublisher, passwordStatusPublisher)
            .map{ $0 == .valid && $1 == .valid }
            .eraseToAnyPublisher()
    }
    
    private func formValidator(){
        isFormValidPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isFormValid, on: self)
            .store(in: &anyCancellable)
    }
    
}

