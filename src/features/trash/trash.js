/* ══════════════════════════════════════════
   ВИДАЛЕННЯ РЕЦЕПТІВ — кошик 30 днів
══════════════════════════════════════════ */
var TRASH_TTL = 30 * 24 * 60 * 60 * 1000;

function softDeleteBrew(id){
  if(!S.trash) S.trash = [];
  var idx = S.brews.findIndex(function(b){ return b.id===id; });
  if(idx===-1) return;
  var brew = S.brews.splice(idx, 1)[0];
  /* ── Повертаємо списане зерно та фільтр назад на склад ── */
  var doseNum=parseFloat(brew.dose);
  if(!isNaN(doseNum)&&doseNum>0){
    var bean=null;
    if(brew.beanId!=null) bean=S.beans.find(function(x){return x.id===brew.beanId;});
    if(!bean&&brew.beanName){
      var bn=(''+brew.beanName).trim().toLowerCase(), br=(''+(brew.roaster||'')).trim().toLowerCase();
      bean=S.beans.find(function(x){return (''+x.name).trim().toLowerCase()===bn&&(''+(x.roaster||'')).trim().toLowerCase()===br;});
    }
    if(bean){ bean.current=Math.min(bean.total,bean.current+doseNum); bean._upd=Date.now(); }
  }
  if(brew.filterId!=null){
    var filt=S.filters.find(function(x){return x.id===brew.filterId;});
    if(filt){ filt.current=Math.min(filt.total,filt.current+1); }
  }
  brew._deletedAt = Date.now();
  S.trash.push(brew);
  var brewDay = dayKey(new Date(brew.ts));
  var brewBean = (brew.beanName||'').toLowerCase();
  S.log = S.log.filter(function(e){
    if(e.id===brew.id) return false;
    var sameDay = dayKey(new Date(e.ts))===brewDay;
    var sameBean = (e.bean||'').toLowerCase()===brewBean;
    if(sameDay && sameBean) return false;
    return true;
  });
  var _st = calcStreak();
  if(_st>(S.record||0)) S.record = _st;
  save();
  clearTimeout(sbSaveTimer);
  _doSbSaveNow();
  renderStreak();
  if(typeof renderCalendar==='function')renderCalendar();
  var outer = document.getElementById('so-'+id);
  if(!outer) { renderFeed(); return; }
  var card = outer.querySelector('.brew-card');
  if(card) { card.classList.add('bc-deleting'); card.style.transform='translateX(-120px)'; }
  setTimeout(function(){
    outer.style.transition='max-height .35s ease,opacity .3s,margin .3s';
    outer.style.overflow='hidden';
    outer.style.maxHeight = outer.offsetHeight+'px';
    requestAnimationFrame(function(){
      outer.style.maxHeight='0'; outer.style.opacity='0';
      outer.style.marginBottom='0'; outer.style.marginTop='0';
    });
  }, 280);
  showBrewDeleteToast();
}

function showBrewDeleteToast(){
  var t = document.getElementById('brew-del-toast');
  if(!t) return;
  t.classList.add('show');
  clearTimeout(t._timer);
  t._timer = setTimeout(function(){ t.classList.remove('show'); }, 3000);
}

function initBrewSwipe(cardEl){
  cardEl._swipeReady = true;
  var DEL_W=84, THRESHOLD=40;
  var startX=0, startY=0, curX=0, open=false, dragging=false, dirLocked=null;
  function clamp(x){ return Math.max(-DEL_W, Math.min(0, x)); } /* exactly DEL_W — card aligns flush with delete button */
  function onStart(x,y){ startX=x; startY=y; curX=open?-DEL_W:0; dragging=true; dirLocked=null; cardEl.classList.add('bc-swiping'); cardEl.classList.remove('bc-snapping'); }
  function onMove(x,y){
    if(!dragging) return;
    var dx=x-startX, dy=y-startY;
    if(!dirLocked){ if(Math.abs(dx)<5&&Math.abs(dy)<5) return; dirLocked=Math.abs(dx)>Math.abs(dy)?'h':'v'; }
    if(dirLocked==='v') return;
    curX=clamp((open?-DEL_W:0)+dx); cardEl.style.transform='translateX('+curX+'px)';
  }
  function onEnd(){
    if(!dragging||dirLocked!=='h'){ dragging=false; return; }
    dragging=false; cardEl.classList.remove('bc-swiping'); cardEl.classList.add('bc-snapping');
    if(!open&&curX<-THRESHOLD){ cardEl.style.transform='translateX(-'+DEL_W+'px)'; open=true; }
    else if(open&&curX>-DEL_W+THRESHOLD){ cardEl.style.transform='translateX(0)'; open=false; }
    else if(open){ cardEl.style.transform='translateX(-'+DEL_W+'px)'; }
    else{ cardEl.style.transform='translateX(0)'; }
  }
  cardEl.addEventListener('mousedown', function(e){ onStart(e.clientX,e.clientY); });
  window.addEventListener('mousemove', function(e){ if(dragging) onMove(e.clientX,e.clientY); });
  window.addEventListener('mouseup', onEnd);
  cardEl.addEventListener('touchstart', function(e){ var t=e.touches[0]; onStart(t.clientX,t.clientY); }, {passive:true});
  cardEl.addEventListener('touchmove', function(e){ var t=e.touches[0]; onMove(t.clientX,t.clientY); }, {passive:true});
  cardEl.addEventListener('touchend', onEnd);
  document.addEventListener('click', function(e){
    if(open&&!cardEl.contains(e.target)){ cardEl.classList.add('bc-snapping'); cardEl.style.transform='translateX(0)'; open=false; }
  });
}

function purgeOldTrash(){
  if(!S.trash) return;
  var now = Date.now();
  S.trash = S.trash.filter(function(b){ return now-(b._deletedAt||0)<TRASH_TTL; });
  save();
}

function openDeletedTrash(){
  purgeOldTrash();
  renderTrashList();
  openOv('ov-trash');
}

function renderTrashList(){
  var el = document.getElementById('trash-list');
  if(!el) return;
  var now = Date.now();
  var items = (S.trash||[]).slice().sort(function(a,b){ return b._deletedAt-a._deletedAt; });
  if(!items.length){
    el.innerHTML='<div style="text-align:center;padding:40px 20px;color:var(--txt3);font-size:13px"><i class="ti ti-trash" style="font-size:32px;display:block;margin-bottom:10px;opacity:.3"></i>Немає видалених рецептів</div>';
    return;
  }
  el.innerHTML = items.map(function(b){
    var daysLeft = Math.ceil((TRASH_TTL-(now-b._deletedAt))/86400000);
    var dateShort = b.ts ? (function(){var d=new Date(b.ts);var p=function(n){return(n<10?'0':'')+n;};return p(d.getDate())+'.'+p(d.getMonth()+1)+'.'+String(d.getFullYear()).slice(2);})() : '';
    var ratColor=(function(){var r=parseFloat(b.rating||0);return r>=8?'#5fbf83':r>=6.5?'#b9c64f':r>=5?'#e2c64c':r>=3.5?'#ea9b3c':'#ea6a52';})();
    var mlVal = b.espresso ? (b.espresso.actualYield||b.espresso.targetYield||'—') : (b.totalMl||Math.round((parseFloat(b.dose)||16)*(parseFloat(b.ratio)||16))||'—');
    var timeVal = b.totalTime||'—';
    return '<div style="background:linear-gradient(165deg,var(--card-hi),var(--card),var(--card-lo));border:1px solid var(--line-soft);border-left:3px solid '+ratColor+';border-radius:13px;padding:13px 14px;margin-bottom:9px">'
      +'<div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px">'
      +'<div style="min-width:0;flex:1">'
      +'<div style="font-size:14px;font-weight:600;color:var(--txt);white-space:nowrap;overflow:hidden;text-overflow:ellipsis">'+(b.beanName||t('journal_no_name'))+'</div>'
      +(b.roaster?'<div style="font-size:9.5px;color:var(--txt3);margin-top:1px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">'+b.roaster+'</div>':'')
      +'</div>'
      +'<div style="text-align:right;flex-shrink:0">'
      +'<span style="font-family:var(--mono);font-size:11px;font-weight:700;background:rgba(255,255,255,.06);border-radius:6px;padding:2px 7px;color:var(--txt2)">'+(b.method||'')+'</span>'
      +'<div style="font-family:var(--mono);font-size:15px;font-weight:700;color:'+ratColor+';margin-top:3px">'+parseFloat(b.rating||0).toFixed(1)+'</div>'
      +'</div>'
      +'</div>'
      +'<div style="display:flex;gap:6px;margin-top:9px">'
      +'<div style="flex:1;background:var(--card-lo);border-radius:8px;padding:6px 4px;text-align:center"><div style="font-family:var(--mono);font-size:12px;font-weight:700;color:var(--txt)">'+(b.dose||'—')+'г</div><div style="font-size:8px;color:var(--txt3);text-transform:uppercase;margin-top:1px">Доза</div></div>'
      +'<div style="flex:1;background:var(--card-lo);border-radius:8px;padding:6px 4px;text-align:center"><div style="font-family:var(--mono);font-size:12px;font-weight:700;color:var(--txt)">'+mlVal+'мл</div><div style="font-size:8px;color:var(--txt3);text-transform:uppercase;margin-top:1px">Вихід</div></div>'
      +'<div style="flex:1;background:var(--card-lo);border-radius:8px;padding:6px 4px;text-align:center"><div style="font-family:var(--mono);font-size:12px;font-weight:700;color:var(--txt)">'+timeVal+'</div><div style="font-size:8px;color:var(--txt3);text-transform:uppercase;margin-top:1px">Час</div></div>'
      +'</div>'
      +'<div style="display:flex;align-items:center;justify-content:space-between;margin-top:10px;gap:8px">'
      +'<div style="font-family:var(--mono);font-size:9px;color:var(--txt3);white-space:nowrap">'+dateShort+' · '+daysLeft+' дн.</div>'
      +'<div style="display:flex;gap:6px;flex-shrink:0">'
      +'<button onclick="restoreBrew('+b.id+')" style="background:rgba(184,115,51,.12);border:1px solid var(--copper-dk);border-radius:8px;color:var(--copper-lt);font-family:var(--mono);font-size:9.5px;font-weight:600;padding:6px 10px;cursor:pointer;letter-spacing:.3px;white-space:nowrap">'+t('trash_restore')+'</button>'
      +'<button onclick="permanentDeleteBrew('+b.id+')" style="background:rgba(224,40,32,.08);border:1px solid #7a1a1a;border-radius:8px;color:#f5a0a0;font-family:var(--mono);font-size:9.5px;font-weight:600;padding:6px 10px;cursor:pointer;letter-spacing:.3px;white-space:nowrap">Видалити</button>'
      +'</div>'
      +'</div>'
      +'</div>';
  }).join('');
}

function restoreBrew(id){
  if(!S.trash) return;
  var idx = S.trash.findIndex(function(b){ return b.id===id; });
  if(idx===-1) return;
  var brew = S.trash.splice(idx,1)[0];
  delete brew._deletedAt;
  var doseNum=parseFloat(brew.dose);
  if(!isNaN(doseNum)&&doseNum>0){
    var bean=null;
    if(brew.beanId!=null) bean=S.beans.find(function(x){return x.id===brew.beanId;});
    if(!bean&&brew.beanName){
      var bn=(''+brew.beanName).trim().toLowerCase(), br=(''+(brew.roaster||'')).trim().toLowerCase();
      bean=S.beans.find(function(x){return (''+x.name).trim().toLowerCase()===bn&&(''+(x.roaster||'')).trim().toLowerCase()===br;});
    }
    if(bean){ bean.current=Math.max(0,bean.current-doseNum); bean._upd=Date.now(); }
  }
  if(brew.filterId!=null){
    var filt=S.filters.find(function(x){return x.id===brew.filterId;});
    if(filt){ filt.current=Math.max(0,filt.current-1); }
  }
  var inserted = false;
  for(var k=0; k<S.brews.length; k++){ if(S.brews[k].ts<=brew.ts){ S.brews.splice(k,0,brew); inserted=true; break; } }
  if(!inserted) S.brews.push(brew);
  var logEntry={id:brew.id,ts:brew.ts,vol:Math.round((parseFloat(brew.dose)||16)*(parseFloat(brew.ratio)||16)),cat:methodCat(brew.method||''),method:brew.method||'',bean:brew.beanName||'',rating:brew.rating||8,dose:parseFloat(brew.dose)||16};
  var logInserted=false;
  for(var k=0;k<S.log.length;k++){ if(S.log[k].ts<=brew.ts){ S.log.splice(k,0,logEntry); logInserted=true; break; } }
  if(!logInserted) S.log.push(logEntry);
  var _st=calcStreak(); if(_st>(S.record||0)) S.record=_st;
  save();
  clearTimeout(sbSaveTimer);
  _doSbSaveNow();
  renderStreak(); renderTrashList(); renderFeed();
  if(typeof renderCalendar==='function')renderCalendar();
  toast('Рецепт відновлено');
}

function permanentDeleteBrew(id){
  if(!S.trash) return;
  S.trash = S.trash.filter(function(b){ return b.id!==id; });
  save();
  clearTimeout(sbSaveTimer);
  _doSbSaveNow();
  renderTrashList();
}
