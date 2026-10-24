/* ── FILTERS ── */
function addFilter(){
  const name=document.getElementById('fl-name').value.trim();if(!name)return;
  const cnt=parseInt(document.getElementById('fl-count').value)||100;
  S.filters.unshift({id:++S.id,name,total:cnt,current:cnt});
  save();closeOv('ov-filter-add');
  document.getElementById('fl-name').value='';
  const cont=document.getElementById('filter-list-cont');if(cont)renderFilterList(cont);
  toast('Фильтры добавлены');
}
function delFilter(id){S.filters=S.filters.filter(f=>f.id!==id);save();const cont=document.getElementById('filter-list-cont');if(cont)renderFilterList(cont);toast('Видалено')}
function renderFilterList(cont){
  if(!cont)return;
  if(!S.filters.length){cont.innerHTML='<div style="padding:16px;text-align:center;color:#555;font-size:13px">Немає фільтрів</div>';return}
  cont.innerHTML=S.filters.map(f=>{const pct=Math.round(f.current/f.total*100);return`<div class="filter-card">
    <div class="filter-icon"><i class="ti ti-layers-subtract" aria-hidden="true"></i></div>
    <div style="flex:1;min-width:0"><div style="font-size:14px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${f.name}</div><div style="font-size:12px;color:#888;margin-top:2px">Залишилось ${f.current} / ${f.total} шт</div><div style="height:2px;background:#222;border-radius:1px;margin-top:7px;overflow:hidden"><div style="height:100%;background:#9B7FE8;border-radius:1px;width:${pct}%"></div></div></div>
    <button class="del-btn" onclick="delFilter(${f.id})" aria-label="Удалить"><i class="ti ti-trash" aria-hidden="true"></i></button>
  </div>`;}).join('');
}
