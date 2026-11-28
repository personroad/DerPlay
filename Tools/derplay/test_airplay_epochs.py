import unittest
from analyze_airplay import analyze
from airplay_epochs import segment
from test_airplay_analysis import B, M

I = 'AirPlay HLS item installed (initial stream); preferred forward buffer=3s'
R = 'AirPlay HLS item installed (bounded recovery 1/2); preferred forward buffer=3s'
A = 'AirPlay HLS item recovery attempt 1/2; source frames are fresh'

class EpochTests(unittest.TestCase):
    def run_lines(self, lines):
        return segment(analyze(lines))

    def test_empty(self):
        self.assertEqual(self.run_lines([])['epochs'], [])

    def test_partial_prefix(self):
        r = self.run_lines([M,I,M])
        self.assertEqual([e['start_boundary'] for e in r['epochs']], ['unobserved','item_installed'])
        self.assertEqual(r['connection_identity'], 'unknown')

    def test_recovery_boundary(self):
        e = self.run_lines([I,A,R])['epochs']
        self.assertEqual(e[0]['recovery_lines'], [2])
        self.assertEqual(e[1]['recovery_lines'], [])
        self.assertEqual(e[0]['end_boundary'], 'next_item_installed')
        self.assertEqual(e[1]['end_boundary'], 'unobserved')

    def test_memory_delta(self):
        e = self.run_lines([I,M,M.replace('1024B','2048B'),R,M])['epochs']
        self.assertEqual(e[0]['retained_sample_delta_bytes'],1024)
        self.assertIsNone(e[1]['retained_sample_delta_bytes'])

    def test_unknown_and_empty(self):
        e = self.run_lines([I,B.format('unknown','unknown').replace('empty=false','empty=true')])['epochs'][0]
        self.assertEqual(e['anomaly_lines'],[2])
        self.assertIsNone(e['buffer']['ahead_s']['max'])

    def test_malformed_boundary(self):
        r = self.run_lines([I,R+' corrupt',M])
        self.assertEqual(r['malformed_lines'],[2])
        self.assertEqual(len(r['epochs']),1)

    def test_consecutive_installs(self):
        e = self.run_lines([I,R])['epochs']
        self.assertEqual([(x['first_line'],x['last_line']) for x in e],[(1,1),(2,2)])
