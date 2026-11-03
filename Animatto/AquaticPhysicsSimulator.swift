import Foundation
import CoreGraphics

// MARK: - Aquatic 3D Vector
public struct AquaticVector3D: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double // 0.0 (front glass) to 1.0 (deep background)
    
    public init(x: Double, y: Double, z: Double = 0.0) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public static let zero = AquaticVector3D(x: 0, y: 0, z: 0)
    
    public var lengthSquared: Double {
        x * x + y * y + z * z
    }
    
    public var length: Double {
        sqrt(lengthSquared)
    }
    
    public var length2D: Double {
        sqrt(x * x + y * y)
    }
    
    public var normalized: AquaticVector3D {
        let len = length
        guard len > 1e-6 else { return .zero }
        return AquaticVector3D(x: x / len, y: y / len, z: z / len)
    }
    
    public static func + (lhs: AquaticVector3D, rhs: AquaticVector3D) -> AquaticVector3D {
        AquaticVector3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    public static func - (lhs: AquaticVector3D, rhs: AquaticVector3D) -> AquaticVector3D {
        AquaticVector3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    public static func * (lhs: AquaticVector3D, scalar: Double) -> AquaticVector3D {
        AquaticVector3D(x: lhs.x * scalar, y: lhs.y * scalar, z: lhs.z * scalar)
    }
    
    public static func / (lhs: AquaticVector3D, scalar: Double) -> AquaticVector3D {
        guard abs(scalar) > 1e-6 else { return .zero }
        return AquaticVector3D(x: lhs.x / scalar, y: lhs.y / scalar, z: lhs.z / scalar)
    }
    
    public static func += (lhs: inout AquaticVector3D, rhs: AquaticVector3D) {
        lhs = lhs + rhs
    }
}

// MARK: - Aquatic Tank Bounds
public struct AquaticBounds: Codable, Equatable, Sendable {
    public var minX: Double
    public var maxX: Double
    public var minY: Double
    public var maxY: Double
    public var minZ: Double
    public var maxZ: Double
    public var margin: Double
    
    public init(
        minX: Double = 0.0,
        maxX: Double = 720.0,
        minY: Double = 0.0,
        maxY: Double = 480.0,
        minZ: Double = 0.0,
        maxZ: Double = 1.0,
        margin: Double = 48.0
    ) {
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
        self.minZ = minZ
        self.maxZ = maxZ
        self.margin = margin
    }
    
    public var width: Double {
        max(1.0, maxX - minX)
    }
    
    public var height: Double {
        max(1.0, maxY - minY)
    }
}

// MARK: - Aquatic Entity State
public struct AquaticEntityState: Codable, Equatable, Sendable {
    public var position: AquaticVector3D
    public var velocity: AquaticVector3D
    public var heading: Double       // radians (-pi to pi), 0 = pointing right
    public var bankAngle: Double     // degrees (-15 to 15)
    public var targetDepth: Double   // z in [0.0, 1.0]
    public var isFacingRight: Bool
    public var isResting: Bool
    public var currentSpeed: Double
    
    public init(
        position: AquaticVector3D = .zero,
        velocity: AquaticVector3D = .zero,
        heading: Double = 0.0,
        bankAngle: Double = 0.0,
        targetDepth: Double = 0.4,
        isFacingRight: Bool = true,
        isResting: Bool = false,
        currentSpeed: Double = 0.0
    ) {
        self.position = position
        self.velocity = velocity
        self.heading = heading
        self.bankAngle = bankAngle
        self.targetDepth = targetDepth
        self.isFacingRight = isFacingRight
        self.isResting = isResting
        self.currentSpeed = currentSpeed
    }
}

// MARK: - Aquatic Physics Configuration
public struct AquaticPhysicsConfig: Codable, Equatable, Sendable {
    public var dragCoefficient: Double        // Fluid resistance coefficient
    public var linearDrag: Double             // Low-speed fluid damping
    public var buoyancyStiffness: Double      // Depth-seeking force constant
    public var depthDamping: Double           // Depth velocity damping
    public var boundaryRepulsionStiffness: Double // Soft wall repulsion force
    public var maxSpeed: Double               // Maximum swimming speed (pt/s)
    public var maxTurnRate: Double            // Maximum angular steering speed (rad/s)
    public var maxBankingAngle: Double        // Maximum roll angle (degrees)
    public var negativeBuoyancyGravity: Double // Substrate pull for benthic species
    
    public init(
        dragCoefficient: Double = 0.045,
        linearDrag: Double = 0.85,
        buoyancyStiffness: Double = 4.5,
        depthDamping: Double = 2.2,
        boundaryRepulsionStiffness: Double = 420.0,
        maxSpeed: Double = 160.0,
        maxTurnRate: Double = .pi,
        maxBankingAngle: Double = 15.0,
        negativeBuoyancyGravity: Double = 0.0
    ) {
        self.dragCoefficient = dragCoefficient
        self.linearDrag = linearDrag
        self.buoyancyStiffness = buoyancyStiffness
        self.depthDamping = depthDamping
        self.boundaryRepulsionStiffness = boundaryRepulsionStiffness
        self.maxSpeed = maxSpeed
        self.maxTurnRate = maxTurnRate
        self.maxBankingAngle = maxBankingAngle
        self.negativeBuoyancyGravity = negativeBuoyancyGravity
    }
    
    public static let pelagicDefault = AquaticPhysicsConfig()
    public static let benthicDefault = AquaticPhysicsConfig(
        dragCoefficient: 0.08,
        linearDrag: 1.2,
        buoyancyStiffness: 2.0,
        depthDamping: 3.0,
        boundaryRepulsionStiffness: 300.0,
        maxSpeed: 80.0,
        maxTurnRate: .pi * 0.8,
        maxBankingAngle: 8.0,
        negativeBuoyancyGravity: 45.0
    )
}

// MARK: - Independent Aquatic Physics Simulator
public final class AquaticPhysicsSimulator: @unchecked Sendable {
    public static let shared = AquaticPhysicsSimulator()
    
    /// Minimum animation/physics delta time (avoids zero/negative or sub-millisecond churn)
    public static let minDeltaTime: TimeInterval = 0.001
    
    /// Maximum catch-up clamp per physics tick (100 ms) preventing explosive leaps after pauses/sleep
    public static let maxDeltaTimeClamp: TimeInterval = 0.10
    
    public init() {}
    
    // MARK: - Pure Simulation Step
    
    /// Advance creature physics deterministically by elapsed time dt.
    public func step(
        state: AquaticEntityState,
        bounds: AquaticBounds,
        targetWaypoint: AquaticVector3D? = nil,
        thrustForce: Double = 0.0,
        config: AquaticPhysicsConfig = .pelagicDefault,
        deltaTime: TimeInterval
    ) -> AquaticEntityState {
        // Enforce safe delta time clamping policy
        guard deltaTime >= Self.minDeltaTime else { return state }
        let dt = min(deltaTime, Self.maxDeltaTimeClamp)
        
        var next = state
        
        // 1. Steering & Thrust Direction
        var desiredDirection: AquaticVector3D = .zero
        if let waypoint = targetWaypoint {
            let toTarget = waypoint - next.position
            desiredDirection = toTarget.normalized
        } else {
            // Default thrust in current heading direction
            desiredDirection = AquaticVector3D(x: cos(next.heading), y: sin(next.heading), z: 0.0)
        }
        
        // Smoothly steer current heading towards desired heading
        let targetAngle = atan2(desiredDirection.y, desiredDirection.x)
        let angleDiff = normalizeAngle(targetAngle - next.heading)
        let maxTurnThisStep = config.maxTurnRate * dt
        let turnStep = clamp(angleDiff, min: -maxTurnThisStep, max: maxTurnThisStep)
        next.heading = normalizeAngle(next.heading + turnStep)
        
        // Update horizontal orientation flag
        if abs(cos(next.heading)) > 0.05 {
            next.isFacingRight = cos(next.heading) >= 0.0
        }
        
        // 2. Net Force Calculation
        var totalForce = AquaticVector3D.zero
        
        // Propulsion thrust aligned with updated heading
        let headingVector = AquaticVector3D(x: cos(next.heading), y: sin(next.heading), z: desiredDirection.z)
        let thrust = headingVector * thrustForce
        totalForce += thrust
        
        // Hydrodynamic Fluid Drag (Quadratic + Linear damping)
        let speed = next.velocity.length
        let dragMagnitude = (0.5 * config.dragCoefficient * speed * speed) + (config.linearDrag * speed)
        let dragForce = next.velocity.normalized * (-dragMagnitude)
        totalForce += dragForce
        
        // Buoyancy / Depth Seeking in Z
        let depthError = next.targetDepth - next.position.z
        let depthBuoyancyForce = (depthError * config.buoyancyStiffness) - (next.velocity.z * config.depthDamping)
        totalForce.z += depthBuoyancyForce
        
        // Substrate gravity for benthic bottom dwellers (opposed by ground normal force when resting)
        if config.negativeBuoyancyGravity > 0.0 && !next.isResting {
            totalForce.y -= config.negativeBuoyancyGravity
        }
        
        // Soft Boundary Repulsion (Floor repulsion only applies to pelagic species; benthic dwellers settle)
        let repulsion = calculateBoundaryRepulsion(
            position: next.position,
            bounds: bounds,
            stiffness: config.boundaryRepulsionStiffness,
            repelFromFloor: config.negativeBuoyancyGravity <= 0.0
        )
        totalForce += repulsion
        
        // 3. Integration (Symplectic Euler)
        let acceleration = totalForce // Assuming unit mass m = 1.0 for companions
        next.velocity += acceleration * dt
        
        // Speed Clamping
        let newSpeed = next.velocity.length
        if newSpeed > config.maxSpeed {
            next.velocity = next.velocity.normalized * config.maxSpeed
        }
        next.currentSpeed = next.velocity.length
        
        // Position Integration
        next.position += next.velocity * dt
        
        // 4. Hard Boundary Clamping & Substrate Normal Force Contact
        next.position.x = clamp(next.position.x, min: bounds.minX, max: bounds.maxX)
        next.position.y = clamp(next.position.y, min: bounds.minY, max: bounds.maxY)
        next.position.z = clamp(next.position.z, min: bounds.minZ, max: bounds.maxZ)
        
        // Substrate rest & ground reaction
        if next.position.y <= bounds.minY + 2.0 && config.negativeBuoyancyGravity > 0.0 {
            if next.velocity.y < 0.0 {
                next.velocity.y = 0.0
            }
            next.isResting = true
        } else {
            next.isResting = false
        }
        
        // 5. Dynamic Banking Calculation
        // Roll into turns proportionally to lateral turn rate
        let turnAngularVelocity = dt > 0 ? (turnStep / dt) : 0.0
        let lateralVelocity = next.velocity.length2D
        let rawBank = -(turnAngularVelocity * lateralVelocity * 0.12)
        next.bankAngle = clamp(rawBank, min: -config.maxBankingAngle, max: config.maxBankingAngle)
        
        return next
    }
    
    // MARK: - Boundary Repulsion Helper
    
    private func calculateBoundaryRepulsion(
        position: AquaticVector3D,
        bounds: AquaticBounds,
        stiffness: Double,
        repelFromFloor: Bool = true
    ) -> AquaticVector3D {
        var force = AquaticVector3D.zero
        let m = bounds.margin
        guard m > 1.0 else { return .zero }
        
        // Left wall (xMin)
        if position.x < bounds.minX + m {
            let dist = max(0.0, position.x - bounds.minX)
            let factor = (m - dist) / m
            force.x += stiffness * factor * factor
        }
        
        // Right wall (xMax)
        if position.x > bounds.maxX - m {
            let dist = max(0.0, bounds.maxX - position.x)
            let factor = (m - dist) / m
            force.x -= stiffness * factor * factor
        }
        
        // Floor / Substrate (yMin) - Pelagic fish turn away, but benthic dwellers settle onto substrate
        if repelFromFloor && position.y < bounds.minY + m {
            let dist = max(0.0, position.y - bounds.minY)
            let factor = (m - dist) / m
            force.y += stiffness * factor * factor
        }
        
        // Water Surface (yMax)
        if position.y > bounds.maxY - m {
            let dist = max(0.0, bounds.maxY - position.y)
            let factor = (m - dist) / m
            force.y -= stiffness * factor * factor
        }
        
        // Front Glass (zMin = 0.0)
        if position.z < bounds.minZ + 0.15 {
            let dist = max(0.0, position.z - bounds.minZ)
            let factor = (0.15 - dist) / 0.15
            force.z += (stiffness * 0.5) * factor * factor
        }
        
        // Back Wall (zMax = 1.0)
        if position.z > bounds.maxZ - 0.15 {
            let dist = max(0.0, bounds.maxZ - position.z)
            let factor = (0.15 - dist) / 0.15
            force.z -= (stiffness * 0.5) * factor * factor
        }
        
        return force
    }
    
    // MARK: - Mathematical Helpers
    
    private func normalizeAngle(_ angle: Double) -> Double {
        var a = angle.truncatingRemainder(dividingBy: 2.0 * .pi)
        if a > .pi { a -= 2.0 * .pi }
        if a < -.pi { a += 2.0 * .pi }
        return a
    }
    
    private func clamp(_ val: Double, min: Double, max: Double) -> Double {
        Swift.min(Swift.max(val, min), max)
    }
}
