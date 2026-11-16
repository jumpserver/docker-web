import contextlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import re
import shutil
import socket
import ssl
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]


class EchoHeaders(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps(dict(self.headers)).encode()
        self.send_response(200)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


def free_port():
    with socket.socket() as listener:
        listener.bind(('127.0.0.1', 0))
        return listener.getsockname()[1]


@unittest.skipUnless(shutil.which('nginx') and shutil.which('openssl'), 'nginx and openssl required')
class ForwardedProtoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backend = ThreadingHTTPServer(('127.0.0.1', 0), EchoHeaders)
        cls.thread = threading.Thread(target=cls.backend.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.backend.shutdown()
        cls.backend.server_close()
        cls.thread.join()

    @contextlib.contextmanager
    def proxy(self, use_lb):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            http_port, https_port, inner_port = (free_port() for _ in range(3))
            subprocess.run([
                'openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1',
                '-subj', '/CN=localhost', '-addext', 'subjectAltName=DNS:localhost,IP:127.0.0.1',
                '-keyout', str(root / 'server.key'), '-out', str(root / 'server.crt'),
            ], check=True, capture_output=True)
            config = (ROOT / 'https_server.conf').read_text()
            config = config.replace('listen 80;', f'listen 127.0.0.1:{http_port};')
            config = config.replace('listen 443 ssl;', f'listen 127.0.0.1:{https_port} ssl;')
            config = config.replace('server web:8080;', f'server 127.0.0.1:{inner_port};')
            config = config.replace('cert/server.', f'{root}/server.')
            (root / 'servers.conf').write_text(config)
            # Execute the actual startup function; macOS sed needs an explicit backup suffix.
            script = (ROOT / 'init.sh').read_text().split('# helm-charts mount')[0]
            if sys.platform == 'darwin':
                script = script.replace('sed -i ', 'sed -i "" ')
            env = dict(os.environ)
            for name in ('USE_LB', 'USE_IPV6', 'SERVER_NAME', 'CLIENT_MAX_BODY_SIZE'):
                env.pop(name, None)
            if use_lb is not None:
                env['USE_LB'] = use_lb
            subprocess.run(['bash', '-c', script + '\nconfig_nginx "$1"', 'test', str(root / 'servers.conf')],
                           env=env, check=True, capture_output=True)
            mapping = re.search(r'    map \$http_x_forwarded_proto .*?\n    }',
                                (ROOT / 'nginx.conf').read_text(), re.S).group()
            core = (ROOT / 'includes/core.conf').read_text().replace(
                'http://core:8080', f'http://127.0.0.1:{self.backend.server_port}')
            (root / 'core.conf').write_text(core)
            (root / 'nginx.conf').write_text(f'''
daemon off;
pid {root}/nginx.pid;
error_log {root}/error.log;
events {{}}
http {{
    access_log off;
    {mapping}
    include {root}/servers.conf;
    server {{ listen 127.0.0.1:{inner_port}; include {root}/core.conf; }}
}}
''')
            command = ['nginx', '-p', str(root), '-c', str(root / 'nginx.conf')]
            subprocess.run(command + ['-t'], check=True, capture_output=True)
            process = subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            try:
                for _ in range(100):
                    try:
                        with socket.create_connection(('127.0.0.1', http_port), timeout=0.1):
                            break
                    except OSError:
                        if process.poll() is not None:
                            self.fail(process.stderr.read().decode())
                        time.sleep(0.05)
                else:
                    self.fail('nginx did not start')
                context = ssl.create_default_context(cafile=str(root / 'server.crt'))
                yield http_port, https_port, context
            finally:
                process.terminate()
                process.communicate(timeout=10)

    def test_protocol_survives_both_proxy_hops(self):
        for use_lb in (None, '1', '0', 'unexpected'):
            with self.subTest(use_lb=use_lb), self.proxy(use_lb) as (http_port, https_port, context):
                for scheme, port in (('http', http_port), ('https', https_port)):
                    for forwarded in (None, 'http', 'https', 'invalid'):
                        with self.subTest(scheme=scheme, forwarded=forwarded):
                            headers = {'Host': 'jumpserver.example.test:8443'}
                            if forwarded is not None:
                                headers['X-Forwarded-Proto'] = forwarded
                            request = Request(f'{scheme}://127.0.0.1:{port}/api/probe/', headers=headers)
                            with urlopen(request, context=context, timeout=5) as response:
                                received = json.load(response)
                            expected = forwarded if use_lb == '0' and forwarded in ('http', 'https') else scheme
                            self.assertEqual(received['X-Forwarded-Proto'], expected)
                            self.assertEqual(received['Host'], headers['Host'])


if __name__ == '__main__':
    unittest.main()
