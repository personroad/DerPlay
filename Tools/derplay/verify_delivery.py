#!/usr/bin/env python3
"""Offline verification of DerPlay consolidated delivery ZIPs; never deploys."""
import argparse
import hashlib
import io
import plistlib
import re
import zipfile
from pathlib import PurePosixPath

PRIVATE_NAMES = {'AGENTS.md', 'AI_HANDOVER.md', 'AI_TAKEOVER_PROMPT.md', 'AI_USAGE_GUIDE.md', 'CONVERSATION_LOG.md', 'DECISIONS.md', 'DESIGN_SPEC.md', 'DEVELOPMENT_STATUS.md', 'PROJECT_REQUIREMENTS.md', 'DERPLAY_BUILD_GUIDE.md'}
PRIVATE_DIRS = {'DELIVERY', 'TEST_REPORTS', 'DESIGN_ASSETS', '.git', '__pycache__'}


def files(z):
    names = z.namelist()
    seen = set()
    for n in names:
        p = PurePosixPath(n)
        key = n.rstrip('/').casefold()
        if (not n or p.is_absolute() or '..' in p.parts or '\\' in n or ':' in n or key in seen):
            raise ValueError(f'unsafe or duplicate archive path: {n}')
        seen.add(key)
    bad = z.testzip()
    if bad:
        raise ValueError(f'ZIP CRC failure: {bad}')
    return {n for n in names if not n.endswith('/')}


def check_manifest(z, expected):
    actual = {}
    for line in z.read('SHA256.txt').decode('utf-8-sig').splitlines():
        match = re.fullmatch(r'([0-9a-fA-F]{64})  (.+)', line)
        if not match:
            raise ValueError('invalid SHA256 manifest line')
        digest, name = match.groups()
        if name in actual or name not in expected:
            raise ValueError(f'unexpected or duplicate manifest entry: {name}')
        actual[name] = digest.lower()
    if set(actual) != expected:
        raise ValueError('incomplete SHA256 manifest')
    for name, digest in actual.items():
        with z.open(name) as f:
            if hashlib.file_digest(f, 'sha256').hexdigest() != digest:
                raise ValueError(f'SHA256 mismatch: {name}')


def one(names, pattern):
    found = [n for n in names if re.fullmatch(pattern, n)]
    if len(found) != 1:
        raise ValueError(f'expected exactly one entry matching {pattern}')
    return found[0]


def verify(path):
    with zipfile.ZipFile(path) as outer:
        names = files(outer)
        deploy = one(names, r'DerPlay-build\d+-R\d+-all-in-one\.zip')
        stem = deploy.removesuffix('-all-in-one.zip')
        private, logs = stem+'-private.zip', stem+'-test-logs.zip'
        required = {deploy, private, logs, 'SHA256.txt', 'README-交付说明.txt'}
        if names != required:
            raise ValueError('unexpected or missing outer delivery files')
        check_manifest(outer, {deploy, private, logs})
        build, revision = re.search(r'build(\d+)-R(\d+)$', stem).groups()
        with zipfile.ZipFile(io.BytesIO(outer.read(deploy))) as d:
            dn = files(d)
            source = one(dn, rf'DerPlay-0\.0\.1-build{build}-R{revision}-source\.zip')
            if dn != {source, 'deploy.cmd', 'deploy.sh', 'README.txt', 'SHA256.txt'}:
                raise ValueError('unexpected or missing public deployment files')
            check_manifest(d, dn-{'SHA256.txt'})
            with zipfile.ZipFile(io.BytesIO(d.read(source))) as s, zipfile.ZipFile(io.BytesIO(outer.read(private))) as p:
                sn, pn = files(s), files(p)
                for n in sn:
                    parts = PurePosixPath(n).parts
                    if parts[-1] in PRIVATE_NAMES or set(parts) & PRIVATE_DIRS:
                        raise ValueError(f'private path in public source: {n}')
                prefix = one(pn, r'[^/]+/App/Info\.plist').removesuffix('App/Info.plist')
                for n in ('App/Info.plist', 'LICENSE', 'Package.swift'):
                    if n not in sn or prefix+n not in pn:
                        raise ValueError(f'missing required source file: {n}')
                plist = plistlib.loads(s.read('App/Info.plist'))
                if str(plist['CFBundleVersion']) != build:
                    raise ValueError('build number mismatch')
                roots = ('App/', 'Sources/', '.github/', 'TDSCarKit.xcodeproj/')
                runtime = {n for n in sn if n.startswith(roots)}
                private_runtime = {n[len(prefix):] for n in pn if n.startswith(prefix) and n[len(prefix):].startswith(roots)}
                if runtime != private_runtime:
                    raise ValueError('public/private runtime file sets differ')
                for n in sorted(runtime):
                    if s.read(n) != p.read(prefix+n):
                        raise ValueError(f'public/private runtime mismatch: {n}')
                for n in PRIVATE_NAMES:
                    if prefix+n not in pn:
                        raise ValueError(f'missing private handover document: {n}')
        with zipfile.ZipFile(io.BytesIO(outer.read(logs))) as l:
            ln = files(l)
            if not any(n.endswith('.log') for n in ln):
                raise ValueError('test log archive has no logs')
        return f'PASS: {stem}; outer/inner SHA256, ZIP CRC, public/private runtime ({len(runtime)} files), Build {build}, handover and test logs'


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive')
    args = parser.parse_args()
    try:
        print(verify(args.archive))
    except (ValueError, KeyError, OSError, zipfile.BadZipFile) as e:
        parser.exit(1, f'FAIL: {e}\n')
