

import SwiftUI
import CodeScanner
import CoreImage.CIFilterBuiltins


struct QRView: View {
    
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appSession: AppSession
    
    private let username: String
 
    private let context = CIContext()
   
    private let filter = CIFilter.qrCodeGenerator()
    
    init() {
        guard let username = UsernameValidator.shared.userInfo?.asString else {
            fatalError("QR görünümü açıldı ancak kullanıcı adı ayarlanmadı")
        }
        self.username = username
    }
    
    /// Show camera for scanning QR codes.
    @State private var qrCodeScannerIsShown = false
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("QR kodunu tarayın")
                .font(.title)
                .padding()
            
            ZStack {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .foregroundColor(.white)
                    .frame(width: 225, height: 225)
                
               
                Image(uiImage: generateQRCode(from: "dim://\(username)//\(CryptoHandler.fetchPublicKeyString())"))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200, alignment: .center)
            }
                
            Spacer(minLength: 150)
            
            Text("Tarama butonuna basın ve birbirinizin QR kodunu tarayın. Birbirinizi eklemelisiniz.")
                .font(.footnote)
                .foregroundColor(.accentColor)
            
            Button {
                qrCodeScannerIsShown = true
            } label: {
                Text("Scan")
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
            }.sheet(isPresented: $qrCodeScannerIsShown, content: {
                ZStack {
                    CodeScannerView(codeTypes: [.qr], completion: handleScan)
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                qrCodeScannerIsShown = false
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .imageScale(.large)
                                    .padding()
                            }

                        }
                        Spacer()
                        Text("QR kodunu tarayarak yeni bir kişi ekleyin.")
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            })
        }
        .padding()
    
        .background(
            Image("bubbleBackground")
                .resizable(resizingMode: .tile)
                .edgesIgnoringSafeArea(.all)
        )
        .navigationBarTitle("KİŞİ EKLE", displayMode: .inline)
    }
    
    /// Handles the result of the QR scan.
    /// - Parameter result: Result of the QR scan or an error.
    private func handleScan(result: Result<ScanResult, ScanError>) {
        qrCodeScannerIsShown = false
        switch result {
        case .success(let result):
            appSession.addUserFromQrScan(result.string)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    
   
    private func generateQRCode(from string: String) -> UIImage {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
