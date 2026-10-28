import Foundation
import CoreGraphics

// MARK: - Ambient Environment Type
public enum AmbientEnvironmentType: String, Codable, CaseIterable {
    case rain
    case snow
    case fog
    case sunlight
    case wind
    case fallingLeaves
    
    public var displayName: String {
        switch self {
        case .rain: return "Gentle Rain"
        case .snow: return "Quiet Snow"
        case .fog: return "Misty Fog"
        case .sunlight: return "Golden Sunlight"
        case .wind: return "Breezy Wind"
        case .fallingLeaves: return "Autumn Leaves"
        }
    }
    
    public var iconName: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .snow: return "snowflake"
        case .fog: return "cloud.fog.fill"
        case .sunlight: return "sun.max.fill"
        case .wind: return "wind"
        case .fallingLeaves: return "leaf.fill"
        }
    }
}

// MARK: - Ambient Quality Mode
public enum AmbientQualityMode: String, Codable, CaseIterable {
    case lowPower
    case balanced
    case highQuality
    
    public var displayName: String {
        switch self {
        case .lowPower: return "Low Power"
        case .balanced: return "Balanced"
        case .highQuality: return "High Quality"
        }
    }
    
    public var maxParticles: Int {
        switch self {
        case .lowPower: return 40
        case .balanced: return 110
        case .highQuality: return 260
        }
    }
    
    public var frameInterval: TimeInterval {
        switch self {
        case .lowPower: return 1.0 / 20.0 // 20 FPS
        case .balanced: return 1.0 / 30.0 // 30 FPS
        case .highQuality: return 1.0 / 60.0 // 60 FPS
        }
    }
}

// MARK: - Ambient Particle
public struct AmbientParticle: Identifiable, Equatable {
    public let id: UUID
    public var x: CGFloat
    public var y: CGFloat
    public var vx: CGFloat
    public var vy: CGFloat
    public var size: CGFloat
    public var opacity: CGFloat
    public var rotation: CGFloat
    public var rotationSpeed: CGFloat
    public var layer: Int // 0: background (smaller, slower), 1: foreground (larger, faster)
    public var environment: AmbientEnvironmentType
    
    public init(
        id: UUID = UUID(),
        x: CGFloat,
        y: CGFloat,
        vx: CGFloat,
        vy: CGFloat,
        size: CGFloat,
        opacity: CGFloat,
        rotation: CGFloat = 0,
        rotationSpeed: CGFloat = 0,
        layer: Int = 0,
        environment: AmbientEnvironmentType
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.size = size
        self.opacity = opacity
        self.rotation = rotation
        self.rotationSpeed = rotationSpeed
        self.layer = layer
        self.environment = environment
    }
}

// MARK: - Atmosphere Preset
public struct AtmospherePreset: Codable, Identifiable, Equatable {
    public let id: UUID
    public var presetKey: String
    public var name: String
    public var environmentType: AmbientEnvironmentType
    public var intensity: Double       // 0.1 ... 1.0
    public var windStrength: Double    // -1.0 (left) ... 1.0 (right)
    public var qualityMode: AmbientQualityMode
    public var companionReactionsAllowed: Bool
    public var isBuiltIn: Bool
    
    public init(
        id: UUID = UUID(),
        presetKey: String,
        name: String,
        environmentType: AmbientEnvironmentType,
        intensity: Double = 0.5,
        windStrength: Double = 0.2,
        qualityMode: AmbientQualityMode = .balanced,
        companionReactionsAllowed: Bool = true,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.presetKey = presetKey
        self.name = name
        self.environmentType = environmentType
        self.intensity = min(max(intensity, 0.1), 1.0)
        self.windStrength = min(max(windStrength, -1.0), 1.0)
        self.qualityMode = qualityMode
        self.companionReactionsAllowed = companionReactionsAllowed
        self.isBuiltIn = isBuiltIn
    }
    
    // Built-in presets
    public static let builtInPresets: [AtmospherePreset] = [
        AtmospherePreset(
            presetKey: "rainy_evening",
            name: "Rainy Evening",
            environmentType: .rain,
            intensity: 0.65,
            windStrength: 0.15,
            qualityMode: .balanced,
            companionReactionsAllowed: true,
            isBuiltIn: true
        ),
        AtmospherePreset(
            presetKey: "first_snow",
            name: "First Snow",
            environmentType: .snow,
            intensity: 0.55,
            windStrength: -0.1,
            qualityMode: .balanced,
            companionReactionsAllowed: true,
            isBuiltIn: true
        ),
        AtmospherePreset(
            presetKey: "autumn_window",
            name: "Autumn Window",
            environmentType: .fallingLeaves,
            intensity: 0.70,
            windStrength: 0.45,
            qualityMode: .highQuality,
            companionReactionsAllowed: true,
            isBuiltIn: true
        ),
        AtmospherePreset(
            presetKey: "golden_morning",
            name: "Golden Morning",
            environmentType: .sunlight,
            intensity: 0.75,
            windStrength: 0.05,
            qualityMode: .balanced,
            companionReactionsAllowed: true,
            isBuiltIn: true
        ),
        AtmospherePreset(
            presetKey: "quiet_night",
            name: "Quiet Night",
            environmentType: .fog,
            intensity: 0.40,
            windStrength: -0.05,
            qualityMode: .lowPower,
            companionReactionsAllowed: true,
            isBuiltIn: true
        ),
        AtmospherePreset(
            presetKey: "misty_forest",
            name: "Misty Forest",
            environmentType: .fog,
            intensity: 0.60,
            windStrength: 0.20,
            qualityMode: .balanced,
            companionReactionsAllowed: true,
            isBuiltIn: true
        )
    ]
}

// MARK: - Collectible Minigame Models
public enum CollectibleRarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    
    public var displayName: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Legendary"
        }
    }
    
    public var pointValue: Int {
        switch self {
        case .common: return 10
        case .uncommon: return 25
        case .rare: return 50
        case .epic: return 100
        }
    }
    
    public var weight: Double {
        switch self {
        case .common: return 0.55
        case .uncommon: return 0.28
        case .rare: return 0.13
        case .epic: return 0.04
        }
    }
}

public struct CollectibleItem: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let rarity: CollectibleRarity
    public var x: CGFloat
    public var y: CGFloat
    public var vx: CGFloat
    public var vy: CGFloat
    public var size: CGFloat
    public var isCollected: Bool
    public var symbolName: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        rarity: CollectibleRarity,
        x: CGFloat,
        y: CGFloat,
        vx: CGFloat = 0,
        vy: CGFloat = -1.2,
        size: CGFloat = 28.0,
        isCollected: Bool = false,
        symbolName: String = "sparkle"
    ) {
        self.id = id
        self.name = name
        self.rarity = rarity
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.size = size
        self.isCollected = isCollected
        self.symbolName = symbolName
    }
}

// MARK: - Weather Condition & Inverse Mode
public struct WeatherCondition: Codable, Equatable {
    public let temperatureCelsius: Double
    public let weatherCode: Int
    public let windSpeedKmh: Double
    public let conditionDescription: String
    public let isDay: Bool
    
    public init(
        temperatureCelsius: Double,
        weatherCode: Int,
        windSpeedKmh: Double,
        conditionDescription: String,
        isDay: Bool = true
    ) {
        self.temperatureCelsius = temperatureCelsius
        self.weatherCode = weatherCode
        self.windSpeedKmh = windSpeedKmh
        self.conditionDescription = conditionDescription
        self.isDay = isDay
    }
    
    // Maps WMO code to native AmbientEnvironmentType
    public var mappedEnvironment: AmbientEnvironmentType {
        switch weatherCode {
        case 51...67, 80...82: // Drizzle & Rain
            return .rain
        case 71...77, 85...86: // Snow
            return .snow
        case 45, 48:           // Fog
            return .fog
        case 0, 1:             // Clear sky, mostly sunny
            return .sunlight
        case 2, 3:             // Partly cloudy, breezy
            return windSpeedKmh > 20 ? .wind : .fallingLeaves
        default:
            return windSpeedKmh > 25 ? .wind : .sunlight
        }
    }
    
    // Deterministic Inverse Mode Mapping:
    // External Rain -> Cozy Sunlight
    // External Snow -> Warm Autumn Leaves
    // External Fog -> Bright Sunlight
    // External Clear -> Refreshing Rain
    // External Wind -> Calm Misty Fog
    public var inverseEnvironment: AmbientEnvironmentType {
        switch mappedEnvironment {
        case .rain:
            return .sunlight
        case .snow:
            return .fallingLeaves
        case .fog:
            return .sunlight
        case .sunlight:
            return .rain
        case .wind:
            return .fog
        case .fallingLeaves:
            return .snow
        }
    }
}
