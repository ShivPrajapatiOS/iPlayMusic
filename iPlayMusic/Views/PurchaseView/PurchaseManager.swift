//
//  PurchaseManager.swift
//  iPlayMusic
//
//  Created by Shiv on 26/08/26.
//

import SwiftUI
import Combine
import StoreKit

@MainActor
class PurchaseManager: ObservableObject {
    static let shared: PurchaseManager = .init()
        
    @Published var availableProducts: [Product] = []
    
    @Published var isLoading: Bool = false
    
    init() {
        Task {
            await fetchProducts()
            await updatePurchasedStatus()
            await observeTransactions()
        }
    }
    
    // Fetch products from App Store
    func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: [
                AppConstants.YEARLY_ID, // Auto Renewable ProductID
                AppConstants.MONTHLY_ID, // Auto Renewable ProductID
                AppConstants.WEEKLY_ID // Auto Renewable ProductID
            ])
            availableProducts = storeProducts.sorted(by: { $0.price > $1.price })
            print("Products fetched successfully: \(availableProducts.map({ $0.displayName }))")
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
        }
    }
    
    // Purchase Product
    func purchase(_ product: Product) async -> (Bool) {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    print("Purchase Success: \(verification)")
                    await transaction.finish()
                    await updatePurchasedStatus()
                    return true
                }
            case .userCancelled:
                print("Purchase Cancelled")
                StateManager.shared.hasPurchased = false
            case .pending:
                print("Purchase pending...")
                StateManager.shared.hasPurchased = false
            default:
                print("Purchase Failed / pending...")
                StateManager.shared.hasPurchased = false
            }
        } catch {
            print("Purchase error: \(error.localizedDescription)")
        }
        return false
    }
    
    // Check already purchased items
    func updatePurchasedStatus() async {
        var premiumActive: Bool = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                print("Already Purchased Transation: \(transaction)")
                if [AppConstants.YEARLY_ID, AppConstants.MONTHLY_ID, AppConstants.WEEKLY_ID].contains(transaction.productID) {
                    premiumActive = true
                }
            }
        }
        StateManager.shared.hasPurchased = premiumActive
        print("Premium Status: \(StateManager.shared.hasPurchased)")
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print("Restore purchases failed: \(error)")
        }
    }
    
    private func observeTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transation) = result {
                print("Transaction Update: \(transation)")
                await transation.finish()
                await updatePurchasedStatus()
            }
        }
    }
}
