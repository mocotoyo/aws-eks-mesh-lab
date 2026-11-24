from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json, os, socket
class Handler(BaseHTTPRequestHandler):
    def respond(self, status=200):
        body=json.dumps({'servicio':'cuentas','version':os.getenv('VERSION','v1'),'pod':socket.gethostname()}).encode()
        self.send_response(status)
        self.send_header('Content-Type','application/json')
        self.send_header('Content-Length',str(len(body)))
        self.end_headers(); self.wfile.write(body)
    def do_GET(self): self.respond()
    def do_POST(self): self.respond(201)
if __name__=='__main__': ThreadingHTTPServer(('0.0.0.0',8080),Handler).serve_forever()
