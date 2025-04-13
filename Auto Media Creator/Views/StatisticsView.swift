import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    // Environment and data dependencies
    @Environment(\.dismiss) private var dismiss
    
    // Queries for data
    @Query private var platforms: [SocialMediaPlatform]
    @Query(sort: \Post.creationDate, order: .reverse) private var posts: [Post]
    
    // View state
    @State private var selectedTimeFrame: TimeFrame = .allTime
    
    // Initialization
    init(modelContext: ModelContext) {
        // No special initialization needed
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time frame picker
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.displayName).tag(timeFrame)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Overview card
                    overviewCard
                    
                    // Platform breakdown chart
                    platformBreakdownCard
                    
                    // Post type statistics
                    postTypeBreakdownCard
                    
                    // Recent activity
                    recentActivityCard
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Back")
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    // Overview statistics card
    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.primaryColor)
            
            HStack(spacing: 20) {
                StatBox(
                    title: "Total Posts",
                    value: String(filteredPosts.count),
                    icon: "doc.fill"
                )
                
                StatBox(
                    title: "Platforms",
                    value: String(platforms.count),
                    icon: "network"
                )
                
                StatBox(
                    title: "Memes",
                    value: String(filteredPosts.filter { $0.postType == .meme }.count),
                    icon: "face.smiling.fill"
                )
            }
        }
        .padding()
        .background(Color.cardBackgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // Platform breakdown chart
    private var platformBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Platform Breakdown")
                .font(.headline)
                .foregroundColor(.primaryColor)
            
            if platformPostCounts.isEmpty {
                Text("No posts created yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Bar chart
                Chart(platformPostCounts, id: \.platform) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Platform", item.platform)
                    )
                    .foregroundStyle(by: .value("Platform", item.platform))
                }
                .frame(height: CGFloat(platformPostCounts.count * 40 + 20))
                .chartLegend(.hidden)
                
                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(platformPostCounts, id: \.platform) { item in
                        LegendItem(
                            color: platformColor(for: item.platformType),
                            label: item.platform,
                            value: "\(item.count)"
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // Post type breakdown card
    private var postTypeBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Post Types")
                .font(.headline)
                .foregroundColor(.primaryColor)
            
            if filteredPosts.isEmpty {
                Text("No posts created yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                HStack(alignment: .top, spacing: 20) {
                    // Traditional posts stats
                    VStack {
                        ZStack {
                            Circle()
                                .trim(from: 0, to: traditionalPercentage)
                                .stroke(Color.blue, lineWidth: 10)
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(traditionalPercentage * 100))%")
                                .font(.headline)
                        }
                        
                        Text("Traditional")
                            .font(.subheadline)
                            .padding(.top, 4)
                        
                        Text("\(traditionalCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Meme posts stats
                    VStack {
                        ZStack {
                            Circle()
                                .trim(from: 0, to: memePercentage)
                                .stroke(Color.orange, lineWidth: 10)
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(memePercentage * 100))%")
                                .font(.headline)
                        }
                        
                        Text("Memes")
                            .font(.subheadline)
                            .padding(.top, 4)
                        
                        Text("\(memeCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color.cardBackgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // Recent activity card
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primaryColor)
            
            if filteredPosts.isEmpty {
                Text("No posts created yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(filteredPosts.prefix(5), id: \.id) { post in
                    HStack {
                        Image(systemName: post.platformType.icon)
                            .foregroundColor(platformColor(for: post.platformType))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text(post.textContent.isEmpty ? post.userInputPrompt : post.textContent.truncated(to: 50))
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Text(post.creationDate.formatted())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Status indicator
                        Circle()
                            .fill(statusColor(post.reviewStatus))
                            .frame(width: 10, height: 10)
                    }
                    .padding(.vertical, 4)
                    
                    if post.id != filteredPosts.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods and Computed Properties
    
    // Filter posts based on time frame
    private var filteredPosts: [Post] {
        switch selectedTimeFrame {
        case .last7Days:
            let date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return posts.filter { $0.creationDate >= date }
        case .last30Days:
            let date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return posts.filter { $0.creationDate >= date }
        case .last90Days:
            let date = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            return posts.filter { $0.creationDate >= date }
        case .allTime:
            return posts
        }
    }
    
    // Platform post counts for chart
    private var platformPostCounts: [PlatformCount] {
        let postsByPlatform = Dictionary(grouping: filteredPosts) { $0.platformType }
        
        return postsByPlatform.map { platformType, posts in
            PlatformCount(
                platform: platformType.rawValue,
                platformType: platformType,
                count: posts.count
            )
        }.sorted { $0.count > $1.count }
    }
    
    // Post type counts
    private var traditionalCount: Int {
        filteredPosts.filter { $0.postType == .traditional }.count
    }
    
    private var memeCount: Int {
        filteredPosts.filter { $0.postType == .meme }.count
    }
    
    // Percentages for charts
    private var traditionalPercentage: Double {
        let total = filteredPosts.count
        return total > 0 ? Double(traditionalCount) / Double(total) : 0
    }
    
    private var memePercentage: Double {
        let total = filteredPosts.count
        return total > 0 ? Double(memeCount) / Double(total) : 0
    }
    
    // Color for platform
    private func platformColor(for platformType: PlatformType) -> Color {
        switch platformType {
        case .facebook:
            return .blue
        case .instagram:
            return .purple
        case .tiktok:
            return .teal
        case .twitter:
            return Color(red: 0.11, green: 0.63, blue: 0.95)
        case .linkedin:
            return Color(red: 0.0, green: 0.47, blue: 0.71)
        }
    }
    
    // Color for status
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

// MARK: - Helper Structs

// Time frame options
enum TimeFrame: String, CaseIterable {
    case last7Days = "7 Days"
    case last30Days = "30 Days"
    case last90Days = "90 Days"
    case allTime = "All Time"
    
    var displayName: String {
        return self.rawValue
    }
}

// Platform count for chart
struct PlatformCount {
    let platform: String
    let platformType: PlatformType
    let count: Int
}

// MARK: - Helper Views

// Statistics box
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.primaryColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundColor)
        .cornerRadius(8)
    }
}

// Legend item
struct LegendItem: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}
