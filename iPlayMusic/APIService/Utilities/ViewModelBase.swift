// ViewModelBase.swift
// Reusable ViewModel utilities for SwiftUI — handles loading, error, success states

import Foundation
import SwiftUI
import Combine

// MARK: - Loading State

enum LoadingState<T> {
    case idle
    case loading
    case success(T)
    case failure(APIError)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var value: T? {
        if case .success(let val) = self { return val }
        return nil
    }
    
    var error: APIError? {
        if case .failure(let err) = self { return err }
        return nil
    }
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var hasError: Bool {
        if case .failure = self { return true }
        return false
    }
}

// MARK: - Base ViewModel

@MainActor
class BaseViewModel: ObservableObject {
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    var cancellables = Set<AnyCancellable>()
    
    /// Execute an async operation safely — handles loading + error states automatically
    func execute<T>(
        _ operation: () async throws -> T,
        onSuccess: ((T) -> Void)? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let result = try await operation()
            isLoading = false
            onSuccess?(result)
        } catch let error as APIError {
            isLoading = false
            errorMessage = error.errorDescription
            showError = true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Example: Artist Detail ViewModel
