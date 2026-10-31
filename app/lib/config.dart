/// Server manzillari / Адреса серверов.
///
/// Render'ga joylagandan keyin shu ikki manzilni o‘zingiznikiga almashtiring.
/// После деплоя на Render замените эти два адреса на свои.
///
/// Sinfda (bir Wi‑Fi) ishlatish uchun: `http://192.168.x.x:8765`.
/// Для класса (одна сеть Wi‑Fi): `http://192.168.x.x:8765`.
library;

/// Akkauntlar, reyting, ustoz paneli / аккаунты, рейтинг, панель учителя.
const String kDefaultServer = 'https://kodla-api.onrender.com';

/// Python kodini bajaruvchi alohida xizmat. Bo‘sh qoldirilsa, asosiy server ishlatiladi.
/// Отдельный сервис для запуска Python. Если пусто — используется основной сервер.
const String kRunnerServer = 'https://kodla-runner.onrender.com';

/// Ilova nomi / название приложения.
const String kAppName = 'Idrok Academy';

/// So‘rov kutish vaqti / таймаут запросов.
const Duration kRequestTimeout = Duration(seconds: 12);
