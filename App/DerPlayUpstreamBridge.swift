// The only menu-facing bridge to DerPlay extension metadata.
import UIKit

enum DerPlayUpstreamBridge {
    static func extensionMenuItems() -> [UIMenuElement] {
        DerPlayExtensionRegistry.planned.map { descriptor in
            // No session routing is implemented yet. Fail closed even if metadata changes.
            return UIAction(title: descriptor.title + "（开发中）", identifier: UIAction.Identifier(rawValue: descriptor.id), attributes: .disabled) { _ in }
        }
    }
}
