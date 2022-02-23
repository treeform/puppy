from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl

host = ("0.0.0.0",443)

class ExecuteServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/connect":
            self.connect_handler()

    def do_POST(self):
        if self.path == "/plain":
            self.plain_handler()

    def log_message(self, format, *args):
        pass
    
    ################ Start of GET handlers ################
    def connect_handler(self):
        global connections

        try:
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write("test")
        except:
            pass

        print(f"New connection received")
            
    
    ################ End of Get handlers ################

    ################ Start of POST handlers ################

    # for commands that just send a plain text, no need for error checking
    def plain_handler(self):
        content_len = int(self.headers.get("Content-Length"))
        post_body = self.rfile.read(content_len)
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        
        post_body = str(post_body.decode())
        print(post_body)


    
    ################ End of POST handlers ################

def start_execute_server():
    server = HTTPServer(host, ExecuteServer)
    server.socket = ssl.wrap_socket(server.socket,
                                     server_side=True,
                                     certfile="certs/ssl.crt",
                                     keyfile="certs/ssl.key",
                                     ssl_version=ssl.PROTOCOL_TLS)
    
    print(f"Starting server, listening on port {host[1]}")
    server.serve_forever()


        

def main():
    global SYSTEM_STATE
    start_execute_server()


if __name__ == "__main__":
    main()            
