// SwiftUIHelpers.swift
// Reusable SwiftUI modifiers and views for error/loading states

import SwiftUI

// MARK: - Error Alert Modifier

struct APIErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String?
    var onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Something went wrong", isPresented: $isPresented) {
                Button("OK", role: .cancel) {}
                if let retry = onRetry {
                    Button("Retry") { retry() }
                }
            } message: {
                Text(message ?? "An unknown error occurred.")
            }
    }
}

extension View {
    /// Attach this to any View to show error alerts from your ViewModel
    func apiErrorAlert(
        isPresented: Binding<Bool>,
        message: String?,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        modifier(APIErrorAlertModifier(isPresented: isPresented, message: message, onRetry: onRetry))
    }
}

// MARK: - Loading Overlay Modifier

//struct LoadingOverlayModifier: ViewModifier {
//    let isLoading: Bool
//    var message: String = "Loading..."
//    
//    func body(content: Content) -> some View {
//        ZStack {
//            content
//                .disabled(isLoading)
//                .blur(radius: isLoading ? 2 : 0)
//            
//            if isLoading {
//                VStack(spacing: 12) {
//                    ProgressView()
//                        .scaleEffect(1.4)
//                    Text(message)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                .padding(24)
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(.ultraThinMaterial)
//                )
//                .shadow(radius: 10)
//            }
//        }
//    }
//}

//extension View {
//    func loadingOverlay(_ isLoading: Bool, message: String = "Loading...") -> some View {
//        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
//    }
//}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title3.bold())
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            }
        }
        .padding(32)
    }
}

// MARK: - Network Error View

struct NetworkErrorView: View {
    let error: APIError
    var onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            
            Text("Oops!")
                .font(.title2.bold())
            
            Text(error.errorDescription ?? "Unknown error")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let retry = onRetry {
                Button("Try Again") { retry() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
    }
    
    private var iconName: String {
        switch error {
        case .noInternetConnection:      return "wifi.slash"
        case .networkTimeout:            return "clock.badge.exclamationmark"
        case .unauthorized:              return "lock.fill"
        case .notFound:                  return "questionmark.circle"
        case .rateLimited:               return "exclamationmark.triangle"
        default:                         return "xmark.octagon"
        }
    }
}

// MARK: - Usage Example (SwiftUI View)

/*
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var query = ""
    
    var body: some View {
        NavigationStack {
            List(viewModel.songs) { song in
                Text(song.name ?? "Unknown")
            }
            .searchable(text: $query)
            .onChange(of: query) { newValue in
                Task { await viewModel.searchSongs(query: newValue) }
            }
            .loadingOverlay(viewModel.isLoading)
            .apiErrorAlert(
                isPresented: $viewModel.showError,
                message: viewModel.errorMessage,
                onRetry: { Task { await viewModel.searchSongs(query: query) } }
            )
            .navigationTitle("Search")
        }
    }
}
*/
