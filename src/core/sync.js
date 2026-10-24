/* ── SUPABASE SYNC ── */
const SUPABASE_URL='https://mhudtufaxjjvvxefeyrs.supabase.co';
const SUPABASE_KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1odWR0dWZheGpqdnZ4ZWZleXJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNTU2NDEsImV4cCI6MjA5NTYzMTY0MX0.IKMFN_y4oOa_3dcxxLNLW2txPoKRyXjPaS05p_S3t8M';

let TG_USER_ID=null;
let _sbLoaded=false; // захист від запису до завантаження
try{
  var tg=window.Telegram;
  if(tg&&tg.WebApp&&tg.WebApp.initDataUnsafe&&tg.WebApp.initDataUnsafe.user){
    TG_USER_ID=String(tg.WebApp.initDataUnsafe.user.id);
    tg.WebApp.ready();
    tg.WebApp.expand();
  }
}catch(e){}

async function sbLoad(){
  if(!TG_USER_ID)return false;
  try{
    console.log('[sbLoad] TG_USER_ID:', TG_USER_ID);
    var res=await fetch(SUPABASE_URL+'/rest/v1/users?telegram_id=eq.'+TG_USER_ID+'&select=data',{
      headers:{'apikey':SUPABASE_KEY,'Authorization':'Bearer '+SUPABASE_KEY}
    });
    console.log('[sbLoad] status:', res.status);
    var rows=await res.json();
    console.log('[sbLoad] rows:', rows&&rows.length, rows&&rows[0]&&Object.keys(rows[0].data||{}).join(','));
    if(rows&&rows.length&&rows[0].data){
      var remote=rows[0].data;
      var localBefore=S;
      S=_mergeS(localBefore, remote);
      _migrateS();
      localStorage.setItem('cj_v7',JSON.stringify(S));
      localStorage.setItem('cj_clean',JSON.stringify(S));
      console.log('[sbLoad] OK brews:', S.brews&&S.brews.length);
      _sbLoaded=true;
      try{
        await fetch(SUPABASE_URL+'/rest/v1/users',{
          method:'POST',
          headers:{'apikey':SUPABASE_KEY,'Authorization':'Bearer '+SUPABASE_KEY,'Content-Type':'application/json','Prefer':'resolution=merge-duplicates'},
          body:JSON.stringify({telegram_id:TG_USER_ID,data:S,updated_at:new Date().toISOString()})
        });
      }catch(e){console.log('[sbLoad] merge-push err',e);}
      return true;
    } else {
      console.log('[sbLoad] no data in row — перший запуск');
    }
  }catch(e){console.log('[sbLoad] ERROR:', e.message);}
  _sbLoaded=true;
  return false;
}

function _mergeS(local, remote){
  if(!remote) return local;
  var merged=JSON.parse(JSON.stringify(remote));
  function mergeArrByKey(key, idKey){
    var a=local[key]||[], b=merged[key]||[];
    var map={};
    b.forEach(function(item){ if(item&&item[idKey]!=null) map[item[idKey]]=item; });
    a.forEach(function(item){
      if(!item) return;
      var k=(item[idKey]!=null)?item[idKey]:('_loc_'+Math.random());
      map[k]=item;
    });
    /* Object.keys() автоматично сортує числові ключі за зростанням (особливість JS) —
       тому після злиття явно повертаємо порядок "найновіше — першим" */
    merged[key]=Object.values(map).sort(function(x,y){return (y[idKey]||0)-(x[idKey]||0);});
  }
  /* Для редагованих сутностей (зерно/девайси/фільтри) — перемагає та версія, яку РЕАЛЬНО редагували останньою (за _upd), інакше пристрій що давно не синхронізувався затирає свіжі зміни іншого */
  function mergeArrByUpd(key, idKey){
    var a=local[key]||[], b=merged[key]||[];
    var map={};
    b.forEach(function(item){ if(item&&item[idKey]!=null) map[item[idKey]]=item; });
    a.forEach(function(item){
      if(!item) return;
      var k=(item[idKey]!=null)?item[idKey]:('_loc_'+Math.random());
      var existing=map[k];
      if(!existing || (item._upd||0)>=(existing._upd||0)){
        map[k]=item;
      }
    });
    merged[key]=Object.keys(map).map(function(k){return map[k];});
  }
  mergeArrByKey('brews','ts');
  mergeArrByKey('log','ts');
  mergeArrByKey('trash','id');
  /* Захист — перевіряємо СИРЕ об'єднання (до виключення кошика): воно ніколи не повинно бути меншим за локальне,
     інакше це ознака помилки самого об'єднання, а не навмисного видалення */
  if((merged.brews||[]).length < (local.brews||[]).length){
    console.log('[_mergeS] ЗАХИСТ: рецептів стало менше ПІСЛЯ СИРОГО об\'єднання (',(local.brews||[]).length,'->',(merged.brews||[]).length,') — лишаю локальну версію brews');
    merged.brews=local.brews;
  }
  if((merged.log||[]).length < (local.log||[]).length){
    console.log('[_mergeS] ЗАХИСТ: лог став меншим після сирого об\'єднання — лишаю локальну версію log');
    merged.log=local.log;
  }
  /* Тепер прибираємо з рецептів усе що вже в кошику (з будь-якого пристрою) — це навмисне видалення,
     йому дозволено зменшувати список далі, на відміну від помилки об'єднання вище */
  var _trashedIds={};
  (merged.trash||[]).forEach(function(tItem){ if(tItem&&tItem.id!=null) _trashedIds[tItem.id]=true; });
  if(Object.keys(_trashedIds).length){
    merged.brews=(merged.brews||[]).filter(function(b){ return !_trashedIds[b.id]; });
    merged.log=(merged.log||[]).filter(function(l){ return !_trashedIds[l.id]; });
  }
  mergeArrByUpd('beans','id');
  mergeArrByUpd('equipment','id');
  mergeArrByUpd('filters','id');
  ['roasters','beanNames','milks','juices'].forEach(function(key){
    var set={};
    (local[key]||[]).concat(merged[key]||[]).forEach(function(v){ if(v) set[v]=true; });
    merged[key]=Object.keys(set);
  });
  merged.id=Math.max(local.id||0, merged.id||0);
  merged.record=Math.max(local.record||0, merged.record||0);
  merged.achEarned=Object.assign({}, merged.achEarned||{}, local.achEarned||{});
  /* ХР більше не окреме поле що може розсинхронитись — рахуємо наново з готових brews+achEarned після злиття */
  merged.xp = computeTotalXp(merged);
  return merged;
}
var sbSaveTimer=null;
var _sbSaving=false;
/* ── Примусове перезаписування сервера поточною локальною версією, без злиття.
   Використовувати коли впевнений, що ЦЕЙ пристрій має правильні дані (наприклад,
   видалив рецепти тут, а на іншому пристрої вони ще старі) ── */
async function forcePushToServer(){
  if(!TG_USER_ID){toast('Немає підключення до Telegram');return;}
  if(!confirm('Це перезапише дані на сервері поточною версією цього пристрою, без об\'єднання з тим що могло змінитись на інших пристроях. Продовжити?'))return;
  try{
    toast('Зберігаю на сервер...');
    var postRes=await fetch(SUPABASE_URL+'/rest/v1/users',{
      method:'POST',
      headers:{
        'apikey':SUPABASE_KEY,
        'Authorization':'Bearer '+SUPABASE_KEY,
        'Content-Type':'application/json',
        'Prefer':'resolution=merge-duplicates'
      },
      body:JSON.stringify({telegram_id:TG_USER_ID,data:S,updated_at:new Date().toISOString()})
    });
    console.log('[forcePushToServer] статус:', postRes.status, 'рецептів відправлено:', (S.brews||[]).length);
    if(postRes.status>=200&&postRes.status<300){
      toast('Готово! На сервері тепер '+(S.brews||[]).length+' рецептів');
    } else {
      toast('Помилка збереження — деталі в консолі');
    }
  }catch(e){
    console.log('[forcePushToServer] ПОМИЛКА:', e.message);
    toast('Помилка: '+e.message);
  }
}
async function _doSbSaveNow(){
  if(!TG_USER_ID)return;
  if(S.id===0&&S.xp===0&&(!S.log||S.log.length===0))return;
  if(_sbSaving){console.log('[sbSave] вже виконується — пропускаю повторний запуск');return;}
  _sbSaving=true;
  try{
    console.log('[sbSave] СТАРТ — пряме перезаписування, рецептів:', (S.brews||[]).length);
    localStorage.setItem('cj_v7',JSON.stringify(S));
    var postRes=await fetch(SUPABASE_URL+'/rest/v1/users',{
      method:'POST',
      headers:{
        'apikey':SUPABASE_KEY,
        'Authorization':'Bearer '+SUPABASE_KEY,
        'Content-Type':'application/json',
        'Prefer':'resolution=merge-duplicates'
      },
      body:JSON.stringify({telegram_id:TG_USER_ID,data:S,updated_at:new Date().toISOString()})
    });
    console.log('[sbSave] POST статус:', postRes.status, '— готово, рецептів відправлено:', (S.brews||[]).length);
  }catch(e){console.log('[sbSave] ПОМИЛКА:', e.message);}
  finally{_sbSaving=false;}
}
function sbSave(){
  if(!TG_USER_ID)return;
  /* Не зберігаємо поки не завантажились з Supabase */
  if(TG_USER_ID&&!_sbLoaded)return;
  /* Не зберігаємо порожній SEED — захист від затирання реальних даних */
  if(S.id===0&&S.xp===0&&(!S.log||S.log.length===0))return;
  clearTimeout(sbSaveTimer);
  sbSaveTimer=setTimeout(_doSbSaveNow,1200);
}
/* ── Мобільний Telegram WebView може призупинити/вбити вкладку при перемиканні швидше ніж встигне відпрацювати дебаунс (1.2с) — тому при втраті фокусу зберігаємо НЕГАЙНО, без очікування.
   Але Telegram WebView може слати visibility_changed дуже часто навіть від дрібних взаємодій — тому обмежуємо: не частіше ніж раз на 3с ── */
var _lastImmediateFlush=0;
function _flushSaveThrottled(){
  var now=Date.now();
  if(now-_lastImmediateFlush<3000)return;
  _lastImmediateFlush=now;
  clearTimeout(sbSaveTimer);
  _doSbSaveNow();
}
document.addEventListener('visibilitychange', function(){
  if(document.hidden && TG_USER_ID && _sbLoaded) _flushSaveThrottled();
});
window.addEventListener('pagehide', function(){
  if(TG_USER_ID && _sbLoaded) _flushSaveThrottled();
});
