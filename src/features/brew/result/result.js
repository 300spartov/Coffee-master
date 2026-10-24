/* ── Екран-результат після збереження: ХР + вибір "заварити ще" / "до стрічки" ── */
function showBrewResultModal(xpInfo){
  if(!xpInfo)return;
  var old=document.getElementById('brew-result-modal');if(old)old.remove();
  var lvlText=xpInfo.leveledUp?('<div style="margin-top:8px;font-size:13px;color:var(--copper-lt);font-weight:700">🎉 Новий рівень '+xpInfo.newLevel+' — '+xpInfo.tierName+'!</div>'):'';
  var modal=document.createElement('div');
  modal.id='brew-result-modal';
  modal.style.cssText='position:fixed;inset:0;z-index:9000;background:rgba(0,0,0,.7);display:flex;align-items:center;justify-content:center;padding:24px';
  modal.innerHTML='<div style="background:var(--card-hi);border:1px solid var(--line-soft);border-radius:16px;padding:26px 20px;max-width:320px;width:100%;box-shadow:0 12px 32px rgba(0,0,0,.5);text-align:center">'
    +'<div style="font-size:34px;margin-bottom:6px">☕</div>'
    +'<div style="font-size:15px;color:var(--txt);margin-bottom:6px">Рецепт збережено!</div>'
    +'<div style="font-family:var(--mono);font-size:22px;font-weight:700;color:var(--copper-lt)">+'+xpInfo.gained+' XP</div>'
    +lvlText
    +'<div style="display:flex;gap:8px;margin-top:20px">'
    +'<button onclick="document.getElementById(\'brew-result-modal\').remove();showScr(\'scr-brew\');" style="flex:1;background:none;border:1px solid var(--line-soft);border-radius:10px;padding:11px 8px;font-size:13px;color:var(--txt2);cursor:pointer;font-family:inherit">Заварити ще</button>'
    +'<button onclick="document.getElementById(\'brew-result-modal\').remove();showScr(\'scr-home\');" style="flex:1;background:var(--copper);border:none;border-radius:10px;padding:11px 8px;font-size:13px;font-weight:700;color:#1c130a;cursor:pointer;font-family:inherit">До стрічки</button>'
    +'</div></div>';
  document.body.appendChild(modal);
}
