import SwiftUI

struct JournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color.purple.opacity(0.2),
                    Color.blue.opacity(0.1),
                    Color.black
                ] : [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.05),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Solid background overlay to prevent transparency
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header with back button
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Header
                VStack(spacing: 16) {
                    Image("icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text("Wellness Journal")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.top, 20)
                
                // Placeholder content
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Journal Coming Soon")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Reflect on your wellness journey, track your mood, and document your progress.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

#Preview {
    JournalView()
} 