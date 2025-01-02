

import SwiftUI


struct SettingsView: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.colorScheme) var colorScheme
    
    
    private let defaults = UserDefaults.standard
    
    /// The `AppSession` to get things from the logic layer.
    @EnvironmentObject var appSession: AppSession
    
    @State private var usernameTextFieldText = ""
    @State private var usernameTextFieldIdentifier = ""
    
    @State private var invalidUsernameAlertMessageIsShown = false
    @State private var invalidUsernameAlertMessage = ""
    
    @State private var changeUsernameAlertMessageIsShown = false
    
    /// All conversations stored to CoreData
    @FetchRequest(
        entity: ConversationEntity.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ConversationEntity.date, ascending: false)
        ]
    ) var conversations: FetchedResults<ConversationEntity>
    
    /// Read messages setting saved to UserDefaults
    @AppStorage(UserDefaultsKey.readMessages.rawValue) var readStatusToggle = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 65)
                    
                    if changeUsernameAlertMessageIsShown {
                        Spacer()
                        ProgressView()
                    } else {
                        TextField("Choose a username...", text: $usernameTextFieldText, onCommit: {
                            hideKeyboard()
                            
                            switch UsernameValidator.shared.validate(username: usernameTextFieldText) {
                            case .valid, .demoMode:
                                changeUsernameAlertMessageIsShown = true
                            case .error(message: let errorMessage):
                                invalidUsernameAlertMessage = errorMessage
                                invalidUsernameAlertMessageIsShown = true
                            default: ()
                            }
                        })
                        .keyboardType(.namePhonePad)
                        .padding()
                        .cornerRadius(10.0)
                    }
                    
                    Spacer()
                    
                    Text("# " + usernameTextFieldIdentifier)
                        .foregroundColor(.gray)
                }
                .foregroundColor(.accentColor)
            } header: {
                Text("Kullanıcı adım")
            } footer: {
                Text("Kullanıcı adınızı değiştirirseniz, siz ve kişileriniz birbirinizi tekrar eklemek zorunda kalacaksınız.")
            }
            
            Section {
                Toggle(isOn: $readStatusToggle) {
                    Label("Okundu Bilgilerini Göster", systemImage: "eye.fill")
                        .imageScale(.large)
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            } footer: {
                Text("Okundu bilgisi, kişilerinizin mesajlarını okuyup okumadığınızı görmelerini sağlar.")
            }
            
            Section {
                NavigationLink(destination: AboutView()) {
                    Label("Hakkımızda & İletişim", systemImage: "questionmark")
                        .foregroundColor(.accentColor)
                        .imageScale(.large)
                }
            }
            
            Section {
                Label(
                    appSession.connectedDevicesAmount < 0 ? "Bağlı cihaz yok." : "\(appSession.connectedDevicesAmount) cihaz bağlandı.",
                    systemImage: "ipad.and.iphone")
                    .imageScale(.large)
                
                Label("\(appSession.routedCounter) Bu oturumda yönlendirilen mesajlar.", systemImage: "arrow.left.arrow.right")
                    .imageScale(.large)
            } header: {
                Text("Bağlantı")
            } footer: {
                Text("Bağlı cihazlar ve telefonunuzdan yönlendirilen mesaj miktarı hakkında bilgiler içerir.")
            }
        }
        .symbolRenderingMode(.hierarchical)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .navigationBarTitle("Ayarlar", displayMode: .large)
        .onAppear {
            setUsernameTextFieldToStoredValue()
        }
        // MARK: Alerts
        // Invalid username alert
        .alert("Invalid username", isPresented: $invalidUsernameAlertMessageIsShown) {
            Button("OK", role: .cancel) {
                setUsernameTextFieldToStoredValue()
            }
        } message: {
            Text(invalidUsernameAlertMessage)
        }
        // Change username alert
        .alert("Change username", isPresented: $changeUsernameAlertMessageIsShown) {
            Button("Change", role: .destructive) {
                let state = UsernameValidator.shared.set(username: usernameTextFieldText, context: context)
                switch state {
                case .valid(let userInfo):
                    usernameTextFieldText = userInfo.name
                    usernameTextFieldIdentifier = userInfo.id
                    deleteAllConversations()
                    CryptoHandler.resetKeys()
                case .demoMode(let userInfo):
                    usernameTextFieldText = userInfo.name
                    usernameTextFieldIdentifier = userInfo.id
                    CryptoHandler.resetKeys()
                default:
                    setUsernameTextFieldToStoredValue()
                }
            }
            Button("Cancel", role: .cancel) {
                setUsernameTextFieldToStoredValue()
            }
        } message: {
            Text("Kullanıcı adınızı değiştirmek SA-RA'yı sıfırlayacak ve kişilerinizi kaldıracaktır.")
        }
    }
    
    /// Revert username to what is stored in UserDefaults
    private func setUsernameTextFieldToStoredValue() {
        usernameTextFieldText = UsernameValidator.shared.userInfo?.name ?? ""
        usernameTextFieldIdentifier = UsernameValidator.shared.userInfo?.id ?? ""
    }
    
    /// Delete all conversations (very destructive)
    private func deleteAllConversations() {
        conversations.forEach { conversation in
            context.delete(conversation)
        }
        do {
            try context.save()
        } catch {
            print("Tüm konuşmalar silindikten sonra kaynak kaydedilmez")
        }
    }
}
