/* профиль: переключатель Календарь / Статистика */
let profV='cal';
function profView(v){
  profV=v;
  document.getElementById('jt-cal').classList.toggle('on',v==='cal');
  document.getElementById('jt-stat').classList.toggle('on',v==='stat');
  document.getElementById('prof-cal-view').style.display=v==='cal'?'block':'none';
  document.getElementById('prof-stat-view').style.display=v==='stat'?'block':'none';
  if(v==='cal')renderCalendar();else renderStat();
}
const STAT_CATS=[
  {id:'filter',get label(){return t('stat_cat_filter');},color:'var(--copper-lt)',raw:'#E8A860'},
  {id:'espresso',get label(){return t('stat_cat_espresso');},color:'var(--steel)',raw:'#6f93b0'},
  {id:'other',get label(){return t('stat_cat_other');},color:'var(--neutral)',raw:'#9b958c'}
];
/* профиль: сворачиваетрав. статистика */
let statOpen=false;
function toggleStat(){statOpen=!statOpen;document.getElementById('stat-toggle').classList.toggle('open',statOpen);document.getElementById('stat-collapse').classList.toggle('open',statOpen);if(statOpen)renderStat();}
function toggleProfCal(){const p=document.getElementById('prof-cal-panel');const open=p.classList.toggle('open');document.getElementById('pdate-btn').classList.toggle('lit',open);if(open)renderCalendar();}
function renderStat(){
  const box=document.getElementById('prof-stat-view');if(!box)return;
  const agg={};let total=0,cups=0;const days=new Set();
  S.log.forEach(e=>{const c=e.cat||'filter';agg[c]=agg[c]||{vol:0,n:0};agg[c].vol+=e.vol;agg[c].n++;total+=e.vol;cups++;days.add(dayKey(new Date(e.ts)));});
  if(!cups){box.innerHTML=`<div class="empty" style="padding:34px 0"><i class="ti ti-chart-bar" aria-hidden="true"></i><div class="empty-t">Пока нет данных</div><div class="empty-s">Свари кофе — здесь появится статистика</div></div>`;return;}
  const max=Math.max(...STAT_CATS.map(c=>(agg[c.id]||{vol:0}).vol),1);
  const liters=(total/1000).toFixed(1);
  const bars=STAT_CATS.map(c=>{const a=agg[c.id]||{vol:0,n:0};const pct=Math.round(a.vol/total*100)||0;const w=Math.round(a.vol/max*100);
    return`<div class="sbar">
      <div class="sbar-top"><span class="sbar-dot" style="background:${c.color}"></span><span class="sbar-name">${c.label}</span><span class="sbar-cnt">${a.n}×</span><span class="sbar-val">${a.vol} мл · ${pct}%</span></div>
      <div class="sbar-track"><div class="sbar-fill" style="width:${w}%;background:linear-gradient(90deg,${c.raw}aa,${c.raw})"></div></div>
    </div>`;}).join('');
  const avgCup=Math.round(total/cups),avgDay=Math.round(total/days.size);
  box.innerHTML=`<div class="stat-card">
    <div class="stat-tot"><span class="stat-tot-v">${liters}</span><span class="stat-tot-u">литров кофе</span></div>
    <div class="stat-tot-sub">
      <div class="stat-pill"><b>${total.toLocaleString('uk-UA')}</b><span>мл всього</span></div>
      <div class="stat-pill"><b>${cups}</b><span>чашек</span></div>
      <div class="stat-pill"><b>${days.size}</b><span>днів</span></div>
    </div>
    <div class="stat-seclbl">Сравнение по типам напитка</div>
    ${bars}
    <div class="stat-mini">
      <div class="mcell"><div class="mcell-v">${avgCup}<span style="font-size:10px"> мл</span></div><div class="mcell-l">средн. чашка</div></div>
      <div class="mcell"><div class="mcell-v">${avgDay}<span style="font-size:10px"> мл</span></div><div class="mcell-l">в день</div></div>
      <div class="mcell"><div class="mcell-v">${(cups/days.size).toFixed(1)}</div><div class="mcell-l">чашек/день</div></div>
    </div>
  </div>`;
}
