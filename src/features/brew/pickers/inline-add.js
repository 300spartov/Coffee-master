/* ── QUICK ADD (з пікера під час заварювання) ── */
function quickAddBean(){
  const name=prompt('Назва зерна:','');if(!name||!name.trim())return;
  const roaster=prompt('Обсмажувач (необов\'язково):','')||'';
  const bean={id:++S.id,name:name.trim(),roaster:roaster.trim(),total:250,current:250};
  S.beans.unshift(bean);save();
  bSelBean(bean.id);
  openOv('ov-bbean');
  toast('Зерно додано та обрано ✓');
}
function addFilterInline(){
  const name=(document.getElementById('if-name').value||'').trim();if(!name)return;
  const cnt=parseInt(document.getElementById('if-count').value)||100;
  const filter={id:++S.id,name,total:cnt,current:cnt,ftype:document.getElementById('if-type').value};
  S.filters.unshift(filter);save();
  document.getElementById('if-name').value='';
  document.getElementById('if-count').value='100';
  document.getElementById('if-type').value='';
  toggleInlineAdd('filter');
  bSelFilter(filter.id);
  toast(name+' додано та обрано ✓');
}

/* ── INLINE ADD (пікери під час заварювання) ── */
function toggleInlineAdd(type){
  const el=document.getElementById('inline-add-'+type);
  if(!el)return;
  const open=el.style.display==='none';
  el.style.display=open?'block':'none';
  if(open&&type==='bean'){
    const inp=document.getElementById('ib-name');if(inp)setTimeout(()=>inp.focus(),80);
  }
}
function addBeanInline(){
  const name=(document.getElementById('ib-name').value||'').trim();if(!name)return;
  const roaster=(document.getElementById('ib-roast').value||'').trim();
  const bean={
    id:++S.id,name,roaster,total:parseInt(document.getElementById('ib-weight').value)||250,current:parseInt(document.getElementById('ib-weight').value)||250,
    country:(document.getElementById('ib-country').value||'').trim(),
    process:document.getElementById('ib-process').value,
    descriptors:(document.getElementById('ib-desc').value||'').trim()
  };
  S.beans.unshift(bean);
  if(roaster&&!S.roasters.includes(roaster))S.roasters.push(roaster);
  if(name&&!S.beanNames.includes(name))S.beanNames.push(name);
  save();
  ['ib-name','ib-roast','ib-country','ib-desc'].forEach(id=>{const e=document.getElementById(id);if(e)e.value='';});
  document.getElementById('ib-process').value='';
  document.getElementById('ib-weight').value='250';
  toggleInlineAdd('bean');
  bSelBean(bean.id);
  toast('Зерно додано та обрано ✓');
}
function addDeviceInline(type){
  let name='',extra={};
  if(type==='grinder'){
    name=(document.getElementById('ig-name').value||'').trim();if(!name)return;
    extra={gtype:document.getElementById('ig-type').value,burr:document.getElementById('ig-burr').value,notes:(document.getElementById('ig-notes').value||'').trim()};
    document.getElementById('ig-name').value='';document.getElementById('ig-notes').value='';
  } else if(type==='dripper'){
    name=(document.getElementById('id-name').value||'').trim();if(!name)return;
    extra={size:document.getElementById('id-size').value,material:document.getElementById('id-material').value};
    document.getElementById('id-name').value='';
  } else if(type==='espresso'){
    name=(document.getElementById('iem-name').value||'').trim();if(!name)return;
    extra={etype:document.getElementById('iem-type').value,pump:document.getElementById('iem-pump').value,notes:(document.getElementById('iem-notes').value||'').trim()};
    document.getElementById('iem-name').value='';document.getElementById('iem-notes').value='';
  } else if(type==='acc'){
    name=(document.getElementById('iac-name').value||'').trim();if(!name)return;
    document.getElementById('iac-name').value='';
  }
  const dev={id:++S.id,name,type,...extra};
  S.equipment.unshift(dev);save();
  toggleInlineAdd(type);
  if(type==='grinder')bSelGrinder(dev.id);
  if(type==='dripper')bSelDripper(dev.id);
  if(type==='espresso')bSelEspMachine(dev.id);
  if(type==='acc'){bToggleAcc(dev.id);renderBaccPick();}
  renderCatGrid();
  toast(name+' додано та обрано ✓');
}
