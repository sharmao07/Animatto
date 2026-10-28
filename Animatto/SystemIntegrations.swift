import Foundation
import Combine
import AppKit
import Network

// MARK: - Discord RPC IPC Client
class DiscordRPC {
    static let shared = DiscordRPC()
    
    private var connection: NWConnection?
    private let clientID = "1534653992469008464"
    private(set) var isConnected = false
    private var isConnecting = false
    
    init() {}
    
    private func findDiscordSocketPath() -> String? {
        let env = ProcessInfo.processInfo.environment
        let tempDirs = [
            env["TMPDIR"],
            NSTemporaryDirectory(),
            "/tmp"
        ].compactMap { $0 }
        
        for dir in tempDirs {
            for i in 0...9 {
                let path = (dir as NSString).appendingPathComponent("discord-ipc-\(i)")
                if FileManager.default.fileExists(atPath: path) {
                    return path
                }
            }
        }
        return nil
    }
    
    func connect() {
        guard !isConnected && !isConnecting else { return }
        guard let socketPath = findDiscordSocketPath() else {
            // Discord is not running or socket is not available
            return
        }
        
        isConnecting = true
        let endpoint = NWEndpoint.unix(path: socketPath)
        let parameters = NWParameters.tcp
        
        let conn = NWConnection(to: endpoint, using: parameters)
        self.connection = conn
        
        conn.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.isConnecting = false
                self.isConnected = true
                self.sendHandshake()
                self.startReading()
            case .failed, .cancelled:
                self.isConnecting = false
                self.isConnected = false
                self.connection = nil
            default:
                break
            }
        }
        conn.start(queue: .global(qos: .background))
    }
    
    func disconnect() {
        isConnecting = false
        isConnected = false
        connection?.cancel()
        connection = nil
    }
    
    private func startReading() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if data != nil {
                self.isConnected = true
            }
            
            if isComplete || error != nil {
                self.isConnected = false
                self.connection = nil
                return
            }
            
            self.startReading()
        }
    }
    
    private func sendHandshake() {
        let payload = """
        {"v": 1, "client_id": "\(clientID)"}
        """
        send(opcode: 0, payload: payload)
    }
    
    func clearActivity() {
        guard isConnected else { return }
        let payload = """
        {
            "cmd": "SET_ACTIVITY",
            "args": {
                "pid": \(ProcessInfo.processInfo.processIdentifier),
                "activity": null
            },
            "nonce": "\(UUID().uuidString)"
        }
        """
        send(opcode: 1, payload: payload)
    }
    
    func updateActivity(petName: String, state: String = "Chilling on Desktop") {
        if !isConnected {
            connect()
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self, self.isConnected else { return }
                self.sendActivityPayload(petName: petName, state: state)
            }
            return
        }
        sendActivityPayload(petName: petName, state: state)
    }
    
    private func sendActivityPayload(petName: String, state: String) {
        let cleanPetName = petName.replacingOccurrences(of: "\"", with: "\\\"")
        let cleanState = state.replacingOccurrences(of: "\"", with: "\\\"")
        let payload = """
        {
            "cmd": "SET_ACTIVITY",
            "args": {
                "pid": \(ProcessInfo.processInfo.processIdentifier),
                "activity": {
                    "details": "Hanging out with \(cleanPetName)",
                    "state": "\(cleanState)"
                }
            },
            "nonce": "\(UUID().uuidString)"
        }
        """
        send(opcode: 1, payload: payload)
    }
    
    private func send(opcode: Int, payload: String) {
        guard let payloadData = payload.data(using: .utf8), let conn = connection else { return }
        
        var op = UInt32(opcode).littleEndian
        var length = UInt32(payloadData.count).littleEndian
        
        var packet = Data()
        packet.append(Data(bytes: &op, count: 4))
        packet.append(Data(bytes: &length, count: 4))
        packet.append(payloadData)
        
        conn.send(content: packet, completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send RPC data: \(error)")
            }
        }))
    }
}

// MARK: - System Music Monitor
class MusicMonitor: ObservableObject {
    static let shared = MusicMonitor()
    
    @Published var currentTrack: String? = nil
    private var timer: AnyCancellable?
    private var isMonitoring = false
    
    init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        checkMusic()
        
        timer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkMusic()
            }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        timer?.cancel()
        timer = nil
        DispatchQueue.main.async { [weak self] in
            self?.currentTrack = nil
        }
    }
    
    private func checkMusic() {
        guard isMonitoring else { return }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self, self.isMonitoring else { return }
            
            // Check running applications first to prevent launching closed apps
            let runningApps = NSWorkspace.shared.runningApplications
            let isSpotifyRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
            let isMusicRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
            
            var script = ""
            
            if isSpotifyRunning {
                script = """
                    try
                        tell application "Spotify"
                            if player state is playing then
                                return name of current track & " by " & artist of current track
                            end if
                        end tell
                    end try
                    return ""
                    """
            } else if isMusicRunning {
                script = """
                    try
                        tell application "Music"
                            if player state is playing then
                                return name of current track & " by " & artist of current track
                            end if
                        end tell
                    end try
                    return ""
                    """
            } else {
                DispatchQueue.main.async { [weak self] in
                    if self?.currentTrack != nil {
                        self?.currentTrack = nil
                    }
                }
                return
            }
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                let result = appleScript.executeAndReturnError(&error)
                let trackString = (result.stringValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.isMonitoring else { return }
                    if trackString.isEmpty {
                        if self.currentTrack != nil {
                            self.currentTrack = nil
                        }
                    } else if self.currentTrack != trackString {
                        self.currentTrack = trackString
                    }
                }
            }
        }
    }
}
