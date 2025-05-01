import Foundation
import SwiftUI

// MARK: - View Extensions
extension View {
    // Apply common button styling
    func primaryButtonStyle() -> some View {
        self.font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.primaryColor)
            .cornerRadius(10)
    }
    
    // Apply secondary button styling
    func secondaryButtonStyle() -> some View {
        self.font(.headline)
            .foregroundColor(.primaryColor)
            .padding()
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primaryColor, lineWidth: 1)
            )
            .cornerRadius(10)
    }
    
    // Apply accent button styling
    func accentButtonStyle() -> some View {
        self.font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .cornerRadius(10)
    }
    
    // Apply card styling
    func cardStyle() -> some View {
        self.padding()
            .background(Color.cardBackgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.darkAccentColor.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // Hide keyboard on tap outside text fields
    func hideKeyboardOnTap() -> some View {
        return self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Color Extensions
extension Color {
    // Primary colors
    static let primaryColor = Color(hex: "27476E")      // Deep blue
    static let secondaryColor = Color(hex: "006992")    // Medium blue
    static let accentColor = Color(hex: "ECA400")       // Golden yellow
    
    // Background colors
    static let backgroundColor = Color(UIColor.systemBackground)
    static let cardBackgroundColor = Color(hex: "EAF88F").opacity(0.2)  // Light yellow with opacity
    
    // Additional theme colors
    static let darkAccentColor = Color(hex: "001D4A")   // Dark navy
    
    // Initialize color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - String Extensions
extension String {
    // Trim string to maximum length
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        } else {
            return self
        }
    }
    
    // Check if a string is a valid URL
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

// MARK: - Date Extensions
extension Date {
    // Format date as a relative time string
    func relativeTime() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // Format as readable date time
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Notification extension for keyboard
extension NotificationCenter {
    // Get keyboard height from notification
    static func keyboardHeight(from notification: Notification) -> CGFloat {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return 0
        }
        return keyboardFrame.height
    }
}
