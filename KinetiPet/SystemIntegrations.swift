import Foundation
import Combine
import AppKit
import Network

// MARK: - Discord RPC IPC Client
class DiscordRPC {
    static let shared = DiscordRPC()
    
    private var connection: NWConnection?
    private let clientID = "1534653992469008464"
    private var isConnected = false
    
    init() {
        connect()
    }
    
    private func getSocketPath() -> String {
        // macOS reliably stores the Discord socket in the TMPDIR environment variable
        let env = ProcessInfo.processInfo.environment
        if let tmpDir = env["TMPDIR"] {
            return (tmpDir as NSString).appendingPathComponent("discord-ipc-0")
        }
        return (NSTemporaryDirectory() as NSString).appendingPathComponent("discord-ipc-0")
    }
    
    private func connect() {
        let socketPath = getSocketPath()
        
        let endpoint = NWEndpoint.unix(path: socketPath)
        let parameters = NWParameters.tcp
        
        connection = NWConnection(to: endpoint, using: parameters)
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Discord RPC Socket Connected!")
                self?.sendHandshake()
                self?.startReading() // CRITICAL: Keeps the socket alive
            case .failed(let error):
                print("Discord RPC Failed: \(error)")
                self?.isConnected = false
            default:
                break
            }
        }
        connection?.start(queue: .global(qos: .background))
    }
    
    private func startReading() {
        // We must actively listen to Discord's stream so it doesn't close the connection
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, context, isComplete, error in
            if data != nil {
                // Discord sent the READY response. We are officially connected.
                self?.isConnected = true
            }
            
            if isComplete || error != nil {
                self?.isConnected = false
                return
            }
            
            // Loop recursively to keep listening
            self?.startReading()
        }
    }
    
    private func sendHandshake() {
        let payload = """
        {"v": 1, "client_id": "\(clientID)"}
        """
        send(opcode: 0, payload: payload)
    }
    
    func updateActivity(petName: String, state: String = "Chilling on Desktop") {
        let payload = """
        {
            "cmd": "SET_ACTIVITY",
            "args": {
                "pid": \(ProcessInfo.processInfo.processIdentifier),
                "activity": {
                    "details": "Hanging out with \(petName)",
                    "state": "\(state)"
                }
            },
            "nonce": "\(UUID().uuidString)"
        }
        """
        
        // Wait to send the status until the handshake officially completes
        if !isConnected {
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                self.send(opcode: 1, payload: payload)
            }
        } else {
            send(opcode: 1, payload: payload)
        }
    }
    
    private func send(opcode: Int, payload: String) {
        guard let payloadData = payload.data(using: .utf8) else { return }
        
        var op = UInt32(opcode).littleEndian
        var length = UInt32(payloadData.count).littleEndian
        
        var packet = Data()
        packet.append(Data(bytes: &op, count: 4))
        packet.append(Data(bytes: &length, count: 4))
        packet.append(payloadData)
        
        connection?.send(content: packet, completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send RPC data: \(error)")
            }
        }))
    }
}
// MARK: - System Music Monitor
class MusicMonitor: ObservableObject {
    @Published var currentTrack: String? = nil
    private var timer: AnyCancellable?
    
    init() {
        // Fix 1: Use .main for the RunLoop
        timer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkMusic()
            }
    }
    
    private func checkMusic() {
        DispatchQueue.global(qos: .background).async {
            
            // 1. Silently check active Mac memory using Swift, NOT AppleScript
            let runningApps = NSWorkspace.shared.runningApplications
            let isSpotifyRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
            let isMusicRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
            
            var script = ""
            
            // 2. Only build the AppleScript string IF the app is actively running
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
                // Neither app is running, clear track and abort safely.
                DispatchQueue.main.async {
                    if self.currentTrack != nil {
                        self.currentTrack = nil
                    }
                }
                return
            }
            
            // 3. Execute the script safely now that we know the app exists
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                let result = appleScript.executeAndReturnError(&error)
                let trackString = result.stringValue ?? ""
                
                DispatchQueue.main.async {
                    if trackString.isEmpty {
                        self.currentTrack = nil
                    } else if self.currentTrack != trackString {
                        self.currentTrack = trackString
                    }
                }
            }
        }
    }
}
