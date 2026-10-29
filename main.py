"""Kodla — o‘ynab dasturlashni o‘rganish (Python + Flet).
Kodla — учимся программировать, играя (Python + Flet).

Ishga tushirish / Запуск:
    python server.py          # 1-oyna: server / окно 1: сервер
    python main.py            # 2-oyna: ilova shu kompyuterda / окно 2: приложение на этом ПК
    python main.py --web      # telefonlar uchun brauzer rejimi / режим браузера для телефонов
"""

import json
import os
import random
import sys
import threading
import urllib.error
import urllib.request
from datetime import date

import flet as ft

from lessons import ALL_LESSONS, COURSES, PLAYGROUND_START, T, run_python
from progress import (AVATARS, GOAL, QUESTS, buy_avatar, claim_quest, complete_lesson, empty_state,
                      last_week, level_of, normalize, open_chest, quest_progress)

WEB_PORT = int(os.environ.get("PORT", "8550"))
DEFAULT_SERVER = "http://127.0.0.1:8765"
PREFS_KEY = "kodla.prefs"

# ---------------------------------------------------------------- ranglar / цвета
LIGHT = {
    "bg": "#EEF4FC", "surface": "#FFFFFF", "surface2": "#E3ECF9", "line": "#CFDDF2",
    "ink": "#0C1F45", "muted": "#5A6E93", "blue": "#1650E0", "deep": "#0B2F8A", "sky": "#3FA2FF",
    "ice": "#D7E8FF", "good": "#12925A", "good_bg": "#DDF5E9", "bad": "#D23A3A", "bad_bg": "#FBE3E3",
    "gold": "#E89A00", "gold_bg": "#FFF1CC", "code_bg": "#0B1B3D", "code_fg": "#D9E7FF",
    "hero1": "#1A5BF0", "hero2": "#0A2C86", "on_hero": "#FFFFFF", "hero_soft": "#C9DBFF",
}
DARK = {
    "bg": "#060E24", "surface": "#0E1C44", "surface2": "#152857", "line": "#22407E",
    "ink": "#E8EFFF", "muted": "#93A8D3", "blue": "#4C86FF", "deep": "#2A55C8", "sky": "#5DB4FF",
    "ice": "#1B3474", "good": "#3DD08C", "good_bg": "#0E3A2A", "bad": "#FF7A7A", "bad_bg": "#45191F",
    "gold": "#FFC93C", "gold_bg": "#3A2E0A", "code_bg": "#030A1C", "code_fg": "#D9E7FF",
    "hero1": "#2A5DE0", "hero2": "#0B1A50", "on_hero": "#FFFFFF", "hero_soft": "#B8CBFF",
}
MONO = "JetBrainsMono"
DISPLAY = "Unbounded"
W8 = ft.FontWeight.W_800
W7 = ft.FontWeight.W_700
W6 = ft.FontWeight.W_600


# ---------------------------------------------------------------- server bilan aloqa / связь с сервером
class ApiError(Exception):
    def __init__(self, code):
        super().__init__(code)
        self.code = code  # "conn" | "auth" | "taken" | "short" | ...


class Api:
    def __init__(self, base, token=None):
        self.base = base.rstrip("/")
        self.token = token

    def call(self, path, data=None):
        headers = {"Content-Type": "application/json"}
        if self.token:
            headers["Authorization"] = "Bearer " + self.token
        body = None if data is None else json.dumps(data).encode()
        req = urllib.request.Request(self.base + path, data=body, headers=headers,
                                     method="GET" if data is None else "POST")
        try:
            with urllib.request.urlopen(req, timeout=6) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            try:
                raise ApiError(json.loads(e.read()).get("error", "error"))
            except (ValueError, AttributeError):
                raise ApiError("error")
        except (urllib.error.URLError, OSError, ValueError):
            raise ApiError("conn")


# ---------------------------------------------------------------- ilova / приложение
class Kodla:
    def __init__(self, page: ft.Page):
        self.page = page
        self.prefs = {"lang": "uz", "theme": "light", "server": DEFAULT_SERVER, "token": "",
                      "mode": "", "offline_state": {}, "course": "html", "name": ""}
        self.load_prefs()
        self.tab = "home"
        self.ls = None
        self.user = None            # serverdagi foydalanuvchi / пользователь сервера
        self.st = normalize(self.prefs.get("offline_state") or {})
        self.api = Api(self.prefs["server"], self.prefs["token"] or None)
        self.auth_mode = "login"
        self.auth_error = ""
        self.rank_rows, self.rank_error = None, ""
        self.teacher_rows, self.teacher_error = None, ""
        self.confirm_reset = False
        self.play_code, self.play_inputs, self.play_out = PLAYGROUND_START, "5", ""
        self.setup_page()
        self.boot()

    # ------------------------------------------------------------ sozlamalar / настройки
    def load_prefs(self):
        try:
            raw = self.page.client_storage.get(PREFS_KEY)
            if raw:
                self.prefs.update(json.loads(raw))
        except Exception:
            pass

    def save_prefs(self):
        if not self.online:
            self.prefs["offline_state"] = self.st
        try:
            self.page.client_storage.set(PREFS_KEY, json.dumps(self.prefs))
        except Exception:
            pass

    @property
    def online(self):
        return self.user is not None

    @property
    def is_teacher(self):
        return self.online and self.user.get("role") == "teacher"

    @property
    def c(self):
        return DARK if self.prefs["theme"] == "dark" else LIGHT

    def t(self, key):
        return T[self.prefs["lang"]][key]

    def tr(self, v):
        return v if isinstance(v, str) else v[self.prefs["lang"]]

    def display_name(self):
        if self.online:
            return self.user.get("name") or self.user.get("username", "")
        return self.prefs.get("name", "")

    def setup_page(self):
        p = self.page
        p.title = "Kodla"
        p.padding = 0
        p.fonts = {
            DISPLAY: "https://github.com/google/fonts/raw/main/ofl/unbounded/Unbounded%5Bwght%5D.ttf",
            "Manrope": "https://github.com/google/fonts/raw/main/ofl/manrope/Manrope%5Bwght%5D.ttf",
            MONO: "https://github.com/google/fonts/raw/main/ofl/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf",
        }
        try:
            p.window.width, p.window.height, p.window.min_width = 440, 900, 360
        except Exception:
            pass
        p.on_keyboard_event = self.on_key
        self.apply_theme()

    def apply_theme(self):
        p = self.page
        p.theme_mode = ft.ThemeMode.DARK if self.prefs["theme"] == "dark" else ft.ThemeMode.LIGHT
        p.theme = ft.Theme(color_scheme_seed=LIGHT["blue"], font_family="Manrope")
        p.dark_theme = ft.Theme(color_scheme_seed=DARK["blue"], font_family="Manrope")
        p.bgcolor = self.c["bg"]

    def boot(self):
        if self.prefs.get("mode") == "online" and self.prefs.get("token"):
            try:
                self.user = self.api.call("/api/me")["user"]
                self.st = normalize(self.user["state"])
            except ApiError:
                self.user = None
        self.render()

    # ------------------------------------------------------------ kichik UI bo‘laklari / мелкие элементы
    def txt(self, value, size=15, weight=None, color=None, font=None, **kw):
        return ft.Text(value, size=size, weight=weight, color=color or self.c["ink"], font_family=font, **kw)

    def title(self, value, size=20):
        return self.txt(value, size, W8, font=DISPLAY)

    def card(self, content, pad=16, bg=None, border=None, radius=20, **kw):
        c = self.c
        return ft.Container(content, padding=pad, bgcolor=bg or c["surface"], border_radius=radius,
                            border=ft.border.all(1, border or c["line"]), **kw)

    def btn(self, text, on_click, kind="primary", expand=False, disabled=False, icon=None, height=52):
        c = self.c
        colors = {"primary": (c["blue"], "#FFFFFF"), "hero": ("#FFFFFF", "#0B2F8A"),
                  "ghost": (c["surface2"], c["ink"]), "good": (c["good"], "#FFFFFF"),
                  "bad": (c["bad"], "#FFFFFF"), "gold": (c["gold"], "#2A1C00")}
        bg, fg = colors[kind]
        return ft.ElevatedButton(
            text=text, icon=icon, on_click=on_click, disabled=disabled, expand=expand, height=height,
            bgcolor=bg, color=fg, icon_color=fg,
            style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=16), elevation=0,
                                 text_style=ft.TextStyle(size=16, weight=W8),
                                 padding=ft.padding.symmetric(horizontal=18)))

    def chip(self, text, bg=None, fg=None, border=None):
        c = self.c
        return ft.Container(self.txt(text, 14, W8, fg or c["ink"]), bgcolor=bg or c["surface"],
                            border=ft.border.all(1, border or c["line"]), border_radius=99,
                            padding=ft.padding.symmetric(6, 11))

    def bar(self, value, color=None, bg=None, height=10):
        return ft.ProgressBar(value=max(0.0, min(1.0, value)), color=color or self.c["blue"],
                              bgcolor=bg or self.c["surface2"], bar_height=height, border_radius=99)

    def label(self, text, color=None):
        return self.txt(text.upper(), 12, W8, color or self.c["muted"])

    def code_box(self, code):
        c = self.c
        return ft.Container(self.txt(code, 14, color=c["code_fg"], font=MONO, selectable=True),
                            bgcolor=c["code_bg"], border_radius=16, padding=ft.padding.symmetric(14, 16))

    def code_field(self, value, on_change, min_lines=6):
        c = self.c
        return ft.TextField(value=value, on_change=on_change, multiline=True, min_lines=min_lines,
                            text_style=ft.TextStyle(font_family=MONO, size=14, color=c["code_fg"]),
                            bgcolor=c["code_bg"], cursor_color=c["sky"], border_color=c["code_bg"],
                            focused_border_color=c["sky"], border_radius=16, content_padding=14)

    def field(self, value, label, on_change, password=False, **kw):
        c = self.c
        return ft.TextField(value=value, label=label, on_change=on_change, password=password,
                            can_reveal_password=password, bgcolor=c["surface"], border_color=c["line"],
                            focused_border_color=c["blue"], border_radius=14, color=c["ink"],
                            label_style=ft.TextStyle(color=c["muted"]), **kw)

    def avatar(self, emoji, size=44, ring=None):
        c = self.c
        return ft.Container(ft.Text(emoji, size=size * 0.55), width=size, height=size, border_radius=size / 2,
                            bgcolor=c["ice"], alignment=ft.alignment.center,
                            border=ft.border.all(3, ring) if ring else None)

    def toast(self, text):
        try:
            self.page.open(ft.SnackBar(ft.Text(text), bgcolor=self.c["deep"], behavior=ft.SnackBarBehavior.FLOATING))
        except Exception:
            pass

    def theme_button(self):
        dark = self.prefs["theme"] == "dark"
        return ft.IconButton(ft.Icons.LIGHT_MODE if dark else ft.Icons.DARK_MODE,
                             tooltip=self.t("light") if dark else self.t("dark"),
                             icon_color=self.c["ink"], bgcolor=self.c["surface"], on_click=self.toggle_theme)

    def lang_button(self):
        other = "RU" if self.prefs["lang"] == "uz" else "UZ"
        return ft.Container(self.txt(f"{self.prefs['lang'].upper()} ⇄ {other}", 13, W8),
                            bgcolor=self.c["surface"], border=ft.border.all(1, self.c["line"]),
                            border_radius=99, padding=ft.padding.symmetric(8, 12), ink=True,
                            on_click=self.toggle_lang)

    def header(self):
        c, s = self.c, self.st
        me = ft.Container(self.avatar(s["avatar"], 42, c["blue"]), on_click=lambda e: self.go("profile"),
                          tooltip=self.display_name() or "Kodla")
        logo = ft.Row([me, ft.Column([self.txt("Kodla", 18, W8, c["blue"], font=DISPLAY),
                                      self.txt(f"{self.t('level')} {level_of(s['xp'])}", 12, W7, c["muted"])],
                                     spacing=0)], spacing=10)
        stats = ft.Row([self.chip(f"🔥 {s['streak']}"), self.chip(f"💎 {s['gems']}", c["gold_bg"], border=c["gold_bg"]),
                        self.theme_button()], spacing=6)
        return ft.Row([logo, stats], alignment=ft.MainAxisAlignment.SPACE_BETWEEN, wrap=True)

    # ------------------------------------------------------------ kirish ekrani / экран входа
    def view_auth(self):
        c = self.c
        form = {"server": self.prefs["server"], "username": "", "password": "", "name": ""}
        reg = self.auth_mode == "register"

        def setv(k):
            def h(e):
                form[k] = e.control.value
            return h

        def submit(e=None):
            self.do_auth(form)

        err = ft.Container(self.txt(self.auth_error, 14, W6, c["bad"]), bgcolor=c["bad_bg"], border_radius=12,
                           padding=12, visible=bool(self.auth_error))
        fields = [
            self.field(form["username"], self.t("username"), setv("username"), autofocus=True,
                       prefix_icon=ft.Icons.PERSON_OUTLINE),
            self.field(form["password"], self.t("password"), setv("password"), password=True,
                       prefix_icon=ft.Icons.LOCK_OUTLINE, on_submit=submit),
        ]
        if reg:
            fields.append(self.field("", self.t("name"), setv("name"), prefix_icon=ft.Icons.BADGE_OUTLINED))
        fields.append(self.field(form["server"], self.t("server"), setv("server"), prefix_icon=ft.Icons.DNS_OUTLINED))

        hero = ft.Container(ft.Column([
            ft.Row([self.avatar("🤖", 64, "#FFFFFF"),
                    ft.Container(self.txt(random.choice(self.t("tips")), 14, W6, c["ink"]), bgcolor=c["surface"],
                                 border_radius=16, padding=12, expand=True)], spacing=12),
            self.txt("Kodla", 34, W8, "#FFFFFF", font=DISPLAY),
            self.txt(self.t("login_sub"), 15, W6, c["hero_soft"]),
        ], spacing=10), gradient=ft.LinearGradient(begin=ft.alignment.top_left, end=ft.alignment.bottom_right,
                                                   colors=[c["hero1"], c["hero2"]]),
            border_radius=26, padding=22)

        return ft.Column([
            ft.Row([self.lang_button(), self.theme_button()], alignment=ft.MainAxisAlignment.END),
            hero,
            self.title(self.t("register_btn") if reg else self.t("login_title"), 22),
            *fields, err,
            self.btn(self.t("register_btn") if reg else self.t("login_btn"), submit, expand=True),
            ft.TextButton(self.t("have_account") if reg else self.t("no_account"), on_click=self.flip_auth,
                          style=ft.ButtonStyle(color=c["blue"])),
            ft.Divider(color=c["line"]),
            self.btn(self.t("offline"), self.go_offline, "ghost", expand=True, icon=ft.Icons.WIFI_OFF),
        ], spacing=14, scroll=ft.ScrollMode.AUTO, expand=True)

    def flip_auth(self, e=None):
        self.auth_mode = "register" if self.auth_mode == "login" else "login"
        self.auth_error = ""
        self.render()

    def do_auth(self, form):
        if len(form["username"].strip()) < 3 or len(form["password"]) < 4:
            self.auth_error = self.t("err_short")
            return self.render()
        self.prefs["server"] = form["server"].strip() or DEFAULT_SERVER
        api = Api(self.prefs["server"])
        path = "/api/register" if self.auth_mode == "register" else "/api/login"
        try:
            res = api.call(path, {"username": form["username"].strip(), "password": form["password"],
                                  "name": form["name"].strip()})
        except ApiError as e:
            self.auth_error = self.t({"conn": "err_conn", "taken": "err_taken", "short": "err_short"}.get(e.code, "err_auth"))
            return self.render()
        api.token = res["token"]
        self.api, self.user = api, res["user"]
        self.st = normalize(self.user["state"])
        self.prefs.update(token=res["token"], mode="online")
        self.auth_error, self.tab = "", "home"
        self.save_prefs()
        self.render()

    def go_offline(self, e=None):
        self.user = None
        self.prefs.update(mode="offline", token="")
        self.st = normalize(self.prefs.get("offline_state") or {})
        self.save_prefs()
        self.tab = "home"
        self.render()

    def logout(self, e=None):
        if self.online:
            try:
                self.api.call("/api/logout", {})
            except ApiError:
                pass
        self.user = None
        self.prefs.update(mode="", token="")
        self.st = normalize(self.prefs.get("offline_state") or {})
        self.save_prefs()
        self.render()

    # ------------------------------------------------------------ o‘yin amallari (server yoki oflayn)
    def server_or_local(self, path, payload, local_fn):
        """Onlayn bo‘lsa serverga yuboradi, bo‘lmasa shu yerda hisoblaydi."""
        if self.online:
            try:
                res = self.api.call(path, payload)
                self.user = res["user"]
                self.st = normalize(self.user["state"])
                return res
            except ApiError as e:
                self.toast(self.t("err_conn") if e.code == "conn" else self.t("error"))
                return None
        self.st, res = local_fn(self.st)
        self.save_prefs()
        return res

    def claim(self, qid):
        res = self.server_or_local("/api/claim", {"quest_id": qid},
                                   lambda s: (lambda r: (r[0], {"gems": r[1]}))(claim_quest(s, qid)))
        if res and res.get("gems"):
            self.toast(f"+{res['gems']} 💎")
        self.render()

    def chest(self, course):
        ids = [l["id"] for l in course["lessons"]]
        res = self.server_or_local("/api/chest", {"course_id": course["id"]},
                                   lambda s: (lambda r: (r[0], {"gems": r[1]}))(open_chest(s, course["id"], ids)))
        if res and res.get("gems"):
            self.toast(f"🎁 {self.t('chest')}: +{res['gems']} 💎")
        self.render()

    def pick_avatar(self, emoji):
        if emoji not in self.st["owned"] and self.st["gems"] < AVATARS[emoji]:
            self.toast(self.t("not_enough"))
            return
        self.server_or_local("/api/avatar", {"avatar": emoji},
                             lambda s: (lambda r: (r[0], {"ok": r[1]}))(buy_avatar(s, emoji)))
        self.render()

    def finish_lesson(self, lesson, perfect, best_combo):
        res = self.server_or_local(
            "/api/complete", {"lesson_id": lesson["id"], "perfect": perfect, "best_combo": best_combo},
            lambda s: (lambda r: (r[0], {"result": r[1]}))(complete_lesson(s, lesson["id"], lesson["xp"], perfect, best_combo)))
        return res["result"] if res else None

    # ------------------------------------------------------------ yordamchi hisoblar
    def course(self):
        return next((x for x in COURSES if x["id"] == self.prefs["course"]), COURSES[0])

    def progress(self, course):
        return sum(1 for l in course["lessons"] if self.st["done"].get(l["id"]))

    def next_lesson(self, course):
        return next((l for l in course["lessons"] if not self.st["done"].get(l["id"])), None)

    def unlocked(self, course, i):
        return i == 0 or self.st["done"].get(course["lessons"][i - 1]["id"])

    # ------------------------------------------------------------ 1. Sarguzasht / Приключение
    def view_home(self):
        c, s = self.c, self.st
        lvl = level_of(s["xp"])
        course = self.course()
        nl = self.next_lesson(course) or next((self.next_lesson(x) for x in COURSES if self.next_lesson(x)), None)
        nl_course = ALL_LESSONS[nl["id"]][1] if nl else course
        tip = self.t("tips")[date.today().toordinal() % len(self.t("tips"))]
        name = self.display_name()

        ring = ft.Stack([
            ft.ProgressRing(value=(s["xp"] % 100) / 100, width=86, height=86, stroke_width=9,
                            color="#8FD0FF", bgcolor="#FFFFFF33"),
            ft.Container(ft.Column([self.txt(str(lvl), 26, W8, "#FFFFFF", font=DISPLAY),
                                    self.txt(self.t("level"), 10, W8, c["hero_soft"])],
                                   spacing=0, horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                         width=86, height=86, alignment=ft.alignment.center),
        ], width=86, height=86)
        if nl:
            cta = self.btn(f"▶  {self.t('play_now')}: {self.tr(nl['title'])}",
                           lambda e, lid=nl["id"]: self.open_lesson(lid), "hero", expand=True)
        else:
            cta = self.btn(f"🏆 {self.t('courses')}", lambda e: self.go("courses"), "hero", expand=True)
        hero = ft.Container(ft.Column([
            ft.Row([ring, ft.Column([
                self.txt(f"{self.t('hello')}{', ' + name if name else ''}!", 22, W8, "#FFFFFF", font=DISPLAY),
                self.txt(f"{100 - s['xp'] % 100} XP {self.t('next_level')}", 14, W6, c["hero_soft"]),
                self.chip(f"{nl_course['tag']}  {self.tr(nl_course['name'])}", "#FFFFFF22", "#FFFFFF", "#FFFFFF33"),
            ], spacing=6, expand=True)], spacing=16),
            ft.Row([self.txt(f"🎯 {self.t('goal')}", 13, W7, "#FFFFFF"),
                    self.txt(f"{min(s['today_xp'], GOAL)} / {GOAL} XP", 13, W7, "#FFFFFF")],
                   alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            self.bar(s["today_xp"] / GOAL, "#8FD0FF", "#FFFFFF2A", 12),
            ft.Row([cta]),
        ], spacing=12), gradient=ft.LinearGradient(begin=ft.alignment.top_left, end=ft.alignment.bottom_right,
                                                   colors=[c["hero1"], c["hero2"]]),
            border_radius=26, padding=20)

        mascot = ft.Row([
            self.avatar("🤖", 54, c["sky"]),
            ft.Container(ft.Column([self.txt(self.t("mascot_name"), 12, W8, c["blue"]),
                                    self.txt(tip, 14, W6)], spacing=2),
                         bgcolor=c["surface"], border=ft.border.all(1, c["line"]),
                         border_radius=ft.border_radius.only(4, 18, 18, 18), padding=12, expand=True),
        ], spacing=10, vertical_alignment=ft.CrossAxisAlignment.START)

        days = self.t("days_short")
        week = ft.Row([ft.Column([
            ft.Container(self.txt("🔥" if on else "·", 18 if on else 20, W8, c["muted"]), width=38, height=38,
                         border_radius=19, alignment=ft.alignment.center,
                         bgcolor=c["gold_bg"] if on else c["surface2"],
                         border=ft.border.all(2, c["blue"]) if d == date.today().isoformat() else None),
            self.txt(days[date.fromisoformat(d).weekday()], 11, W7, c["muted"]),
        ], spacing=4, horizontal_alignment=ft.CrossAxisAlignment.CENTER) for d, on in last_week(s)],
            alignment=ft.MainAxisAlignment.SPACE_BETWEEN)
        week_card = self.card(ft.Column([
            ft.Row([self.title(self.t("week"), 16), self.chip(f"🔥 {s['streak']} {self.t('streak').lower()}")],
                   alignment=ft.MainAxisAlignment.SPACE_BETWEEN, wrap=True), week], spacing=12))

        quest_rows = []
        for q in QUESTS:
            prog = quest_progress(s, q)
            done = prog >= q["target"]
            claimed = q["id"] in s["quests"]["claimed"]
            if claimed:
                action = self.chip(f"✓ {self.t('claimed')}", c["good_bg"], c["good"], c["good_bg"])
            elif done:
                action = self.btn(f"{self.t('claim')} 💎{q['gems']}", lambda e, qid=q["id"]: self.claim(qid), "gold", height=40)
            else:
                action = self.chip(f"💎 {q['gems']}", c["gold_bg"], border=c["gold_bg"])
            quest_rows.append(ft.Row([
                ft.Container(ft.Text(q["icon"], size=22), width=44, height=44, border_radius=14, bgcolor=c["surface2"],
                             alignment=ft.alignment.center),
                ft.Column([self.txt(self.tr(q["title"]), 14, W7),
                           ft.Row([ft.Container(self.bar(prog / q["target"], c["gold"] if done else c["blue"], height=8),
                                                expand=True),
                                   self.txt(f"{prog}/{q['target']}", 12, W7, c["muted"])], spacing=8)],
                          spacing=6, expand=True),
                action], spacing=12))
        quests = self.card(ft.Column([self.title(self.t("quests"), 16), *quest_rows], spacing=14))

        cards = []
        for co in COURSES:
            d, n = self.progress(co), len(co["lessons"])
            cards.append(ft.Container(ft.Column([
                ft.Row([ft.Container(self.txt(co["tag"], 14, W8, "#FFFFFF", font=MONO), width=46, height=46,
                                     border_radius=14, bgcolor=co["color"], alignment=ft.alignment.center),
                        self.txt("🎁" if co["id"] not in s["chests"] else "✨", 18)],
                       alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                self.txt(self.tr(co["name"]), 16, W8),
                self.txt(self.tr(co["sub"]), 12, color=c["muted"]),
                self.bar(d / n, co["color"], height=8),
                self.txt(f"{d}/{n} {self.t('lessons')}", 12, W7, c["muted"]),
            ], spacing=8), bgcolor=c["surface"], border=ft.border.all(1, c["line"]), border_radius=20, padding=14,
                ink=True, col={"xs": 6}, on_click=lambda e, cid=co["id"]: self.pick_course(cid, True)))

        return [hero, mascot, quests, week_card, self.title(self.t("courses"), 18),
                ft.ResponsiveRow(cards, spacing=12, run_spacing=12)]

    # ------------------------------------------------------------ 2. Xarita / Карта курса
    def view_courses(self):
        c, s = self.c, self.st
        course = self.course()
        cur = self.next_lesson(course)
        chips = ft.Row([ft.Container(
            self.txt(f"{x['tag']}  {self.tr(x['name'])}", 14, W8, "#FFFFFF" if x["id"] == course["id"] else c["ink"]),
            bgcolor=x["color"] if x["id"] == course["id"] else c["surface"],
            border=ft.border.all(1, x["color"] if x["id"] == course["id"] else c["line"]),
            border_radius=99, padding=ft.padding.symmetric(9, 14), ink=True,
            on_click=lambda e, cid=x["id"]: self.pick_course(cid)) for x in COURSES], scroll=ft.ScrollMode.AUTO, spacing=8)

        d, n = self.progress(course), len(course["lessons"])
        head = ft.Container(ft.Column([
            ft.Row([ft.Container(self.txt(course["tag"], 16, W8, "#FFFFFF", font=MONO), width=54, height=54,
                                 border_radius=16, bgcolor="#FFFFFF33", alignment=ft.alignment.center),
                    ft.Column([self.txt(f"{self.t('boss')} 1", 12, W8, "#FFFFFFCC"),
                               self.txt(self.tr(course["name"]), 22, W8, "#FFFFFF", font=DISPLAY),
                               self.txt(self.tr(course["sub"]), 13, W6, "#FFFFFFDD")], spacing=0, expand=True)],
                   spacing=14),
            self.bar(d / n, "#FFFFFF", "#FFFFFF33", 10),
        ], spacing=12), bgcolor=course["color"], border_radius=24, padding=18)

        offsets = [0, 70, 140, 70]
        rows = []
        for i, l in enumerate(course["lessons"]):
            done = s["done"].get(l["id"])
            is_open = self.unlocked(course, i)
            is_cur = cur is not None and cur["id"] == l["id"]
            if done:
                bg, fg, mark, sub = c["blue"], "#FFFFFF", "★", self.t("completed")
            elif is_cur:
                bg, fg, mark, sub = c["sky"], "#FFFFFF", "▶", f"{self.t('now')} · +{l['xp']} XP"
            elif is_open:
                bg, fg, mark, sub = c["surface2"], c["ink"], str(i + 1), f"+{l['xp']} XP"
            else:
                bg, fg, mark, sub = c["surface2"], c["muted"], "🔒", self.t("locked")
            node = ft.Container(
                self.txt(mark, 24, W8, fg), width=74, height=74, border_radius=37, bgcolor=bg,
                alignment=ft.alignment.center,
                border=ft.border.all(6, c["ice"]) if is_cur else ft.border.all(3, c["deep"] if done else c["line"]),
                shadow=ft.BoxShadow(blur_radius=0, offset=ft.Offset(0, 6), color=c["deep"] if (done or is_cur) else c["line"]),
                on_click=(lambda e, lid=l["id"]: self.open_lesson(lid)) if is_open else None, ink=bool(is_open),
                animate_scale=ft.Animation(400, ft.AnimationCurve.EASE_OUT_BACK), scale=1.08 if is_cur else 1)
            rows.append(ft.Container(ft.Row([node, ft.Column([self.txt(self.tr(l["title"]), 16, W8),
                                                              self.txt(sub, 13, W6, c["muted"])], spacing=0, expand=True)],
                                            spacing=14), padding=ft.padding.only(left=offsets[i % 4])))
            rows.append(ft.Container(self.txt("• • •", 14, W8, c["line"]), padding=ft.padding.only(left=offsets[i % 4] + 24)))

        all_done = d == n
        opened = course["id"] in s["chests"]
        chest = self.card(ft.Row([
            ft.Container(ft.Text("✨" if opened else "🎁", size=34), width=64, height=64, border_radius=18,
                         bgcolor=c["gold_bg"], alignment=ft.alignment.center),
            ft.Column([self.txt(self.t("chest"), 16, W8),
                       self.txt(self.t("chest_done") if opened else ("+50 💎" if all_done else self.t("chest_locked")),
                                13, W6, c["muted"])], spacing=2, expand=True),
            self.btn(self.t("chest_open"), lambda e: self.chest(course), "gold", height=44)
            if all_done and not opened else ft.Container()], spacing=14),
            bg=c["gold_bg"] if all_done and not opened else None, border=c["gold"] if all_done and not opened else None)
        return [chips, head, ft.Column(rows, spacing=6), chest]

    # ------------------------------------------------------------ 3. Mashq / Практика
    def view_play(self):
        c = self.c
        output = self.txt(self.play_out or self.t("empty_out"), 14, color=c["code_fg"], font=MONO, selectable=True)

        def set_code(e):
            self.play_code = e.control.value

        def set_inputs(e):
            self.play_inputs = e.control.value

        def run(e):
            out, err = run_python(self.play_code, self.play_inputs.splitlines())
            if err == "timeout":
                out += f"\n⚠ {self.t('timeout')}"
            elif err:
                out += f"\n⚠ {self.t('error')}: {err}"
            self.play_out = out.strip()
            output.value = self.play_out or self.t("empty_out")
            output.update()

        return [
            ft.Row([ft.Container(self.txt("Py", 16, W8, "#FFFFFF", font=MONO), width=50, height=50, border_radius=16,
                                 bgcolor="#2F9E6E", alignment=ft.alignment.center),
                    ft.Column([self.title(self.t("play_title")), self.txt(self.t("play_text"), 14, color=c["muted"])],
                              spacing=2, expand=True)], spacing=14),
            self.code_field(self.play_code, set_code, 9),
            self.field(self.play_inputs, self.t("inputs"), set_inputs, multiline=True, min_lines=1),
            ft.Row([self.btn(f"▶  {self.t('run')}", run, "good", expand=True)]),
            self.label(self.t("output")),
            ft.Container(output, bgcolor=c["code_bg"], border_radius=16, padding=16, width=float("inf")),
        ]

    # ------------------------------------------------------------ 4. Reyting / Рейтинг
    def load_ranking(self, e=None):
        try:
            self.rank_rows, self.rank_error = self.api.call("/api/leaderboard")["rows"], ""
        except ApiError:
            self.rank_rows, self.rank_error = None, self.t("err_conn")
        if e is not None:
            self.render()

    def view_ranking(self):
        c = self.c
        top = ft.Row([self.title(self.t("ranking")),
                      ft.IconButton(ft.Icons.REFRESH, on_click=self.load_ranking, icon_color=c["ink"],
                                    tooltip=self.t("refresh"))], alignment=ft.MainAxisAlignment.SPACE_BETWEEN)
        if not self.online:
            return [top, self.card(ft.Row([ft.Text("📡", size=28), self.txt(self.t("rank_offline"), 15, W6, expand=True)],
                                          spacing=12))]
        if self.rank_rows is None and not self.rank_error:
            self.load_ranking()
        if self.rank_error:
            return [top, self.card(self.txt(self.rank_error, 14, W6, c["bad"]), bg=c["bad_bg"], border=c["bad_bg"])]
        rows = self.rank_rows or []
        if not rows:
            return [top, self.card(ft.Row([ft.Text("🏁", size=28), self.txt(self.t("rank_empty"), 15, W6, expand=True)],
                                          spacing=12))]
        me = self.user.get("username", "").lower()
        medals = [("🥇", c["gold"], 130), ("🥈", "#A9B6CC", 104), ("🥉", "#D08A4E", 86)]
        podium_order = [1, 0, 2]
        podium = []
        for idx in podium_order:
            if idx >= len(rows):
                continue
            r = rows[idx]
            medal, col, h = medals[idx]
            podium.append(ft.Column([
                self.avatar(r.get("avatar", "🤖"), 56 if idx == 0 else 46, col),
                self.txt(r["name"], 13, W8, max_lines=1, overflow=ft.TextOverflow.ELLIPSIS, text_align=ft.TextAlign.CENTER),
                ft.Container(ft.Column([ft.Text(medal, size=26), self.txt(f"{r['xp']} XP", 13, W8, "#1A1200")],
                                       horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=2),
                             height=h, bgcolor=col, border_radius=ft.border_radius.only(16, 16, 6, 6),
                             alignment=ft.alignment.top_center, padding=10),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=6, expand=True))
        podium_card = self.card(ft.Row(podium, vertical_alignment=ft.CrossAxisAlignment.END, spacing=10), pad=14)

        lines = []
        for i, r in enumerate(rows):
            mine = r["username"].lower() == me
            lines.append(ft.Container(ft.Row([
                self.txt(f"{i + 1}", 16, W8, c["muted"], font=DISPLAY, width=30, text_align=ft.TextAlign.CENTER),
                self.avatar(r.get("avatar", "🤖"), 40),
                ft.Column([self.txt(r["name"] + (f"  ({self.t('you')})" if mine else ""), 15, W8),
                           self.txt(f"{self.t('level')} {r['level']} · 🔥 {r['streak']} · {r['done']} {self.t('lessons')}",
                                    12, W6, c["muted"])], spacing=0, expand=True),
                self.txt(f"{r['xp']} XP", 15, W8, c["blue"])], spacing=12),
                bgcolor=c["ice"] if mine else c["surface"], border=ft.border.all(2 if mine else 1, c["blue"] if mine else c["line"]),
                border_radius=16, padding=ft.padding.symmetric(10, 12)))
        return [top, podium_card, ft.Column(lines, spacing=8)]

    # ------------------------------------------------------------ 5. Ustoz paneli / Панель учителя
    def load_teacher(self, e=None):
        try:
            self.teacher_rows, self.teacher_error = self.api.call("/api/teacher/students")["rows"], ""
        except ApiError:
            self.teacher_rows, self.teacher_error = None, self.t("err_conn")
        if e is not None:
            self.render()

    def view_teacher(self):
        c = self.c
        if self.teacher_rows is None and not self.teacher_error:
            self.load_teacher()
        top = ft.Row([ft.Column([self.title(self.t("teacher")), self.txt(self.t("teacher_sub"), 14, color=c["muted"])],
                                spacing=2, expand=True),
                      ft.IconButton(ft.Icons.REFRESH, on_click=self.load_teacher, icon_color=c["ink"])])
        if self.teacher_error:
            return [top, self.card(self.txt(self.teacher_error, 14, W6, c["bad"]), bg=c["bad_bg"], border=c["bad_bg"])]
        rows = self.teacher_rows or []
        today = date.today().isoformat()

        def stat(v, k, icon):
            return self.card(ft.Column([self.txt(icon, 20), self.txt(str(v), 22, W8, font=DISPLAY),
                                        self.txt(k, 12, W7, c["muted"])], spacing=2,
                                       horizontal_alignment=ft.CrossAxisAlignment.CENTER), pad=12, expand=True)

        summary = ft.Row([
            stat(len(rows), self.t("students"), "👩‍🎓"),
            stat(sum(len(r["done"]) for r in rows), self.t("lessons"), "📘"),
            stat(sum(1 for r in rows if r["last_day"] == today), date.today().strftime("%d.%m"), "🔥"),
        ], spacing=10)
        cards = []
        for r in rows:
            per_course = ft.Row([ft.Column([self.txt(co["tag"], 11, W8, co["color"], font=MONO),
                                            self.bar(sum(1 for l in co["lessons"] if l["id"] in r["done"]) / len(co["lessons"]),
                                                     co["color"], height=6)], spacing=4, expand=True)
                                 for co in COURSES], spacing=10)
            cards.append(self.card(ft.Column([
                ft.Row([self.avatar(r.get("avatar", "🤖"), 44),
                        ft.Column([self.txt(r["name"], 16, W8), self.txt(f"@{r['username']}", 12, W6, c["muted"])],
                                  spacing=0, expand=True),
                        ft.Column([self.txt(f"{r['xp']} XP", 15, W8, c["blue"]),
                                   self.txt(f"🔥 {r['streak']} · 💎 {r.get('gems', 0)}", 12, W6, c["muted"])],
                                  spacing=0, horizontal_alignment=ft.CrossAxisAlignment.END)], spacing=12),
                per_course,
                self.txt(f"{self.t('last_active')}: {r['last_day'] or self.t('never')}", 12, W6, c["muted"]),
            ], spacing=10), pad=14))
        if not rows:
            cards.append(self.card(self.txt(self.t("rank_empty"), 14, W6)))
        return [top, summary, *cards]

    # ------------------------------------------------------------ 6. Profil / Профиль
    def view_profile(self):
        c, s = self.c, self.st

        def set_name(e):
            if not self.online:
                self.prefs["name"] = e.control.value.strip()[:30]
                self.save_prefs()

        def save_name(e):
            if self.online:
                try:
                    self.user = self.api.call("/api/name", {"name": e.control.value})["user"]
                except ApiError:
                    self.toast(self.t("err_conn"))
            self.render()

        def stat(v, k):
            return self.card(ft.Column([self.txt(str(v), 22, W8, font=DISPLAY), self.txt(k, 12, W7, c["muted"])],
                                       spacing=2, horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                             pad=12, col={"xs": 4})

        status = self.chip(f"● {self.t('online')}" if self.online else f"○ {self.t('offline_mode')}",
                           c["good_bg"] if self.online else c["surface2"], c["good"] if self.online else c["muted"],
                           c["good_bg"] if self.online else c["surface2"])
        head = ft.Row([self.avatar(s["avatar"], 84, c["blue"]),
                       ft.Column([self.field(self.display_name(), self.t("name"), set_name, on_blur=save_name,
                                             on_submit=save_name, max_length=30),
                                  ft.Row([status] + ([self.chip(f"@{self.user['username']}")] if self.online else []),
                                         wrap=True)], spacing=6, expand=True)], spacing=16)

        stats = ft.ResponsiveRow([stat(level_of(s["xp"]), self.t("level")), stat(s["xp"], "XP"),
                                  stat(s["gems"], self.t("gems")), stat(s["streak"], self.t("streak")),
                                  stat(len(s["done"]), self.t("lessons")), stat(s["perfect"], self.t("perfect_n"))],
                                 spacing=10, run_spacing=10)

        shop = []
        for emoji, price in AVATARS.items():
            owned = emoji in s["owned"]
            equipped = s["avatar"] == emoji
            if equipped:
                tag = self.txt(self.t("equipped"), 11, W8, c["blue"])
            elif owned:
                tag = self.txt(self.t("equip"), 11, W8, c["muted"])
            else:
                tag = self.txt(f"💎 {price}", 12, W8, c["gold"] if s["gems"] >= price else c["muted"])
            shop.append(ft.Container(ft.Column([ft.Text(emoji, size=30, opacity=1 if owned or s["gems"] >= price else 0.45),
                                                tag], spacing=4, horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                                     bgcolor=c["ice"] if equipped else c["surface"],
                                     border=ft.border.all(2 if equipped else 1, c["blue"] if equipped else c["line"]),
                                     border_radius=16, padding=ft.padding.symmetric(10, 4), col={"xs": 4, "sm": 3},
                                     ink=True, on_click=lambda e, em=emoji: self.pick_avatar(em)))

        badges = [("🚀", self.t("b1"), len(s["done"]) >= 1), ("⚡", self.t("b2"), s["xp"] >= 100),
                  ("🔥", self.t("b3"), s["streak"] >= 3), ("🎯", self.t("perfect"), s["perfect"] >= 1),
                  ("🏆", self.t("b4"), any(self.progress(x) == len(x["lessons"]) for x in COURSES)),
                  ("💎", "200 💎", s["gems"] >= 200)]
        badge_row = ft.ResponsiveRow([ft.Container(ft.Column([
            ft.Container(ft.Text(icon, size=22, opacity=1 if on else 0.3), width=48, height=48, border_radius=24,
                         bgcolor=c["gold_bg"] if on else c["surface2"], alignment=ft.alignment.center),
            self.txt(name, 11, W8, c["ink"] if on else c["muted"], text_align=ft.TextAlign.CENTER)],
            spacing=6, horizontal_alignment=ft.CrossAxisAlignment.CENTER), col={"xs": 4}, padding=6)
            for icon, name, on in badges], spacing=6, run_spacing=6)

        settings = self.card(ft.Column([
            ft.Row([self.txt(f"🌓 {self.t('theme')}", 15, W7, expand=True),
                    ft.SegmentedButton(selected={self.prefs["theme"]}, show_selected_icon=False,
                                       on_change=lambda e: self.set_theme(next(iter(e.control.selected))),
                                       segments=[ft.Segment(value="light", label=ft.Text(self.t("light")), icon=ft.Icon(ft.Icons.LIGHT_MODE)),
                                                 ft.Segment(value="dark", label=ft.Text(self.t("dark")), icon=ft.Icon(ft.Icons.DARK_MODE))])],
                   wrap=True),
            ft.Row([self.txt("🌐 Til / Язык", 15, W7, expand=True), self.lang_button()]),
        ], spacing=12))

        if self.online:
            bottom = self.btn(self.t("logout"), self.logout, "ghost", icon=ft.Icons.LOGOUT)
        elif self.confirm_reset:
            bottom = self.card(ft.Column([self.txt(self.t("reset_q"), 15, W7),
                                          ft.Row([self.btn(self.t("yes"), self.do_reset, "bad"),
                                                  self.btn(self.t("no"), lambda e: self.set_confirm(False), "ghost")],
                                                 wrap=True)], spacing=10), bg=c["bad_bg"], border=c["bad_bg"])
        else:
            bottom = ft.Row([self.btn(self.t("login_btn"), self.logout, "primary", icon=ft.Icons.LOGIN),
                             self.btn(self.t("reset"), lambda e: self.set_confirm(True), "ghost")], wrap=True)
        return [head, stats, self.title(self.t("shop"), 18), ft.ResponsiveRow(shop, spacing=10, run_spacing=10),
                self.title(self.t("badges"), 18), badge_row, settings, bottom]

    # ------------------------------------------------------------ chizish / отрисовка
    def tabs(self):
        return ["home", "courses", "play", "ranking", "teacher" if self.is_teacher else "profile"]

    def render(self):
        p, c = self.page, self.c
        p.bgcolor = c["bg"]
        p.controls.clear()
        p.navigation_bar = None
        if self.ls:
            p.add(ft.SafeArea(self.view_lesson(), expand=True))
            p.update()
            return
        if not self.online and self.prefs.get("mode") != "offline":
            p.add(ft.SafeArea(ft.Container(self.view_auth(), padding=ft.padding.symmetric(14, 16), expand=True,
                                           alignment=ft.alignment.top_center), expand=True))
            p.update()
            return
        tabs = self.tabs()
        if self.tab not in tabs and self.tab != "profile":
            self.tab = "home"
        views = {"home": self.view_home, "courses": self.view_courses, "play": self.view_play,
                 "ranking": self.view_ranking, "profile": self.view_profile, "teacher": self.view_teacher}
        body = ft.Column([self.header(), *views[self.tab]()], spacing=16, scroll=ft.ScrollMode.AUTO, expand=True)
        p.add(ft.SafeArea(ft.Container(ft.Container(body, width=640), padding=ft.padding.symmetric(12, 16), expand=True,
                                       alignment=ft.alignment.top_center), expand=True))
        icons = {"home": (ft.Icons.EXPLORE_OUTLINED, ft.Icons.EXPLORE, self.t("adventure")),
                 "courses": (ft.Icons.MAP_OUTLINED, ft.Icons.MAP, self.t("courses")),
                 "play": (ft.Icons.TERMINAL_OUTLINED, ft.Icons.TERMINAL, self.t("play")),
                 "ranking": (ft.Icons.LEADERBOARD_OUTLINED, ft.Icons.LEADERBOARD, self.t("ranking")),
                 "profile": (ft.Icons.PERSON_OUTLINE, ft.Icons.PERSON, self.t("profile")),
                 "teacher": (ft.Icons.SCHOOL_OUTLINED, ft.Icons.SCHOOL, self.t("teacher"))}
        sel = tabs.index(self.tab) if self.tab in tabs else len(tabs) - 1
        p.navigation_bar = ft.NavigationBar(
            selected_index=sel, bgcolor=c["surface"], indicator_color=c["ice"],
            on_change=lambda e: self.go(tabs[e.control.selected_index]),
            destinations=[ft.NavigationBarDestination(icon=icons[k][0], selected_icon=icons[k][1], label=icons[k][2])
                          for k in tabs])
        p.update()

    # ------------------------------------------------------------ hodisalar / события
    def go(self, tab):
        self.tab = tab
        self.confirm_reset = False
        if tab == "ranking":
            self.rank_rows, self.rank_error = None, ""
        if tab == "teacher":
            self.teacher_rows, self.teacher_error = None, ""
        self.render()

    def toggle_theme(self, e=None):
        self.set_theme("light" if self.prefs["theme"] == "dark" else "dark")

    def set_theme(self, mode):
        self.prefs["theme"] = mode
        self.save_prefs()
        self.apply_theme()
        self.render()

    def toggle_lang(self, e=None):
        self.prefs["lang"] = "ru" if self.prefs["lang"] == "uz" else "uz"
        self.save_prefs()
        self.render()

    def pick_course(self, cid, go=False):
        self.prefs["course"] = cid
        self.save_prefs()
        if go:
            self.tab = "courses"
        self.render()

    def set_confirm(self, v):
        self.confirm_reset = v
        self.render()

    def do_reset(self, e=None):
        self.st = normalize(empty_state())
        self.confirm_reset = False
        self.save_prefs()
        self.render()

    def on_key(self, e: ft.KeyboardEvent):
        if not self.ls:
            return
        if e.key == "Escape":
            self.close_lesson()
        elif e.key == "Enter" and not e.shift and self.ls.get("enter"):
            self.ls["enter"]()

    # ------------------------------------------------------------ dars o‘yini / игра-урок
    def open_lesson(self, lid):
        lesson, course = ALL_LESSONS[lid]
        self.ls = {"l": lesson, "c": course, "i": 0, "sel": None, "status": None, "input": "", "code": None,
                   "out": None, "wrong_once": False, "result": None, "combo": 0, "best": 0, "mistakes": 0,
                   "say": ""}
        self.render()

    def close_lesson(self, e=None):
        self.ls = None
        self.render()

    def view_lesson(self):
        c, ls = self.c, self.ls
        l, steps = ls["l"], ls["l"]["steps"]
        combo = ft.Container(self.txt(f"🔥 x{ls['combo']}", 14, W8, "#2A1C00"), bgcolor=c["gold"], border_radius=99,
                             padding=ft.padding.symmetric(6, 10), visible=ls["combo"] >= 2,
                             animate_scale=ft.Animation(300, ft.AnimationCurve.EASE_OUT_BACK))
        top = ft.Row([
            ft.IconButton(ft.Icons.CLOSE, on_click=self.close_lesson, bgcolor=c["surface2"], icon_color=c["ink"]),
            ft.Container(self.bar(ls["i"] / len(steps), c["sky"], c["surface2"], 16), expand=True),
            combo, self.chip(f"⚡ {l['xp']}"),
        ], spacing=10)
        wrap = lambda col: ft.Container(ft.Container(col, width=640), padding=ft.padding.symmetric(12, 16), expand=True,
                                        alignment=ft.alignment.top_center)
        if ls["i"] >= len(steps):
            return wrap(ft.Column([top, self.view_done()], expand=True))

        st = steps[ls["i"]]
        kind_icon = {"read": "📖", "quiz": "❓", "fill": "✏️", "try": "⌨️"}[st["t"]]
        body = [ft.Row([self.txt(kind_icon, 16), self.label(self.t(st["t"]), c["blue"])], spacing=6)]
        check_btn = None

        if st["t"] == "read":
            body += [self.title(self.tr(st["h"]), 22), self.txt(self.tr(st["p"]), 16)]
            if st.get("code"):
                body.append(self.code_box(st["code"]))

        elif st["t"] == "quiz":
            body.append(self.title(self.tr(st["q"]), 20))
            if st.get("code"):
                body.append(self.code_box(st["code"]))
            opts = []
            for k, o in enumerate(st["o"]):
                bg, bd = c["surface"], c["line"]
                if ls["status"]:
                    if k == st["a"] and (ls["status"] == "ok" or ls["wrong_once"]):
                        bg, bd = c["good_bg"], c["good"]
                    elif k == ls["sel"] and ls["status"] == "no":
                        bg, bd = c["bad_bg"], c["bad"]
                elif k == ls["sel"]:
                    bg, bd = c["ice"], c["blue"]
                opts.append(ft.Container(ft.Row([
                    ft.Container(self.txt(str(k + 1), 13, W8, c["muted"], font=MONO), width=30, height=30,
                                 border=ft.border.all(1, c["line"]), border_radius=9, alignment=ft.alignment.center),
                    self.txt(self.tr(o), 16, W7, font=MONO if st.get("mono") else None, expand=True)], spacing=12),
                    bgcolor=bg, border=ft.border.all(2, bd), border_radius=16, padding=ft.padding.symmetric(14, 16),
                    shadow=ft.BoxShadow(blur_radius=0, offset=ft.Offset(0, 4), color=bd), ink=True,
                    on_click=(lambda e, kk=k: self.pick_option(kk)) if ls["status"] != "ok" else None))
            body.append(ft.Column(opts, spacing=12))

        elif st["t"] == "fill":
            body.append(self.title(self.tr(st["q"]), 20))

            def on_fill(e):
                ls["input"] = e.control.value
                if check_btn is not None:
                    check_btn.disabled = not ls["input"].strip()
                    check_btn.update()

            fld = ft.TextField(value=ls["input"], on_change=on_fill, hint_text=self.t("type_here"), width=130,
                               text_align=ft.TextAlign.CENTER, autofocus=True, disabled=ls["status"] == "ok",
                               text_style=ft.TextStyle(font_family=MONO, size=16, color=c["ink"], weight=W7), dense=True,
                               bgcolor=c["surface"], border_color=c["sky"], focused_border_color=c["gold"],
                               border_radius=10, on_submit=lambda e: self.check() if ls["input"].strip() else None)
            parts = ([self.txt(st["pre"], 16, color=c["code_fg"], font=MONO)] if st["pre"] else []) + \
                    [fld, self.txt(st["post"], 16, color=c["code_fg"], font=MONO)]
            body.append(ft.Container(ft.Row(parts, wrap=True, spacing=6, vertical_alignment=ft.CrossAxisAlignment.CENTER),
                                     bgcolor=c["code_bg"], border_radius=16, padding=ft.padding.symmetric(16, 16)))

        elif st["t"] == "try":
            if ls["code"] is None:
                ls["code"] = st["start"]
            mode = {"html": "HTML", "css": "CSS", "js": "JavaScript", "py": "Python"}[st["mode"]]
            body[0] = ft.Row([self.txt(kind_icon, 16), self.label(f"{self.t('try')} · {mode}", c["blue"])], spacing=6)
            body.append(self.title(self.tr(st["task"]), 20))

            def on_code(e):
                ls["code"] = e.control.value

            body += [self.label(self.t("your_code")), self.code_field(ls["code"], on_code)]
            if st["mode"] == "py":
                out_ctrl = self.txt(ls["out"] or self.t("empty_out"), 14, color=c["code_fg"], font=MONO, selectable=True)

                def run_now(e):
                    ls["out"] = self.format_run(*run_python(ls["code"]))
                    out_ctrl.value = ls["out"] or self.t("empty_out")
                    out_ctrl.update()

                body += [ft.Row([ft.OutlinedButton(f"▶  {self.t('run')}", on_click=run_now,
                                                   style=ft.ButtonStyle(color=c["good"]))]),
                         self.label(self.t("output")),
                         ft.Container(out_ctrl, bgcolor=c["code_bg"], border_radius=16, padding=14, width=float("inf"))]

        # ---- Kodi gapiradi / Коди говорит
        foot = []
        if ls["status"] in ("ok", "no"):
            ok = ls["status"] == "ok"
            lines = [self.txt(("✓ " if ok else "✗ ") + ls["say"], 17, W8, c["good"] if ok else c["bad"])]
            if not ok:
                lines.append(self.txt(self.t("try_again"), 14))
                if ls["wrong_once"]:
                    if st["t"] == "fill":
                        lines.append(self.txt(f"{self.t('answer')}: {st['a'][0]}", 14, W7, font=MONO))
                    elif st["t"] == "try":
                        lines.append(self.txt(f"💡 {self.tr(st['hint'])}", 14, W7, font=MONO))
                    elif st.get("e"):
                        lines.append(self.txt(self.tr(st["e"]), 14))
            elif st.get("e"):
                lines.append(self.txt(self.tr(st["e"]), 14))
            foot.append(ft.Container(ft.Row([self.avatar("🤖" if ok else "🤔", 46),
                                             ft.Column(lines, spacing=4, expand=True)], spacing=12,
                                            vertical_alignment=ft.CrossAxisAlignment.START),
                                     bgcolor=c["good_bg"] if ok else c["bad_bg"], border_radius=18, padding=14))

        if st["t"] == "read" or ls["status"] == "ok":
            action = self.btn(self.t("next"), lambda e: self.next_step(), "good" if ls["status"] == "ok" else "primary",
                              expand=True, height=56)
            ls["enter"] = self.next_step
        else:
            can = {"quiz": ls["sel"] is not None, "fill": bool(ls["input"].strip()), "try": True}[st["t"]]
            check_btn = self.btn(self.t("check"), lambda e: self.check(), expand=True, disabled=not can, height=56)
            action = check_btn
            ls["enter"] = lambda: self.check() if not check_btn.disabled else None
        foot.append(ft.Row([action]))

        return wrap(ft.Column([top, ft.Column(body, spacing=16, scroll=ft.ScrollMode.AUTO, expand=True),
                               ft.Divider(height=1, color=c["line"]), *foot], spacing=12, expand=True))

    def view_done(self):
        c, ls = self.c, self.ls
        l, course = ls["l"], ls["c"]
        if ls["result"] is None:
            ls["result"] = self.finish_lesson(l, ls["mistakes"] == 0, ls["best"]) or {
                "xp": 0, "gems": 0, "first": False, "perfect": False, "level_up": False, "level": level_of(self.st["xp"])}
        r = ls["result"]
        nx = self.next_lesson(course)
        trophy = ft.Container(ft.Text("🏆" if r["perfect"] else "🎉", size=60), width=128, height=128, border_radius=36,
                              alignment=ft.alignment.center,
                              gradient=ft.LinearGradient(colors=[c["sky"], c["blue"]]),
                              shadow=ft.BoxShadow(blur_radius=0, offset=ft.Offset(0, 8), color=c["deep"]),
                              scale=0.5, animate_scale=ft.Animation(600, ft.AnimationCurve.ELASTIC_OUT))

        def reward(icon, value, label, bg):
            return ft.Container(ft.Column([self.txt(icon, 22), self.txt(value, 22, W8, font=DISPLAY),
                                           self.txt(label, 11, W8, c["muted"])], spacing=2,
                                          horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                                bgcolor=bg, border_radius=18, padding=12, expand=True)

        rewards = ft.Row([reward("⚡", f"+{r['xp']}", "XP", c["ice"]),
                          reward("💎", f"+{r['gems']}", self.t("gems"), c["gold_bg"]),
                          reward("🔥", f"x{ls['best']}", self.t("combo"), c["surface2"])], spacing=10)
        extras = []
        if r["perfect"]:
            extras.append(self.chip(f"🎯 {self.t('perfect')}", c["good_bg"], c["good"], c["good_bg"]))
        if r["level_up"]:
            extras.append(self.chip(f"⬆ {self.t('level_up')} {r['level']}", c["gold_bg"], c["gold"], c["gold"]))
        if not r["first"]:
            extras.append(self.chip(self.t("review")))
        buttons = []
        if nx:
            buttons.append(ft.Row([self.btn(f"▶  {self.tr(nx['title'])}", lambda e, lid=nx["id"]: self.open_lesson(lid),
                                            expand=True, height=56)]))
        buttons.append(ft.Row([self.btn(self.t("back"), self.close_lesson, "ghost", expand=True)]))
        ls["enter"] = (lambda: self.open_lesson(nx["id"])) if nx else self.close_lesson

        def pop():
            try:
                trophy.scale = 1
                trophy.update()
            except Exception:
                pass
        threading.Timer(0.15, pop).start()

        return ft.Container(ft.Column([
            trophy, self.title(self.t("lesson_done"), 26),
            self.txt(random.choice(self.t("praise")) + " " + self.tr(l["title"]), 15, W6, c["muted"]),
            rewards, ft.Row(extras, wrap=True, alignment=ft.MainAxisAlignment.CENTER), *buttons,
        ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, alignment=ft.MainAxisAlignment.CENTER, spacing=16,
            scroll=ft.ScrollMode.AUTO), expand=True, alignment=ft.alignment.center)

    def pick_option(self, k):
        self.ls["sel"] = k
        self.ls["status"] = None
        self.render()

    def format_run(self, out, err):
        if err == "timeout":
            out += f"\n⚠ {self.t('timeout')}"
        elif err:
            out += f"\n⚠ {self.t('error')}: {err}"
        return out.strip()

    def check(self):
        ls = self.ls
        st = ls["l"]["steps"][ls["i"]]
        ok = False
        if st["t"] == "quiz":
            ok = ls["sel"] == st["a"]
        elif st["t"] == "fill":
            ok = ls["input"].strip().lower() in [a.lower() for a in st["a"]]
        elif st["t"] == "try":
            output = ""
            if st["mode"] == "py":
                output, err = run_python(ls["code"])
                ls["out"] = self.format_run(output, err)
                if err:
                    output = ""
            ok = bool(st["check"](ls["code"], output))
        if ok:
            ls["status"] = "ok"
            ls["combo"] += 1
            ls["best"] = max(ls["best"], ls["combo"])
            ls["say"] = random.choice(self.t("praise")) + (f"  🔥 x{ls['combo']}" if ls["combo"] >= 2 else "")
        else:
            if ls["status"] == "no" or st["t"] == "quiz":
                ls["wrong_once"] = True
            ls["status"] = "no"
            ls["combo"] = 0
            ls["mistakes"] += 1
            ls["say"] = random.choice(self.t("cheer"))
        self.render()

    def next_step(self):
        self.ls.update({"i": self.ls["i"] + 1, "sel": None, "status": None, "input": "", "code": None,
                        "out": None, "wrong_once": False, "say": ""})
        self.render()


def main(page: ft.Page):
    Kodla(page)


if __name__ == "__main__":
    if "--web" in sys.argv:
        from server import lan_ip
        print(f"Telefonlar uchun / Для телефонов:  http://{lan_ip()}:{WEB_PORT}")
        ft.app(target=main, view=ft.AppView.WEB_BROWSER, host="0.0.0.0", port=WEB_PORT)
    else:
        ft.app(target=main)
