import StoreKit
import SwiftUI

struct TipOption: Identifiable {
    let id: String
    let displayName: String
    let displayPrice: String
    let storeProduct: Product?
}

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()
    
    @Published var tipOptions: [TipOption] = []
    @Published var isPurchasing = false
    @Published var hasLoaded = false
    @Published var storeAvailable = false
    
    private let productIDs = [
        "com.yuanbei.pastepal.tip.coffee",
        "com.yuanbei.pastepal.tip.meal",
        "com.yuanbei.pastepal.tip.supercharge"
    ]
    
    func loadProducts() async {
        hasLoaded = false
        tipOptions = []
        
        let storeProducts = (try? await Product.products(for: productIDs)) ?? []
        
        if !storeProducts.isEmpty {
            storeAvailable = true
            tipOptions = storeProducts.sorted(by: { $0.price < $1.price }).map {
                TipOption(id: $0.id, displayName: $0.displayName, displayPrice: $0.displayPrice, storeProduct: $0)
            }
        } else {
            storeAvailable = false
            tipOptions = [
                TipOption(id: productIDs[0], displayName: "Developer Espresso", displayPrice: "$1.99", storeProduct: nil),
                TipOption(id: productIDs[1], displayName: "Developer Combo Meal", displayPrice: "$4.99", storeProduct: nil),
                TipOption(id: productIDs[2], displayName: "Supercharger Support", displayPrice: "$9.99", storeProduct: nil),
            ]
        }
        hasLoaded = true
    }
    
    func purchase(_ option: TipOption) async -> Bool {
        guard let product = option.storeProduct else {
            return false
        }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    return true
                case .unverified:
                    return false
                }
            case .pending:
                return false
            case .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }
}
