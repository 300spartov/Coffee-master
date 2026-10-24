/* ══════════════════════════════════════
   BOOT — startup statements that used to run inline in the single
   <script>. Loaded last, after every feature file is defined.
   ══════════════════════════════════════ */

_migrateS();

// Ініціалізація з завантаженням даних
(async function(){
  var app=document.getElementById('app');
  if(TG_USER_ID){
    var loader=document.createElement('div');
    loader.id='sb-loader';
    loader.style.cssText='position:absolute;inset:0;background:#17181a;display:flex;flex-direction:column;align-items:center;justify-content:center;z-index:999;gap:12px';
    loader.innerHTML='<svg width="52" height="52" viewBox="0 0 52 52" fill="none"><ellipse cx="26" cy="26" rx="18" ry="22" fill="#B87333" opacity=".7"/><path d="M26 6 Q34 18 34 26 Q34 36 26 46" stroke="#D89858" stroke-width="2.5" stroke-linecap="round" fill="none"/></svg><div style="font-family:monospace;font-size:10px;color:#6b6862;letter-spacing:2px;text-transform:uppercase">Завантаження...</div>';
    app.appendChild(loader);
    await sbLoad();
    loader.remove();
  }
  renderFeed();renderProf();bCalc();setWet(true);showBV('bv-setup');
  applyLangToDOM();
  localStorage.removeItem('cm_draft_recipe'); /* функцію "незавершений рецепт" відключено */
})();

if(!S.trash) S.trash = [];
// Очищуємо старий кошик при завантаженні
(function(){ var now=Date.now(); S.trash=S.trash.filter(function(b){return now-(b._deletedAt||0)<TRASH_TTL;}); save(); })();

/* Auto-fill name from Telegram on first launch */
(function(){
  try{
    var tg = window.Telegram;
    if(tg && tg.WebApp && tg.WebApp.initDataUnsafe && tg.WebApp.initDataUnsafe.user){
      var u = tg.WebApp.initDataUnsafe.user;
      if(u && u.first_name && (!S.profile||!S.profile.name)){
        if(!S.profile) S.profile={};
        S.profile.name = (u.first_name + (u.last_name?' '+u.last_name:'')).trim();
        save();
      }
    }
  }catch(e){}
})();

/* Flavor wheel init (was DOMContentLoaded — partials are injected after it fires) */
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
