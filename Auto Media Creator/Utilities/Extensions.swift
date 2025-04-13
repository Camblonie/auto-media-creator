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
            .background(Color.blue)
            .cornerRadius(10)
    }
    
    // Apply secondary button styling
    func secondaryButtonStyle() -> some View {
        self.font(.headline)
            .foregroundColor(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .cornerRadius(10)
    }
    
    // Add a card style
    func cardStyle() -> some View {
        self.padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
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
    static let primaryColor = Color.blue
    static let secondaryColor = Color(red: 0.1, green: 0.1, blue: 0.8)
    static let accentColor = Color.orange
    static let backgroundColor = Color(UIColor.systemBackground)
    static let cardBackgroundColor = Color(UIColor.secondarySystemBackground)
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
