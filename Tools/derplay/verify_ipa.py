#!/usr/bin/env python3
"""Verify the unsigned IPA identity and executable, without extracting it."""
import argparse, json, pathlib, plistlib, re, struct, zipfile


def verify(path, expected_version="0.0.1", expected_build=None):
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError('Corrupt IPA archive')
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate archive members')
        roots = [name for name in names if name.startswith('Payload/') and name.count('/') == 2 and name.endswith('.app/Info.plist')]
        if len(roots) != 1:
            raise ValueError('Expected exactly one root application')
        info = plistlib.loads(archive.read(roots[0]))
        expected = {'CFBundleIdentifier': 'com.derplay.app', 'CFBundleDisplayName': 'DerPlay', 'CFBundlePackageType': 'APPL'}
        for key, value in expected.items():
            if info.get(key) != value:
                raise ValueError(f'{key}: expected {value}, got {info.get(key)}')
        if info.get('CFBundleShortVersionString') != expected_version:
            raise ValueError('Unexpected main version')
        build = info.get('CFBundleVersion')
        if not isinstance(build, str) or not re.fullmatch(r'[1-9][0-9]*', build):
            raise ValueError('Invalid build number')
        if expected_build is not None and build != expected_build:
            raise ValueError('Unexpected build number')
        executable = info['CFBundleExecutable']
        if not executable or '/' in executable or '\\' in executable:
            raise ValueError('Invalid executable name')
        with archive.open(roots[0].rsplit('/', 1)[0] + '/' + executable) as stream:
            header = stream.read(32)
        if len(header) != 32 or struct.unpack_from('<II', header) != (0xfeedfacf, 0x0100000c):
            raise ValueError('Expected thin ARM64 Mach-O executable')
        return {**{key: info[key] for key in expected}, 'version': info.get('CFBundleShortVersionString'), 'build': info.get('CFBundleVersion'), 'minimumOS': info.get('MinimumOSVersion'), 'architecture': 'arm64', 'runtimeVerified': False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('ipa', type=pathlib.Path)
    parser.add_argument('--report', type=pathlib.Path)
    parser.add_argument('--source-plist', type=pathlib.Path)
    args = parser.parse_args()
    source = plistlib.loads(args.source_plist.read_bytes()) if args.source_plist else {} 
    result = json.dumps(verify(args.ipa, expected_build=source.get('CFBundleVersion')), indent=2, ensure_ascii=False)
    if args.report:
        args.report.write_text(result + '\n', encoding='utf-8')
    print(result)
