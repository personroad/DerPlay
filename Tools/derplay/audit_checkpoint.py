#!/usr/bin/env python3
"""Read-only audit of a private checkpoint against its supplied SHA256 manifest."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re


def audit(root):
    root = Path(root).resolve()
    manifest = root / 'MANIFEST.sha256'
    if manifest.is_symlink():
        raise ValueError('Manifest must not be a symlink')
    result = {key: [] for key in ('matched', 'mismatched', 'missing', 'unlisted')}
    seen = set()
    for number, line in enumerate(manifest.read_text(encoding='utf-8').splitlines(), 1):
        match = re.fullmatch(r'([0-9a-fA-F]{64})  (.+)', line)
        if not match:
            raise ValueError(f'Invalid manifest line {number}')
        expected, name = match.groups()
        path = PurePosixPath(name)
        if (path.is_absolute() or '\\' in name or ':' in name or name != path.as_posix()
                or any(part in ('..', '.') for part in path.parts) or name in seen
                or name == 'MANIFEST.sha256'):
            raise ValueError(f'Unsafe or duplicate manifest path at line {number}')
        seen.add(name)
        target = root / name
        if any(p.is_symlink() for p in [target, *target.parents] if p != root and p.is_relative_to(root)):
            raise ValueError(f'Symlink in manifest path: {name}')
        if not target.is_file():
            result['missing'].append(name)
            continue
        with target.open('rb') as stream:
            actual = hashlib.file_digest(stream, 'sha256').hexdigest()
        if actual == expected.lower():
            result['matched'].append(name)
        else:
            result['mismatched'].append({'path': name, 'expected': expected.lower(), 'actual': actual})
    if not seen:
        raise ValueError('Empty manifest')
    for target in sorted(root.rglob('*')):
        name = target.relative_to(root).as_posix()
        if target.is_symlink():
            raise ValueError(f'Symlink in checkpoint: {name}')
        if target.is_file() and name not in seen and name != 'MANIFEST.sha256':
            result['unlisted'].append(name)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', type=Path)
    args = parser.parse_args()
    try:
        result = audit(args.root)
    except (OSError, ValueError) as exc:
        parser.exit(2, f'Audit error: {exc}\n')
    print(json.dumps({'counts': {k: len(v) for k, v in result.items()},
                      'mismatched': result['mismatched'], 'missing': result['missing'],
                      'unlisted': result['unlisted']}, ensure_ascii=False, indent=2))
    return int(any(result[k] for k in ('mismatched', 'missing', 'unlisted')))


if __name__ == '__main__':
    raise SystemExit(main())
