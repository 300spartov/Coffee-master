/* ── STATE ── */
const SEED={
  profile:{name:'',loc:'',cat:'Новачок',stazh:''},
  beans:[],
  filters:[],
  equipment:[],
  brews:[],
  log:[],
  record:0,
  id:0,
  xp:0,
  achEarned:{},
  trash:[],
  roasters:[],
  beanNames:[],
  milks:[],
  juices:[]
};
let S=JSON.parse(localStorage.getItem('cj_v7')||'null')||JSON.parse(JSON.stringify(SEED));

function _migrateS(){
  if(!S.log)S.log=[];
  if(!S.record)S.record=0;
  if(!S.roasters)S.roasters=[];
  if(!S.beanNames)S.beanNames=[];
  if(!S.milks)S.milks=[];
  if(!S.juices)S.juices=[];
  /* ── Примусово впорядковуємо рецепти/лог за часом (найновіше — першим), на випадок якщо попередні злиття переплутали порядок ── */
  if(S.brews&&S.brews.length)S.brews.sort(function(a,b){return (b.ts||0)-(a.ts||0);});
  if(S.log&&S.log.length)S.log.sort(function(a,b){return (b.ts||0)-(a.ts||0);});
  /* ── MIGRATION: add new fields without breaking existing data ── */
  var changed=false;
  if(S.xp===undefined){ S.xp=0; changed=true; }
  if(!S.achEarned){ S.achEarned={}; changed=true; }
  if(!S.trash){ S.trash=[]; changed=true; }
  if(S.brews&&S.brews.length){S.brews.forEach(function(br){if(br.cafeVisit===undefined){br.cafeVisit=(br.source==='place')||!!(br.place&&br.place.length);changed=true;}});}
  /* ── Доповнюємо S.log для рецептів, у яких немає відповідного запису (звідси малюється календар) —
     інакше деякі дні (зазвичай старі еспресо-рецепти) виглядають порожніми в календарі, хоч рецепти є ── */
  if(S.brews&&S.brews.length){
    var _logIds={};
    (S.log||[]).forEach(function(e){ if(e.id!=null) _logIds[e.id]=true; });
    var _missingLog=S.brews.filter(function(br){return !_logIds[br.id];}).map(function(br){
      var _dose=parseFloat(br.dose)||16, _ratio=parseFloat(br.ratio)||(br.espresso?2:16);
      var _vol = br.espresso ? Math.round(br.espresso.actualYield||br.espresso.targetYield||(_dose*_ratio)) : Math.round(_dose*_ratio);
      return {id:br.id,ts:br.ts,vol:_vol,cat:methodCat(br.method||''),method:br.method||'',bean:br.beanName||'',rating:br.rating||8,dose:_dose};
    });
    if(_missingLog.length){
      S.log=(S.log||[]).concat(_missingLog);
      S.log.sort(function(x,y){return (y.ts||0)-(x.ts||0);});
      changed=true;
    }
  }
  /* ХР більше не окреме поле — рахуємо наново з кількості рецептів + отриманих ачівок щоразу при завантаженні */
  var _recomputedXp = computeTotalXp();
  if(_recomputedXp !== S.xp){ S.xp = _recomputedXp; changed = true; }
  if(changed){ S.record=0; }
  if(changed) localStorage.setItem('cj_v7',JSON.stringify(S));
}

function save(){
  localStorage.setItem('cj_v7',JSON.stringify(S));
  if(typeof sbSave==='function') sbSave();
}
