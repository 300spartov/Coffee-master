function openXpHistory(){
  renderXpHistoryList();
  openOv('ov-xp-history');
}

function renderXpHistoryList(){
  var el = document.getElementById('xp-history-list');
  if(!el) return;
  var items = [];
  (S.brews||[]).forEach(function(b){
    items.push({amount:15, reason:b.cafeVisit?"Кав'ярня":(b.method||t('brew_title')), ts:b.ts});
  });
  var defs = buildAchievements();
  Object.keys(S.achEarned||{}).forEach(function(id){
    var a = defs.find(function(d){return d.id===id;});
    if(a) items.push({amount:a.xp, reason:a.name, ts:S.achEarned[id]});
  });
  items.sort(function(a,b){ return (b.ts||0)-(a.ts||0); });
  if(!items.length){
    el.innerHTML='<div style="text-align:center;padding:40px 20px;color:var(--txt3);font-size:13px"><i class="ti ti-bolt" style="font-size:32px;display:block;margin-bottom:10px;opacity:.3"></i>Поки немає нарахувань XP</div>';
    return;
  }
  el.innerHTML = items.map(function(e){
    var dateStr = e.ts ? new Date(e.ts).toLocaleDateString('uk',{day:'numeric',month:'short',year:'numeric'}) : '';
    var timeStr = e.ts ? new Date(e.ts).toLocaleTimeString('uk',{hour:'2-digit',minute:'2-digit'}) : '';
    return '<div style="display:flex;align-items:center;justify-content:space-between;gap:10px;background:linear-gradient(165deg,var(--card-hi),var(--card),var(--card-lo));border:1px solid var(--line-soft);border-radius:13px;padding:12px 14px;margin-bottom:8px">'
      +'<div style="min-width:0;flex:1">'
      +'<div style="font-size:13.5px;font-weight:600;color:var(--txt);white-space:nowrap;overflow:hidden;text-overflow:ellipsis">'+(e.reason||'XP')+'</div>'
      +'<div style="font-size:11px;color:var(--txt3);margin-top:2px">'+dateStr+(timeStr?' · '+timeStr:'')+'</div>'
      +'</div>'
      +'<div style="font-family:var(--mono);font-size:14px;font-weight:700;color:var(--copper-lt);white-space:nowrap;flex-shrink:0">+'+e.amount+' XP</div>'
      +'</div>';
  }).join('');
}
