/* ══════════════════════════════════════════
   Зберегти рецепт
   ══════════════════════════════════════════ */
function saveBrew(){
  RS.rating=parseFloat(document.getElementById('rate-slider').value)||8;
  RS.notes=document.getElementById('brew-notes').value.trim();
  RS.flavors=(window.nwGetFlavors?window.nwGetFlavors():[]);
  RS.aroma=(window.nwGetAroma?window.nwGetAroma():[]);
  const dripName=BS.dripper?BS.dripper.name:'';
  const methodLbl=BS.altMethod||(BS.dripper?DRIPPER_LABEL[dripperType(BS.dripper.name)]:'Альтернатива');
  const grinderName=BS.grinder?BS.grinder.name:'';
  const brew={id:++S.id,beanName:BS.bean?BS.bean.name:'',roaster:BS.bean?BS.bean.roaster:'',roastType:BS.bean?BS.bean.roastType:'',beanId:BS.bean?BS.bean.id:null,method:methodLbl,inverted:BS.inverted||false,aeroFilters:BS.aeroFilters||1,dripper:dripName,dripperId:BS.dripper?BS.dripper.id:null,grinder:grinderName,grinderId:BS.grinder?BS.grinder.id:null,clicks:BS.clicks,temp:document.getElementById('b-temp-sl').value,ratio:BS.ratio,filter:BS.filter?BS.filter.name:'',filterId:BS.filter?BS.filter.id:null,filterWet:BS.wet,dose:BS.dose.toFixed(1),steps:BS.steps,totalTime:fmt(BS.elapsed),rating:Math.round(RS.rating*10)/10,flavors:RS.flavors,aroma:RS.aroma,notes:RS.notes,accessories:BS.accessories||[],likes:0,liked:false,ts:Date.now()};
  S.brews.unshift(brew);
  S.log.unshift({id:brew.id,ts:brew.ts,vol:Math.round(BS.pouredFixed||(BS.dose*BS.ratio)),cat:methodCat(methodLbl),method:methodLbl,bean:brew.beanName,rating:brew.rating,dose:BS.dose});
  if(BS.bean){const bean=S.beans.find(b=>b.id===BS.bean.id);if(bean){bean.current=Math.max(0,bean.current-BS.dose);bean._upd=Date.now();if(bean.current===0)toast('⚠️ '+bean.name+' закончилось!');}}
  if(BS.filter){const filter=S.filters.find(f=>f.id===BS.filter.id);if(filter){filter.current=Math.max(0,filter.current-1);if(filter.current===0)toast('⚠️ Фильтры '+filter.name+' закончились!');else if(filter.current<=10)toast('⚠️ Мало фильтров: '+filter.current+' шт');}}
  save();
  document.getElementById('b-res-t').textContent=fmt(BS.elapsed);
  document.getElementById('b-res-ml').textContent=BS.pouredFixed.toFixed(1)+' мл';
  document.getElementById('b-res-rating').textContent=brew.rating.toFixed(1);
  document.getElementById('b-res-flavors').textContent=(RS.flavors.length+RS.aroma.length);
  document.getElementById('b-res-info').textContent=(BS.bean?BS.bean.name+' · ':'')+brew.temp+'°C · 1:'+brew.ratio;
  var xpInfo=addBrewXp('alt', brew.method, brew.id);showBV('bv-result');toast('Рецепт збережено!');
  localStorage.removeItem('cm_draft_recipe');currentBrewScreen='bv-method-pick';
  showBrewResultModal(xpInfo);
}
function brewGoSetup(){clearInterval(BS.mainInt);clearInterval(BS.phaseInt);clearInterval(BS.pauseInt);Object.assign(BS,{mainInt:null,phaseInt:null,pauseInt:null,mainStart:null,steps:[],pourCnt:0,phase:'idle',elapsed:0,phaseMs:0,pouredFixed:0,firstDone:false});showBV('bv-setup');bCalc();}
function brewReset(){
  bFinalize();
  Object.assign(BS,{bean:null,filter:null,dripper:null,grinder:null,espMachine:null,accessories:[],clicks:28,wet:true,dose:16,ratio:16,pours:3,mainInt:null,phaseInt:null,pauseInt:null,mainStart:null,steps:[],pourCnt:0,phase:'idle',elapsed:0,phaseMs:0,pouredFixed:0,firstDone:false,espMethod:null,espNeedsMilk:false,espNeedsIce:false,milk:null,ice:null});
  document.getElementById('bsel-bean').textContent=t('devices_choose_bean');
  document.getElementById('bsel-bean-sub').textContent=t('devices_tap');
  document.getElementById('bbean-bar').style.display='none';
  document.getElementById('bsel-dripper').textContent=t(dripperLabelKey(BS.altMethod));
  document.getElementById('bsel-dripper-sub').textContent=t('devices_tap');
  document.getElementById('bsel-dripper-ico').innerHTML='';
  document.getElementById('bsel-filter').textContent=t('devices_choose_filter');
  document.getElementById('bsel-filter-sub').textContent=t('devices_tap');
  document.getElementById('bfilter-bar').style.display='none';
  document.getElementById('bsel-grinder').textContent=t('devices_choose_grinder');
  document.getElementById('bsel-grinder-sub').textContent=t('devices_tap');
  const _bem=document.getElementById('bsel-espmachine');if(_bem)_bem.textContent=t('devices_choose_espmachine');
  const _bems=document.getElementById('bsel-espmachine-sub');if(_bems)_bems.textContent=t('devices_tap');
  renderBaccList();
  document.getElementById('clicks-val').textContent='28';
  document.getElementById('brew-title').textContent='Заварювання';
  BS.altMethod=null;
  BS.inverted=false;
  BS.aeroFilters=1;
  const _af=document.getElementById('b-aero-filters');if(_af)_af.textContent='1';
  const _fw=document.getElementById('b-filter-count-wrap');if(_fw)_fw.style.display='none';
  /* скидаємо вигляд рівня 2 */
  if(document.getElementById('bv-method-l1'))document.getElementById('bv-method-l1').style.display='';
  if(document.getElementById('bv-method-l2'))document.getElementById('bv-method-l2').style.display='none';
  document.getElementById('b-dose').value='16';
  document.getElementById('b-ratio').value='16';
  document.getElementById('b-pours').value='3';
  const _tsl=document.getElementById('b-temp-sl');
  if(_tsl){_tsl.min='80';_tsl.max='100';_tsl.step='1';_tsl.value='93';}
  document.getElementById('b-temp-out').textContent='93°C';
  showPauseActions(false);resetPauseActions();
  setWet(true);bCalc();showBV('bv-method-pick');
}
