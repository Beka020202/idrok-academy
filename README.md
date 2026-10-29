# Kodla 🎮 — o‘ynab dasturlashni o‘rganing / учимся программировать, играя

HTML, CSS, JavaScript va Python bo‘yicha o‘yin-darslar: XP, olmoslar 💎, kombo 🔥, kunlik vazifalar, xazina sandiqlari 🎁, avatar do‘koni, reyting va ustoz paneli. Yorug‘ va qorong‘i mavzu. O‘zbek va rus tillari.

Игровые уроки по HTML, CSS, JavaScript и Python: XP, кристаллы 💎, комбо 🔥, задания дня, сундуки 🎁, магазин аватаров, рейтинг и панель учителя. Светлая и тёмная тема. Узбекский и русский языки.

## Fayllar / Файлы

| Fayl | Nima uchun / Для чего |
|---|---|
| `main.py` | Ilova (o‘yin ekranlari) / приложение (игровые экраны) |
| `server.py` | Mahalliy server: akkauntlar, reyting, ustoz paneli / локальный сервер |
| `lessons.py` | Darslar va matnlar / уроки и тексты |
| `progress.py` | O‘yin qoidalari: XP, olmos, vazifalar / правила игры |
| `kodla.db` | Ma’lumotlar bazasi (server o‘zi yaratadi) / база данных (создаётся сама) |

## 1. O‘rnatish (bir marta) / Установка (один раз)

```
python -m pip install "flet[all]==0.28.3"
```

## 2. Serverni yoqish / Запуск сервера

Birinchi terminal oynasida / В первом окне терминала:
```
python server.py
```
Server ekranga manzillarni va ustoz akkauntini chiqaradi (login `ustoz`, parol `ustoz123`).
Сервер покажет адреса и аккаунт учителя (логин `ustoz`, пароль `ustoz123`).

Parolni o‘zgartiring / Смените пароль:
```
python server.py --teacher-password YangiParol
```

## 3. Ilovani ochish / Открыть приложение

**Shu kompyuterda / На этом компьютере** — ikkinchi terminalda / во втором терминале:
```
python main.py
```

**O‘quvchilarning telefonlarida / На телефонах учеников** (bir xil Wi‑Fi / одна сеть Wi‑Fi):
```
python main.py --web
```
Terminalda `http://192.168.x.x:8550` kabi manzil chiqadi. O‘quvchilar uni telefon brauzerida ochadi — hech narsa o‘rnatish shart emas.
В терминале появится адрес вида `http://192.168.x.x:8550`. Ученики открывают его в браузере телефона — ничего устанавливать не нужно.

Agar telefon ochmasa: Windows «Brandmauer» (Firewall) so‘raganda **Ruxsat berish** ni bosing, Wi‑Fi tarmog‘i «Xususiy» (Private) bo‘lsin.
Если телефон не открывает: когда Windows Firewall спросит — нажмите **Разрешить**; сеть Wi‑Fi должна быть «Частная» (Private).

## O‘yin qoidalari / Правила игры

- Yangi dars: XP + 10 💎. Xatosiz dars: +5 XP va +5 💎. / Новый урок: XP + 10 💎. Без ошибок: +5 XP и +5 💎.
- Ketma-ket to‘g‘ri javoblar — kombo 🔥. / Верные ответы подряд — комбо 🔥.
- Har kuni 3 ta vazifa yangilanadi. / Каждый день — 3 новых задания.
- Kursni tugatsangiz — sandiqda 50 💎. / Пройдите курс — в сундуке 50 💎.
- Olmoslarga avatar sotib oling. / Покупайте аватары за кристаллы.
- Har 100 XP — yangi daraja. / Каждые 100 XP — новый уровень.

## Xavfsizlik / Безопасность

O‘quvchi yozgan Python kodi ustoz kompyuterida bajariladi, shuning uchun fayllar, `os` va tarmoqqa kirish yopilgan (faqat `math`, `random` kabi xavfsiz modullar). Serverni faqat ishonchli sinf tarmog‘ida ishlating.
Код учеников выполняется на компьютере учителя, поэтому доступ к файлам, `os` и сети закрыт (только безопасные модули вроде `math`, `random`). Используйте сервер только в доверенной сети класса.

## Yangi dars qo‘shish / Добавить урок

`lessons.py` dagi `COURSES` ro‘yxatiga mavjud dars kabi blok qo‘shing va serverni qayta ishga tushiring.
Добавьте блок, как у существующего урока, в список `COURSES` в `lessons.py` и перезапустите сервер.
