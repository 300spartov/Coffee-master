function logToday(){let mx=0;S.log.forEach(e=>{if(e.ts>mx)mx=e.ts});const d=mx?new Date(mx):new Date();d.setHours(12,0,0,0);return d;}
function dayKey(d){return d.getFullYear()+'-'+d.getMonth()+'-'+d.getDate();}
function logDaySet(){return new Set(S.log.map(e=>dayKey(new Date(e.ts))));}
function calcStreak(){
  const set=logDaySet();
  if(!set.size) return 0;
  // Grace period: start from today; if no entry today — try yesterday
  const today=new Date(); today.setHours(12,0,0,0);
  const yesterday=new Date(today); yesterday.setDate(today.getDate()-1);
  let c;
  if(set.has(dayKey(today))) c=new Date(today);
  else if(set.has(dayKey(yesterday))) c=new Date(yesterday);
  else return 0;
  // Walk back counting consecutive days
  let n=0;
  for(;;){if(set.has(dayKey(c))){n++;c.setDate(c.getDate()-1);}else break;}
  return n;
}
function logByDay(year,month){const map={};S.log.forEach(e=>{const d=new Date(e.ts);if(d.getFullYear()===year&&d.getMonth()===month){const k=d.getDate();(map[k]=map[k]||{vol:0,items:[]});map[k].vol+=e.vol;map[k].items.push(e);}});Object.values(map).forEach(o=>o.items.sort((a,b)=>a.ts-b.ts));return map;}

let statsPage=0,_statsInit=false;
function statsGo(i){statsPage=Math.max(0,Math.min(1,i));const tr=document.getElementById('stats-track');if(tr){tr.style.transition='';tr.style.transform='translateX(-'+(statsPage*100)+'%)';}document.getElementById('pd0').classList.toggle('on',statsPage===0);document.getElementById('pd1').classList.toggle('on',statsPage===1);}
function initStats(){
  if(_statsInit)return;const pager=document.querySelector('.stats-pager');const tr=document.getElementById('stats-track');if(!pager||!tr)return;_statsInit=true;
  let sx=0,sy=0,dx=0,drag=false,w=0,lock=null;
  pager.addEventListener('pointerdown',e=>{drag=true;sx=e.clientX;sy=e.clientY;dx=0;lock=null;w=pager.clientWidth;tr.style.transition='none';});
  window.addEventListener('pointermove',e=>{if(!drag)return;dx=e.clientX-sx;const dy=e.clientY-sy;
    if(lock===null&&(Math.abs(dx)>6||Math.abs(dy)>6))lock=Math.abs(dx)>Math.abs(dy)?'x':'y';
    if(lock==='x'){e.preventDefault();const base=-statsPage*w;let t=Math.max(-w,Math.min(0,base+dx));tr.style.transform='translateX('+t+'px)';}
  },{passive:false});
  window.addEventListener('pointerup',()=>{if(!drag)return;drag=false;tr.style.transition='';if(lock==='x'&&Math.abs(dx)>w*0.18)statsGo(statsPage+(dx<0?1:-1));else statsGo(statsPage);lock=null;});
  pager.addEventListener('dragstart',e=>e.preventDefault());
}
function toggleStreak(){const p=document.getElementById('streak-panel');const open=p.classList.toggle('open');document.getElementById('hdr-streak').classList.toggle('lit',open);if(open){renderStreak();renderCalendar();}}
function renderStreak(){
  const streak=calcStreak();const rec=Math.max(S.record||0,streak);
  const hn=document.getElementById('hdr-streak-num');if(hn)hn.textContent=streak;
  const td=logToday();const MON=['янв','фев','мар','апр','трав.','июн','июл','авг','сен','окт','ноя','дек'];
  const pn=document.getElementById('pdate-num');if(pn)pn.textContent=td.getDate();
  const pm=document.getElementById('pdate-mon');if(pm)pm.textContent=MON[td.getMonth()];
  const sn=document.getElementById('se-num');if(sn)sn.textContent=streak;
  const sr=document.getElementById('se-rec');if(sr)sr.textContent=rec;
  const C=2*Math.PI*54,frac=Math.min(streak/Math.max(rec,1),1);
  const arc=document.getElementById('se-arc');
  if(arc){arc.setAttribute('stroke-dasharray',C.toFixed(1));arc.setAttribute('stroke-dashoffset',C.toFixed(1));requestAnimationFrame(()=>requestAnimationFrame(()=>arc.setAttribute('stroke-dashoffset',(C*(1-frac)).toFixed(1))));}
  const t=logToday(),dow=(t.getDay()+6)%7,mon=new Date(t);mon.setDate(t.getDate()-dow);
  const set=logDaySet(),L=['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];let h='';
  for(let i=0;i<7;i++){const d=new Date(mon);d.setDate(mon.getDate()+i);const on=set.has(dayKey(d)),fut=dayKey(d)!==dayKey(t)&&d>t;h+=`<div class="se-wd"><span class="dot ${on?'on':''} ${fut?'future':''}"></span><span class="lbl">${L[i]}</span></div>`;}
  document.getElementById('se-week').innerHTML=h;
  /* Sync profile streak badge */
  const pst=document.getElementById('pr-streak-top');if(pst)pst.textContent=streak;
  const pdn=document.getElementById('pdate-num');if(pdn)pdn.textContent=streak;
}

const MONTHS=['Січень','Лютий','Березень','Квітень','Травень','Червень','Липень','Серпень','Вересень','Жовтень','Листопад','Грудень'];
let calState=null;
function calInit(){if(calState)return;const t=logToday();calState={y:t.getFullYear(),m:t.getMonth(),mode:'vol',sel:null};}
function calNav(dir){calInit();calState.sel=null;let m=calState.m+dir,y=calState.y;if(m<0){m=11;y--;}if(m>11){m=0;y++;}calState.m=m;calState.y=y;renderCalendar();}
function calMode(mode){calInit();calState.mode=mode;renderCalendar();}
function calTap(d){calInit();calState.sel=calState.sel===d?null:d;renderCalendar();}
function plural(n,a,b,c){const m10=n%10,m100=n%100;return m10===1&&m100!==11?a:(m10>=2&&m10<=4&&(m100<10||m100>=20)?b:c);}
function renderCalendar(){
  calInit();
  const map=logByDay(calState.y,calState.m);
  const lead=(new Date(calState.y,calState.m,1).getDay()+6)%7;
  const dim=new Date(calState.y,calState.m+1,0).getDate();
  const t=logToday(),isTM=t.getFullYear()===calState.y&&t.getMonth()===calState.m;
  let grid='';
  for(let i=0;i<lead;i++)grid+='<div class="cal-cell blank"></div>';
  for(let d=1;d<=dim;d++){
    const day=map[d],has=!!day,sel=calState.sel===d,today=isTM&&t.getDate()===d;
    let dots='';if(has)day.items.slice(0,3).forEach(it=>dots+=`<i class="${it.cat}"></i>`);
    grid+=`<div class="cal-cell ${calState.mode==='ind'?'ind-mode':''} ${has?'has':''} ${sel?'sel':''} ${today?'today':''}" ${has?`onclick="calTap(${d})"`:''}>
      <span class="cc-d">${d}</span>
      ${has&&calState.mode==='vol'?`<span class="cc-v">${day.vol}мл</span>`:''}
      ${has&&calState.mode==='ind'?`<span class="cc-dots">${dots}</span>`:''}
    </div>`;
  }
  let detailHTML='',detailOpen=false;
  if(calState.sel&&map[calState.sel]){
    const day=map[calState.sel],cnt=day.items.length,word=plural(cnt,'заварювання','заварювання','заварювань');
    const items=day.items.map(it=>`<div class="cd-item"><span class="cd-dot ${it.cat}"></span><span class="cd-bean">${it.bean}</span><span class="cd-method">${it.method}</span><span class="cd-vol">${it.vol}мл</span><span class="cd-rate"><i class="ti ti-star-filled" style="font-size:10px;color:var(--copper-lt)"></i>${(+it.rating).toFixed(1)}</span></div>`).join('');
    detailHTML=`<div class="cd-head"><i class="ti ti-coffee" aria-hidden="true"></i>${calState.sel} ${MONTHS[calState.m].toLowerCase()} · ${day.vol} мл · ${cnt} ${word}</div>${items}`;
    detailOpen=true;
  }
  document.querySelectorAll('.cal-card').forEach(card=>{
    const ml=card.querySelector('.cal-month-lbl');if(ml)ml.textContent=MONTHS[calState.m]+' '+calState.y;
    const g=card.querySelector('.cal-grid');if(g)g.innerHTML=grid;
    const cv=card.querySelector('.cm-vol'),ci=card.querySelector('.cm-ind');
    if(cv)cv.classList.toggle('on',calState.mode==='vol');
    if(ci)ci.classList.toggle('on',calState.mode==='ind');
    const det=card.querySelector('.cal-detail');
    if(det){if(detailOpen){det.innerHTML=detailHTML;det.classList.add('open');}else{det.classList.remove('open');det.innerHTML='';}}
  });
}
