import pathlib, subprocess, tempfile, unittest, shutil
ROOT = pathlib.Path(__file__).resolve().parents[2]
class AirPlayHTTPTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('swiftc'), 'Swift unavailable')
    def test_response_bytes(self):
        source = (ROOT/'App/VideoOutputServer.swift').read_text().split('struct AirPlayHTTPReply {',1)[1]
        smoke = r'''
let resource = (type: "video/mp4", body: Data([1,2,3,4]))
func check(_ method: String, _ range: String?, _ code: Int, _ body: [UInt8], _ missing: Bool = false) {
    let reply = AirPlayHTTPReply.make(method: method, range: range, resource: missing ? nil : resource)
    let split = reply.data.range(of: Data("\r\n\r\n".utf8))!
    precondition(reply.code == code)
    precondition(Array(reply.data[split.upperBound...]) == body)
}
check("GET", nil, 200, [1,2,3,4])
check("HEAD", "bytes=1-2", 200, [])
check("GET", "bytes=1-2", 206, [2,3])
check("GET", "bytes=2-", 206, [3,4])
check("GET", "bytes=-2", 206, [3,4])
check("GET", "bytes=3-99", 206, [4])
check("GET", "bytes=4-", 416, [])
check("GET", "bytes=0-1,2-3", 200, [1,2,3,4])
check("HEAD", nil, 404, [], true)
'''
        with tempfile.TemporaryDirectory() as tmp:
            p=pathlib.Path(tmp)/'main.swift'; p.write_text('import Foundation\nstruct AirPlayHTTPReply {'+source+smoke)
            exe=pathlib.Path(tmp)/'smoke'; subprocess.run(['swiftc',str(p),'-o',str(exe)],check=True,timeout=30); subprocess.run([str(exe)],check=True,timeout=10)

    def test_response_lifecycle_source(self):
        source = (ROOT/'App/VideoOutputServer.swift').read_text()
        self.assertIn('client.mode = .airPlayResponse', source)
        self.assertIn('self.generation == run, self.clients[client.id] != nil', source)
        self.assertIn('complete && client.mode != .airPlayResponse', source)
        self.assertIn('case .request, .airPlayResponse:', source)
        self.assertIn('clients.values.filter { $0.mode == .raw || $0.mode == .webSocket }.count', source)
        stop = source.split('private func stopOnQueue()', 1)[1].split('private func report', 1)[0]
        for token in ('generation = UUID()', 'hls = nil', 'client.connection.cancel()', 'clients.removeAll()', 'hlsKeyframeTimer?.cancel()'):
            self.assertIn(token, stop)
