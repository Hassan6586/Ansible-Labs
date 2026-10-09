#!/usr/bin/env python3
"""A tiny web app for Lab 12: counts visits in Redis.

Uses only the Python standard library plus the redis client (python3-redis).
"""
import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

import redis

APP_NAME = os.environ.get("APP_NAME", "visit-counter")
PORT = int(os.environ.get("APP_PORT", "8000"))
store = redis.Redis(
    host=os.environ.get("REDIS_HOST", "127.0.0.1"),
    port=int(os.environ.get("REDIS_PORT", "6379")),
    socket_connect_timeout=2,
)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            try:
                store.ping()
                self.reply(200, "ok", "text/plain")
            except redis.RedisError:
                self.reply(503, "redis unavailable", "text/plain")
            return

        try:
            visits = store.incr("visits")
        except redis.RedisError:
            self.reply(503, "<h1>Database unavailable</h1>", "text/html")
            return

        body = (
            f"<h1>{APP_NAME}</h1>"
            f"<p>Visits: {visits}</p>"
            f"<p>App server: {socket.gethostname()}</p>"
        )
        self.reply(200, body, "text/html")

    def reply(self, status, body, content_type):
        data = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", f"{content_type}; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):  # quieter logs
        pass


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
