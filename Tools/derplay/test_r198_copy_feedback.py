import hashlib,json,unittest
from test_glass_ui import ROOT,GLASS,CONTROLLER,method
class CopyFeedback(unittest.TestCase):
    def test_plain_row(self):
        row=GLASS.split('let label = state.browserCopyAddressLabel',1)[1].split('if state.showsAirPlayPicker',1)[0]
        for token in ['Text(state.browserAddressCopied ? CWL("访问地址已复制") : label)', '.underline(false)', '.buttonStyle(.plain)', '.foregroundStyle(.secondary)', 'copyBrowserAddress(address)']:
            self.assertIn(token,row)
    def test_feedback_and_reset(self):
        body=method(CONTROLLER,'copyBrowserAccessAddress')
        for token in ['guard glassDashboardState.browserCopyAddress == address', 'UIPasteboard.general.string = address','browserAddressCopied = true','UIAccessibility.post(notification: .announcement', '.now() + 1.5','self.browserCopyFeedbackGeneration == generation','browserAddressCopied = false']:
            self.assertIn(token,body)
        refresh=method(CONTROLLER,'refreshDashboardStatus')
        self.assertIn('browserCopyFeedbackGeneration = UUID()',refresh)
        self.assertIn('glassDashboardState.browserAddressCopied = false',refresh)
    def test_localization_and_previous_lock(self):
        cat=json.loads((ROOT/'App/Localization/Localizable.xcstrings').read_text())['strings']
        self.assertEqual(cat['访问地址已复制']['localizations']['en']['stringUnit']['value'],'Access address copied')
        old=(ROOT/'DerPlay/R197-candidate-lock.json').read_bytes();new=json.loads((ROOT/'DerPlay/R198-candidate-lock.json').read_text())
        self.assertEqual(new['previous_lock_sha256'],hashlib.sha256(old).hexdigest())
        for name,entry in json.loads(old)['files'].items():
            self.assertEqual(new['files'][name].get('r197_sha256',new['files'][name]['candidate_sha256']),entry['candidate_sha256'])
