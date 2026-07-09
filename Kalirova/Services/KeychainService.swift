import Foundation
import Security

enum KeychainServiceError: LocalizedError {
    case unexpectedStatus(OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status): "Keychain operation failed with status \(status)."
        case .invalidData: "Stored Keychain data is invalid."
        }
    }
}

final class KeychainService: @unchecked Sendable {
    static let shared = KeychainService()

    private let service: String
    private let openAIAccount: String
    private let legacyOpenAIAccount = "openai-api-key"

    init(service: String = "com.kalirova.app", openAIAccount: String = "openai_api_key") {
        self.service = service
        self.openAIAccount = openAIAccount
    }

    func saveOpenAIAPIKey(_ apiKey: String) throws {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            throw KeychainServiceError.invalidData
        }

        let query = baseQuery(account: openAIAccount)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw KeychainServiceError.unexpectedStatus(updateStatus)
        }

        let status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainServiceError.unexpectedStatus(status)
        }
    }

    func loadOpenAIAPIKey() throws -> String? {
        if let apiKey = try loadOpenAIAPIKey(account: openAIAccount) {
            return apiKey
        }

        guard openAIAccount != legacyOpenAIAccount, let legacyAPIKey = try loadOpenAIAPIKey(account: legacyOpenAIAccount) else {
            return nil
        }

        try saveOpenAIAPIKey(legacyAPIKey)
        try deleteOpenAIAPIKey(account: legacyOpenAIAccount)
        return legacyAPIKey
    }

    func deleteOpenAIAPIKey() throws {
        try deleteOpenAIAPIKey(account: openAIAccount)
    }

    static func maskedAPIKey(_ apiKey: String) -> String {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "No key saved"
        }

        let suffix = String(trimmed.suffix(4))
        if trimmed.hasPrefix("sk-") {
            return "sk-...\(suffix)"
        }

        return "Stored key ...\(suffix)"
    }

    private func loadOpenAIAPIKey(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainServiceError.unexpectedStatus(status)
        }

        guard
            let data = item as? Data,
            let apiKey = String(data: data, encoding: .utf8)
        else {
            throw KeychainServiceError.invalidData
        }

        return apiKey
    }

    private func deleteOpenAIAPIKey(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainServiceError.unexpectedStatus(status)
        }
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
