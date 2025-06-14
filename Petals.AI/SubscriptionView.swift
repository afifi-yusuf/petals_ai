import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager()
    @State private var isPurchasing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image("icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Text("Upgrade to Premium")
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
                        .padding(.top, 40)
                        
                        // Features
                        VStack(alignment: .leading, spacing: 20) {
                            FeatureRow(icon: "heart.fill", title: "Unlimited Health Tracking", description: "Track all your health metrics")
                            FeatureRow(icon: "brain.head.profile", title: "AI Wellness Coach", description: "Personalized guidance and insights")
                            FeatureRow(icon: "moon.stars.fill", title: "Premium Meditations", description: "Access to all meditation sessions")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", description: "Detailed progress tracking")
                        }
                        .padding(.horizontal)
                        
                        // Subscription Card
                        VStack(spacing: 16) {
                            Text("Monthly Premium")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("$8.99")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("per month")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                isPurchasing = true
                                Task {
                                    await storeManager.purchase()
                                    isPurchasing = false
                                }
                            }) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Subscribe Now")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(25)
                                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(isPurchasing)
                            
                            Text("Cancel anytime")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .purple.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        
                        // Terms
                        VStack(spacing: 8) {
                            Text("By subscribing, you agree to our")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Link("Terms of Service", destination: URL(string: "https://petals.ai/terms")!)
                                Text("and")
                                Link("Privacy Policy", destination: URL(string: "https://petals.ai/privacy")!)
                            }
                            .font(.caption)
                            .foregroundColor(.purple)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.purple)
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    
    init() {
        Task {
            await loadProducts()
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: ["com.petals.ai.premium.monthly"])
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func purchase() async {
        guard let product = products.first else { return }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Handle successful purchase
                    await transaction.finish()
                case .unverified:
                    // Handle unverified transaction
                    break
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Failed to purchase: \(error)")
        }
    }
}

#Preview {
    SubscriptionView()
} 