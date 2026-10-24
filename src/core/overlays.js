function openOv(id){
  if(id==='ov-custom-dev'){
    const sel=document.getElementById('cd-type');
    if(sel && typeof activeCat!=='undefined' && activeCat && activeCat!=='filter'){
      sel.value=activeCat;
    }
  }
  if(id==='ov-settings'){
    document.getElementById('s-name').value=S.profile.name||'';
    document.getElementById('s-loc').value=S.profile.loc||'';
    document.getElementById('s-cat').value=S.profile.cat||'Новичок';
    document.getElementById('s-stazh').value=S.profile.stazh||'';
  }
  if(id==='ov-bbean'){
    const emptyBtn=`<div style="padding:32px 16px;display:flex;flex-direction:column;align-items:center;gap:12px">
      <i class="ti ti-coffee" style="font-size:36px;color:var(--txt3)"></i>
      <div style="font-size:13px;color:var(--txt3)">Зерно ще не додано</div>
      <button onclick="closeOv('ov-bbean');openOv('ov-bean')" style="background:linear-gradient(160deg,var(--copper-lt),var(--copper));color:#1c130a;border:none;border-radius:12px;padding:10px 28px;font-size:13px;font-weight:700;cursor:pointer;font-family:inherit;display:flex;align-items:center;gap:6px"><i class="ti ti-plus"></i> Додати зерно</button>
    </div>`;
    document.getElementById('bbean-pick').innerHTML=S.beans.length
      ?S.beans.map(b=>{const pct=Math.round(b.current/b.total*100),sel=BS.bean&&BS.bean.id===b.id;
        return`<div class="pick-item" onclick="bSelBean(${b.id})">
          <div style="flex:1;min-width:0;margin-right:10px"><div class="pick-main">${b.name}</div><div class="pick-sub">${b.roaster||'—'} · ${b.current}г / ${b.total}г</div><div class="pick-bar"><div class="pick-bar-g" style="width:${pct}%"></div></div></div>
          <i class="ti ${sel?'ti-check" style="color:#4CAF50':'ti-chevron-right" style="color:#555'};font-size:16px" aria-hidden="true"></i></div>`;}).join('')+
        `<div style="padding:10px 0 4px;text-align:center"><button onclick="closeOv('ov-bbean');openOv('ov-bean')" style="background:none;border:1px solid var(--copper-dk);border-radius:10px;padding:8px 20px;font-size:12px;font-weight:600;color:var(--copper-lt);cursor:pointer;font-family:inherit;display:inline-flex;align-items:center;gap:5px"><i class="ti ti-plus"></i> Додати нове зерно</button></div>`
      :emptyBtn;
  }
  if(id==='ov-bdripper'){
    const f=document.getElementById('inline-add-dripper');if(f)f.style.display='none';
    const titleEl=document.getElementById('ov-bdripper-title');
    if(titleEl)titleEl.textContent=t(dripperLabelKey(BS.altMethod));
    const _methodToType={Aeropress:'aeropress',Chemex:'chemex','French Press':'frenchpress','Batch Brewing':'batch','Cold Brew':'coldbrew'};
    const _EXCLUSIVE_TYPES=['aeropress','chemex','frenchpress','coldbrew','batch'];
    const _wantType=_methodToType[BS.altMethod];
    const dr=S.equipment.filter(e=>e.type==='dripper'&&(_wantType?dripperType(e.name)===_wantType:!_EXCLUSIVE_TYPES.includes(dripperType(e.name))));
    if(dr.length===0){
      /* юзер ще не додав свій пристрій цього типу — пропонуємо готові моделі з бази */
      const suggested=_wantType
        ?DB.dripper.filter(d=>dripperType(d.name)===_wantType)
        :DB.dripper.filter(d=>!_EXCLUSIVE_TYPES.includes(dripperType(d.name)));
      if(suggested.length){
        document.getElementById('bdripper-pick').innerHTML=
          `<div class="sec-lbl">Рекомендовані моделі</div>`+
          suggested.map(d=>`<div class="pick-item" onclick="bAddAndSelectDripper('${d.name.replace(/'/g,"\\'")}')">
            <div><div class="pick-main">${d.name}</div><div class="pick-sub">${d.sub}</div></div>
            <i class="ti ti-plus" style="color:var(--copper-lt)" aria-hidden="true"></i>
          </div>`).join('');
      } else {
        document.getElementById('bdripper-pick').innerHTML='<div style="padding:20px;text-align:center;color:var(--txt3);font-size:13px">Список порожній — натисни «Додати» вгорі</div>';
        const fi=document.getElementById('inline-add-dripper');
        if(fi) fi.style.display='block';
      }
    } else {
      document.getElementById('bdripper-pick').innerHTML=dr.map(d=>{const sel=BS.dripper&&BS.dripper.id===d.id;
        return`<div class="pick-item" onclick="bSelDripper(${d.id})">
          <div style="display:flex;align-items:center;gap:12px;flex:1;min-width:0;margin-right:10px"><span style="flex-shrink:0;display:flex;width:40px;height:32px;align-items:center;justify-content:center">${bMiniDripper(d.name)}</span><div><div class="pick-main">${d.name}</div><div class="pick-sub">${d.size?d.size+' · ':''}${d.material||DRIPPER_LABEL[dripperType(d.name)]||'Воронка'}</div></div></div>
          <i class="ti ${sel?'ti-check" style="color:var(--copper-lt)':'ti-chevron-right" style="color:#555'};font-size:16px" aria-hidden="true"></i></div>`;}).join('');
    }
  }
  if(id==='ov-bespmachine'){
    const f=document.getElementById('inline-add-espresso');if(f)f.style.display='none';
    const em=S.equipment.filter(e=>e.type==='espresso');
    if(em.length===0){
      if(DB.espresso.length){
        document.getElementById('bespmachine-pick').innerHTML=
          `<div class="sec-lbl">Рекомендовані моделі</div>`+
          DB.espresso.map(d=>`<div class="pick-item" onclick="bAddAndSelectEspMachine('${d.name.replace(/'/g,"\\'")}')">
            <div><div class="pick-main">${d.name}</div><div class="pick-sub">${d.sub}</div></div>
            <i class="ti ti-plus" style="color:var(--copper-lt)" aria-hidden="true"></i>
          </div>`).join('');
      } else {
        document.getElementById('bespmachine-pick').innerHTML='<div style="padding:20px;text-align:center;color:var(--txt3);font-size:13px">Список порожній — натисни «Додати» вгорі</div>';
        const fi=document.getElementById('inline-add-espresso');
        if(fi) fi.style.display='block';
      }
    } else {
      document.getElementById('bespmachine-pick').innerHTML=em.map(d=>{const sel=BS.espMachine&&BS.espMachine.id===d.id;
        return`<div class="pick-item" onclick="bSelEspMachine(${d.id})">
          <div class="pick-main">${d.name}</div>
          <i class="ti ${sel?'ti-check" style="color:var(--copper-lt)':'ti-chevron-right" style="color:#555'};font-size:16px" aria-hidden="true"></i></div>`;}).join('');
    }
  }
  if(id==='ov-bacc'){
    renderBaccPick();
    const accs=S.equipment.filter(e=>e.type==='acc');
    if(accs.length===0){
      const fi=document.getElementById('inline-add-acc');
      if(fi) fi.style.display='block';
    }
  }
  if(id==='ov-bfilter'){
    const f=document.getElementById('inline-add-filter');if(f)f.style.display='none';
    document.getElementById('bfilter-pick').innerHTML=S.filters.length
      ?S.filters.map(fl=>{const pct=Math.round(fl.current/fl.total*100),sel=BS.filter&&BS.filter.id===fl.id;
        return`<div class="pick-item" onclick="bSelFilter(${fl.id})">
          <div style="flex:1;min-width:0;margin-right:10px"><div class="pick-main">${fl.name}</div><div class="pick-sub">Залишилось ${fl.current} / ${fl.total} шт</div><div class="pick-bar"><div class="pick-bar-p" style="width:${pct}%"></div></div></div>
          <i class="ti ${sel?'ti-check" style="color:#4CAF50':'ti-chevron-right" style="color:#555'};font-size:16px" aria-hidden="true"></i></div>`;}).join('')
      :'<div style="padding:20px;text-align:center;color:var(--txt3);font-size:13px">Список порожній — натисни «Додати» вгорі</div>';
  }
  if(id==='ov-bgrinder'){
    const f=document.getElementById('inline-add-grinder');if(f)f.style.display='none';
    const gr=S.equipment.filter(e=>e.type==='grinder');
    if(gr.length===0){
      /* юзер ще не додав свою кавомолку — пропонуємо готові моделі з бази */
      if(DB.grinder.length){
        document.getElementById('bgrinder-pick').innerHTML=
          `<div class="sec-lbl">Рекомендовані моделі</div>`+
          DB.grinder.map(d=>`<div class="pick-item" onclick="bAddAndSelectGrinder('${d.name.replace(/'/g,"\\'")}')">
            <div><div class="pick-main">${d.name}</div><div class="pick-sub">${d.sub}</div></div>
            <i class="ti ti-plus" style="color:var(--copper-lt)" aria-hidden="true"></i>
          </div>`).join('');
      } else {
        document.getElementById('bgrinder-pick').innerHTML='<div style="padding:20px;text-align:center;color:var(--txt3);font-size:13px">Список порожній — натисни «Додати» вгорі</div>';
        const fi=document.getElementById('inline-add-grinder');
        if(fi) fi.style.display='block';
      }
    } else {
      document.getElementById('bgrinder-pick').innerHTML=gr.map(g=>{const sel=BS.grinder&&BS.grinder.id===g.id;
        return`<div class="pick-item" onclick="bSelGrinder(${g.id})">
          <div style="flex:1;min-width:0;margin-right:10px"><div class="pick-main">${g.name}</div><div class="pick-sub">${g.gtype||'Кавомолка'}${g.burr?' · '+g.burr:''}</div></div>
          <i class="ti ${sel?'ti-check" style="color:var(--copper-lt)':'ti-chevron-right" style="color:#555'};font-size:16px" aria-hidden="true"></i></div>`;}).join('');
    }
  }
  document.getElementById(id).classList.add('open');
}
function closeOv(id){document.getElementById(id).classList.remove('open')}
