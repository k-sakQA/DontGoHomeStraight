import SwiftUI

// MARK: - Modern Chic Theme Utilities

extension Color {
    static let appPurpleStart = Color(hex: "6366F1")
    static let appPurpleEnd = Color(hex: "8B5CF6")
}

extension LinearGradient {
    static var appHeroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appPurpleStart,
                Color.appPurpleEnd
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var appBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "F0F9FF"),
                Color(hex: "E0E7FF")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                LinearGradient.appHeroGradient
                    .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.1 : 0.2), radius: configuration.isPressed ? 6 : 12, x: 0, y: configuration.isPressed ? 3 : 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(Color(hex: "212529"))
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(
                Color.white.opacity(configuration.isPressed ? 0.95 : 1.0)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "E9EDF3"), lineWidth: 1)
            )
            .shadow(color: .black.opacity(configuration.isPressed ? 0.02 : 0.04), radius: configuration.isPressed ? 2 : 4, x: 0, y: configuration.isPressed ? 1 : 2)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

// MARK: - Card Style

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Color.white)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: "E9EDF3"), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 25, x: 0, y: 10)
    }
}

extension View {
    func appCard() -> some View {
        self.modifier(AppCardModifier())
    }
}

// MARK: - Chip Style

struct ChipStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(isSelected ? .white : Color(hex: "2E3238"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "3A7DFF") : Color.white)
            .cornerRadius(999)
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(isSelected ? Color.clear : Color(hex: "E9EDF3"), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Tab Style

struct TabStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(isSelected ? Color(hex: "3A7DFF") : Color(hex: "212529"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(isSelected ? Color.white : Color.clear)
            .cornerRadius(12)
            .shadow(color: .black.opacity(isSelected ? 0.08 : 0), radius: isSelected ? 10 : 0, x: 0, y: isSelected ? 5 : 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

