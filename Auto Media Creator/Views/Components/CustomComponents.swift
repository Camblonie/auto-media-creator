import SwiftUI

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundColor.opacity(0.9))
    }
}

// MARK: - Platform Toggle
struct PlatformToggle: View {
    let platform: PlatformType
    @Binding var isActive: Bool
    let isAuthenticated: Bool
    var action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: platform.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(isActive ? .primaryColor : .gray)
            
            Text(platform.rawValue)
                .font(.headline)
            
            Spacer()
            
            // Authentication indicator
            if isAuthenticated {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .padding(.trailing, 8)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .padding(.trailing, 8)
            }
            
            Toggle("", isOn: $isActive)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .primaryColor))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Pending Post Card
struct PendingPostCard: View {
    let title: String
    let subtitle: String
    let date: Date
    let platform: PlatformType
    let status: ReviewStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: platform.icon)
                    .foregroundColor(.primaryColor)
                
                Text(platform.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text(date.relativeTime())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.headline)
                .lineLimit(2)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Spacer()
                
                // Status badge
                Text(status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(status))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.cardBackgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func statusColor(_ status: ReviewStatus) -> Color {
        switch status {
        case .pendingTextReview, .pendingGraphicReview, .pendingMemeReview:
            return .orange
        case .approved:
            return .blue
        case .rejected:
            return .red
        case .posted:
            return .green
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.primaryColor)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.red)
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
}

// MARK: - Text Input Field
struct TextInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let secure: Bool
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        secure: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.secure = secure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if secure {
                SecureField(placeholder, text: $text)
                    .padding()
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(8)
                    .keyboardType(keyboardType)
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(Color.cardBackgroundColor)
                    .cornerRadius(8)
                    .keyboardType(keyboardType)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Text Input Area
struct TextInputArea: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let height: CGFloat
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        height: CGFloat = 150
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.height = height
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $text)
                    .frame(minHeight: height)
                    .padding(4)
            }
            .background(Color.cardBackgroundColor)
            .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Platform Card
struct PlatformCard: View {
    let platform: PlatformType
    let isActive: Bool
    let isAuthenticated: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: platform.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isActive ? .primaryColor : .gray)
                
                Text(platform.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Status indicator
                if isAuthenticated {
                    Text("Connected")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } else {
                    Text("Not Connected")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            // Active status
            HStack {
                Text("Status:")
                    .fontWeight(.medium)
                
                Text(isActive ? "Active" : "Inactive")
                    .foregroundColor(isActive ? .green : .secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.cardBackgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
