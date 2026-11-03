import Foundation
import CoreGraphics
import SwiftUI
import Combine

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
    // Desktop Widget Presets
    case small
    case medium
    case large
    case panoramicWidget
    
    // Legacy / Expanded Canvas Presets
    case compact
    case standard
    case panoramic
    case custom
    
    public var displayName: String {
        switch self {
        case .small: return "Small Widget (280 × 180)"
        case .medium: return "Medium Widget (420 × 280)"
        case .large: return "Large Widget (560 × 360)"
        case .panoramicWidget: return "Panoramic Widget (640 × 240)"
        case .compact: return "Compact (480 × 320)"
        case .standard: return "Standard (720 × 480)"
        case .panoramic: return "Panoramic (960 × 540)"
        case .custom: return "Custom Resizable"
        }
    }
    
    public var defaultDimensions: CGSize {
        switch self {
        case .small: return CGSize(width: 280, height: 180)
        case .medium: return CGSize(width: 420, height: 280)
        case .large: return CGSize(width: 560, height: 360)
        case .panoramicWidget: return CGSize(width: 640, height: 240)
        case .compact: return CGSize(width: 480, height: 320)
        case .standard: return CGSize(width: 720, height: 480)
        case .panoramic: return CGSize(width: 960, height: 540)
        case .custom: return CGSize(width: 420, height: 280)
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

// MARK: - Directory Resolver
public struct AquariumDirectoryResolver {
    public static func resolveAquariumSpeciesDirectory(speciesFolder: String) -> URL? {
        let relativePaths = [
            "Animatto/DefaultCompanions/Aquarium/\(speciesFolder)",
            "DefaultCompanions/Aquarium/\(speciesFolder)",
            "Aquarium/\(speciesFolder)"
        ]
        for rel in relativePaths {
            let url = URL(fileURLWithPath: rel)
            let manifest = url.appendingPathComponent("manifest.json")
            if FileManager.default.fileExists(atPath: manifest.path) {
                return url
            }
        }
        if let bundle = Bundle.main.resourceURL {
            let candidates = [
                bundle.appendingPathComponent("DefaultCompanions/Aquarium/\(speciesFolder)"),
                bundle.appendingPathComponent("Aquarium/\(speciesFolder)"),
                bundle.appendingPathComponent("Contents/Resources/DefaultCompanions/Aquarium/\(speciesFolder)"),
                bundle.appendingPathComponent("Resources/DefaultCompanions/Aquarium/\(speciesFolder)")
            ]
            for candidate in candidates {
                if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("manifest.json").path) {
                    return candidate
                }
            }
        }
        return nil
    }
}

// MARK: - Aquatic Companion Animation State
public enum AquaticCompanionState: String, Codable, CaseIterable {
    case swim_idle
    case swim_active
    case turn
    case feed
    case rest
    case dart
}

// MARK: - Aquatic Species Profile
public struct AquaticSpeciesProfile: Codable, Equatable, Identifiable {
    public var id: String { speciesId }
    public let speciesId: String
    public let displayName: String
    public let scientificName: String
    public let niche: AquaticNiche
    public let folderName: String
    public let renderSize: CGSize
    public let cruiseSpeed: Double
    public let maxSpeed: Double
    public let turningSpeedDegPerSec: Double
    public let schoolingAffinity: Double
    public let boldness: Double
    public let curiosity: Double
    public let energy: Double
    public let friendliness: Double
    public let minZ: Double
    public let maxZ: Double
    public let preferredZ: Double
    
    public init(
        speciesId: String,
        displayName: String,
        scientificName: String,
        niche: AquaticNiche,
        folderName: String,
        renderSize: CGSize,
        cruiseSpeed: Double,
        maxSpeed: Double,
        turningSpeedDegPerSec: Double = 180.0,
        schoolingAffinity: Double = 0.0,
        boldness: Double = 0.5,
        curiosity: Double = 0.5,
        energy: Double = 0.8,
        friendliness: Double = 0.5,
        minZ: Double = 0.1,
        maxZ: Double = 0.8,
        preferredZ: Double = 0.4
    ) {
        self.speciesId = speciesId
        self.displayName = displayName
        self.scientificName = scientificName
        self.niche = niche
        self.folderName = folderName
        self.renderSize = renderSize
        self.cruiseSpeed = cruiseSpeed
        self.maxSpeed = maxSpeed
        self.turningSpeedDegPerSec = turningSpeedDegPerSec
        self.schoolingAffinity = schoolingAffinity
        self.boldness = boldness
        self.curiosity = curiosity
        self.energy = energy
        self.friendliness = friendliness
        self.minZ = minZ
        self.maxZ = maxZ
        self.preferredZ = preferredZ
    }
    
    // Presets for the 4 starter species (Stage 4.3 / 4.4)
    public static let sunfin = AquaticSpeciesProfile(
        speciesId: "animatto.creature.sunfin",
        displayName: "Finny",
        scientificName: "Heliochthys splendens",
        niche: .pelagic,
        folderName: "Sunfin",
        renderSize: CGSize(width: 72, height: 72),
        cruiseSpeed: 65.0,
        maxSpeed: 140.0,
        turningSpeedDegPerSec: 180.0,
        schoolingAffinity: 0.15,
        boldness: 0.8,
        curiosity: 0.8,
        energy: 0.85,
        friendliness: 0.8,
        minZ: 0.15,
        maxZ: 0.65,
        preferredZ: 0.35
    )
    
    public static let puffer = AquaticSpeciesProfile(
        speciesId: "animatto.creature.puffer",
        displayName: "Pip",
        scientificName: "Nanochanna guttatus",
        niche: .surface,
        folderName: "Puffer",
        renderSize: CGSize(width: 60, height: 60),
        cruiseSpeed: 45.0,
        maxSpeed: 110.0,
        turningSpeedDegPerSec: 220.0,
        schoolingAffinity: 0.0,
        boldness: 0.4,
        curiosity: 0.9,
        energy: 0.70,
        friendliness: 0.6,
        minZ: 0.10,
        maxZ: 0.45,
        preferredZ: 0.25
    )
    
    public static let tetra = AquaticSpeciesProfile(
        speciesId: "animatto.creature.tetra",
        displayName: "Glow",
        scientificName: "Spectrachthys caeruleus",
        niche: .pelagic,
        folderName: "Tetra",
        renderSize: CGSize(width: 64, height: 64),
        cruiseSpeed: 55.0,
        maxSpeed: 125.0,
        turningSpeedDegPerSec: 200.0,
        schoolingAffinity: 0.90,
        boldness: 0.3,
        curiosity: 0.5,
        energy: 0.75,
        friendliness: 0.9,
        minZ: 0.30,
        maxZ: 0.85,
        preferredZ: 0.60
    )
    
    public static let hermitCrab = AquaticSpeciesProfile(
        speciesId: "animatto.creature.hermit_crab",
        displayName: "Barnaby",
        scientificName: "Paguropsis muscosus",
        niche: .benthic,
        folderName: "HermitCrab",
        renderSize: CGSize(width: 64, height: 64),
        cruiseSpeed: 25.0,
        maxSpeed: 50.0,
        turningSpeedDegPerSec: 120.0,
        schoolingAffinity: 0.0,
        boldness: 0.3,
        curiosity: 0.4,
        energy: 0.50,
        friendliness: 0.5,
        minZ: 0.40,
        maxZ: 0.90,
        preferredZ: 0.75
    )
}

// MARK: - Aquarium Food Pellet
public struct AquariumFoodPellet: Identifiable, Sendable {
    public let id: UUID
    public var position: AquaticVector3D
    public var velocity: AquaticVector3D
    public var wobblePhase: Double
    public var wobbleFreq: Double
    public var age: TimeInterval
    public var isSettled: Bool
    public var dissolveProgress: Double
    
    public init(
        id: UUID = UUID(),
        position: AquaticVector3D,
        velocity: AquaticVector3D = AquaticVector3D(x: 0, y: -22.0, z: 0),
        wobblePhase: Double = Double.random(in: 0...(.pi * 2)),
        wobbleFreq: Double = 1.2,
        age: TimeInterval = 0.0,
        isSettled: Bool = false,
        dissolveProgress: Double = 0.0
    ) {
        self.id = id
        self.position = position
        self.velocity = velocity
        self.wobblePhase = wobblePhase
        self.wobbleFreq = wobbleFreq
        self.age = age
        self.isSettled = isSettled
        self.dissolveProgress = dissolveProgress
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
public final class AquaticCompanionInstance: AquaticCompanionProtocol, Identifiable, ObservableObject {
    public let id: UUID
    public var speciesId: String { profile.speciesId }
    public var displayName: String {
        get { customName ?? profile.displayName }
        set { customName = newValue }
    }
    public var niche: AquaticNiche { profile.niche }
    public let profile: AquaticSpeciesProfile
    public var state: AquaticEntityState
    public var physicsConfig: AquaticPhysicsConfig
    public var targetWaypoint: AquaticVector3D?
    public var wanderTimer: TimeInterval = 0.0
    
    // Animation & State Machine
    @Published public private(set) var currentAnimationState: AquaticCompanionState = .swim_idle
    public private(set) var sequencePlayer: SpriteSequencePlayer?
    public var energy: Double = 1.0
    public var dartTimer: TimeInterval = 0.0
    public var isFacingRight: Bool = true
    
    private var customName: String?
    private var turnCooldown: TimeInterval = 0.0
    
    public var currentFrameImage: CGImage? {
        return sequencePlayer?.currentFrame
    }
    
    public var renderSize: CGSize {
        return profile.renderSize
    }
    
    public init(
        id: UUID = UUID(),
        profile: AquaticSpeciesProfile,
        initialState: AquaticEntityState = AquaticEntityState(),
        physicsConfig: AquaticPhysicsConfig? = nil,
        directoryURL: URL? = nil
    ) {
        self.id = id
        self.profile = profile
        self.state = initialState
        self.physicsConfig = physicsConfig ?? (profile.niche == .benthic ? .benthicDefault : .pelagicDefault)
        self.isFacingRight = initialState.isFacingRight
        
        let resolvedDir = directoryURL ?? AquariumDirectoryResolver.resolveAquariumSpeciesDirectory(speciesFolder: profile.folderName)
        if let dir = resolvedDir {
            do {
                let player = try SpriteSequencePlayer(directoryURL: dir, initialState: AquaticCompanionState.swim_idle.rawValue)
                self.sequencePlayer = player
                // Configure one-shot auto transition callback
                player.onOneShotComplete = { [weak self] completedState in
                    guard let self = self else { return }
                    if completedState == AquaticCompanionState.turn.rawValue {
                        self.transitionAnimation(to: .swim_active)
                    } else if completedState == AquaticCompanionState.feed.rawValue {
                        self.transitionAnimation(to: .swim_idle)
                    } else if completedState == AquaticCompanionState.dart.rawValue {
                        self.transitionAnimation(to: .swim_active)
                    }
                }
            } catch {
                NSLog("[AquaticCompanionInstance] Could not initialize player for \(profile.displayName): \(error)")
                self.sequencePlayer = nil
            }
        }
    }
    
    public convenience init(
        id: UUID = UUID(),
        speciesId: String,
        displayName: String,
        niche: AquaticNiche = .pelagic,
        initialState: AquaticEntityState = AquaticEntityState(),
        physicsConfig: AquaticPhysicsConfig = .pelagicDefault
    ) {
        let profile: AquaticSpeciesProfile
        switch speciesId {
        case "animatto.creature.sunfin": profile = .sunfin
        case "animatto.creature.puffer": profile = .puffer
        case "animatto.creature.tetra": profile = .tetra
        case "animatto.creature.hermit_crab": profile = .hermitCrab
        default:
            profile = AquaticSpeciesProfile(
                speciesId: speciesId,
                displayName: displayName,
                scientificName: speciesId,
                niche: niche,
                folderName: "Sunfin",
                renderSize: CGSize(width: 72, height: 72),
                cruiseSpeed: 60.0,
                maxSpeed: 120.0
            )
        }
        self.init(id: id, profile: profile, initialState: initialState, physicsConfig: physicsConfig)
    }
    
    // MARK: - Animation State Transitions
    
    public func transitionAnimation(to newState: AquaticCompanionState) {
        guard currentAnimationState != newState else { return }
        currentAnimationState = newState
        sequencePlayer?.transition(to: newState.rawValue)
    }
    
    // MARK: - Behavior & AI Update
    
    public func stepAI(
        bounds: AquaticBounds,
        allCompanions: [AquaticCompanionInstance],
        pellets: inout [AquariumFoodPellet],
        cursorLocation: CGPoint?,
        dt: TimeInterval
    ) {
        // 1. Monotonic animation advance
        sequencePlayer?.advance(by: dt)
        turnCooldown = max(0.0, turnCooldown - dt)
        
        // 2. Dart burst recovery
        if dartTimer > 0.0 {
            dartTimer -= dt
            if dartTimer <= 0.0 {
                dartTimer = 0.0
                if currentAnimationState == .dart {
                    transitionAnimation(to: .swim_active)
                }
            }
        }
        
        // 3. Schooling / Flocking for schooling species (Glow Tetras)
        var steeringImpulse = AquaticVector3D.zero
        if profile.schoolingAffinity > 0.4 {
            let (sep, align, coh) = calculateFlocking(allCompanions: allCompanions)
            steeringImpulse = (sep * 1.5) + (align * 0.8) + (coh * 1.0)
        }
        
        // 4. Food Pellet Detection & Interception
        var isHuntingFood = false
        if currentAnimationState != .dart && !state.isResting && pellets.count > 0 {
            let myPos = state.position
            var closestDistance = Double.infinity
            var closestIndex: Int? = nil
            
            for (idx, pellet) in pellets.enumerated() {
                guard !pellet.isSettled else { continue }
                let dist = (pellet.position - myPos).length2D
                if dist < 220.0 && dist < closestDistance {
                    closestDistance = dist
                    closestIndex = idx
                }
            }
            
            if let targetIdx = closestIndex {
                let targetPellet = pellets[targetIdx]
                isHuntingFood = true
                targetWaypoint = targetPellet.position
                
                // Interception collision check (< 16 pt)
                if closestDistance < 16.0 {
                    pellets.remove(at: targetIdx)
                    transitionAnimation(to: .feed)
                    energy = min(1.0, energy + 0.35)
                    AudioEngine.shared.playAquariumSound(.feedFlake)
                }
            }
        }
        
        // 5. Cursor Awareness
        if !isHuntingFood && currentAnimationState != .dart, let cursor = cursorLocation {
            let cursorX = Double(cursor.x)
            let cursorY = bounds.maxY - Double(cursor.y)
            let cursorVec = AquaticVector3D(x: cursorX, y: cursorY, z: state.position.z)
            let diff = cursorVec - state.position
            let dist = diff.length2D
            
            if profile.curiosity >= 0.75 {
                // Finny curiosity approach: hover 35-50 pt away
                if dist < 220.0 && dist > 45.0 {
                    targetWaypoint = state.position + (diff.normalized * (dist - 40.0))
                }
            } else if profile.boldness <= 0.45 {
                // Pip timid avoidance: back away if cursor is close
                if dist < 70.0 {
                    targetWaypoint = state.position - (diff.normalized * 80.0)
                }
            }
        }
        
        // 6. Autonomous wander target update if idle or arrived
        if !isHuntingFood {
            wanderTimer -= dt
            if wanderTimer <= 0.0 {
                wanderTimer = Double.random(in: 3.5...7.0)
                targetWaypoint = pickNextWaypoint(bounds: bounds)
            }
        }
        
        // 7. Benthic Grounding for Hermit Crab
        if niche == .benthic {
            targetWaypoint = AquaticVector3D(
                x: targetWaypoint?.x ?? state.position.x,
                y: bounds.minY + 6.0,
                z: targetWaypoint?.z ?? 0.75
            )
        }
        
        // 8. Facing & Turn State Detection
        if state.velocity.x > 8.0 && !isFacingRight {
            isFacingRight = true
            state.isFacingRight = true
            if turnCooldown <= 0.0 && (currentAnimationState == .swim_active || currentAnimationState == .swim_idle) {
                transitionAnimation(to: .turn)
                turnCooldown = 1.0
            }
        } else if state.velocity.x < -8.0 && isFacingRight {
            isFacingRight = false
            state.isFacingRight = false
            if turnCooldown <= 0.0 && (currentAnimationState == .swim_active || currentAnimationState == .swim_idle) {
                transitionAnimation(to: .turn)
                turnCooldown = 1.0
            }
        }
        
        // 9. Cyclic Animation State Determination
        if currentAnimationState != .turn && currentAnimationState != .feed && currentAnimationState != .dart {
            if state.isResting {
                transitionAnimation(to: .rest)
            } else if state.velocity.length2D > profile.cruiseSpeed * 0.75 {
                transitionAnimation(to: .swim_active)
            } else {
                transitionAnimation(to: .swim_idle)
            }
        }
        
        // 10. Thrust force & simulator step
        let baseThrust: Double
        if state.isResting {
            baseThrust = 0.0
        } else if currentAnimationState == .dart {
            baseThrust = profile.maxSpeed * 1.5
        } else if currentAnimationState == .swim_active || isHuntingFood {
            baseThrust = profile.cruiseSpeed * 1.1
        } else {
            baseThrust = profile.cruiseSpeed * 0.65
        }
        
        state.velocity += steeringImpulse * dt
        
        state = AquaticPhysicsSimulator.shared.step(
            state: state,
            bounds: bounds,
            targetWaypoint: targetWaypoint,
            thrustForce: baseThrust,
            config: physicsConfig,
            deltaTime: dt
        )
        
        // Enforce benthic substrate contact
        if niche == .benthic {
            state.position.y = bounds.minY + 6.0
            state.velocity.y = 0.0
        }
    }
    
    // MARK: - Craig Reynolds Flocking
    
    private func calculateFlocking(allCompanions: [AquaticCompanionInstance]) -> (sep: AquaticVector3D, align: AquaticVector3D, coh: AquaticVector3D) {
        var sepForce = AquaticVector3D.zero
        var avgVelocity = AquaticVector3D.zero
        var centerOfMass = AquaticVector3D.zero
        var neighborCount = 0
        let myPos = state.position
        
        let sepDist = 45.0
        let neighborDist = 140.0
        
        for other in allCompanions {
            guard other.id != self.id, other.speciesId == self.speciesId else { continue }
            let diff = other.state.position - myPos
            let d = diff.length2D
            
            if d > 0.01 && d < neighborDist {
                neighborCount += 1
                avgVelocity += other.state.velocity
                centerOfMass += other.state.position
                
                if d < sepDist {
                    let push = (myPos - other.state.position).normalized * ((sepDist - d) / sepDist)
                    sepForce += push * 35.0
                }
            }
        }
        
        var alignForce = AquaticVector3D.zero
        var cohForce = AquaticVector3D.zero
        
        if neighborCount > 0 {
            let invCount = 1.0 / Double(neighborCount)
            avgVelocity = avgVelocity * invCount
            centerOfMass = centerOfMass * invCount
            
            alignForce = (avgVelocity - state.velocity) * 0.5
            cohForce = (centerOfMass - myPos).normalized * 25.0
        }
        
        return (sepForce, alignForce, cohForce)
    }
    
    // MARK: - Compatibility stepPhysics
    
    public func stepPhysics(bounds: AquaticBounds, dt: TimeInterval) {
        var dummyPellets: [AquariumFoodPellet] = []
        stepAI(bounds: bounds, allCompanions: [self], pellets: &dummyPellets, cursorLocation: nil, dt: dt)
    }
    
    public func pickNextWaypoint(bounds: AquaticBounds) -> AquaticVector3D {
        let margin = bounds.margin
        let x = Double.random(in: (bounds.minX + margin)...(bounds.maxX - margin))
        let y: Double
        let z: Double
        
        switch niche {
        case .pelagic:
            let minY = bounds.minY + bounds.height * 0.2
            let maxY = bounds.maxY - bounds.height * 0.2
            y = Double.random(in: minY...max(minY, maxY))
            z = Double.random(in: profile.minZ...profile.maxZ)
        case .surface:
            let minY = bounds.maxY - bounds.height * 0.25
            y = Double.random(in: minY...bounds.maxY)
            z = Double.random(in: profile.minZ...profile.maxZ)
        case .benthic:
            y = bounds.minY + 6.0
            z = Double.random(in: profile.minZ...profile.maxZ)
        case .cryptic:
            let minY = bounds.minY + 16.0
            let maxY = bounds.minY + bounds.height * 0.5
            y = Double.random(in: minY...max(minY, maxY))
            z = Double.random(in: profile.minZ...profile.maxZ)
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
        case .small, .medium, .large, .panoramicWidget, .compact, .standard, .panoramic:
            return tankSizePreset.defaultDimensions
        case .custom:
            return CGSize(width: max(320, customWidth), height: max(240, customHeight))
        }
    }
}
