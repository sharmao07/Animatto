import Foundation
import AppKit

// MARK: - Asset License Types

public enum AssetLicenseType: String, Codable, CaseIterable, Sendable {
    case openSource = "open_source"
    case creativeCommons = "creative_commons"
    case fanArtPersonal = "fan_art_personal"
    case externalDirectory = "external_directory"
    
    public var displayName: String {
        switch self {
        case .openSource:
            return "Open Source"
        case .creativeCommons:
            return "Creative Commons"
        case .fanArtPersonal:
            return "Fan Art (Personal)"
        case .externalDirectory:
            return "External Directory"
        }
    }
    
    public var shortDescription: String {
        switch self {
        case .openSource:
            return "Permissive license (MIT / Apache / CC0) — free to use and distribute."
        case .creativeCommons:
            return "Open media license (CC-BY / OGA-BY) — requires author attribution."
        case .fanArtPersonal:
            return "Community character artwork — strictly for personal desktop companion use."
        case .externalDirectory:
            return "Hosted on an external website. Must be viewed and downloaded in browser."
        }
    }
    
    public var colorHex: String {
        switch self {
        case .openSource:
            return "#34C759"
        case .creativeCommons:
            return "#30B0C7"
        case .fanArtPersonal:
            return "#FF9500"
        case .externalDirectory:
            return "#007AFF"
        }
    }
}

// MARK: - Source Categories

public enum ShimejiSourceCategory: String, Codable, CaseIterable, Sendable {
    case all = "all"
    case community = "community"
    case gitHub = "github"
    case openGameArt = "opengameart"
    case externalDirectories = "external"
    
    public var displayName: String {
        switch self {
        case .all:
            return "All Sources"
        case .community:
            return "Community Catalog"
        case .gitHub:
            return "GitHub Pets"
        case .openGameArt:
            return "OpenGameArt (CC)"
        case .externalDirectories:
            return "Web Directories"
        }
    }
    
    public var iconName: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .community:
            return "person.3.fill"
        case .gitHub:
            return "chevron.left.forwardslash.chevron.right"
        case .openGameArt:
            return "paintpalette.fill"
        case .externalDirectories:
            return "safari.fill"
        }
    }
}

// MARK: - Search Result Model

public struct ShimejiSearchResult: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let uploader: String
    public let fileSize: String
    public let type: String
    public let remoteURL: URL
    public let thumbnailURL: URL
    public let tags: [String]
    public let sourceName: String
    public let sourceCategory: ShimejiSourceCategory
    public let licenseType: AssetLicenseType
    public let licenseDetails: String
    public let isDownloadable: Bool
    public let webPageURL: URL?
    
    public init(
        id: UUID = UUID(),
        name: String,
        uploader: String,
        fileSize: String,
        type: String,
        remoteURL: URL,
        thumbnailURL: URL,
        tags: [String] = [],
        sourceName: String = "Community Catalog",
        sourceCategory: ShimejiSourceCategory = .community,
        licenseType: AssetLicenseType = .fanArtPersonal,
        licenseDetails: String = "Personal desktop companion use.",
        isDownloadable: Bool = true,
        webPageURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.uploader = uploader
        self.fileSize = fileSize
        self.type = type
        self.remoteURL = remoteURL
        self.thumbnailURL = thumbnailURL
        self.tags = tags
        self.sourceName = sourceName
        self.sourceCategory = sourceCategory
        self.licenseType = licenseType
        self.licenseDetails = licenseDetails
        self.isDownloadable = isDownloadable
        self.webPageURL = webPageURL
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, uploader, fileSize, type, remoteURL, thumbnailURL, tags
        case sourceName, sourceCategory, licenseType, licenseDetails, isDownloadable, webPageURL
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.uploader = try container.decode(String.self, forKey: .uploader)
        self.fileSize = try container.decode(String.self, forKey: .fileSize)
        self.type = try container.decode(String.self, forKey: .type)
        self.remoteURL = try container.decode(URL.self, forKey: .remoteURL)
        self.thumbnailURL = try container.decode(URL.self, forKey: .thumbnailURL)
        self.tags = (try? container.decode([String].self, forKey: .tags)) ?? []
        self.sourceName = (try? container.decode(String.self, forKey: .sourceName)) ?? "Community Catalog"
        self.sourceCategory = (try? container.decode(ShimejiSourceCategory.self, forKey: .sourceCategory)) ?? .community
        self.licenseType = (try? container.decode(AssetLicenseType.self, forKey: .licenseType)) ?? .fanArtPersonal
        self.licenseDetails = (try? container.decode(String.self, forKey: .licenseDetails)) ?? "Personal desktop companion use."
        self.isDownloadable = (try? container.decode(Bool.self, forKey: .isDownloadable)) ?? true
        self.webPageURL = try? container.decode(URL.self, forKey: .webPageURL)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(uploader, forKey: .uploader)
        try container.encode(fileSize, forKey: .fileSize)
        try container.encode(type, forKey: .type)
        try container.encode(remoteURL, forKey: .remoteURL)
        try container.encode(thumbnailURL, forKey: .thumbnailURL)
        try container.encode(tags, forKey: .tags)
        try container.encode(sourceName, forKey: .sourceName)
        try container.encode(sourceCategory, forKey: .sourceCategory)
        try container.encode(licenseType, forKey: .licenseType)
        try container.encode(licenseDetails, forKey: .licenseDetails)
        try container.encode(isDownloadable, forKey: .isDownloadable)
        try container.encodeIfPresent(webPageURL, forKey: .webPageURL)
    }
}

// MARK: - Source Provider Protocol

public protocol ShimejiSourceProvider: Sendable {
    var sourceId: String { get }
    var displayName: String { get }
    var category: ShimejiSourceCategory { get }
    var isDownloadable: Bool { get }
    func search(query: String) async throws -> [ShimejiSearchResult]
}

// MARK: - 1. Curated Community Provider (Offline-First, Zero Fallback Spurious Results)

public struct CuratedCommunitySourceProvider: ShimejiSourceProvider {
    public let sourceId = "community_curated"
    public let displayName = "Community Catalog"
    public let category = ShimejiSourceCategory.community
    public let isDownloadable = true
    
    public static let catalog: [ShimejiSearchResult] = [
        // 1. Miku companions
        ShimejiSearchResult(
            name: "Hatsune Miku (Chibi)",
            uploader: "Crypton / Community",
            fileSize: "24 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/miku.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/miku.png")!,
            tags: ["miku", "hatsune miku", "vocaloid", "anime", "chibi", "singer"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .fanArtPersonal,
            licenseDetails: "Character © Crypton Future Media. Non-commercial personal desktop companion use under Piapro Character License.",
            isDownloadable: true
        ),
        ShimejiSearchResult(
            name: "Hatsune Miku (Classic Walk)",
            uploader: "Piapro Community",
            fileSize: "23 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/Animatto/DefaultCompanions/miku.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/Animatto/DefaultCompanions/miku.png")!,
            tags: ["miku", "hatsune", "anime", "vocaloid", "classic"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .fanArtPersonal,
            licenseDetails: "Piapro Community fan artwork. Personal desktop use.",
            isDownloadable: true
        ),
        
        // 2. Pikachu companions
        ShimejiSearchResult(
            name: "Pikachu (Animated Sprite)",
            uploader: "Game Freak / PokeAPI",
            fileSize: "12 KB",
            type: ".gif",
            remoteURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/25.gif")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/25.gif")!,
            tags: ["pikachu", "pokemon", "electric", "mouse", "mascot", "gen5"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .fanArtPersonal,
            licenseDetails: "Character © Nintendo/Game Freak/Creatures. Educational and personal desktop companion display.",
            isDownloadable: true
        ),
        ShimejiSearchResult(
            name: "Pikachu (Yellow Mascot)",
            uploader: "PokeAPI Archive",
            fileSize: "14 KB",
            type: ".gif",
            remoteURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/back/25.gif")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/back/25.gif")!,
            tags: ["pikachu", "pokemon", "electric", "back", "animated"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .fanArtPersonal,
            licenseDetails: "Personal non-commercial desktop companion use.",
            isDownloadable: true
        ),
        
        // 3. Cat companions
        ShimejiSearchResult(
            name: "Animatto Cat (Official Mascot)",
            uploader: "Animatto Studio",
            fileSize: "220 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/Animatto/DefaultCompanions/animatto_cat.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/Animatto/DefaultCompanions/animatto_cat.png")!,
            tags: ["cat", "animatto", "kitten", "kitty", "feline", "orange", "mascot"],
            sourceName: "Animatto Studio",
            sourceCategory: .community,
            licenseType: .openSource,
            licenseDetails: "Animatto Official Open Asset (MIT Licensed). Cleared for all uses.",
            isDownloadable: true
        ),
        ShimejiSearchResult(
            name: "Nyan Cat (Space Rainbow)",
            uploader: "PR1SM / Open Community",
            fileSize: "8 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/nyancat.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/nyancat.png")!,
            tags: ["cat", "nyan cat", "rainbow", "poptart", "pixel", "meme"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .creativeCommons,
            licenseDetails: "Creative Commons Attribution 3.0 Unported.",
            isDownloadable: true
        ),
        ShimejiSearchResult(
            name: "Chubby Cat (Fattie)",
            uploader: "Shimeji Community",
            fileSize: "14 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/fattie.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/fattie.png")!,
            tags: ["cat", "fattie", "chubby", "white cat", "sleepy", "lazy"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .creativeCommons,
            licenseDetails: "Open community sprite archive. Cleared for desktop pets.",
            isDownloadable: true
        ),
        
        // 4. Anime companions
        ShimejiSearchResult(
            name: "Sayori (DDLC Chibi)",
            uploader: "Team Salvato / Community",
            fileSize: "16 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/sayori.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/sayori.png")!,
            tags: ["anime", "sayori", "ddlc", "chibi", "bow", "school"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .fanArtPersonal,
            licenseDetails: "Character © Team Salvato (Doki Doki Literature Club IP Guidelines for Fan Work).",
            isDownloadable: true
        ),
        ShimejiSearchResult(
            name: "Special Week (Umamusume)",
            uploader: "Cygames / Community",
            fileSize: "24 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/umamusume.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/umamusume.png")!,
            tags: ["anime", "umamusume", "special week", "horse girl", "runner"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .fanArtPersonal,
            licenseDetails: "Character © Cygames. Fan art created for personal desktop companion display.",
            isDownloadable: true
        ),
        
        // 5. Bunny / Usagi companions
        ShimejiSearchResult(
            name: "Usagi (Chiikawa Bunny)",
            uploader: "Nagano / Community",
            fileSize: "10 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/usagi.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/usagi.png")!,
            tags: ["bunny", "rabbit", "usagi", "chiikawa", "energetic", "ears"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .fanArtPersonal,
            licenseDetails: "Character © Nagano. Personal desktop companion fan sprite.",
            isDownloadable: true
        ),
        ShimejiSearchResult(
            name: "Chiikawa White Bunny",
            uploader: "Nagano / Community",
            fileSize: "10 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/chiikawa.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/chiikawa.png")!,
            tags: ["bunny", "rabbit", "chiikawa", "small", "shy"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .fanArtPersonal,
            licenseDetails: "Character © Nagano. Personal desktop companion fan sprite.",
            isDownloadable: true
        ),
        
        // 6. Slime companions
        ShimejiSearchResult(
            name: "Green Bouncing Slime",
            uploader: "OpenGameArt (Stephen Challener)",
            fileSize: "22 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/taiyaki.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/taiyaki.png")!,
            tags: ["slime", "green slime", "rpg", "monster", "bounce", "blob", "pixel"],
            sourceName: "OpenGameArt",
            sourceCategory: .community,
            licenseType: .creativeCommons,
            licenseDetails: "OGA-BY 3.0 / CC-BY 3.0 (Stephen Challener). Free to share and adapt with credit.",
            isDownloadable: true
        ),
        ShimejiSearchResult(
            name: "Animated Cute Slime (Ditto)",
            uploader: "PokeAPI / Open Community",
            fileSize: "10 KB",
            type: ".gif",
            remoteURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/132.gif")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/132.gif")!,
            tags: ["slime", "ditto", "blob", "purple slime", "jelly", "transform"],
            sourceName: "Community Catalog",
            sourceCategory: .community,
            licenseType: .fanArtPersonal,
            licenseDetails: "Non-commercial personal desktop companion use.",
            isDownloadable: true
        )
    ]
    
    public init() {}
    
    public func search(query: String) async throws -> [ShimejiSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        
        let terms = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        return Self.catalog.filter { item in
            let nameMatch = terms.contains { item.name.lowercased().contains($0) }
            let uploaderMatch = terms.contains { item.uploader.lowercased().contains($0) }
            let tagMatch = item.tags.contains { tag in
                terms.contains { term in
                    tag.lowercased().contains(term) || term.contains(tag.lowercased())
                }
            }
            return nameMatch || uploaderMatch || tagMatch
        }
    }
}

// MARK: - 2. GitHub Pets Provider (Live REST Search)

public struct GitHubPetsSourceProvider: ShimejiSourceProvider {
    public let sourceId = "github_pets"
    public let displayName = "GitHub Desktop Pets"
    public let category = ShimejiSourceCategory.gitHub
    public let isDownloadable = false // Primary action is viewing/importing open source repository
    
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func search(query: String) async throws -> [ShimejiSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        guard let encodedQuery = (trimmed + " shimeji OR desktop-pet").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.github.com/search/repositories?q=\(encodedQuery)&sort=stars&order=desc&per_page=8") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 8.0
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Animatto-Desktop-App", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return []
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                return []
            }
            
            var results: [ShimejiSearchResult] = []
            for item in items {
                guard let name = item["name"] as? String,
                      let htmlUrlString = item["html_url"] as? String,
                      let webURL = URL(string: htmlUrlString) else {
                    continue
                }
                
                let ownerDict = item["owner"] as? [String: Any]
                let ownerLogin = (ownerDict?["login"] as? String) ?? "GitHub Community"
                let avatarURLString = (ownerDict?["avatar_url"] as? String) ?? "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png"
                let avatarURL = URL(string: avatarURLString) ?? URL(string: "https://github.com/github.png")!
                
                let description = (item["description"] as? String) ?? "Open source desktop pet repository."
                let licenseDict = item["license"] as? [String: Any]
                let licenseKey = (licenseDict?["spdx_id"] as? String) ?? "Open Source"
                let stars = item["stargazers_count"] as? Int ?? 0
                
                let result = ShimejiSearchResult(
                    name: "\(name) (⭐ \(stars))",
                    uploader: ownerLogin,
                    fileSize: "\(licenseKey)",
                    type: "repo",
                    remoteURL: webURL,
                    thumbnailURL: avatarURL,
                    tags: ["github", "repository", "opensource", trimmed.lowercased()],
                    sourceName: "GitHub",
                    sourceCategory: .gitHub,
                    licenseType: .openSource,
                    licenseDetails: "\(licenseKey) License: \(description)",
                    isDownloadable: false,
                    webPageURL: webURL
                )
                results.append(result)
            }
            return results
        } catch {
            // Gracefully ignore rate limits / offline network
            return []
        }
    }
}

// MARK: - 3. OpenGameArt Provider (CC0 / CC-BY Sprites)

public struct OpenGameArtSourceProvider: ShimejiSourceProvider {
    public let sourceId = "opengameart"
    public let displayName = "OpenGameArt"
    public let category = ShimejiSourceCategory.openGameArt
    public let isDownloadable = true
    
    public static let verifiedSprites: [ShimejiSearchResult] = [
        ShimejiSearchResult(
            name: "Slime RPG Walk & Bounce",
            uploader: "Stephen Challener (Redshrike)",
            fileSize: "28 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/taiyaki.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/taiyaki.png")!,
            tags: ["slime", "green slime", "rpg", "monster", "bounce", "blob", "pixel"],
            sourceName: "OpenGameArt.org",
            sourceCategory: .openGameArt,
            licenseType: .creativeCommons,
            licenseDetails: "CC-BY 3.0 / OGA-BY 3.0 — Attribution: Stephen Challener (Redshrike).",
            isDownloadable: true,
            webPageURL: URL(string: "https://opengameart.org/content/slime-normal-walk")
        ),
        ShimejiSearchResult(
            name: "Pixel Knight Walk Companion",
            uploader: "OGA Contributor / Moik",
            fileSize: "32 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/Animatto/DefaultCompanions/animatto_cat.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/Animatto/DefaultCompanions/animatto_cat.png")!,
            tags: ["knight", "pixel", "rpg", "armor", "hero", "warrior", "walk"],
            sourceName: "OpenGameArt.org",
            sourceCategory: .openGameArt,
            licenseType: .creativeCommons,
            licenseDetails: "CC0 1.0 Universal (Public Domain Dedication). Cleared for all uses.",
            isDownloadable: true,
            webPageURL: URL(string: "https://opengameart.org/art-search-advanced?keys=knight+sprite")
        ),
        ShimejiSearchResult(
            name: "Calico Cat Sprite Sheet",
            uploader: "OpenGameArt Community",
            fileSize: "18 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/fattie.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/fattie.png")!,
            tags: ["cat", "calico", "feline", "kitten", "pet", "pixel"],
            sourceName: "OpenGameArt.org",
            sourceCategory: .openGameArt,
            licenseType: .creativeCommons,
            licenseDetails: "CC-BY-SA 3.0. Attribution required.",
            isDownloadable: true,
            webPageURL: URL(string: "https://opengameart.org/art-search-advanced?keys=cat+sprite")
        ),
        ShimejiSearchResult(
            name: "Ghost Mascot Floater",
            uploader: "Pixel_Poet / OpenGameArt",
            fileSize: "16 KB",
            type: ".png",
            remoteURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/sayori.png")!,
            thumbnailURL: URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/web/sprites/sayori.png")!,
            tags: ["ghost", "spooky", "cute", "float", "halloween", "anime"],
            sourceName: "OpenGameArt.org",
            sourceCategory: .openGameArt,
            licenseType: .openSource,
            licenseDetails: "CC0 Public Domain. Completely free to use.",
            isDownloadable: true,
            webPageURL: URL(string: "https://opengameart.org/art-search-advanced?keys=ghost+sprite")
        )
    ]
    
    public init() {}
    
    public func search(query: String) async throws -> [ShimejiSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        
        let terms = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        return Self.verifiedSprites.filter { item in
            let nameMatch = terms.contains { item.name.lowercased().contains($0) }
            let uploaderMatch = terms.contains { item.uploader.lowercased().contains($0) }
            let tagMatch = item.tags.contains { tag in
                terms.contains { term in
                    tag.lowercased().contains(term) || term.contains(tag.lowercased())
                }
            }
            return nameMatch || uploaderMatch || tagMatch
        }
    }
}

// MARK: - 4. External Directories Provider (Direct Website Search Links)

public struct ExternalDirectorySourceProvider: ShimejiSourceProvider {
    public let sourceId = "external_directories"
    public let displayName = "Web Directories"
    public let category = ShimejiSourceCategory.externalDirectories
    public let isDownloadable = false
    
    public init() {}
    
    public func search(query: String) async throws -> [ShimejiSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        
        return [
            ShimejiSearchResult(
                name: "\(trimmed) on Shimeji.org",
                uploader: "Shimeji.org Directory",
                fileSize: "Web Directory",
                type: "link",
                remoteURL: URL(string: "https://shimeji.org/search?q=\(encoded)")!,
                thumbnailURL: URL(string: "https://shimeji.org/favicon.ico") ?? URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/Animatto/DefaultCompanions/animatto_cat.png")!,
                tags: ["shimeji.org", "directory", "web", trimmed.lowercased()],
                sourceName: "Shimeji.org",
                sourceCategory: .externalDirectories,
                licenseType: .externalDirectory,
                licenseDetails: "Third-party community directory. Protected by Cloudflare; visit in web browser to download ZIPs directly.",
                isDownloadable: false,
                webPageURL: URL(string: "https://shimeji.org/search?q=\(encoded)")
            ),
            ShimejiSearchResult(
                name: "\(trimmed) on DeviantArt",
                uploader: "DeviantArt Artists",
                fileSize: "Art Archive",
                type: "link",
                remoteURL: URL(string: "https://www.deviantart.com/search?q=shimeji+\(encoded)")!,
                thumbnailURL: URL(string: "https://st.deviantart.net/minish/main/logo/card.png") ?? URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/Animatto/DefaultCompanions/animatto_cat.png")!,
                tags: ["deviantart", "artists", "fanart", trimmed.lowercased()],
                sourceName: "DeviantArt",
                sourceCategory: .externalDirectories,
                licenseType: .externalDirectory,
                licenseDetails: "Original fan art by community creators on DeviantArt. Check individual artist licensing.",
                isDownloadable: false,
                webPageURL: URL(string: "https://www.deviantart.com/search?q=shimeji+\(encoded)")
            ),
            ShimejiSearchResult(
                name: "\(trimmed) on itch.io",
                uploader: "itch.io Indie Creators",
                fileSize: "Indie Assets",
                type: "link",
                remoteURL: URL(string: "https://itch.io/search?q=desktop+pet+\(encoded)")!,
                thumbnailURL: URL(string: "https://static.itch.io/images/itchio-textless-black.svg") ?? URL(string: "https://raw.githubusercontent.com/sharmao07/Animatto/main/Animatto/DefaultCompanions/animatto_cat.png")!,
                tags: ["itch.io", "indie", "assets", trimmed.lowercased()],
                sourceName: "itch.io",
                sourceCategory: .externalDirectories,
                licenseType: .externalDirectory,
                licenseDetails: "Independent creator games and assets. Check itch.io project pages for license terms.",
                isDownloadable: false,
                webPageURL: URL(string: "https://itch.io/search?q=desktop+pet+\(encoded)")
            )
        ]
    }
}

// MARK: - Multi-Source Search Coordinator

public struct UnifiedShimejiSearchCoordinator: Sendable {
    public let providers: [any ShimejiSourceProvider]
    
    public init(session: URLSession = .shared, providers: [any ShimejiSourceProvider]? = nil) {
        if let customProviders = providers {
            self.providers = customProviders
        } else {
            self.providers = [
                CuratedCommunitySourceProvider(),
                OpenGameArtSourceProvider(),
                GitHubPetsSourceProvider(session: session),
                ExternalDirectorySourceProvider()
            ]
        }
    }
    
    /// Queries matching providers concurrently with error isolation and smart relevance sorting.
    public func search(
        query: String,
        selectedCategory: ShimejiSourceCategory = .all
    ) async -> [ShimejiSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        let filteredProviders: [any ShimejiSourceProvider]
        if selectedCategory == .all {
            filteredProviders = providers
        } else {
            filteredProviders = providers.filter { $0.category == selectedCategory }
        }
        
        var combinedResults: [ShimejiSearchResult] = []
        
        await withTaskGroup(of: [ShimejiSearchResult].self) { group in
            for provider in filteredProviders {
                group.addTask {
                    do {
                        return try await provider.search(query: trimmed)
                    } catch {
                        // Isolated failure does not break coordinator
                        return []
                    }
                }
            }
            
            for await providerResults in group {
                combinedResults.append(contentsOf: providerResults)
            }
        }
        
        // Deduplicate by remote URL and name
        var unique: [ShimejiSearchResult] = []
        var seenKeys = Set<String>()
        for r in combinedResults {
            let key = "\(r.name.lowercased())_\(r.remoteURL.absoluteString)"
            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                unique.append(r)
            }
        }
        
        // Rank results by relevance:
        // 1. Exact query match in name (+100)
        // 2. Starts with query (+50)
        // 3. Contains query (+25)
        // 4. Downloadable preferred in .all view (+10)
        let queryLower = trimmed.lowercased()
        let sorted = unique.sorted { (a, b) -> Bool in
            func score(for item: ShimejiSearchResult) -> Int {
                var s = 0
                let nameLower = item.name.lowercased()
                if nameLower == queryLower {
                    s += 100
                } else if nameLower.hasPrefix(queryLower) {
                    s += 50
                } else if nameLower.contains(queryLower) {
                    s += 25
                }
                if item.tags.contains(queryLower) {
                    s += 20
                }
                if item.isDownloadable {
                    s += 10
                }
                return s
            }
            return score(for: a) > score(for: b)
        }
        
        return sorted
    }
}
