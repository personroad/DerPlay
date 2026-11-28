"""Validate manually observed AirPlay trials; no inference from player telemetry."""
import argparse
import json
import math
import statistics
import sys


def finite(value):
    return type(value) in (int, float) and math.isfinite(value)


def analyze(data):
    if not isinstance(data, dict) or data.get('schema') != 1:
        raise ValueError('expected schema 1 object')
    trials = data.get('trials')
    if not isinstance(trials, list) or not trials:
        raise ValueError('trials must be a nonempty list')
    seen = set()
    results = []
    for trial in trials:
        if not isinstance(trial, dict):
            raise ValueError('trial must be an object')
        name = trial.get('id')
        if not isinstance(name, str) or not name.strip() or name in seen:
            raise ValueError('unique nonempty trial id required')
        seen.add(name)
        if trial.get('parked') is not True:
            raise ValueError('parked trial required: ' + name)
        for field in ('receiver', 'network', 'capture_reference'):
            if not isinstance(trial.get(field), str) or not trial[field].strip():
                raise ValueError('missing '+field+': '+name)
        fps = trial.get('capture_fps')
        if not finite(fps) or fps <= 0:
            raise ValueError('positive capture_fps required')
        samples = trial.get('samples')
        if not isinstance(samples, list) or not samples:
            raise ValueError('nonempty samples required')
        delays, offsets = [], []
        for sample in samples:
            if not isinstance(sample, dict):
                raise ValueError('sample must be an object')
            source, video = sample.get('source_frame'), sample.get('receiver_frame')
            if any(type(v) is not int or v < 0 for v in (source, video)) or video < source:
                raise ValueError('invalid source/receiver frame order')
            delays.append((video-source)*1000/fps)
            audio = sample.get('audio_frame')
            if audio is not None:
                if type(audio) is not int or audio < 0:
                    raise ValueError('invalid audio_frame')
                offsets.append((audio-video)*1000/fps)
        def stats(values):
            return dict(count=len(values), median_ms=statistics.median(values) if values else None,
                        min_ms=min(values) if values else None, max_ms=max(values) if values else None)
        results.append(dict(id=name, frame_period_ms=1000/fps, video_delay=stats(delays), audio_minus_video=stats(offsets)))
    return dict(schema=1, evidence='manual observations; not independently verified', trials=results)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('input')
    args = p.parse_args()
    try:
        with open(args.input, encoding='utf-8-sig') as f:
            result = analyze(json.load(f))
        print(json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False))
        return 0
    except (OSError, ValueError, OverflowError) as exc:
        print(str(exc), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
