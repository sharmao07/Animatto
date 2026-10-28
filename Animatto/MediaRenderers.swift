import SwiftUI
import AppKit
import AVKit

// 1. Native GIF & Image Renderer
struct NativeImageView: NSViewRepresentable {
    var url: URL
    
    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        
        // --- THE GIF SIZE FIX ---
        // This forces the GIF to obey the size slider instead of its original resolution
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        return imageView
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = NSImage(contentsOf: url)
    }
}

// 2. Native Video Loop Renderer
struct NativeVideoView: NSViewRepresentable {
    var url: URL
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.videoGravity = .resizeAspect
        view.layer = playerLayer
        view.wantsLayer = true
        
        player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main) { _ in
                player.seek(to: .zero)
                player.play()
        }
        
        player.isMuted = true
        player.play()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.layer?.frame = nsView.bounds
    }
}
