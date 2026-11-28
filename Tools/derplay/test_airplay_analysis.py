import unittest
from analyze_airplay import analyze

B = 'AirPlay buffer telemetry: empty=false likelyToKeepUp=true full=false ahead≈{}s localSeekableEdgeLag={}s'
M = 'AirPlay HLS memory: segments=18 retained=1024B pending=512B frames=2 announced=true'

class AirPlayAnalysisTests(unittest.TestCase):
    def test_localized_prefix_and_order(self):
        r = analyze(['下午11:59:59  '+B.format('1.5','unknown'), '00:00:01  '+M])
        self.assertEqual([e['kind'] for e in r['events']], ['buffer','memory'])
        self.assertEqual(r['buffer']['local_edge_lag_s']['unknown'], 1)
        self.assertIsNone(r['buffer']['local_edge_lag_s']['median'])
    def test_statistics(self):
        r = analyze([B.format('0.0','4.0'), B.format('2.0','6.0'), B.format('unknown','unknown'), M])
        self.assertEqual(r['buffer']['ahead_s'], dict(samples=3,unknown=1,min=0,median=1,max=2))
        self.assertEqual(r['memory']['retained_bytes']['max'],1024)
    def test_recovery_sequence(self):
        r = analyze(['AirPlay player clock stalled >= 10s','AirPlay buffering recovery attempt 1/2','AirPlay HLS item recovery attempt 2/2; source frames are fresh','AirPlay HLS item installed (bounded recovery 2/2); preferred forward buffer=3s','AirPlay player clock advanced or reset'])
        self.assertEqual(len(r['events']),5)
        self.assertEqual(r['events'][2]['attempt'],2)
    def test_invalid_and_unrelated(self):
        r = analyze(['unrelated private data',B.format('NaN','1.0'),M+' bad','AirPlay source frames resumed'])
        self.assertEqual(r['malformed_lines'],[2,3])
        self.assertEqual(r['ignored_lines'],1)
        self.assertNotIn('private',str(r))
    def test_empty(self):
        r = analyze([])
        self.assertEqual(r['events'],[])
        self.assertIsNone(r['memory']['segments']['max'])
    def test_jump(self):
        r = analyze(['AirPlay local timeline jump: backward position=1e-05s'])
        self.assertEqual(r['events'][0]['position_s'],1e-5)
    def test_source_and_exhausted(self):
        r = analyze(['AirPlay source idle >= 10s (not proof of disconnect)','AirPlay HLS item recovery exhausted; waiting for manual retry'])
        self.assertEqual(r['event_counts'],{'source_idle':1,'recovery_exhausted':1})
