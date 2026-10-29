/* ── РУЧНОЕ ДОБАВЛЕНИЕ В ЖУРНАЛ ── */
var _lbSource='home';

function lbSetSource(src){
  _lbSource=src;
  var bH=document.getElementById('lb-src-home'),bP=document.getElementById('lb-src-place');
  var pw=document.getElementById('lb-place-wrap'),hp=document.getElementById('lb-home-params');
  var on='flex:1;padding:9px 6px;border-radius:8px;border:none;cursor:pointer;font-family:inherit;font-size:12.5px;font-weight:700;box-shadow:inset 0 1px 0 rgba(255,255,255,.05);';
  var off='flex:1;padding:9px 6px;border-radius:8px;border:none;cursor:pointer;font-family:inherit;font-size:12.5px;font-weight:700;background:none;';
  if(src==='home'){
    if(bH)bH.style.cssText=on+'background:linear-gradient(160deg,var(--card-hi),var(--card-lo));color:var(--copper-lt);';
    if(bP)bP.style.cssText=off+'color:var(--txt3);';
    if(pw)pw.style.display='none';
    if(hp)hp.style.display='block';
  } else {
    if(bP)bP.style.cssText=on+'background:linear-gradient(160deg,#1a2030,#121820);color:var(--steel);';
    if(bH)bH.style.cssText=off+'color:var(--txt3);';
    if(pw)pw.style.display='block';
    if(hp)hp.style.display='none';
  }
}

function openLogBrew(){
  _lbSource='home';
  var t=new Date();
  var d=t.getFullYear()+'-'+String(t.getMonth()+1).padStart(2,'0')+'-'+String(t.getDate()).padStart(2,'0');
  var el=document.getElementById('lb-date');if(el)el.value=d;
  ['lb-bean','lb-notes','lb-place','lb-grinder'].forEach(function(id){var e=document.getElementById(id);if(e)e.value='';});
  var defaults={lb_vol:'240',lb_rating:'8.0',lb_dose:'16',lb_temp:'93'};
  Object.keys(defaults).forEach(function(k){var e=document.getElementById(k.replace('_','-'));if(e)e.value=defaults[k];});
  var r=document.getElementById('lb-ratio');if(r)r.value='16';
  var m=document.getElementById('lb-method');if(m)m.value='V60';
  if(typeof BS!=='undefined'&&BS.grinder){var g=document.getElementById('lb-grinder');if(g)g.value=BS.grinder.name;}
  lbSetSource('home');
  openOv('ov-log-brew');
}

function logBrewManual(){
  var dateVal=(document.getElementById('lb-date')||{}).value||'';
  if(!dateVal){toast('Укажи дату');return;}
  var bean=((document.getElementById('lb-bean')||{}).value||'').trim()||'Кофе';
  var method=(document.getElementById('lb-method')||{}).value||'V60';
  var vol=parseInt((document.getElementById('lb-vol')||{}).value)||240;
  var rating=Math.round((parseFloat((document.getElementById('lb-rate-slider')||{}).value)||8)*10)/10;
  var notes=((document.getElementById('lb-notes')||{}).value||'').trim();
  var place=_lbSource==='place'?((document.getElementById('lb-place')||{}).value||'').trim():'';
  var parts=dateVal.split('-');
  var ts=new Date(+parts[0],+parts[1]-1,+parts[2],12,0,0).getTime();
  var entry={id:++S.id,ts:ts,vol:vol,cat:methodCat(method),method:method,bean:bean,rating:rating,source:_lbSource,manual:true};
  if(notes)entry.notes=notes;
  if(place)entry.place=place;
  if(_lbSource==='home'){
    entry.dose=parseFloat((document.getElementById('lb-dose')||{}).value)||16;
    entry.ratio=parseInt((document.getElementById('lb-ratio')||{}).value)||16;
    entry.temp=parseInt((document.getElementById('lb-temp')||{}).value)||93;
    var gr=((document.getElementById('lb-grinder')||{}).value||'').trim();
    if(gr)entry.grinder=gr;
  }
  // Insert into S.log (calendar/stats)
  var inserted=false;
  for(var i=0;i<S.log.length;i++){if(S.log[i].ts<=ts){S.log.splice(i,0,entry);inserted=true;break;}}
  if(!inserted)S.log.push(entry);

  // Also insert into S.brews (feed) so it appears in the list
  var brewEntry={
    id:entry.id, ts:ts, beanName:bean, roaster:'', method:method,
    dripper:'', grinder:entry.grinder||'', clicks:0,
    temp:entry.temp||93, ratio:entry.ratio||16, filter:'', filterWet:true,
    dose:entry.dose||16, steps:[], totalTime:'—',
    rating:rating, flavors:[], aroma:[], notes:notes||'',
    likes:0, liked:false, manual:true,
    place: place||''
  };
  var bInserted=false;
  for(var i=0;i<S.brews.length;i++){if(S.brews[i].ts<=ts){S.brews.splice(i,0,brewEntry);bInserted=true;break;}}
  if(!bInserted)S.brews.push(brewEntry);

  addBrewXp('alt', method, brewEntry.id);
  var streak=calcStreak();if(streak>(S.record||0))S.record=streak;
  save();closeOv('ov-log-brew');
  renderCalendar();renderStreak();renderFeed();
  toast(place?'Додано: '+place:'Додано: '+bean);
}
