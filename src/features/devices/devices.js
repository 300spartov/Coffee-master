/* ── DEVICES ── */
let activeCat='dripper';
function renderCatGrid(){
  document.getElementById('cat-grid').innerHTML=DB_CATS.map(c=>{
    const n=c.id==='filter'?S.filters.length:S.equipment.filter(e=>e.type===c.id).length;
    const dbLen=DB[c.id]?.length||0;
    return`<div class="cat-card" onclick="openCat('${c.id}')"><div class="cat-icon ${c.cls}"><i class="ti ${c.icon}" aria-hidden="true"></i></div><div><div class="cat-name">${c.name}</div><div class="cat-count">${n?n+(c.id==='filter'?' пачек':' устр.'):(dbLen?'База '+dbLen:'0 пачек')}</div></div><i class="ti ti-chevron-right cat-arr" aria-hidden="true"></i></div>`;
  }).join('');
}
function openCat(id){
  activeCat=id;const m=DB_CATS.find(c=>c.id===id);
  document.getElementById('devlist-title').textContent=m?m.name:t('devices_title');
  document.getElementById('dev-search').value='';
  renderDevList('');showScr('scr-devlist');
}
function filterDevs(){renderDevList(document.getElementById('dev-search').value.toLowerCase())}
function renderDevList(q){
  const body=document.getElementById('devlist-body');
  if(activeCat==='filter'){
    body.innerHTML=`<div class="sec-lbl">Мої пачки фільтрів</div><div id="filter-list-cont" style="padding:0 16px"></div><div style="padding:10px 16px"><button onclick="openOv('ov-filter-add')" style="width:100%;background:rgba(216,152,88,.06);border:1px dashed var(--copper-dk);border-radius:8px;padding:11px;font-size:12px;font-weight:500;color:var(--copper-lt);cursor:pointer;font-family:inherit">+ Додати пачку фільтрів</button></div>`;
    renderFilterList(document.getElementById('filter-list-cont'));
    return;
  }
  const myItems=S.equipment.filter(e=>e.type===activeCat);
  const owned=new Set(myItems.map(e=>e.name));
  const dbItems=(DB[activeCat]||[]).filter(d=>!q||d.name.toLowerCase().includes(q)||d.sub.toLowerCase().includes(q));
  const m=DB_CATS.find(c=>c.id===activeCat)||{icon:'ti-tool',cls:'ic-gray'};
  let html='';
  if(myItems.length&&!q){
    html+=`<div class="sec-lbl">Мої пристрої</div>`;
    html+=myItems.map(e=>`<div class="my-dev"><div class="my-dev-ico ${m.cls}"><i class="ti ${m.icon}" aria-hidden="true"></i></div><div style="flex:1;min-width:0"><div class="dev-item-name">${e.name}</div></div><button class="del-btn" onclick="editDev(${e.id})" style="background:rgba(184,115,51,.12);border-color:var(--copper-dk);color:var(--copper-lt)"><i class="ti ti-pencil" aria-hidden="true"></i></button><button class="del-btn" onclick="delDev(${e.id})"><i class="ti ti-trash" aria-hidden="true"></i></button></div>`).join('');
  }
  if(dbItems.length){
    html+=`<div class="sec-lbl">${q?'Результати пошуку':'База — '+dbItems.length+' пристроїв'}</div>`;
    html+=dbItems.map(d=>{const has=owned.has(d.name);return`<div class="dev-item"><div style="flex:1;min-width:0"><div class="dev-item-name">${d.name}</div><div class="dev-item-sub">${d.sub}</div></div><button class="add-btn-sm ${has?'added':''}" onclick="toggleDev('${d.name.replace(/'/g,"\\'")}','${activeCat}')">${has?'Є':'+'}</button></div>`;}).join('');
  } else if(q){
    html+=`<div style="padding:20px 16px;text-align:center">
      <div style="color:#666;font-size:13px;margin-bottom:14px">«${q}» не знайдено в базі</div>
      <div style="background:#181a1c;border:1px solid var(--line);border-radius:12px;padding:14px;text-align:left">
        <div style="font-size:12px;color:var(--txt3);margin-bottom:8px;letter-spacing:.5px;text-transform:uppercase">Додати у мій інвентар</div>
        <div style="font-size:14px;font-weight:700;color:var(--txt);margin-bottom:10px">${q}</div>
        <div style="font-size:11px;color:var(--txt3);margin-bottom:6px">Тип пристрою:</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-bottom:12px" id="quick-type-grid">
          ${DB_CATS.filter(c=>c.id!=='filter').map(c=>`<button onclick="quickAddDev('${q.replace(/'/g,"\\'")}','${c.id}',this)" style="background:${c.id===activeCat?'var(--copper)':'#222'};color:${c.id===activeCat?'#1c130a':'var(--txt2)'};border:1px solid ${c.id===activeCat?'var(--copper)':'var(--line)'};border-radius:9px;padding:7px 4px;font-size:11px;font-weight:600;cursor:pointer;font-family:inherit;display:flex;align-items:center;justify-content:center;gap:4px" data-cat="${c.id}"><i class="ti ${c.icon}" aria-hidden="true"></i>${c.name}</button>`).join('')}
        </div>
        <button onclick="quickAddDev('${q.replace(/'/g,"\\'")}','${activeCat}',null)" style="width:100%;background:linear-gradient(160deg,var(--copper-lt),var(--copper));color:#1c130a;border:none;border-radius:11px;padding:10px;font-size:13px;font-weight:700;cursor:pointer;font-family:inherit;display:flex;align-items:center;justify-content:center;gap:6px" id="quick-add-confirm"><i class="ti ti-plus" aria-hidden="true"></i> Додати в інвентар</button>
      </div>
    </div>`;
  } else if(!myItems.length){
    html+=`<div style="padding:24px;text-align:center;color:#555;font-size:13px">Немає пристроїв</div>`;
  }
  html+=`<div style="padding:10px 16px"><button onclick="openAddDev()" style="width:100%;background:rgba(216,152,88,.06);border:1px dashed var(--copper-dk);border-radius:8px;padding:11px;font-size:12px;font-weight:500;color:var(--copper-lt);cursor:pointer;font-family:inherit">+ Додати свій девайс</button></div>`;
  body.innerHTML=html;
}
function toggleDev(name,type){
  const idx=S.equipment.findIndex(e=>e.name===name&&e.type===type);
  if(idx>=0)S.equipment.splice(idx,1);else S.equipment.push({id:++S.id,name,type,_upd:Date.now()});
  save();renderDevList(document.getElementById('dev-search').value.toLowerCase());renderCatGrid();
  toast(idx>=0?'Видалено':'Додано');
}
function delDev(id){S.equipment=S.equipment.filter(e=>e.id!==id);save();renderDevList('');renderCatGrid();toast('Видалено')}
let _editDevId=null;
function openAddDev(){
  _editDevId=null;
  const st=document.getElementById('cd-sheet-title');if(st)st.textContent='Свій девайс';
  const sb=document.getElementById('cd-save-btn');if(sb)sb.textContent='Додати';
  document.getElementById('cd-name').value='';
  openOv('ov-custom-dev');
}
function editDev(id){
  const e=S.equipment.find(x=>x.id===id);if(!e)return;
  _editDevId=id;
  document.getElementById('cd-name').value=e.name;
  document.getElementById('cd-type').value=e.type;
  const st=document.getElementById('cd-sheet-title');if(st)st.textContent='Редагувати девайс';
  const sb=document.getElementById('cd-save-btn');if(sb)sb.textContent='Зберегти';
  openOv('ov-custom-dev');
}
function addCustomDev(){
  const name=document.getElementById('cd-name').value.trim();if(!name)return;
  const type=document.getElementById('cd-type').value;
  if(_editDevId){
    const e=S.equipment.find(x=>x.id===_editDevId);
    if(e){e.name=name;e.type=type;e._upd=Date.now();}
    _editDevId=null;
    save();closeOv('ov-custom-dev');document.getElementById('cd-name').value='';
    renderDevList('');renderCatGrid();toast('Оновлено');
    return;
  }
  S.equipment.push({id:++S.id,name,type,_upd:Date.now()});
  save();closeOv('ov-custom-dev');document.getElementById('cd-name').value='';
  renderDevList('');renderCatGrid();toast('Додано');
}
function quickAddDev(name,type,btn){
  /* If a type button was clicked — highlight it and update activeCat for confirm */
  if(btn){
    document.querySelectorAll('#quick-type-grid button').forEach(b=>{
      const isThis=b===btn;
      b.style.background=isThis?'var(--copper)':'#222';
      b.style.color=isThis?'#1c130a':'var(--txt2)';
      b.style.borderColor=isThis?'var(--copper)':'var(--line)';
    });
    /* Update confirm button to use selected type */
    const confirmBtn=document.getElementById('quick-add-confirm');
    if(confirmBtn) confirmBtn.setAttribute('onclick',`quickAddDev('${name.replace(/'/g,"\\'")}','${type}',null)`);
    return;
  }
  /* Confirm — actually add */
  if(S.equipment.some(e=>e.name===name&&e.type===type)){toast('Вже є в інвентарі');return;}
  S.equipment.push({id:++S.id,name,type,_upd:Date.now()});
  save();
  document.getElementById('dev-search').value='';
  renderDevList('');renderCatGrid();
  toast('«'+name+'» додано до інвентарю ✓');
}
