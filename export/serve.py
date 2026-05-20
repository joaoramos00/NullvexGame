#!/usr/bin/env python3
"""Serve the web export with the headers required for SharedArrayBuffer (Godot 4 web).
Run from the repo root: python export/serve.py
Then open http://localhost:8000/web/index.html
"""
import http.server
import socketserver

PORT = 8000

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="export", **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, format, *args):
        pass  # suppress per-request noise

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving at http://localhost:{PORT}/web/index.html")
    print("Press Ctrl+C to stop.")
    httpd.serve_forever()
