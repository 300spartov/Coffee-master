var CW_ROASTS=[];
var CW_SEGC={filter:'#E0A93B',espresso:'#A85A2E',omni:'#8198AE'};
var cwi=0;
var _cwPeriod='year';
var _CW_CIRC=2*Math.PI*61; /* ≈ 383.27 */
var _CW_GAP=_CW_CIRC*0.035; /* ≈ 3.5% від довжини кола на проміжок між сегментами */

function cwWeight(kg){ return kg<1 ? {v:String(Math.round(kg*1000)),u:'г'} : {v:parseFloat(kg.toFixed(2)).toString(),u:'кг'}; }
function cwHx(h,a){var n=parseInt(h.slice(1),16);return 'rgba('+(n>>16&255)+','+(n>>8&255)+','+(n&255)+','+a+')';}
function cwNext(){cwi=(cwi+1)%CW_ROASTS.length;cwApply();}

/* ─── Coffee stats: навігація по тижнях/місяцях ─── */
var _cwNavOffset=0; /* 0=поточний, -1=попередній і т.д. */

function cwSetPeriod(p){
  _cwPeriod=p;
  _cwNavOffset=0;
  document.querySelectorAll('.cw-tabs .cw-tab').forEach(function(b){
    b.classList.toggle('on', b.getAttribute('data-period')===p);
  });
  var nav=document.getElementById('cw-nav');
  var customRange=document.getElementById('cw-custom-range');
  if(p==='year'){nav.style.display='none';}else{nav.style.display='flex';}
  if(p==='custom'){customRange.style.display='block';nav.style.display='none';}else{customRange.style.display='none';}
  cwi=0;
  cwBuildData();
}

function cwNavPrev(){_cwNavOffset--;cwi=0;cwBuildData();}
function cwNavNext(){
  if(_cwNavOffset<0){_cwNavOffset++;cwi=0;cwBuildData();}
}
function cwUpdateCustom(){cwi=0;cwBuildData();}

function cwGetRange(){
  var now=new Date(),p=_cwPeriod;
  var from,to;
  if(p==='week'){
    var d=new Date(now);
    d.setDate(d.getDate()-d.getDay()+1+_cwNavOffset*7); /* Пн */
    from=new Date(d.getFullYear(),d.getMonth(),d.getDate());
    to=new Date(from); to.setDate(to.getDate()+6); to.setHours(23,59,59,999);
  } else if(p==='month'){
    var y=now.getFullYear(),m=now.getMonth()+_cwNavOffset;
    while(m<0){m+=12;y--;}
    while(m>11){m-=12;y++;}
    from=new Date(y,m,1);
    to=new Date(y,m+1,0,23,59,59,999);
  } else if(p==='year'){
    from=new Date(now.getFullYear(),0,1);
    to=new Date(now.getFullYear(),11,31,23,59,59,999);
  } else if(p==='custom'){
    var f=document.getElementById('cw-date-from').value;
    var t=document.getElementById('cw-date-to').value;
    from=f?new Date(f):new Date(now.getFullYear(),now.getMonth(),1);
    to=t?new Date(t+'T23:59:59'):now;
  }
  return {from:from,to:to};
}

function cwFromPicked(val){
  /* Одразу відкриваємо "До" після вибору "Від" */
  var toInp=document.getElementById('cw-date-to');
  if(toInp&&val){
    toInp.min=val;
    toInp.showPicker?toInp.showPicker():toInp.focus();
  }
  cwUpdateCustom();
}
function cwNavLabel(){
  var r=cwGetRange(),p=_cwPeriod;
  var pad=function(n){return(n<10?'0':'')+n;};
  if(p==='week'){
    var f=r.from,t=r.to;
    return pad(f.getDate())+'.'+pad(f.getMonth()+1)+' – '+pad(t.getDate())+'.'+pad(t.getMonth()+1)+'.'+t.getFullYear();
  } else if(p==='month'){
    var mn=['Січень','Лютий','Березень','Квітень','Травень','Червень','Липень','Серпень','Вересень','Жовтень','Листопад','Грудень'];
    return mn[r.from.getMonth()]+' '+r.from.getFullYear();
  } else if(p==='year'){
    return String(r.from.getFullYear());
  }
  return '';
}

function cwBuildData(){
  /* Навігаційний підпис */
  var lbl=document.getElementById('cw-nav-label');if(lbl)lbl.textContent=cwNavLabel();
  var nextBtn=document.getElementById('cw-nav-next');
  if(nextBtn)nextBtn.style.opacity=_cwNavOffset<0?'1':'.3';

  /* Фільтруємо варіння по вибраному діапазону */
  var range=cwGetRange();
  var brews=(S.brews||[]).filter(function(b){
    var ts=b.ts||0;
    return (!range||!range.from||ts>=range.from.getTime())&&(!range||!range.to||ts<=range.to.getTime());
  });

  /* Статистика по зерну */
  var byType={filter:0,espresso:0,omni:0};
  var total=0,brewCount=brews.length,totalDose=0;
  var methodCounts={};
  var cafeCount=0;
  brews.forEach(function(b){
    var dose=parseFloat(b.dose);if(isNaN(dose))dose=16;
    totalDose+=dose;total+=dose;
    var lb=liveBeanInfo(b.beanId,b.beanName,b.roaster);
    var type=lb.roastType||b.roastType||getRoastType(b.method);
    if(!byType.hasOwnProperty(type))type='filter';
    byType[type]+=dose;
    if(b.cafeVisit)cafeCount++;
    var m=b.method||'Альтернатива';
    methodCounts[m]=(methodCounts[m]||0)+1;
  });
  var avgDose=brewCount?Math.round(totalDose/brewCount):0;
  /* Фаворит-метод */
  var favMethod='—',favCount=0;
  Object.keys(methodCounts).forEach(function(m){if(methodCounts[m]>favCount){favCount=methodCounts[m];favMethod=m;}});

  /* Кіло */
  var f=byType.filter/1000, e=byType.espresso/1000, o=byType.omni/1000, tot=total/1000;
  CW_ROASTS=[
    {label:'ВСЬОГО', kg:tot, color:'', seg:null},
    {label:'ФІЛЬТР', kg:f, color:'#E0A93B', seg:'filter'},
    {label:'ЕСПРЕСО',kg:e, color:'#A85A2E', seg:'espresso'},
    {label:'ОМНІ',   kg:o, color:'#8198AE', seg:'omni'}
  ];
  /* Зберігаємо для шерингу */
  window._cwShareData={
    range:range,brews:brews,brewCount:brewCount,favMethod:favMethod,
    cafeCount:cafeCount,avgDose:avgDose,
    total:total,byType:byType,period:_cwPeriod,navLabel:cwNavLabel()
  };

  var parts=[
    {id:'filter',  v:byType.filter,  color:'#E0A93B'},
    {id:'espresso',v:byType.espresso,color:'#A85A2E'},
    {id:'omni',    v:byType.omni,    color:'#8198AE'}
  ];
  var totalG=total||1;
  var offset=0;
  parts.forEach(function(p){
    var seg=document.getElementById('cw-seg-'+p.id);
    if(!seg)return;
    var share=p.v/totalG;
    var segLen=share*_CW_CIRC;
    seg.setAttribute('stroke-dasharray', segLen.toFixed(2)+' '+(_CW_CIRC-segLen).toFixed(2));
    seg.setAttribute('stroke-dashoffset', (-offset).toFixed(2));
    offset+=segLen;
  });
  parts.forEach(function(p){
    var el=document.getElementById('cw-kg-'+p.id);
    if(!el)return;
    var w=cwWeight(p.v/1000);
    el.textContent=w.v+' '+w.u;
  });
  var bc=document.getElementById('cw-brewcount');if(bc)bc.textContent=brewCount;
  var ad=document.getElementById('cw-avgdose');if(ad)ad.textContent=avgDose+' г';
  var cc=document.getElementById('cw-cafecnt');if(cc)cc.textContent=cafeCount;
  var fm=document.getElementById('cw-favmethod');if(fm)fm.textContent=favMethod;
  cwApply();
}

function cwShareStats(){
  var d=window._cwShareData;
  if(!d){toast('Дані не завантажені');return;}
  var pad=function(n){return(n<10?'0':'')+n;};
  var fmtDate=function(dt){return pad(dt.getDate())+'.'+pad(dt.getMonth()+1)+'.'+String(dt.getFullYear()).slice(2);};
  var dateLabel=d.navLabel||'';
  if(d.period==='custom'&&d.range&&d.range.from&&d.range.to){
    dateLabel=fmtDate(d.range.from)+' – '+fmtDate(d.range.to);
  }
  var totG=d.total,f=d.byType.filter,e=d.byType.espresso,o=d.byType.omni;
  var totKgW=cwWeight(totG/1000),fW=cwWeight(f/1000),eW=cwWeight(e/1000),oW=cwWeight(o/1000);
  var t2=totG||1;
  /* Три ОКРЕМИХ концентричних кільця — Фільтр/Еспресо/Омні */
  var TRACKS=[
    {r:108,sw:14,v:f,col:'#E0A93B',label:'Фільтр'},
    {r:84, sw:14,v:e,col:'#A85A2E',label:'Еспресо'},
    {r:60, sw:14,v:o,col:'#8198AE',label:'Омні'}
  ];
  var ringHTML='';
  TRACKS.forEach(function(tr){
    var circ=2*Math.PI*tr.r;
    var filled=tr.v>0?(tr.v/t2*circ):0;
    ringHTML+='<circle cx="150" cy="150" r="'+tr.r+'" fill="none" stroke="#1c1e22" stroke-width="'+tr.sw+'"/>';
    if(filled>2)ringHTML+='<circle cx="150" cy="150" r="'+tr.r+'" fill="none" stroke="'+tr.col+'" stroke-width="'+tr.sw+'" stroke-linecap="round" stroke-dasharray="'+filled.toFixed(2)+' '+(circ-filled).toFixed(2)+'" stroke-dashoffset="0" transform="rotate(-90 150 150)"/>';
  });
  var legendHTML=TRACKS.map(function(tr){
    var pct=t2>0?Math.round(tr.v/t2*100):0;
    var w=cwWeight(tr.v/1000);
    return '<div style="display:flex;align-items:center;gap:8px;margin-bottom:9px">'
      +'<div style="width:10px;height:10px;border-radius:50%;background:'+tr.col+';flex-shrink:0"></div>'
      +'<div style="flex:1;font-size:13px;font-weight:600;color:#c8c0b4">'+tr.label+'</div>'
      +'<div style="font-size:12px;font-weight:700;color:'+tr.col+';font-family:monospace;min-width:36px;text-align:right">'+pct+'%</div>'
      +'<div style="font-size:11px;color:#888;font-family:monospace;min-width:46px;text-align:right">'+w.v+' '+w.u+'</div>'
      +'</div>';
  }).join('');
  var html='<div style="width:360px;background:#17181a;border-radius:22px;overflow:hidden;font-family:system-ui,sans-serif">'
    +'<div style="background:linear-gradient(160deg,#1e2022 0%,#17181a 100%);padding:24px 22px 20px">'
    +'<div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:20px">'
    +'<div><div style="font-size:10px;letter-spacing:2.5px;color:#4a4540;margin-bottom:4px;text-transform:uppercase">Coffee Master</div>'
    +'<div style="font-size:18px;font-weight:700;color:#f0ebe4">'+dateLabel+'</div></div>'
    +'<div style="text-align:right">'
    +'<div style="font-size:9px;color:#4a4540;letter-spacing:1.5px;text-transform:uppercase;margin-bottom:2px">Всього</div>'
    +'<div style="font-size:28px;font-weight:800;color:#d89858;line-height:1">'+totKgW.v+'</div>'
    +'<div style="font-size:10px;color:#8a6030;font-weight:600;margin-top:1px">'+totKgW.u+' зерна</div>'
    +'</div></div>'
    +'<div style="display:flex;align-items:center;gap:18px">'
    +'<div style="position:relative;width:156px;height:156px;flex-shrink:0">'
    +'<svg viewBox="0 0 300 300" width="156" height="156">'+ringHTML+'</svg>'
    +'<div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center">'
    +'<div style="font-family:monospace;font-size:26px;font-weight:800;color:#f0ebe4;line-height:1">'+totKgW.v+'</div>'
    +'<div style="font-size:10px;letter-spacing:2px;color:#5a5550;margin-top:4px;text-transform:uppercase">'+totKgW.u+'</div>'
    +'</div></div>'
    +'<div style="flex:1">'+legendHTML+'</div>'
    +'</div></div>'
    +'<div style="padding:16px 22px 20px;display:grid;grid-template-columns:1fr 1fr;gap:8px;border-top:1px solid #202224">'
    +'<div style="background:#1c1e22;border-radius:11px;padding:12px 14px"><div style="font-size:8px;color:#3a3835;letter-spacing:1.5px;text-transform:uppercase;margin-bottom:5px">Заварювань</div><div style="font-size:24px;font-weight:700;color:#f0ebe4">'+d.brewCount+'</div></div>'
    +'<div style="background:#1c1e22;border-radius:11px;padding:12px 14px"><div style="font-size:8px;color:#3a3835;letter-spacing:1.5px;text-transform:uppercase;margin-bottom:5px">Фаворит</div><div style="font-size:14px;font-weight:700;color:#f0ebe4;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">'+d.favMethod+'</div></div>'
    +(d.cafeCount>0?'<div style="background:#1c1e22;border-radius:11px;padding:12px 14px"><div style="font-size:8px;color:#3a3835;letter-spacing:1.5px;text-transform:uppercase;margin-bottom:5px">В кав\u2019ярні</div><div style="font-size:24px;font-weight:700;color:#f0ebe4">'+d.cafeCount+'</div></div>':'')
    +'<div style="background:#1c1e22;border-radius:11px;padding:12px 14px"><div style="font-size:8px;color:#3a3835;letter-spacing:1.5px;text-transform:uppercase;margin-bottom:5px">Серед. доза</div><div style="font-size:22px;font-weight:700;color:#f0ebe4">'+d.avgDose+'<span style="font-size:11px;color:#444;font-weight:400"> г</span></div></div>'
    +'</div>'
    +'<div style="text-align:center;padding-bottom:14px;font-size:8px;color:#242220;letter-spacing:2.5px;text-transform:uppercase">Зварено в Coffee Master</div>'
    +'</div>';
  var wrap=document.createElement('div');
  wrap.style.cssText='position:fixed;left:-9999px;top:0;z-index:-1';
  wrap.innerHTML=html;
  document.body.appendChild(wrap);
  if(typeof html2canvas!=='function'){toast('Шеринг недоступний');wrap.remove();return;}
  toast('Готуємо картку...');
  html2canvas(wrap.firstChild,{scale:2,backgroundColor:'#17181a',logging:false}).then(function(canvas){
    wrap.remove();
    canvas.toBlob(function(blob){
      var url=URL.createObjectURL(blob);
      if(navigator.share&&navigator.canShare&&navigator.canShare({files:[new File([blob],'coffee-stats.png',{type:'image/png'})]})){
        navigator.share({files:[new File([blob],'coffee-stats.png',{type:'image/png'})],title:'Coffee Stats'}).catch(function(){});
      } else {var a=document.createElement('a');a.href=url;a.download='coffee-stats.png';a.click();}
      setTimeout(function(){URL.revokeObjectURL(url);},5000);
    },'image/png');
  }).catch(function(e){wrap.remove();toast('Помилка шерингу');console.log(e);});
}


function cwApply(){
  var r=CW_ROASTS[cwi]; if(!r)return;
  var p=cwWeight(r.kg);
  document.getElementById('cw-lbl').textContent=r.label;
  var v=document.getElementById('cw-val');v.textContent=p.v;v.style.color=r.color||'var(--txt)';
  document.getElementById('cw-unit').textContent=p.u;
  document.getElementById('cw-legend').classList.toggle('all',!r.seg);
  ['filter','espresso','omni'].forEach(function(k){
    var seg=document.getElementById('cw-seg-'+k), row=document.getElementById('cw-row-'+k);
    var active=!r.seg||r.seg===k, sel=!!r.seg&&r.seg===k, dim=!!r.seg&&r.seg!==k;
    if(seg)seg.style.opacity=active?'1':'.16';
    if(row){row.style.opacity=dim?'.32':'1';row.style.background=sel?cwHx(CW_SEGC[k],.16):'transparent';row.style.borderColor=sel?cwHx(CW_SEGC[k],.55):'transparent';}
  });
  document.querySelectorAll('#cw-dots span').forEach(function(d,i){d.classList.toggle('on',i===cwi);});
}
