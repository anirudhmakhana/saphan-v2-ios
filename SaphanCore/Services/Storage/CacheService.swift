import Foundation

public class CacheService {
    private let cache: NSCache<NSString, CachedTranslation>
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    public init() {
        self.cache = NSCache<NSString, CachedTranslation>()
        self.cache.countLimit = Constants.Limits.maxCachedTranslations

        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID) {
            self.cacheDirectory = containerURL.appendingPathComponent("TranslationCache", isDirectory: true)
        } else {
            self.cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("TranslationCache", isDirectory: true)
        }

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    public func getCachedTranslation(for key: String) -> TranslationResponse? {
        if let cached = cache.object(forKey: key as NSString) {
            if cached.isExpired {
                cache.removeObject(forKey: key as NSString)
                return nil
            }
            return cached.response
        }

        if let cached = loadFromDisk(key: key) {
            if cached.isExpired {
                removeFromDisk(key: key)
                return nil
            }
            cache.setObject(cached, forKey: key as NSString)
            return cached.response
        }

        return nil
    }

    public func cacheTranslation(_ response: TranslationResponse, for key: String) {
        let cached = CachedTranslation(response: response)
        cache.setObject(cached, forKey: key as NSString)
        saveToDisk(cached: cached, key: key)
    }

    public func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func loadFromDisk(key: String) -> CachedTranslation? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(CachedTranslation.self, from: data)
    }

    private func saveToDisk(cached: CachedTranslation, key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        if let data = try? JSONEncoder().encode(cached) {
            try? data.write(to: fileURL)
        }
    }

    private func removeFromDisk(key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? fileManager.removeItem(at: fileURL)
    }
}

private class CachedTranslation: Codable {
    let response: TranslationResponse
    let timestamp: Date

    init(response: TranslationResponse, timestamp: Date = Date()) {
        self.response = response
        self.timestamp = timestamp
    }

    var isExpired: Bool {
        let expirationInterval: TimeInterval = 24 * 60 * 60
        return Date().timeIntervalSince(timestamp) > expirationInterval
    }
}
