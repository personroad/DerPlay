"""Offline playback-item epochs; never infer connection identity or causality."""
import argparse
import json
import sys
from analyze_airplay import analyze, summary


def segment(report):
    groups = []
    current = None
    for event in report['events']:
        kind = event['kind']
        if current is None or kind == 'item_installed':
            current = dict(start_boundary='item_installed' if kind == 'item_installed' else 'unobserved', events=[])
            groups.append(current)
        current['events'].append(event)
    for i, group in enumerate(groups):
        events = group.pop('events')
        first, last = events[0]['line'], events[-1]['line']
        buffers = [e for e in events if e['kind'] == 'buffer']
        memory = [e for e in events if e['kind'] == 'memory']
        group.update(index=i+1, first_line=first, last_line=last,
                     end_boundary='next_item_installed' if i+1 < len(groups) else 'unobserved',
                     event_counts={k: sum(e['kind']==k for e in events) for k in sorted({e['kind'] for e in events})},
                     buffer={k: summary([e[k] for e in buffers]) for k in ('ahead_s','local_edge_lag_s')},
                     memory={k: summary([e[k] for e in memory]) for k in ('retained_bytes','pending_bytes','segments','frames')},
                     retained_sample_delta_bytes=memory[-1]['retained_bytes']-memory[0]['retained_bytes'] if len(memory)>=2 else None,
                     recovery_lines=[e['line'] for e in events if e['kind'] in ('keyframe_recovery','item_recovery','recovery_exhausted')],
                     anomaly_lines=[e['line'] for e in events if e['kind'] in ('clock_stalled','source_idle','timeline_jump') or (e['kind']=='buffer' and e['empty'])])
    return dict(schema=1, boundary_kind='observed_playback_item_installation', connection_identity='unknown',
                malformed_lines=report['malformed_lines'], ignored_lines=report['ignored_lines'], epochs=groups)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('log', help='UTF-8 copied diagnostic log or - for stdin')
    args = p.parse_args()
    try:
        if args.log == '-':
            report = analyze(sys.stdin)
        else:
            with open(args.log, encoding='utf-8-sig') as f:
                report = analyze(f)
        print(json.dumps(segment(report), indent=2, ensure_ascii=False, allow_nan=False))
        return 1 if report['malformed_lines'] or not report['events'] else 0
    except (OSError, UnicodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
