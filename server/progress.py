"""O‘yin qoidalari: XP, olmoslar, kunlik vazifalar, sandiqlar, avatarlar, ketma-ket kunlar.
Ilova ham, server ham shu fayldan foydalanadi.
Правила игры: XP, кристаллы, ежедневные задания, сундуки, аватары, серия дней.
Этот файл используют и приложение, и сервер."""

from datetime import date, timedelta

GOAL = 30            # kunlik maqsad / цель дня, XP
REVIEW_XP = 5        # takrorlash uchun / за повторение
LESSON_GEMS = 10     # birinchi marta tugatish / первое прохождение
PERFECT_GEMS = 5     # xatosiz dars / урок без ошибок
PERFECT_XP = 5
CHEST_GEMS = 50      # kurs tugaganda sandiq / сундук за курс
KEEP_DAYS = 60

# Kunlik vazifalar / Ежедневные задания: id, maqsad, mukofot (olmos)
QUESTS = [
    {"id": "xp", "target": 30, "gems": 15, "icon": "⚡",
     "title": {"uz": "30 XP to‘plang", "ru": "Наберите 30 XP"}},
    {"id": "lessons", "target": 2, "gems": 15, "icon": "📙",
     "title": {"uz": "2 ta dars o‘ting", "ru": "Пройдите 2 урока"}},
    {"id": "combo", "target": 3, "gems": 20, "icon": "🔥",
     "title": {"uz": "Ketma-ket 3 ta to‘g‘ri javob", "ru": "3 верных ответа подряд"}},
]

# Avatar do‘koni / Магазин аватаров: belgi -> narx
AVATARS = {"🤖": 0, "🦊": 40, "🐼": 40, "🐯": 60, "🦉": 60, "🐙": 80, "🦄": 100, "🐲": 150, "🚀": 200, "👑": 300}


def today_str():
    return date.today().isoformat()


def _day_before(day):
    return (date.fromisoformat(day) - timedelta(days=1)).isoformat()


def empty_state():
    return {"xp": 0, "done": {}, "streak": 0, "last_day": "", "today_xp": 0, "today_date": "", "days": [],
            "gems": 0, "avatar": "🤖", "owned": ["🤖"], "chests": [], "perfect": 0,
            "quests": {"date": "", "xp": 0, "lessons": 0, "combo": 0, "claimed": []}}


def normalize(state, today=None):
    """Eski holatni to‘ldiradi, yangi kunda kunlik ko‘rsatkichlarni yangilaydi."""
    today = today or today_str()
    s = empty_state()
    for k, v in (state or {}).items():
        s[k] = v
    q = dict(empty_state()["quests"])
    q.update(s.get("quests") or {})
    s["quests"] = q
    if s["today_date"] != today:
        s["today_xp"], s["today_date"] = 0, today
    if q["date"] != today:
        s["quests"] = {"date": today, "xp": 0, "lessons": 0, "combo": 0, "claimed": []}
    if s["last_day"] and s["last_day"] not in (today, _day_before(today)):
        s["streak"] = 0
    if s["avatar"] not in s["owned"]:
        s["avatar"] = "🤖"
    return s


def complete_lesson(state, lesson_id, lesson_xp, perfect=False, best_combo=0, today=None):
    """Dars tugadi. Qaytaradi: (holat, natija lug‘ati).
    Урок завершён. Возвращает: (состояние, словарь результата)."""
    today = today or today_str()
    s = normalize(state, today)
    level_before = level_of(s["xp"])
    first = not s["done"].get(lesson_id)
    xp = lesson_xp if first else REVIEW_XP
    gems = LESSON_GEMS if first else 0
    if perfect:
        xp += PERFECT_XP
        gems += PERFECT_GEMS
        s["perfect"] += 1
    s["xp"] += xp
    s["gems"] += gems
    s["today_xp"] += xp
    s["done"][lesson_id] = True
    q = s["quests"]
    q["xp"] += xp
    q["lessons"] += 1
    q["combo"] = max(q["combo"], int(best_combo or 0))
    if s["last_day"] != today:
        s["streak"] = s["streak"] + 1 if s["last_day"] == _day_before(today) else 1
        s["last_day"] = today
    if today not in s["days"]:
        s["days"] = (s["days"] + [today])[-KEEP_DAYS:]
    result = {"xp": xp, "gems": gems, "first": first, "perfect": bool(perfect),
              "level_up": level_of(s["xp"]) > level_before, "level": level_of(s["xp"])}
    return s, result


def quest_progress(state, quest):
    return min(state["quests"].get(quest["id"], 0), quest["target"])


def claim_quest(state, quest_id):
    """Bajarilgan vazifa mukofotini oladi. Qaytaradi: (holat, olmos yoki 0)."""
    s = normalize(state)
    quest = next((q for q in QUESTS if q["id"] == quest_id), None)
    if not quest or quest_id in s["quests"]["claimed"] or quest_progress(s, quest) < quest["target"]:
        return s, 0
    s["quests"]["claimed"].append(quest_id)
    s["gems"] += quest["gems"]
    return s, quest["gems"]


def open_chest(state, course_id, lesson_ids):
    """Kurs to‘liq tugaganda sandiqni ochadi. Qaytaradi: (holat, olmos yoki 0)."""
    s = normalize(state)
    if course_id in s["chests"] or not all(s["done"].get(l) for l in lesson_ids):
        return s, 0
    s["chests"].append(course_id)
    s["gems"] += CHEST_GEMS
    return s, CHEST_GEMS


def buy_avatar(state, avatar):
    """Avatar sotib olish yoki tanlash. Qaytaradi: (holat, muvaffaqiyatmi)."""
    s = normalize(state)
    if avatar not in AVATARS:
        return s, False
    if avatar not in s["owned"]:
        if s["gems"] < AVATARS[avatar]:
            return s, False
        s["gems"] -= AVATARS[avatar]
        s["owned"].append(avatar)
    s["avatar"] = avatar
    return s, True


def last_week(state, today=None):
    """Oxirgi 7 kun: [(sana, faolmi), ...]."""
    today = date.fromisoformat(today or today_str())
    active = set(state.get("days", []))
    return [((today - timedelta(days=b)).isoformat(), (today - timedelta(days=b)).isoformat() in active)
            for b in range(6, -1, -1)]


def level_of(xp):
    return xp // 100 + 1
