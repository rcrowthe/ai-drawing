//
//  PersistenceService.swift
//  AIDrawing
//
//  Handles saving and loading of sessions and user profiles
//

import Foundation

class PersistenceService {
    static let shared = PersistenceService()

    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard

    init() {}

    // MARK: - File URLs

    private var documentsURL: URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func sessionURL(for id: UUID) -> URL {
        return documentsURL
            .appendingPathComponent("sessions")
            .appendingPathComponent("\(id.uuidString).json")
    }

    private var sessionsDirectory: URL {
        return documentsURL.appendingPathComponent("sessions")
    }

    // MARK: - Session Persistence

    func saveSession(_ session: DrawingSession) throws {
        // Ensure sessions directory exists
        try? fileManager.createDirectory(
            at: sessionsDirectory,
            withIntermediateDirectories: true
        )

        let url = sessionURL(for: session.id)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(session)
        try data.write(to: url)
    }

    func loadSession(id: UUID) throws -> DrawingSession {
        let url = sessionURL(for: id)
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(DrawingSession.self, from: data)
    }

    func listSessions() -> [UUID] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: sessionsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { UUID(uuidString: $0.deletingPathExtension().lastPathComponent) }
    }

    func deleteSession(id: UUID) throws {
        let url = sessionURL(for: id)
        try fileManager.removeItem(at: url)
    }

    // MARK: - Configuration Persistence

    private let configurationKey = "aiConfiguration"

    func saveConfiguration(_ configuration: AIConfiguration) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(configuration) {
            userDefaults.set(data, forKey: configurationKey)
        }
    }

    func loadConfiguration() -> AIConfiguration? {
        guard let data = userDefaults.data(forKey: configurationKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(AIConfiguration.self, from: data)
    }

    // MARK: - User Profile Persistence

    private let profileKey = "userProfile"

    func saveProfile(_ profile: UserProfile) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(profile) {
            userDefaults.set(data, forKey: profileKey)
        }
    }

    func loadProfile() -> UserProfile? {
        guard let data = userDefaults.data(forKey: profileKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(UserProfile.self, from: data)
    }

    // Alias methods for compatibility
    func saveUserProfile(_ profile: UserProfile) {
        saveProfile(profile)
    }

    func loadUserProfile() -> UserProfile? {
        return loadProfile()
    }

    // MARK: - Current Session ID

    private let currentSessionKey = "currentSessionID"

    func saveCurrentSessionID(_ id: UUID) {
        userDefaults.set(id.uuidString, forKey: currentSessionKey)
    }

    func loadCurrentSessionID() -> UUID? {
        guard let uuidString = userDefaults.string(forKey: currentSessionKey) else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }
}
