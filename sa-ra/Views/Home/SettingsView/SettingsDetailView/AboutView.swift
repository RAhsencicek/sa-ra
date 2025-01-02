

import SwiftUI
import Foundation
import MessageUI

/// Shows some text together with an `Image`.
struct FeatureCell: View {
    var image: Image
    var title: String
    var subtitle: String
    
    var body: some View {
        HStack(spacing: 24) {
            image
                .resizable()
                .scaledToFit()
                .foregroundColor(.accentColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                // Using `.init(:_)` to render Markdown links for iOS 15+
                Text(.init(subtitle))
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
    }
}


struct AboutView: View {
    @State private var emailHelperAlertIsShown = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                FeatureCell(image: Image("appiconsvg"), title: "SA-RA HAKKINDA", subtitle: "SA-RA Bluetooth tabanlı, açık kaynaklı, merkezi olmayan bir sohbet uygulamasıdır.")
                FeatureCell(image: Image(systemName: "network"), title: "Peer-to-peer network", subtitle: "Birine bir mesaj gönderdiğinizde, bu mesaj diğer SA-RA kullanıcılarından oluşan bir Peer-to-peer (eşler arası Bluetooth ağı) üzerinden iletilir.")
                FeatureCell(image: Image(systemName: "chevron.left.forwardslash.chevron.right"), title: "Git-Hub kütüphanemiz", subtitle: "SA-RA'nın kaynakları hakkında daha fazla bilgi edinmek için kütüphanemizi ziyaret edebilirsiniz. Geliştiriciler için SA-RA mevcut en iyi ve en güvenli merkezi olmayan mesajlaşma aracı olarak ilham vereceğini temenni ediyoruz. [Github deposunu buradan görüntüleyin](https://github.com/RAhsencicek/sa-ra).")
                FeatureCell(image: Image(systemName: "lock.circle"), title: "Şifrelenmiş ve özel", subtitle: "Mesajlarınız şifrelenerek yalnızca sizin ve alıcının okuyabilmesi sağlanır ve böylece meraklı gözlerden korunursunuz :) ")
                FeatureCell(image: Image(systemName: "bubble.left.and.bubble.right"), title: "Geri bildirimleriniz bizim için çok değerli", subtitle: "Bize e-posta gönderebilirsiniz veya [web sitemizi ziyaret edebilirsiniz](https://dfdfsa.my.canva.site/safe-range).")
                    .padding(.bottom, 20)
                
                Button {
                    if !EmailHelper.shared.sendEmail(subject: "SA-RA için geri dönüşleriniz ve önerileriniz bizim için değerli ", body: "", to: "ahsen.cicek752@gmail.com") {
                        emailHelperAlertIsShown = true
                    }
                } label: {
                    Text("Email")
                }
                .padding(.bottom, 20)
                
                HStack {
                    Spacer()
                    Text("v\(Bundle.main.releaseVersionNumber ?? "")b\(Bundle.main.buildVersionNumber ?? "")")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
            }
        }
        .padding(20)
        .navigationTitle("Merkezi Olmayan Anlık Mesajlaşma")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Varsayılan posta ayarı yok", isPresented: $emailHelperAlertIsShown) {
            Button("OK", role: .cancel) { () }
        } message: {
            Text("E-posta göndermek için varsayılan bir posta kutusu ayarlayın veya favori posta sağlayıcınızı kullanın ve bizimle şu adresten iletişime geçin: ahsen.cicek752@gmail.com")
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}


fileprivate class EmailHelper: NSObject, MFMailComposeViewControllerDelegate {
    /// The EmailHelper static object.
    public static let shared = EmailHelper()
    private override init() {}
    
    
    func sendEmail(subject:String, body:String, to:String) -> Bool {
        if !MFMailComposeViewController.canSendMail() {
            print("Hiçbir posta hesabı bulunamadı")
            return false
        }
        
        let picker = MFMailComposeViewController()
        
        picker.setSubject(subject)
        picker.setMessageBody(body, isHTML: true)
        picker.setToRecipients([to])
        picker.mailComposeDelegate = self
        
        EmailHelper.getRootViewController()?.present(picker, animated: true, completion: nil)
        return true
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        EmailHelper.getRootViewController()?.dismiss(animated: true, completion: nil)
    }
    
    static func getRootViewController() -> UIViewController? {
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController
    }
}
