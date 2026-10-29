/* ── ЕСПРЕСО ТАЙМЕР ── */
let espInt=null,espSec=0,espRunning=false;
function brewStart(){
  if(brewMethod==='esp'){espStartShot();return;}
  bCalc();const total=Math.round(BS.dose*BS.ratio);
  BS.steps=[];BS.pourCnt=0;BS.phase='idle';BS.mainStart=null;BS.elapsed=0;BS.phaseMs=0;BS.pouredFixed=0;BS.firstDone=false;
  document.getElementById('b-pour-tot').textContent=BS.pours;
  document.getElementById('b-bar-tot').textContent=total+' мл';
  document.getElementById('b-main-t').textContent='0:00';
  document.getElementById('b-phase-t').textContent='—';document.getElementById('b-phase-t').style.color='#555';
  document.getElementById('b-phase-lbl').textContent='Фаза';document.getElementById('b-phase-lbl').style.color='#555';
  document.getElementById('b-pour-cnt').textContent='0';
  document.getElementById('b-pour-btn').disabled=false;document.getElementById('b-pour-btn').className='action-btn btn-pour';
  document.getElementById('b-pour-lbl').textContent=t('brew_pour');document.getElementById('b-pour-sub').textContent=t('brew_pour_sub');
  document.getElementById('b-ml-wrap').style.display='none';document.getElementById('b-ml-inp').value='';
  document.getElementById('b-pause-btn').className='action-btn btn-pause';
  document.getElementById('b-pause-lbl').textContent=t('brew_pause');document.getElementById('b-pause-sub').textContent=t('brew_pause_sub');
  document.getElementById('b-pause-icon').style.color='#4CAF50';document.getElementById('b-p-ring').style.strokeDashoffset='131.9';
  document.getElementById('b-log-box').innerHTML='';document.getElementById('b-log-wrap').style.display='none';
  document.getElementById('b-bar-markers').innerHTML='';document.getElementById('b-bar-labels').innerHTML='';
  showPauseActions(false);resetPauseActions();
  document.getElementById('brew-sub').textContent='1:'+BS.ratio+' · '+document.getElementById('b-temp-sl').value+'°C';
  /* B1: замінюємо дефолтний лейбл методу на підгрупу або пусто */
  const _bt=document.getElementById('brew-title');
  if(_bt&&(_bt.textContent==='Альтернатива'||_bt.textContent===t('method_esp'))){
    _bt.textContent=BS.altMethod||'';
  }
  bRenderDripper();bDrip(false);
  const liq0=document.getElementById('vessel-liquid');if(liq0)liq0.setAttribute('transform','translate(0,197)');
  /* Початковий рендер підказок — всі вливи одразу видно до старту */
  bRenderAllPourHints(-1);
  bUpdateBar(0,total);showBV('bv-active');
}
function bStartMain(){if(BS.mainStart!==null)return;BS.mainStart=Date.now();BS.mainInt=setInterval(()=>{BS.elapsed=Date.now()-BS.mainStart;document.getElementById('b-main-t').textContent=fmt(BS.elapsed);},100);}
function bStartPhase(lbl,color){clearInterval(BS.phaseInt);BS.phaseStart=Date.now();BS.phaseMs=0;const pl=document.getElementById('b-phase-lbl'),pt=document.getElementById('b-phase-t');pl.textContent=lbl;pl.style.color=color;pt.style.color=color;BS.phaseInt=setInterval(()=>{BS.phaseMs=Date.now()-BS.phaseStart;pt.textContent=fmt(BS.phaseMs);},100);}
function bStopPhase(){clearInterval(BS.phaseInt);BS.phaseInt=null;BS.phaseMs=BS.phaseStart?Date.now()-BS.phaseStart:0;return BS.phaseMs;}
function bUpdateBar(projected,totalOverride){
  const total=totalOverride||Math.round(BS.dose*BS.ratio);
  const pct=Math.min(projected/total*100,100);
  const liq=document.getElementById('vessel-liquid');
  if(liq)liq.setAttribute('transform','translate(0,'+(197-1.02*pct).toFixed(1)+')');
  const vc=document.getElementById('b-vessel-pct');if(vc)vc.textContent=Math.round(pct)+'%';
  document.getElementById('b-bar-fill').style.width=pct.toFixed(1)+'%';
  document.getElementById('b-bar-pct').textContent=Math.round(pct)+'%';
  document.getElementById('b-poured-lbl').innerHTML=projected.toFixed(1)+' <span class="w-unit">мл</span>';
  document.getElementById('b-remain-lbl').innerHTML=Math.max(total-projected,0).toFixed(1)+' <span class="w-unit">мл</span>';
  /* Фіча 10b: живий ratio якщо налито більше ніж заплановано */
  const liveRatioEl=document.getElementById('b-live-ratio');
  if(liveRatioEl&&BS.dose>0&&projected>0){
    const actualR=projected/BS.dose;
    if(actualR>BS.ratio+0.05){
      liveRatioEl.textContent='1:'+(actualR).toFixed(1);
      liveRatioEl.style.color='#ea9b3c';
    } else {
      liveRatioEl.textContent='';
    }
  }
  const completedPours=BS.steps.filter(s=>s.type==='pour').length;
  const remain=total-BS.pouredFixed,partsLeft=BS.pours-completedPours;
  let ml='',ll='';
  /* Маркери показуємо тільки після того як Блум повністю завершено (зробили паузу після нього) */
  const bloomDone=completedPours>=1;
  if(bloomDone&&partsLeft>0&&remain>0){
    /* Після Блуму: ділимо воду що залишилась рівномірно на залишок вливів */
    const step=remain/partsLeft;
    for(let i=1;i<partsLeft;i++){
      /* Маркер тільки між наступними вливами, не в кінці */
      const atMl=BS.pouredFixed+step*i;
      if(atMl>=total)continue;
      const p=Math.min(atMl/total*100,100);
      const done=projected>=atMl;
      ml+=`<div style="position:absolute;top:0;bottom:0;left:${p.toFixed(1)}%;width:2px;background:${done?'rgba(255,255,255,.15)':'rgba(74,158,219,.45)'}"></div>`;
      const ls=p<10?'left:2px':p>90?'right:2px':`left:${p.toFixed(1)}%;transform:translateX(-50%)`;
      ll+=`<div style="position:absolute;${ls};top:0;text-align:center"><div style="width:5px;height:5px;border-radius:50%;background:${done?'#4CAF50':'#4A9EDB'};margin:0 auto 1px"></div><div style="font-size:11px;font-weight:700;color:${done?'#555':'#4A9EDB'};white-space:nowrap">${Math.round(atMl)}</div></div>`;
    }
  }
  document.getElementById('b-bar-markers').innerHTML=ml;document.getElementById('b-bar-labels').innerHTML=ll;
  bRenderAllPourHints(completedPours);
}
/* Рендер усіх вливів у єдиному стилі: завершені=сірі, активний=об'ємний синій, майбутні=читабельні */
function bRenderAllPourHints(completedPours){
  const total=Math.round(BS.dose*BS.ratio);
  /* Блум ≈ 25% від загального об'єму (65/260 ≈ 25%), решта вливів рівно ділять залишок */
  const BLOOM_PCT=0.25;
  const bloomMl=Math.round(total*BLOOM_PCT);
  const restMl=total-bloomMl;
  const remainPours=BS.pours-1; /* вливів після блуму */
  const perPour=remainPours>0?Math.round(restMl/remainPours):restMl;
  function plannedMl(i){return i===1?bloomMl:perPour;}

  const isPreStart=completedPours<0||(!BS.firstDone&&BS.phase!=='pour');
  /* Наступний влив підсвічується і під час паузи (після завершення попереднього) */
  const nextPourNum=completedPours+1; /* 1-based, наступний що треба зробити */
  let h='<div style="display:flex;gap:6px;align-items:stretch">';
  for(let i=1;i<=BS.pours;i++){
    const lblTxt=i===1?'Блум':`Влив ${i}`;
    const isDone=!isPreStart&&i<nextPourNum&&!(BS.phase==='pour'&&i===nextPourNum);
    /* Активний: або prestart=Блум, або активне вливання, або пауза перед наступним */
    const isActive=(isPreStart&&i===1)||(BS.phase==='pour'&&i===nextPourNum)||(BS.phase!=='pour'&&!isPreStart&&i===nextPourNum&&i<=BS.pours);
    let dpour=null;
    if(isDone){dpour=BS.steps.filter(s=>s.type==='pour')[i-1];}
    const mlVal=isDone?(dpour?Math.round(dpour.ml||0):'—'):plannedMl(i);
    if(isActive){
      h+=`<div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:72px;background:linear-gradient(160deg,#3a8fcf,#1a6aad);border:1.5px solid #4A9EDB;border-radius:14px;padding:10px 8px;text-align:center;min-width:0;box-shadow:0 3px 10px rgba(74,158,219,.3),inset 0 1px 0 rgba(255,255,255,.15)">
        <div style="font-size:10px;font-weight:700;color:rgba(255,255,255,.75);letter-spacing:.6px;line-height:1">${lblTxt}</div>
        <div style="font-size:18px;font-weight:800;color:#fff;line-height:1.2;margin-top:5px">${mlVal}</div>
        <div style="font-size:9px;color:rgba(255,255,255,.55);line-height:1;margin-top:2px">мл</div>
      </div>`;
    } else if(isDone){
      h+=`<div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:72px;background:rgba(255,255,255,.025);border:1px solid rgba(255,255,255,.05);border-radius:14px;padding:10px 8px;text-align:center;min-width:0;opacity:.35">
        <div style="font-size:10px;font-weight:600;color:#555;letter-spacing:.4px;line-height:1">${lblTxt}</div>
        <div style="font-size:15px;font-weight:700;color:#555;line-height:1.2;margin-top:5px">${mlVal}</div>
        <div style="font-size:9px;color:#444;line-height:1;margin-top:2px">мл</div>
      </div>`;
    } else {
      h+=`<div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:72px;background:var(--card-lo);border:1px solid var(--line-soft);border-radius:14px;padding:10px 8px;text-align:center;min-width:0">
        <div style="font-size:10px;font-weight:600;color:var(--txt3);letter-spacing:.4px;line-height:1">${lblTxt}</div>
        <div style="font-size:15px;font-weight:700;color:var(--txt2);line-height:1.2;margin-top:5px">${mlVal}</div>
        <div style="font-size:9px;color:var(--txt3);line-height:1;margin-top:2px">мл</div>
      </div>`;
    }
  }
  h+='</div>';
  document.getElementById('b-hints').innerHTML=h;
}
function bOnMl(){const v=parseFloat(document.getElementById('b-ml-inp').value)||0;bUpdateBar(BS.pouredFixed+v);}

/* ── ДЕЙСТВИЯ В ПАУЗЕ ── */
const ACT_DURATION=15; // секунд
const ACT_CIRC=100.5;  // 2π×16
const actTimers={};    // {id: intervalId}
const actStarted={};   // {id: Date}
// Повертає кумулятивний startMs для наступного кроку (сума ph всіх поточних steps)
function bCumOffset(){let ms=0;for(let i=0;i<BS.steps.length;i++){const s=BS.steps[i];ms+=(s.ph!=null?s.ph:(s.dur||0)*1000);}return ms;}
/* Відновлення активних таймерів заварювання після відновлення чернетки —
   setInterval-ідентифікатори не виживають перезавантаження сторінки,
   тому перераховуємо абсолютні старти і запускаємо інтервали вручну
   (без виклику bStartMain/bStartPhase, бо вони мають блокувальну умову
   на BS.mainStart!==null). */
function resumeBrewTimers(){
  if(BS.mainStart!=null){
    BS.mainStart=Date.now()-(BS.elapsed||0);
    clearInterval(BS.mainInt);
    BS.mainInt=setInterval(()=>{BS.elapsed=Date.now()-BS.mainStart;const el=document.getElementById('b-main-t');if(el)el.textContent=fmt(BS.elapsed);},100);
  }
  if(BS.phaseStart!=null){
    BS.phaseStart=Date.now()-(BS.phaseMs||0);
    clearInterval(BS.phaseInt);
    const pt=document.getElementById('b-phase-t');
    BS.phaseInt=setInterval(()=>{BS.phaseMs=Date.now()-BS.phaseStart;if(pt)pt.textContent=fmt(BS.phaseMs);},100);
  }
  if(BS._pauseStart!=null){
    bStartLivePause();
  }
  rebuildBrewLogUI();
}
function rebuildBrewLogUI(){
  /* Відтворює видимий лог кроків (b-log-box) із BS.steps після відновлення
     чернетки — bAddLog лише ДОДАЄ рядки по одному при живому заварюванні
     і не годиться для масового перемалювання, тож тут малюємо напряму. */
  const box=document.getElementById('b-log-box');if(!box)return;
  box.innerHTML='';
  const fT=function(ms){const s=Math.floor(ms/1000),m=Math.floor(s/60),sc=s%60;return(m<10?'0':'')+m+':'+(sc<10?'0':'')+sc;};
  let hasAny=false;
  BS.steps.forEach(function(st,idx){
    const startMs=st.t||0;
    const phMs=(typeof st.ph==='number'&&st.ph>0)?st.ph:0;
    const endMs=startMs+phMs;
    const dur=Math.round(phMs/1000);
    const rng=fT(startMs)+'–'+fT(endMs);
    const d=document.createElement('div');d.className='step-row';d.id='lr-'+idx;
    if(st.type==='pour'){
      d.innerHTML=`<span class="sb sb-p">${t('brew_pour')}</span><span style="font-size:11px;font-weight:600;color:var(--txt);font-family:var(--mono);flex:1">${rng}</span><span style="font-size:11px;color:var(--txt3);padding:0 6px">${dur}с</span><input type="number" step="0.1" inputmode="decimal" class="edit-ml" id="em-${idx}" value="${st.ml!=null?st.ml.toFixed(1):''}" readonly onclick="openNumPad('em-${idx}','pour-ml')"><button class="edit-apply" onclick="bEditMl(${idx})"><i class="ti ti-check" aria-hidden="true"></i></button>`;
    } else if(st.type==='action'){
      const col=st.color||'#6C6C72';
      d.innerHTML=`<span class="sb" style="background:${col}18;color:${col};border:1px solid ${col}40"><i class="ti ti-bolt" style="font-size:9px"></i></span><span style="font-size:11px;font-weight:600;color:${col};padding:0 6px;flex:1">${st.label||t('brew_action_lbl')}</span><span style="font-size:11px;color:var(--txt3);font-family:var(--mono)">${rng}</span><span style="font-size:11px;color:var(--txt3);padding-left:5px">${dur}с</span>`;
    } else {
      d.innerHTML=`<span class="sb sb-pa">${t('brew_pause')}</span><span style="font-size:11px;font-weight:600;color:var(--txt);font-family:var(--mono);flex:1">${rng}</span><span style="font-size:11px;color:var(--txt3);padding:0 6px">${dur}с</span><span style="font-size:11px;color:var(--txt3)">—</span>`;
    }
    box.appendChild(d);
    hasAny=true;
  });
  const wrap=document.getElementById('b-log-wrap');if(wrap)wrap.style.display=hasAny?'block':'none';
  /* Прогрес-бар і підказки наступного вливу теж мають синхронізуватись */
  if(typeof bUpdateBar==='function') bUpdateBar(BS.pouredFixed||0);
}
function bStartLivePause(){
  clearInterval(BS._pauseLiveInt);BS._pauseLiveInt=null;
  const _pauseRowId='lr-live-pause';
  // Завжди створюємо новий placeholder (видаляємо старий якщо є)
  const _old=document.getElementById(_pauseRowId);if(_old)_old.remove();
  const _placeDiv=document.createElement('div');_placeDiv.className='step-row';_placeDiv.id=_pauseRowId;
  document.getElementById('b-log-box').appendChild(_placeDiv);
  document.getElementById('b-log-wrap').style.display='block';
  const _fTP=function(ms){const s=Math.floor(ms/1000),m=Math.floor(s/60),sc=s%60;return(m<10?'0':'')+m+':'+(sc<10?'0':'')+sc;};
  const _startMs=bCumOffset();
  BS._pauseLiveInt=setInterval(function(){
    if(!BS._pauseStart){clearInterval(BS._pauseLiveInt);return;}
    const pMs=Date.now()-BS._pauseStart;
    const pSec=Math.round(pMs/1000);
    _placeDiv.innerHTML=`<span class="sb sb-pa">Пауза</span><span style="font-size:11px;font-weight:600;color:var(--txt);font-family:var(--mono);flex:1">${_fTP(_startMs)}–${_fTP(_startMs+pMs)}</span><span style="font-size:11px;color:var(--txt3);padding:0 6px">${pSec}с</span><span style="font-size:11px;color:var(--txt3)">—</span>`;
  },500);
}

function showPauseActions(show){
  const w=document.getElementById('pause-actions-wrap');
  if(w)w.style.display=show?'block':'none';
  /* B4: показуємо aero кнопки тільки для Aeropress */
  const aw=document.getElementById('aero-actions-wrap');
  if(aw) aw.style.display=(show && BS.altMethod==='Aeropress')?'block':'none';
}

var _aeroStirStart=null, _aeroStirInt=null; // збережено для сумісності

/* B4: Aeropress — Чавимо (старт → Стоп → завершення) */
var _aeroPressStart=null, _aeroPressInt=null;
function aeroDoPress(){
  if(BS.phase!=='pause') return;
  const btn=document.getElementById('b-aero-press');
  const timerEl=document.getElementById('aero-press-timer');
  if(_aeroPressInt){
    /* Зупиняємо — завершуємо заварювання */
    clearInterval(_aeroPressInt); _aeroPressInt=null;
    const durationMs=_aeroPressStart?Date.now()-_aeroPressStart:0;
    const durSec=Math.round(durationMs/1000);
    _aeroPressStart=null;
    BS.steps.push({type:'action',label:'Чавимо',t:bCumOffset(),ph:durationMs,dur:durSec,ml:null,color:'#7c5cbf'});
    if(timerEl) timerEl.textContent=durSec+'с';
    BS.phase='pressing'; // не 'pause' — bFinalize не запише зайву паузу
    BS._pauseStart=null;
    clearInterval(BS._pauseLiveInt);BS._pauseLiveInt=null;
    /* Завершуємо заварювання як brewStop */
    setTimeout(function(){ brewStop(); }, 300);
    return;
  }
  clearInterval(BS._pauseLiveInt);BS._pauseLiveInt=null;
  const _livePR=document.getElementById('lr-live-pause');if(_livePR)_livePR.remove();
  if(BS._pauseStart){const _pMs=Date.now()-BS._pauseStart;if(_pMs>300){BS.steps.push({type:'pause',t:bCumOffset(),ph:_pMs,dur:Math.round(_pMs/1000),ml:null});bAddLog('pause',BS.steps.length-1,_pMs,null,null);}BS._pauseStart=null;}
  if(btn){ btn.style.background='rgba(124,92,191,.3)'; const lbl=document.getElementById('b-aero-press-label'); if(lbl) lbl.textContent='Стоп ■'; }
  /* Запускаємо чавлення — оновлюємо верхній таймер і зупиняємо pauseInt */
  clearInterval(BS.pauseInt);BS.pauseInt=null;
  clearInterval(BS.phaseInt);BS.phaseInt=null;
  bStartPhase(t('brew_press'),'#7c5cbf');
  document.getElementById('b-pause-btn').className='action-btn btn-pause';
  document.getElementById('b-pause-lbl').textContent='Чавимо';
  document.getElementById('b-pause-sub').textContent='тисни коли готово';
  document.getElementById('b-pause-icon').style.color='#7c5cbf';
  _aeroPressStart=Date.now();
  const _apTimerEl=document.getElementById('aero-press-timer');
  _aeroPressInt=setInterval(function(){
    const s=Math.round((Date.now()-_aeroPressStart)/1000);
    if(_apTimerEl) _apTimerEl.textContent=s+'с';
  },200);
}
function resetPauseActions(){
  ['stir','swirl','shake'].forEach(id=>{
    clearInterval(actTimers[id]);delete actTimers[id];delete actStarted[id];
    const btn=document.getElementById('act-'+id);
    if(btn)btn.classList.remove('done','pulsing','active-now');
    const ring=document.getElementById('ring-'+id);
    if(ring)ring.style.strokeDashoffset=ACT_CIRC;
    const timer=document.getElementById('timer-'+id);
    if(timer)timer.textContent='';
  });
  /* B4: скидаємо aero стан */
  if(_aeroStirInt){ clearInterval(_aeroStirInt); _aeroStirInt=null; } _aeroStirStart=null;
  if(_aeroPressInt){ clearInterval(_aeroPressInt); _aeroPressInt=null; } _aeroPressStart=null;
  const st=document.getElementById('aero-stir-timer'); if(st) st.textContent='';
  const pt=document.getElementById('aero-press-timer'); if(pt) pt.textContent='';
  const pb=document.getElementById('b-aero-press');
  if(pb){ pb.style.background='rgba(124,92,191,.12)'; const lbl=document.getElementById('b-aero-press-label'); if(lbl) lbl.textContent='Чавимо'; }}
function brewDoAction(id,btn){
  if(BS.phase!=='pause')return;
  const isDone=btn.classList.contains('done');
  const isActive=btn.classList.contains('active-now');

  if(isActive){
    // Зупиняємо секундомер — зберігаємо як виконане
    clearInterval(actTimers[id]);delete actTimers[id];
    const elapsed=actStarted[id]?Math.round((Date.now()-actStarted[id])/1000):1;
    delete actStarted[id];
    btn.classList.remove('active-now');btn.classList.add('done','pulsing');
    setTimeout(()=>btn.classList.remove('pulsing'),800);
    const ring=document.getElementById('ring-'+id);
    if(ring)ring.style.strokeDashoffset='0';
    const timer=document.getElementById('timer-'+id);
    if(timer)timer.textContent=elapsed+'с';
    const labels={stir:'Перемішування',swirl:'Свьорл',shake:'Взбалтування'};
    const lbl=labels[id];
    const actionMs=elapsed*1000;
    const _actionEndTs=Date.now();
    const _actionStartTs=_actionEndTs-actionMs;
    // Записуємо паузу що була до дії (від старту паузи до моменту натискання кнопки дії)
    clearInterval(BS._pauseLiveInt);BS._pauseLiveInt=null;
    const _livePauseRow=document.getElementById('lr-live-pause');if(_livePauseRow)_livePauseRow.remove();
    if(BS._pauseStart){
      const pMs=_actionStartTs-BS._pauseStart;
      if(pMs>300){BS.steps.push({type:'pause',t:bCumOffset(),ph:pMs,dur:Math.round(pMs/1000),ml:null});bAddLog('pause',BS.steps.length-1,pMs,null,null);}
      BS._pauseStart=null;
    }
    // Записуємо дію — ph=actionMs (мілісекунди), t=lbl (назва для відображення)
    BS.steps.push({type:'action',t:bCumOffset(),label:lbl,dur:elapsed,ph:actionMs,ml:null,color:id==='stir'?'#5fbf83':id==='swirl'?'#38C4B8':'#B8A0E8'});
    bAddLog('action',BS.steps.length-1,lbl,actionMs,id);
    // Стартуємо нову паузу після дії
    BS._pauseStart=Date.now();
    bStartLivePause();
    return;
  }
  if(isDone){
    // Дія вже зафіксована — просто скидаємо візуальний стан і запускаємо нову дію
    btn.classList.remove('done');
    const ring=document.getElementById('ring-'+id);if(ring)ring.style.strokeDashoffset=ACT_CIRC;
    const timer=document.getElementById('timer-'+id);if(timer)timer.textContent='';
    delete actStarted[id];
    // Не видаляємо запис зі steps — попередня дія вже збережена
    // Продовжуємо вниз до блоку "Запускаємо секундомер"
  }
  // Запускаємо секундомер
  btn.classList.add('active-now');
  actStarted[id]=Date.now();
  const ring=document.getElementById('ring-'+id);
  const timerEl=document.getElementById('timer-'+id);
  actTimers[id]=setInterval(()=>{
    const sec=Math.min(Math.round((Date.now()-actStarted[id])/1000),ACT_DURATION);
    const pct=sec/ACT_DURATION;
    if(ring)ring.style.strokeDashoffset=(ACT_CIRC*(1-pct)).toFixed(2);
    if(timerEl)timerEl.textContent=sec+'с';
    if(sec>=ACT_DURATION){
      // Автозавершення — викликаємо як ручна зупинка
      btn.click();
    }
  },100);
}

function bHandlePour(){
  if(BS.phase==='pour')return;
  if(BS.phase==='pause'){
    clearInterval(BS._pauseLiveInt);BS._pauseLiveInt=null;
    const _livePR2=document.getElementById('lr-live-pause');if(_livePR2)_livePR2.remove();
    const dur=BS._pauseStart?(Date.now()-BS._pauseStart):bStopPhase();
    clearInterval(BS.pauseInt);BS.pauseInt=null;BS._pauseStart=null;
    if(dur>300){BS.steps.push({type:'pause',t:bCumOffset(),ph:dur,dur:Math.round(dur/1000),ml:null});bAddLog('pause',BS.steps.length-1,dur,null,null);}
    document.getElementById('b-p-ring').style.strokeDashoffset='131.9';
    document.getElementById('b-pause-btn').className='action-btn btn-pause';
    document.getElementById('b-pause-lbl').textContent=t('brew_pause');
    document.getElementById('b-pause-sub').textContent=t('brew_pause_sub');
    document.getElementById('b-pause-icon').style.color='#4CAF50';
    showPauseActions(false);resetPauseActions();
  }
  bStartMain();
  if(BS.pourCnt<BS.pours)BS.pourCnt++;
  BS.phase='pour';
  document.getElementById('b-pour-cnt').textContent=BS.pourCnt;
  document.getElementById('b-pour-btn').className='action-btn btn-pour act';
  document.getElementById('b-pour-btn').disabled=false;
  document.getElementById('b-pour-lbl').textContent=t('brew_pouring');
  document.getElementById('b-pour-sub').textContent=t('brew_pour_release');
  document.getElementById('b-ml-wrap').style.display='block';
  document.getElementById('b-ml-inp').value='';
  document.getElementById('b-ml-inp').focus();
  bStartPhase(t('brew_pour')+' '+BS.pourCnt,'#4A9EDB');bDrip(true);
}

function bHandlePause(){
  if(BS.phase==='pause')return;if(BS.phase!=='pour')return;
  const v=parseFloat(document.getElementById('b-ml-inp').value)||0;
  const dur=bStopPhase();BS.pouredFixed+=v;
  const idx=BS.steps.length;
  BS.steps.push({type:'pour',t:bCumOffset(),ph:dur,ml:v});
  bAddLog('pour',idx,BS.elapsed,dur,v);
  if(!BS.firstDone)BS.firstDone=true;
  bUpdateBar(BS.pouredFixed);
  document.getElementById('b-pour-btn').className='action-btn btn-pour';
  document.getElementById('b-pour-btn').disabled=false;
  document.getElementById('b-pour-lbl').textContent=t('brew_pour');
  document.getElementById('b-ml-wrap').style.display='none';
  document.getElementById('b-ml-inp').value='';
  const remaining=Math.round(BS.dose*BS.ratio)-BS.pouredFixed;
  document.getElementById('b-pour-sub').textContent=remaining>1?'ещё ~'+Math.round(remaining)+' мл':'дожать →';
  BS.phase='pause';BS._pauseStart=Date.now();bDrip(false);
  bStartLivePause();
  showPauseActions(true);
  document.getElementById('b-pause-btn').className='action-btn btn-pause act';
  document.getElementById('b-pause-lbl').textContent=t('act_pouring');
  document.getElementById('b-pause-icon').style.color='#fff';
  bStartPhase(t('brew_pause'),'#4CAF50');
  const dname=(BS.dripper?BS.dripper.name:'').toLowerCase();
  const isQuick=dname.includes('v60')||dname.includes('chemex')||dname.includes('aeropress')||dname.includes('aero');
  const pauseMax=isQuick?60000:30000;
  const ring=document.getElementById('b-p-ring'),c=131.9,t0=Date.now();
  clearInterval(BS.pauseInt);
  BS.pauseInt=setInterval(()=>{
    const el=Date.now()-t0,p=Math.min(el/pauseMax,1);
    ring.style.strokeDashoffset=(c-c*p).toFixed(2);
    document.getElementById('b-pause-sub').textContent=Math.round(el/1000)+' с';
    if(p>=1){clearInterval(BS.pauseInt);BS.pauseInt=null;}
  },100);
}
function bAddLog(type,idx,tArg,ph,ml){
  // tArg = для pour/pause: BS.elapsed; для action: назва (рядок)
  // ph = для pour/pause: тривалість в мс; для action: тривалість в мс
  // ml = для pour: мілілітри; для action: id ('stir'/'swirl'/'shake')
  document.getElementById('b-log-wrap').style.display='block';
  const d=document.createElement('div');d.className='step-row';d.id='lr-'+idx;
  // Рахуємо startMs як суму ph всіх попередніх кроків у BS.steps
  const startMs=BS.steps[idx]?BS.steps[idx].t:0;
  const phMs=(typeof ph==='number'&&ph>0)?ph:0;
  const endMs=startMs+phMs;
  const fT=function(ms){const s=Math.floor(ms/1000),m=Math.floor(s/60),sc=s%60;return(m<10?'0':'')+m+':'+(sc<10?'0':'')+sc;};
  const dur=Math.round(phMs/1000);
  const rng=fT(startMs)+'–'+fT(endMs);
  if(type==='pour'){
    d.innerHTML=`<span class="sb sb-p">${t('brew_pour')}</span><span style="font-size:11px;font-weight:600;color:var(--txt);font-family:var(--mono);flex:1">${rng}</span><span style="font-size:11px;color:var(--txt3);padding:0 6px">${dur}с</span><input type="number" step="0.1" inputmode="decimal" class="edit-ml" id="em-${idx}" value="${ml!=null?ml.toFixed(1):''}" readonly onclick="openNumPad('em-${idx}','pour-ml')"><button class="edit-apply" onclick="bEditMl(${idx})"><i class="ti ti-check" aria-hidden="true"></i></button>`;
  } else if(type==='action'){
    const icons={stir:'ti-rotate-clockwise',swirl:'ti-refresh',shake:'ti-activity'};
    const colors={stir:'#5fbf83',swirl:'#38C4B8',shake:'#B8A0E8'};
    const aid=ml||'stir';
    const col=colors[aid]||'#5fbf83';
    const lbl=aid==='stir'?t('act_stir'):aid==='swirl'?t('act_swirl'):t('act_shake');
    d.innerHTML=`<span class="sb" style="background:${col}18;color:${col};border:1px solid ${col}40"><i class="ti ${icons[aid]||'ti-bolt'}" style="font-size:9px"></i></span><span style="font-size:11px;font-weight:600;color:${col};padding:0 6px;flex:1">${lbl}</span><span style="font-size:11px;color:var(--txt3);font-family:var(--mono)">${rng}</span><span style="font-size:11px;color:var(--txt3);padding-left:5px">${dur}с</span>`;
  } else {
    d.innerHTML=`<span class="sb sb-pa">${t('brew_pause')}</span><span style="font-size:11px;font-weight:600;color:var(--txt);font-family:var(--mono);flex:1">${rng}</span><span style="font-size:11px;color:var(--txt3);padding:0 6px">${dur}с</span><span style="font-size:11px;color:var(--txt3)">—</span>`;
  }
  document.getElementById('b-log-box').appendChild(d);
}
function bEditMl(idx){const inp=document.getElementById('em-'+idx);if(!inp)return;const nv=parseFloat(inp.value)||0,step=BS.steps[idx];if(!step||step.type!=='pour')return;BS.pouredFixed+=nv-(step.ml||0);step.ml=nv;bUpdateBar(BS.pouredFixed);toast('Обновлено: '+nv.toFixed(1)+' мл');}
function bFinalize(){
  clearInterval(BS._pauseLiveInt);BS._pauseLiveInt=null;
  const _livePR3=document.getElementById('lr-live-pause');if(_livePR3)_livePR3.remove();
  if(BS.phase==='pour'){
    const v=parseFloat(document.getElementById('b-ml-inp').value)||0;
    const dur=bStopPhase();BS.pouredFixed+=v;
    const idx=BS.steps.length;
    BS.steps.push({type:'pour',t:bCumOffset(),ph:dur,ml:v});
    if(!BS.firstDone)BS.firstDone=true;
    bAddLog('pour',idx,BS.elapsed,dur,v);
  } else if(BS.phase==='pause'){
    const dur=BS._pauseStart?(Date.now()-BS._pauseStart):bStopPhase();
    if(dur>300){BS.steps.push({type:'pause',t:bCumOffset(),ph:dur,dur:Math.round(dur/1000),ml:null});bAddLog('pause',BS.steps.length-1,dur,null,null);}
    BS._pauseStart=null;
  }
  clearInterval(BS.mainInt);clearInterval(BS.phaseInt);clearInterval(BS.pauseInt);BS.mainInt=null;BS.phaseInt=null;BS.pauseInt=null;bDrip(false);
  resetPauseActions();
}

/* Перехід на екран оцінки */
function brewStop(){
  bFinalize();
  save();
  RS={rating:8.0,flavors:[],aroma:[],notes:'',_fwSel:{_active:null,_activeSub:null},_awSel:{_active:null,_activeSub:null}};
  document.getElementById('rate-bean-name').textContent=BS.bean?BS.bean.name:t('journal_no_name');
  document.getElementById('rate-info').textContent='1:'+BS.ratio+' · '+document.getElementById('b-temp-sl').value+'°C · '+fmt(BS.elapsed);
  document.getElementById('rate-time').textContent=fmt(BS.elapsed);
  document.getElementById('rate-ml').textContent=BS.pouredFixed.toFixed(1)+' мл';
  document.getElementById('rate-slider').value='8';
  document.getElementById('rate-num').textContent='8.0';
  applyRatingColor('rate-num','rate-slider',8);
  document.getElementById('brew-notes').value='';
  if(window.nwResetAll)window.nwResetAll();
  /* Показуємо секцію вливань якщо є pour-кроки */
  var _pourSection=document.getElementById('rate-pours-section');
  var _pourBody=document.getElementById('rate-pours-body');
  var _pourToggle=document.getElementById('rate-pours-toggle');
  if(_pourSection&&_pourBody){
    var _pours=BS.steps.filter(function(s){return s.type==='pour';});
    if(_pours.length){
      _pourSection.style.display='block';
      _pourBody.style.display='none';
      _ratePoursOpen=false;
      if(_pourToggle)_pourToggle.textContent='▼ показати';
      renderRatePours();
    } else {
      _pourSection.style.display='none';
    }
  }
  showBV('bv-rate');
}
