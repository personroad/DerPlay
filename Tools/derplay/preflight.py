#!/usr/bin/env python3
"""Read-only build gate; verifies files and metadata, not iOS runtime behavior."""
import json, pathlib, plistlib, re, sys
root = pathlib.Path(__file__).resolve().parents[2]
required = ['App/Info.plist','App/DerPlayIdentityDER.swift','App/DerPlayIdentityImport.swift','Tools/derplay/test_identity.py','App/DerPlayExtensionAPI.swift','App/DerPlayExtensionSession.swift','Tools/derplay/SessionSmoke.swift','Tools/derplay/verify_ipa.py','App/DerPlayUpstreamBridge.swift','App/ReceiverViewController.swift','DerPlay/Extensions/DisplayGeometry.swift','Tools/derplay/DisplayGeometrySmoke.swift','Tools/generate_project.py','TDSCarKit.xcodeproj/project.pbxproj','LICENSE','THIRD_PARTY_NOTICES.txt','README.md','docs/derplay/home-design.jpg','DerPlay/upstream.json','.github/workflows/build-ipa.yml','.github/workflows/upstream-sync.yml']
for name in required:
    if not (root/name).is_file(): sys.exit('Missing: '+name)
info=plistlib.loads((root/'App/Info.plist').read_bytes())
if info.get('CFBundleShortVersionString') != '0.0.1': sys.exit('Unexpected main version; user approval required')
if not re.fullmatch(r'[1-9][0-9]*', str(info.get('CFBundleVersion',''))): sys.exit('Build must be a positive integer')
if info.get('CFBundleDisplayName')!='DerPlay': sys.exit('Unexpected bundle display name')
if (root/'TDSCarKit.xcodeproj/project.pbxproj').read_text().count('PRODUCT_BUNDLE_IDENTIFIER = "com.derplay.app";') != 2: sys.exit('Unexpected Debug/Release Bundle ID')
if 'TDS_BUNDLE_IDENTIFIER: com.derplay.app' not in (root/'.github/workflows/build-ipa.yml').read_text(): sys.exit('Unexpected CI Bundle ID')
private_suffixes={'.p12','.p8','.pk8','.p7b','.cer','.pem','.key','.x963','.mobileprovision','.provisionprofile'}
for path in root.rglob('*'):
    rel=path.relative_to(root)
    if '.git' in rel.parts or not path.is_file(): continue
    if path.suffix.lower() in private_suffixes or 'BundledIdentity' in rel.parts or 'IdentityImport' in rel.parts:
        sys.exit('Credential-like file must be removed before CI: '+str(rel))
text=(root/'App/ReceiverViewController.swift').read_text()
order=re.search(r'static let menuOrder: \[Self\] = \[([^\]]+)\]',text)
expected=set('browser carLife airPlay ninebot43 ninebot ninebotSeven tailing zeeho zeehoSEPlus zeehoAE2 cfmoto5 cfmoto62'.split())
if not order or not expected.issubset(set(re.findall(r'\.(\w+)',order.group(1)))): sys.exit('Missing baseline upstream output mode; inspect upstream changes')
if 'HeadUnitOutput.menuOrder.map' not in text: sys.exit('Dashboard output menu no longer follows upstream')
print('Preflight PASS: required files, app metadata, credential-file guard, baseline output modes')
