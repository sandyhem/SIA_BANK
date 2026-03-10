#!/usr/bin/env python3
import argparse
import socket
import threading
import time


class RogueService(threading.Thread):
    def __init__(self, host: str, port: int, max_connections: int):
        super().__init__(daemon=True)
        self.host = host
        self.port = port
        self.max_connections = max_connections
        self.accepted = 0
        self._stop = threading.Event()

    def stop(self):
        self._stop.set()

    def run(self):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
            server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            server.bind((self.host, self.port))
            server.listen(256)
            server.settimeout(0.5)

            while not self._stop.is_set() and self.accepted < self.max_connections:
                try:
                    client, _addr = server.accept()
                except socket.timeout:
                    continue
                except OSError:
                    break

                with client:
                    self.accepted += 1
                    try:
                        client.settimeout(0.1)
                        _ = client.recv(32)
                        client.sendall(b"ok")
                    except OSError:
                        pass


def burst_connections(target_host: str, target_port: int, count: int, delay_ms: int):
    successful = 0
    for _ in range(count):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
                client.settimeout(0.4)
                client.connect((target_host, target_port))
                client.sendall(b"attack-probe")
                try:
                    _ = client.recv(8)
                except OSError:
                    pass
                successful += 1
        except OSError:
            pass

        if delay_ms > 0:
            time.sleep(delay_ms / 1000.0)

    return successful


def main():
    parser = argparse.ArgumentParser(description="Generate suspicious traffic for eBPF demo detection")
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind rogue service")
    parser.add_argument("--port", type=int, default=19090, help="Port to bind rogue service (mapped in attack demo policy)")
    parser.add_argument("--count", type=int, default=80, help="Number of burst connections")
    parser.add_argument("--delay-ms", type=int, default=2, help="Delay between connections")
    args = parser.parse_args()

    print("[attack-sim] Starting rogue service process")
    rogue = RogueService(args.host, args.port, max_connections=args.count)

    try:
        rogue.start()
        time.sleep(0.2)

        print(f"[attack-sim] Sending {args.count} rapid connections to {args.host}:{args.port}")
        successful = burst_connections(args.host, args.port, args.count, args.delay_ms)

        time.sleep(0.5)
        rogue.stop()
        rogue.join(timeout=1.5)

        print(f"[attack-sim] Completed. successful_connections={successful} accepted_by_rogue={rogue.accepted}")
        print("[attack-sim] Expected eBPF alerts: PROCESS_PORT_MISMATCH + UNAUTHORIZED_FLOW")
    except KeyboardInterrupt:
        rogue.stop()
        rogue.join(timeout=1.0)


if __name__ == "__main__":
    main()
