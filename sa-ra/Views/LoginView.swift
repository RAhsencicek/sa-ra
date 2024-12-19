import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loginFailed: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Giriş Yap")
                    .font(.largeTitle)
                    .bold()
                
                TextField("Kullanıcı Adı", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                SecureField("Şifre", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    // Giriş yapma işlemi
                    if username == "test" && password == "1234" {
                        // Başarılı giriş
                        loginFailed = false
                        // Ana ekrana yönlendirme veya başka bir işlem
                    } else {
                        // Başarısız giriş
                        loginFailed = true
                    }
                }) {
                    Text("Giriş Yap")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if loginFailed {
                    Text("Giriş başarısız. Lütfen tekrar deneyin.")
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
} 