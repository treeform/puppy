from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl

host = ("0.0.0.0", 443)

class ExecuteServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/connect":
            try:
                self.send_response(200)
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(bytes("test", "utf8"))
            except:
                pass

    def do_POST(self):
        if self.path == "/plain":
            content_len = int(self.headers.get("Content-Length"))
            post_body = self.rfile.read(content_len)
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()

            post_body = str(post_body.decode())
            print(post_body)

    def log_message(self, format, *args):
        pass

def start_server():
    server = HTTPServer(host, ExecuteServer)
    server.socket = ssl.wrap_socket(server.socket,
                                    server_side=True,
                                    certfile="tests/data/ssl.crt",
                                    keyfile="tests/data/ssl.key",
                                    ssl_version=ssl.PROTOCOL_TLS)

    print(f"Starting server, listening on port {host[1]}")
    server.serve_forever()

def main():
    start_server()

if __name__ == "__main__":
    main()
