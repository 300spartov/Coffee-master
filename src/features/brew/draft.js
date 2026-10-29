function saveDraft(){
  try{
    /* Інтервали (mainInt/phaseInt/pauseInt) — це ID setInterval, нежиттєздатні
       після перезавантаження сторінки; не зберігаємо їх, лише дані стану. */
    const {mainInt,phaseInt,pauseInt,_pauseLiveInt,...BS_safe}=BS;
    localStorage.setItem('cm_draft_recipe', JSON.stringify({BS:BS_safe, screen: currentBrewScreen, ts: Date.now()}));
  }catch(e){}
}
/* ── ВІДКЛЮЧЕНО: функція "незавершений рецепт" викликала проблеми, прибрано до подальшого з'ясування ──
document.addEventListener('visibilitychange', function(){
  if(document.hidden) saveDraft();
});
window.addEventListener('beforeunload', saveDraft);
*/

function tryRestoreDraft(){
  try{
    const raw=localStorage.getItem('cm_draft_recipe');
    if(!raw)return;
    const draft=JSON.parse(raw);
    /* Чернетку має сенс пропонувати лише для екранів активного процесу —
       не для bv-method-pick (там ще немає чого відновлювати) */
    if(!draft.screen||draft.screen==='bv-method-pick'){
      localStorage.removeItem('cm_draft_recipe');
      return;
    }
    const elapsed=Date.now()-draft.ts;
    if(elapsed>60*60*1000){ // більше 1 години — видалити
      localStorage.removeItem('cm_draft_recipe');
      return;
    }
    if(elapsed<30*1000){
      // менше 30 сек — одразу відновити без питання
      restoreDraftData(draft);
    } else {
      // 30 сек - 1 година — показати банер з питанням
      showDraftBanner(draft);
    }
  }catch(e){}
}
function restoreDraftData(draft){
  BS=draft.BS;
  showBV(draft.screen);
  /* Параметри рецепту — інпути не прив'язані до BS напряму (bCalc лише
     читає з них в BS), тож після підміни BS їх треба заповнити вручну */
  const doseEl=document.getElementById('b-dose');if(doseEl&&BS.dose!=null)doseEl.value=BS.dose;
  const ratioEl=document.getElementById('b-ratio');if(ratioEl&&BS.ratio!=null)ratioEl.value=BS.ratio;
  const poursEl=document.getElementById('b-pours');if(poursEl&&BS.pours!=null)poursEl.value=BS.pours;
  const clicksEl=document.getElementById('clicks-val');if(clicksEl&&BS.clicks!=null)clicksEl.textContent=BS.clicks;
  if(typeof setWet==='function'&&BS.wet!=null) setWet(BS.wet);
  if(typeof bCalc==='function') bCalc();
  /* Синхронізуємо UI вибраних пристроїв — bSel*-функції самі оновлюють
     відповідні DOM-елементи і безпечні навіть без відкритого overlay
     (closeOv просто знімає клас, якого вже й немає). */
  if(BS.bean&&BS.bean.id!=null) bSelBean(BS.bean.id);
  if(BS.dripper&&BS.dripper.id!=null) bSelDripper(BS.dripper.id);
  if(BS.grinder&&BS.grinder.id!=null) bSelGrinder(BS.grinder.id);
  if(BS.espMachine&&BS.espMachine.id!=null) bSelEspMachine(BS.espMachine.id);
  if(BS.filter&&BS.filter.id!=null&&typeof bSelFilter==='function') bSelFilter(BS.filter.id);
  if(typeof renderBaccList==='function') renderBaccList();
  if(draft.screen==='bv-active') resumeBrewTimers();
}
function restoreDraft(){
  const raw=localStorage.getItem('cm_draft_recipe');
  if(!raw)return;
  const draft=JSON.parse(raw);
  restoreDraftData(draft);
  const b=document.getElementById('draft-banner');if(b)b.remove();
}
function dismissDraft(){
  localStorage.removeItem('cm_draft_recipe');
  const b=document.getElementById('draft-banner');if(b)b.remove();
}
function showDraftBanner(draft){
  const old=document.getElementById('draft-banner');if(old)old.remove();
  const banner=document.createElement('div');
  banner.id='draft-banner';
  banner.style.cssText='position:fixed;top:0;left:0;right:0;z-index:9000;background:var(--card-hi);border-bottom:1px solid var(--line-soft);padding:12px 16px;display:flex;align-items:center;justify-content:space-between;gap:10px';
  banner.innerHTML=`<span style="font-size:13px;color:var(--txt)" data-i18n="draft_banner_text">${t('draft_banner_text')}</span>
    <div style="display:flex;gap:8px">
      <button onclick="dismissDraft()" style="background:none;border:1px solid var(--line-soft);border-radius:8px;padding:6px 12px;font-size:12px;color:var(--txt2);cursor:pointer" data-i18n="draft_close">${t('draft_close')}</button>
      <button onclick="restoreDraft()" style="background:var(--copper);border:none;border-radius:8px;padding:6px 12px;font-size:12px;font-weight:600;color:#1c130a;cursor:pointer" data-i18n="draft_continue">${t('draft_continue')}</button>
    </div>`;
  document.body.appendChild(banner);
}
function resetBrewDraft(){
  localStorage.removeItem('cm_draft_recipe');
  brewReset();
}
