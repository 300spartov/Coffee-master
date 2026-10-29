/* ══════════════════════════════════════
   ЕКСПОРТ ДАНИХ — файл .json зі станом S (той самий формат, що cj_v7 у localStorage).
   Потрібен для перенесення історії в iOS-застосунок: Налаштування → «Import from Web App».
   Спочатку пробуємо системне меню «Поділитися» (працює в Telegram/мобільних браузерах),
   інакше — звичайне завантаження файлу.
   ══════════════════════════════════════ */
function _exportFileName(){
  var d=new Date(),p=function(n){return (n<10?'0':'')+n;};
  return 'coffee-master-'+d.getFullYear()+'-'+p(d.getMonth()+1)+'-'+p(d.getDate())+'.json';
}
function exportData(){
  var json;
  try{ json=JSON.stringify(S); }catch(e){ console.error('exportData',e); toast(t('export_error')); return; }
  var name=_exportFileName();
  var file=null;
  try{ file=new File([json],name,{type:'application/json'}); }catch(e){}
  if(file&&navigator.share&&navigator.canShare&&navigator.canShare({files:[file]})){
    navigator.share({files:[file],title:'Coffee Master'})
      .then(function(){ toast(t('export_done')); })
      .catch(function(e){ if(e&&e.name==='AbortError')return; _exportDownload(json,name); });
    return;
  }
  _exportDownload(json,name);
}
function _exportDownload(json,name){
  try{
    var url=URL.createObjectURL(new Blob([json],{type:'application/json'}));
    var a=document.createElement('a');a.href=url;a.download=name;
    document.body.appendChild(a);a.click();a.remove();
    setTimeout(function(){URL.revokeObjectURL(url);},4000);
    toast(t('export_done'));
  }catch(e){ console.error('exportData download',e); toast(t('export_error')); }
}
