#!/usr/bin/env python3
"""Check upstream or prepare a review branch; never publish or merge main."""
import argparse
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def git(*args, check=True):
    return subprocess.run(['git', *args], cwd=ROOT, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, check=check)


def out(*args):
    return git(*args).stdout.strip()


def ancestor(a, b):
    result = git('merge-base', '--is-ancestor', a, b, check=False)
    if result.returncode not in (0, 1):
        raise RuntimeError(result.stderr.strip())
    return result.returncode == 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['check', 'bootstrap', 'prepare'])
    parser.add_argument('--branch', help='New review branch; required for bootstrap/prepare')
    parser.add_argument('--confirm-zip-baseline', action='store_true',
                        help='Confirm current tree is derived from the recorded original ZIP')
    args = parser.parse_args()
    cfg = json.loads((ROOT / 'DerPlay/upstream.json').read_text())
    baseline = cfg['initial_commit']
    if not re.fullmatch(r'[0-9a-f]{40}', baseline):
        raise RuntimeError('Invalid baseline SHA')
    # Fetch to an isolated tracking ref; never pull or reset the working tree.
    print('Fetching upstream ...', flush=True)
    git('fetch', '--no-tags', cfg['url'],
        f"refs/heads/{cfg['branch']}:refs/remotes/carwithin/{cfg['branch']}")
    tip = out('rev-parse', f"refs/remotes/carwithin/{cfg['branch']}")
    if not ancestor(baseline, tip):
        raise RuntimeError('Recorded baseline is not an ancestor of upstream tip; inspect upstream history manually.')
    head = out('rev-parse', 'HEAD')
    linked = ancestor(baseline, head)
    print(f'Initial baseline: {baseline}\nDerPlay HEAD: {head}\nUpstream tip: {tip}\nHistory linked: {linked}')
    if args.action == 'check':
        base = out('merge-base', head, tip) if linked else baseline
        if not ancestor(baseline, base):
            raise RuntimeError('Unexpected merge base')
        print('New upstream commits:', out('rev-list', '--count', f'{base}..{tip}'))
        print(out('log', '--format=%h %s', '-n', '30', f'{base}..{tip}'))
        print(out('diff', '--stat', base, tip))
        return 0
    if not args.branch or not args.branch.startswith('sync/'):
        raise RuntimeError('A new sync/ review branch is required')
    git('check-ref-format', '--branch', args.branch)
    if out('status', '--porcelain'):
        raise RuntimeError('Working tree must be clean; commit or stash changes first')
    if args.action == 'bootstrap':
        if linked:
            raise RuntimeError('History already linked; use prepare')
        if not args.confirm_zip_baseline:
            raise RuntimeError('Review the original ZIP provenance before explicitly confirming baseline')
        if git('merge-base', head, baseline, check=False).returncode != 1:
            raise RuntimeError('Existing common history or merge-base error; inspect manually')
        git('switch', '-c', args.branch)
        # Record the verified ZIP's actual upstream parent without altering our existing tree.
        git('merge', '--allow-unrelated-histories', '-s', 'ours', '--no-ff',
            '-m', f'Link CarWithin ZIP baseline {baseline}', baseline)
        if out('rev-parse', 'HEAD^{tree}') != out('rev-parse', f'{head}^{{tree}}'):
            raise RuntimeError('Bootstrap unexpectedly changed source tree')
        print('Baseline linked; source tree unchanged. Merge this review branch with a merge commit.')
        return 0
    if not linked:
        raise RuntimeError('Bootstrap ZIP history before preparing updates')
    if ancestor(tip, head):
        print('Already up to date; no review branch created.')
        return 0
    base = out('merge-base', head, tip)
    print('Upstream changed files:\n' + out('diff', '--name-status', base, tip))
    git('switch', '-c', args.branch)
    result = git('merge', '--no-ff', '--no-edit', tip, check=False)
    print(result.stdout, result.stderr, sep='\n')
    if result.returncode:
        print('Merge stopped. Unresolved files:\n' + out('diff', '--name-only', '--diff-filter=U'))
        print('Review and resolve locally, then git merge --continue, or git merge --abort. Do not publish partial merge.')
        return 2
    print('Candidate created; inspect changes and run regression tests before merging.')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (RuntimeError, subprocess.CalledProcessError, OSError, ValueError) as exc:
        print(getattr(exc, 'stderr', None) or str(exc), file=sys.stderr)
        sys.exit(1)
