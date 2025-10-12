//
//  BaseViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Base ViewModel Protocol

protocol BaseViewModelProtocol: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }

    func handleError(_ error: Error)
    func clearError()
}

// MARK: - Base ViewModel Implementation

@MainActor
class BaseViewModel: ObservableObject, BaseViewModelProtocol {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {}

    deinit {
        cancellables.removeAll()
    }

    // MARK: - Error Handling

    func handleError(_ error: Error) {
        self.isLoading = false
        self.errorMessage = error.localizedDescription
    }

    func clearError() {
        self.errorMessage = nil
    }

    // MARK: - Loading State Management

    func withLoading<T>(_ operation: @escaping () async throws -> T) async -> T? {
        self.isLoading = true
        defer { isLoading = false }

        do {
            return try await operation()
        } catch {
            self.handleError(error)
            return nil
        }
    }

    func withLoadingSync<T>(_ operation: () throws -> T) -> T? {
        self.isLoading = true
        defer { isLoading = false }

        do {
            return try operation()
        } catch {
            self.handleError(error)
            return nil
        }
    }
}
