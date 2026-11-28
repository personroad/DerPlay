"""Source guards for AirPlay observer retirement; not AVFoundation runtime tests."""
import unittest
from pathlib import Path
from test_glass_ui import method
C = (Path(__file__).resolve().parents[2] / 'App/ReceiverViewController.swift').read_text()

class R99AirPlayLifecycleTests(unittest.TestCase):
    def test_retire_observers_before_player_detach(self):
        for name, detach in [('stop', 'airPlayPlayer?.pause()'), ('startAirPlayTransport', 'previous?.pause()')]:
            body = method(C, name)
            for observer in ('airPlayItemObservation', 'airPlayRouteObservation', 'airPlayTimeObservation'):
                self.assertLess(body.index(observer + '?.invalidate()'), body.index(observer + ' = nil'))
                self.assertLess(body.index(observer + ' = nil'), body.index(detach))

    def test_replacement_weakly_captures_player_and_checks_identity(self):
        body = method(C, 'installAirPlayItem')
        self.assertLess(body.index('airPlayItemObservation?.invalidate()'), body.index('item.observe('))
        self.assertIn('item.observe(\\.status, options: [.new]) { [weak self, weak item, weak player]', body)
        self.assertIn('self.airPlayPlayer === player, player.currentItem === item', body)
        self.assertIn('item.preferredForwardBufferDuration = 3', body)
        self.assertNotIn('seek(to:', body)
        self.assertNotIn('AVPlayer()', body)
