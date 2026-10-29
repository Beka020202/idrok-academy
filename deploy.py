"""Render start command for Idrok Academy / Kodla.
Starts the API server and Flet web app in one service.
"""
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PORT = os.environ.get("PORT")
TEACHER_PASSWORD = os.environ.get("TEACHER_PASSWORD", "").strip()

if not PORT:
    print("ERROR: Render did not provide PORT.", flush=True)
    raise SystemExit(1)
if len(TEACHER_PASSWORD) < 12:
    print("ERROR: Set TEACHER_PASSWORD in Render Environment to a strong password (at least 12 characters).", flush=True)
    raise SystemExit(1)

# On Render, attach a persistent disk mounted at /var/data.
# The database is stored there so student progress survives redeploys.
os.environ.setdefault("KODLA_DB_PATH", "/var/data/kodla.db")

server = subprocess.Popen(
    [sys.executable, str(ROOT / "server.py"), "--port", "8765", "--teacher-password", TEACHER_PASSWORD],
    cwd=str(ROOT),
)
time.sleep(1.5)
if server.poll() is not None:
    raise SystemExit("Kodla API server failed to start; check the logs above.")

try:
    app = subprocess.Popen([sys.executable, str(ROOT / "main.py"), "--web"], cwd=str(ROOT))
    while True:
        if server.poll() is not None:
            print("API server stopped; shutting down web app.", flush=True)
            app.terminate()
            raise SystemExit(1)
        code = app.poll()
        if code is not None:
            server.terminate()
            raise SystemExit(code)
        time.sleep(1)
except KeyboardInterrupt:
    pass
finally:
    server.terminate()
