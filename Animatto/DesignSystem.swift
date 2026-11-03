import SwiftUI
import AppKit
import Combine

// MARK: - Animatto Native macOS Design System (Phase 2)
// High-craft, quiet-chrome tokens and reusable components following Apple HIG,
// Unslop, and Hallmark design principles.

// MARK: - Centralized Accent Theme Preset & Manager
public enum AnimattoAccentPreset: String, CaseIterable, Identifiable {
    case coralBunny = "coralBunny"
    case oceanBlue = "oceanBlue"
    case emerald = "emerald"
    case sunsetOrange = "sunsetOrange"
    case royalViolet = "royalViolet"
    case system = "system"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .coralBunny: return "Coral Bunny"
        case .oceanBlue: return "Ocean Blue"
        case .emerald: return "Emerald"
        case .sunsetOrange: return "Sunset Orange"
        case .royalViolet: return "Royal Violet"
        case .system: return "System Accent"
        }
    }
    
    public var defaultHex: String {
        switch self {
        case .coralBunny: return "FF5A5F"
        case .oceanBlue: return "007AFF"
        case .emerald: return "34C759"
        case .sunsetOrange: return "FF9500"
        case .royalViolet: return "AF52DE"
        case .system: return "SYSTEM"
        }
    }
    
    public var previewColor: Color {
        switch self {
        case .coralBunny: return Color(hex: "FF5A5F")
        case .oceanBlue: return Color(hex: "007AFF")
        case .emerald: return Color(hex: "34C759")
        case .sunsetOrange: return Color(hex: "FF9500")
        case .royalViolet: return Color(hex: "AF52DE")
        case .system: return Color.accentColor
        }
    }
}

public final class AnimattoThemeManager: ObservableObject {
    public static let shared = AnimattoThemeManager()
    
    @Published public var currentAccentHex: String {
        didSet {
            UserDefaults.standard.set(currentAccentHex, forKey: "appAccentHex")
        }
    }
    
    public init() {
        let saved = UserDefaults.standard.string(forKey: "appAccentHex") ?? "FF5A5F"
        self.currentAccentHex = saved
    }
    
    public var isSystemAccent: Bool {
        currentAccentHex.uppercased() == "SYSTEM"
    }
    
    public var currentAccentColor: Color {
        if isSystemAccent {
            return Color.accentColor
        }
        return Color(hex: currentAccentHex)
    }
    
    public func setPreset(_ preset: AnimattoAccentPreset) {
        currentAccentHex = preset.defaultHex
    }
    
    public func setHex(_ hex: String) {
        currentAccentHex = hex
    }
}

public enum AnimattoTheme {
    // Dynamic Accent Color
    public static var accentColor: Color {
        AnimattoThemeManager.shared.currentAccentColor
    }
    // Spacing (Strict 4px Grid)
    public static let space2: CGFloat = 2
    public static let space4: CGFloat = 4
    public static let space8: CGFloat = 8
    public static let space12: CGFloat = 12
    public static let space16: CGFloat = 16
    public static let space20: CGFloat = 20
    public static let space24: CGFloat = 24
    public static let space32: CGFloat = 32
    
    // Corner Radii
    public static let radius4: CGFloat = 4
    public static let radius6: CGFloat = 6
    public static let radius8: CGFloat = 8
    public static let radius10: CGFloat = 10
    public static let radius12: CGFloat = 12
    public static let radius16: CGFloat = 16
    
    // Hairline Border
    public static let hairline: CGFloat = 1.0
    
    // Semantic System Colors (Light & Dark Adaptive)
    public static var surfaceBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }
    
    public static var controlBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }
    
    public static var sidebarBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }
    
    public static var cardBackground: Color {
        Color(nsColor: .controlBackgroundColor).opacity(0.75)
    }
    
    public static var cardElevated: Color {
        Color(nsColor: .controlBackgroundColor)
    }
    
    public static var subtleBorder: Color {
        Color.primary.opacity(0.08)
    }
    
    public static var divider: Color {
        Color.primary.opacity(0.08)
    }
    
    public static var hoverOverlay: Color {
        Color.primary.opacity(0.04)
    }
    
    public static var pressedOverlay: Color {
        Color.primary.opacity(0.08)
    }
}

// MARK: - Reusable Card Container
public struct AnimattoCard<Content: View>: View {
    private let content: Content
    private let isSelected: Bool
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    
    public init(
        isSelected: Bool = false,
        padding: CGFloat = AnimattoTheme.space12,
        cornerRadius: CGFloat = AnimattoTheme.radius10,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AnimattoTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSelected ? AnimattoTheme.accentColor : AnimattoTheme.subtleBorder,
                        lineWidth: isSelected ? 1.5 : AnimattoTheme.hairline
                    )
            )
    }
}

// MARK: - Section Header View
public struct AnimattoSectionHeader<Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let icon: String?
    private let trailing: Trailing?
    
    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.trailing = trailing()
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: AnimattoTheme.space8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 18)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let trailing = trailing {
                trailing
            }
        }
        .padding(.vertical, AnimattoTheme.space4)
    }
}

public extension AnimattoSectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, icon: String? = nil) {
        self.init(title: title, subtitle: subtitle, icon: icon, trailing: { EmptyView() })
    }
}

// MARK: - Standardized Badge Pill
public struct AnimattoBadge: View {
    private let title: String
    private let icon: String?
    private let tintColor: Color
    
    public init(_ title: String, icon: String? = nil, color: Color = .secondary) {
        self.title = title
        self.icon = icon
        self.tintColor = color
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .medium))
            }
            Text(title)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(tintColor.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(tintColor.opacity(0.24), lineWidth: 0.5)
        )
        .foregroundColor(tintColor)
    }
}

// MARK: - Standardized Setting / Control Row
public struct AnimattoToggleRow: View {
    private let title: String
    private let description: String?
    private let icon: String?
    @Binding private var isOn: Bool
    
    public init(
        _ title: String,
        description: String? = nil,
        icon: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self._isOn = isOn
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: AnimattoTheme.space12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 18)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                
                if let description = description {
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .accessibilityLabel(title)
        }
        .padding(.vertical, AnimattoTheme.space6)
    }
}

// MARK: - Standardized Slider Row
public struct AnimattoSliderRow: View {
    private let title: String
    private let description: String?
    private let icon: String?
    private let range: ClosedRange<Double>
    private let step: Double?
    private let format: (Double) -> String
    @Binding private var value: Double
    
    public init(
        _ title: String,
        description: String? = nil,
        icon: String? = nil,
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0.0...1.0,
        step: Double? = nil,
        format: @escaping (Double) -> String = { "\(Int($0 * 100))%" }
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: AnimattoTheme.space8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(format(value))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            if let step = step {
                Slider(value: $value, in: range, step: step)
                    .controlSize(.small)
            } else {
                Slider(value: $value, in: range)
                    .controlSize(.small)
            }
            
            if let description = description {
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, AnimattoTheme.space4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(format(value))
    }
}

// MARK: - Reusable Empty State View
public struct AnimattoEmptyState: View {
    private let icon: String
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?
    
    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: AnimattoTheme.space12) {
            Image(systemName: icon)
                .font(.system(size: 38, weight: .light))
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.bottom, AnimattoTheme.space4)
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.top, AnimattoTheme.space8)
            }
        }
        .padding(AnimattoTheme.space24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sidebar Navigation Item
public struct AnimattoSidebarItem: View {
    private let title: String
    private let icon: String
    private let isSelected: Bool
    private let badge: String?
    private let action: () -> Void
    @State private var isHovered = false
    
    public init(
        title: String,
        icon: String,
        isSelected: Bool,
        badge: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.badge = badge
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AnimattoTheme.space8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AnimattoTheme.accentColor : .secondary)
                    .frame(width: 18)
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(Color.primary.opacity(0.08))
                        )
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, AnimattoTheme.space10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: AnimattoTheme.radius6)
                    .fill(
                        isSelected ? AnimattoTheme.accentColor.opacity(0.14) :
                        (isHovered ? AnimattoTheme.hoverOverlay : Color.clear)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// Additional spacing token helper
public extension AnimattoTheme {
    static let space6: CGFloat = 6
    static let space10: CGFloat = 10
}
