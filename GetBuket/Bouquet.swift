import SwiftUI

struct Bouquet: Identifiable, Equatable {
    let id: String
    let name: String
    let mood: String
    let price: Int
    let tint: Color
    var image: String { "bouquet-\(id)" }
    var priceLabel: String { price.formatted(.number.locale(Locale(identifier: "ru_RU"))) + " ₽" }

    // Names, photographs and prices from GetBuket's catalogue, 21 September 2026.
    static let collection: [Bouquet] = [
        .init(id: "2204", name: "Райское облако", mood: "Для самых нежных чувств", price: 3890, tint: Color(hex: 0xAC6388)),
        .init(id: "2203", name: "Рената", mood: "Маленькое красивое признание", price: 4150, tint: Color(hex: 0x727AA0)),
        .init(id: "2222", name: "Летняя поляна", mood: "Солнечный день в ваших руках", price: 2690, tint: Color(hex: 0xB99843)),
        .init(id: "2226", name: "Летний луг", mood: "Просто так. От всего сердца", price: 3050, tint: Color(hex: 0xA86C64)),
        .init(id: "2230", name: "Подготовка к свиданию", mood: "Когда всё понятно без слов", price: 13124, tint: Color(hex: 0x9A976D))
    ]
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
    // Exact colours from GetBuket's published CSS and logo.
    static let brandPurple = Color(hex: 0xBC00FF)
    static let brandGreen = Color(hex: 0x007852)
    static let brandSurface = Color(hex: 0xF5F7FA)
    static let ink = Color(hex: 0x181818)
}
