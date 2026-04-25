from http.server import BaseHTTPRequestHandler, HTTPServer

VERSION = "v1"

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(f'{{"status":"ok", "message": "{VERSION}"}}'.encode())

    def log_message(self, format, *args):
        pass

HTTPServer(("0.0.0.0", 80), Handler).serve_forever()
