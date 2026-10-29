/* ============================================================
   Хранилище выбора + поиск. Единый контракт для всех режимов.
   Выбор возможен на ЛЮБОМ уровне:
     уровень 1: {catId}                 → «Фрукты»
     уровень 2: {catId, subId}          → «Фрукты › Тропические»
     уровень 3: {catId, subId, note}    → «Фрукты › Тропические › Манго»
   ============================================================ */
(function(){
  var listeners=[];
  var SEL={};            // pathId → entry
  var state={ search:'' };

  function pathId(catId,subId,note){
    return [catId,subId,note].filter(Boolean).join('▸');
  }
  function findCat(id){ return window.FLAVORS.find(function(c){return c.id===id;}); }
  function findSub(cat,id){ return cat.subs.find(function(s){return s.id===id;}); }

  function entryFor(catId,subId,note){
    var cat=findCat(catId);
    var sub=subId?findSub(cat,subId):null;
    var level=note?3:(subId?2:1);
    return { id:pathId(catId,subId,note), level:level, catId:catId, subId:subId||null,
             note:note||null, cat:cat, sub:sub };
  }

  function toggle(catId,subId,note){
    var id=pathId(catId,subId,note);
    if(SEL[id]) delete SEL[id];
    else SEL[id]=entryFor(catId,subId,note);
    emit();
  }
  function isSel(catId,subId,note){ return !!SEL[pathId(catId,subId,note)]; }
  function reset(){ SEL={}; emit(); }
  function remove(id){ delete SEL[id]; emit(); }

  /* кол-во выбранного внутри узла (для бейджей) */
  function countUnder(catId,subId){
    var n=0;
    Object.values(SEL).forEach(function(e){
      if(e.catId!==catId) return;
      if(subId==null){ n++; }
      else if(e.subId===subId){ n++; }
    });
    return n;
  }
  function countCat(catId){
    var n=0; Object.values(SEL).forEach(function(e){ if(e.catId===catId) n++; }); return n;
  }
  function total(){ return Object.keys(SEL).length; }

  /* список выбранного, сгруппированный по категориям, отсортированный по уровню */
  function list(){
    return Object.values(SEL).sort(function(a,b){
      var ca=window.FLAVORS.indexOf(a.cat), cb=window.FLAVORS.indexOf(b.cat);
      if(ca!==cb) return ca-cb;
      if(a.level!==b.level) return a.level-b.level;
      return a.id.localeCompare(b.id);
    });
  }
  function grouped(){
    var g={};
    list().forEach(function(e){ (g[e.catId]=g[e.catId]||[]).push(e); });
    return g;
  }
  function label(e){
    var parts=[e.cat.label];
    if(e.sub && e.sub.label!==e.cat.label) parts.push(e.sub.label);
    if(e.note) parts.push(e.note);
    return parts;
  }

  /* ── ЦВЕТА: рамп оттенков внутри категории ── */
  function subColor(cat,si){
    var n=cat.subs.length;
    if(n===1) return cat.color;
    var t=-0.18 + (si/(n-1))*0.5;   // от темнее к светлее
    return WC.shade(cat.color,t);
  }
  function noteColor(cat,si,di,n){
    var base=subColor(cat,si);
    var t=-0.12 + (di/Math.max(1,n-1))*0.4;
    return WC.shade(base,t);
  }

  /* ── ПОИСК ── */
  function setSearch(q){ state.search=q||''; emit(); }
  function searchMatches(){
    var q=state.search.trim().toLowerCase();
    if(!q) return null;
    var hit={notes:{},subs:{},cats:{}};
    window.FLAT_NOTES.forEach(function(f){
      /* f.note is UA key; also check EN label via f.desc */
      var uaLbl=(f.note||'').toLowerCase();
      var enLbl=f.desc&&typeof f.desc==='object'?(f.desc.en||'').toLowerCase():'';
      if(uaLbl.indexOf(q)>=0 || enLbl.indexOf(q)>=0){
        hit.notes[f.cat.id+'\u25b8'+f.sub.id+'\u25b8'+f.note]=true;
        hit.subs[f.cat.id+'\u25b8'+f.sub.id]=true;
        hit.cats[f.cat.id]=true;
      }
    });
    /* також по назві категорії/підкатегорії — обидві мови */
    window.FLAVORS.forEach(function(c){
      var cua=(c.label_ua||c.label||'').toLowerCase();
      var cen=(c.label_en||'').toLowerCase();
      if(cua.indexOf(q)>=0||cen.indexOf(q)>=0) hit.cats[c.id]=true;
      c.subs.forEach(function(s){
        var sua=(s.label_ua||s.label||'').toLowerCase();
        var sen=(s.label_en||'').toLowerCase();
        if(sua.indexOf(q)>=0||sen.indexOf(q)>=0){ hit.subs[c.id+'\u25b8'+s.id]=true; hit.cats[c.id]=true; }
      });
    });
    return hit;
  }

  function on(fn){ listeners.push(fn); }
  function emit(){ listeners.forEach(function(fn){ fn(); }); }

  window.STORE={ SEL:function(){return SEL;}, state:state, pathId:pathId,
    findCat:findCat, findSub:findSub, toggle:toggle, isSel:isSel, reset:reset, remove:remove,
    countUnder:countUnder, countCat:countCat, total:total, list:list, grouped:grouped, label:label,
    subColor:subColor, noteColor:noteColor, setSearch:setSearch, searchMatches:searchMatches, on:on, emit:emit,
    /* ── two-tab memory ── */
    setTab:function(t){
      if(!_MAPS[t]) _MAPS[t]={};
      _curTab=t; SEL=_MAPS[t]; state.search=''; emit();
    },
    labelsFor:function(t){
      var m=_MAPS[t]||{};
      return Object.values(m).sort(function(a,b){
        var ca=window.FLAVORS.indexOf(a.cat),cb=window.FLAVORS.indexOf(b.cat);
        if(ca!==cb)return ca-cb; if(a.level!==b.level)return a.level-b.level;
        return a.id.localeCompare(b.id);
      }).map(function(e){ var p=label(e); return p[p.length-1]; });
    },
    resetAll:function(){
      _MAPS={flavor:{},aroma:{}};
      _curTab='flavor'; SEL=_MAPS[_curTab]; emit();
    },
    curTab:function(){ return _curTab; }
  };
  /* private maps for each tab */
  var _MAPS={flavor:SEL,aroma:{}};
  var _curTab='flavor';
  /* patch toggle/isSel/reset/remove/countUnder/countCat/total/list to use SEL ref */
})();
