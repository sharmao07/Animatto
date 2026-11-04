import SwiftUI
import AppKit

// MARK: - Free vs Premium Comparison & License Activation Modal
public struct FreeVsPremiumSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    @ObservedObject private var themeManager = AnimattoThemeManager.shared
    
    @State private var licenseInput: String = ""
    @State private var activationError: String? = nil
    @State private var activationSuccess: Bool = false
    
    private let checkoutProURL = URL(string: "https://animatto.app/api/checkout?tier=pro&redirect=true")!
    private let checkoutFounderURL = URL(string: "https://animatto.app/api/checkout?tier=founder&redirect=true")!
    private let recoveryURL = URL(string: "https://animatto.app/api/license?action=recover")!
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // Header Bar
            HStack(spacing: AnimattoTheme.space12) {
                Image(systemName: "hare.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeManager.currentAccentColor)
                    .frame(width: 28, height: 28)
                    .background(themeManager.currentAccentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Animatto Open-Core & Licensing")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text("100% free offline core under Apache-2.0 • Zero paywalls on core features")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AnimattoTheme.space20)
            .padding(.top, AnimattoTheme.space16)
            .padding(.bottom, AnimattoTheme.space12)
            
            Divider()
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
                    
                    // 1. Current Entitlement Status Card
                    currentStatusCard
                    
                    // 2. Free Core vs Pro Comparison Table
                    comparisonTableCard
                    
                    // 3. License Key Activation Card
                    licenseActivationCard
                    
                    // 4. Developer / QA Mock Tester
                    #if DEBUG
                    developerMockCard
                    #endif
                }
                .padding(AnimattoTheme.space20)
            }
        }
        .frame(width: 680, height: 600)
        .background(AnimattoTheme.surfaceBackground)
    }
    
    // MARK: - Current Status Card
    
    private var currentStatusCard: some View {
        AnimattoCard {
            VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                HStack(alignment: .top, spacing: AnimattoTheme.space12) {
                    statusIcon
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entitlementManager.status.displayTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            AnimattoBadge(
                                entitlementManager.status.statusBadgeTitle,
                                icon: statusBadgeIcon,
                                color: statusColor
                            )
                            
                            Spacer()
                            
                            if let key = entitlementManager.redactedActiveKey() {
                                Text(key)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(entitlementManager.status.statusSummary)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // If unlicensed, show direct Lifetime Pro and Founder Supporter CTAs
                if entitlementManager.status == .unlicensed {
                    Divider()
                    
                    VStack(spacing: AnimattoTheme.space10) {
                        // Tier 1: Lifetime Pro
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Lifetime Pro — $3.99 USD")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.primary)
                                    AnimattoBadge("One-Time", icon: "sparkles", color: .blue)
                                }
                                Text("Lifetime access to all Pro features • Up to 3 Macs • No subscription")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                NSWorkspace.shared.open(checkoutProURL)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text("Get Pro ($3.99)")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        
                        Divider()
                        
                        // Tier 2: Founder Supporter
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Founder Supporter — $5.99 USD")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.primary)
                                    AnimattoBadge("Founder", icon: "heart.fill", color: .purple)
                                }
                                Text("All Pro features + name in repository README (optional) + early beta access")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                NSWorkspace.shared.open(checkoutFounderURL)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                    Text("Become Founder ($5.99)")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .controlSize(.small)
                        }
                    }
                } else if case .valid(let key, _, _) = entitlementManager.status {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                if let payload = entitlementManager.activePayload {
                                    Text("Tier: \(payload.licenseTier.displayName) • Order: \(payload.orderId)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                Text("Device ID: \(entitlementManager.currentDeviceId) • \(entitlementManager.activeDeviceSlots.active)/\(entitlementManager.activeDeviceSlots.maxAllowed) Macs Active")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Deactivate This Mac") {
                                entitlementManager.deactivateDeviceOnline(licenseKey: key) { _ in }
                                licenseInput = ""
                                activationSuccess = false
                                activationError = nil
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        if let payload = entitlementManager.activePayload, payload.licenseTier == .founder {
                            HStack(spacing: 8) {
                                AnimattoBadge("Founder Supporter", icon: "crown.fill", color: .purple)
                                AnimattoBadge("Early Beta Access", icon: "sparkles", color: .blue)
                                if entitlementManager.supporterConsentEnabled {
                                    AnimattoBadge("README Listed", icon: "doc.text.fill", color: .green)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch entitlementManager.status {
        case .unlicensed: return .blue
        case .valid: return .green
        case .gracePeriod: return .orange
        case .expired: return .yellow
        case .revoked: return .red
        }
    }
    
    private var statusIcon: some View {
        Group {
            switch entitlementManager.status {
            case .unlicensed:
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            case .valid:
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
            case .gracePeriod:
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
            case .expired:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.yellow)
            case .revoked:
                Image(systemName: "xmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var statusBadgeIcon: String {
        switch entitlementManager.status {
        case .unlicensed: return "doc.text.fill"
        case .valid: return "checkmark.circle.fill"
        case .gracePeriod: return "clock.fill"
        case .expired: return "exclamationmark.circle.fill"
        case .revoked: return "xmark.circle.fill"
        }
    }
    
    // MARK: - Comparison Table
    
    private var comparisonTableCard: some View {
        VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
            AnimattoSectionHeader(
                title: "Core Freedoms & Tier Comparison",
                subtitle: "Every fundamental capability is permanently free under Apache-2.0.",
                icon: "tablecells"
            )
            
            AnimattoCard(padding: 0) {
                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text("Capability / Pillar")
                            .font(.system(size: 11, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Free Core (Apache-2.0)")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 170, alignment: .center)
                            .foregroundColor(.blue)
                        
                        Text("Animatto Pro")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 150, alignment: .center)
                            .foregroundColor(themeManager.currentAccentColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.primary.opacity(0.04))
                    
                    Divider()
                    
                    // Rows
                    comparisonRow(
                        title: "1. Desktop Companions & Physics",
                        detail: "Walking, falling, climbing, menu bar upside-down",
                        free: "Unlimited Free",
                        pro: "Unlimited Free"
                    )
                    comparisonRow(
                        title: "2. Sprite Animation & Shimeji Import",
                        detail: "Custom XML, multi-frame APNG/GIF, asset caching",
                        free: "Included",
                        pro: "Included"
                    )
                    comparisonRow(
                        title: "3. Desktop Aquarium Widget",
                        detail: "4 species, 3D buoyancy, schooling tetras, feeding",
                        free: "Included (60fps)",
                        pro: "Included (60fps)"
                    )
                    comparisonRow(
                        title: "4. Ambient Worlds Engine",
                        detail: "Rain, Snow, Starfall, procedural weather soundscapes",
                        free: "Included",
                        pro: "Included"
                    )
                    comparisonRow(
                        title: "5. Focus Timer & Behaviour Sync",
                        detail: "Pomodoro sessions, break states, distraction shields",
                        free: "Included",
                        pro: "Included"
                    )
                    comparisonRow(
                        title: "6. Procedural Audio Engine",
                        detail: "Footstep synthesis, purring, underwater aerator",
                        free: "Included",
                        pro: "Included"
                    )
                    comparisonRow(
                        title: "7. Offline Privacy & Zero Telemetry",
                        detail: "Zero analytics, zero tracking, 100% on-device",
                        free: "100% Offline",
                        pro: "100% Offline"
                    )
                    comparisonRow(
                        title: "8. Pro Sound Studio & Acoustics",
                        detail: "High-fidelity parametric sound profiles & ambience",
                        free: "—",
                        pro: "Included in Pro"
                    )
                    comparisonRow(
                        title: "9. Pro Custom Palettes & Themes",
                        detail: "Exclusive color gradations, badge styling & morphs",
                        free: "—",
                        pro: "Included in Pro"
                    )
                    comparisonRow(
                        title: "10. Multi-Mac Licensing",
                        detail: "Permanent license activation on up to 3 personal Macs",
                        free: "Single Device",
                        pro: "Up to 3 Macs"
                    )
                    comparisonRow(
                        title: "11. Early Public Beta Access",
                        detail: "Early access to public release candidates and beta testing",
                        free: "Standard",
                        pro: "Included in Founder"
                    )
                    comparisonRow(
                        title: "12. Repository Acknowledgement",
                        detail: "Optional supporter recognition in GitHub repository README (with consent)",
                        free: "—",
                        pro: "Founder Tier"
                    )
                }
            }
        }
    }
    
    private func comparisonRow(title: String, detail: String, free: String, pro: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                    Text(detail)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 4) {
                    if free != "—" {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                    Text(free)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(free == "—" ? .secondary : .primary)
                }
                .frame(width: 170, alignment: .center)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(themeManager.currentAccentColor)
                    Text(pro)
                        .font(.system(size: 10, weight: .medium))
                }
                .frame(width: 150, alignment: .center)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            
            Divider()
                .padding(.horizontal, 8)
        }
    }
    
    // MARK: - License Activation Card
    
    private var licenseActivationCard: some View {
        VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
            AnimattoSectionHeader(
                title: "License Key Activation",
                subtitle: "Enter your cryptographically signed Animatto Pro license key.",
                icon: "key.fill"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    HStack(spacing: AnimattoTheme.space8) {
                        TextField("ANIM-PRO-eyJvcm...", text: $licenseInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                        
                        Button("Activate Key") {
                            activateKey()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(licenseInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if let error = activationError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                        }
                    }
                    
                    if activationSuccess {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("License key verified and stored securely in macOS Keychain!")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Button(action: {
                            NSWorkspace.shared.open(recoveryURL)
                        }) {
                            Text("Lost your license key? Retrieve via email →")
                                .font(.system(size: 11))
                                .foregroundColor(themeManager.currentAccentColor)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text("14-Day Money Back Guarantee")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func activateKey() {
        activationError = nil
        activationSuccess = false
        
        let key = licenseInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = entitlementManager.activateLicenseWithDetails(key: key)
        if result.success {
            activationSuccess = true
            licenseInput = ""
            AudioEngine.shared.playUISound(.select)
            entitlementManager.syncDeviceActivationOnline(licenseKey: key) { _ in }
        } else {
            activationError = result.error ?? "Invalid license token or cryptographic signature."
            AudioEngine.shared.playUISound(.click)
        }
    }
    
    // MARK: - Developer / QA Mock Tester
    
    #if DEBUG
    private var developerMockCard: some View {
        VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
            AnimattoSectionHeader(
                title: "Development & QA Mock Tester",
                subtitle: "Test all entitlement states without real payment credentials.",
                icon: "hammer.fill"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space10) {
                    Text("Simulate Entitlement States (Debug Build Only):")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Button("Free Core (Default)") {
                            entitlementManager.activateMockState(.unlicensed)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Valid Lifetime Pro") {
                            entitlementManager.activateLicense(key: "ANIM-PRO-TEST-ACTIVE")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Valid Founder Supporter") {
                            entitlementManager.activateLicense(key: "ANIM-FOUNDER-TEST-ACTIVE")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Grace Period") {
                            entitlementManager.activateMockState(
                                .gracePeriod(licenseKey: "ANIM-PRO-TEST-GRACE", expiry: nil, errorReason: "Mock offline state")
                            )
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Expired") {
                            entitlementManager.activateMockState(
                                .expired(licenseKey: "ANIM-PRO-TEST-EXPIRED")
                            )
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Revoked") {
                            entitlementManager.activateMockState(
                                .revoked(licenseKey: "ANIM-PRO-TEST-REVOKED", reason: "Mock chargeback")
                            )
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }
    #endif
}
