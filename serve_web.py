import http.server
import os
import json

WEB_DIR = os.path.join(os.path.dirname(__file__), "export", "web")
PROJECT_DIR = os.path.dirname(__file__)
HITBOX_JSON = os.path.join(PROJECT_DIR, "data", "hitbox_overrides.json")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self):
        if self.path.split("?")[0] == "/hitbox_overrides.json":
            try:
                with open(HITBOX_JSON, "rb") as f:
                    body = f.read()
            except OSError:
                body = b"{}"
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()

    def do_POST(self):
        if self.path.split("?")[0] != "/save-hitbox":
            self.send_response(404)
            self.end_headers()
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
        except ValueError:
            self.send_response(400); self.end_headers(); return
        try:
            with open(HITBOX_JSON, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (OSError, ValueError):
            data = {}
        data[payload["id"]] = payload["data"]
        os.makedirs(os.path.dirname(HITBOX_JSON), exist_ok=True)
        with open(HITBOX_JSON, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, format, *args):
        pass

if __name__ == "__main__":
    with http.server.ThreadingHTTPServer(("", 8080), Handler) as httpd:
        print("Serving at http://localhost:8080")
        httpd.serve_forever()
