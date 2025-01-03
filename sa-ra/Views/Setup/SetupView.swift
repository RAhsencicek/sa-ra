

import SwiftUI

/**
 SetUpView handles all initial first logins where users choose a username
 and are then redirected to ContentView which is the main View of the app.
 */
struct SetupView: View {
    @State private var isLoggedIn = false
    @State private var id = UUID()
    
    /// CoreData context object
    @Environment(\.managedObjectContext) var context
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var appSession: AppSession
    
    /// True if the keyboard is shown. Used for animations.
    @FocusState private var keyboardShown: Bool
    
    /// A model for keeping track of active card in the carousel.
    @ObservedObject private var carouselViewModel = CarouselViewModel()
    
    /// Show the carousel or not.
    @State private var carouselShown = true
    
    @State private var usernameTextField = ""
    @State private var usernameTextFieldState: UsernameValidator.State = .undetermined
    
    @State private var usernameIsValid = UsernameValidator.shared.isUsernameValid
    
    var body: some View {
        if isLoggedIn {
            HomeView()
        } else {
            NavigationView {
                if usernameIsValid {
                    HomeView()
                        .navigationBarTitle("")
                        .navigationBarBackButtonHidden(true)
                } else {
                    VStack {
                        // Explanatory carousel
                        if carouselShown {
                            SnapCarousel()
                                .environmentObject(carouselViewModel)
                                .transition(.opacity)
                        }
                        
                        // TextField for setting username
                        VStack {
                            TextField("Kullanıcı adını girin", text: $usernameTextField) {
                                hideKeyboard()
                            }
                                .keyboardType(.namePhonePad)
                                .padding()
                                .background(
                                    colorScheme == .dark ? Asset.greyDark.swiftUIColor : Asset.greyLight.swiftUIColor
                                )
                                .cornerRadius(10.0)
                                .focused($keyboardShown)
                                .onChange(of: keyboardShown) { newValue in
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        self.carouselShown.toggle()
                                    }
                                }
                            
                            // Show a warning if username is invalid
                            if case .error(let errorMessage) = UsernameValidator.shared.validate(username: usernameTextField) {
                                Text(usernameTextField.isEmpty ? "" : errorMessage)
                                    .font(.footnote)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .animation(.spring())
                        .padding()
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        
                        Spacer()
                        
                        VStack {
                            // EULA part.
                            HStack {
                                Text("Devam ederek şunları kabul etmiş olursunuz:")
                                Link("Son kullanıcı lisans sözleşmesi", destination: URL(string: "https://dfdfsa.my.canva.site/safe-range")!)
                            }
                            
                            // Enter button
                            Button {
                                UsernameValidator.shared.set(username: usernameTextField, context: context)
                                id = UUID() // Hack to force refresh view
                            } label: {
                                Text("Devam Et")
                                    .padding()
                                    .foregroundColor(.white)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Asset.dimOrangeDark.swiftUIColor, Asset.dimOrangeLight.swiftUIColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10.0)
                            }
                        }
                        .padding()
                    }
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .onAppear {
                        UNUserNotificationCenter.current().requestAuthorization(
                            options: [.alert, .badge, .sound]
                        ) { success, error in
                            if success {
                                print("Tamamdır!")
                            } else if let e = error {
                                print(e.localizedDescription)
                            }
                        }
                    }
                }
            }
            .id(id)
            .onChange(of: UsernameValidator.shared.isUsernameValid) { newValue in
                usernameIsValid = newValue
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .banner(data: $appSession.bannerData, isPresented: $appSession.bannerDataShouldShow)
        }
    }
}
