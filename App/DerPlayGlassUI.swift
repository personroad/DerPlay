// DerPlay presentation layer. No transport, credentials or session ownership.
import UIKit
import SwiftUI
import AVKit

@MainActor enum DerPlayHaptics {
    private static let defaultsKey = "derPlayHapticFeedbackEnabled"
    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: defaultsKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }
    static func lightImpact() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

@MainActor enum DerPlayGlassPalette {
    static let canvas = UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(red: 0.88, green: 0.90, blue: 0.92, alpha: 1)
    }
    // A single tint over the native sheet material; no separate navigation blur.
    static let sheetTint = UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(white: 0.18, alpha: 1) : UIColor(red: 0.90, green: 0.92, blue: 0.94, alpha: 1)
    }
    static let card = UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(white: 0.35, alpha: 0.28) : UIColor(white: 1, alpha: 0.32)
    }
    static let accent = UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(white: 0.94, alpha: 1) : UIColor(white: 0.23, alpha: 1)
    }
    static let startGreen = UIColor(red: 52.0 / 255, green: 199.0 / 255, blue: 89.0 / 255, alpha: 1)
    static let stopRed = UIColor(red: 255.0 / 255, green: 59.0 / 255, blue: 48.0 / 255, alpha: 1)
    // Keep old SDKs and iOS 16–25 on the original controls.
    static var usesNativeButtonGlass: Bool {
        #if compiler(>=6.2)
        if #available(iOS 26.0, macCatalyst 26.0, *) {
            return !UIAccessibility.isReduceTransparencyEnabled
        }
        #endif
        return false
    }
    static func nativeButtonConfiguration(prominent: Bool = false) -> UIButton.Configuration? {
        #if compiler(>=6.2)
        if #available(iOS 26.0, macCatalyst 26.0, *), usesNativeButtonGlass {
            return prominent ? .prominentGlass() : .glass()
        }
        #endif
        return nil
    }
    static func applyVideoButtonGlass(_ button: UIButton, image: UIImage?) {
        guard var configuration = nativeButtonConfiguration() else {
            button.configuration = nil
            button.setImage(image, for: .normal)
            button.tintColor = .white
            button.backgroundColor = UIAccessibility.isReduceTransparencyEnabled ? .black : UIColor.black.withAlphaComponent(0.55)
            return
        }
        configuration.cornerStyle = .capsule
        configuration.image = image
        configuration.baseForegroundColor = .white
        configuration.contentInsets = .zero
        button.overrideUserInterfaceStyle = .dark
        button.backgroundColor = .clear
        button.layer.borderWidth = 0
        button.layer.shadowOpacity = 0
        button.configuration = configuration
    }
    static func shadow(_ view: UIView, radius: CGFloat = 16, offset: CGFloat = 8) {
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = view.traitCollection.userInterfaceStyle == .dark ? 0.65 : 0.32
        view.layer.shadowRadius = radius
        view.layer.shadowOffset = CGSize(width: 0, height: offset)
    }
    // R161: preview cards only; leave other glass surfaces unchanged.
    static func previewShadow(_ view: UIView) {
        shadow(view, radius: 8, offset: 10)
        view.layer.shadowOpacity = 0.22
    }
    static func styleAction(_ button: UIButton, radius: CGFloat = 23) {
        button.configuration?.cornerStyle = .fixed
        button.configuration?.background.cornerRadius = radius
        button.configuration?.background.backgroundColor = card
        button.configuration?.background.strokeColor = UIColor.white.withAlphaComponent(0.12)
        button.configuration?.background.strokeWidth = 0.7
        button.configuration?.baseForegroundColor = accent
        shadow(button, radius: 12, offset: 6)
    }
    static func decorate(_ view: UIView, radius: CGFloat) {
        view.backgroundColor = card
        view.layer.cornerRadius = radius
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 0.6
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        shadow(view)
    }
}

/// The app preference must not override UIWindow or its navigation controller:
/// their traits remain the unmodified system appearance source for CarPlay.
enum DerPlaySoftwareAppearance: String, CaseIterable {
    case dark, light
    static let defaultsKey = "derplay.softwareAppearance"
    var title: String { self == .dark ? CWL("开启") : CWL("关闭") }
    var symbol: String { self == .dark ? "moon.stars" : "sun.max" }
    var style: UIUserInterfaceStyle { self == .dark ? .dark : .light }
    static func saved(in defaults: UserDefaults = .standard) -> Self {
        // Migrate the former "follow system" choice to night mode OFF.
        guard let raw = defaults.string(forKey: defaultsKey) else { return .light }
        if let value = Self(rawValue: raw) { return value }
        defaults.set(Self.light.rawValue, forKey: defaultsKey)
        return .light
    }
}

/// A non-interactive trait observer attached to the unoverridden parent view,
/// so forced app appearance cannot hide system day/night changes.
final class DerPlaySystemAppearanceObserver: UIView {
    var onChange: (() -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        isHidden = true
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in self.onChange?() }
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17.0), previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle { onChange?() }
    }
}

struct DerPlayGlassBackdrop: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            LinearGradient(colors: scheme == .dark ? [Color(white: 0.25), Color(white: 0.08)] : [Color(red: 0.91, green: 0.94, blue: 0.96), Color(red: 0.71, green: 0.75, blue: 0.79)], startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Color(white: 0.75).opacity(scheme == .dark ? 0.12 : 0.35), .clear], center: .leading, startRadius: 5, endRadius: 380)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

@MainActor final class DerPlayGlassDashboardState: ObservableObject {
    @Published var mode = ""
    @Published var locked = false
    @Published var statusLines: [String] = []
    @Published var needsCertificate = false
    @Published var browserCopyAddress: String?
    @Published var browserCopyAddressLabel: String?
    @Published var browserAddressCopied = false
    @Published var showsAirPlayPicker = false
    @Published var airPlayPickerReady = false
}

// Host the existing native route picker; never create a parallel discovery or playback session.
@MainActor private struct DerPlayHomeAirPlayPicker: UIViewRepresentable {
    let picker: AVRoutePickerView
    func makeUIView(context: Context) -> AVRoutePickerView { picker }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}


private extension UIView {
    func firstSubview<T: UIView>(of type: T.Type) -> T? {
        if let view = self as? T { return view }
        for subview in subviews {
            if let match = subview.firstSubview(of: type) { return match }
        }
        return nil
    }
}

@MainActor struct DerPlayGlassDashboard: View {
    @ObservedObject var state: DerPlayGlassDashboardState
    let settings: () -> Void
    let connection: () -> Void
    let importCertificate: () -> Void
    let copyBrowserAddress: (String) -> Void
    let airPlayPicker: AVRoutePickerView
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private func openAirPlayPicker() {
        guard state.airPlayPickerReady else { return }
        airPlayPicker.layoutIfNeeded()
        airPlayPicker.firstSubview(of: UIButton.self)?.sendActions(for: .touchUpInside)
    }

    private func menuRow(_ title: String, symbol: String, value: String = "", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 19)).frame(width: 24)
                Text(title).font(.body).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                if !value.isEmpty { Text(value).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.trailing).fixedSize(horizontal: false, vertical: true) }
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    private var rows: some View {
        VStack(spacing: 0) {
            menuRow(CWL("通用设置"), symbol: "gearshape", action: settings)
            Divider()
            menuRow(CWL("连接模式"), symbol: "car", value: state.mode, action: connection)
            if !state.statusLines.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(state.statusLines.enumerated()), id: \.offset) { index, line in
                        VStack(alignment: .leading, spacing: 5) {
                            if state.needsCertificate && line == CWL("需要导入 MFi 证书") {
                                Button(action: importCertificate) {
                                    HStack {
                                        Text(line).font(.subheadline)
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                                    }
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(line).font(.subheadline).foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if index == min(1, state.statusLines.count - 1),
                               let address = state.browserCopyAddress,
                               let label = state.browserCopyAddressLabel {
                                Button {
                                    copyBrowserAddress(address)
                                } label: {
                                    Text(state.browserAddressCopied ? CWL("访问地址已复制") : label)
                                        .font(.subheadline)
                                        .underline(false)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint(CWL("复制访问地址"))
                            }
                        }
                    }
                }.padding(.vertical, 14)
            }
            if state.showsAirPlayPicker {
                Divider()
                Button(action: openAirPlayPicker) {
                    HStack(spacing: 12) {
                        Text("选择 AirPlay 设备").font(.body)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityHidden(true)
                        Image(systemName: "airplayvideo")
                            .font(.system(size: 23, weight: .regular))
                            .foregroundStyle(scheme == .dark ? Color.white : Color.black)
                            .frame(width: 44, height: 44, alignment: .center)
                            .opacity(state.airPlayPickerReady ? 1 : 0.45)
                            .allowsHitTesting(false)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!state.airPlayPickerReady)
                .overlay(alignment: .trailing) {
                    DerPlayHomeAirPlayPicker(picker: airPlayPicker)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 16)
        .foregroundStyle(.primary)
    }
    @ViewBuilder var body: some View {
        // Compile old SDKs without referencing the iOS 26 API. Reduced transparency gets solid fill.
        if reduceTransparency {
            rows.background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 23))
                .shadow(color: .black.opacity(scheme == .dark ? 0.60 : 0.25), radius: 20, x: 0, y: 12)
        } else {
            #if compiler(>=6.2)
            if #available(iOS 26.0, macCatalyst 26.0, *) {
                // Regular glass keeps the menu text legible over the varying backdrop.
                // Let the system supply depth; do not add another large drop shadow.
                rows.glassEffect(.regular, in: .rect(cornerRadius: 23))
            } else {
                fallback
            }
            #else
            fallback
            #endif
        }
    }
    private var fallback: some View {
        rows.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 23))
            .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(.white.opacity(0.18), lineWidth: 0.8))
            .shadow(color: .black.opacity(scheme == .dark ? 0.65 : 0.25), radius: 20, x: 0, y: 12)
    }
}

// A bar item can otherwise compress an image-only glass button to a shallow pill.
// Supply a square intrinsic size as well as the explicit layout constraints.
@MainActor private final class DerPlayCircularPlaybackButton: UIButton {
    override var intrinsicContentSize: CGSize { CGSize(width: 44, height: 44) }
    override func sizeThatFits(_ size: CGSize) -> CGSize { intrinsicContentSize }
}

// A native navigation stack hosted inside ONE system sheet. Keep legacy page lifecycles,
// controls, alerts, file pickers, keyboard and callbacks intact.
final class DerPlayGlassNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    var onClose: (() -> Void)?
    var onContentHeightChanged: (() -> Void)?
    var reservesConnectionPlayback = false
    var onPlaybackSlotChanged: (() -> Void)?
    var playbackSlot: UIView? {
        topViewController?.navigationItem.rightBarButtonItems?.first {
            $0.accessibilityIdentifier == "derplay.connection.slot"
        }?.customView
    }
    private var contentHeight: CGFloat = 0
    private var lastResolvedHeight: CGFloat?
    private var heightLocked = false
    private var detentUpdatePending = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func resolvedHeight(maximum: CGFloat) -> CGFloat {
        let limit = maximum * 0.86
        // Once deeper navigation begins, retain the last resolved sheet height.
        // Only a changed container size (rotation, multitasking) may clamp it.
        if heightLocked { return min(limit, lastResolvedHeight ?? limit) }
        let height = contentHeight > 0 ? min(limit, max(240, contentHeight)) : limit
        lastResolvedHeight = height
        return height
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Measure the initial root only. Child pages scroll inside the existing sheet.
        guard !heightLocked, viewControllers.count == 1,
              let page = topViewController as? SettingsPageController, let table = page.tableView else { return }
        let height = table.contentSize.height + navigationBar.bounds.height + 32
        guard height.isFinite, height > 80, abs(height - contentHeight) > 12 else { return }
        contentHeight = height
        guard !detentUpdatePending else { return }
        detentUpdatePending = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.detentUpdatePending = false
            // A queued root layout pass must never resize a push/pop transition.
            guard !self.heightLocked, self.viewControllers.count == 1 else { return }
            self.sheetPresentationController?.invalidateDetents()
            self.onContentHeightChanged?()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNavigationMaterials), name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)
        if viewControllers.count > 1 { heightLocked = true }
        view.tintColor = DerPlayGlassPalette.accent
        navigationBar.tintColor = DerPlayGlassPalette.accent
        navigationBar.prefersLargeTitles = false
        additionalSafeAreaInsets.top = 8
        interactivePopGestureRecognizer?.delegate = self
        // UIKit owns the native sheet material. Tint the navigation root once,
        // rather than compositing independent blur views during push/pop.
        view.backgroundColor = DerPlayGlassPalette.sheetTint
        // Opaque content prevents underlying dashboard text from bleeding through.
        interactivePopGestureRecognizer?.isEnabled = viewControllers.count > 1
        navigationBar.isTranslucent = true
        let appearance = sharedBarAppearance()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance
        if let topViewController {
            applySharedAppearance(to: topViewController)
            clearTrailingPlaybackControls(on: topViewController)
            installBack(on: topViewController)
        }
    }
    // Native navigation animations and interactive edge-back, with opaque pages.
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        heightLocked = true
        viewController.view.backgroundColor = DerPlayGlassPalette.sheetTint
        super.pushViewController(viewController, animated: animated)
    }
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        interactivePopGestureRecognizer?.isEnabled = viewControllers.count > 1
        onPlaybackSlotChanged?()
    }
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // Keep the same sheet position for every push, pop and interactive back.
        // Do not reset the height even after returning to the root.
        if viewController !== viewControllers.first { heightLocked = true }
        applySharedAppearance(to: viewController)
        clearTrailingPlaybackControls(on: viewController)
        installBack(on: viewController)
    }
    private func sharedBarAppearance() -> UINavigationBarAppearance {

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = DerPlayGlassPalette.sheetTint
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        return appearance
    }
    private func applySharedAppearance(to page: UIViewController) {
        page.view.backgroundColor = DerPlayGlassPalette.sheetTint
        let appearance = sharedBarAppearance()
        page.navigationItem.standardAppearance = appearance
        page.navigationItem.scrollEdgeAppearance = appearance
        page.navigationItem.compactAppearance = appearance
        page.navigationItem.compactScrollEdgeAppearance = appearance
    }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1 && transitionCoordinator == nil
    }
    @objc private func refreshNavigationMaterials() {
        for page in viewControllers {
            let items = (page.navigationItem.leftBarButtonItems ?? []) + (page.navigationItem.rightBarButtonItems ?? [])
            for item in items {
                guard let button = item.customView as? UIButton,
                      button.accessibilityIdentifier == "derplay.navigation.glass",
                      let image = button.configuration?.image else { continue }
                button.configuration = navigationGlassConfiguration(image: image)
                button.layer.shadowOpacity = DerPlayGlassPalette.usesNativeButtonGlass ? 0 : 0.12
                button.transform = .identity
            }
        }
    }
    private func navigationGlassConfiguration(image: UIImage?) -> UIButton.Configuration {
        let native = DerPlayGlassPalette.nativeButtonConfiguration()
        var configuration = native ?? UIButton.Configuration.filled()
        configuration.cornerStyle = .capsule
        configuration.image = image
        configuration.baseForegroundColor = .label
        if native == nil {
            configuration.baseBackgroundColor = UIColor { traits in
                traits.userInterfaceStyle == .dark ? UIColor(white: 0.28, alpha: 1) : UIColor(white: 0.98, alpha: 1)
            }
            configuration.background.strokeColor = UIColor { traits in
                UIColor.white.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.20 : 0.85)
            }
            configuration.background.strokeWidth = 0.8
        }
        return configuration
    }
    private func glassButton(symbol: String, label: String, action: @escaping () -> Void) -> UIBarButtonItem {
        let image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        let primaryAction = UIAction { _ in
            DerPlayHaptics.lightImpact()
            action()
        }

        #if compiler(>=6.2)
        if #available(iOS 26.0, macCatalyst 26.0, *) {
            // Let UIKit own navigation-bar glass and its transition snapshots.
            // Custom UIButton.Configuration.glass() views inside bar items can briefly
            // expose a square backing layer while a page is pushed or popped.
            let item = UIBarButtonItem(image: image, primaryAction: primaryAction)
            item.accessibilityLabel = label
            item.accessibilityIdentifier = "derplay.navigation.glass"
            item.tintColor = .label
            return item
        }
        #endif

        // Older systems retain the custom capsule, where UIKit has no native
        // navigation-bar glass treatment.
        let configuration = navigationGlassConfiguration(image: image)
        let button = UIButton(configuration: configuration, primaryAction: primaryAction)
        button.accessibilityLabel = label
        button.accessibilityIdentifier = "derplay.navigation.glass"
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.12
        button.layer.shadowRadius = 3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.configurationUpdateHandler = { button in
            guard !UIAccessibility.isReduceMotionEnabled else { button.transform = .identity; return }
            UIView.animate(withDuration: 0.15) {
                button.transform = button.isHighlighted
                    ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity
            }
        }
        let item = UIBarButtonItem(customView: button)
        item.accessibilityLabel = label
        return item
    }
    private func installBack(on page: UIViewController) {
        guard page !== viewControllers.first, page.navigationItem.leftBarButtonItem == nil else { return }
        page.navigationItem.leftBarButtonItem = glassButton(symbol: "chevron.backward", label: "返回") { [weak self] in
            self?.popViewController(animated: true)
        }
    }
    // R204: settings are dismissed with the native sheet drag gesture.
    private func clearTrailingPlaybackControls(on page: UIViewController) {
        let items = (page.navigationItem.rightBarButtonItems ?? []).filter {
            $0.accessibilityIdentifier != "derplay.navigation.playback" && $0.accessibilityIdentifier != "derplay.close.settings" && $0.accessibilityIdentifier != "derplay.connection.slot"
        }
        if reservesConnectionPlayback {
            // Preserve the existing anchor across repeated willShow callbacks.
            if let existing = page.navigationItem.rightBarButtonItems?.first(where: {
                $0.accessibilityIdentifier == "derplay.connection.slot" && $0.customView != nil
            }) {
                page.navigationItem.rightBarButtonItems = [existing] + items
                return
            }
            let anchor = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            anchor.isUserInteractionEnabled = false
            anchor.isAccessibilityElement = false
            anchor.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([anchor.widthAnchor.constraint(equalToConstant: 44), anchor.heightAnchor.constraint(equalToConstant: 44)])
            let slot = UIBarButtonItem(customView: anchor)
            slot.width = 44
            #if compiler(>=6.2)
            if #available(iOS 26.0, macCatalyst 26.0, *) {
                slot.hidesSharedBackground = true
            }
            #endif
            slot.accessibilityIdentifier = "derplay.connection.slot"
            page.navigationItem.rightBarButtonItems = [slot] + items
        } else {
            page.navigationItem.rightBarButtonItems = items.isEmpty ? nil : items
        }
    }

}

/// Persistent L2 layer. The button and panel are siblings; neither is reparented.
final class ConnectionControlLayer: UIView, UIGestureRecognizerDelegate {
    let panel = UIView()
    let backdrop = UIControl()
    private let backdropTint = UIView()
    let grabber = UIView()
    private let button: UIButton
    private weak var homeSlot: UIView?
    private var animator: UIViewPropertyAnimator?
    private var generation = 0
    private(set) var progress: CGFloat = 0
    private var dragStart: CGFloat = 0
    private var dragReturnOpen = false
    private weak var dragOwner: UIPanGestureRecognizer?
    private var dragging = false
    private var contentConstraints: [NSLayoutConstraint] = []
    private var keyboardLimit: NSLayoutConstraint?
    private var targetOpen = false
    var playbackSlot: (() -> UIView?)?
    var onBeginOpening: (() -> Bool)?
    var onClosed: (() -> Void)?
    var canDrag: (() -> Bool)?
    // A single session uses a stable height. Content changes scroll inside it.
    var panelHeight: CGFloat = 0
    private struct MotionGeometry {
        let bounds: CGRect
        let height: CGFloat
        let home: CGRect
        let end: CGRect
    }
    private var motionGeometry: MotionGeometry?
    var active = false { didSet { if active != oldValue { updateButtonAppearance() } } }
    private let playbackContent = UIView()
    private let playbackIcon = UIImageView()
    private let playbackTitle = UILabel()
    private var pendingLayout = false
    private lazy var buttonPan = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
    private lazy var headerPan = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))

    init(button: UIButton, homeSlot: UIView) {
        self.button = button
        self.homeSlot = homeSlot
        super.init(frame: .zero)
        backgroundColor = .clear
        // Keep the hit-test surface active even at the first frame of expansion.
        backdrop.backgroundColor = .clear
        backdrop.isAccessibilityElement = false
        backdrop.addTarget(self, action: #selector(closeFromBackdrop), for: .touchUpInside)
        addSubview(backdrop)
        backdropTint.backgroundColor = .black
        backdropTint.alpha = 0
        backdropTint.isUserInteractionEnabled = false
        backdropTint.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backdrop.addSubview(backdropTint)
        panel.backgroundColor = DerPlayGlassPalette.sheetTint
        panel.layer.cornerRadius = 34
        panel.layer.cornerCurve = .continuous
        panel.clipsToBounds = true
        addSubview(panel)
        grabber.backgroundColor = .tertiaryLabel
        grabber.layer.cornerRadius = 2
        grabber.isUserInteractionEnabled = false
        panel.addSubview(grabber)
        button.translatesAutoresizingMaskIntoConstraints = true
        addSubview(button)
        // Keep the native button as the only interactive material surface.
        playbackContent.isUserInteractionEnabled = false
        playbackContent.accessibilityElementsHidden = true
        playbackContent.clipsToBounds = true
        playbackIcon.contentMode = .scaleAspectFit
        playbackIcon.tintColor = .white
        playbackTitle.font = .systemFont(ofSize: 22, weight: .semibold)
        playbackTitle.textColor = .white
        playbackTitle.textAlignment = .center
        playbackContent.addSubview(playbackIcon)
        playbackContent.addSubview(playbackTitle)
        button.addSubview(playbackContent)
        button.configuration?.imageColorTransformer = UIConfigurationColorTransformer { _ in .clear }
        button.configuration?.title = nil
        button.configurationUpdateHandler = { [weak self] button in
            self?.playbackContent.alpha = button.isEnabled ? (button.isHighlighted ? 0.75 : 1) : 0.45
        }
        updateButtonAppearance()
        for gesture in [buttonPan, headerPan] {
            gesture.delegate = self
            gesture.cancelsTouchesInView = true
        }
        button.addGestureRecognizer(buttonPan)
        panel.addGestureRecognizer(headerPan)
        panel.isHidden = true
        backdrop.isHidden = true
        button.accessibilityIdentifier = "derplay.connection.playback"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    var acceptsPlaybackTap: Bool { animator == nil && !dragging }
    var isExpandedOrMoving: Bool { targetOpen || progress > 0 || animator != nil || dragging }
    private var effectiveHeight: CGFloat {
        let maximum = max(1, bounds.height - safeAreaInsets.top - 8)
        return min(maximum, max(1, panelHeight > 0 ? panelHeight : maximum * 0.86))
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsLayout()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        reconcileSettledLayout()
    }
    // Also called after the root controller lays out the sibling home slot.
    func reconcileSettledLayout() {
        if animator != nil || dragging { pendingLayout = true; return }
        UIView.performWithoutAnimation {
            preparePanelGeometry()
            render(progress)
        }
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event), hit !== self else { return nil }
        return hit
    }
    func installContent(_ content: UIView) {
        panel.insertSubview(content, belowSubview: grabber)
        content.translatesAutoresizingMaskIntoConstraints = false
        let bottom = content.bottomAnchor.constraint(equalTo: panel.bottomAnchor)
        bottom.priority = UILayoutPriority(998)
        contentConstraints = [
            content.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            content.topAnchor.constraint(equalTo: panel.topAnchor, constant: 16),
            content.heightAnchor.constraint(greaterThanOrEqualToConstant: 0), bottom
        ]
        NSLayoutConstraint.activate(contentConstraints)
        // The keyboard can shrink the list, never change the shared motion geometry.
        // Activate only while settled open, so a panel below the screen is unconstrained.
        let limit = content.bottomAnchor.constraint(lessThanOrEqualTo: keyboardLayoutGuide.topAnchor)
        limit.priority = UILayoutPriority(999)
        keyboardLimit = limit
    }
    func uninstallContent(_ content: UIView) {
        keyboardLimit?.isActive = false
        keyboardLimit = nil
        NSLayoutConstraint.deactivate(contentConstraints)
        contentConstraints.removeAll()
        content.removeFromSuperview()
    }
    override func accessibilityPerformEscape() -> Bool {
        guard isExpandedOrMoving, canDrag?() != false, !dragging else { return false }
        setExpanded(false)
        return true
    }
    func updateButtonAppearance() {
        playbackTitle.text = active ? CWL("停止") : CWL("启动")
        playbackIcon.image = UIImage(systemName: active ? "stop.fill" : "play.fill",
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold))
        button.accessibilityLabel = active ? CWL("停止 CarPlay") : CWL("启动 CarPlay")
        // Model progress is already the destination during a property animation.
        // Do not overwrite in-flight foreground geometry on a network state update.
        if animator == nil { layoutPlaybackContent(progress) }
        else { pendingLayout = true }
    }
    private func layoutPlaybackContent(_ value: CGFloat) {
        let p = min(1, max(0, value))
        playbackContent.frame = button.bounds
        let width = playbackContent.bounds.width
        let height = playbackContent.bounds.height
        let titleWidth = min(playbackTitle.sizeThatFits(CGSize(width: width, height: height)).width,
                             max(0, width - 36))
        let iconSize = 24 - 4 * p
        let gap: CGFloat = 12
        let homeOffset = (titleWidth + gap) / 2
        playbackIcon.frame = CGRect(x: width / 2 - homeOffset * (1 - p) - iconSize / 2,
                                    y: (height - iconSize) / 2, width: iconSize, height: iconSize)
        playbackTitle.frame = CGRect(x: playbackIcon.frame.maxX + gap,
                                     y: 0, width: titleWidth, height: height)
        playbackTitle.alpha = 1 - p
    }
    private func captureGeometry() -> MotionGeometry? {
        guard let homeSlot, let window, homeSlot.window === window,
              homeSlot.bounds.width > 0, homeSlot.bounds.height > 0,
              bounds.width > 0, bounds.height > 0 else { return nil }
        let height = effectiveHeight
        let fallback = CGRect(x: bounds.width - safeAreaInsets.right - 16 - 44,
                              y: bounds.maxY - height + 20, width: 44, height: 44)
        var end = fallback
        if let slot = playbackSlot?(), slot.window === window {
            // Measure in panel coordinates, independent of its current animation position.
            let local = slot.convert(slot.bounds, to: panel)
            if local.width > 0, local.height > 0, local.midX.isFinite, local.midY.isFinite,
               panel.bounds.contains(CGPoint(x: local.midX, y: local.midY)) {
                end = CGRect(x: local.midX - 22, y: bounds.maxY - height + local.midY - 22,
                             width: 44, height: 44)
            }
        }
        return MotionGeometry(bounds: bounds, height: height,
            home: homeSlot.convert(homeSlot.bounds, to: self), end: end)
    }
    private func render(_ value: CGFloat) {
        progress = min(1, max(0, value))
        guard let geometry = motionGeometry ?? captureGeometry() else { return }
        let height = geometry.height
        let top = geometry.bounds.maxY - height * progress
        backdrop.frame = geometry.bounds
        backdropTint.frame = backdrop.bounds
        backdropTint.alpha = 0.24 * progress
        panel.frame = CGRect(x: 0, y: top, width: geometry.bounds.width, height: height)
        grabber.frame = CGRect(x: (panel.bounds.width - 40) / 2, y: 6, width: 40, height: 4)
        let home = geometry.home
        let end = geometry.end
        func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b-a)*progress }
        button.frame = CGRect(x: mix(home.minX, end.minX), y: mix(home.minY, end.minY), width: mix(home.width, end.width), height: mix(home.height, end.height))
        layoutPlaybackContent(progress)
    }
    private func preparePanelGeometry() {
        guard motionGeometry == nil else { return }
        // Establish the actual navigation bar layout before freezing motion endpoints.
        panel.frame = CGRect(x: 0, y: bounds.maxY - effectiveHeight * progress,
                             width: bounds.width, height: effectiveHeight)
        panel.setNeedsLayout()
        panel.layoutIfNeeded()
    }
    private func interrupt() {
        guard let animator else { return }
        // Sample once on interruption, never continuously track a separate animation.
        let y = panel.layer.presentation()?.frame.minY ?? panel.frame.minY
        let geometry = motionGeometry ?? captureGeometry()
        let current = geometry.map { ($0.bounds.maxY-y)/$0.height } ?? progress
        generation += 1
        animator.stopAnimation(true)
        self.animator = nil
        UIView.performWithoutAnimation { render(current) }
    }
    func setExpanded(_ open: Bool) {
        guard !dragging else { return }
        // A repeated request must not interrupt an in-flight transition to the same target.
        if animator != nil && targetOpen == open { return }
        interrupt()
        targetOpen = open
        keyboardLimit?.isActive = false
        if !open { endEditing(true) }
        accessibilityViewIsModal = true
        UIView.performWithoutAnimation {
            preparePanelGeometry()
            if motionGeometry == nil { motionGeometry = captureGeometry() }
            render(progress)
        }
        // A detached or not-yet-laid-out home slot cannot drive a transition.
        // Roll back the mounted panel instead of settling a visible modal offscreen.
        guard motionGeometry != nil else {
            targetOpen = false
            progress = 0
            panel.isHidden = true
            backdrop.isHidden = true
            accessibilityViewIsModal = false
            onClosed?()
            setNeedsLayout()
            return
        }
        panel.isHidden = false
        backdrop.isHidden = false
        generation += 1
        let ticket = generation
        let destination: CGFloat = open ? 1 : 0
        let finish = { [weak self] in
            guard let self, self.generation == ticket else { return }
            self.animator = nil
            self.motionGeometry = nil
            self.progress = destination
            UIView.performWithoutAnimation {
                self.preparePanelGeometry()
                self.render(destination)
                self.panel.isHidden = !open
                self.backdrop.isHidden = !open
            }
            self.accessibilityViewIsModal = open
            self.keyboardLimit?.isActive = open
            if self.pendingLayout { self.pendingLayout = false; self.setNeedsLayout() }
            if !open { self.onClosed?() }
        }
        if UIAccessibility.isReduceMotionEnabled || abs(progress-destination) < 0.001 {
            finish(); return
        }
        let spring = UIViewPropertyAnimator(duration: 0.42, dampingRatio: 0.88) { [weak self] in
            self?.render(destination)
        }
        animator = spring
        spring.addCompletion { _ in finish() }
        spring.startAnimation()
    }
    @objc private func closeFromBackdrop() {
        guard canDrag?() != false, !dragging else { return }
        setExpanded(false)
    }
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, canDrag?() != false, !dragging else { return false }
        let velocity = pan.velocity(in: self)
        guard abs(velocity.y) > abs(velocity.x) else { return false }
        // Allow reversal during an in-flight spring, not two simultaneous pans.
        if pan === buttonPan { return animator != nil || (isExpandedOrMoving ? velocity.y > 0 : velocity.y < 0) }
        // Restrict panel dragging to the header; the list retains native scrolling.
        return isExpandedOrMoving && (animator != nil || velocity.y > 0) && pan.location(in: panel).y <= 64
    }
    @objc private func drag(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard !dragging else { return }
            if !isExpandedOrMoving, onBeginOpening?() != true { return }
            dragReturnOpen = targetOpen
            interrupt()
            keyboardLimit?.isActive = false
            endEditing(true)
            accessibilityViewIsModal = true
            UIView.performWithoutAnimation {
                preparePanelGeometry()
                if motionGeometry == nil { motionGeometry = captureGeometry() }
                render(progress)
            }
            guard motionGeometry != nil else {
                setExpanded(false)
                return
            }
            panel.isHidden = false
            backdrop.isHidden = false
            dragOwner = gesture
            dragging = true
            dragStart = progress
            // Ignore movement consumed by recognition and by interrupting a spring.
            gesture.setTranslation(.zero, in: self)
        case .changed:
            guard dragging, dragOwner === gesture else { return }
            render(dragStart - gesture.translation(in: self).y/(motionGeometry?.height ?? effectiveHeight))
        case .ended, .cancelled, .failed:
            guard dragging, dragOwner === gesture else { return }
            dragOwner = nil
            dragging = false
            let velocity = gesture.velocity(in: self).y
            let open = gesture.state == .ended ? (progress - velocity * 0.18/(motionGeometry?.height ?? effectiveHeight) > 0.5) : dragReturnOpen
            setExpanded(open)
        default: break
        }
    }
}

final class DerPlayPreviewMark: UIView {
    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = .clear; isAccessibilityElement = false }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func draw(_ rect: CGRect) {
        let scale = min(bounds.width, bounds.height) / 80
        guard let c = UIGraphicsGetCurrentContext() else { return }
        c.saveGState(); defer { c.restoreGState() }
        c.translateBy(x: (bounds.width - 80 * scale) / 2, y: (bounds.height - 80 * scale) / 2)
        c.scaleBy(x: scale, y: scale)
        let ink = UIColor(white: 0.60, alpha: 1)
        ink.setStroke(); ink.setFill()
        let ring = UIBezierPath(arcCenter: CGPoint(x: 40, y: 40), radius: 27, startAngle: .pi / 4, endAngle: 7 * .pi / 4, clockwise: true)
        ring.lineWidth = 8; ring.lineCapStyle = .round; ring.stroke()
        let triangle = UIBezierPath(); triangle.move(to: CGPoint(x: 32, y: 22)); triangle.addLine(to: CGPoint(x: 62, y: 40)); triangle.addLine(to: CGPoint(x: 32, y: 58)); triangle.close(); triangle.fill()
    }
}

/// User-approved Dashboard illustration, not a captured CarPlay frame or device status.
/// Day and night artwork is separate; Dock placement is composed locally.
struct DerPlayAppearancePreview: View {
    let night: Bool
    var dock: DerPlayDockPosition = .automatic
    var legacyRight = false
    private let apps = ["DerPlayDashboardMaps", "DerPlayDashboardMusic", "DerPlayDashboardMessages"]
    private var ink: Color { night ? .white : Color(red: 0.12, green: 0.16, blue: 0.20) }
    private var dockTint: Color { night ? Color(red: 0.07, green: 0.10, blue: 0.15) : Color(red: 0.87, green: 0.91, blue: 0.95) }
    private var clock: some View {
        Text("9:41").font(.system(size: 9, weight: .semibold)).monospacedDigit()
    }
    private var launcher: some View {
        Image(systemName: "square.grid.3x3.fill").font(.system(size: 10))
    }
    private func dockItems(iconSize: CGFloat, horizontal: Bool = false) -> some View {
        Group {
            if horizontal { launcher } else { clock }
            Spacer(minLength: 2)
            ForEach(apps, id: \.self) { asset in
                Image(night ? asset + "Night" : asset).resizable().scaledToFit().frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Spacer(minLength: 2)
            }
            if horizontal { clock } else { launcher }
        }
    }
    private func dashboard(width: CGFloat, height: CGFloat) -> some View {
        // This is an illustration, not the live video surface. Fit all artwork
        // into the reserved area without cropping map labels or widget content.
        Image(night ? "DerPlayDashboardNight" : "DerPlayDashboardDay")
            .resizable()
            .frame(width: width, height: height)
            .clipped()
    }
    private func sideBar(width: CGFloat, height: CGFloat) -> some View {
        let iconSize = min(18, max(10, (height - 32) / 3))
        return VStack(spacing: 0) { dockItems(iconSize: iconSize) }
            .padding(.vertical, 3).frame(width: width, height: height)
            .background(dockTint)
    }
    var body: some View {
        GeometryReader { g in
            let width = max(0, g.size.width)
            let height = max(0, g.size.height)
            if dock == .bottom {
                let barHeight = min(height * 0.23, min(22, max(16, width * 0.06)))
                VStack(spacing: 0) {
                    dashboard(width: width, height: height - barHeight)
                    HStack(spacing: 4) {
                        dockItems(iconSize: max(0, min(16, barHeight - 4)), horizontal: true)
                    }
                    .padding(.horizontal, 10).frame(width: width, height: barHeight)
                    .background(dockTint)
                }
            } else {
                let barWidth = min(width * 0.15, 30)
                HStack(spacing: 0) {
                    if !dock.driverSide(legacy: legacyRight) { sideBar(width: barWidth, height: height) }
                    dashboard(width: width - barWidth, height: height)
                    if dock.driverSide(legacy: legacyRight) { sideBar(width: barWidth, height: height) }
                }
            }
        }
        .foregroundStyle(ink)
        .background(dockTint)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(ink.opacity(0.10), lineWidth: 1))
        .accessibilityLabel("CarPlay \(night ? "夜间" : "日间")外观，Dock \(dock.title)示意")
        .accessibilityElement(children: .ignore)
    }
}
