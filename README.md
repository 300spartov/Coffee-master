# Coffee-master
Приложение для заметок о кофе, записи рецептов и их контроля

## Структура проєкту

```
index.html            — оболонка: <head>, CSS-лінки, каркас .app і плейсхолдери <div data-include="...">
src/loader.js         — підставляє HTML-партіали, потім по черзі підключає JS (список SCRIPTS — порядок важливий)
src/core/             — спільне: i18n, дані/DB, стан S + save, утиліти, оверлеї, роутер (showScr),
                        автодоповнення, Supabase-синхронізація, boot.js (старт застосунку — завантажується останнім)
src/features/<name>/  — окремий екран/фіча: <name>.html, <name>.css, <name>.js
```

Порядок CSS у `index.html` повторює оригінальний каскад — не переставляйте лінки без потреби.
Новий JS-файл додається в `SCRIPTS` у `src/loader.js`, новий CSS — `<link>` в `index.html`,
новий HTML-партіал — `<div data-include="src/...">` у потрібному місці.

Локальний запуск (fetch не працює з `file://`):

```
python3 -m http.server 8000   # → http://localhost:8000
```
