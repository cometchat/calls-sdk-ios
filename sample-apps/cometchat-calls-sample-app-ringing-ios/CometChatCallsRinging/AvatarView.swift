import SwiftUI
import UIKit

/// A round avatar: the image when there is one, otherwise initials on a colour picked from
/// the name, so the same person always gets the same colour.
struct AvatarView: View {
    let name: String?
    let avatarURL: String?
    let size: CGFloat
    var initialsCount: Int = 1
    var isOnline: Bool? = nil

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                if isOnline == true { presenceDot }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        if let avatarURL, !avatarURL.isEmpty, let url = URL(string: avatarURL) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    initials // also while loading, so there is no blank flash
                }
            }
        } else {
            initials
        }
    }

    private var initials: some View {
        let index = AvatarColors.index(for: name ?? "")
        return ZStack {
            Circle().fill(Color(AvatarColors.palette[index]))
            Text(Self.initials(of: name, maxCount: initialsCount))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(Color(AvatarColors.contrast(on: AvatarColors.palette[index])))
        }
    }

    private var presenceDot: some View {
        let dot = max(8, size * 0.3)
        return Circle()
            .fill(Color.statusOnline)
            .frame(width: dot, height: dot)
            .overlay(Circle().stroke(Color.appBackground, lineWidth: dot * 0.16))
    }

    static func initials(of name: String?, maxCount: Int) -> String {
        let words = (name ?? "").split(whereSeparator: \.isWhitespace)
        let letters = words.prefix(max(1, maxCount)).compactMap(\.first).map { String($0).uppercased() }
        return letters.isEmpty ? "?" : letters.joined()
    }
}

/// The avatar colour palette and the readable initial colour on each.
enum AvatarColors {
    private static let hexes: [UInt32] = [
        0x7C6FCF, 0x5B8FD9, 0x4FA88C, 0x8FA65B, 0xD16B9B,
        0x5FA9B5, 0x5C6BC0, 0x7A8CA6, 0xC46A6A, 0x9A6FBF,
    ]

    static let palette: [UIColor] = hexes.map(color(from:))

    private static func color(from hex: UInt32) -> UIColor {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

    /// djb2, so a name maps to the same colour on every launch and platform.
    static func index(for name: String) -> Int {
        var hash: UInt64 = 5381
        for scalar in name.unicodeScalars {
            hash = (hash &<< 5) &+ hash &+ UInt64(scalar.value)
        }
        return Int(hash % UInt64(palette.count))
    }

    /// Near-black on light fills, white on dark ones.
    static func contrast(on color: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        func linear(_ c: CGFloat) -> CGFloat { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        let luminance = 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
        return luminance > 0.45 ? UIColor(red: 24 / 255, green: 26 / 255, blue: 32 / 255, alpha: 1) : .white
    }
}
