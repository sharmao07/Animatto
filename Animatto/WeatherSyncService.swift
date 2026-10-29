import Foundation
import Combine

// MARK: - Weather Provider Protocol
public protocol WeatherProviderProtocol {
    var providerName: String { get }
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherCondition
}

// MARK: - Open-Meteo Implementation (Open-Access, No API Key Required)
public class OpenMeteoWeatherProvider: WeatherProviderProtocol {
    public let providerName = "Open-Meteo"
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherCondition {
        // Coarsen coordinates to 1 decimal place (~10km radius) to protect user location privacy
        let coarseLat = (latitude * 10.0).rounded() / 10.0
        let coarseLon = (longitude * 10.0).rounded() / 10.0
        
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.1f", coarseLat)),
            URLQueryItem(name: "longitude", value: String(format: "%.1f", coarseLon)),
            URLQueryItem(name: "current_weather", value: "true")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let current = json["current_weather"] as? [String: Any],
              let temp = current["temperature"] as? Double,
              let weatherCode = current["weathercode"] as? Int,
              let windSpeed = current["windspeed"] as? Double else {
            throw URLError(.cannotParseResponse)
        }
        
        let isDay = (current["is_day"] as? Int ?? 1) == 1
        
        return WeatherCondition(
            temperatureCelsius: temp,
            weatherCode: weatherCode,
            windSpeedKmh: windSpeed,
            conditionDescription: "Open-Meteo Code \(weatherCode)",
            isDay: isDay
        )
    }
}

// MARK: - Weather Synchronization Service
public class WeatherSyncService: ObservableObject {
    public static let shared = WeatherSyncService()
    
    @Published public var isSyncEnabled: Bool = false {
        didSet {
            handleSyncStateChange()
            savePreferences()
        }
    }
    
    @Published public var isInverseModeEnabled: Bool = false {
        didSet {
            applyCurrentWeatherToEngine()
            savePreferences()
        }
    }
    
    @Published public private(set) var lastCondition: WeatherCondition?
    @Published public private(set) var lastSyncTime: Date?
    @Published public private(set) var statusMessage: String = "Offline (Manual Selection)"
    
    @Published public var userLatitude: Double = 37.7749
    @Published public var userLongitude: Double = -122.4194
    @Published public var userCityName: String = "San Francisco"
    
    public var provider: WeatherProviderProtocol = OpenMeteoWeatherProvider()
    public var minRefreshIntervalSeconds: TimeInterval = 900.0 // 15 Minutes minimum rate-limit
    
    private var refreshTimer: Timer?
    private let prefsKey = "com.dev.Animatto.weather_sync_prefs"
    
    public init() {
        loadPreferences()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Synchronization Lifecycle
    
    private func handleSyncStateChange() {
        if isSyncEnabled {
            statusMessage = "Syncing with \(provider.providerName)..."
            startPeriodicSync()
            Task {
                await refreshWeather()
            }
        } else {
            stopPeriodicSync()
            statusMessage = "Offline (Manual Selection)"
        }
    }
    
    private func startPeriodicSync() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: minRefreshIntervalSeconds, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.refreshWeather()
            }
        }
    }
    
    private func stopPeriodicSync() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    @MainActor
    public func refreshWeather() async {
        guard isSyncEnabled else { return }
        
        // Rate-limit check
        if let last = lastSyncTime, Date().timeIntervalSince(last) < 60.0 {
            statusMessage = "Cached (\(Int(Date().timeIntervalSince(last)))s ago)"
            return
        }
        
        statusMessage = "Updating weather..."
        do {
            let condition = try await provider.fetchWeather(latitude: userLatitude, longitude: userLongitude)
            self.lastCondition = condition
            self.lastSyncTime = Date()
            self.statusMessage = "\(Int(condition.temperatureCelsius))°C, \(condition.mappedEnvironment.displayName)"
            applyCurrentWeatherToEngine()
        } catch {
            statusMessage = "Sync failed; using cached ambience"
        }
    }
    
    public func applyCurrentWeatherToEngine() {
        guard let cond = lastCondition else { return }
        let targetEnvironment = isInverseModeEnabled ? cond.inverseEnvironment : cond.mappedEnvironment
        
        AmbientEngine.shared.currentEnvironment = targetEnvironment
        if cond.windSpeedKmh > 20 {
            AmbientEngine.shared.windStrength = min(cond.windSpeedKmh / 50.0, 1.0)
        }
    }
    
    // MARK: - Privacy & Location Clearing
    
    public func clearLocationData() {
        userLatitude = 0.0
        userLongitude = 0.0
        userCityName = ""
        isSyncEnabled = false
        lastCondition = nil
        lastSyncTime = nil
        statusMessage = "Location cleared. Offline mode active."
        savePreferences()
    }
    
    // MARK: - Persistence
    
    private func savePreferences() {
        let dict: [String: Any] = [
            "isSyncEnabled": isSyncEnabled,
            "isInverseModeEnabled": isInverseModeEnabled,
            "userLatitude": userLatitude,
            "userLongitude": userLongitude,
            "userCityName": userCityName
        ]
        UserDefaults.standard.set(dict, forKey: prefsKey)
    }
    
    private func loadPreferences() {
        guard let dict = UserDefaults.standard.dictionary(forKey: prefsKey) else { return }
        if let enabled = dict["isSyncEnabled"] as? Bool { self.isSyncEnabled = enabled }
        if let inverse = dict["isInverseModeEnabled"] as? Bool { self.isInverseModeEnabled = inverse }
        if let lat = dict["userLatitude"] as? Double { self.userLatitude = lat }
        if let lon = dict["userLongitude"] as? Double { self.userLongitude = lon }
        if let city = dict["userCityName"] as? String { self.userCityName = city }
    }
}
