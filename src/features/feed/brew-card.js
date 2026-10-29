/* ── BREW CARD TABS & DIAGRAM ── */
function bcTab(bid,n,btn){
  for(var i=0;i<3;i++){
    var p=document.getElementById('bcp-'+i+'-'+bid);
    if(p)p.classList.toggle('on',i===n);
  }
  var tabs=btn.closest('.bc-tabs').querySelectorAll('.bc-tab');
  tabs.forEach(function(t,i){t.classList.toggle('on',i===n);});
}
function bcLogToggle(bid,mode,btn){
  var logDiv=document.getElementById('bcl-log-'+bid);
  var diaDiv=document.getElementById('bcl-dia-'+bid);
  var logBtn=document.getElementById('bct-log-'+bid);
  var diaBtn=document.getElementById('bct-dia-'+bid);
  var onStyle='flex:1;padding:7px 8px;border-radius:7px;border:none;cursor:pointer;font-family:var(--mono);font-size:10px;font-weight:600;letter-spacing:.5px;background:linear-gradient(160deg,var(--card-hi),var(--card-lo));box-shadow:inset 0 1px 0 rgba(255,255,255,.05);';
  var offStyle='flex:1;padding:7px 8px;border-radius:7px;border:none;cursor:pointer;font-family:var(--mono);font-size:10px;font-weight:600;letter-spacing:.5px;background:none;';
  if(mode==='log'){
    if(logDiv)logDiv.style.display='block';
    if(diaDiv)diaDiv.style.display='none';
    if(logBtn)logBtn.style.cssText=onStyle+'color:var(--copper-lt);';
    if(diaBtn)diaBtn.style.cssText=offStyle+'color:var(--txt3);';
  } else {
    if(logDiv)logDiv.style.display='none';
    if(diaDiv)diaDiv.style.display='block';
    if(logBtn)logBtn.style.cssText=offStyle+'color:var(--txt3);';
    if(diaBtn)diaBtn.style.cssText=onStyle+'color:var(--steel);';
  }
}
function bcSegTap(bid,idx,val,lbl){
  var vEl=document.getElementById('bcdv-'+bid);
  var lEl=document.getElementById('bcdl-'+bid);
  if(vEl)vEl.textContent=val;
  if(lEl)lEl.textContent=lbl;
}

/* ── RING TAP — интерактив кольца ── */
var _ringSelected={};

function ringNext(bid){
  var brew=S.brews.find(function(b){return b.id===bid;});
  var steps=(brew?brew.steps||[]:[]).filter(function(s){return s.type==='pour'||s.type==='pause'||s.type==='action';});
  var cur=_ringSelected[bid];
  var next=(cur===null||cur===undefined)?0:cur+1;
  if(next>=steps.length)next=null;
  _ringSelected[bid]=next;
  ringTap(bid, next===null?-1:next, true);
}
function ringReset(bid){
  _ringSelected[bid]=null;
  ringTap(bid,-1,true);
}
function ringTap(bid,i,fromNext){
  var brew=S.brews.find(function(b){return b.id===bid;});
  var steps=(brew?brew.steps||[]:[]).filter(function(s){return s.type==='pour'||s.type==='pause'||s.type==='action';});
  var prev=_ringSelected[bid];
  if(i===-1){_ringSelected[bid]=null;}
  else if(!fromNext){_ringSelected[bid]=(prev===i)?null:i;}
  var sel=_ringSelected[bid];
  var COL={pour:{base:'#3E8FCE',on:'#74C0F5',glow:'rgba(116,192,245,.6)'},pause:{base:'#DC7E16',on:'#F7AC34',glow:'rgba(247,172,52,.6)'},action:{base:'#6C6C72',on:'#C3BFB8',glow:'rgba(178,178,188,.6)'}};
  var _ACTION_COL={'Перемішування':'#5fbf83','Чавимо':'#7c5cbf','Свьорл':'#38C4B8','Взбалтування':'#B8A0E8','Взбалтывание':'#B8A0E8','Перемешивание':'#5fbf83'};
  function fmtSec(sec){var m=Math.floor(sec/60);return m+':'+String(Math.round(sec)%60).padStart(2,'0');}
  var svg=document.getElementById('rring-'+bid);if(!svg)return;
  var segs=svg.querySelectorAll('.rring-seg');
  segs.forEach(function(p,j){
    var st=steps[j];if(!st)return;
    var isAct=st.type==='action';
    var actColor=(isAct&&st.label&&_ACTION_COL[st.label])?_ACTION_COL[st.label]:(isAct&&st.color)?st.color:null;
    var c=actColor?{base:actColor,on:actColor,glow:'rgba(0,0,0,0)'}:(COL[st.type]||COL.action);
    var on=(sel===j);
    p.setAttribute('stroke',c.base);
    p.setAttribute('stroke-width',on?22:14);
    p.style.opacity=(sel===null||on)?'1':'.38';
    p.style.filter=on?'drop-shadow(0 0 7px '+c.glow+')':'none';
  });
  var tEl=document.getElementById('rring-t-'+bid),cEl=document.getElementById('rring-c-'+bid);
  var nEl=document.getElementById('rring-n-'+bid),xEl=document.getElementById('rring-x-'+bid);
  var rstBtn=document.getElementById('rring-reset-'+bid);
  var footEl=document.getElementById('rring-foot-'+bid);
  if(sel===null){
    if(tEl){tEl.textContent=brew?brew.totalTime||'—':'—';tEl.style.color='var(--txt)';}
    if(cEl){cEl.textContent=t('brew_total');cEl.style.color='var(--txt3)';}
    if(nEl)nEl.textContent='';if(xEl)xEl.textContent='';
    if(footEl)footEl.style.display='flex';
    if(rstBtn){rstBtn.disabled=true;rstBtn.style.opacity='.4';rstBtn.style.background='linear-gradient(180deg,#1c1e21,#191b1e)';rstBtn.style.color='var(--txt3)';}
  }else{
    var st=steps[sel];
    var isAct2=st.type==='action';
    var actColor2=(isAct2&&st.label&&_ACTION_COL[st.label])?_ACTION_COL[st.label]:(isAct2&&st.color)?st.color:null;
    var c=actColor2?{base:actColor2,on:actColor2,glow:'rgba(0,0,0,0)'}:(COL[st.type]||COL.action);
    var durSec=st.ph!=null?st.ph/1000:(st.dur||0);
    if(tEl){tEl.textContent=fmtSec(durSec);tEl.style.color=c.on;}
    if(cEl){cEl.textContent='';cEl.style.color='transparent';}
    var labels={pour:t('brew_pour'),pause:t('brew_pause'),action:t('brew_action_lbl')};
    if(nEl){nEl.textContent=st.label||(labels[st.type]||t('brew_step_lbl'));nEl.style.color=c.on;}
    if(xEl)xEl.textContent=st.ml?st.ml.toFixed(0)+' мл':(sel+1)+' / '+steps.length;
    if(footEl)footEl.style.display='none';
    if(rstBtn){rstBtn.disabled=false;rstBtn.style.opacity='1';rstBtn.style.background='linear-gradient(180deg,#26282c,#202225)';rstBtn.style.color='var(--txt)';}
  }
}

function toggleRec(id){const p=document.getElementById('rec-'+id),b=document.getElementById('ex-'+id);const o=p.classList.toggle('open');b.classList.toggle('open',o);const card=document.getElementById('bc-'+id);if(card)card.classList.toggle('rec-open',o);}
function toggleLike(id){const b=S.brews.find(x=>x.id===id);if(!b)return;b.liked=!b.liked;b.likes+=b.liked?1:-1;save();renderFeed()}
