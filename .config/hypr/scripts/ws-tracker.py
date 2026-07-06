#!/usr/bin/env python3
import socket, os, sys, time, json

STATE_FILE = os.path.expanduser("~/.local/state/noctalia/user-active-ws")
OPEN_FILE  = os.path.expanduser("~/.local/state/noctalia/user-open-ws")
os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)

uid       = os.getuid()
hypr_base = f"/run/user/{uid}/hypr/"

sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
if not sig:
    try:
        entries = [e for e in os.listdir(hypr_base) if os.path.isdir(hypr_base + e)]
        if entries:
            sig = entries[0]
    except Exception:
        pass

if not sig:
    print("HYPRLAND_INSTANCE_SIGNATURE nicht gefunden", file=sys.stderr)
    sys.exit(1)

socket_path = f"{hypr_base}{sig}/.socket2.sock"
ctl_socket  = f"{hypr_base}{sig}/.socket.sock"

def ctl(cmd):
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(1.0)
        s.connect(ctl_socket)
        s.sendall(cmd.encode())
        data = b""
        try:
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    break
                data += chunk
        except socket.timeout:
            pass
        s.close()
        return json.loads(data.decode())
    except Exception as e:
        print(f"ctl error ({cmd}): {e}", file=sys.stderr)
        return None

def write(path, content):
    try:
        with open(path, "w") as f:
            f.write(content)
    except Exception as e:
        print(f"Write error: {e}", file=sys.stderr)

def refresh():
    active = ctl("j/activeworkspace")
    if active:
        write(STATE_FILE, str(active.get("id", 0)))

    ws_data = ctl("j/workspaces")
    if ws_data:
        ids = sorted(set(w["id"] for w in ws_data if w.get("windows", 0) > 0))
        write(OPEN_FILE, ",".join(str(i) for i in ids))
        print(f"active={active.get('id') if active else '?'} open={ids}", flush=True)

refresh()

while True:
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(socket_path)
        print(f"Connected: {socket_path}", flush=True)
        buf = b""
        while True:
            data = s.recv(4096)
            if not data:
                break
            buf += data
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                line = line.decode("utf-8", errors="ignore").strip()
                if any(line.startswith(e) for e in ("workspace>>", "openwindow>>", "closewindow>>", "movewindow>>")):
                    refresh()
        s.close()
    except Exception as e:
        print(f"Socket error: {e}", file=sys.stderr)
        time.sleep(2)
