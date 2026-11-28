import unittest
from airplay_measurement import analyze


def example():
    return {'schema':1,'trials':[{'id':'A','parked':True,'receiver':'test','network':'test','capture_reference':'synthetic','capture_fps':100,'samples':[{'source_frame':10,'receiver_frame':30,'audio_frame':28},{'source_frame':40,'receiver_frame':70}]}]}


class MeasurementTests(unittest.TestCase):
    def test_delays(self):
        r=analyze(example())['trials'][0]
        self.assertEqual(r['video_delay']['median_ms'],250)
        self.assertEqual(r['audio_minus_video']['median_ms'],-20)
        self.assertEqual(r['audio_minus_video']['count'],1)
    def test_missing_audio(self):
        d=example(); del d['trials'][0]['samples'][0]['audio_frame']
        self.assertIsNone(analyze(d)['trials'][0]['audio_minus_video']['median_ms'])
    def test_invalid_fps(self):
        for v in (0,-1,True,float('inf'),float('nan')):
            d=example(); d['trials'][0]['capture_fps']=v
            with self.assertRaises(ValueError): analyze(d)
    def test_parked_required(self):
        d=example(); d['trials'][0]['parked']=False
        with self.assertRaises(ValueError): analyze(d)
    def test_reverse_frames(self):
        d=example(); d['trials'][0]['samples'][0]['receiver_frame']=1
        with self.assertRaises(ValueError): analyze(d)
    def test_duplicate_trial(self):
        d=example(); d['trials']*=2
        with self.assertRaises(ValueError): analyze(d)
    def test_missing_reference(self):
        d=example(); del d['trials'][0]['capture_reference']
        with self.assertRaises(ValueError): analyze(d)
