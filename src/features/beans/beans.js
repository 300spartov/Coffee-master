/* ── BEANS ── */
function renderBeans(){
  const el=document.getElementById('bean-list');
  const addTile=`<button class="bean-add" onclick="openAddBean()"><i class="ti ti-plus" aria-hidden="true"></i> Додати пачку</button>`;
  if(!S.beans.length){el.innerHTML=`<div class="empty" style="padding:34px 0 18px"><i class="ti ti-package" aria-hidden="true"></i><div class="empty-t">Немає зерна</div><div class="empty-s">Додай першу пачку</div></div>${addTile}`;return}
  el.innerHTML=S.beans.map(b=>{const pct=Math.round(b.current/b.total*100);return`<div class="bean-card">
    <div class="bean-icon"><i class="ti ti-coffee" aria-hidden="true"></i></div>
    <div style="flex:1;min-width:0"><div style="font-size:14px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${b.name}</div><div style="font-size:12px;color:#888;margin-top:2px">${b.roaster||'—'} · ${b.current}г / ${b.total}г</div><div style="height:2px;background:#222;border-radius:1px;margin-top:7px;overflow:hidden"><div style="height:100%;background:#4CAF50;border-radius:1px;width:${pct}%"></div></div></div>
    <button class="del-btn" onclick="editBean(${b.id})" aria-label="Редагувати" style="background:rgba(184,115,51,.12);border-color:var(--copper-dk);color:var(--copper-lt)"><i class="ti ti-pencil" aria-hidden="true"></i></button>
    <button class="del-btn" onclick="delBean(${b.id})" aria-label="Удалить"><i class="ti ti-trash" aria-hidden="true"></i></button>
  </div>`;}).join('')+addTile;
}
let _editBeanId=null;
function openAddBean(){
  _editBeanId=null;
  const st=document.getElementById('bean-sheet-title');if(st)st.textContent='Додати пачку';
  const sb=document.getElementById('bean-save-btn');if(sb)sb.textContent='Додати';
  ['bn-name','bn-roast','bn-country','bn-farm','bn-score','bn-desc'].forEach(id=>{const el=document.getElementById(id);if(el)el.value='';});
  document.getElementById('bn-process').value='';
  document.getElementById('bn-roastprofile').value='';
  document.getElementById('bn-weight').value='250';
  openOv('ov-bean');
}
function editBean(id){
  const b=S.beans.find(x=>x.id===id);if(!b)return;
  _editBeanId=id;
  document.getElementById('bn-name').value=b.name||'';
  document.getElementById('bn-roast').value=b.roaster||'';
  document.getElementById('bn-country').value=b.country||'';
  document.getElementById('bn-process').value=b.process||'';
  document.getElementById('bn-farm').value=b.farm||'';
  document.getElementById('bn-score').value=b.score||'';
  document.getElementById('bn-desc').value=b.descriptors||'';
  document.getElementById('bn-roastprofile').value=b.roastType||'';
  document.getElementById('bn-weight').value=b.total||250;
  const st=document.getElementById('bean-sheet-title');if(st)st.textContent='Редагувати пачку';
  const sb=document.getElementById('bean-save-btn');if(sb)sb.textContent='Зберегти';
  openOv('ov-bean');
}
function addBean(){
  const name=document.getElementById('bn-name').value.trim();if(!name)return;
  const w=parseInt(document.getElementById('bn-weight').value)||250;
  const roaster=document.getElementById('bn-roast').value.trim();
  const roastType=document.getElementById('bn-roastprofile').value;
  if(_editBeanId){
    const b=S.beans.find(x=>x.id===_editBeanId);
    if(b){
      const diff=w-b.total;
      b.name=name;b.roaster=roaster;b.total=w;b.current=Math.max(0,b.current+diff);
      b.country=document.getElementById('bn-country').value.trim();
      b.process=document.getElementById('bn-process').value;
      b.farm=document.getElementById('bn-farm').value.trim();
      b.score=parseFloat(document.getElementById('bn-score').value)||null;
      b.descriptors=document.getElementById('bn-desc').value.trim();
      b.roastType=roastType;
      b._upd=Date.now();
    }
    _editBeanId=null;
    save();closeOv('ov-bean');acCloseAll();
    renderBeans();toast('Пачку оновлено');
    return;
  }
  const bean={
    id:++S.id,name,roaster,total:w,current:w,
    country:document.getElementById('bn-country').value.trim(),
    process:document.getElementById('bn-process').value,
    farm:document.getElementById('bn-farm').value.trim(),
    score:parseFloat(document.getElementById('bn-score').value)||null,
    descriptors:document.getElementById('bn-desc').value.trim(),
    roastType:roastType,
    _upd:Date.now()
  };
  S.beans.unshift(bean);
  if(roaster&&!S.roasters.includes(roaster))S.roasters.push(roaster);
  if(name&&!S.beanNames.includes(name))S.beanNames.push(name);
  save();closeOv('ov-bean');acCloseAll();
  ['bn-name','bn-roast','bn-country','bn-farm','bn-score','bn-desc'].forEach(id=>{const el=document.getElementById(id);if(el)el.value='';});
  document.getElementById('bn-process').value='';
  document.getElementById('bn-roastprofile').value='';
  renderBeans();toast('Пачку додано');
}
function delBean(id){S.beans=S.beans.filter(b=>b.id!==id);save();renderBeans();toast('Видалено')}
