function bEspCalc(){
  const dose=parseFloat(document.getElementById('b-esp-dose').value)||18;
  const ratio=parseFloat(document.getElementById('b-esp-ratio-sel').value)||2;
  const yld=Math.round(dose*ratio*10)/10;
  document.getElementById('b-esp-dose-lbl').textContent=dose;
  document.getElementById('b-esp-yield-lbl').textContent=yld;
  document.getElementById('b-esp-ratio-lbl').textContent=ratio.toFixed(1);
  // сохраняем для таймера
  if(window._espYield!==undefined)window._espYield=yld;
}

function espStartShot(){
  clearInterval(espInt);espSec=0;espRunning=false;
  const dose=parseFloat(document.getElementById('b-esp-dose').value)||18;
  const ratio=parseFloat(document.getElementById('b-esp-ratio-sel').value)||2;
  const yld=Math.round(dose*ratio*10)/10;
  const targetSec=27; // стандарт, уточняется фактом
  document.getElementById('esp-dose-disp').textContent=dose+' г';
  document.getElementById('esp-yield-disp').textContent=yld+' г';
  document.getElementById('esp-target-s').textContent=targetSec+'с ціль';
  document.getElementById('esp-timer').textContent='0:00';
  document.getElementById('esp-seconds').textContent='0';
  document.getElementById('esp-time-bar').style.width='0%';
  document.getElementById('esp-time-bar').style.background='var(--copper-lt)';
  document.getElementById('esp-fill').setAttribute('y','70');
  document.getElementById('esp-fill').setAttribute('height','0');
  document.getElementById('esp-drop').setAttribute('opacity','0');
  document.getElementById('esp-phase-lbl').textContent='Готовий до старту';
  document.getElementById('brew-title').textContent='';
  document.getElementById('brew-sub').textContent=dose+'г → '+yld+'г · '+document.getElementById('b-esp-temp-out').textContent;
  document.getElementById('esp-start-btn').disabled=false;
  document.getElementById('esp-start-btn').style.opacity='1';
  document.getElementById('esp-stop-btn').disabled=true;
  document.getElementById('esp-stop-btn').style.opacity='0.5';
  window._espTargetSec=targetSec;
  window._espYield=yld;
  showBV('bv-esp-active');
}

function espStartTimer(){
  if(espRunning)return;
  espRunning=true;espSec=0;
  const targetSec=window._espTargetSec||27;
  document.getElementById('esp-start-btn').disabled=true;
  document.getElementById('esp-start-btn').style.opacity='0.5';
  document.getElementById('esp-stop-btn').disabled=false;
  document.getElementById('esp-stop-btn').style.opacity='1';
  document.getElementById('esp-phase-lbl').textContent=t('brew_pouring_active');
  document.getElementById('esp-drop').setAttribute('opacity','1');
  espInt=setInterval(()=>{
    espSec++;
    const m=Math.floor(espSec/60),s=espSec%60;
    document.getElementById('esp-timer').textContent=m+':'+(s<10?'0':'')+s;
    document.getElementById('esp-seconds').textContent=espSec;
    const pct=Math.min(espSec/targetSec*100,100);
    document.getElementById('esp-time-bar').style.width=pct+'%';
    const fillH=Math.min(pct*0.4,40);
    document.getElementById('esp-fill').setAttribute('y',(70-fillH).toString());
    document.getElementById('esp-fill').setAttribute('height',fillH.toString());
    if(espSec>=targetSec){
      document.getElementById('esp-phase-lbl').textContent='Оптимальний час!';
      document.getElementById('esp-time-bar').style.background='#4CAF50';
    }
  },1000);
}

function espStopTimer(){
  clearInterval(espInt);espRunning=false;
  document.getElementById('esp-drop').setAttribute('opacity','0');
  document.getElementById('esp-phase-lbl').textContent='Готово — '+espSec+'с';
  if(BS.espNeedsMilk||BS.espNeedsIce){
    document.getElementById('em-milk-name').value='';
    document.getElementById('em-milk-temp').value='60';
    document.getElementById('em-milk-vol').value='150';
    document.getElementById('em-ice-amount').value='4';
    document.getElementById('em-mixer-name').value='';
    document.getElementById('esp-milk-block').style.display=BS.espNeedsMilk?'block':'none';
    document.getElementById('esp-ice-block').style.display=BS.espNeedsIce?'block':'none';
    const emt=document.getElementById('esp-milk-title');if(emt)emt.textContent=BS.espNeedsIce?'Додай лід та мікс':'Додай молоко';
    renderFrotherSelect();
    showBV('bv-esp-milk');
    return;
  }
  espFinishToResult();
}
function renderFrotherSelect(){
  const sel=document.getElementById('em-frother');if(!sel)return;
  const accs=S.equipment.filter(e=>e.type==='acc');
  sel.innerHTML='<option value="steamer">Стимер</option>'+accs.map(a=>`<option value="${a.id}">${a.name}</option>`).join('');
}
function espFinishToResult(){
  // Перехід на екран результату
  const dose=parseFloat(document.getElementById('b-esp-dose').value)||18;
  document.getElementById('esp-res-time-lbl').textContent='Час проливу: '+espSec+' секунд';
  document.getElementById('esp-res-sec').textContent=espSec+'с';
  document.getElementById('esp-res-dose-disp').textContent=dose+' г';
  document.getElementById('esp-actual-yield').value='';
  document.getElementById('esp-tds-actual').value='';
  document.getElementById('esp-notes').value='';
  document.getElementById('esp-rate-slider').value='8';
  document.getElementById('esp-rate-num').textContent='8.0';
  applyRatingColor('esp-rate-num','esp-rate-slider',8);
  // Слухаємо зміну виходу для розрахунку коефіцієнта
  const yieldInp=document.getElementById('esp-actual-yield');
  yieldInp.oninput=()=>{
    const y=parseFloat(yieldInp.value)||0;
    const r=dose>0?(y/dose).toFixed(1):'—';
    document.getElementById('esp-actual-ratio').textContent='1 : '+r;
  };
  if(window.nwResetAll) window.nwResetAll();
  showBV('bv-esp-result');
}

function espMilkContinue(){
  BS.milk=BS.espNeedsMilk?{
    name:document.getElementById('em-milk-name').value.trim(),
    temp:document.getElementById('em-milk-temp').value,
    vol:document.getElementById('em-milk-vol').value,
    frother:(()=>{const v=document.getElementById('em-frother').value;if(v==='steamer')return'Стимер';const a=v?S.equipment.find(e=>e.id===parseInt(v)):null;return a?a.name:'';})()
  }:null;
  if(BS.milk&&BS.milk.name&&!S.milks.includes(BS.milk.name))S.milks.push(BS.milk.name);
  BS.ice=BS.espNeedsIce?{
    amount:document.getElementById('em-ice-amount').value,
    mixer:document.getElementById('em-mixer-name').value.trim()
  }:null;
  if(BS.ice&&BS.ice.mixer&&!S.juices.includes(BS.ice.mixer))S.juices.push(BS.ice.mixer);
  espFinishToResult();
}
function espAbandon(){
  clearInterval(espInt);espRunning=false;
  showBV('bv-setup');
}

function espSave(){
  const dose=parseFloat(document.getElementById('b-esp-dose').value)||18;
  const ratio=parseFloat(document.getElementById('b-esp-ratio-sel').value)||2;
  const targetYield=Math.round(dose*ratio*10)/10;
  const actualYield=parseFloat(document.getElementById('esp-actual-yield').value)||0;
  const tdsTarget=parseFloat(document.getElementById('esp-tds-target').value)||0;
  const tdsActual=parseFloat(document.getElementById('esp-tds-actual').value)||0;
  const rating=parseFloat(document.getElementById('esp-rate-slider').value)||8;
  const notes=document.getElementById('esp-notes').value.trim();
  const temp=document.getElementById('b-esp-temp-out').textContent;
  const bar=document.getElementById('b-esp-bar-sl').value;
  const brew={
    id:++S.id,beanName:BS.bean?BS.bean.name:'',roaster:BS.bean?BS.bean.roaster:'',roastType:BS.bean?BS.bean.roastType:'',beanId:BS.bean?BS.bean.id:null,
    method:BS.espMethod||t('method_esp'),dose:dose.toString(),temp:temp.replace('°C',''),
    grinder:BS.grinder?BS.grinder.name:'',grinderId:BS.grinder?BS.grinder.id:null,clicks:BS.clicks,
    espMachine:BS.espMachine?BS.espMachine.name:'',espMachineId:BS.espMachine?BS.espMachine.id:null,accessories:BS.accessories||[],
    espresso:{dose,targetYield,actualYield,shotTime:espSec,tdsTarget,tdsActual,pressure:bar},
    milk:BS.milk||null,ice:BS.ice||null,
    totalTime:espSec+'с',ratio:(actualYield>0?(actualYield/dose).toFixed(1):ratio.toFixed(1)),
    rating:Math.round(rating*10)/10,
    flavors:(window.nwGetFlavors?window.nwGetFlavors():[]),
    aroma:(window.nwGetAroma?window.nwGetAroma():[]),
    notes,likes:0,liked:false,ts:Date.now()
  };
  if(BS.bean){const bean=S.beans.find(b=>b.id===BS.bean.id);if(bean){bean.current=Math.max(0,bean.current-dose);bean._upd=Date.now();}}
  S.brews.unshift(brew);
  S.log.unshift({id:brew.id,ts:brew.ts,vol:Math.round(actualYield>0?actualYield:targetYield),cat:methodCat(brew.method),method:brew.method,bean:brew.beanName,rating:brew.rating,dose:dose});
  save();
  var xpInfo=addBrewXp('esp', brew.method, brew.id);
  toast('Шот збережено!');
  BS.espMethod=null;BS.espNeedsMilk=false;BS.espNeedsIce=false;BS.milk=null;BS.ice=null;
  localStorage.removeItem('cm_draft_recipe');currentBrewScreen='bv-method-pick';
  if(document.getElementById('bv-method-l1'))document.getElementById('bv-method-l1').style.display='';
  if(document.getElementById('bv-method-l2'))document.getElementById('bv-method-l2').style.display='none';
  showScr('scr-home');
  showBrewResultModal(xpInfo);
}

function espRatioAdj(delta){
  const el=document.getElementById('b-esp-ratio-sel');if(!el)return;
  const v=Math.round((parseFloat(el.value||2)+delta)*10)/10;
  el.value=Math.min(5,Math.max(1,v)).toFixed(1);
  bEspCalc();
}
