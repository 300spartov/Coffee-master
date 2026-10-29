var _ratePoursOpen=false;
function toggleRatePours(){
  _ratePoursOpen=!_ratePoursOpen;
  var body=document.getElementById('rate-pours-body');
  var btn=document.getElementById('rate-pours-toggle');
  if(body)body.style.display=_ratePoursOpen?'block':'none';
  if(btn)btn.textContent=_ratePoursOpen?'▲ сховати':'▼ показати';
  if(_ratePoursOpen)renderRatePours();
}
function renderRatePours(){
  var body=document.getElementById('rate-pours-body');
  if(!body)return;
  var pourIdx=0;
  var totalSec=Math.round((BS.elapsed||0)/1000);
  /* Спільний стиль колонок для рівного вирівнювання */
  var colLbl='width:58px;flex-shrink:0;font-size:9px;font-weight:800;padding:3px 0;text-align:center;border-radius:6px;font-family:var(--mono)';
  var colTime='width:108px;flex-shrink:0;font-size:10px;color:var(--txt3);font-family:var(--mono);white-space:nowrap';
  var colDur='width:30px;flex-shrink:0;font-size:11px;color:var(--txt3);font-family:var(--mono);text-align:right;font-weight:600';
  var colMl='width:80px;flex-shrink:0;display:flex;align-items:center;gap:4px;margin-left:auto';
  var rows=BS.steps.map(function(s,si){
    var tStr=function(ms){var sec=Math.floor((ms||0)/1000),m=Math.floor(sec/60),sc=sec%60;return(m<10?'0':'')+m+':'+(sc<10?'0':'')+sc;};
    var t0=tStr(s.t);var t1=tStr((s.t||0)+(s.ph||0));
    var dur=Math.round((s.ph||0)/1000);
    if(s.type==='pour'){
      var pi=pourIdx++;
      var lbl=pi===0?'Блум':'Влив '+(pi+1);
      return '<div style="display:flex;align-items:center;gap:10px;padding:10px 14px;border-bottom:1px solid var(--line-soft)">'
        +'<span style="'+colLbl+';background:rgba(74,158,219,.18);color:#5aabdf;border:1px solid rgba(74,158,219,.3)">'+lbl+'</span>'
        +'<span style="'+colTime+'">'+t0+'–'+t1+'</span>'
        +'<div style="'+colMl+'">'
        +'<input type="number" value="'+(s.ml!=null?s.ml.toFixed(1):'0')+'" min="0" max="600" step="0.5" '
        +'style="width:70px;background:var(--card);border:1px solid rgba(74,158,219,.35);border-radius:7px;color:var(--txt);font-family:var(--mono);font-size:14px;font-weight:700;text-align:center;padding:5px 4px" '
        +'readonly id="rate-s-'+si+'" onclick="openNumPad(\'rate-s-'+si+'\',\'pour-ml\')" oninput="updateRateStep('+si+',this.value)">'
        +'<span style="font-size:11px;color:var(--txt3)">мл</span>'
        +'</div>'
        +'<span style="'+colDur+'">'+dur+'с</span>'
        +'</div>';
    } else if(s.type==='pause'){
      return '<div style="display:flex;align-items:center;gap:10px;padding:8px 14px;border-bottom:1px solid var(--line-soft);background:rgba(255,255,255,.012)">'
        +'<span style="'+colLbl+';background:rgba(234,155,60,.15);color:var(--copper-lt);border:1px solid rgba(234,155,60,.25)">Пауза</span>'
        +'<span style="'+colTime+'">'+t0+'–'+t1+'</span>'
        +'<div style="width:80px;flex-shrink:0;margin-left:auto"></div>'
        +'<span style="'+colDur+'">'+dur+'с</span>'
        +'</div>';
    } else if(s.type==='action'){
      return '<div style="display:flex;align-items:center;gap:10px;padding:8px 14px;border-bottom:1px solid var(--line-soft)">'
        +'<span style="'+colLbl+';background:rgba(95,191,131,.12);color:#5fbf83;border:1px solid rgba(95,191,131,.2)">'+(s.lbl||'Дія')+'</span>'
        +'<span style="'+colTime+'">'+t0+'</span>'
        +'</div>';
    }
    return '';
  }).join('');
  body.innerHTML='<div style="background:var(--card-lo);border-radius:10px;overflow:hidden;margin-bottom:6px">'
    +rows
    +'<div style="display:flex;align-items:center;gap:10px;padding:11px 14px;background:rgba(255,255,255,.035);border-top:1px solid var(--line-soft)">'
    +'<span style="width:58px;flex-shrink:0;font-size:12px;font-weight:700;color:var(--txt);font-family:inherit">Загалом</span>'
    +'<span style="'+colTime+';color:transparent">——</span>'
    +'<div style="'+colMl+'">'
    +'<input type="number" value="'+BS.pouredFixed.toFixed(1)+'" min="0" max="2000" step="0.5" '
    +'style="width:70px;background:var(--card);border:1px solid var(--copper-dk);border-radius:7px;color:var(--copper-lt);font-family:var(--mono);font-size:14px;font-weight:700;text-align:center;padding:5px 4px" '
    +'id="rate-pour-total" readonly onclick="openNumPad(\'rate-pour-total\',\'pour-ml\')" oninput="updateRatePourTotal(this.value)">'
    +'<span style="font-size:11px;color:var(--txt3)">мл</span>'
    +'</div>'
    +'<span style="'+colDur+'">'+totalSec+'с</span>'
    +'</div>'
    +'</div>';
  /* Зареєструємо id нампаду для кожного step-поля */
  BS.steps.forEach(function(s,si){
    if(s.type==='pour'){
      var inp=document.getElementById('rate-s-'+si);
      if(inp)inp.setAttribute('data-step-idx',si);
    }
  });
}
function updateRateStep(stepIdx,val){
  var s=BS.steps[stepIdx];
  if(!s||s.type!=='pour')return;
  s.ml=Math.max(0,parseFloat(val)||0);
  BS.pouredFixed=BS.steps.filter(function(x){return x.type==='pour';}).reduce(function(acc,x){return acc+(x.ml||0);},0);
  var tot=document.getElementById('rate-pour-total');
  if(tot)tot.value=BS.pouredFixed.toFixed(1);
  document.getElementById('rate-ml').textContent=BS.pouredFixed.toFixed(1)+' мл';
}
function updateRatePour(idx,val){
  /* compat wrapper — idx = позиція серед пурів, знаходимо реальний step */
  var pours=BS.steps.filter(function(s){return s.type==='pour';});
  if(idx<0||idx>=pours.length)return;
  pours[idx].ml=Math.max(0,parseFloat(val)||0);
  BS.pouredFixed=pours.reduce(function(acc,p){return acc+(p.ml||0);},0);
  var tot=document.getElementById('rate-pour-total');
  if(tot)tot.value=BS.pouredFixed.toFixed(1);
  document.getElementById('rate-ml').textContent=BS.pouredFixed.toFixed(1)+' мл';
}
function updateRatePourTotal(val){
  var total=Math.max(0,parseFloat(val)||0);
  var pours=BS.steps.filter(function(s){return s.type==='pour';});
  if(!pours.length)return;
  var avg=Math.round(total/pours.length*10)/10;
  pours.forEach(function(p,i){
    p.ml=avg;
    /* оновлюємо step-input за step-idx */
    var si=BS.steps.indexOf(p);
    var inp=document.getElementById('rate-s-'+si);
    if(inp)inp.value=avg.toFixed(1);
  });
  BS.pouredFixed=total;
  document.getElementById('rate-ml').textContent=total.toFixed(1)+' мл';
}
