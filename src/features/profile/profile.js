/* ── PROFILE ── */
function renderProf(){
  const p=S.profile;const init=p.name?p.name[0].toUpperCase():'?';
  document.getElementById('pr-av').textContent=init;
  document.getElementById('hdr-av').innerHTML=`<span style="font-size:13px;font-weight:700;color:#fff">${init}</span>`;
  document.getElementById('pr-name').textContent=p.name||'Настрой профиль';
  document.getElementById('pr-cat').innerHTML=`<i class="ti ti-leaf" aria-hidden="true"></i> ${p.cat||'Новичок'}`;
  document.getElementById('pr-loc').textContent=p.loc||'';
  document.getElementById('st-b').textContent=S.brews.length;
  document.getElementById('st-i').textContent=S.beans.length;
  document.getElementById('st-e').textContent=S.equipment.length;
  document.getElementById('st-s').textContent=p.stazh||'—';
  renderStreak();
  const pcp=document.getElementById('prof-cal-panel');if(pcp)pcp.classList.remove('open');
  const pdb=document.getElementById('pdate-btn');if(pdb)pdb.classList.remove('lit');
  statOpen=false;
  document.getElementById('stat-toggle').classList.remove('open');
  document.getElementById('stat-collapse').classList.remove('open');
  renderStat();
}
function saveProf(){
  S.profile.name=document.getElementById('s-name').value.trim();
  S.profile.loc=document.getElementById('s-loc').value.trim();
  S.profile.cat=document.getElementById('s-cat').value;
  S.profile.stazh=document.getElementById('s-stazh').value.trim();
  save();closeOv('ov-settings');renderProf();toast('Профіль збережено');
}
