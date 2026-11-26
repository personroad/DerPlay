// DerPlay presentation layer. No transport, credentials or session ownership.
import UIKit
import SwiftUI
import AVKit

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
    static func shadow(_ view: UIView, radius: CGFloat = 16, offset: CGFloat = 8) {
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = view.traitCollection.userInterfaceStyle == .dark ? 0.65 : 0.32
        view.layer.shadowRadius = radius
        view.layer.shadowOffset = CGSize(width: 0, height: offset)
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
    case system, light, dark
    static let defaultsKey = "derplay.softwareAppearance"
    var title: String {
        switch self { case .system: return "跟随系统"; case .light: return "日间"; case .dark: return "夜间" }
    }
    var symbol: String {
        switch self { case .system: return "circle.lefthalf.filled"; case .light: return "sun.max"; case .dark: return "moon.stars" }
    }
    var style: UIUserInterfaceStyle {
        switch self { case .system: return .unspecified; case .light: return .light; case .dark: return .dark }
    }
    static func saved(in defaults: UserDefaults = .standard) -> Self {
        Self(rawValue: defaults.string(forKey: defaultsKey) ?? "") ?? .system
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
    @Published var showsAirPlayPicker = false
    @Published var airPlayPickerReady = false
}

// Host the existing native route picker; never create a parallel discovery or playback session.
@MainActor private struct DerPlayHomeAirPlayPicker: UIViewRepresentable {
    let picker: AVRoutePickerView
    func makeUIView(context: Context) -> AVRoutePickerView { picker }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

@MainActor struct DerPlayGlassDashboard: View {
    @ObservedObject var state: DerPlayGlassDashboardState
    let settings: () -> Void
    let modes: () -> Void
    let connection: () -> Void
    let airPlayPicker: AVRoutePickerView
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private func menuRow(_ title: String, symbol: String, value: String = "", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: symbol).font(.body).frame(width: 22)
                Text(title).font(.subheadline)
                Spacer(minLength: 6)
                if !value.isEmpty { Text(value).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.trailing) }
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            .frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    private var rows: some View {
        VStack(spacing: 0) {
            menuRow("软件设置", symbol: "gearshape", action: settings)
            Divider()
            menuRow("互联方式", symbol: "car", value: state.mode, action: modes)
                .accessibilityHint(state.locked ? "运行中，仅可查看互联方式" : "选择互联方式")
            Divider()
            menuRow("连接设置", symbol: "slider.horizontal.3", action: connection)
            if !state.statusLines.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(state.statusLines.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.footnote).foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.padding(.vertical, 12)
            }
            if state.showsAirPlayPicker {
                Divider()
                HStack(spacing: 12) {
                    Text("选择 AirPlay 设备").font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityHidden(true)
                    DerPlayHomeAirPlayPicker(picker: airPlayPicker)
                        .frame(width: 44, height: 44)
                        .allowsHitTesting(state.airPlayPickerReady)
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
                rows.glassEffect(.clear, in: .rect(cornerRadius: 23))
                    .shadow(color: .black.opacity(scheme == .dark ? 0.60 : 0.25), radius: 20, x: 0, y: 12)
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

// A native navigation stack hosted inside ONE system sheet. Keep legacy page lifecycles,
// controls, alerts, file pickers, keyboard and callbacks intact.
final class DerPlayGlassNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    var onClose: (() -> Void)?
    private var contentHeight: CGFloat = 0
    private var lastResolvedHeight: CGFloat?
    private var heightLocked = false
    private var detentUpdatePending = false

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
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
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
            installClose(on: topViewController)
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
    }
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // Keep the same sheet position for every push, pop and interactive back.
        // Do not reset the height even after returning to the root.
        if viewController !== viewControllers.first { heightLocked = true }
        applySharedAppearance(to: viewController)
        installClose(on: viewController)
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
    private func glassButton(symbol: String, label: String, action: @escaping () -> Void) -> UIBarButtonItem {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .capsule
        configuration.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        configuration.baseForegroundColor = .label
        configuration.baseBackgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(white: 0.28, alpha: 1) : UIColor(white: 0.98, alpha: 1)
        }
        configuration.background.strokeColor = UIColor { traits in
            UIColor.white.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.20 : 0.85)
        }
        configuration.background.strokeWidth = 0.8
        let button = UIButton(configuration: configuration, primaryAction: UIAction { _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        })
        button.accessibilityLabel = label
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 44), button.heightAnchor.constraint(equalToConstant: 44)])
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.12
        button.layer.shadowRadius = 3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.configurationUpdateHandler = { button in
            UIView.animate(withDuration: 0.15) { button.transform = button.isHighlighted ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity }
        }
        return UIBarButtonItem(customView: button)
    }
    private func installBack(on page: UIViewController) {
        guard page !== viewControllers.first, page.navigationItem.leftBarButtonItem == nil else { return }
        page.navigationItem.leftBarButtonItem = glassButton(symbol: "chevron.backward", label: "返回") { [weak self] in
            self?.popViewController(animated: true)
        }
    }
    private func installClose(on viewController: UIViewController) {
        // Preserve any page-specific trailing actions; install exactly one global close.
        let items = viewController.navigationItem.rightBarButtonItems ?? []
        if !items.contains(where: { $0.accessibilityIdentifier == "derplay.close.settings" }) {
            let close = glassButton(symbol: "xmark", label: "关闭设置") { [weak self] in self?.onClose?() }
            close.accessibilityIdentifier = "derplay.close.settings"
            close.accessibilityLabel = "关闭设置"
            viewController.navigationItem.rightBarButtonItems = [close] + items
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

/// A schematic, not a captured CarPlay frame or device status.
struct DerPlayAppearancePreview: View {
    let night: Bool
    var dock: DerPlayDockPosition = .automatic
    var legacyRight = false
    private let apps = [("phone.fill", "电话", Color.green), ("music.note", "音乐", Color.pink), ("location.fill", "地图", Color.blue), ("message.fill", "信息", Color.green), ("play.fill", "正在播放", Color.pink), ("car.fill", "车辆", Color.gray), ("waveform", "播客", Color.purple), ("gearshape.fill", "设置", Color.gray)]
    private var dockItems: some View {
        Group {
            Text("9:41").font(.system(size: 10, weight: .semibold))
            Spacer(minLength: 3)
            ForEach([0, 1, 2], id: \.self) { i in
                Image(systemName: apps[i].0).font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 21, height: 21).background(apps[i].2, in: RoundedRectangle(cornerRadius: 6))
                Spacer(minLength: 3)
            }
            Image(systemName: "square.grid.3x3.fill").font(.system(size: 12))
        }
    }
    private func appGrid(size: CGSize) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 4), spacing: dock == .bottom ? 4 : 9) {
            ForEach(apps.indices, id: \.self) { i in
                VStack(spacing: 3) {
                    Image(systemName: apps[i].0).font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: min(dock == .bottom ? 26 : 34, size.width * 0.12), height: min(dock == .bottom ? 26 : 34, size.width * 0.12))
                        .background(apps[i].2, in: RoundedRectangle(cornerRadius: 9))
                    Text(apps[i].1).font(.system(size: 8)).lineLimit(1).minimumScaleFactor(0.5)
                }
            }
        }.padding(6).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private func sideBar(width: CGFloat) -> some View {
        VStack(spacing: 0) { dockItems }.padding(.vertical, 10).frame(width: width * 0.15)
            .background(night ? Color.black.opacity(0.27) : Color.white.opacity(0.30))
    }
    var body: some View {
        GeometryReader { g in
            Group {
                if dock == .bottom {
                    VStack(spacing: 0) {
                        appGrid(size: g.size)
                        HStack(spacing: 4) { dockItems }.padding(.horizontal, 12).frame(height: 32)
                            .background(night ? Color.black.opacity(0.27) : Color.white.opacity(0.30))
                    }
                } else {
                    HStack(spacing: 0) {
                        if !dock.driverSide(legacy: legacyRight) { sideBar(width: g.size.width) }
                        appGrid(size: g.size)
                        if dock.driverSide(legacy: legacyRight) { sideBar(width: g.size.width) }
                    }
                }
            }
            .foregroundStyle(night ? Color.white : Color(red: 0.15, green: 0.22, blue: 0.26))
            .background(LinearGradient(colors: night ? [Color(red: 0.20, green: 0.32, blue: 0.45), Color(red: 0.06, green: 0.10, blue: 0.16)] : [Color(red: 0.72, green: 0.84, blue: 0.91), Color(red: 0.77, green: 0.87, blue: 0.79)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.black, lineWidth: 4))
        }
        .accessibilityLabel("CarPlay \(night ? "夜间" : "日间")外观，Dock \(dock.title)示意")
        .accessibilityElement(children: .ignore)
    }
}
