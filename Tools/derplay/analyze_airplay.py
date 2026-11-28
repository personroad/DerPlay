"""Offline summary of R97–R100 AirPlay logs; never sends or changes playback."""
import argparse
import json
import math
import re
import statistics
import sys

NUM = r'(?:unknown|[0-9]+(?:\.[0-9]+)?)'
BOOL = r'(true|false)'
BUFFER = re.compile(r'empty='+BOOL+r' likelyToKeepUp='+BOOL+r' full='+BOOL+r' ahead≈('+NUM+r')s localSeekableEdgeLag=('+NUM+r')s')
MEMORY = re.compile(r'segments=([0-9]+) retained=([0-9]+)B pending=([0-9]+)B frames=([0-9]+) announced='+BOOL)
EVENTS = {
    'AirPlay local timeline jump: ': ('timeline_jump', r'(\w+) position=(-?[0-9]+(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)s'),
    'AirPlay player clock stalled >= 10s': ('clock_stalled', ''),
    'AirPlay player clock advanced or reset': ('clock_advanced_or_reset', ''),
    'AirPlay source idle >= 10s (not proof of disconnect)': ('source_idle', ''),
    'AirPlay source frames resumed': ('source_resumed', ''),
    'AirPlay buffering recovery attempt ': ('keyframe_recovery', r'([12])/2'),
    'AirPlay HLS item recovery attempt ': ('item_recovery', r'([12])/2; source frames are fresh'),
    'AirPlay HLS item recovery exhausted; waiting for manual retry': ('recovery_exhausted', ''),
    'AirPlay HLS item installed ': ('item_installed', r'\([^\r\n]*\); preferred forward buffer=3s'),
}


def number(s):
    if s == 'unknown':
        return None
    v = float(s)
    if not math.isfinite(v):
        raise ValueError('nonfinite sample')
    return v


def summary(values):
    known = [v for v in values if v is not None]
    return dict(samples=len(values), unknown=len(values)-len(known),
                min=min(known, default=None), median=statistics.median(known) if known else None,
                max=max(known, default=None))


def analyze(lines):
    events, malformed = [], []
    ignored = 0
    for line_no, line in enumerate(lines, 1):
        # Copied UI logs have localized timestamps; preserve order, not guessed wall time.
        _, marker, msg = line.rstrip('\r\n').partition('AirPlay ')
        if not marker:
            ignored += 1
            continue
        msg = marker + msg
        try:
            if msg.startswith('AirPlay buffer telemetry: '):
                m = BUFFER.fullmatch(msg.removeprefix('AirPlay buffer telemetry: '))
                if not m:
                    raise ValueError('buffer')
                a,b,c,d,e = m.groups()
                event = dict(kind='buffer', empty=a=='true', likely_to_keep_up=b=='true', full=c=='true', ahead_s=number(d), local_edge_lag_s=number(e))
            elif msg.startswith('AirPlay HLS memory: '):
                m = MEMORY.fullmatch(msg.removeprefix('AirPlay HLS memory: '))
                if not m:
                    raise ValueError('memory')
                a,b,c,d,e = m.groups()
                event = dict(kind='memory', segments=int(a), retained_bytes=int(b), pending_bytes=int(c), frames=int(d), announced=e=='true')
            else:
                event = None
                for prefix, (kind, pattern) in EVENTS.items():
                    if msg.startswith(prefix):
                        m = re.fullmatch(pattern, msg[len(prefix):])
                        if not m:
                            raise ValueError('event')
                        event = dict(kind=kind)
                        if kind == 'timeline_jump':
                            event.update(direction=m[1], position_s=number(m[2]))
                        elif kind in ('keyframe_recovery', 'item_recovery'):
                            event['attempt'] = int(m[1])
                        break
                if event is None:
                    ignored += 1
                    continue
            events.append(dict(line=line_no, **event))
        except (ValueError, OverflowError):
            malformed.append(line_no)
    buffers = [e for e in events if e['kind']=='buffer']
    memory = [e for e in events if e['kind']=='memory']
    counts = {kind: sum(e['kind']==kind for e in events) for kind in sorted({e['kind'] for e in events})}
    return dict(schema=1, ignored_lines=ignored, malformed_lines=malformed, event_counts=counts,
                buffer={k:summary([e[k] for e in buffers]) for k in ('ahead_s','local_edge_lag_s')},
                memory={k:summary([e[k] for e in memory]) for k in ('segments','retained_bytes','pending_bytes','frames')},
                events=events)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('log', help='UTF-8 copied diagnostic log, or - for stdin')
    args = p.parse_args()
    try:
        if args.log == '-':
            result = analyze(sys.stdin)
        else:
            with open(args.log, encoding='utf-8-sig') as f:
                result = analyze(f)
        print(json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False))
        return 1 if result['malformed_lines'] or not result['events'] else 0
    except (OSError, UnicodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
