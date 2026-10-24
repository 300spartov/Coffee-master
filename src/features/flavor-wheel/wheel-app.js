// ============================================================
// Связка приложения: переключатель режимов, поиск, лог-панель
// ============================================================
window.VIEW = { active:null, activeSub:null };
var MODE = localStorage.getItem('fw_mode2') || 'drill';
if(MODE==='full'){ MODE='drill'; localStorage.setItem('fw_mode2','drill'); }

function $(id){ return document.getElementById(id); }

window.GOTO_WHEEL = function(){ setMode('drill', true); };

function setMode(m, keepView){
  MODE=m; localStorage.setItem('fw_mode2',m);
  if(!keepView){ window.VIEW.active=null; window.VIEW.activeSub=null; }
  document.querySelectorAll('.mode-btn').forEach(function(b){ b.classList.toggle('on', b.dataset.mode===m); });
  APP_RENDER();
}

window.APP_RENDER = function(){
  var svg=$('wheel-svg'), box=$('cascade-box');
  var isCascade = MODE==='cascade';
  svg.style.display = isCascade?'none':'block';
  box.style.display = isCascade?'block':'none';
  $('wheel-stage').classList.toggle('cascade', isCascade);

  if(MODE==='drill') MODES.drill(svg);
  else if(MODE==='full') MODES.full(svg);
  else MODES.cascade(box);

  updateHint();
  updateActionBar();
  updateLog();
};

function updateHint(){
  var h=$('fw-hint');
  if(MODE==='cascade'){ h.textContent = STORE.state.search ? t('wheel_cascade_search_hint') : t('wheel_cascade_hint'); return; }
  if(MODE==='full'){ h.textContent = STORE.total()?t('wheel_full_active_hint'):t('wheel_full_hint'); return; }
  // колесо (по рівнях)
  if(!window.VIEW.active) h.textContent=t('wheel_level1_hint');
  else if(!window.VIEW.activeSub) h.textContent=t('wheel_level2_hint');
  else h.textContent=t('wheel_level3_hint');
}

/* Контекстная кнопка «отметить родительский уровень» (только drill) */
function updateActionBar(){ /* action-bar hidden — auto-mark on navigation */ }

/* Лог: чипы-пути, сгруппированные по категориям (демонстрация сортировки) */
function updateLog(){
  var box=$('log-box'); var groups=STORE.grouped();
  var cats=Object.keys(groups);
  if(!cats.length){ box.innerHTML='<div class="log-empty">Поки нічого не обрано — познач смаки вище</div>'; $('log-count').textContent=''; return; }
  $('log-count').textContent=STORE.total();
  box.innerHTML='';
  window.FLAVORS.forEach(function(cat){
    var arr=groups[cat.id]; if(!arr) return;
    var grp=document.createElement('div'); grp.className='log-grp';
    var head=document.createElement('div'); head.className='log-grp-head';
    var dot=document.createElement('span'); dot.className='log-dot'; dot.style.background=cat.color; head.appendChild(dot);
    var nm=document.createElement('span'); nm.textContent=cat.label; head.appendChild(nm);
    var c=document.createElement('span'); c.className='log-grp-n'; c.textContent=arr.length; head.appendChild(c);
    grp.appendChild(head);
    arr.forEach(function(e){
      var parts=STORE.label(e);
      var chip=document.createElement('div'); chip.className='log-chip lvl'+e.level;
      chip.style.setProperty('--c', cat.color);
      var path=document.createElement('span'); path.className='log-path';
      parts.forEach(function(p,i){
        if(i){ var sep=document.createElement('span'); sep.className='log-sep'; sep.textContent='›'; path.appendChild(sep); }
        var s=document.createElement('span'); s.className='log-seg'+(i===parts.length-1?' last':''); s.textContent=p; path.appendChild(s);
      });
      chip.appendChild(path);
      var x=document.createElement('button'); x.className='log-x'; x.textContent='×';
      x.addEventListener('click',function(){ STORE.remove(e.id); });
      chip.appendChild(x);
      grp.appendChild(chip);
    });
    box.appendChild(grp);
  });
}

function init(){
  // переключатель режимов
  document.querySelectorAll('.mode-btn').forEach(function(b){
    b.addEventListener('click',function(){ setMode(b.dataset.mode); });
  });
  // поиск
  var si=$('search-inp');
  si.addEventListener('input',function(){ STORE.setSearch(si.value); });
  $('search-clear').addEventListener('click',function(){ si.value=''; STORE.setSearch(''); si.focus(); });
  // рейтинг
  var rng=$('rate-rng')||$('rate-slider');
  if(rng) rng.addEventListener('input',function(){ var n=$('rate-num'); if(n) n.textContent=parseFloat(rng.value).toFixed(1); });
  // сброс
  $('reset-btn').addEventListener('click',function(){ STORE.reset(); window.VIEW.active=null; window.VIEW.activeSub=null; APP_RENDER(); });

  STORE.on(function(){
    // обновлять видимость крестика поиска
    $('search-clear').style.display=STORE.state.search?'flex':'none';
    APP_RENDER();
  });

  setMode(MODE);
}
