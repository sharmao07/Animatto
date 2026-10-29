import SwiftUI
import AppKit
import AVFoundation
import AVKit
import UniformTypeIdentifiers

// MARK: - Centralized Supported Media Formats
public enum SupportedMediaFormat: String, CaseIterable {
    case png
    case gif
    case jpg
    case jpeg
    case webp
    case apng
    case mp4
    case mov
    
    public static var supportedExtensions: [String] {
        allCases.map { $0.rawValue }
    }
    
    public static var supportedUTTypes: [UTType] {
        var types: [UTType] = [.png, .gif, .jpeg, .movie, .mpeg4Movie, .quickTimeMovie]
        if let webp = UTType("org.webmproject.webp") {
            types.append(webp)
        }
        return types
    }
    
    public static func isSupported(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return SupportedMediaFormat(rawValue: ext) != nil
    }
    
    public static func isVideo(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "mp4" || ext == "mov"
    }
    
    public static func isAnimated(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "gif" || ext == "apng" || ext == "webp" || isVideo(url: url)
    }
}

// MARK: - 1. Native GIF & Static Image Renderer
struct NativeImageView: NSViewRepresentable {
    var url: URL
    
    class Coordinator {
        var currentURL: URL?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.animates = true
        
        // Allows the image to obey parent frame rather than forcing intrinsic size
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        if let image = NSImage(contentsOf: url) {
            imageView.image = image
            context.coordinator.currentURL = url
        }
        
        return imageView
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        // Only reload the image if the URL changed to prevent resetting GIF animation frames on SwiftUI re-renders
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            if let newImage = NSImage(contentsOf: url) {
                nsView.image = newImage
            }
        }
    }
}

// MARK: - 2. Native Looping Video Renderer
struct NativeVideoView: NSViewRepresentable {
    var url: URL
    
    class Coordinator {
        var currentURL: URL?
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
        var loopObserver: NSObjectProtocol?
        
        deinit {
            cleanup()
        }
        
        func cleanup() {
            if let obs = loopObserver {
                NotificationCenter.default.removeObserver(obs)
                loopObserver = nil
            }
            player?.pause()
            player = nil
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
            currentURL = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        
        let player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        containerView.layer?.addSublayer(playerLayer)
        
        player.actionAtItemEnd = .none
        player.isMuted = true
        
        // Loop continuously without memory leaks
        let observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
        
        context.coordinator.currentURL = url
        context.coordinator.player = player
        context.coordinator.playerLayer = playerLayer
        context.coordinator.loopObserver = observer
        
        player.play()
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            if let obs = context.coordinator.loopObserver {
                NotificationCenter.default.removeObserver(obs)
                context.coordinator.loopObserver = nil
            }
            let newItem = AVPlayerItem(url: url)
            context.coordinator.player?.replaceCurrentItem(with: newItem)
            context.coordinator.loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: newItem,
                queue: .main
            ) { [weak player = context.coordinator.player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
            context.coordinator.player?.play()
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        context.coordinator.playerLayer?.frame = nsView.bounds
        CATransaction.commit()
    }
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.cleanup()
    }
}

// MARK: - 3. Unified Companion Media View
struct CompanionMediaView: View {
    let url: URL
    
    var body: some View {
        if SupportedMediaFormat.isVideo(url: url) {
            NativeVideoView(url: url)
        } else {
            NativeImageView(url: url)
        }
    }
}
