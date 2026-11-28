import unittest
from test_glass_ui import GLASS

class GlassHierarchyTests(unittest.TestCase):
    def test_dashboard_native_glass_has_no_extra_shadow(self):
        body = GLASS.split('@ViewBuilder var body: some View {', 1)[1].split('private var fallback:', 1)[0]
        native = body.split('if #available(iOS 26.0, macCatalyst 26.0, *) {', 1)[1].split('} else {', 1)[0]
        self.assertIn('rows.glassEffect(.regular, in: .rect(cornerRadius: 23))', native)
        self.assertNotIn('.shadow(', native)
    def test_dashboard_keeps_accessible_solid_and_legacy_material(self):
        self.assertIn('rows.background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 23))', GLASS)
        self.assertIn('rows.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 23))', GLASS)
