import SwiftUI

/// A quiet, cool studio using the website's light surface and purple accent.
struct StudioBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.brandSurface
                RadialGradient(
                    colors: [Color.brandPurple.opacity(0.045), .clear],
                    center: UnitPoint(x: 0.5, y: 0.48),
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.85
                )
                LinearGradient(colors: [.white.opacity(0.8), .clear], startPoint: .top, endPoint: .center)
            }
        }.ignoresSafeArea()
    }
}

/// Real Liquid Glass on iOS 26, with a material fallback on older iPhones.
struct BrandGlass<S: Shape>: ViewModifier {
    let shape: S
    var interactive = true

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(interactive), in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(.white.opacity(0.65), lineWidth: 0.8))
        }
    }
}

struct FlowerFlight: View {
    let bouquet: Bouquet
    let flying: Bool
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Image("petal-\(bouquet.id)-\(i % 4)")
                    .resizable().scaledToFit().frame(width: CGFloat(62 + i % 3 * 13), height: 90)
                    .rotationEffect(.degrees(flying ? Double(i - 4) * 13 : Double(i) * 67))
                    .offset(x: flying ? CGFloat(i % 4 - 2) * 30 : CGFloat(i % 2 == 0 ? -1 : 1) * CGFloat(180 + i * 18), y: flying ? CGFloat(i % 3 - 1) * 30 - 65 : CGFloat(-410 - i * 33))
                    .opacity(flying ? 0 : 1)
                    .animation(.easeInOut(duration: 1.5).delay(Double(i) * 0.095), value: flying)
            }
        }.allowsHitTesting(false)
    }
}
