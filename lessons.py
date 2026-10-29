"""Kodla — dars mazmuni, interfeys matnlari va kodni tekshirish.
Kodla — содержание уроков, тексты интерфейса и проверка кода."""

import re
import threading


def L(uz, ru):
    return {"uz": uz, "ru": ru}


# ---------------------------------------------------------------- UI matnlari
T = {
    "uz": {
        "home": "Asosiy", "courses": "Kurslar", "play": "Mashq", "profile": "Profil",
        "hello": "Salom", "hero": "Har kuni 5 daqiqa — va kod yozishni o‘rganasiz. Cheklovsiz, bepul.",
        "goal": "Kunlik maqsad", "cont": "Davom etish", "start": "Boshlash",
        "lessons": "dars", "free": "Cheklov yo‘q",
        "free_text": "Energiya yoki yuraklar yo‘q. Xohlagancha dars o‘ting.",
        "unit": "Bo‘lim", "locked": "Avval oldingi darsni tugating", "completed": "Tugatildi",
        "now": "Hozirgi dars", "check": "Tekshirish", "next": "Davom etish",
        "right": "To‘g‘ri!", "wrong": "Unchalik emas", "try_again": "Qayta urinib ko‘ring",
        "answer": "To‘g‘ri javob", "read": "NAZARIYA", "quiz": "SAVOL", "fill": "BO‘SH JOYNI TO‘LDIRING",
        "try": "AMALIYOT", "run": "Ishga tushirish", "output": "Natija",
        "lesson_done": "Dars tugadi!", "back": "Kurslarga qaytish", "your_code": "Sizning kodingiz",
        "play_title": "Python maydoni", "play_text": "Python kodini yozing va «Ishga tushirish»ni bosing.",
        "inputs": "input() uchun qiymatlar (har biri yangi qatorda)",
        "level": "Daraja", "streak": "Kun ketma-ket", "name": "Ismingiz",
        "badges": "Yutuqlar", "reset": "Progressni o‘chirish",
        "reset_q": "Barcha XP va darslar o‘chiriladi. Ishonchingiz komilmi?",
        "yes": "Ha, o‘chirish", "no": "Bekor qilish", "type_here": "javob",
        "b1": "Birinchi dars", "b2": "100 XP", "b3": "3 kun", "b4": "Kurs tugadi",
        "review": "Takrorlash uchun +5 XP", "hint": "Maslahat", "timeout": "Kod juda uzoq ishladi (cheksiz sikl?)",
        "error": "Xato", "empty_out": "(hech narsa chiqarilmadi)",
        "login_title": "Xush kelibsiz!", "login_sub": "Darslarni davom ettirish uchun kiring.",
        "username": "Login", "password": "Parol", "server": "Server manzili",
        "login_btn": "Kirish", "register_btn": "Ro‘yxatdan o‘tish",
        "no_account": "Akkauntingiz yo‘qmi? Ro‘yxatdan o‘ting", "have_account": "Akkauntingiz bormi? Kiring",
        "offline": "Serversiz davom etish", "logout": "Chiqish",
        "ranking": "Reyting", "teacher": "Ustoz", "students": "o‘quvchi", "you": "siz",
        "last_active": "Oxirgi faollik", "never": "hali yo‘q", "refresh": "Yangilash",
        "week": "Bu hafta", "days_short": ["Du", "Se", "Ch", "Pa", "Ju", "Sh", "Ya"],
        "err_conn": "Serverga ulanib bo‘lmadi. Manzilni tekshiring va server ishlayotganiga ishonch hosil qiling.",
        "err_auth": "Login yoki parol noto‘g‘ri.", "err_taken": "Bu login band. Boshqasini tanlang.",
        "err_short": "Login kamida 3 ta, parol kamida 4 ta belgidan iborat bo‘lsin.",
        "online": "Serverga ulangan", "offline_mode": "Oflayn rejim",
        "rank_empty": "Hali hech kim dars o‘tmagan. Birinchi bo‘ling!",
        "rank_offline": "Reyting faqat serverga ulanganda ishlaydi.",
        "teacher_sub": "O‘quvchilar natijalari", "total_xp": "Jami XP",
        "light": "Yorug‘", "dark": "Qorong‘i", "theme": "Mavzu",
        "adventure": "Sarguzasht", "quests": "Kunlik vazifalar", "claim": "Olish", "claimed": "Olindi",
        "gems": "Olmos", "shop": "Avatar do‘koni", "equip": "Tanlash", "equipped": "Tanlangan",
        "not_enough": "Olmos yetarli emas. Dars o‘tib, vazifalarni bajaring!",
        "combo": "Kombo", "perfect": "Xatosiz dars!", "perfect_n": "Xatosiz darslar",
        "level_up": "Yangi daraja!", "chest": "Xazina sandig‘i", "chest_open": "Sandiqni ochish",
        "chest_locked": "Kursni tugating — sandiq ochiladi", "chest_done": "Ochilgan",
        "next_level": "keyingi darajagacha", "best_combo": "Eng yaxshi kombo",
        "play_now": "O‘ynash", "boss": "Bosqich",
        "mascot_name": "Kodi",
        "tips": ["Bugun bitta dars — ertaga o‘nta! Boshladikmi? 🚀", "Xato qilish — o‘rganishning bir qismi. Qo‘rqma!",
                 "Ketma-ket to‘g‘ri javoblar kombo beradi. 🔥", "Xatosiz dars uchun qo‘shimcha olmos bor! 💎",
                 "Olmoslarga yangi avatar sotib ol! 🦊", "Python olimpiadada eng mashhur til. 🐍",
                 "Kurs oxiridagi sandiqda 50 ta olmos kutmoqda! 🎁"],
        "praise": ["Zo‘r!", "Ajoyib!", "Barakalla!", "Davom et!", "Sen dahosan!", "Aynan shunday!"],
        "cheer": ["Hechqisi yo‘q, yana urin!", "Deyarli to‘g‘ri!", "Shoshilma, qaytadan o‘qi."],
    },
    "ru": {
        "home": "Главная", "courses": "Курсы", "play": "Практика", "profile": "Профиль",
        "hello": "Привет", "hero": "5 минут в день — и вы научитесь писать код. Без ограничений, бесплатно.",
        "goal": "Цель дня", "cont": "Продолжить", "start": "Начать",
        "lessons": "уроков", "free": "Без ограничений",
        "free_text": "Никакой энергии и сердечек. Проходите сколько хотите.",
        "unit": "Раздел", "locked": "Сначала пройдите предыдущий урок", "completed": "Пройдено",
        "now": "Текущий урок", "check": "Проверить", "next": "Продолжить",
        "right": "Верно!", "wrong": "Не совсем", "try_again": "Попробуйте ещё раз",
        "answer": "Правильный ответ", "read": "ТЕОРИЯ", "quiz": "ВОПРОС", "fill": "ЗАПОЛНИТЕ ПРОПУСК",
        "try": "ПРАКТИКА", "run": "Запустить", "output": "Результат",
        "lesson_done": "Урок пройден!", "back": "Вернуться к курсам", "your_code": "Ваш код",
        "play_title": "Песочница Python", "play_text": "Напишите код на Python и нажмите «Запустить».",
        "inputs": "Значения для input() (каждое с новой строки)",
        "level": "Уровень", "streak": "Дней подряд", "name": "Ваше имя",
        "badges": "Достижения", "reset": "Сбросить прогресс",
        "reset_q": "Все XP и уроки будут удалены. Вы уверены?",
        "yes": "Да, сбросить", "no": "Отмена", "type_here": "ответ",
        "b1": "Первый урок", "b2": "100 XP", "b3": "3 дня", "b4": "Курс пройден",
        "review": "+5 XP за повторение", "hint": "Подсказка", "timeout": "Код работал слишком долго (бесконечный цикл?)",
        "error": "Ошибка", "empty_out": "(ничего не выведено)",
        "login_title": "Добро пожаловать!", "login_sub": "Войдите, чтобы продолжить уроки.",
        "username": "Логин", "password": "Пароль", "server": "Адрес сервера",
        "login_btn": "Войти", "register_btn": "Зарегистрироваться",
        "no_account": "Нет аккаунта? Зарегистрируйтесь", "have_account": "Уже есть аккаунт? Войдите",
        "offline": "Продолжить без сервера", "logout": "Выйти",
        "ranking": "Рейтинг", "teacher": "Учитель", "students": "учеников", "you": "вы",
        "last_active": "Последняя активность", "never": "ещё нет", "refresh": "Обновить",
        "week": "Эта неделя", "days_short": ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"],
        "err_conn": "Не удалось подключиться к серверу. Проверьте адрес и что сервер запущен.",
        "err_auth": "Неверный логин или пароль.", "err_taken": "Этот логин занят. Выберите другой.",
        "err_short": "Логин — минимум 3 символа, пароль — минимум 4.",
        "online": "Подключено к серверу", "offline_mode": "Офлайн-режим",
        "rank_empty": "Пока никто не прошёл урок. Будьте первым!",
        "rank_offline": "Рейтинг работает только при подключении к серверу.",
        "teacher_sub": "Результаты учеников", "total_xp": "Всего XP",
        "light": "Светлая", "dark": "Тёмная", "theme": "Тема",
        "adventure": "Приключение", "quests": "Задания дня", "claim": "Забрать", "claimed": "Получено",
        "gems": "Кристаллы", "shop": "Магазин аватаров", "equip": "Выбрать", "equipped": "Выбран",
        "not_enough": "Не хватает кристаллов. Проходите уроки и выполняйте задания!",
        "combo": "Комбо", "perfect": "Урок без ошибок!", "perfect_n": "Уроков без ошибок",
        "level_up": "Новый уровень!", "chest": "Сундук с сокровищами", "chest_open": "Открыть сундук",
        "chest_locked": "Пройдите курс — сундук откроется", "chest_done": "Открыт",
        "next_level": "до следующего уровня", "best_combo": "Лучшее комбо",
        "play_now": "Играть", "boss": "Этап",
        "mascot_name": "Коди",
        "tips": ["Сегодня один урок — завтра десять! Начнём? 🚀", "Ошибки — часть обучения. Не бойся!",
                 "Верные ответы подряд дают комбо. 🔥", "За урок без ошибок — бонусные кристаллы! 💎",
                 "Купи новый аватар за кристаллы! 🦊", "Python — самый популярный язык на олимпиадах. 🐍",
                 "В сундуке в конце курса ждут 50 кристаллов! 🎁"],
        "praise": ["Отлично!", "Супер!", "Молодец!", "Так держать!", "Ты гений!", "Именно так!"],
        "cheer": ["Ничего, попробуй ещё!", "Почти верно!", "Не спеши, перечитай."],
    },
}


# ---------------------------------------------------------------- Python ishga tushirish
# O‘quvchi kodi ustoz kompyuterida ishlaydi, shuning uchun fayl va tizimga
# kirish yopilgan: open, eval, exec, os va boshqalar yo‘q.
# Код ученика выполняется на компьютере учителя, поэтому доступ к файлам и
# системе закрыт: нет open, eval, exec, os и т.п.
import builtins as _b

_ALLOWED = ("abs all any bool chr dict divmod enumerate filter float format frozenset hex int isinstance "
            "issubclass iter len list map max min next oct ord pow range repr reversed round set slice "
            "sorted str sum tuple type zip object super __build_class__ Exception ValueError TypeError IndexError "
            "KeyError ZeroDivisionError StopIteration NameError ArithmeticError").split()
SAFE_BUILTINS = {name: getattr(_b, name) for name in _ALLOWED}
SAFE_MODULES = {"math", "random", "string", "itertools", "collections", "statistics", "fractions", "decimal"}


def _safe_import(name, globals=None, locals=None, fromlist=(), level=0):
    if name.split(".")[0] not in SAFE_MODULES:
        raise ImportError(f"'{name}' moduli ruxsat etilmagan / модуль '{name}' не разрешён")
    return __import__(name, globals, locals, fromlist, level)


def run_python(code, inputs=None, timeout=3.0):
    """Python kodini bajaradi va (chiqish, xato) qaytaradi.
    Выполняет код Python и возвращает (вывод, ошибка)."""
    out = []
    result = {}
    feed = iter(inputs or [])

    def _print(*args, sep=" ", end="\n", **_):
        out.append(sep.join(str(a) for a in args) + end)

    def _input(prompt=""):
        out.append(str(prompt))
        try:
            value = next(feed)
        except StopIteration:
            value = "Ali"
        out.append(value + "\n")
        return value

    def target():
        safe = dict(SAFE_BUILTINS)
        safe.update(print=_print, input=_input, __import__=_safe_import)
        env = {"__name__": "__main__", "__builtins__": safe}
        try:
            exec(compile(code, "<kod>", "exec"), env)
        except Exception as exc:  # noqa: BLE001 — o‘quvchi xatosini ko‘rsatamiz
            result["err"] = f"{type(exc).__name__}: {exc}"

    th = threading.Thread(target=target, daemon=True)
    th.start()
    th.join(timeout)
    if th.is_alive():
        return "".join(out), "timeout"
    return "".join(out), result.get("err")


def _has(pattern, code, flags=re.I):
    return re.search(pattern, code, flags) is not None


# ---------------------------------------------------------------- kurslar
# step turlari: read | quiz | fill | try
# try: mode "html"/"css"/"js" — kod qoidaga mosligi tekshiriladi;
#      mode "py" — kod haqiqatan bajariladi va natijasi tekshiriladi.
# check(code, output) -> bool

COURSES = [
    {"id": "html", "tag": "</>", "color": "#E8622C", "name": L("HTML", "HTML"),
     "sub": L("Veb-sahifa tuzilishi", "Структура веб-страницы"), "lessons": [
        {"id": "html1", "xp": 15, "title": L("Birinchi sahifa", "Первая страница"), "steps": [
            {"t": "read", "h": L("HTML nima?", "Что такое HTML?"),
             "p": L("HTML — veb-sahifaning skeleti. U teglardan iborat: ochuvchi <p> va yopuvchi </p>. Ular orasidagi matn sahifada ko‘rinadi.",
                    "HTML — это скелет веб-страницы. Он состоит из тегов: открывающего <p> и закрывающего </p>. Текст между ними видно на странице."),
             "code": "<h1>Salom, dunyo!</h1>\n<p>Bu mening birinchi sahifam.</p>"},
            {"t": "quiz", "q": L("Qaysi teg eng katta sarlavhani yaratadi?", "Какой тег создаёт самый крупный заголовок?"),
             "o": ["<h1>", "<h6>", "<p>", "<head>"], "a": 0, "mono": True,
             "e": L("<h1> — eng muhim va eng katta sarlavha. <h6> esa eng kichigi.", "<h1> — самый важный и крупный заголовок. <h6> — самый маленький.")},
            {"t": "quiz", "q": L("Yopuvchi teg qanday yoziladi?", "Как пишется закрывающий тег?"),
             "o": ["</p>", "<p/>", "<\\p>", "(p)"], "a": 0, "mono": True,
             "e": L("Yopuvchi teg nomidan oldin / belgisi qo‘yiladi.", "В закрывающем теге перед именем ставится /.")},
            {"t": "try", "mode": "html",
             "task": L("<h1> ichiga ismingizni yozing.", "Напишите своё имя внутри <h1>."),
             "start": "<h1></h1>\n<p>Men dasturlashni o‘rganyapman.</p>",
             "check": lambda c, o: _has(r"<h1>\s*[^<\s][^<]*</h1>", c),
             "hint": L("<h1>Aziza</h1>", "<h1>Азиза</h1>")},
        ]},
        {"id": "html2", "xp": 15, "title": L("Havola va rasm", "Ссылки и картинки"), "steps": [
            {"t": "read", "h": L("Havola va rasm", "Ссылки и картинки"),
             "p": L("<a> — havola. Manzil href atributiga yoziladi. <img> — rasm: manba src ga, tavsif alt ga. <img> yopuvchi tegga ega emas.",
                    "<a> — ссылка. Адрес пишется в атрибут href. <img> — картинка: источник в src, описание в alt. У <img> нет закрывающего тега."),
             "code": '<a href="https://uz.wikipedia.org">Vikipediya</a>\n<img src="mushuk.png" alt="Mushuk">'},
            {"t": "quiz", "q": L("Havola manzili qaysi atributga yoziladi?", "В какой атрибут пишется адрес ссылки?"),
             "o": ["href", "src", "alt", "link"], "a": 0, "mono": True,
             "e": L("href — havola manzili.", "href — адрес ссылки.")},
            {"t": "fill", "q": L("Rasm faylini ko‘rsating:", "Укажите файл картинки:"),
             "pre": "<img ", "post": '="rasm.png" alt="Mushuk">', "a": ["src"],
             "e": L("Rasm manbasi src atributida bo‘ladi.", "Источник картинки задаётся в атрибуте src.")},
            {"t": "try", "mode": "html",
             "task": L("https://uz.wikipedia.org saytiga istalgan matnli havola yarating.", "Создайте ссылку с любым текстом на https://uz.wikipedia.org."),
             "start": "<p>Foydali sayt:</p>\n",
             "check": lambda c, o: _has(r"<a\s+[^>]*href\s*=\s*[\"']https?://[^\"']+[\"'][^>]*>\s*[^<\s][^<]*</a>", c),
             "hint": L('<a href="https://uz.wikipedia.org">Vikipediya</a>', '<a href="https://uz.wikipedia.org">Википедия</a>')},
        ]},
        {"id": "html3", "xp": 15, "title": L("Ro‘yxatlar", "Списки"), "steps": [
            {"t": "read", "h": L("Ro‘yxatlar", "Списки"),
             "p": L("<ul> — belgili ro‘yxat, <ol> — raqamli ro‘yxat. Har bir element <li> ichida yoziladi.",
                    "<ul> — маркированный список, <ol> — нумерованный. Каждый пункт пишется внутри <li>."),
             "code": "<ul>\n  <li>Olma</li>\n  <li>Nok</li>\n</ul>"},
            {"t": "quiz", "q": L("Raqamli ro‘yxat uchun qaysi teg kerak?", "Какой тег нужен для нумерованного списка?"),
             "o": ["<ol>", "<ul>", "<li>", "<nl>"], "a": 0, "mono": True,
             "e": L("<ol> — «ordered list», tartiblangan ro‘yxat.", "<ol> — «ordered list», упорядоченный список.")},
            {"t": "try", "mode": "html",
             "task": L("Sevimli 3 ta faningiz bilan <ul> ro‘yxat tuzing.", "Составьте список <ul> из 3 любимых предметов."),
             "start": "<h2>Sevimli fanlarim</h2>\n<ul>\n  \n</ul>",
             "check": lambda c, o: _has(r"<ul>", c) and len(re.findall(r"<li>\s*[^<\s][^<]*</li>", c, re.I)) >= 3,
             "hint": L("<li>Matematika</li> — shunday 3 ta qator", "<li>Математика</li> — три такие строки")},
        ]},
    ]},
    {"id": "css", "tag": "{ }", "color": "#1F7BE8", "name": L("CSS", "CSS"),
     "sub": L("Sahifani bezash", "Оформление страницы"), "lessons": [
        {"id": "css1", "xp": 15, "title": L("Ranglar", "Цвета"), "steps": [
            {"t": "read", "h": L("CSS qoidasi", "Правило CSS"),
             "p": L("CSS sahifaga ko‘rinish beradi. Qoida: selektor, keyin { } ichida «xususiyat: qiymat;». color — matn rangi, background-color — fon rangi.",
                    "CSS задаёт внешний вид страницы. Правило: селектор, затем в { } «свойство: значение;». color — цвет текста, background-color — цвет фона."),
             "code": "h1 {\n  color: blue;\n  background-color: lightyellow;\n}"},
            {"t": "quiz", "q": L("Fon rangini qaysi xususiyat o‘zgartiradi?", "Какое свойство меняет цвет фона?"),
             "o": ["background-color", "color", "font-color", "bg"], "a": 0, "mono": True,
             "e": L("color faqat matnga ta’sir qiladi, fon uchun background-color.", "color влияет только на текст, для фона — background-color.")},
            {"t": "fill", "q": L("Paragraf matnini qizil qiling:", "Сделайте текст абзаца красным:"),
             "pre": "p { ", "post": ": red; }", "a": ["color"], "e": L("Matn rangi — color.", "Цвет текста — color.")},
            {"t": "try", "mode": "css",
             "task": L("h1 sarlavhasiga istalgan rang bering.", "Задайте заголовку h1 любой цвет."),
             "start": "h1 {\n  \n}",
             "check": lambda c, o: _has(r"h1\s*\{[^}]*\bcolor\s*:\s*[^;}\s]+", c),
             "hint": L("color: royalblue;", "color: royalblue;")},
        ]},
        {"id": "css2", "xp": 15, "title": L("Matn", "Текст"), "steps": [
            {"t": "read", "h": L("Matn bilan ishlash", "Работа с текстом"),
             "p": L("font-size — o‘lcham, font-weight — qalinlik, text-align — tekislash (left, center, right).",
                    "font-size — размер, font-weight — жирность, text-align — выравнивание (left, center, right)."),
             "code": "h1 {\n  font-size: 32px;\n  font-weight: bold;\n  text-align: center;\n}"},
            {"t": "quiz", "q": L("Matnni markazga qanday tekislaymiz?", "Как выровнять текст по центру?"),
             "o": ["text-align: center;", "align: middle;", "font-align: center;", "center: true;"], "a": 0, "mono": True,
             "e": L("text-align matnni gorizontal tekislaydi.", "text-align выравнивает текст по горизонтали.")},
            {"t": "fill", "q": L("Sarlavha o‘lchamini belgilang:", "Задайте размер заголовка:"),
             "pre": "h1 { font-", "post": ": 32px; }", "a": ["size"], "e": L("To‘liq nomi — font-size.", "Полное название — font-size.")},
            {"t": "try", "mode": "css",
             "task": L("p uchun font-size ni 22px qiling.", "Сделайте font-size у p равным 22px."),
             "start": "p {\n  \n}",
             "check": lambda c, o: _has(r"p\s*\{[^}]*font-size\s*:\s*\d+(\.\d+)?(px|rem|em|pt)", c),
             "hint": L("font-size: 22px;", "font-size: 22px;")},
        ]},
        {"id": "css3", "xp": 20, "title": L("Quti modeli", "Блочная модель"), "steps": [
            {"t": "read", "h": L("Har bir element — quti", "Каждый элемент — коробка"),
             "p": L("padding — kontent va chegara orasidagi ichki joy. border — chegara. margin — boshqa elementlardan tashqi masofa.",
                    "padding — внутренний отступ между содержимым и рамкой. border — рамка. margin — внешний отступ от других элементов."),
             "code": ".karta {\n  padding: 16px;\n  border: 2px solid blue;\n  margin: 20px;\n}"},
            {"t": "quiz", "q": L("Kontent va chegara orasidagi ichki joy qanday ataladi?", "Как называется внутренний отступ между содержимым и рамкой?"),
             "o": ["padding", "margin", "border", "gap"], "a": 0, "mono": True,
             "e": L("padding — ichki, margin — tashqi masofa.", "padding — внутренний, margin — внешний отступ.")},
            {"t": "quiz", "q": L("Qaysi yozuv to‘g‘ri?", "Какая запись правильная?"),
             "o": ["border: 2px solid blue;", "border: blue 2px line;", "border = 2px blue;", "border-all: 2px;"], "a": 0, "mono": True,
             "e": L("Tartib: qalinlik, uslub, rang.", "Порядок: толщина, стиль, цвет.")},
            {"t": "try", "mode": "css",
             "task": L(".karta ga padding va border qo‘shing.", "Добавьте .karta свойства padding и border."),
             "start": ".karta {\n  \n}",
             "check": lambda c, o: _has(r"\.karta\s*\{[^}]*padding\s*:", c) and _has(r"\.karta\s*\{[^}]*border\s*:", c),
             "hint": L("padding: 16px; border: 2px solid blue;", "padding: 16px; border: 2px solid blue;")},
        ]},
    ]},
    {"id": "js", "tag": "JS", "color": "#C99A00", "name": L("JavaScript", "JavaScript"),
     "sub": L("Sahifaga jon berish", "Оживляем страницу"), "lessons": [
        {"id": "js1", "xp": 15, "title": L("O‘zgaruvchilar", "Переменные"), "steps": [
            {"t": "read", "h": L("Ma’lumotni saqlash", "Храним данные"),
             "p": L("O‘zgaruvchi — qiymat saqlanadigan quti. let qiymatni keyin o‘zgartirishga ruxsat beradi, const esa yo‘q. console.log() qiymatni chiqaradi.",
                    "Переменная — коробка для значения. let позволяет потом менять значение, const — нет. console.log() выводит значение."),
             "code": 'let ism = "Ali";\nconst yil = 2026;\nconsole.log(ism, yil);'},
            {"t": "quiz", "q": L("Qaysi o‘zgaruvchini qayta o‘zgartirib bo‘lmaydi?", "Какую переменную нельзя переприсвоить?"),
             "o": ["const", "let", "var", "change"], "a": 0, "mono": True,
             "e": L("const — doimiy, uni qayta yozib bo‘lmaydi.", "const — константа, её нельзя переприсвоить.")},
            {"t": "fill", "q": L("O‘zgaruvchi e’lon qiling:", "Объявите переменную:"),
             "pre": "", "post": ' ism = "Ali";', "a": ["let", "const", "var"],
             "e": L("let, const yoki var bilan e’lon qilinadi.", "Объявляется через let, const или var.")},
            {"t": "try", "mode": "js",
             "task": L("yosh nomli o‘zgaruvchi yarating va uni console.log bilan chiqaring.", "Создайте переменную yosh и выведите её через console.log."),
             "start": "// kodingizni shu yerga yozing\n",
             "check": lambda c, o: _has(r"\b(let|const|var)\s+yosh\s*=", c, 0) and _has(r"console\.log\s*\(\s*yosh", c, 0),
             "hint": L("let yosh = 15;\nconsole.log(yosh);", "let yosh = 15;\nconsole.log(yosh);")},
        ]},
        {"id": "js2", "xp": 15, "title": L("Shartlar", "Условия"), "steps": [
            {"t": "read", "h": L("Agar… aks holda", "Если… иначе"),
             "p": L("if sharti to‘g‘ri bo‘lsa, birinchi blok ishlaydi; aks holda else bloki. Tenglikni === bilan tekshiramiz.",
                    "Если условие if истинно, выполняется первый блок; иначе — блок else. Равенство проверяем через ===."),
             "code": 'let ball = 85;\nif (ball >= 80) {\n  console.log("A’lo");\n} else {\n  console.log("Yaxshi");\n}'},
            {"t": "quiz", "q": L("Bu kod nima chiqaradi?", "Что выведет этот код?"),
             "code": 'let b = 7;\nif (b > 5) {\n  console.log("katta");\n} else {\n  console.log("kichik");\n}',
             "o": ["katta", "kichik", "7", "Xato"], "a": 0, "mono": True,
             "e": L("7 > 5 to‘g‘ri, shuning uchun birinchi blok ishlaydi.", "7 > 5 — истина, поэтому выполняется первый блок.")},
            {"t": "fill", "q": L("Qat’iy tenglikni tekshiring:", "Проверьте строгое равенство:"),
             "pre": "if (a ", "post": " 10) { … }", "a": ["==="],
             "e": L("=== qiymat va turini tekshiradi.", "=== сравнивает и значение, и тип.")},
            {"t": "try", "mode": "js",
             "task": L("ball 80 dan katta yoki teng bo‘lsa «A’lo», aks holda «Harakat qiling» deb chiqaring.",
                       "Если ball больше или равен 80, выведите «A’lo», иначе — «Harakat qiling»."),
             "start": "let ball = 92;\n",
             "check": lambda c, o: _has(r"if\s*\(", c, 0) and _has(r"\belse\b", c, 0) and _has(r"console\.log", c, 0),
             "hint": L('if (ball >= 80) { console.log("A’lo"); } else { … }', 'if (ball >= 80) { console.log("A’lo"); } else { … }')},
        ]},
        {"id": "js3", "xp": 20, "title": L("Funksiyalar", "Функции"), "steps": [
            {"t": "read", "h": L("Qayta ishlatiladigan kod", "Код, который можно повторять"),
             "p": L("Funksiya — nomlangan kod bo‘lagi. U parametrlar oladi va return orqali natija qaytaradi.",
                    "Функция — именованный кусок кода. Она принимает параметры и возвращает результат через return."),
             "code": "function qoshish(a, b) {\n  return a + b;\n}\nconsole.log(qoshish(2, 3)); // 5"},
            {"t": "quiz", "q": L("return nima qiladi?", "Что делает return?"),
             "o": [L("Natijani funksiyadan qaytaradi", "Возвращает результат из функции"), L("Sahifani yangilaydi", "Обновляет страницу"),
                   L("Xato chiqaradi", "Выдаёт ошибку"), L("Funksiyani o‘chiradi", "Удаляет функцию")], "a": 0,
             "e": L("return dan keyin funksiya to‘xtaydi va qiymat qaytaradi.", "После return функция завершается и отдаёт значение.")},
            {"t": "try", "mode": "js",
             "task": L("Sonning kvadratini qaytaradigan kvadrat(n) funksiyasini yozing va kvadrat(4) ni chiqaring.",
                       "Напишите функцию kvadrat(n), возвращающую квадрат числа, и выведите kvadrat(4)."),
             "start": "function kvadrat(n) {\n  \n}\n",
             "check": lambda c, o: _has(r"return\s+(n\s*\*\s*n|n\s*\*\*\s*2)", c, 0) and _has(r"console\.log\s*\(\s*kvadrat\s*\(", c, 0),
             "hint": L("return n * n;\nconsole.log(kvadrat(4));", "return n * n;\nconsole.log(kvadrat(4));")},
        ]},
    ]},
    {"id": "py", "tag": "Py", "color": "#2F9E6E", "name": L("Python", "Python"),
     "sub": L("Olimpiada tili", "Язык олимпиад"), "lessons": [
        {"id": "py1", "xp": 15, "title": L("print()", "print()"), "steps": [
            {"t": "read", "h": L("Birinchi dastur", "Первая программа"),
             "p": L("Python — sodda va kuchli til. print() ekranga ma’lumot chiqaradi. Matn qo‘shtirnoq ichida yoziladi.",
                    "Python — простой и мощный язык. print() выводит данные на экран. Текст пишется в кавычках."),
             "code": 'print("Salom, dunyo!")\nprint(2 + 3)'},
            {"t": "quiz", "q": L("print(2 + 3) nima chiqaradi?", "Что выведет print(2 + 3)?"),
             "o": ["5", "2 + 3", "23", "Xato"], "a": 0, "mono": True,
             "e": L("Qo‘shtirnoqsiz ifoda hisoblanadi: 2 + 3 = 5.", "Выражение без кавычек вычисляется: 2 + 3 = 5.")},
            {"t": "fill", "q": L("Ekranga chiqaring:", "Выведите на экран:"),
             "pre": "", "post": '("Salom")', "a": ["print"], "e": L("Chiqarish funksiyasi — print.", "Функция вывода — print.")},
            {"t": "try", "mode": "py",
             "task": L("Ismingizni ekranga chiqaring.", "Выведите на экран своё имя."),
             "start": "print()\n",
             "check": lambda c, o: "print" in c and o.strip() != "",
             "hint": L('print("Aziza")', 'print("Азиза")')},
        ]},
        {"id": "py2", "xp": 15, "title": L("O‘zgaruvchi va input", "Переменные и input"), "steps": [
            {"t": "read", "h": L("Foydalanuvchidan so‘rash", "Спрашиваем пользователя"),
             "p": L('Pythonda turi yozilmaydi: ism = "Ali". input() foydalanuvchi kiritgan matnni oladi. f-satr ichida {} qiymat qo‘yadi.',
                    'В Python тип не указывается: ism = "Ali". input() получает введённый текст. В f-строке {} подставляет значение.'),
             "code": 'ism = input("Ismingiz? ")\nprint(f"Salom, {ism}!")'},
            {"t": "quiz", "q": L('ism = "Laylo" bo‘lsa, print(f"Salom, {ism}") nima chiqaradi?', 'Если ism = "Laylo", что выведет print(f"Salom, {ism}")?'),
             "o": ["Salom, Laylo", "Salom, {ism}", "Salom, ism", "Xato"], "a": 0, "mono": True,
             "e": L("f-satr {ism} o‘rniga qiymatni qo‘yadi.", "f-строка подставляет значение вместо {ism}.")},
            {"t": "fill", "q": L("Foydalanuvchidan so‘rang:", "Спросите пользователя:"),
             "pre": "ism = ", "post": '("Ismingiz? ")', "a": ["input"], "e": L("Kiritish funksiyasi — input.", "Функция ввода — input.")},
            {"t": "try", "mode": "py",
             "task": L('shahar o‘zgaruvchisini yarating va f-satr bilan "Men ... da yashayman" deb chiqaring.',
                       'Создайте переменную shahar и выведите через f-строку "Men ... da yashayman".'),
             "start": 'shahar = "Asaka"\n',
             "check": lambda c, o: _has(r"f[\"']", c, 0) and "yashayman" in o and "{" not in o,
             "hint": L('print(f"Men {shahar}da yashayman")', 'print(f"Men {shahar}da yashayman")')},
        ]},
        {"id": "py3", "xp": 20, "title": L("for sikli", "Цикл for"), "steps": [
            {"t": "read", "h": L("Takrorlash", "Повторение"),
             "p": L("for sikli kodni bir necha marta bajaradi. range(3) — 0, 1, 2 sonlari. Ichki kod 4 ta bo‘sh joy bilan suriladi.",
                    "Цикл for повторяет код несколько раз. range(3) — числа 0, 1, 2. Внутренний код сдвигается на 4 пробела."),
             "code": "for i in range(3):\n    print(i)"},
            {"t": "quiz", "q": L("range(3) qaysi sonlarni beradi?", "Какие числа даёт range(3)?"),
             "o": ["0, 1, 2", "1, 2, 3", "0, 1, 2, 3", "3"], "a": 0, "mono": True,
             "e": L("Hisob 0 dan boshlanadi va 3 gacha (3 kirmaydi).", "Отсчёт с 0 и до 3 (3 не входит).")},
            {"t": "fill", "q": L("Siklni to‘ldiring:", "Допишите цикл:"),
             "pre": "for i ", "post": " range(5):", "a": ["in"], "e": L("To‘g‘ri yozuv: for i in range(5):", "Правильно: for i in range(5):")},
            {"t": "try", "mode": "py",
             "task": L("for sikli yordamida 1 dan 5 gacha sonlarni chiqaring (har biri yangi qatorda).",
                       "С помощью цикла for выведите числа от 1 до 5 (каждое с новой строки)."),
             "start": "for i in range():\n    print(i)\n",
             "check": lambda c, o: _has(r"\bfor\b", c, 0) and o.split() == ["1", "2", "3", "4", "5"],
             "hint": L("for i in range(1, 6):", "for i in range(1, 6):")},
        ]},
    ]},
]

ALL_LESSONS = {l["id"]: (l, c) for c in COURSES for l in c["lessons"]}

PLAYGROUND_START = '''# Kvadratlar jadvali
n = int(input("Nechta son? "))
for i in range(1, n + 1):
    print(i, "→", i * i)
'''
