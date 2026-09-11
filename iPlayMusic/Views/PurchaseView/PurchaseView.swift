//
//  PurchaseView.swift
//  iPlayMusic
//
//  Created by Shiv on 26/08/26.
//

import SwiftUI
import StoreKit

struct PurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var purchaseManager: PurchaseManager = .shared
    @StateObject private var appState: StateManager = .shared
    @State private var selectedProductId: String = AppConstants.MONTHLY_ID

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @Namespace private var animation
    
    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                Color(theme.theme.darkBackground).ignoresSafeArea()
                HStack(spacing: 0) {
                    Image("ic_model")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            ForEach(purchaseManager.availableProducts, id: \.id) { product in
                                HStack {
                                    Image(systemName: selectedProductId == product.id ? "checkmark.circle.fill" : "circle")
                                        .resizable()
                                        .frame(width: 17, height: 17)
                                        .foregroundStyle(selectedProductId == product.id ? theme.theme.primary : theme.subText(isDark: isDark).opacity(0.25))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.displayName.uppercased())
                                            .font(.system(size: 14, weight: .semibold, design: .default))
                                            .foregroundStyle(theme.text(isDark: isDark))
                                        if !UserDefaults.inReview {
                                            Text(product.displayPrice)
                                                .font(.system(size: 13, weight: .semibold, design: .default))
                                                .foregroundStyle(theme.subText(isDark: isDark))
                                        }
                                    }
                                    
                                    Spacer()
                                    if UserDefaults.inReview {
                                        Text(product.displayPrice)
                                            .font(.system(size: 13, weight: .semibold, design: .default))
                                            .foregroundStyle(theme.subText(isDark: isDark))
                                    } else {
                                        if let perPrice = weeklyPrice(for: product) {
                                            HStack(spacing: 0) {
                                                Text(perPrice)
                                                    .font(.system(size: 13, weight: .medium, design: .default))
                                                    .foregroundStyle(theme.text(isDark: isDark))
                                                Text(" / week")
                                                    .font(.system(size: 11, weight: .medium, design: .default))
                                                    .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
                                            }
                                        } else {
                                            HStack(spacing: 0) {
                                                Text(product.displayPrice)
                                                    .font(.system(size: 13, weight: .medium, design: .default))
                                                    .foregroundStyle(theme.text(isDark: isDark))
                                                Text(" / week")
                                                    .font(.system(size: 11, weight: .medium, design: .default))
                                                    .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 55, alignment: .leading)
                                .padding(.horizontal, 12)
                                .background {
                                    if selectedProductId == product.id {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(theme.secondaryCard(isDark: isDark))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(theme.theme.primary, lineWidth: 2)
                                            }
                                            .matchedGeometryEffect(id: "SELECT_PRODUCT", in: animation)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(theme.card(isDark: isDark))
                                    }
                                }
                                .onTapGesture {
                                    withAnimation(.linear) {
                                        selectedProductId = product.id
                                    }
                                }
                            }
                        }
                        
                        Button {
                            if let product = purchaseManager.availableProducts.first(where: { $0.id == selectedProductId }) {
                                Task {
                                    purchaseManager.isLoading = true
                                    _ = await purchaseManager.purchase(product)
                                    purchaseManager.isLoading = false
                                }
                            }
                        } label: {
                            Text("Continue")
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .foregroundStyle(theme.text(isDark: isDark))
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(RoundedRectangle(cornerRadius: 8).fill(theme.theme.primary))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.init(top: 20, leading: 0, bottom: 20, trailing: 50))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topTrailing, content: {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10 ,weight: .light, design: .default))
                        .foregroundStyle(theme.text(isDark: isDark))
                        .frame(width: 22.5, height: 22.5)
                        .background(Circle().fill(theme.subText(isDark: !isDark)))
                }
                .buttonStyle(.plain)
                .padding()
            })
            .loadingOverlay($purchaseManager.isLoading)
        }
    }
    
    private func weeklyPrice(for product: Product) -> String? {
        switch product.id {
        case AppConstants.YEARLY_ID:
            let weeklyPrice = product.price / 52
            return "\(weeklyPrice.formatted(product.priceFormatStyle))"

        case AppConstants.MONTHLY_ID:
            let weeklyPrice = product.price / 4.33
            return "\(weeklyPrice.formatted(product.priceFormatStyle))"

        default:
            return nil
        }
    }
}

#Preview {
    PurchaseView()
}
