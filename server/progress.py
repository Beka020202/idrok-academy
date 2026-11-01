"""O‘yin qoidalari — ilovadagi app/lib/progress.dart bilan bir xil bo‘lishi shart.
Правила игры — должны совпадать с app/lib/progress.dart.

Yagona valyuta — XP / единственная валюта — XP:
  xp        — joriy balans (do‘kon va AI yordamchiga sarflanadi) / текущий баланс
  xp_total  — jami ishlab topilgan (daraja shundan) / всего заработано (от него уровень)
Reyting davr ichida ISHLAB TOPILGAN XP bo‘yicha (xp_log), sarflash o‘rinni tushirmaydi.
Рейтинг — по ЗАРАБОТАННОМУ за период XP (xp_log), траты не снижают место.
"""

from datetime import date, timedelta

GOAL = 30
REVIEW_XP = 5
PERFECT_XP = 5
CHEST_XP = 50
PLACEMENT_XP = 20
HELPER_COST = 5
KEEP_DAYS = 60
MAX_RETRY = 2
LEAGUES = ["beginner", "advanced", "master"]

QUESTS = [
    {"id": "xp", "target": 30, "reward": 10, "title": {"uz": "30 XP to‘plang", "ru": "Наберите 30 XP"}},
    {"id": "lessons", "target": 2, "reward": 10, "title": {"uz": "2 ta dars o‘ting", "ru": "Пройдите 2 урока"}},
    {"id": "combo", "target": 3, "reward": 15, "title": {"uz": "Ketma-ket 3 ta to‘g‘ri javob", "ru": "3 верных ответа подряд"}},
]


def today_str():
    return date.today().isoformat()


def _day_before(day):
    return (date.fromisoformat(day) - timedelta(days=1)).isoformat()


def empty_state():
    return {"xp": 0, "xp_total": 0, "done": {}, "streak": 0, "last_day": "", "today_xp": 0, "today_date": "",
            "days": [], "chests": [], "perfect": 0, "league": "", "retries": {},
            "stats": {"attempts": 0, "correct": 0, "total": 0, "time_share": 0.0},
            "quests": {"date": "", "xp": 0, "lessons": 0, "combo": 0, "claimed": []}}


def normalize(state, today=None):
    """Eski holatni to‘ldiradi, yangi kunda kunlik ko‘rsatkichlarni yangilaydi."""
    today = today or today_str()
    raw = dict(state or {})
    s = empty_state()
    for k, v in raw.items():
        if k in s:
            s[k] = v
    # eski versiyadan ko‘chirish: xp_total yo‘q bo‘lsa — xp dan / миграция со старой версии
    if "xp_total" not in raw:
        s["xp_total"] = int(raw.get("xp", 0) or 0)
    s["xp"] = max(0, int(s["xp"] or 0))
    s["xp_total"] = max(int(s["xp_total"] or 0), 0)
    q = dict(empty_state()["quests"])
    q.update(s.get("quests") or {})
    s["quests"] = q
    st = dict(empty_state()["stats"])
    st.update(s.get("stats") or {})
    s["stats"] = st
    if not isinstance(s["retries"], dict):
        s["retries"] = {}
    if s["league"] not in LEAGUES:
        s["league"] = ""
    if s["today_date"] != today:
        s["today_xp"], s["today_date"] = 0, today
    if q["date"] != today:
        s["quests"] = {"date": today, "xp": 0, "lessons": 0, "combo": 0, "claimed": []}
    if s["last_day"] and s["last_day"] not in (today, _day_before(today)):
        s["streak"] = 0
    return s


def earn(s, amount, quest=True):
    """XP qo‘shish (balans ham, jami ham) / начислить XP (и баланс, и всего)."""
    amount = max(0, int(amount))
    s["xp"] += amount
    s["xp_total"] += amount
    s["today_xp"] += amount
    if quest:
        s["quests"]["xp"] += amount
    return amount


def complete_lesson(state, lesson_id, lesson_xp, perfect=False, best_combo=0, correct=0, total=0, time_share=1.0,
                    today=None):
    """Dars tugadi. Qaytaradi: (holat, natija). / Урок завершён. Возвращает: (состояние, результат)."""
    today = today or today_str()
    s = normalize(state, today)
    level_before = level_of(s["xp_total"])
    first = not s["done"].get(lesson_id)
    xp = lesson_xp if first else REVIEW_XP
    if perfect:
        xp += PERFECT_XP
        s["perfect"] += 1
    earn(s, xp)
    s["done"][lesson_id] = True
    s["retries"].pop(lesson_id, None)
    q = s["quests"]
    q["lessons"] += 1
    q["combo"] = max(q["combo"], int(best_combo or 0))
    st = s["stats"]
    st["attempts"] += 1
    st["correct"] += max(0, int(correct))
    st["total"] += max(0, int(total))
    st["time_share"] = round(float(st["time_share"]) + max(0.0, min(1.0, float(time_share))), 4)
    if s["last_day"] != today:
        s["streak"] = s["streak"] + 1 if s["last_day"] == _day_before(today) else 1
        s["last_day"] = today
    if today not in s["days"]:
        s["days"] = (s["days"] + [today])[-KEEP_DAYS:]
    result = {"xp": xp, "first": first, "perfect": bool(perfect),
              "level_up": level_of(s["xp_total"]) > level_before, "level": level_of(s["xp_total"])}
    return s, result


def quest_progress(state, quest):
    return min(state["quests"].get(quest["id"], 0), quest["target"])


def claim_quest(state, quest_id):
    """Bajarilgan vazifa mukofoti (XP). Qaytaradi: (holat, XP yoki 0)."""
    s = normalize(state)
    quest = next((q for q in QUESTS if q["id"] == quest_id), None)
    if not quest or quest_id in s["quests"]["claimed"] or quest_progress(s, quest) < quest["target"]:
        return s, 0
    s["quests"]["claimed"].append(quest_id)
    return s, earn(s, quest["reward"], quest=False)


def open_chest(state, course_id, lesson_ids):
    """Kurs to‘liq tugaganda sandiq (XP). / Сундук за пройденный курс (XP)."""
    s = normalize(state)
    if not lesson_ids or course_id in s["chests"] or not all(s["done"].get(l) for l in lesson_ids):
        return s, 0
    s["chests"].append(course_id)
    return s, earn(s, CHEST_XP, quest=False)


def spend(state, amount):
    """XP sarflash (faqat balansdan). Qaytaradi: (holat, muvaffaqiyatmi)."""
    s = normalize(state)
    amount = int(amount)
    if amount <= 0 or s["xp"] < amount:
        return s, False
    s["xp"] -= amount
    return s, True


def set_league(state, league):
    """Birinchi marta liga belgilash (+ isinish uchun XP). / Первое назначение лиги."""
    s = normalize(state)
    if s["league"] or league not in LEAGUES:
        return s, 0
    s["league"] = league
    return s, earn(s, PLACEMENT_XP, quest=False)


def cancel_test(state, lesson_id):
    """Test bekor qilindi — keyingi urinish qiyinroq. / Тест отменён — следующая попытка сложнее."""
    s = normalize(state)
    s["retries"][lesson_id] = min(int(s["retries"].get(lesson_id, 0)) + 1, MAX_RETRY)
    return s


def promote(state):
    s = normalize(state)
    i = LEAGUES.index(s["league"]) if s["league"] in LEAGUES else 0
    if i < len(LEAGUES) - 1:
        s["league"] = LEAGUES[i + 1]
        return s, True
    return s, False


def level_of(xp_total):
    return xp_total // 100 + 1
