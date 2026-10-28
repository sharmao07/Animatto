import Foundation
import CoreGraphics
import Combine

// MARK: - Collectible Minigame Manager
public class AmbientMinigameManager: ObservableObject {
    public static let shared = AmbientMinigameManager()
    
    @Published public var isGameEnabled: Bool = false {
        didSet {
            if isGameEnabled {
                startSession()
            } else {
                stopSession()
            }
        }
    }
    
    @Published public private(set) var isSessionActive: Bool = false
    @Published public private(set) var currentScore: Int = 0
    @Published public private(set) var sessionCollectiblesCount: Int = 0
    @Published public private(set) var highScore: Int = 0
    @Published public private(set) var totalCollectedEver: Int = 0
    @Published public private(set) var activeItems: [CollectibleItem] = []
    
    public var maxActiveCollectibles: Int = 6
    public var spawnIntervalSeconds: TimeInterval = 8.0
    
    // Injectable bounds for testing
    public var spawnBoundsProvider: () -> CGRect = {
        CGRect(x: 50, y: 100, width: 1300, height: 700)
    }
    
    private var spawnTimer: Timer?
    private var simulationTimer: Timer?
    private let lock = NSLock()
    
    private let highScoreKey = "com.dev.Animatto.minigame_highscore"
    private let totalCountKey = "com.dev.Animatto.minigame_total_collected"
    
    public init() {
        self.highScore = UserDefaults.standard.integer(forKey: highScoreKey)
        self.totalCollectedEver = UserDefaults.standard.integer(forKey: totalCountKey)
    }
    
    deinit {
        stopSession()
    }
    
    // MARK: - Session Lifecycle
    
    public func startSession() {
        lock.lock()
        isSessionActive = true
        currentScore = 0
        sessionCollectiblesCount = 0
        activeItems.removeAll()
        lock.unlock()
        
        spawnTimer?.invalidate()
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnIntervalSeconds, repeats: true) { [weak self] _ in
            self?.spawnCollectible()
        }
        
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tickItems()
        }
    }
    
    public func stopSession() {
        spawnTimer?.invalidate()
        spawnTimer = nil
        simulationTimer?.invalidate()
        simulationTimer = nil
        
        lock.lock()
        isSessionActive = false
        activeItems.removeAll()
        lock.unlock()
    }
    
    public func resetSessionScore() {
        lock.lock()
        currentScore = 0
        sessionCollectiblesCount = 0
        lock.unlock()
    }
    
    // MARK: - Item Spawning & Physics
    
    public func spawnCollectible() {
        lock.lock()
        defer { lock.unlock() }
        
        guard isSessionActive && activeItems.count < maxActiveCollectibles else { return }
        
        let bounds = spawnBoundsProvider()
        let x = CGFloat.random(in: bounds.minX...bounds.maxX)
        let y = bounds.maxY + 15 // Start just above visible screen
        
        // Determine rarity via weighted roll
        let roll = Double.random(in: 0.0...1.0)
        let rarity: CollectibleRarity
        let name: String
        let symbol: String
        
        if roll < CollectibleRarity.epic.weight {
            rarity = .epic
            name = "Starlight Crystal"
            symbol = "sparkles"
        } else if roll < (CollectibleRarity.epic.weight + CollectibleRarity.rare.weight) {
            rarity = .rare
            name = "Prismatic Shard"
            symbol = "diamond.fill"
        } else if roll < (CollectibleRarity.epic.weight + CollectibleRarity.rare.weight + CollectibleRarity.uncommon.weight) {
            rarity = .uncommon
            name = "Frost Blossom"
            symbol = "snowflake"
        } else {
            rarity = .common
            name = "Golden Leaf"
            symbol = "leaf.fill"
        }
        
        let item = CollectibleItem(
            name: name,
            rarity: rarity,
            x: x,
            y: y,
            vx: CGFloat.random(in: -0.6...0.6),
            vy: -CGFloat.random(in: 0.8...1.8),
            size: 28.0,
            symbolName: symbol
        )
        
        activeItems.append(item)
    }
    
    public func tickItems() {
        lock.lock()
        defer { lock.unlock() }
        
        guard isSessionActive else { return }
        let bounds = spawnBoundsProvider()
        
        for i in (0..<activeItems.count).reversed() {
            activeItems[i].x += activeItems[i].vx
            activeItems[i].y += activeItems[i].vy
            
            // Remove items that have fallen below the floor without being collected
            if activeItems[i].y < bounds.minY - 40 {
                activeItems.remove(at: i)
            }
        }
    }
    
    // MARK: - Interactive Collection
    
    @discardableResult
    public func collect(itemWithId id: UUID) -> CollectibleItem? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let index = activeItems.firstIndex(where: { $0.id == id && !$0.isCollected }) else {
            return nil
        }
        
        var collectedItem = activeItems[index]
        collectedItem.isCollected = true
        activeItems.remove(at: index)
        
        let points = collectedItem.rarity.pointValue
        currentScore += points
        sessionCollectiblesCount += 1
        totalCollectedEver += 1
        
        if currentScore > highScore {
            highScore = currentScore
            UserDefaults.standard.set(highScore, forKey: highScoreKey)
        }
        UserDefaults.standard.set(totalCollectedEver, forKey: totalCountKey)
        
        // Post notification for companion reactions
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("com.dev.Animatto.collectibleCaptured"),
                object: nil,
                userInfo: ["name": collectedItem.name, "points": points]
            )
        }
        
        return collectedItem
    }
}
