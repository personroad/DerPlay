import UIKit

/// A pull-down choice with the subset of the UISegmentedControl API the app uses, so a setting can
/// switch from segments to a menu without touching the code that reads it.
final class ChoiceMenu: UIControl {
    private var items: [String]
    private var disabledItems = Set<Int>()
    private let button = UIButton(type: .system)
    var selectedSegmentIndex: Int = 0 { didSet { refresh() } }
    var numberOfSegments: Int { items.count }
    var selectedTitle: String { items.indices.contains(selectedSegmentIndex) ? items[selectedSegmentIndex] : "" }

    init(items: [String]) {
        self.items = items
        super.init(frame: .zero)
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "chevron.up.chevron.down",
                                      withConfiguration: UIImage.SymbolConfiguration(textStyle: .footnote, scale: .small))
        configuration.imagePlacement = .trailing; configuration.imagePadding = 4
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.baseForegroundColor = .secondaryLabel
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 0)
        button.configuration = configuration
        button.titleLabel?.numberOfLines = 1
        button.showsMenuAsPrimaryAction = true
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([button.leadingAnchor.constraint(equalTo: leadingAnchor), button.trailingAnchor.constraint(equalTo: trailingAnchor),
                                     button.topAnchor.constraint(equalTo: topAnchor), button.bottomAnchor.constraint(equalTo: bottomAnchor)])
        refresh()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func setTitle(_ title: String?, forSegmentAt index: Int) {
        guard items.indices.contains(index) else { return }
        items[index] = title ?? ""; refresh()
    }
    func setEnabled(_ enabled: Bool, forSegmentAt index: Int) {
        if enabled { disabledItems.remove(index) } else { disabledItems.insert(index) }
        refresh()
    }
    override var isEnabled: Bool { didSet { button.isEnabled = isEnabled } }
    override var intrinsicContentSize: CGSize {
        let measured = button.intrinsicContentSize
        guard let configuration = button.configuration else { return measured }
        let font = button.titleLabel?.font ?? .preferredFont(forTextStyle: .body)
        let titleWidth = (selectedTitle as NSString).size(withAttributes: [.font: font]).width
        let insets = configuration.contentInsets
        let imageWidth = configuration.image.map { $0.size.width + configuration.imagePadding } ?? 0
        let width = ceil(titleWidth + insets.leading + insets.trailing + imageWidth + 2)
        return CGSize(width: max(measured.width, width), height: measured.height)
    }
    override func sizeThatFits(_ size: CGSize) -> CGSize { intrinsicContentSize }

    private func refresh() {
        button.configuration?.title = selectedTitle
        button.menu = UIMenu(children: items.enumerated().map { index, title in
            UIAction(title: title, attributes: disabledItems.contains(index) ? .disabled : [],
                     state: index == selectedSegmentIndex ? .on : .off) { [weak self] _ in
                guard let self, self.selectedSegmentIndex != index else { return }
                self.selectedSegmentIndex = index
                self.sendActions(for: .valueChanged)
            }
        })
        invalidateIntrinsicContentSize()
        // As a table accessory view the frame is not managed by Auto Layout.
        if let superview { frame.size = intrinsicContentSize; superview.setNeedsLayout() }
    }
}

/// A status line whose text changes while a settings page is open; the page re-measures its row.
final class StatusLabel: UILabel {
    static let didChange = Notification.Name("CarWithinStatusLabelDidChange")
    override var text: String? {
        didSet { if text != oldValue { NotificationCenter.default.post(name: Self.didChange, object: self) } }
    }
}

/// Rounded, colored icon tiles in the style of the iOS Settings app.
enum SettingsIcon {
    private static var cache: [String: UIImage] = [:]
    static func image(_ symbol: String, _ color: UIColor, traits: UITraitCollection = .current) -> UIImage {
        if symbol == "DerPlayVehicleScooter" || symbol == "DerPlayVehicleCar" {
            let dark = traits.userInterfaceStyle == .dark
            let name = symbol == "DerPlayVehicleScooter"
                ? (dark ? "DerPlayVehicleScooterNight" : "DerPlayVehicleScooter")
                : (dark ? "DerPlayVehicleNight" : "DerPlayVehicleDay")
            if let artwork = UIImage(named: name) {
                let bounds = CGRect(x: 0, y: 0, width: 32, height: 32)
                let artworkFormat = UIGraphicsImageRendererFormat()
                artworkFormat.scale = max(1, traits.displayScale)
                return UIGraphicsImageRenderer(size: bounds.size, format: artworkFormat).image { _ in
                    UIBezierPath(roundedRect: bounds, cornerRadius: 8).addClip()
                    artwork.draw(in: bounds)
                }.withRenderingMode(.alwaysOriginal)
            }
        }
        if symbol.hasPrefix("DerPlayBrand"), let logo = UIImage(named: symbol) {
            let key = "brand|\(symbol)|\(traits.displayScale)"
            if let cached = cache[key] { return cached }
            let size = CGSize(width: 32, height: 32)
            let bounds = CGRect(origin: .zero, size: size)
            let outlined = ["DerPlayBrandZeeho", "DerPlayBrandCfmoto", "DerPlayBrandEasyConnection", "DerPlayBrandCarlink"].contains(symbol)
            let format = UIGraphicsImageRendererFormat()
            format.scale = max(1, traits.displayScale)
            let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                let shape = UIBezierPath(roundedRect: bounds, cornerRadius: 8)
                shape.addClip()
                (outlined ? UIColor.white : symbol == "DerPlayBrandNinebot" ? UIColor.black : symbol == "DerPlayBrandTailing" ? UIColor(red: 0.82, green: 0.09, blue: 0.13, alpha: 1) : UIColor(red: 0, green: 0.48, blue: 0.95, alpha: 1)).setFill()
                shape.fill()
                let scale = min(size.width / logo.size.width, size.height / logo.size.height)
                let fitted = CGSize(width: logo.size.width * scale, height: logo.size.height * scale)
                logo.draw(in: CGRect(x: (size.width - fitted.width) / 2, y: (size.height - fitted.height) / 2, width: fitted.width, height: fitted.height))
                if outlined {
                    UIColor(white: 0.82, alpha: 1).setStroke()
                    let border = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 7.5)
                    border.lineWidth = 1
                    border.stroke()
                }
            }.withRenderingMode(.alwaysOriginal)
            cache[key] = image
            return image
        }
        // Resolve dynamic colors before rendering/caching. Darken light tiles so
        // the white glyph remains legible, including after an appearance change.
        let resolved = color.resolvedColor(with: traits)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let fill: UIColor
        if resolved.getRed(&r, green: &g, blue: &b, alpha: &a) {
            func linear(_ value: CGFloat) -> CGFloat {
                value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            var scale: CGFloat = 1
            while 0.2126 * linear(r * scale) + 0.7152 * linear(g * scale) + 0.0722 * linear(b * scale) > 0.18 {
                scale *= 0.95
            }
            fill = UIColor(red: r * scale, green: g * scale, blue: b * scale, alpha: 1)
        } else {
            fill = UIColor(white: 0.42, alpha: 1)
        }
        let key = "\(symbol)|\(fill.description)|\(traits.displayScale)"
        if let cached = cache[key] { return cached }
        let size = CGSize(width: 32, height: 32)
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(1, traits.displayScale)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            fill.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8).fill()
            let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
            if let glyph = (UIImage(systemName: symbol, withConfiguration: configuration) ?? UIImage(systemName: "gearshape", withConfiguration: configuration))?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                let fitted = glyph.size.width > 22 ? CGSize(width: 22, height: glyph.size.height * 22 / glyph.size.width) : glyph.size
                glyph.draw(in: CGRect(x: (size.width - fitted.width) / 2, y: (size.height - fitted.height) / 2, width: fitted.width, height: fitted.height))
            }
        }
        let original = image.withRenderingMode(.alwaysOriginal)
        cache[key] = original
        return original
    }
}

struct SettingsRow {
    enum Kind {
        /// Opens another page.
        case page(() -> UIViewController)
        /// A switch, choice menu or other small control at the trailing edge.
        case control(UIView)
        /// A tappable row.
        case action(() -> Void)
        /// A full-width custom view (text field row, status text, log).
        case view(UIView)
        /// Read-only title and value.
        case info
    }
    var title: String
    var icon: (symbol: String, color: UIColor)?
    var detail: (() -> String?)?
    var kind: Kind
    var destructive = false
    var opensExternalLink = false
    var checked: (() -> Bool)?
    var onDelete: (() -> Void)?
    var subtitle: (() -> String?)?

    static func page(_ title: String, icon: (String, UIColor)? = nil, detail: (() -> String?)? = nil, _ make: @escaping () -> UIViewController) -> Self {
        SettingsRow(title: title, icon: icon, detail: detail, kind: .page(make))
    }
    static func control(_ title: String, icon: (String, UIColor)? = nil, _ control: UIView) -> Self {
        SettingsRow(title: title, icon: icon, kind: .control(control))
    }
    static func action(_ title: String, icon: (String, UIColor)? = nil, destructive: Bool = false, detail: (() -> String?)? = nil,
                       _ run: @escaping () -> Void) -> Self {
        SettingsRow(title: title, icon: icon, detail: detail, kind: .action(run), destructive: destructive)
    }
    static func externalLink(_ title: String, icon: (String, UIColor), detail: String? = nil, _ open: @escaping () -> Void) -> Self {
        SettingsRow(title: title, icon: icon, detail: { detail }, kind: .action(open), opensExternalLink: true)
    }
    static func view(_ view: UIView) -> Self { SettingsRow(title: "", kind: .view(view)) }
    static func info(_ title: String, _ value: String, icon: (String, UIColor)? = nil) -> Self { SettingsRow(title: title, icon: icon, detail: { value }, kind: .info) }

    static func guide(_ title: String, icon: (String, UIColor), _ description: String) -> Self {
        SettingsRow(title: title, icon: icon, kind: .info, subtitle: { description })
    }

    /// "Title ............ [text field]" as a full-width row.
    static func field(_ title: String, _ field: UITextField, placeholder: String? = nil, icon: (String, UIColor) = ("square.and.pencil", .systemBlue)) -> Self {
        let label = UILabel(); label.text = title
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        field.borderStyle = .none; field.textAlignment = .right; field.clearButtonMode = .whileEditing
        field.autocorrectionType = .no; field.autocapitalizationType = .none
        field.smartQuotesType = .no; field.smartDashesType = .no; field.spellCheckingType = .no
        field.accessibilityLabel = title
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        if let placeholder { field.placeholder = placeholder }
        field.textColor = .secondaryLabel
        let tile = UIImageView(image: SettingsIcon.image(icon.0, icon.1))
        tile.widthAnchor.constraint(equalToConstant: 32).isActive = true
        tile.heightAnchor.constraint(equalToConstant: 32).isActive = true
        let row = UIStackView(arrangedSubviews: [tile, label, field]); row.spacing = 12; row.alignment = .center
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true
        return .view(row)
    }
    /// Secondary text shown as its own row (live status lines).
    static func note(_ label: UILabel) -> Self {
        label.font = .preferredFont(forTextStyle: .footnote); label.textColor = .secondaryLabel; label.numberOfLines = 0
        return .view(label)
    }
}

struct SettingsSection {
    var header: String?
    var footer: String?
    var rows: [SettingsRow]
    var centered: Bool
    init(_ header: String?, footer: String? = nil, centered: Bool = false, _ rows: [SettingsRow]) {
        self.centered = centered
        self.header = header; self.footer = footer; self.rows = rows
    }
    init(footer: String?, _ rows: [SettingsRow]) { self.init(nil, footer: footer, rows) }
    init(_ rows: [SettingsRow]) { self.init(nil, footer: nil, rows) }
}

/// One settings page. Sections are rebuilt each time the page appears, so details stay current.
final class SettingsPageController: UITableViewController {
    private let build: () -> [SettingsSection]
    private var sections: [SettingsSection] = []
    private var cells: [IndexPath: UITableViewCell] = [:]
    private var reloadPending = false
    private var layoutPending = false
    var onAppear: (() -> Void)?
    var onLeave: (() -> Void)?

    init(title: String, build: @escaping () -> [SettingsSection]) {
        self.build = build
        super.init(style: .insetGrouped)
        self.title = title
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .interactive
        navigationItem.largeTitleDisplayMode = .never
        applyGlassSurface()
        NotificationCenter.default.addObserver(self, selector: #selector(statusChanged(_:)), name: StatusLabel.didChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(editingEnded(_:)), name: UITextField.textDidEndEditingNotification, object: nil)
    }
    private func applyGlassSurface() {
        if navigationController is DerPlayGlassNavigationController {
            tableView.backgroundColor = DerPlayGlassPalette.sheetTint
            tableView.backgroundView = nil
            tableView.clipsToBounds = true
            tableView.tintColor = DerPlayGlassPalette.accent
            tableView.contentInsetAdjustmentBehavior = .automatic
            edgesForExtendedLayout = []
            extendedLayoutIncludesOpaqueBars = false
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if isViewLoaded, previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle { reload() }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyGlassSurface()
        reload()
        onAppear?()
    }
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
        super.viewWillDisappear(animated)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onLeave?()
    }
    func reload() {
        // Reparenting shared fields mid-edit interrupts the cursor and marked text (e.g. Pinyin).
        guard !containsEditingField(tableView) else { reloadPending = true; return }
        reloadPending = false
        sections = build(); cells.removeAll()
        tableView.reloadData()
    }
    private func containsEditingField(_ view: UIView) -> Bool {
        if let field = view as? UITextField, field.isFirstResponder { return true }
        return view.subviews.contains { containsEditingField($0) }
    }
    @objc private func editingEnded(_ note: Notification) {
        guard let field = note.object as? UITextField, field.isDescendant(of: tableView) else { return }
        // Wait for focus to move to the next field before deciding whether it is safe to rebuild.
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.containsEditingField(self.tableView) else { return }
            if self.reloadPending { self.reload() }
            if self.layoutPending {
                self.layoutPending = false
                UIView.performWithoutAnimation { self.tableView.performBatchUpdates(nil) }
            }
        }
    }
    func refreshDetails() {
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            let row = sections[indexPath.section].rows[indexPath.row]
            guard let detail = row.subtitle ?? row.detail,
                  let cell = tableView.cellForRow(at: indexPath),
                  var content = cell.contentConfiguration as? UIListContentConfiguration else { continue }
            content.secondaryText = detail()
            cell.contentConfiguration = content
        }
    }
    @objc private func statusChanged(_ note: Notification) {
        guard let label = note.object as? UIView, label.isDescendant(of: tableView) else { return }
        guard !containsEditingField(tableView) else { layoutPending = true; return }
        UIView.performWithoutAnimation { tableView.performBatchUpdates(nil) }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].rows.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].header }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? { sections[section].footer }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].centered ? 46 : UITableView.automaticDimension
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard sections[section].centered, let title = sections[section].header else { return nil }
        let container = UIView()
        let label = UILabel()
        label.text = title
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if sections[section].footer == nil, sections.indices.contains(section + 1), sections[section + 1].centered { return .leastNormalMagnitude }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if sections[section].centered, let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textAlignment = .center
        }
    }
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if sections[section].centered, let footer = view as? UITableViewHeaderFooterView {
            footer.textLabel?.textAlignment = .center
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = cells[indexPath] { return cell }
        // Controls are shared objects owned by the main screen, so cells are never reused.
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        if navigationController is DerPlayGlassNavigationController {
            cell.backgroundColor = DerPlayGlassPalette.card
        }
        if case .view(let custom) = row.kind {
            custom.removeFromSuperview()
            custom.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(custom)
            let margins = cell.contentView.layoutMarginsGuide
            NSLayoutConstraint.activate([custom.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                custom.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                custom.topAnchor.constraint(equalTo: margins.topAnchor), custom.bottomAnchor.constraint(equalTo: margins.bottomAnchor)])
        } else {
            let subtitle = row.subtitle?()
            var content = subtitle == nil ? UIListContentConfiguration.valueCell() : UIListContentConfiguration.subtitleCell()
            content.text = row.title
            content.secondaryText = subtitle ?? row.detail?()
            if subtitle != nil {
                content.secondaryTextProperties.color = .secondaryLabel
                content.secondaryTextProperties.numberOfLines = 0
            }
            let fallback: (String, UIColor) = row.checked != nil ? ("checkmark.circle", .systemBlue) : ("gearshape", .systemGray)
            let icon = row.icon ?? fallback
            content.image = SettingsIcon.image(icon.0, icon.1, traits: tableView.traitCollection)
            if row.destructive { content.textProperties.color = .systemRed }
            switch row.kind {
            case .page:
                cell.accessoryType = .disclosureIndicator; cell.selectionStyle = .default
            case .control(let control):
                control.removeFromSuperview()
                control.translatesAutoresizingMaskIntoConstraints = true
                control.sizeToFit()
                cell.accessoryView = control
            case .action:
                cell.selectionStyle = .default
                if row.opensExternalLink {
                    let indicator = UIImageView(image: UIImage(systemName: "arrow.up.right"))
                    indicator.tintColor = .secondaryLabel
                    indicator.sizeToFit()
                    cell.accessoryView = indicator
                    cell.accessibilityHint = CWL("打开外部链接")
                }
                if !row.destructive, row.icon == nil, row.checked == nil { content.textProperties.color = .tintColor }
            case .view, .info:
                break
            }
            if let checked = row.checked { cell.accessoryType = checked() ? .checkmark : .none }
            cell.contentConfiguration = content
        }
        cells[indexPath] = cell
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row.kind {
        case .page(let make):
            view.endEditing(true)
            navigationController?.pushViewController(make(), animated: true)
        case .action(let run):
            view.endEditing(true)
            run()
            if row.checked != nil || row.detail != nil { reload() }
        default: break
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let delete = sections[indexPath.section].rows[indexPath.row].onDelete else { return nil }
        let configuration = UISwipeActionsConfiguration(actions: [UIContextualAction(style: .destructive, title: CWL("删除")) { [weak self] _, _, done in
            guard let self else { done(false); return }
            let title = self.sections[indexPath.section].rows[indexPath.row].title
            let confirmation = UIAlertController(title: CWL("删除“{1}”？", [String(describing: title)]), message: CWL("删除后无法撤销。"), preferredStyle: .alert)
            confirmation.addAction(UIAlertAction(title: CWL("取消"), style: .cancel) { _ in done(false) })
            confirmation.addAction(UIAlertAction(title: CWL("删除"), style: .destructive) { _ in
                delete(); self.reload(); done(true)
            })
            self.present(confirmation, animated: true)
        }])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}
