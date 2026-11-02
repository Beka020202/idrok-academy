// O‘zbekiston viloyatlari va tumanlari (maktabni tanlash uchun).
// Области и районы Узбекистана (для выбора школы).
import 'model.dart';

class Region {
  final String id; // serverga yuboriladigan nom / название для сервера
  final Tr name;
  final List<String> districts;
  const Region(this.id, this.name, this.districts);
}

const List<Region> kRegions = [
  Region('Toshkent shahri', Tr('Toshkent shahri', 'город Ташкент'), [
    'Bektemir', 'Chilonzor', 'Mirobod', 'Mirzo Ulug‘bek', 'Olmazor', 'Sergeli', 'Shayxontohur', 'Uchtepa',
    'Yakkasaroy', 'Yangihayot', 'Yashnobod', 'Yunusobod',
  ]),
  Region('Andijon viloyati', Tr('Andijon viloyati', 'Андижанская область'), [
    'Andijon shahri', 'Xonobod shahri', 'Andijon tumani', 'Asaka', 'Baliqchi', 'Bo‘ston', 'Buloqboshi', 'Izboskan',
    'Jalaquduq', 'Marhamat', 'Oltinko‘l', 'Paxtaobod', 'Qo‘rg‘ontepa', 'Shahrixon', 'Ulug‘nor', 'Xo‘jaobod',
  ]),
  Region('Buxoro viloyati', Tr('Buxoro viloyati', 'Бухарская область'), [
    'Buxoro shahri', 'Kogon shahri', 'Buxoro tumani', 'G‘ijduvon', 'Jondor', 'Kogon tumani', 'Olot', 'Peshku',
    'Qorako‘l', 'Qorovulbozor', 'Romitan', 'Shofirkon', 'Vobkent',
  ]),
  Region('Farg‘ona viloyati', Tr('Farg‘ona viloyati', 'Ферганская область'), [
    'Farg‘ona shahri', 'Marg‘ilon shahri', 'Qo‘qon shahri', 'Quvasoy shahri', 'Bag‘dod', 'Beshariq', 'Buvayda',
    'Dang‘ara', 'Farg‘ona tumani', 'Furqat', 'Oltiariq', 'O‘zbekiston', 'Qo‘shtepa', 'Quva', 'Rishton', 'So‘x',
    'Toshloq', 'Uchko‘prik', 'Yozyovon',
  ]),
  Region('Jizzax viloyati', Tr('Jizzax viloyati', 'Джизакская область'), [
    'Jizzax shahri', 'Arnasoy', 'Baxmal', 'Do‘stlik', 'Forish', 'G‘allaorol', 'Mirzacho‘l', 'Paxtakor',
    'Sharof Rashidov', 'Yangiobod', 'Zafarobod', 'Zarbdor', 'Zomin',
  ]),
  Region('Xorazm viloyati', Tr('Xorazm viloyati', 'Хорезмская область'), [
    'Urganch shahri', 'Xiva shahri', 'Bog‘ot', 'Gurlan', 'Hazorasp', 'Qo‘shko‘pir', 'Shovot', 'Tuproqqal’a',
    'Urganch tumani', 'Xiva tumani', 'Xonqa', 'Yangiariq', 'Yangibozor',
  ]),
  Region('Namangan viloyati', Tr('Namangan viloyati', 'Наманганская область'), [
    'Namangan shahri', 'Chortoq', 'Chust', 'Davlatobod', 'Kosonsoy', 'Mingbuloq', 'Namangan tumani', 'Norin',
    'Pop', 'To‘raqo‘rg‘on', 'Uchqo‘rg‘on', 'Uychi', 'Yangiqo‘rg‘on',
  ]),
  Region('Navoiy viloyati', Tr('Navoiy viloyati', 'Навоийская область'), [
    'Navoiy shahri', 'Zarafshon shahri', 'G‘ozg‘on shahri', 'Karmana', 'Konimex', 'Navbahor', 'Nurota',
    'Qiziltepa', 'Tomdi', 'Uchquduq', 'Xatirchi',
  ]),
  Region('Qashqadaryo viloyati', Tr('Qashqadaryo viloyati', 'Кашкадарьинская область'), [
    'Qarshi shahri', 'Shahrisabz shahri', 'Chiroqchi', 'Dehqonobod', 'G‘uzor', 'Kasbi', 'Kitob', 'Koson',
    'Ko‘kdala', 'Mirishkor', 'Muborak', 'Nishon', 'Qamashi', 'Qarshi tumani', 'Shahrisabz tumani', 'Yakkabog‘',
  ]),
  Region('Qoraqalpog‘iston Respublikasi', Tr('Qoraqalpog‘iston Respublikasi', 'Республика Каракалпакстан'), [
    'Nukus shahri', 'Amudaryo', 'Beruniy', 'Bo‘zatov', 'Chimboy', 'Ellikqal’a', 'Kegeyli', 'Mo‘ynoq',
    'Nukus tumani', 'Qanliko‘l', 'Qo‘ng‘irot', 'Qorao‘zak', 'Shumanay', 'Taxiatosh', 'Taxtako‘pir', 'To‘rtko‘l',
    'Xo‘jayli',
  ]),
  Region('Samarqand viloyati', Tr('Samarqand viloyati', 'Самаркандская область'), [
    'Samarqand shahri', 'Kattaqo‘rg‘on shahri', 'Bulung‘ur', 'Ishtixon', 'Jomboy', 'Kattaqo‘rg‘on tumani',
    'Narpay', 'Nurobod', 'Oqdaryo', 'Pastdarg‘om', 'Paxtachi', 'Payariq', 'Qo‘shrabot', 'Samarqand tumani',
    'Toyloq', 'Urgut',
  ]),
  Region('Sirdaryo viloyati', Tr('Sirdaryo viloyati', 'Сырдарьинская область'), [
    'Guliston shahri', 'Shirin shahri', 'Yangiyer shahri', 'Boyovut', 'Guliston tumani', 'Mirzaobod', 'Oqoltin',
    'Sardoba', 'Sayxunobod', 'Sirdaryo tumani', 'Xovos',
  ]),
  Region('Surxondaryo viloyati', Tr('Surxondaryo viloyati', 'Сурхандарьинская область'), [
    'Termiz shahri', 'Angor', 'Bandixon', 'Boysun', 'Denov', 'Jarqo‘rg‘on', 'Muzrabot', 'Oltinsoy', 'Qiziriq',
    'Qumqo‘rg‘on', 'Sariosiyo', 'Sherobod', 'Sho‘rchi', 'Termiz tumani', 'Uzun',
  ]),
  Region('Toshkent viloyati', Tr('Toshkent viloyati', 'Ташкентская область'), [
    'Nurafshon shahri', 'Angren shahri', 'Bekobod shahri', 'Chirchiq shahri', 'Olmaliq shahri',
    'Ohangaron shahri', 'Yangiyo‘l shahri', 'Bekobod tumani', 'Bo‘ka', 'Bo‘stonliq', 'Chinoz', 'Ohangaron tumani',
    'Oqqo‘rg‘on', 'O‘rtachirchiq', 'Parkent', 'Piskent', 'Qibray', 'Quyichirchiq', 'Toshkent tumani',
    'Yangiyo‘l tumani', 'Yuqorichirchiq', 'Zangiota',
  ]),
];

Region? regionById(String id) {
  for (final r in kRegions) {
    if (r.id == id) return r;
  }
  return null;
}

/// Maktab turi / тип школы.
enum SchoolKind { school, idum, president, lyceum, private }

const Map<SchoolKind, Tr> kSchoolKinds = {
  SchoolKind.school: Tr('Maktab', 'Школа'),
  SchoolKind.idum: Tr('IDUM', 'ИДУМ'),
  SchoolKind.president: Tr('Prezident maktabi', 'Президентская школа'),
  SchoolKind.lyceum: Tr('Litsey', 'Лицей'),
  SchoolKind.private: Tr('Xususiy', 'Частная'),
};

/// Raqamli turlar / типы с номером.
bool kindHasNumber(SchoolKind k) => k == SchoolKind.school || k == SchoolKind.idum;
bool kindHasName(SchoolKind k) => k == SchoolKind.lyceum || k == SchoolKind.private;

/// Maktab nomini bir xil ko‘rinishda yasaydi (reyting to‘g‘ri ishlashi uchun).
/// Единообразное название школы (чтобы рейтинги школ работали правильно).
String schoolLabel(SchoolKind kind, {String number = '', String name = ''}) {
  final n = number.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
  final t = name.trim().replaceAll(RegExp(r'\s+'), ' ');
  return switch (kind) {
    SchoolKind.school => n.isEmpty ? '' : '$n-maktab',
    SchoolKind.idum => n.isEmpty ? '' : '$n-IDUM',
    SchoolKind.president => 'Prezident maktabi',
    SchoolKind.lyceum => t.isEmpty ? '' : '$t litseyi',
    SchoolKind.private => t.isEmpty ? '' : '“$t” xususiy maktabi',
  };
}

/// Saqlangan nomdan qaytarish / разбор сохранённого названия.
(SchoolKind, String number, String name) parseSchool(String label) {
  final m = RegExp(r'^(\d+)-(maktab|IDUM)$').firstMatch(label.trim());
  if (m != null) return (m.group(2) == 'IDUM' ? SchoolKind.idum : SchoolKind.school, m.group(1)!, '');
  if (label == 'Prezident maktabi') return (SchoolKind.president, '', '');
  if (label.endsWith(' litseyi')) return (SchoolKind.lyceum, '', label.substring(0, label.length - 8));
  final p = RegExp(r'^“(.*)” xususiy maktabi$').firstMatch(label);
  if (p != null) return (SchoolKind.private, '', p.group(1)!);
  final digits = RegExp(r'\d+').firstMatch(label);
  return (SchoolKind.school, digits?.group(0) ?? '', '');
}
