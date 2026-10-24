import Foundation
import SwiftUI
import AppKit
import Combine

// MARK: - 1. The Global Manager (The Factory)
class PetManager: ObservableObject {
    @Published var isPetActive = false
    
    @AppStorage("upsideDownMenuMode") var upsideDownMenuMode = false
    @AppStorage("isPhysicsPaused") var isPhysicsPaused = false
    
    @AppStorage("gravityStrength") var gravityStrength: Double = 1.0
    @AppStorage("walkSpeed") var walkSpeed: Double = 3.0
    @AppStorage("eventFrequency") var eventFrequency: Double = 50.0
    
    @Published var activePets: [UUID: PetInstance] = [:]
    
    func launchPet(url: URL, size: CGFloat) {
        let newPet = PetInstance(url: url, size: size, globalManager: self)
        activePets[newPet.id] = newPet
        isPetActive = true
    }
    
    func removePet(id: UUID) {
        activePets[id]?.closePet()
        activePets.removeValue(forKey: id)
        if activePets.isEmpty {
            isPetActive = false
        }
    }
}

// MARK: - 2. The Individual Pet Controller
class PetInstance: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    var globalManager: PetManager
    private var petWindow: NSWindow?
    
    private var cancellables = Set<AnyCancellable>()
    private var physicsTimer: Timer?
    private var behaviorTimer: Timer?
    
    @Published var petSize: CGFloat
    
    var currentX: CGFloat = CGFloat.random(in: 100...500)
    var currentY: CGFloat = 0
    var isDragging = false
    
    var dragStartMousePos: NSPoint = .zero
    var dragStartWindowPos: NSPoint = .zero
    
    @Published var walkDirectionRight = true
    @Published var isHovering = false
    
    // --- NEW: Walking Animation Variables ---
    @Published var walkBobOffset: CGFloat = 0
    private var walkTime: Double = 0
    
    var isFalling = false
    var yVelocity: CGFloat = 0
    
    enum PetState {
        case walking, idle, sleeping
    }
    @Published var currentState: PetState = .walking
    
    init(url: URL, size: CGFloat, globalManager: PetManager) {
        self.url = url
        self.petSize = size
        self.globalManager = globalManager
        
        createTransparentWindow()
        startPhysicsLoop()
        startBehaviorLoop()
        
        UserDefaults.standard.publisher(for: \.upsideDownMenuMode)
            .sink { [weak self] _ in self?.applyGravity() }
            .store(in: &cancellables)
    }
    
    func closePet() {
        petWindow?.close()
        petWindow = nil
        physicsTimer?.invalidate()
        behaviorTimer?.invalidate()
    }
    
    func triggerAlarm(minutes: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(minutes * 60)) {
            self.currentState = .idle
            self.isHovering = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.isHovering = false
            }
        }
    }
    
    private func createTransparentWindow() {
        let windowSize = petSize + 80
        
        let window = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: windowSize, height: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        
        window.contentView = NSHostingView(rootView: PetSpriteView(pet: self))
        window.makeKeyAndOrderFront(nil)
        self.petWindow = window
        
        applyGravity()
    }
    
    private func applyGravity() {
        guard let screen = NSScreen.main else { return }
        let totalHeight = petSize + 80
        
        if globalManager.upsideDownMenuMode {
            currentY = screen.visibleFrame.maxY - totalHeight + 40
        } else {
            currentY = screen.visibleFrame.maxY - totalHeight
            isFalling = true
            yVelocity = 0
        }
        updatePosition()
    }
    
    private func startBehaviorLoop() {
        behaviorTimer?.invalidate()
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3.5...5.5), repeats: true) { [weak self] _ in
            guard let self = self, !self.globalManager.isPhysicsPaused, !self.isFalling, !self.isHovering, !self.isDragging else { return }
            
            let roll = Double.random(in: 0...100)
            
            if roll < self.globalManager.eventFrequency {
                self.currentState = Bool.random() ? .idle : .sleeping
            } else {
                self.currentState = .walking
                if Bool.random() { self.walkDirectionRight.toggle() }
            }
        }
    }
    
    private func startPhysicsLoop() {
        physicsTimer?.invalidate()
        physicsTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            guard let self = self, !self.globalManager.isPhysicsPaused, !self.isDragging else { return }
            self.physicsTick()
        }
    }
    
    private func physicsTick() {
        guard let screen = NSScreen.main else { return }
        let windowSize = petSize + 80
        
        let currentSpeed = CGFloat(globalManager.walkSpeed)
        
        if globalManager.upsideDownMenuMode {
            currentY = screen.visibleFrame.maxY - windowSize + 40
            if currentState == .walking && !isHovering {
                currentX += walkDirectionRight ? currentSpeed : -currentSpeed
                
                // --- UPSIDE DOWN BOBBING ---
                walkTime += (0.15 * Double(currentSpeed))
                walkBobOffset = CGFloat(sin(walkTime) * 3.0)
            } else {
                walkTime = 0
                walkBobOffset = 0
            }
            bounceOffScreenEdges(screen: screen)
            updatePosition()
            return
        }
        
        let mainWindow = NSApp.windows.first(where: { $0.title == "KinetiPet" || ($0.styleMask.contains(.titled) && $0 != self.petWindow) })
        
        var currentFloor = screen.visibleFrame.minY - 40
        var isWalkingOnWindow = false
        
        if let mw = mainWindow, mw.isVisible {
            let mwFrame = mw.frame
            let petMidX = currentX + (windowSize / 2)
            let visualFeetY = currentY + 40
            
            if petMidX >= mwFrame.minX && petMidX <= mwFrame.maxX {
                if visualFeetY >= mwFrame.maxY - 50 {
                    currentFloor = mwFrame.maxY - 40
                    isWalkingOnWindow = true
                }
                else if visualFeetY >= mwFrame.minY - 50 {
                    currentFloor = mwFrame.minY - 40
                    isWalkingOnWindow = true
                }
            }
        }
        
        if isFalling {
            yVelocity += (1.5 * CGFloat(globalManager.gravityStrength))
            currentY -= yVelocity
            walkBobOffset = 0 // Reset bob while falling
            
            if currentY <= currentFloor {
                currentY = currentFloor
                isFalling = false
                yVelocity = 0
            }
        } else {
            if currentY > currentFloor + 5 {
                isFalling = true
                yVelocity = 0
            } else {
                if currentState == .walking && !isHovering {
                    currentX += walkDirectionRight ? currentSpeed : -currentSpeed
                    
                    // --- NORMAL BOBBING ---
                    // Generates a smooth sine wave that scales up with their movement speed!
                    walkTime += (0.15 * Double(currentSpeed))
                    walkBobOffset = CGFloat(abs(sin(walkTime)) * -4.0) // Tiny 4px bounce upwards
                    
                } else {
                    walkTime = 0
                    walkBobOffset = 0 // Reset when standing still
                }
                
                if isWalkingOnWindow, let mw = mainWindow, currentFloor != screen.visibleFrame.minY - 40 {
                    if currentX + windowSize > mw.frame.maxX {
                        walkDirectionRight = false
                        currentX = mw.frame.maxX - windowSize
                    } else if currentX < mw.frame.minX {
                        walkDirectionRight = true
                        currentX = mw.frame.minX
                    }
                } else {
                    bounceOffScreenEdges(screen: screen)
                }
            }
        }
        updatePosition()
    }
    
    private func bounceOffScreenEdges(screen: NSScreen) {
        let windowSize = petSize + 80
        if currentX + windowSize > screen.visibleFrame.maxX {
            walkDirectionRight = false
            currentX = screen.visibleFrame.maxX - windowSize
        } else if currentX < screen.visibleFrame.minX {
            walkDirectionRight = true
            currentX = screen.visibleFrame.minX
        }
    }
    
    func updatePosition() {
        petWindow?.setFrameOrigin(NSPoint(x: currentX, y: currentY))
    }
}

// MARK: - 3. The Visual Pet
struct PetSpriteView: View {
    @ObservedObject var pet: PetInstance
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            GifView(url: pet.url)
                .frame(width: pet.petSize, height: pet.petSize)
                .scaleEffect(x: pet.walkDirectionRight ? 1 : -1)
                // --- APPLIES THE VISUAL HOP TO THE SPRITE ---
                .offset(y: pet.walkBobOffset)
        }
        .frame(width: pet.petSize + 80, height: pet.petSize + 80)
        .rotationEffect(.degrees(pet.globalManager.upsideDownMenuMode ? 180 : 0))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: pet.globalManager.upsideDownMenuMode)
        .contentShape(Rectangle())
        .onHover { isHovered in
            pet.isHovering = isHovered
            if isHovered && pet.currentState == .sleeping {
                pet.currentState = .idle
            }
        }
        .gesture(
            DragGesture()
                .onChanged { _ in
                    if !pet.isDragging {
                        pet.isDragging = true
                        pet.currentState = .idle
                        pet.dragStartMousePos = NSEvent.mouseLocation
                        pet.dragStartWindowPos = NSPoint(x: pet.currentX, y: pet.currentY)
                    }
                    
                    let currentMouse = NSEvent.mouseLocation
                    let deltaX = currentMouse.x - pet.dragStartMousePos.x
                    let deltaY = currentMouse.y - pet.dragStartMousePos.y
                    
                    pet.currentX = pet.dragStartWindowPos.x + deltaX
                    pet.currentY = pet.dragStartWindowPos.y + deltaY
                    pet.updatePosition()
                }
                .onEnded { _ in
                    pet.isDragging = false
                    pet.isFalling = true
                }
        )
        .contextMenu {
            Button(pet.globalManager.isPhysicsPaused ? "Resume Physics" : "Pause Physics") {
                pet.globalManager.isPhysicsPaused.toggle()
            }
            Button("Dismiss Pet", role: .destructive) {
                pet.globalManager.removePet(id: pet.id)
            }
        }
        .onTapGesture(count: 2) {
            showMenu = true
        }
        .popover(isPresented: $showMenu, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Companion Menu").font(.headline)
                Divider()
                
                Button(action: {
                    showMenu = false
                    if let window = NSApp.windows.first(where: { $0.title == "KinetiPet" }) {
                        window.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }) {
                    Label("Open Settings", systemImage: "gearshape")
                }
                .buttonStyle(.plain)
                
                Menu {
                    Button("5 Minutes") { pet.triggerAlarm(minutes: 5); showMenu = false }
                    Button("15 Minutes") { pet.triggerAlarm(minutes: 15); showMenu = false }
                    Button("30 Minutes") { pet.triggerAlarm(minutes: 30); showMenu = false }
                    Button("1 Hour") { pet.triggerAlarm(minutes: 60); showMenu = false }
                } label: {
                    Label("Set Alarm / Timer", systemImage: "alarm")
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    pet.currentState = .sleeping
                    showMenu = false
                }) {
                    Label("Force Sleep", systemImage: "moon.zzz")
                }
                .buttonStyle(.plain)
                
                Divider()
                
                Button(action: {
                    showMenu = false
                    pet.globalManager.removePet(id: pet.id)
                }) {
                    Label("Dismiss Pet", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .frame(width: 200)
        }
    }
}

// MARK: - 4. GIF/Animation Wrapper
struct GifView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.imageAlignment = .alignCenter
        
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        if let img = NSImage(contentsOf: url) {
            view.image = img
        }
        
        view.animates = true
        return view
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {}
}

// MARK: - UserDefaults Extension for Combine
extension UserDefaults {
    @objc dynamic var upsideDownMenuMode: Bool {
        return bool(forKey: "upsideDownMenuMode")
    }
}
