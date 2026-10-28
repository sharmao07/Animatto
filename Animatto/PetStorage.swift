import Foundation
import SwiftUI
import AppKit
import AVFoundation
import Combine

class PetStorage: ObservableObject {
    @Published var savedPets: [URL] = []
    
    init() {
        Self.migrateUserDefaultsIfNeeded()
        let dest = Self.getStorageDirectory()
        Self.performMigrationIfNeeded(to: dest)
        loadDefaultCharacters() // Checks for inbuilt characters on launch!
        loadPets()
    }
    
    static func getStorageDirectory() -> URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appFolder = paths[0].appendingPathComponent("AnimattoPets")
        
        if !FileManager.default.fileExists(atPath: appFolder.path) {
            try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }
        return appFolder
    }
    
    // MARK: - Safe Idempotent Migrations
    
    /// Migrates user preferences from legacy bundle domains (e.g. com.dev.KinetiPet)
    static func migrateUserDefaultsIfNeeded() {
        let migrationKey = "hasMigratedFromKinetiPet"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        
        if let legacyDomain = UserDefaults.standard.persistentDomain(forName: "com.dev.KinetiPet") {
            for (key, value) in legacyDomain {
                if UserDefaults.standard.object(forKey: key) == nil {
                    UserDefaults.standard.set(value, forKey: key)
                }
            }
        }
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
    
    /// Safely copies user character files from legacy storage folders (AnimotionPets, KinetiPet)
    /// without overwriting newer files.
    static func performMigrationIfNeeded(to destDir: URL) {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupport = paths.first else { return }
        
        let legacyFolders = [
            appSupport.appendingPathComponent("AnimotionPets"),
            appSupport.appendingPathComponent("KinetiPet"),
            appSupport.appendingPathComponent("KinetiPetPets")
        ]
        
        for legacyFolder in legacyFolders {
            guard FileManager.default.fileExists(atPath: legacyFolder.path) else { continue }
            guard let items = try? FileManager.default.contentsOfDirectory(at: legacyFolder, includingPropertiesForKeys: nil) else { continue }
            
            for item in items {
                let targetURL = destDir.appendingPathComponent(item.lastPathComponent)
                if !FileManager.default.fileExists(atPath: targetURL.path) {
                    do {
                        try FileManager.default.copyItem(at: item, to: targetURL)
                    } catch {
                        print("Failed to migrate companion asset \(item.lastPathComponent): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // --- THE GITHUB BUNDLE EXTRACTOR ---
    func loadDefaultCharacters() {
        let dest = Self.getStorageDirectory()
        
        // Scan the Xcode bundle for default GIFs and PNGs
        let bundleGIFs = Bundle.main.urls(forResourcesWithExtension: "gif", subdirectory: nil) ?? []
        let bundlePNGs = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: nil) ?? []
        let allDefaults = bundleGIFs + bundlePNGs
        
        for url in allDefaults {
            // Skips random internal Xcode UI assets
            if url.lastPathComponent.contains("AppIcon") || url.lastPathComponent.contains("AccentColor") { continue }
            
            let destURL = dest.appendingPathComponent(url.lastPathComponent)
            
            // If the user doesn't already have this default character, copy it to their library
            if !FileManager.default.fileExists(atPath: destURL.path) {
                try? FileManager.default.copyItem(at: url, to: destURL)
            }
        }
    }
    
    func importPet(from sourceURL: URL) {
        guard sourceURL.startAccessingSecurityScopedResource() else { return }
        defer { sourceURL.stopAccessingSecurityScopedResource() }
        
        let destinationURL = Self.getStorageDirectory().appendingPathComponent(sourceURL.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            loadPets()
        } catch {
            print("Failed to save pet: \(error.localizedDescription)")
        }
    }
    
    func deletePet(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            loadPets()
        } catch {
            print("Failed to delete pet: \(error.localizedDescription)")
        }
    }
    
    func loadPets() {
        let directory = Self.getStorageDirectory()
        if let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            DispatchQueue.main.async {
                self.savedPets = files.filter { url in
                    let ext = url.pathExtension.lowercased()
                    return ["gif", "mp4", "mov", "webp", "png", "apng"].contains(ext)
                }
            }
        }
    }
}

// MARK: - Universal Thumbnail Generator
struct ThumbnailView: View {
    var url: URL
    @State private var thumbnail: NSImage?
    
    var body: some View {
        Group {
            if let img = thumbnail {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .onAppear { generateThumbnail() }
    }
    
    func generateThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            if ["mp4", "mov"].contains(url.pathExtension.lowercased()) {
                let asset = AVURLAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                
                Task {
                    do {
                        let (cgImage, _) = try await generator.image(at: .zero)
                        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                        await MainActor.run {
                            self.thumbnail = image
                        }
                    } catch {
                        print("Thumbnail generation error: \(error.localizedDescription)")
                    }
                }
            } else {
                if let image = NSImage(contentsOf: url) {
                    DispatchQueue.main.async { self.thumbnail = image }
                }
            }
        }
    }
}
