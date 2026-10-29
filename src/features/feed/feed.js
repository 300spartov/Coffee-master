/* ── FEED ── */
let feedTab='mine';
function setFeedTab(tab){
  feedTab=tab;
  document.getElementById('ft-mine').classList.toggle('on',tab==='mine');
  document.getElementById('ft-comm').classList.toggle('on',tab==='comm');
  document.getElementById('feed-sub').textContent=tab==='mine'?t('journal_my_recipes'):t('journal_discussion');
  renderFeed();
}

function _dayGroupLabel(ts){
  var d=new Date(ts);
  var now=new Date();
  var d0=new Date(d.getFullYear(),d.getMonth(),d.getDate());
  var n0=new Date(now.getFullYear(),now.getMonth(),now.getDate());
  var diffDays=Math.round((n0-d0)/86400000);
  var pad=function(n){return (n<10?'0':'')+n;};
  var dateStr=pad(d.getDate())+'.'+pad(d.getMonth()+1)+'.'+d.getFullYear();
  if(diffDays===0)return 'Сьогодні · '+dateStr;
  if(diffDays===1)return 'Вчора · '+dateStr;
  if(diffDays===2)return 'Позавчора · '+dateStr;
  var weekdays=['Нд','Пн','Вт','Ср','Чт','Пт','Сб'];
  return dateStr+' · '+weekdays[d.getDay()];
}
function _dayKeyOf(ts){
  var d=new Date(ts);
  return d.getFullYear()+'-'+d.getMonth()+'-'+d.getDate();
}
function renderFeed(){
  const hs=document.getElementById('hdr-streak');
  if(hs)hs.classList.toggle('show',feedTab==='mine');
  if(feedTab!=='mine'){const p=document.getElementById('streak-panel');if(p&&p.classList.contains('open')){p.classList.remove('open');hs&&hs.classList.remove('lit');}}
  else{renderStreak();renderCalendar();}
  const el=document.getElementById('feed-list');
  if(feedTab==='comm'){renderCommunity(el);return}
  if(!S.brews.length){el.innerHTML=`<div class="empty"><i class="ti ti-coffee" aria-hidden="true"></i><div class="empty-t">${t('journal_no_recipes')}</div><div class="empty-s">${t('journal_empty_hint')}</div></div>`;return}
var _lastDayKey=null;
el.innerHTML=S.brews.map(b=>{
  try{
  const bid=b.id;
  /* ── колір за оцінкою ── */
  const ratColor=(function(){var r=parseFloat(b.rating||0);return r>=8?'#5fbf83':r>=6.5?'#b9c64f':r>=5?'#e2c64c':r>=3.5?'#ea9b3c':'#ea6a52';})();
  /* ── колір для довідки (не використовується у пілюлі, лишено для сумісності) ── */
  const methodCol=(function(){var m=(b.method||'').toLowerCase();
    if(m.indexOf('еспрес')>-1||m.indexOf('espres')>-1)return'#c0533a';
    if(m.indexOf('v60')>-1)return'#3f8fd6';
    if(m.indexOf('aero')>-1)return'#7c5cbf';
    if(m.indexOf('chemex')>-1)return'#d89858';
    if(m.indexOf('kalita')>-1)return'#3aabaa';
    if(m.indexOf('french')>-1||m.indexOf('френч')>-1)return'#b5683e';
    if(m.indexOf('cold')>-1||m.indexOf('колд')>-1||m.indexOf('холод')>-1)return'#2f7fb0';
    if(m.indexOf('batch')>-1||m.indexOf('бетч')>-1||m.indexOf('бэтч')>-1)return'#5a8f5a';
    if(m.indexOf('drip')>-1||m.indexOf('дрип')>-1)return'#6f8fb8';
    return'';})();
  /* ── СПОСІБ заварювання vs ДЕВАЙС ──
     Якщо в method стоїть назва воронки (Flower/Kalita/Origami…) — показуємо спосіб V60,
     а саму назву воронки виводимо нижче як девайс. */
  const _DEVICE_TO_METHOD=[
    {re:/flower|origami|kalita|switch|orea|пуровер|pour\s*over/i, method:'V60', dev:true},
  ];
  const _rawMethod=(b.method||'').trim();
  let displayMethod=_rawMethod||t('method_alt');
  let _autoDev='';
  for(const r of _DEVICE_TO_METHOD){ if(r.re.test(_rawMethod)){ displayMethod=r.method; if(r.dev)_autoDev=_rawMethod; break; } }
  /* девайс/модель під способом (CAFEC Flower Dripper, Kalita Wave 185, AeroPress Go…) */
  const brewDevice=(b.device||b.dripper||_autoDev||'').trim();
  /* ── маркер "випито в закладі": cafeVisit (fallback на дані ручного логу) ── */
  const cafeOn=!!(b.cafeVisit||b.source==='place'||(b.place&&b.place.length));
  const cafeMarker=cafeOn?`<div class="bc-cafe-chip"><i class="ti ti-building-store" aria-hidden="true"></i>Кав'ярня${b.place?` · <span style="color:#e8edf2;font-weight:700">${b.place}</span>`:''}</div>`:'';
  const totalMs=b.steps&&b.steps.length?Math.max(...b.steps.map(s=>s.t+(s.ph||0))):0;
  const totalSec=Math.round(totalMs/1000);

  /* ── ЛОГ ── */
  const _hasSteps=!!(b.steps&&b.steps.filter(s=>s.type==='pour'||s.type==='pause'||s.type==='action').length);
  const _isEspLog=!!b.espresso&&!_hasSteps;
  const _espRow=(k,v)=>`<div class="bc-esp-trow"><span class="k">${k}</span><span class="v">${v}</span></div>`;
  const _espTable=(()=>{const e=b.espresso||{};const rows=[
    _espRow(t('brew_dose_label'),`${b.dose||'—'} г`),
    _espRow(t('brew_shot_time'),b.totalTime||(e.shotTime?Math.floor(e.shotTime/60)+':'+(e.shotTime%60<10?'0':'')+(e.shotTime%60):'—')),
    _espRow(t('brew_yield'),`${e.actualYield||e.targetYield||'—'} мл`),
    _espRow('Ratio',`1:${b.ratio||'—'}`),
    _espRow(t('brew_pressure'),`${String(e.pressure||'9').replace(/\s*бар\s*/gi,'').trim()} бар`)
  ];if(e.tdsActual)rows.push(_espRow(t('brew_tds_actual'),`${e.tdsActual}%`));if(e.tdsTarget)rows.push(_espRow(t('brew_tds_target'),`${e.tdsTarget}%`));return`<div class="bc-esp-table">${rows.join('')}</div>`;})();
  const logRows = cafeOn ? ''
    : _isEspLog ? _espTable
    : (b.steps&&b.steps.length?b.steps.map((st,si,arr)=>{
    const _stE=st.t+(st.ph!=null?st.ph:(st.dur||0)*1000);
    const _fR=function(ms){const s=Math.floor(ms/1000),m=Math.floor(s/60),sc=s%60;return(m<10?'0':'')+m+':'+(sc<10?'0':'')+sc;};
    const _rng=_fR(st.t)+'–'+_fR(_stE);
    const _ds=Math.round((st.ph!=null?st.ph:(st.dur||0)*1000)/1000);
    if(st.type==='action'){
      const actionColor=st.color||'#5fbf83';
      return`<div class="bc-log-row"><span class="bc-log-badge action" style="background:${actionColor}20;color:${actionColor};border-color:${actionColor}40">${st.label||'Дія'}</span><span class="bc-log-t" style="font-size:10px;min-width:88px">${_rng}</span><span class="bc-log-ph">${_ds}с</span></div>`;
    }
    return`<div class="bc-log-row"><span class="bc-log-badge ${st.type==='pour'?'pour':'pause'}">${st.type==='pour'?t('brew_pour'):t('brew_pause')}</span><span class="bc-log-t" style="font-size:10px;min-width:88px">${_rng}</span><span class="bc-log-ph">${_ds}с</span>${st.ml!=null?`<span class="bc-log-ml">${st.ml.toFixed(1)}мл</span>`:''}</div>`;
  }).join(''):'<div style="font-size:12px;color:var(--txt3);padding:8px 0">'+t('journal_no_log')+'</div>');

  /* ── ДИАГРАММА — кольцо (из b.steps) ── */
  const _steps=(b.steps||[]).filter(s=>s.type==='pour'||s.type==='pause'||s.type==='action');
  const _totalSec=_steps.reduce((s,x)=>s+(x.ph!=null?x.ph/1000:(x.dur||0)),0)||1;
  const _COL={pour:{base:'#3E8FCE',on:'#74C0F5',glow:'rgba(116,192,245,.6)'},pause:{base:'#DC7E16',on:'#F7AC34',glow:'rgba(247,172,52,.6)'},action:{base:'#6C6C72',on:'#C3BFB8',glow:'rgba(178,178,188,.6)'}};
  const _ACTION_COL={'Перемішування':'#5fbf83','Чавимо':'#7c5cbf','Свьорл':'#38C4B8','Взбалтування':'#B8A0E8','Взбалтывание':'#B8A0E8','Перемешивание':'#5fbf83'};
  const _CX=140,_CY=140,_R=104,_W=14,_GAP=2.8;
  const _totGap=(_steps.length>1?(_steps.length-1)*_GAP:0)+_GAP;
  const _span=360-_totGap;
  function _rpol(deg){const a=(deg-90)*Math.PI/180;return[_CX+_R*Math.cos(a),_CY+_R*Math.sin(a)];}
  function _rarc(a0,a1){const[x0,y0]=_rpol(a0),[x1,y1]=_rpol(a1);const lg=(a1-a0)>180?1:0;return`M${x0.toFixed(2)} ${y0.toFixed(2)} A${_R} ${_R} 0 ${lg} 1 ${x1.toFixed(2)} ${y1.toFixed(2)}`;}
  let _rp='',_rc=_GAP/2;
  if(_steps.length===0&&b.espresso){
    const espSec=parseInt(b.totalTime)||0;
    const maxSec=60;
    const fillDeg=Math.min(espSec/maxSec,1)*360;
    if(fillDeg>0){
      const a0=0,a1=fillDeg>359?359.9:fillDeg;
      _rp=`<path d="${_rarc(a0,a1)}" fill="none" stroke="#3E8FCE" stroke-width="${_W}" stroke-linecap="butt" class="rring-seg"/>`;
    }
  } else {
    _steps.forEach((st,i)=>{
      const dur=st.ph!=null?st.ph/1000:(st.dur||0);
      const sp=dur/_totalSec*_span;
      /* B4: action кроки використовують свій колір з кроку */
      const col=(st.type==='action'&&st.label&&_ACTION_COL[st.label])?{base:_ACTION_COL[st.label],on:_ACTION_COL[st.label],glow:'rgba(0,0,0,0)'}:(_COL[st.type]||_COL.action);
      const baseColor=(st.type==='action'&&st.label&&_ACTION_COL[st.label])?_ACTION_COL[st.label]:(st.type==='action'&&st.color)?st.color:(_COL[st.type]||_COL.action).base;
      _rp+=`<path d="${_rarc(_rc,_rc+sp)}" fill="none" stroke="${baseColor}" stroke-width="${_W}" stroke-linecap="butt" class="rring-seg" onclick="ringTap(${bid},${i})" style="cursor:pointer;transition:stroke-width .28s cubic-bezier(.3,.8,.3,1),stroke .25s,opacity .25s,filter .25s"/>`;
      _rc+=sp+_GAP;
    });
  }
  const donutSVG=`<div style="position:relative;width:280px;height:280px;margin:0 auto">
    <svg viewBox="0 0 280 280" width="280" height="280" id="rring-${bid}">
      <circle cx="${_CX}" cy="${_CY}" r="${_R}" fill="none" stroke="#202225" stroke-width="${_W}"/>
      ${_rp}
    </svg>
    <div id="rring-center-${bid}" style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:168px;height:168px;border-radius:50%;overflow:hidden;display:flex;flex-direction:column;align-items:stretch;background:radial-gradient(120% 120% at 50% 18%,#2f3237 0%,#212328 52%,#191b1e 100%);border:1px solid rgba(255,255,255,.07);box-shadow:0 10px 22px rgba(0,0,0,.5),0 2px 5px rgba(0,0,0,.45),inset 0 1px 0 rgba(255,255,255,.06),inset 0 -8px 18px rgba(0,0,0,.35)">
      <div onclick="ringNext(${bid})" style="flex:1;position:relative;display:flex;flex-direction:column;align-items:center;cursor:pointer;box-shadow:inset 0 -1px 0 rgba(0,0,0,.4);transition:background .14s;min-height:0" onmouseover="this.style.background='rgba(255,255,255,.025)'" onmouseout="this.style.background=''" onmousedown="this.style.background='rgba(0,0,0,.18)'" onmouseup="this.style.background='rgba(255,255,255,.025)'">
        <div id="rring-c-${bid}" style="font-family:var(--mono);font-size:10px;letter-spacing:2px;text-transform:uppercase;color:var(--txt3);padding-top:10px">${t('brew_total')}</div>
        <div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px">
          <div id="rring-t-${bid}" style="font-family:var(--mono);font-weight:700;font-size:38px;letter-spacing:-1.5px;line-height:1;color:var(--txt);transition:color .25s">${b.totalTime||'—'}</div>
          <div id="rring-n-${bid}" style="font-size:13px;font-weight:600;letter-spacing:.3px;min-height:16px;transition:color .25s"></div>
          <div id="rring-x-${bid}" style="font-family:var(--mono);font-size:11px;color:var(--txt2);min-height:13px"></div>
        </div>
        <div id="rring-foot-${bid}" style="font-family:var(--mono);font-size:9.5px;letter-spacing:1.2px;text-transform:uppercase;color:var(--txt3);padding-bottom:8px">${t('brew_stages').toLowerCase()}</div>
      </div>
      <button id="rring-reset-${bid}" onclick="ringReset(${bid})" disabled style="flex-shrink:0;height:38px;border:none;cursor:pointer;background:linear-gradient(180deg,#1c1e21,#191b1e);border-top:1px solid rgba(0,0,0,.55);box-shadow:inset 0 1px 0 rgba(255,255,255,.07);color:var(--txt3);font-family:var(--mono);font-size:10px;font-weight:500;letter-spacing:2px;text-transform:uppercase;display:flex;align-items:center;justify-content:center;gap:6px;transition:background .15s,color .15s;opacity:.4"><svg viewBox="0 0 24 24" style="width:12px;height:12px;stroke:currentColor;fill:none;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round"><polyline points="1 4 1 10 7 10"/><path d="M3.5 15a9 9 0 1 0 2.1-9.4L1 10"/></svg>скинути</button>
    </div>
  </div>`;
  const _actionSteps=_steps.filter(s=>s.type==='action');
  const _uniqueActions=[..._actionSteps.reduce((m,s)=>{if(!m.has(s.label))m.set(s.label,s.color||'#6C6C72');return m;},new Map()).entries()];
  const legendRows=`<div style="display:flex;justify-content:center;gap:14px;margin-top:12px;flex-wrap:wrap"><div style="display:flex;align-items:center;gap:7px"><span style="width:11px;height:11px;border-radius:50%;background:#74C0F5;display:inline-block"></span><span style="font-family:var(--mono);font-size:11px;color:var(--txt2)">${t('brew_pour')}</span></div><div style="display:flex;align-items:center;gap:7px"><span style="width:11px;height:11px;border-radius:50%;background:#F7AC34;display:inline-block"></span><span style="font-family:var(--mono);font-size:11px;color:var(--txt2)">${t('brew_pause')}</span></div>${_uniqueActions.map(([lbl,col])=>`<div style="display:flex;align-items:center;gap:7px"><span style="width:11px;height:11px;border-radius:50%;background:${col};display:inline-block"></span><span style="font-family:var(--mono);font-size:11px;color:var(--txt2)">${lbl}</span></div>`).join('')}</div>`;

  /* ── ЕСПРЕСО без проливів: візуал шоту замість порожнього кільця ── */
  const _esp=b.espresso;
  const isEsp=!!_esp && _steps.length===0;
  const _fmtShot=(sec)=>{sec=Math.round(sec||0);return Math.floor(sec/60)+':'+(sec%60<10?'0':'')+(sec%60);};
  const _shot=_esp?(_esp.shotTime||0):0;
  const _shotStr=b.totalTime||(_shot?_fmtShot(_shot):'—');
  const _shotFill=Math.min((_shot||28)/35,1);
  const _ECIRC=2*Math.PI*86;
  const espM=(ic,v,u,l)=>`<div class="bc-sum-m"><i class="ti ${ic}"></i><div class="v">${v}${u?`<u>${u}</u>`:''}</div><div class="l">${l}</div></div>`;
  const espVisual=isEsp?`<div style="padding:6px 0 2px">
    <div style="position:relative;width:200px;height:200px;margin:0 auto 16px">
      <svg viewBox="0 0 200 200" width="200" height="200">
        <circle cx="100" cy="100" r="86" fill="none" stroke="#202225" stroke-width="20"/>
        <circle cx="100" cy="100" r="86" fill="none" stroke="#c0533a" stroke-width="20" stroke-linecap="round" stroke-dasharray="${_ECIRC.toFixed(1)}" stroke-dashoffset="${(_ECIRC*(1-_shotFill)).toFixed(1)}" transform="rotate(-90 100 100)" style="filter:drop-shadow(0 0 6px rgba(192,83,58,.5))"/>
      </svg>
      <div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center">
        <div style="font-family:var(--mono);font-size:11px;letter-spacing:2px;text-transform:uppercase;color:var(--txt3)">${t('brew_shot_time')}</div>
        <div style="font-family:var(--mono);font-weight:700;font-size:40px;letter-spacing:-1.5px;line-height:1.05;color:var(--txt)">${_shotStr}</div>
        <div style="font-family:var(--mono);font-size:10px;letter-spacing:1px;text-transform:uppercase;color:var(--copper-lt)">${t('method_esp')}</div>
      </div>
    </div>
    <div class="bc-sum-metrics" style="margin-bottom:${(_esp&&_esp.tdsActual)?'8px':'0'}">
      ${espM('ti-scale',b.dose||'—','г',t('brew_dose_label'))}
      ${espM('ti-droplet',(_esp.actualYield||_esp.targetYield||'—'),'мл',t('brew_yield'))}
      ${espM('ti-arrows-right-left','1:'+(b.ratio||'—'),'','Ratio')}
      ${espM('ti-gauge',String(_esp.pressure||'9').replace(/\s*бар\s*/gi,'').trim(),' бар',t('brew_pressure'))}
    </div>
    ${(_esp&&_esp.tdsActual)?`<div class="bc-sum-metrics">
      ${espM('ti-droplet-half',_esp.tdsActual,'%',t('brew_tds_actual'))}
      ${espM('ti-target',(_esp.tdsTarget||'—'),'%',t('brew_tds_target'))}
    </div>`:''}
  </div>`:'';

  /* ── ВКУС / АРОМАТ теги ── */
  const fwTags=(b.flavors&&b.flavors.length)?b.flavors.map(f=>{const nc=noteColorByName(f);const fl=translateFlavor(f);return nc?`<span class="ftag" style="background:${nc};color:#fff">${fl}</span>`:`<span class="ftag ft-other">${fl}</span>`;}).join(''):`<span style="font-size:12px;color:var(--txt3)">${t('journal_not_set')}</span>`;
  const awTags=(b.aroma&&b.aroma.length)?b.aroma.map(f=>{const nc=noteColorByName(f);const fl=translateFlavor(f);return nc?`<span class="ftag" style="background:${nc};color:#fff">${fl}</span>`:`<span class="ftag ft-other">${fl}</span>`;}).join(''):`<span style="font-size:12px;color:var(--txt3)">${t('journal_not_set')}</span>`;

  const notesBox=b.notes?`<div class="bc-notes-box"><div class="bc-notes-lbl">Нотатки</div><div class="bc-notes-txt">${b.notes}</div></div>`:'';

  /* ── Зведення для «Деталі»: метрики + девайси ── */
  const volMl=(b.totalMl!=null)?b.totalMl:((parseFloat(b.dose)&&parseFloat(b.ratio))?Math.round(parseFloat(b.dose)*parseFloat(b.ratio)):null);
  const sumMetrics=[
    b.dose?`<div class="bc-sum-m"><i class="ti ti-scale"></i><div class="v">${b.dose}<u>г</u></div><div class="l">${t('brew_dose_label')}</div></div>`:'',
    volMl?`<div class="bc-sum-m"><i class="ti ti-droplet"></i><div class="v">${volMl}<u>мл</u></div><div class="l">${t('brew_vol_label')}</div></div>`:'',
    b.ratio?`<div class="bc-sum-m"><i class="ti ti-arrows-right-left"></i><div class="v">1:${b.ratio}</div><div class="l">${t('brew_ratio_label')}</div></div>`:'',
    (b.temp&&!cafeOn)?`<div class="bc-sum-m"><i class="ti ti-temperature"></i><div class="v">${b.temp}<u>°</u></div><div class="l">${t('brew_temp_label')}</div></div>`:'',
    (b.totalTime&&b.totalTime!=='—')?`<div class="bc-sum-m"><i class="ti ti-clock"></i><div class="v">${b.totalTime}</div><div class="l">${t('brew_time_label')}</div></div>`:''
  ].join('');
  const _liveBean=liveBeanInfo(b.beanId, b.beanName, b.roaster);
  const devRows=[
    b.dripper?`<div class="bc-dev-row"><span class="ic"><i class="ti ti-filter"></i></span><div><div class="dv-l">${t('devices_dripper')}</div><div class="dv-v">${liveDeviceName(b.dripperId,b.dripper)}</div></div></div>`:'',
    b.filter?`<div class="bc-dev-row"><span class="ic"><i class="ti ti-copy"></i></span><div><div class="dv-l">${t('devices_filter')}</div><div class="dv-v">${liveDeviceName(b.filterId,b.filter)}</div></div></div>`:'',
    b.espMachine?`<div class="bc-dev-row"><span class="ic"><i class="ti ti-coffee"></i></span><div><div class="dv-l">${t('devices_espmachine')}</div><div class="dv-v">${liveDeviceName(b.espMachineId,b.espMachine)}</div></div></div>`:'',
    b.grinder?`<div class="bc-dev-row"><span class="ic"><i class="ti ti-settings"></i></span><div><div class="dv-l">${t('devices_grinder')}</div><div class="dv-v">${liveDeviceName(b.grinderId,b.grinder)}</div></div>${b.clicks?`<span class="dv-clicks">${b.clicks} ${t('brew_clicks')}</span>`:''}</div>`:''
  ].join('');
  const summaryBlock=(sumMetrics||devRows)?`<div class="bc-summary">${sumMetrics?`<div class="bc-sum-metrics">${sumMetrics}</div>`:''}${devRows?`<div class="bc-sum-dev"><div class="bc-sum-dev-lbl"><i class="ti ti-tool"></i>${t('devices_title')}</div>${devRows}</div>`:''}</div>`:'';

  var _dayKey=_dayKeyOf(b.ts);
  var _dayHeaderHtml='';
  if(_dayKey!==_lastDayKey){
    _dayHeaderHtml=`<div class="feed-day-header" style="padding:16px 4px 6px;font-family:var(--mono);font-size:11px;letter-spacing:1px;text-transform:uppercase;color:var(--txt3);font-weight:700">${_dayGroupLabel(b.ts)}</div>`;
    _lastDayKey=_dayKey;
  }
  var _cardTimeStr=(function(){var dd=new Date(b.ts);var pad=function(n){return (n<10?'0':'')+n;};return pad(dd.getHours())+':'+pad(dd.getMinutes());})();

  return _dayHeaderHtml+`<div class="swipe-outer" id="so-${bid}"><div class="swipe-delete-bg" onclick="softDeleteBrew(${bid})"><i class="ti ti-trash" aria-hidden="true"></i><span>Видалити</span></div><div class="brew-card" id="bc-${bid}" style="--rc:${ratColor};border-left:3px solid ${ratColor}">
    <div class="bc-top${cafeOn?' bc-top-cafe':''}">
      <div style="min-width:0"><div class="bc-name">${_liveBean.name||t('journal_no_name')}</div>${_liveBean.roaster?`<div class="bc-roaster">${_liveBean.roaster}</div>`:''}<div class="bc-date" style="font-size:10.5px;color:var(--txt3);margin-top:2px;font-family:var(--mono)">${_cardTimeStr}</div>${cafeMarker}</div>
      <div class="bc-right"><div class="bc-method-grp"><span class="method-pill">${displayMethod}</span>${brewDevice?`<span class="bc-device">${brewDevice}</span>`:''}</div><span class="rating-num" style="color:${ratColor}">${parseFloat(b.rating||0).toFixed(1)}</span></div>
      ${cafeOn?`<span class="bc-cafe-badge" title="Кав'ярня"><i class="ti ti-building-store" aria-hidden="true"></i></span>`:''}
    </div>
    <div class="bc-stats"${cafeOn?' style="margin-top:12px"':''}>
      <div class="bstat"><div class="bstat-l">${t('brew_dose_label')}</div><div class="bstat-v">${b.dose||'—'}г</div></div>
      <div class="bstat"><div class="bstat-l">${t('brew_ratio_label')}</div><div class="bstat-v">1:${b.ratio||'—'}</div></div>
      ${cafeOn?`<div class="bstat"><div class="bstat-l">${t('brew_vol_label')}</div><div class="bstat-v">${volMl||'—'}</div></div>`:`<div class="bstat"><div class="bstat-l">${t('brew_time_label')}</div><div class="bstat-v">${b.totalTime||'—'}</div></div>`}
    </div>
    <div class="bc-foot">
      <button class="expand-btn" id="ex-${bid}" onclick="toggleRec(${bid})"><i class="ti ti-chevron-down" aria-hidden="true"></i> Деталі</button>
      <div style="display:flex;gap:6px">
        <button class="like-btn" onclick="openEditBrew(${bid})" title="Редагувати"><i class="ti ti-pencil" aria-hidden="true"></i></button>
        <button class="like-btn" onclick="cpToggleBrew(${bid})" id="cp-btn-${bid}" title="Порівняти"><i class="ti ti-scale" aria-hidden="true"></i></button>
        <button class="like-btn" onclick="shareRecipe(${bid})" title="Поділитись"><i class="ti ti-share" aria-hidden="true"></i></button>
        <button class="like-btn ${b.liked?'liked':''}" onclick="toggleLike(${bid})"><i class="ti ti-heart" aria-hidden="true"></i> ${b.likes}</button>
      </div>
    </div>
    <div class="recipe-panel" id="rec-${bid}">
      ${summaryBlock}
      <div class="bc-tabs">
        <button class="bc-tab on" onclick="bcTab(${bid},0,this)">Лог</button>
        <button class="bc-tab" onclick="bcTab(${bid},1,this)"><span data-i18n="rate_flavor">Смак</span></button>
        <button class="bc-tab" onclick="bcTab(${bid},2,this)"><span data-i18n="rate_aroma">Аромат</span></button>
      </div>
      <div class="bc-pages">
        <div class="bc-page on" id="bcp-0-${bid}">
          ${cafeOn?'<!-- кав\'ярня: тумблер таблиця/діаграма прихований -->':`<div style="display:flex;gap:3px;padding:3px;background:#121315;border:1px solid var(--line-soft);border-radius:10px;margin-bottom:12px">
            <button id="bct-log-${bid}" onclick="bcLogToggle(${bid},'log',this)" style="flex:1;padding:7px 8px;border-radius:7px;border:none;cursor:pointer;font-family:var(--mono);font-size:10px;font-weight:600;color:var(--txt3);letter-spacing:.5px;background:none">Таблиця</button>
            <button id="bct-dia-${bid}" onclick="bcLogToggle(${bid},'dia',this)" style="flex:1;padding:7px 8px;border-radius:7px;border:none;cursor:pointer;font-family:var(--mono);font-size:10px;font-weight:600;color:var(--copper-lt);letter-spacing:.5px;background:linear-gradient(160deg,var(--card-hi),var(--card-lo));box-shadow:inset 0 1px 0 rgba(255,255,255,.05)">Діаграма</button>
          </div>`}
          <div id="bcl-log-${bid}" style="display:${cafeOn?'block':'none'}">
            ${logRows}
            ${notesBox}
          </div>
          ${cafeOn?`<!-- кав'ярня: діаграма прихована
          <div id="bcl-dia-${bid}" style="padding-top:4px">${donutSVG}${legendRows}${notesBox}</div>
          -->`:`<div id="bcl-dia-${bid}" style="padding-top:4px">
            ${isEsp?espVisual:donutSVG+legendRows}
            ${notesBox}
          </div>`}
        </div>
        <div class="bc-page" id="bcp-1-${bid}">
          <div style="font-family:var(--mono);font-size:9px;color:var(--txt3);text-transform:uppercase;letter-spacing:1px;margin-bottom:10px">Смакові дескриптори</div>
          <div class="bc-wheel-tags">${fwTags}</div>
          ${notesBox}
        </div>
        <div class="bc-page" id="bcp-2-${bid}">
          <div style="font-family:var(--mono);font-size:9px;color:var(--txt3);text-transform:uppercase;letter-spacing:1px;margin-bottom:10px">Ароматичні дескриптори</div>
          <div class="bc-wheel-tags">${awTags}</div>
          ${notesBox}
        </div>
      </div>
    </div>
  </div></div></div>`;
  }catch(e){
    console.log('[renderFeed] помилка рендеру картки, brew id:', b.id, 'method:', b.method, 'помилка:', e.message);
    return '';
  }
}).join('');
// Init swipe for new cards
setTimeout(function(){document.querySelectorAll('.swipe-outer').forEach(function(o){var c=o.querySelector('.brew-card');if(c&&!c._swipeReady)initBrewSwipe(c);});},0);
}
