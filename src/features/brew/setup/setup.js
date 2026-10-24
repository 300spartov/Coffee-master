// esp поля подключены через oninput в HTML

function bRatioValidate(){
  var inp=document.getElementById('b-ratio');
  var v=parseFloat(inp.value);
  if(isNaN(v)||v<1)v=1;
  if(v>30)v=30;
  inp.value=Math.round(v*10)/10;
  bCalc();
}
/* Фіча 3: уніфікований блок температури — − | slider | +, значення зверху */
function renderTempBlock(sliderId, outId, min, max, step, val){
  const el=document.getElementById(sliderId);
  const out=document.getElementById(outId);
  if(el){ el.min=min; el.max=max; el.step=step; el.value=val; }
  if(out) out.textContent=val+'°C';
}
function bCalc(){
  BS.dose=parseFloat(document.getElementById('b-dose').value)||16;
  BS.ratio=parseFloat(document.getElementById('b-ratio').value)||16;
  BS.pours=parseInt(document.getElementById('b-pours').value)||3;
  const t=Math.round(BS.dose*BS.ratio);
  document.getElementById('b-total-lbl').textContent=t+' мл';
  document.getElementById('b-bloom-lbl').textContent=Math.round(BS.dose*3)+' мл';
}
function setWet(wet){
  BS.wet=wet;
  const wb=document.getElementById('wet-btn'),db=document.getElementById('dry-btn');
  if(wet){wb.style.cssText='padding:8px;border-radius:8px;font-family:inherit;font-size:12px;font-weight:700;cursor:pointer;border:2px solid #1a4a8a;background:#0d1f35;color:#4A9EDB';db.style.cssText='padding:8px;border-radius:8px;font-family:inherit;font-size:12px;font-weight:700;cursor:pointer;border:0.5px solid #333;background:#1a1a1a;color:#888';}
  else{wb.style.cssText='padding:8px;border-radius:8px;font-family:inherit;font-size:12px;font-weight:700;cursor:pointer;border:0.5px solid #333;background:#1a1a1a;color:#888';db.style.cssText='padding:8px;border-radius:8px;font-family:inherit;font-size:12px;font-weight:700;cursor:pointer;border:2px solid #2a5a1a;background:#1a2e14;color:#4CAF50';}
}
function bSelBean(id){BS.bean=S.beans.find(b=>b.id===id);if(!BS.bean)return;const pct=Math.round(BS.bean.current/BS.bean.total*100);document.getElementById('bsel-bean').textContent=BS.bean.name;document.getElementById('bsel-bean-sub').textContent=BS.bean.roaster+' · '+BS.bean.current+'г / '+BS.bean.total+'г';document.getElementById('bbean-bar').style.display='block';document.getElementById('bbean-fill').style.width=pct+'%';document.getElementById('brew-title').textContent=BS.bean.name;closeOv('ov-bbean');}
function bSelFilter(id){BS.filter=S.filters.find(f=>f.id===id);if(!BS.filter)return;const pct=Math.round(BS.filter.current/BS.filter.total*100);document.getElementById('bsel-filter').textContent=BS.filter.name;document.getElementById('bsel-filter-sub').textContent='Залишилось '+BS.filter.current+' / '+BS.filter.total+' шт';document.getElementById('bfilter-bar').style.display='block';document.getElementById('bfilter-fill').style.width=pct+'%';closeOv('ov-bfilter');}

function bSelGrinder(id){
  BS.grinder=S.equipment.find(e=>e.id===id);if(!BS.grinder)return;
  document.getElementById('bsel-grinder').textContent=BS.grinder.name;
  document.getElementById('bsel-grinder-sub').textContent=BS.grinder.sub||'кавомолку вибрано';
  closeOv('ov-bgrinder');
}

function clicksAdj(delta){
  BS.clicks=Math.max(1,Math.min(200,BS.clicks+delta));
  document.getElementById('clicks-val').textContent=BS.clicks;
}

function openGrinderPick(){
  const grinders=S.equipment.filter(e=>e.type==='grinder');
  document.getElementById('bgrinder-pick').innerHTML=grinders.length
    ?grinders.map(g=>{const sel=BS.grinder&&BS.grinder.id===g.id;return`<div class="pick-item" onclick="bSelGrinder(${g.id})">
      <div style="flex:1;min-width:0"><div class="pick-main">${g.name}</div></div>
      <i class="ti ${sel?'ti-check" style="color:var(--copper-lt)':'ti-chevron-right" style="color:var(--txt3)'};font-size:16px" aria-hidden="true"></i>
    </div>`;}).join('')
    :'<div style="padding:20px;text-align:center;color:var(--txt3);font-size:13px">'+t('devices_no_grinder')+'</div>';
}

/* ── DRIPPER VISUALS ── */
function dripperType(name){
  if(!name)return 'v60';const n=name.toLowerCase();
  if(n.includes('origami'))return 'origami';
  if(n.includes('flower'))return 'flower';
  if(n.includes('aeropress')||n.includes('aero'))return 'aeropress';
  if(n.includes('chemex'))return 'chemex';
  if(n.includes('french')||n.includes('френч'))return 'frenchpress';
  if(n.includes('cold')||n.includes('колд')||n.includes('toddy')||n.includes('mizudashi')||n.includes('filtron')||n.includes('oxo'))return 'coldbrew';
  if(n.includes('batch')||n.includes('бетч')||n.includes('бэтч')||n.includes('moccamaster')||n.includes('bonavita')||n.includes('aiden'))return 'batch';
  return 'v60';
}
const DRIPPER_LABEL={origami:'Origami',flower:'Flower',aeropress:'Aeropress',v60:'V60',chemex:'Chemex',frenchpress:'French Press',coldbrew:'Cold Brew',batch:'Batch Brewing'};
function dripperLabelKey(method){
  if(method==='Aeropress')return'devices_choose_aeropress';
  if(method==='Chemex')return'devices_choose_chemex';
  if(method==='French Press')return'devices_choose_frenchpress';
  if(method==='Batch Brewing')return'devices_choose_batch';
  if(method==='Cold Brew')return'devices_choose_coldbrew';
  return'devices_choose_dripper'; // V60 і будь-який невідомий метод — без змін
}
function bDripperArt(name){
  const t=dripperType(name);
  if(t==='origami')return `
    <path d="M26,16 L33,22 L40,16 L47,22 L54,16 L62,22 L70,16 L77,22 L84,16 L91,22 L98,16 L62,85 Z" fill="#26314d" stroke="#6377a0" stroke-width="1.2" stroke-linejoin="round"></path>
    <g stroke="#42537a" stroke-width="1" fill="none" stroke-linecap="round"><path d="M33,22 L62,85"></path><path d="M47,22 L62,85"></path><path d="M62,22 L62,85"></path><path d="M77,22 L62,85"></path><path d="M91,22 L62,85"></path></g>
    <g stroke="rgba(150,172,214,0.4)" stroke-width="0.8" fill="none"><path d="M40,16 L62,85"></path><path d="M84,16 L62,85"></path></g>
    <ellipse cx="62" cy="86" rx="9" ry="2.8" fill="none" stroke="#6377a0" stroke-width="1.2"></ellipse>`;
  if(t==='flower')return `
    <path d="M30,17 L62,80 L94,17" fill="rgba(74,164,176,0.18)" stroke="#62b9c6" stroke-width="1.3" stroke-linejoin="round"></path>
    <ellipse cx="62" cy="17" rx="32" ry="6.5" fill="rgba(74,164,176,0.12)" stroke="#62b9c6" stroke-width="1.3"></ellipse>
    <g stroke="rgba(126,214,224,0.55)" stroke-width="1.5" fill="none" stroke-linecap="round"><path d="M44,19 Q49,48 60,78"></path><path d="M54,20 Q57,48 61,78"></path><path d="M62,20 L62,78"></path><path d="M70,20 Q67,48 64,78"></path><path d="M80,19 Q75,48 64,78"></path><path d="M36,18 Q44,46 58,78"></path><path d="M88,18 Q80,46 66,78"></path></g>
    <ellipse cx="62" cy="86" rx="22" ry="4.6" fill="rgba(74,164,176,0.14)" stroke="#62b9c6" stroke-width="1.2"></ellipse>
    <path d="M52,80 L52,86 M72,80 L72,86" stroke="#62b9c6" stroke-width="1.2"></path>
    <path d="M94,23 q14,2 14,16 q0,14 -16,15" fill="none" stroke="#62b9c6" stroke-width="1.5"></path>`;
  if(t==='aeropress')return `
    <rect x="40" y="9" width="44" height="7" rx="3" fill="#3a3d42" stroke="#737880" stroke-width="1.1"></rect>
    <rect x="58" y="14" width="8" height="6" fill="#34373b"></rect>
    <path d="M43,20 L43,80 Q43,86 49,86 L75,86 Q81,86 81,80 L81,20 Z" fill="#2c2e31" stroke="#737880" stroke-width="1.3"></path>
    <g stroke="#C8854A" stroke-width="1" opacity="0.7"><path d="M45,34 H79"></path><path d="M45,48 H79"></path><path d="M45,62 H79"></path></g>
    <path d="M41,86 L83,86 L79,93 L45,93 Z" fill="#3a3d42" stroke="#737880" stroke-width="1.1" stroke-linejoin="round"></path>
    <text x="62" y="28" text-anchor="middle" font-size="6" fill="#C8854A" font-family="monospace" font-weight="700">GO</text>`;
  /* v60 generic */
  return `
    <path d="M28,17 L57,82 Q62,86 67,82 L96,17" fill="rgba(174,182,191,0.06)" stroke="#aeb6bf" stroke-width="1.4" stroke-linejoin="round" stroke-linecap="round"></path>
    <ellipse cx="62" cy="16" rx="34" ry="7" fill="rgba(174,182,191,0.05)" stroke="#aeb6bf" stroke-width="1.4"></ellipse>
    <path d="M57,82 L55,88 M67,82 L69,88" stroke="#aeb6bf" stroke-width="1.4" stroke-linecap="round"></path>
    <ellipse cx="62" cy="89" rx="12" ry="3.2" fill="none" stroke="#aeb6bf" stroke-width="1.4"></ellipse>
    <path d="M96,24 q16,4 16,18 q0,14 -16,17" fill="none" stroke="#aeb6bf" stroke-width="1.6"></path>
    <g stroke="rgba(255,255,255,0.18)" stroke-width="1" fill="none" stroke-linecap="round"><path d="M40,20 Q50,50 58,80"></path><path d="M50,21 Q57,50 61,80"></path><path d="M62,22 L62,80"></path><path d="M74,21 Q67,50 65,80"></path><path d="M84,20 Q74,50 68,80"></path><path d="M33,19 Q46,48 55,80"></path><path d="M91,19 Q78,48 71,80"></path></g>`;
}
function bMiniDripper(name){return `<svg viewBox="0 6 124 90" width="34" height="26" style="overflow:visible">${bDripperArt(name)}</svg>`;}
function bRenderDripper(){
  const name=BS.dripper?BS.dripper.name:null;
  const g=document.getElementById('brew-dripper');if(g)g.innerHTML=bDripperArt(name);
  const lbl=document.getElementById('b-dev-name');
  if(lbl)lbl.innerHTML=name?'<i class="ti ti-filter" aria-hidden="true"></i> '+name:'<i class="ti ti-filter" aria-hidden="true"></i> Воронка';
}
function bSelDripper(id){
  BS.dripper=S.equipment.find(e=>e.id===id&&e.type==='dripper');if(!BS.dripper)return;
  document.getElementById('bsel-dripper').textContent=BS.dripper.name;
  document.getElementById('bsel-dripper-sub').textContent=DRIPPER_LABEL[dripperType(BS.dripper.name)]+' · готов к проливу';
  document.getElementById('bsel-dripper-ico').innerHTML=bMiniDripper(BS.dripper.name);
  closeOv('ov-bdripper');
}
function bAddAndSelectDripper(name){
  const id=++S.id;
  S.equipment.push({id:id,name:name,type:'dripper'});
  save();
  bSelDripper(id);
}
function bAddAndSelectGrinder(name){
  const id=++S.id;
  S.equipment.push({id:id,name:name,type:'grinder'});
  save();
  bSelGrinder(id);
}
function bAddAndSelectEspMachine(name){
  const id=++S.id;
  S.equipment.push({id:id,name:name,type:'espresso'});
  save();
  bSelEspMachine(id);
}
function bSelEspMachine(id){
  BS.espMachine=S.equipment.find(e=>e.id===id&&e.type==='espresso');if(!BS.espMachine)return;
  document.getElementById('bsel-espmachine').textContent=BS.espMachine.name;
  document.getElementById('bsel-espmachine-sub').textContent='готова до роботи';
  closeOv('ov-bespmachine');
}
function bToggleAcc(id){
  if(!BS.accessories)BS.accessories=[];
  const idx=BS.accessories.indexOf(id);
  if(idx>-1)BS.accessories.splice(idx,1);else BS.accessories.push(id);
  renderBaccList();
  if(document.getElementById('ov-bacc').classList.contains('open'))renderBaccPick();
}
function renderBaccList(){
  const list=document.getElementById('bacc-list');if(!list)return;
  const items=(BS.accessories||[]).map(id=>S.equipment.find(e=>e.id===id)).filter(Boolean);
  list.innerHTML=items.length?items.map(a=>`<span style="font-size:11px;padding:4px 10px;border-radius:20px;border:0.5px solid var(--copper-dk);background:rgba(184,115,51,.12);color:var(--copper-lt);font-family:inherit;font-weight:600">${a.name}</span>`).join(''):'<div style="font-size:12px;color:var(--txt3)" data-i18n="devices_no_acc">Додай аксесуари в Девайси → Аксесуари</div>';
}
function renderBaccPick(){
  const accs=S.equipment.filter(e=>e.type==='acc');
  const el=document.getElementById('bacc-pick');if(!el)return;
  el.innerHTML=accs.length
    ?accs.map(a=>{const isSelected=BS.accessories&&BS.accessories.includes(a.id);
      return`<div class="pick-item" onclick="bToggleAcc(${a.id})">
        <div class="pick-main">${a.name}</div>
        <i class="ti ${isSelected?'ti-check" style="color:var(--copper-lt)':'ti-circle" style="color:#555'}" aria-hidden="true"></i></div>`;}).join('')
    :'<div style="padding:20px;text-align:center;color:var(--txt3);font-size:13px">'+t('devices_no_acc')+'</div>';
}
function bDrip(on){const d=document.getElementById('drip-stream');if(d)d.classList.toggle('on',!!on);}
function pickBrewMethod(m){
  if(m==='alt'){
    /* Показуємо рівень 2 — підгрупи */
    const ALT_SUBS=[
      {id:'V60',      icon:'ti-filter',   color:'#3E8FCE'},
      {id:'Aeropress',icon:'ti-cylinder', color:'#5fbf83'},
      {id:'Chemex',   icon:'ti-flask',    color:'#b9c64f'},
      {id:'French Press',icon:'ti-coffee',color:'#e2c64c'},
      {id:'Drip',     icon:'ti-droplet',  color:'#ea9b3c'},
      {id:'Cold Brew',icon:'ti-snowflake',color:'#74C0F5'},
      {id:'Batch Brewing',svg:'<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" width="9" height="6" rx="1"/><path d="M13 6h3a2 2 0 0 1 2 2v1a2 2 0 0 1-2 2h-3"/><path d="M5 9v9a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V9"/><line x1="5" y1="13" x2="15" y2="13"/></svg>',color:'#d89858'},
    ];
    document.getElementById('bv-l2-title').textContent=t('method_alt');
    document.getElementById('bv-l2-sub').textContent=t('method_alt_pick_sub');
    document.getElementById('bv-alt-subgrid').innerHTML=ALT_SUBS.map(s=>
      `<button onclick="pickAltSubmethod('${s.id}')" style="background:var(--card-lo);border:1px solid var(--line-soft);border-radius:12px;padding:14px 10px;cursor:pointer;display:flex;flex-direction:column;align-items:center;gap:8px;transition:border-color .15s" onmouseover="this.style.borderColor='${s.color}'" onmouseout="this.style.borderColor=''">
        ${s.svg?`<span style="color:${s.color};display:flex;line-height:1">${s.svg}</span>`:`<i class="ti ${s.icon}" style="font-size:22px;color:${s.color}"></i>`}
        <span style="font-size:12px;font-weight:700;color:var(--txt);font-family:inherit">${s.id}</span>
      </button>`
    ).join('');
    document.getElementById('bv-method-l1').style.display='none';
    document.getElementById('bv-method-l2').style.display='';
  } else {
    const ESP_SUBS=[
      {id:'Espresso',      icon:'ti-coffee',  color:'#C08552'},
      {id:'Cappuccino',    icon:'ti-cup',     color:'#D9A45B'},
      {id:'Flat White',    icon:'ti-milk',    color:'#E8C9A0'},
      {id:'Latte',         icon:'ti-mug',color:'#C9986B'},
      {id:'Bumble',        icon:'ti-droplet', color:'#7CC4A8'},
      {id:'Espresso Tonic',icon:'ti-glass',   color:'#74C0F5'},
    ];
    document.getElementById('bv-l2-title').textContent=t('method_esp');
    document.getElementById('bv-l2-sub').textContent='Вибери напій';
    document.getElementById('bv-alt-subgrid').innerHTML=ESP_SUBS.map(s=>
      `<button onclick="pickEspSubmethod('${s.id}')" style="background:var(--card-lo);border:1px solid var(--line-soft);border-radius:12px;padding:14px 10px;cursor:pointer;display:flex;flex-direction:column;align-items:center;gap:8px;transition:border-color .15s" onmouseover="this.style.borderColor='${s.color}'" onmouseout="this.style.borderColor=''">
        <i class="ti ${s.icon}" style="font-size:22px;color:${s.color}"></i>
        <span style="font-size:12px;font-weight:700;color:var(--txt);font-family:inherit">${s.id}</span>
      </button>`
    ).join('');
    document.getElementById('bv-method-l1').style.display='none';
    document.getElementById('bv-method-l2').style.display='';
  }
}
function pickEspSubmethod(sub){
  setBrewMethod('esp');
  BS.espMethod=(sub==='Espresso')?null:sub;
  BS.espNeedsMilk=['Cappuccino','Flat White','Latte'].includes(sub);
  BS.espNeedsIce=['Bumble','Espresso Tonic'].includes(sub);
  showBV('bv-setup');
}

function pickAltSubmethod(sub){
  BS.altMethod=sub;
  setBrewMethod('alt');
  BS.inverted=false;
  document.getElementById('brew-title').textContent=sub;
  const lbl=document.getElementById('b-setup-method-lbl');
  if(lbl) lbl.textContent=sub;
  /* Показуємо Normal/Inverted тільки для Aeropress */
  const aeroOpts=document.getElementById('b-aeropress-opts');
  if(aeroOpts) aeroOpts.style.display=(sub==='Aeropress')?'':'none';
  updateAeroFilterCountVis();
  /* Для Aeropress підпис вибору "воронки" замінюється на "Вибери Aeropress" */
  const bselDripper=document.getElementById('bsel-dripper');
  if(bselDripper) bselDripper.textContent=t(dripperLabelKey(sub));
  /* Пристрій попереднього методу несумісний з новим — скидаємо вибір повністю */
  BS.dripper=null;
  const bselDripperSub=document.getElementById('bsel-dripper-sub');
  if(bselDripperSub) bselDripperSub.textContent=t('devices_tap');
  const bselDripperIco=document.getElementById('bsel-dripper-ico');
  if(bselDripperIco) bselDripperIco.innerHTML='';
  /* Drip не потребує вибору пристрою-воронки — картку повністю ховаємо */
  const dripperCard=document.getElementById('bcard-dripper');
  if(dripperCard) dripperCard.style.display=(sub==='Drip')?'none':'';
  /* Крок 3: Cold Brew — окремий діапазон температури */
  const tsl=document.getElementById('b-temp-sl');
  const tout=document.getElementById('b-temp-out');
  if(tsl&&tout){
    if(sub==='Cold Brew'){
      tsl.min='10'; tsl.max='30'; tsl.step='1'; tsl.value='18';
      tout.textContent='18°C';
    } else {
      tsl.min='80'; tsl.max='100'; tsl.step='1'; tsl.value='93';
      tout.textContent='93°C';
    }
  }
  showBV('bv-setup');
  document.getElementById('bv-method-l1').style.display='';
  document.getElementById('bv-method-l2').style.display='none';
}

function toggleFilterDropdown(){
  const d=document.getElementById('b-filter-dropdown');
  if(d) d.style.display=d.style.display==='none'?'block':'none';
}
function setAeroFilters(n){
  BS.aeroFilters=n;
  const el=document.getElementById('b-aero-filters');
  if(el) el.textContent=n;
  const d=document.getElementById('b-filter-dropdown');
  if(d) d.style.display='none';
}
/* Показуємо кількість фільтрів тільки для Aeropress */
function updateAeroFilterCountVis(){
  const wrap=document.getElementById('b-filter-count-wrap');
  if(wrap) wrap.style.display=(BS.altMethod==='Aeropress')?'':'none';
}

function setAeroInverted(inv){
  BS.inverted=!!inv;
  const ACT='padding:10px;border-radius:10px;border:2px solid var(--copper);background:linear-gradient(160deg,#2a1e10,#1d1610);color:var(--copper-lt);font-family:inherit;font-size:13px;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:6px';
  const DEF='padding:10px;border-radius:10px;border:1px solid var(--line-soft);background:var(--card-lo);color:var(--txt3);font-family:inherit;font-size:13px;font-weight:600;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:6px';
  const norm=document.getElementById('b-aero-normal');
  const invt=document.getElementById('b-aero-inverted');
  if(norm) norm.style.cssText=inv?DEF:ACT;
  if(invt) invt.style.cssText=inv?ACT:DEF;
}

function brewGoBack(){
  if(brewMethod==='esp'){
    /* Еспресо — одразу на рівень 1 */
    showBV('bv-method-pick');
  } else {
    /* Альтернатива — повертаємо на підгрупи (рівень 2) */
    showBV('bv-method-pick');
    document.getElementById('bv-method-l1').style.display='none';
    document.getElementById('bv-method-l2').style.display='';
  }
}
