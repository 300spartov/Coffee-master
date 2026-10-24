function showScr(id){
  document.querySelectorAll('.scr').forEach(s=>s.classList.remove('on'));
  document.querySelectorAll('.nb').forEach(b=>b.classList.remove('on'));
  const el=document.getElementById(id);if(el)el.classList.add('on');
  const nbMap={'scr-home':'nb-home','scr-coffee':'nb-coffee','scr-eq':'nb-eq','scr-devlist':'nb-eq','scr-profile':'nb-profile','scr-stats':'nb-profile','scr-compare':'nb-home'};
  const nb=nbMap[id];if(nb)document.getElementById(nb)?.classList.add('on');
  const fn={'scr-home':renderFeed,'scr-coffee':renderBeans,'scr-eq':renderCatGrid,'scr-profile':renderProf,'scr-market':mktRender,'scr-ach':renderAchievements};if(id==='scr-brew')showBV('bv-method-pick');
  if(fn[id])fn[id]();
  /* FAB порівняння — показуємо тільки в журналі */
  var fab=document.getElementById('cp-fab');
  if(fab)fab.style.display=(id==='scr-home'&&CP_SELECTED.length>=2)?'block':'none';
}
