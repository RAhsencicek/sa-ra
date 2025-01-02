
import SwiftUI

extension View {
    func banner(data: Binding<BannerModifier.BannerData>, isPresented: Binding<Bool>) -> some View {
        self.modifier(BannerModifier(data: data, shouldShow: isPresented))
    }
}
