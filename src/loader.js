/* ══════════════════════════════════════
   LOADER — збирає сторінку з частин:
   1) підставляє HTML-партіали замість <div data-include="..."> (рекурсивно);
   2) потім по черзі підключає JS-файли (порядок важливий — глобальні функції/змінні).
   Потрібен HTTP-сервер (Vercel / `python3 -m http.server`), з file:// fetch не працює.
   ══════════════════════════════════════ */
(function(){
  var SCRIPTS = [
    'core/i18n.js',
    'core/utils.js',
    'core/data.js',
    'core/state.js',
    'core/helpers.js',
    'core/overlays.js',
    'core/router.js',
    'core/autocomplete.js',
    'core/keyboard-fix.js',
    'core/sync.js',
    'features/community/community.js',
    'features/feed/feed.js',
    'features/streak-calendar/streak-calendar.js',
    'features/profile/profile-stats.js',
    'features/feed/brew-card.js',
    'features/beans/beans.js',
    'features/brew/pickers/inline-add.js',
    'features/devices/filters.js',
    'features/devices/devices.js',
    'features/share/share.js',
    'features/profile/profile.js',
    'features/brew/brew-state.js',
    'features/brew/espresso/espresso.js',
    'features/brew/setup/setup.js',
    'features/brew/draft.js',
    'features/brew/brew-views.js',
    'features/brew/active/active.js',
    'features/brew/rate/rate.js',
    'features/flavor-wheel/flavor-data.js',
    'features/flavor-wheel/wheel-svg.js',
    'features/flavor-wheel/wheel-store.js',
    'features/flavor-wheel/wheel-drill.js',
    'features/flavor-wheel/wheel-cascade.js',
    'features/flavor-wheel/wheel-app.js',
    'features/flavor-wheel/wheel-tabs.js',
    'features/edit-brew/edit-brew.js',
    'features/brew/save.js',
    'features/market/market.js',
    'features/log-brew/log-brew.js',
    'features/profile/xp.js',
    'features/profile/profile-v2.js',
    'features/achievements/achievements.js',
    'features/profile/stats-carousel.js',
    'features/brew/result/result.js',
    'features/trash/trash.js',
    'features/xp-history/xp-history.js',
    'features/coffee-stats/coffee-stats.js',
    'features/avatar-picker/avatar-picker.js',
    'features/log-brew/log-date-picker.js',
    'features/numpad/numpad.js',
    'features/compare/compare.js',
    'features/stats/stats.js',
    'core/boot.js',
  ];
  var BASE = 'src/';

  function loadPartial(el){
    var url = el.getAttribute('data-include');
    return fetch(url).then(function(r){
      if(!r.ok) throw new Error('Partial ' + url + ': HTTP ' + r.status);
      return r.text();
    }).then(function(html){
      var tpl = document.createElement('template');
      tpl.innerHTML = html;
      return includeAll(tpl.content).then(function(){ el.replaceWith(tpl.content); });
    });
  }
  function includeAll(root){
    var els = Array.prototype.slice.call(root.querySelectorAll('[data-include]'));
    return Promise.all(els.map(loadPartial));
  }
  function loadScripts(){
    return new Promise(function(resolve){
      var left = SCRIPTS.length;
      SCRIPTS.forEach(function(src){
        var s = document.createElement('script');
        s.src = BASE + src;
        s.async = false;               /* виконуються строго в порядку списку */
        s.onload = s.onerror = function(){ if(--left === 0) resolve(); };
        document.body.appendChild(s);
      });
    });
  }

  includeAll(document)
    .then(loadScripts)
    .catch(function(e){ console.error('[loader]', e); });
})();
