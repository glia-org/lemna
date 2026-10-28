import CryptoKit
import Foundation
import Security

/// Where session keys live. The journal stores a session's key before the session's first write and destroys it on
/// Done or Discard, which is what makes the file unreadable (crypto-shredding; files cannot be erased on APFS/SSD).
public protocol KeyStore {
    func store(key: SymmetricKey, for session: UUID) throws
    /// nil when the store has no key for the session. Throws when the store would not answer (locked, refused), so
    /// the caller never mistakes "cannot ask now" for "gone".
    func key(for session: UUID) throws -> SymmetricKey?
    /// No error when the key is already gone, so Done can be repeated after a crash.
    func destroy(for session: UUID) throws
    func sessions() throws -> [UUID]
}

public struct KeychainError: Error, CustomStringConvertible {
    public let status: OSStatus
    public var description: String { (SecCopyErrorMessageString(status, nil) as String?) ?? "OSStatus \(status)" }
}

/// Session keys as generic passwords in the user's keychain: service `dev.lemna.app.session` (another for the keys of
/// an older name, `Journal.adopt`), account = the session's UUID string.
public final class KeychainKeyStore: KeyStore {
    public static let service = "dev.lemna.app.session"
    public let service: String

    /// false while the app is ad-hoc signed: the data protection keychain needs a keychain-access-groups entitlement
    /// authorised by a provisioning profile, and fails with -34018 (errSecMissingEntitlement) without one.
    public let useDataProtectionKeychain: Bool

    public init(service: String = KeychainKeyStore.service, useDataProtectionKeychain: Bool = false) {
        self.service = service
        self.useDataProtectionKeychain = useDataProtectionKeychain
    }

    public func store(key: SymmetricKey, for session: UUID) throws {
        var q = query(session)
        q[kSecValueData as String] = key.withUnsafeBytes { Data($0) }
        // Apple: kSecAttrAccessible applies to macOS items only in the data protection keychain (or synchronizable
        // ones). The login keychain has no protection classes; its item is readable while that keychain is unlocked.
        if useDataProtectionKeychain {
            q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
        try check(SecItemAdd(q as CFDictionary, nil))
    }

    public func key(for session: UUID) throws -> SymmetricKey? {
        var q = query(session)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        if status == errSecItemNotFound { return nil }
        try check(status)
        guard let data = out as? Data else { throw KeychainError(status: errSecDecode) }
        return SymmetricKey(data: data)
    }

    public func destroy(for session: UUID) throws {
        let status = SecItemDelete(query(session) as CFDictionary)
        if status != errSecItemNotFound { try check(status) }
    }

    public func sessions() throws -> [UUID] {
        var q = query(nil)
        q[kSecReturnAttributes as String] = true  // attributes only: listing never asks for the secrets
        q[kSecMatchLimit as String] = kSecMatchLimitAll
        var out: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        if status == errSecItemNotFound { return [] }
        try check(status)
        let items = out as? [[String: Any]] ?? []
        return items.compactMap { ($0[kSecAttrAccount as String] as? String).flatMap(UUID.init(uuidString:)) }
    }

    private func query(_ session: UUID?) -> [String: Any] {
        var q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]
        if let session { q[kSecAttrAccount as String] = session.uuidString }
        if useDataProtectionKeychain { q[kSecUseDataProtectionKeychain as String] = true }
        return q
    }

    private func check(_ status: OSStatus) throws {
        if status != errSecSuccess { throw KeychainError(status: status) }
    }
}

/// Keys in a dictionary, for tests. Not thread-safe; the journal calls its store only from the caller's thread.
public final class MemoryKeyStore: KeyStore {
    private var keys: [UUID: SymmetricKey] = [:]

    public init() {}

    public func store(key: SymmetricKey, for session: UUID) throws { keys[session] = key }
    public func key(for session: UUID) throws -> SymmetricKey? { keys[session] }
    public func destroy(for session: UUID) throws { keys[session] = nil }
    public func sessions() throws -> [UUID] { Array(keys.keys) }
}
