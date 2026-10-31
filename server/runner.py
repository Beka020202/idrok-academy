"""Kodla Python ishga tushirgichi — o‘quvchi kodini alohida, cheklangan jarayonda bajaradi.
Запуск кода учеников в отдельном ограниченном процессе.

Ikki xil ishlatiladi / Два способа использования:
    1) Alohida xizmat (Render uchun tavsiya etiladi) / отдельный сервис (рекомендуется для Render):
           python runner.py            # PORT muhit o‘zgaruvchisidan yoki 8766
    2) server.py ichida /api/run sifatida (sinf Wi‑Fi tarmog‘i uchun).
       Внутри server.py как /api/run (для сети класса).

Himoya / Защита:
    - har bir kod yangi Python jarayonida, bo‘sh vaqtinchalik papkada ishlaydi;
      каждый запуск — новый процесс Python в пустой временной папке;
    - muhit o‘zgaruvchilari (parollar) uzatilmaydi / переменные окружения (пароли) не передаются;
    - vaqt, protsessor, xotira va fayl hajmi cheklangan (Linux/macOS);
      ограничены время, процессор, память и размер файлов (Linux/macOS);
    - natija hajmi cheklangan / объём вывода ограничен.
Eng xavfsiz yo‘l: runner.py ni parol va ma’lumotlar bazasi YO‘Q alohida serverda ishlatish.
Самое безопасное: запускать runner.py на отдельном сервере БЕЗ паролей и базы данных.
"""

import json
import os
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TIMEOUT = 3.0              # soniya / секунд
MAX_CODE = 20_000          # belgi / символов
MAX_OUTPUT = 20_000        # belgi / символов
MAX_INPUTS = 200
MEMORY_MB = 512
MAX_PARALLEL = int(os.environ.get("RUNNER_PARALLEL", "4"))
RUNS_PER_MINUTE = 40       # bitta IP uchun / на один IP

# Bola jarayonida ishlaydigan kod / код, который выполняется в дочернем процессе.
HARNESS = r'''
import sys, json, builtins as _b
try:
    import resource as _r
    _r.setrlimit(_r.RLIMIT_CPU, (%(cpu)d, %(cpu)d + 1))
    for _lim, _v in ((getattr(_r, "RLIMIT_AS", None), %(mem)d), (_r.RLIMIT_FSIZE, 1048576), (_r.RLIMIT_NOFILE, 64)):
        if _lim is not None:
            try:
                _r.setrlimit(_lim, (_v, _v))
            except (ValueError, OSError):
                pass
    del _r, _lim, _v
except ImportError:
    pass
data = json.loads(sys.stdin.buffer.read().decode("utf-8"))
code = data.get("code", "")
feed = iter(data.get("inputs") or [])
LIMIT = %(limit)d
out = []
size = [0]

class _OutputLimit(Exception):
    pass

def _w(s):
    out.append(s)
    size[0] += len(s)
    if size[0] > LIMIT:
        raise _OutputLimit()

def _print(*args, sep=" ", end="\n", **_):
    _w(str(sep).join(str(a) for a in args) + str(end))

def _input(prompt=""):
    _w(str(prompt))
    try:
        value = next(feed)
    except StopIteration:
        value = "Ali"
    _w(value + "\n")
    return value

ALLOWED = ("abs all any bool chr dict divmod enumerate filter float format frozenset hex int isinstance "
           "issubclass iter len list map max min next oct ord pow range repr reversed round set slice "
           "sorted str sum tuple type zip object super __build_class__ Exception ValueError TypeError IndexError "
           "KeyError ZeroDivisionError StopIteration NameError ArithmeticError").split()
SAFE_MODULES = {"math", "random", "string", "itertools", "collections", "statistics", "fractions", "decimal"}

def _safe_import(name, globals=None, locals=None, fromlist=(), level=0):
    if level or name.split(".")[0] not in SAFE_MODULES:
        raise ImportError("'%%s' moduli ruxsat etilmagan / модуль '%%s' не разрешён" %% (name, name))
    return __import__(name, globals, locals, fromlist, level)

safe = {n: getattr(_b, n) for n in ALLOWED}
safe.update(print=_print, input=_input, __import__=_safe_import)
err = None
try:
    exec(compile(code, "<kod>", "exec"), {"__name__": "__main__", "__builtins__": safe})
except _OutputLimit:
    err = "OutputLimit: natija juda uzun / слишком длинный вывод"
except MemoryError:
    err = "MemoryError"
except RecursionError as e:
    err = "RecursionError: %%s" %% e
except BaseException as e:
    err = "%%s: %%s" %% (type(e).__name__, e)
sys.__stdout__.write(json.dumps({"out": "".join(out)[:LIMIT], "err": err}))
sys.__stdout__.flush()
''' % {"limit": MAX_OUTPUT, "cpu": int(TIMEOUT) + 1, "mem": MEMORY_MB * 1024 * 1024}


def run_code(code, inputs=None, timeout=TIMEOUT):
    """Kodni bajaradi. Qaytaradi: (natija, xato|None). xato: "timeout" yoki xato matni.
    Выполняет код. Возвращает: (вывод, ошибка|None)."""
    code = str(code or "")
    if len(code) > MAX_CODE:
        return "", "Kod juda uzun / код слишком длинный"
    inputs = [str(x)[:1000] for x in (inputs or [])][:MAX_INPUTS]
    payload = json.dumps({"code": code, "inputs": inputs}).encode("utf-8")
    with tempfile.TemporaryDirectory(prefix="kodla-run-") as tmp:
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin")}
        if os.name == "nt":  # Windows uchun zarur / нужно для Windows
            env["SYSTEMROOT"] = os.environ.get("SYSTEMROOT", "C:\\Windows")
        proc = subprocess.Popen(
            [sys.executable, "-I", "-S", "-B", "-c", HARNESS],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            cwd=tmp, env=env, start_new_session=(os.name != "nt"),
        )
        try:
            raw, _ = proc.communicate(payload, timeout=timeout + 1.5)
        except subprocess.TimeoutExpired:
            _kill(proc)
            return "", "timeout"
    try:
        data = json.loads(raw.decode("utf-8", "replace"))
        return str(data.get("out", ""))[:MAX_OUTPUT], (data.get("err") or None)
    except (ValueError, AttributeError):
        # CPU chegarasi (SIGXCPU) yoki xotira tugashi / лимит CPU или памяти
        if proc.returncode is not None and proc.returncode < 0:
            return "", "timeout"
        return "", "MemoryError"


def _kill(proc):
    try:
        if os.name != "nt":
            os.killpg(proc.pid, 9)
        else:
            proc.kill()
    except (OSError, ProcessLookupError):
        try:
            proc.kill()
        except OSError:
            pass
    try:
        proc.communicate(timeout=2)
    except (subprocess.TimeoutExpired, ValueError, OSError):
        pass


# ---------------------------------------------------------------- navbat va cheklov / очередь и лимиты
_slots = threading.BoundedSemaphore(MAX_PARALLEL)
_rate_lock = threading.Lock()
_rate = {}


def allowed(ip):
    """Bitta IP daqiqasiga RUNS_PER_MINUTE martadan ko‘p ishlata olmaydi."""
    now = time.time()
    with _rate_lock:
        hits = [t for t in _rate.get(ip, []) if now - t < 60]
        if len(hits) >= RUNS_PER_MINUTE:
            _rate[ip] = hits
            return False
        hits.append(now)
        _rate[ip] = hits
        if len(_rate) > 5000:  # eski yozuvlarni tozalash / чистим старые записи
            for k in [k for k, v in _rate.items() if not v or now - v[-1] > 60]:
                _rate.pop(k, None)
        return True


def handle_run(data, ip):
    """/api/run so‘rovi: (status, javob) / запрос /api/run: (статус, ответ)."""
    if not isinstance(data, dict):
        return 400, {"error": "bad_json"}
    if not allowed(ip):
        return 503, {"error": "busy"}
    if not _slots.acquire(timeout=8):
        return 503, {"error": "busy"}
    try:
        inputs = data.get("inputs") or []
        out, err = run_code(data.get("code", ""), inputs if isinstance(inputs, list) else [])
    finally:
        _slots.release()
    return 200, {"out": out, "err": err}


def client_ip(handler):
    fwd = handler.headers.get("X-Forwarded-For", "")
    return fwd.split(",")[0].strip() or handler.client_address[0]


# ---------------------------------------------------------------- alohida xizmat / отдельный сервис
class RunnerHandler(BaseHTTPRequestHandler):
    server_version = "KodlaRunner/1.0"

    def log_message(self, fmt, *args):
        pass  # o‘quvchi kodini logga yozmaymiz / не пишем код учеников в лог

    def send_json(self, status, data):
        body = json.dumps(data, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.split("?")[0] in ("/", "/api/ping"):
            return self.send_json(200, {"ok": True, "app": "kodla-runner"})
        return self.send_json(404, {"error": "not_found"})

    def do_POST(self):
        if self.path.split("?")[0] != "/api/run":
            return self.send_json(404, {"error": "not_found"})
        length = int(self.headers.get("Content-Length") or 0)
        if length > 100_000:
            return self.send_json(413, {"error": "too_big"})
        try:
            data = json.loads(self.rfile.read(length) or b"{}")
        except ValueError:
            return self.send_json(400, {"error": "bad_json"})
        status, res = handle_run(data, client_ip(self))
        return self.send_json(status, res)


def main():
    port = int(os.environ.get("PORT", "8766"))
    print(f"Kodla runner: http://0.0.0.0:{port}  (POST /api/run)", flush=True)
    ThreadingHTTPServer(("0.0.0.0", port), RunnerHandler).serve_forever()


if __name__ == "__main__":
    main()
