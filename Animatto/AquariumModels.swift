import Foundation
import CoreGraphics
import SwiftUI

// MARK: - Aquarium Presentation Mode
public enum AquariumPresentationMode: String, Codable, CaseIterable {
    case dedicatedWindow
    case desktopOverlay
    
    public var displayName: String {
        switch self {
        case .dedicatedWindow: return "Glass Tank Window"
        case .desktopOverlay: return "Desktop Water World"
        }
    }
}

// MARK: - Tank Size Preset
public enum TankSizePreset: String, Codable, CaseIterable {
    case compact
    case standard
    case panoramic
    case custom
    
    public var displayName: String {
        switch self {
        case .compact: return "Compact (480 × 320)"
        case .standard: return "Standard (720 × 480)"
        case .panoramic: return "Panoramic (960 × 540)"
        case .custom: return "Custom Resizable"
        }
    }
    
    public var defaultDimensions: CGSize {
        switch self {
        case .compact: return CGSize(width: 480, height: 320)
        case .standard: return CGSize(width: 720, height: 480)
        case .panoramic: return CGSize(width: 960, height: 540)
        case .custom: return CGSize(width: 720, height: 480)
        }
    }
}

// MARK: - Water Atmosphere Theme
public enum WaterAtmosphereTheme: String, Codable, CaseIterable {
    case tropicalReef
    case freshwaterRiver
    case midnightAbyss
    case sunsetLagoon
    
    public var displayName: String {
        switch self {
        case .tropicalReef: return "Tropical Coral Reef"
        case .freshwaterRiver: return "Freshwater Riverbed"
        case .midnightAbyss: return "Midnight Abyss"
        case .sunsetLagoon: return "Sunset Lagoon"
        }
    }
    
    public var gradientColors: (top: Color, mid: Color, bottom: Color) {
        switch self {
        case .tropicalReef:
            return (
                Color(red: 0.40, green: 0.88, blue: 0.82),
                Color(red: 0.00, green: 0.60, blue: 0.72),
                Color(red: 0.00, green: 0.23, blue: 0.36)
            )
        case .freshwaterRiver:
            return (
                Color(red: 0.32, green: 0.64, blue: 0.41),
                Color(red: 0.12, green: 0.37, blue: 0.22),
                Color(red: 0.04, green: 0.18, blue: 0.10)
            )
        case .midnightAbyss:
            return (
                Color(red: 0.11, green: 0.16, blue: 0.35),
                Color(red: 0.03, green: 0.09, blue: 0.21),
                Color(red: 0.01, green: 0.03, blue: 0.08)
            )
        case .sunsetLagoon:
            return (
                Color(red: 0.90, green: 0.45, blue: 0.35),
                Color(red: 0.46, green: 0.15, blue: 0.29),
                Color(red: 0.18, green: 0.04, blue: 0.23)
            )
        }
    }
}

// MARK: - Ecological Niches
public enum AquaticNiche: String, Codable, CaseIterable {
    case pelagic
    case surface
    case benthic
    case cryptic
    
    public var displayName: String {
        switch self {
        case .pelagic: return "Pelagic Cruiser"
        case .surface: return "Surface Explorer"
        case .benthic: return "Bottom Dweller"
        case .cryptic: return "Flora & Cave Dweller"
        }
    }
}

// MARK: - Clean Protocol for Future Aquatic Companions
public protocol AquaticCompanionProtocol: AnyObject {
    var id: UUID { get }
    var speciesId: String { get }
    var displayName: String { get }
    var niche: AquaticNiche { get }
    var state: AquaticEntityState { get set }
    var physicsConfig: AquaticPhysicsConfig { get }
    
    func stepPhysics(bounds: AquaticBounds, dt: TimeInterval)
}

// MARK: - Concrete Companion Implementation
public final class AquaticCompanionInstance: AquaticCompanionProtocol, Identifiable {
    public let id: UUID
    public let speciesId: String
    public var displayName: String
    public let niche: AquaticNiche
    public var state: AquaticEntityState
    public var physicsConfig: AquaticPhysicsConfig
    public var targetWaypoint: AquaticVector3D?
    public var wanderTimer: TimeInterval = 0.0
    
    public init(
        id: UUID = UUID(),
        speciesId: String,
        displayName: String,
        niche: AquaticNiche = .pelagic,
        initialState: AquaticEntityState = AquaticEntityState(),
        physicsConfig: AquaticPhysicsConfig = .pelagicDefault
    ) {
        self.id = id
        self.speciesId = speciesId
        self.displayName = displayName
        self.niche = niche
        self.state = initialState
        self.physicsConfig = physicsConfig
    }
    
    public func stepPhysics(bounds: AquaticBounds, dt: TimeInterval) {
        // Autonomous wander target update
        wanderTimer -= dt
        if wanderTimer <= 0.0 {
            wanderTimer = Double.random(in: 3.0...6.0)
            targetWaypoint = pickNextWaypoint(bounds: bounds)
        }
        
        let thrust: Double = state.isResting ? 0.0 : (niche == .benthic ? 35.0 : 50.0)
        
        state = AquaticPhysicsSimulator.shared.step(
            state: state,
            bounds: bounds,
            targetWaypoint: targetWaypoint,
            thrustForce: thrust,
            config: physicsConfig,
            deltaTime: dt
        )
    }
    
    public func pickNextWaypoint(bounds: AquaticBounds) -> AquaticVector3D {
        let margin = bounds.margin
        let x = Double.random(in: (bounds.minX + margin)...(bounds.maxX - margin))
        let y: Double
        let z: Double
        
        switch niche {
        case .pelagic:
            y = Double.random(in: (bounds.minY + bounds.height * 0.2)...(bounds.maxY - bounds.height * 0.2))
            z = Double.random(in: 0.2...0.7)
        case .surface:
            y = Double.random(in: (bounds.maxY - bounds.height * 0.25)...bounds.maxY)
            z = Double.random(in: 0.1...0.5)
        case .benthic:
            y = bounds.minY + 6.0
            z = Double.random(in: 0.3...0.8)
        case .cryptic:
            y = Double.random(in: (bounds.minY + 16.0)...(bounds.minY + bounds.height * 0.5))
            z = Double.random(in: 0.5...0.9)
        }
        return AquaticVector3D(x: x, y: y, z: z)
    }
}

// MARK: - Scene Particle & Flora Models
public struct AquariumBubble: Identifiable, Sendable {
    public let id: UUID
    public var x: Double
    public var y: Double
    public var z: Double
    public var radius: Double
    public var speed: Double
    public var wobblePhase: Double
    public var wobbleFrequency: Double
    public var opacity: Double
    
    public init(
        id: UUID = UUID(),
        x: Double,
        y: Double,
        z: Double = 0.5,
        radius: Double = Double.random(in: 2.0...5.0),
        speed: Double = Double.random(in: 40.0...85.0),
        wobblePhase: Double = Double.random(in: 0.0...(.pi * 2.0)),
        wobbleFrequency: Double = Double.random(in: 2.5...5.0),
        opacity: Double = Double.random(in: 0.4...0.8)
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.z = z
        self.radius = radius
        self.speed = speed
        self.wobblePhase = wobblePhase
        self.wobbleFrequency = wobbleFrequency
        self.opacity = opacity
    }
}

public struct AquariumPlant: Identifiable, Sendable {
    public let id: UUID
    public var rootX: Double
    public var height: Double
    public var width: Double
    public var phaseOffset: Double
    public var stalkCount: Int
    
    public init(
        id: UUID = UUID(),
        rootX: Double,
        height: Double,
        width: Double = 28.0,
        phaseOffset: Double = 0.0,
        stalkCount: Int = 3
    ) {
        self.id = id
        self.rootX = rootX
        self.height = height
        self.width = width
        self.phaseOffset = phaseOffset
        self.stalkCount = stalkCount
    }
}

// MARK: - Aquarium Settings
public struct AquariumSettings: Codable, Equatable {
    // Feature Flag: Desktop overlay mode is disabled by default until click-through and window-level are verified
    public static let isDesktopOverlayModeEnabled: Bool = false
    
    public var isEnabled: Bool = false
    public var presentationMode: AquariumPresentationMode = .dedicatedWindow
    public var tankSizePreset: TankSizePreset = .standard
    public var customWidth: Double = 720.0
    public var customHeight: Double = 480.0
    public var staysOnTop: Bool = false
    
    // Water & Lighting
    public var waterTheme: WaterAtmosphereTheme = .tropicalReef
    public var waterClarity: Double = 0.85
    public var causticIntensity: Double = 0.6
    public var lightingCycleEnabled: Bool = true
    
    // Flora & Particles
    public var bubbleIntensity: Double = 0.5
    public var plantDensity: Int = 4
    public var qualityMode: AmbientQualityMode = .balanced
    
    // Audio
    public var soundEnabled: Bool = true
    public var aeratorVolume: Double = 0.35
    public var waterSoundVolume: Double = 0.25
    
    // Population
    public var maxCreatureCount: Int = 6
    
    // Accessibility
    public var reduceMotion: Bool = false
    
    public init() {}
    
    public var effectiveDimensions: CGSize {
        switch tankSizePreset {
        case .compact, .standard, .panoramic:
            return tankSizePreset.defaultDimensions
        case .custom:
            return CGSize(width: max(320, customWidth), height: max(240, customHeight))
        }
    }
}
