import http.server
import os

WEB_DIR = os.path.join(os.path.dirname(__file__), ".godot", "exported", "web")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, format, *args):
        pass  # silence logs

if __name__ == "__main__":
    with http.server.HTTPServer(("", 8080), Handler) as httpd:
        print("Serving at http://localhost:8080")
        httpd.serve_forever()
