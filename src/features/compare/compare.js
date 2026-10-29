/* ── COMPARE: toggle brew selection ── */
var CP_SELECTED=[];
function cpToggleBrew(id){
  var b=S.brews.find(function(x){return x.id===id;});
  if(!b)return;
  var idx=CP_SELECTED.findIndex(function(x){return x.id===id;});
  var btn=document.getElementById('cp-btn-'+id);
  if(idx>=0){
    CP_SELECTED.splice(idx,1);
    if(btn)btn.style.color='';
  } else {
    if(CP_SELECTED.length>=4){toast('Максимум 4 рецепти');return;}
    CP_SELECTED.push(b);
    if(btn)btn.style.color='var(--copper-lt)';
  }
  var fab=document.getElementById('cp-fab');
  var cnt=document.getElementById('cp-fab-count');
  if(fab)fab.style.display=CP_SELECTED.length>=2?'block':'none';
  if(cnt)cnt.textContent=CP_SELECTED.length;
}
function cpResetSelection(){
  CP_SELECTED=[];
  document.querySelectorAll('[id^="cp-btn-"]').forEach(function(b){b.style.color='';});
  var fab=document.getElementById('cp-fab');
  if(fab)fab.style.display='none';
  var cnt=document.getElementById('cp-fab-count');
  if(cnt)cnt.textContent='0';
  /* Якщо вже в екрані порівняння — повертаємо в журнал і скидаємо */
  var activeScr=document.querySelector('.scr.on');
  if(activeScr&&activeScr.id==='scr-compare'){
    renderCompare();
    showScr('scr-home');
  }
}

/* ─────────── ПОРІВНЯННЯ ─────────── */
/* демо-дані — заміни на обрані рецепти */
var CP_RECIPES=[];
var BLUE='#5da3dd',ORANGE='#EFA23F';
var cpUnitMode='sec',cpSel=null;
function cpTotal(r){return r.steps.reduce(function(s,x){return s+x.sec},0)}
function cpMaxTotal(){return Math.max.apply(null,CP_RECIPES.map(cpTotal))}
function cpFmtTime(s){return Math.floor(s/60)+':'+('0'+(s%60)).slice(-2)}
var CP_COLORS=['#E8955C','#7fb08a','#c9a86a','#8198AE'];

/* Колір сегмента за типом дії (як у сценарії заварювання):
   влив=синій, пауза=помаранчевий, дія(перемішування/свьорл/шейк/продавлювання)=власний колір кроку. */
function cpStepColor(st){
  if(st.type==='pour')return BLUE;
  if(st.type==='pause')return ORANGE;
  return st.color||'#7c5cbf';
}
/* Освітлити(+)/затемнити(−) hex-колір, amt ∈ [-1..1] */
function cpShade(hex,amt){
  var m=/^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex||'');if(!m)return hex;
  var ch=[parseInt(m[1],16),parseInt(m[2],16),parseInt(m[3],16)];
  return '#'+ch.map(function(c){c=Math.round(amt>0?c+(255-c)*amt:c*(1+amt));return('0'+Math.max(0,Math.min(255,c)).toString(16)).slice(-2);}).join('');
}

/* Converts a real brew from S.brews into the CP format */
function cpBrewToRecipe(b,idx){
  var d=new Date(b.ts||Date.now());
  var pad=function(n){return(n<10?'0':'')+n;};
  var dateStr=pad(d.getDate())+'.'+pad(d.getMonth()+1);
  var dose=parseFloat(b.dose)||16;
  var ratio=parseFloat(b.ratio)||16;
  var gradeColor=b.rating>=8?'#5fbf83':b.rating>=6.5?'#b9c64f':b.rating>=5?'#e2c64c':'#ea6a52';
  /* Convert steps array */
  var steps=(b.steps||[]).map(function(s){
    if(s.type==='pour')return{type:'pour',sec:Math.round((s.ph||0)/1000),ml:Math.round(s.ml||0)};
    if(s.type==='pause')return{type:'pause',sec:Math.round((s.ph||0)/1000)};
    if(s.type==='action')return{type:'action',sec:(s.dur||Math.round((s.ph||0)/1000)||1),color:s.color||'#7c5cbf',label:s.label||''};
    return null;
  }).filter(Boolean);
  /* Fallback for espresso (no steps) */
  if(!steps.length && b.espresso){
    steps=[{type:'pour',sec:b.espresso.shotTime||25,ml:Math.round(b.espresso.actualYield||b.espresso.targetYield||36)}];
  }
  return{
    name:b.beanName||'Без назви',
    date:dateStr,
    color:CP_COLORS[idx%4],
    grade:parseFloat(b.rating)||0,
    gradeColor:gradeColor,
    dose:dose,
    ratioStr:'1:'+ratio,
    temp:parseFloat(b.temp)||93,
    grind:b.clicks||0,
    water:Math.round(dose*ratio),
    method:b.method||'',
    device:((typeof liveDeviceName==='function'?liveDeviceName(b.dripperId,b.dripper):'')||b.dripper||b.device||''),
    steps:steps
  };
}

function renderCompare(){
  /* Build CP_RECIPES from user-selected brews */
  CP_RECIPES=CP_SELECTED.map(function(b,i){return cpBrewToRecipe(b,i);});
  var n=CP_RECIPES.length;
  var nEl=document.getElementById('cp-n');
  var cntEl=document.getElementById('cp-count');
  if(nEl)nEl.textContent=n+'/5';
  if(cntEl)cntEl.textContent=n>0?(n+' рецепт'+(n===1?'':'и')):'оберіть рецепти ⚖';
  if(n===0){
    /* Empty state */
    ['cp-tl-list','cp-param-grid','cp-rg-list','cp-cv-list'].forEach(function(id){
      var el=document.getElementById(id);
      if(el)el.innerHTML='<div style="text-align:center;padding:24px;color:#555;font-size:13px">Оберіть рецепти в журналі за допомогою ⚖</div>';
    });
    return;
  }
  cpRenderTimelines();cpRenderParams();cpRenderRings();cpRenderCurve();cpRenderLists();cpApplySel();
}
function cpShort(r){return r.date}
/* — таймлайни — */
/* Таблиця кроків рецепта у стилі стрічки (без діаграми) — для розкривної деталізації в таймлайні */
function cpStepTableHTML(b){
  var steps=(b&&b.steps||[]).filter(function(s){return s.type==='pour'||s.type==='pause'||s.type==='action';});
  if(!steps.length)return '<div style="font-size:12px;color:var(--txt3);padding:8px 2px">'+t('journal_no_log')+'</div>';
  var fR=function(ms){var s=Math.floor((ms||0)/1000),m=Math.floor(s/60),sc=s%60;return(m<10?'0':'')+m+':'+(sc<10?'0':'')+sc;};
  return steps.map(function(st){
    var t0=st.t||0,stE=t0+(st.ph!=null?st.ph:(st.dur||0)*1000);
    var rng=fR(t0)+'–'+fR(stE);
    var ds=Math.round((st.ph!=null?st.ph:(st.dur||0)*1000)/1000);
    if(st.type==='action'){var ac=st.color||'#5fbf83';
      return '<div class="bc-log-row"><span class="bc-log-badge action" style="background:'+ac+'20;color:'+ac+';border-color:'+ac+'40">'+(st.label||'Дія')+'</span><span class="bc-log-t" style="font-size:10px;min-width:88px">'+rng+'</span><span class="bc-log-ph">'+ds+'с</span></div>';}
    return '<div class="bc-log-row"><span class="bc-log-badge '+(st.type==='pour'?'pour':'pause')+'">'+(st.type==='pour'?t('brew_pour'):t('brew_pause'))+'</span><span class="bc-log-t" style="font-size:10px;min-width:88px">'+rng+'</span><span class="bc-log-ph">'+ds+'с</span>'+(st.ml!=null?'<span class="bc-log-ml">'+(+st.ml).toFixed(1)+'мл</span>':'')+'</div>';
  }).join('');
}
/* Акордеон розкриття таблиці кроків під рецептом — тільки в таймлайні (перша вкладка) */
function cpTlPick(i){
  var det=document.getElementById('cp-tl-det-'+i);
  var isOpen=det&&det.classList.contains('open');
  document.querySelectorAll('#cp-tl-list .cp-tl-detail.open').forEach(function(d){d.classList.remove('open');});
  document.querySelectorAll('#cp-tl-list .cp-card.cp-open').forEach(function(c){c.classList.remove('cp-open');});
  if(!isOpen&&det){det.classList.add('open');var card=det.parentElement;while(card&&!(card.classList&&card.classList.contains('cp-card')))card=card.parentElement;if(card)card.classList.add('cp-open');}
}
function cpRenderTimelines(){
  var html='';
  CP_RECIPES.forEach(function(r,i){
    var total=cpTotal(r)||1,acc=0,bars='';
    r.steps.forEach(function(st){
      var left=acc/total*100,w=st.sec/total*100;acc+=st.sec;
      var col=cpStepColor(st);
      var bg='linear-gradient(180deg,'+cpShade(col,.22)+','+cpShade(col,-.14)+')';
      var txt=cpUnitMode==='ml'?(st.type==='pour'?st.ml:''):st.sec;
      var op=(cpUnitMode==='ml'&&st.type!=='pour')?';opacity:.5':'';
      bars+='<i style="left:'+left.toFixed(2)+'%;width:'+w.toFixed(2)+'%;background:'+bg+';color:'+cpShade(col,-.6)+op+'">'+txt+'</i>';
    });
    /* власна вісь під кожним рецептом: 0:00 … total з кроком 30с */
    var ax='<span style="left:0">'+cpFmtTime(0)+'</span>';
    for(var tk=30;tk<total;tk+=30){var p=tk/total*100;if(100-p<12)continue;ax+='<span style="left:'+p.toFixed(2)+'%;transform:translateX(-50%)">'+cpFmtTime(tk)+'</span>';}
    ax+='<span style="left:100%;transform:translateX(-100%)">'+cpFmtTime(total)+'</span>';
    html+='<div class="cp-card" data-r="'+i+'" onclick="cpTlPick('+i+')" style="padding:14px 14px 12px;margin-bottom:10px">'
      +'<div class="cp-rname" style="margin-bottom:8px"><span class="cp-dot" style="background:'+r.color+'"></span>'+r.name+' · '+r.date
      +'<span class="cp-rmeta">'+r.dose+'г · '+cpFmtTime(total)+' · '+r.temp+'°</span>'
      +'<span class="cp-grade" style="color:'+r.gradeColor+'">'+r.grade.toFixed(1)+'</span></div>'
      +'<div class="cp-tl">'+bars+'</div>'
      +'<div class="cp-tl-ax">'+ax+'</div>'
      +'<div class="cp-tl-detail" id="cp-tl-det-'+i+'"><div class="cp-tl-detail-inner">'+cpStepTableHTML(CP_SELECTED[i])+'</div></div>'
      +'</div>';
  });
  document.getElementById('cp-tl-list').innerHTML=html;
  var axg=document.getElementById('cp-tl-axis');if(axg)axg.innerHTML=''; /* глобальна вісь більше не потрібна — у кожного своя */
}
function cpRenderParams(){
  var rows=[['Доза',function(r){return r.dose}],['Коефіцієнт',function(r){return r.ratioStr}],['Вода',function(r){return r.water}],
    ['Темп.',function(r){return r.temp+'°'}],['Метод',function(r){return r.method||'—'},'text'],['Девайс',function(r){return r.device||'—'},'text'],['Помел',function(r){return r.grind}],
    ['Час',function(r){return cpFmtTime(cpTotal(r))}],['1-й влив',function(r){var p=r.steps.filter(function(s){return s.type==='pour'})[0];return p?p.ml:'—'}]];
  var cols=CP_RECIPES.length;
  var h='<div style="display:grid;grid-template-columns:1fr repeat('+cols+',1fr);gap:7px 6px">';
  h+='<span class="cp-lbl"></span>'+CP_RECIPES.map(function(r){return '<span class="cp-lbl" style="text-align:right;color:'+r.color+'">'+r.date+'</span>'}).join('');
  rows.forEach(function(row){
    var vals=CP_RECIPES.map(row[1]),same=vals.every(function(v){return v===vals[0]}),isText=row[2]==='text';
    h+='<span style="color:#a3927f">'+row[0]+'</span>';
    CP_RECIPES.forEach(function(r,i){
      var diff=!same&&vals.filter(function(v){return v===vals[i]}).length===1;
      var st='text-align:right'+(diff?';color:#EFA23F':'')+(isText?';font-size:10px;font-weight:600;white-space:normal;word-break:break-word;line-height:1.25':'');
      h+='<b class="cp-mono" style="'+st+'">'+vals[i]+'</b>';
    });
  });
  h+='</div>';document.getElementById('cp-params').innerHTML=h;
}
/* — кільця — */
function cpRenderRings(){
  var n=CP_RECIPES.length;
  var pitch=n>=5?21:22, sw=n>=5?13:17;
  var radii=[];for(var k=0;k<n;k++)radii.push(118-k*pitch);
  var svg='';
  CP_RECIPES.forEach(function(r,i){
    var R=radii[i],total=cpTotal(r)||1,acc=0;
    svg+='<g data-r="'+i+'"><circle cx="140" cy="140" r="'+R+'" stroke="#181512"/>';
    r.steps.forEach(function(st){
      var col=cpStepColor(st),gap=total-st.sec;
      svg+='<circle cx="140" cy="140" r="'+R+'" pathLength="'+total+'" stroke="'+col+'" stroke-dasharray="'+st.sec+' '+gap+'" stroke-dashoffset="'+(-acc)+'"/>';
      acc+=st.sec;
    });
    svg+='</g>';
  });
  var maxT=cpMaxTotal(),cf=n>=4?24:28;
  var full='<g transform="rotate(-90 140 140)" fill="none" stroke-width="'+sw+'">'+svg+'</g>'
    +'<text x="140" y="135" text-anchor="middle" fill="#EDE7DD" font-family="system-ui,-apple-system,sans-serif" font-size="'+cf+'" font-weight="800" letter-spacing="-.5">'+cpFmtTime(maxT)+'</text>'
    +'<text x="140" y="155" text-anchor="middle" fill="#8a7e6a" font-family="system-ui,-apple-system,sans-serif" font-size="10" font-weight="600" letter-spacing="3">ЧАС</text>';
  document.getElementById('cp-rings').innerHTML=full;
}
/* — крива води — */
function cpRenderCurve(){
  var maxT=cpMaxTotal(),maxMl=Math.max.apply(null,CP_RECIPES.map(function(r){return r.water}));
  var X0=34,X1=332,Y0=210,Y1=10;
  function px(t){return X0+(t/maxT)*(X1-X0)}
  function py(ml){return Y0-(ml/maxMl)*(Y0-Y1)}
  var g='<line x1="34" y1="10" x2="34" y2="210" stroke="#2c2721"/><line x1="34" y1="210" x2="332" y2="210" stroke="#2c2721"/>';
  g+='<line x1="34" y1="'+py(maxMl).toFixed(0)+'" x2="332" y2="'+py(maxMl).toFixed(0)+'" stroke="#221e19" stroke-dasharray="3 4"/>';
  g+='<line x1="34" y1="'+py(maxMl/2).toFixed(0)+'" x2="332" y2="'+py(maxMl/2).toFixed(0)+'" stroke="#221e19" stroke-dasharray="3 4"/>';
  g+='<text x="28" y="'+(py(maxMl)+4).toFixed(0)+'" text-anchor="end" fill="#5d5347" font-family="JetBrains Mono" font-size="8">'+Math.round(maxMl)+'</text>';
  g+='<text x="28" y="214" text-anchor="end" fill="#5d5347" font-family="JetBrains Mono" font-size="8">0</text>';
  g+='<text x="34" y="228" fill="#5d5347" font-family="JetBrains Mono" font-size="8">0:00</text><text x="'+px(maxT).toFixed(0)+'" y="228" text-anchor="end" fill="#5d5347" font-family="JetBrains Mono" font-size="8">'+cpFmtTime(maxT)+'</text>';
  var caps='';
  CP_RECIPES.forEach(function(r,i){
    var t=0,ml=0,d='M'+px(0)+' '+py(0),mk='';
    r.steps.forEach(function(st){
      if(st.type==='pour'){var t2=t+st.sec;ml+=st.ml;d+=' L'+px(t2).toFixed(1)+' '+py(ml).toFixed(1);t=t2;}
      else{var t3=t+st.sec;
        if(st.type==='action'){var mx=px(t+st.sec/2),my=py(ml);mk+='<circle data-r="'+i+'" cx="'+mx.toFixed(1)+'" cy="'+my.toFixed(1)+'" r="3.4" fill="'+(st.color||'#7c5cbf')+'" stroke="#17181a" stroke-width="1.3"/>';}
        d+=' L'+px(t3).toFixed(1)+' '+py(ml).toFixed(1);t=t3;}
    });
    g+='<path data-r="'+i+'" d="'+d+'" fill="none" stroke="'+r.color+'" stroke-width="2.5" stroke-linejoin="round"/>';
    caps+=mk+'<circle data-r="'+i+'" cx="'+px(t).toFixed(1)+'" cy="'+py(ml).toFixed(1)+'" r="4" fill="'+r.color+'"/>';
  });
  document.getElementById('cp-curve').innerHTML=g+caps;
}
/* — списки-легенди під графіками — */
function cpRenderLists(){
  function ringLbl(i){return (i+1)+' кільце'}
  function card(r,i,meta){return '<div class="cp-card" data-r="'+i+'" onclick="cpPick('+i+')" style="padding:12px 14px;margin-bottom:8px">'
    +'<div class="cp-rname"><span class="cp-dot" style="background:'+r.color+'"></span>'+r.name.split(' ').slice(0,2).join(' ')+' · '+r.date
    +'<span class="cp-rmeta">'+meta+'</span><span class="cp-grade" style="color:'+r.gradeColor+'">'+r.grade.toFixed(1)+'</span></div></div>'}
  document.getElementById('cp-rg-list').innerHTML=CP_RECIPES.map(function(r,i){return card(r,i,ringLbl(i))}).join('');
  document.getElementById('cp-cv-list').innerHTML=CP_RECIPES.map(function(r,i){return card(r,i,r.water+' мл · '+cpFmtTime(cpTotal(r)))}).join('');
}
/* — перемикачі — */
function cpView(v,btn){document.querySelectorAll('#cp-view-seg button').forEach(function(b){b.classList.remove('on')});btn.classList.add('on');
  ['tl','rg','cv'].forEach(function(k){document.getElementById('cp-view-'+k).classList.toggle('on',k===v)})}
function cpUnit(m,btn){cpUnitMode=m;document.querySelectorAll('#cp-unit-seg button').forEach(function(b){b.classList.remove('on')});btn.classList.add('on');cpRenderTimelines();cpApplySel()}
function cpPick(idx){cpSel=cpSel===idx?null:idx;cpApplySel()}
function cpApplySel(){
  document.querySelectorAll('#scr-compare [data-r]').forEach(function(el){
    var r=el.getAttribute('data-r'),on=cpSel===null||String(cpSel)===r;
    el.classList.toggle('cp-faded',!on);
    if(el.classList.contains('cp-card'))el.classList.toggle('cp-sel',cpSel!==null&&String(cpSel)===r);
  });
}

/* ── Поділитись порівнянням: одна картка з усіма 3 вкладками (Таймлайн / Кільця / Крива) ──
   Клонуємо вже відрендерені view (renderCompare рендерить усі три одразу), тому вкладки
   на екрані лишаються без змін. Замороженi shareRecipe/buildShareHTML не чіпаємо. */
/* Клон однієї вкладки порівняння з прибраними рамками/фокусом (спільний для 3-картинкового і об'єднаного режимів) */
/* Реальний максимум сторони canvas у пристрої (у сучасних iPhone 8192, старіші 4096).
   Визначаємо один раз: малюємо білий піксель у найнижчому рядку і перевіряємо, чи він відрендерився. */
var _cpMaxEdge=0;
function cpMaxCanvasEdge(){
  if(_cpMaxEdge)return _cpMaxEdge;
  var cands=[16384,8192,4096,2048],edge=2048;
  for(var i=0;i<cands.length;i++){var s=cands[i];try{
    var c=document.createElement('canvas');c.width=4;c.height=s;var x=c.getContext('2d');if(!x)continue;
    x.fillStyle='#fff';x.fillRect(0,s-3,4,3);var d=x.getImageData(1,s-1,1,1).data;
    if(d[0]>200){edge=s;break;}
  }catch(e){}}
  _cpMaxEdge=edge;return edge;
}
function _cpClone(k){
  var src=document.getElementById('cp-view-'+k);if(!src)return null;
  var clone=src.cloneNode(true);
  var us=clone.querySelector('#cp-unit-seg');if(us)us.remove();
  clone.classList.add('on');clone.style.display='block';
  clone.querySelectorAll('.cp-faded').forEach(function(el){el.classList.remove('cp-faded');});
  clone.querySelectorAll('.cp-sel').forEach(function(el){el.classList.remove('cp-sel');});
  clone.querySelectorAll('.cp-card').forEach(function(el){el.style.border='none';el.style.boxShadow='none';});
  /* html2canvas спотворює inset-тіні барів (біла inset-підсвітка розтікається і вибілює колір).
     Прибираємо тіні й задаємо трохи глибші градієнти, щоб у шерингу кольори були насичені, як у застосунку. */
  clone.querySelectorAll('.cp-tl').forEach(function(el){el.style.boxShadow='none';});
  clone.querySelectorAll('.cp-tl .pour').forEach(function(el){el.style.boxShadow='none';el.style.background='linear-gradient(180deg,#6db0ea,#3a7dbd)';});
  clone.querySelectorAll('.cp-tl .pause').forEach(function(el){el.style.boxShadow='none';el.style.background='linear-gradient(180deg,#f2a740,#cf7a1b)';});
  clone.querySelectorAll('[id]').forEach(function(el){el.removeAttribute('id');});clone.removeAttribute('id');
  return clone;
}
function cpShare(){
  if(!CP_RECIPES||!CP_RECIPES.length){toast('Оберіть рецепти для порівняння');return;}
  if(typeof html2canvas!=='function'){toast('Шеринг недоступний');return;}
  var titles={tl:'Таймлайн',rg:'Кільця',cv:'Крива'};
  var order=['tl','rg','cv'];
  var n=CP_RECIPES.length;
  var _ms=CP_RECIPES.map(function(r){return r.method;});
  var method=_ms.every(function(m){return m===_ms[0];})?(_ms[0]||''):'';
  var meta=n+' рецепт'+(n===1?'':'и')+(method?' · '+method:'');
  function headHTML(sub){return '<div style="background:linear-gradient(160deg,#1e2022 0%,#17181a 100%);padding:20px 18px 16px">'
    +'<div style="font-size:10px;letter-spacing:2px;color:#5a5550;margin-bottom:4px">COFFEE MASTER</div>'
    +'<div style="display:flex;justify-content:space-between;align-items:baseline">'
    +'<div style="font-size:18px;font-weight:700;color:#f0ebe4">'+sub+'</div>'
    +'<div style="font-size:11px;color:#c8a050;font-weight:700;white-space:nowrap">'+meta+'</div></div></div>';}
  var footHTML='<div style="padding:10px 18px 4px;text-align:center;font-size:8px;color:#2e2c2a;letter-spacing:2px">ЗВАРЕНО В COFFEE MASTER</div>';
  var cardCss='width:360px;background:#17181a;font-family:system-ui,sans-serif;color:#EDE7DD;box-sizing:border-box;padding-bottom:6px';

  /* Чи вміє платформа шерити КІЛЬКА файлів (Telegram-webview часто — ні). Пробуємо на порожніх файлах. */
  function dummy(nm){return new File([new Blob(['x'],{type:'image/png'})],nm,{type:'image/png'});}
  var canShareApi=!!(navigator.share&&navigator.canShare);
  var canMulti=false;try{canMulti=canShareApi&&navigator.canShare({files:[dummy('a.png'),dummy('b.png'),dummy('c.png')]});}catch(e){canMulti=false;}

  var wrap=document.createElement('div');wrap.style.cssText='position:fixed;left:-9999px;top:0;z-index:-1';document.body.appendChild(wrap);
  function toFile(cv,nm){return new Promise(function(res){cv.toBlob(function(bl){res(new File([bl],nm,{type:'image/png'}));},'image/png');});}
  /* послідовний рендер (паралельний html2canvas ненадійний на мобільних).
     scale підвищено для чіткості (мутність у Telegram = замалий рендер), але висоту*scale тримаємо <= ~4000px,
     інакше iOS/Safari дає порожнє полотно (ліміт розміру canvas). */
  /* Максимальна чіткість у межах ліміту canvas пристрою (обидві сторони).
     cap — стеля scale (щоб не роздувати пам'ять); реальний scale тягнемо якомога вище → щонайменше ~2K по ширині. */
  function renderSeq(nodes,cap){var edge=cpMaxCanvasEdge(),lim=edge-96;var out=[];var p=Promise.resolve();nodes.forEach(function(el){p=p.then(function(){var r=el.getBoundingClientRect(),wcss=r.width||360,hcss=(r.height||el.offsetHeight||600);var sc=Math.min(cap,lim/Math.max(1,wcss),lim/Math.max(1,hcss));if(sc<1)sc=1;return html2canvas(el,{scale:sc,backgroundColor:'#17181a',logging:false});}).then(function(cv){out.push(cv);});});return p.then(function(){return out;});}

  if(canMulti){
    /* ── 3 окремі картинки ── */
    toast('Готуємо 3 картки...');
    var metaCards=order.map(function(k){
      var cl=_cpClone(k);if(!cl)return null;
      var card=document.createElement('div');card.style.cssText=cardCss;
      card.innerHTML=headHTML('Порівняння · '+titles[k]);
      var body=document.createElement('div');body.style.cssText='padding:16px 18px 0';body.appendChild(cl);card.appendChild(body);
      card.insertAdjacentHTML('beforeend',footHTML);wrap.appendChild(card);
      return {card:card,k:k};
    }).filter(Boolean);
    renderSeq(metaCards.map(function(x){return x.card;}),6).then(function(cvs){
      return Promise.all(cvs.map(function(cv,i){return toFile(cv,'compare_'+(i+1)+'_'+metaCards[i].k+'.png');}));
    }).then(function(files){
      wrap.remove();
      navigator.share({files:files,title:'Порівняння · Coffee Master'}).catch(function(err){console.log('[cpShare] share cancelled/err',err&&err.name);});
    }).catch(function(e){wrap.remove();toast('Помилка шерингу');console.log('[cpShare multi]',e);});
  } else {
    /* ── одна картинка з усіма 3 вкладками (мультифайл недоступний / нема Web Share) ── */
    toast('Готуємо картку...');
    var card=document.createElement('div');card.style.cssText=cardCss;
    card.innerHTML=headHTML('Порівняння');
    order.forEach(function(k){
      var cl=_cpClone(k);if(!cl)return;
      var sec=document.createElement('div');sec.style.cssText='padding:14px 18px 0';
      sec.innerHTML='<div style="font-size:10px;letter-spacing:1.5px;color:#8a7e6e;text-transform:uppercase;margin-bottom:10px">'+titles[k]+'</div>';
      sec.appendChild(cl);card.appendChild(sec);
    });
    card.insertAdjacentHTML('beforeend',footHTML);wrap.appendChild(card);
    renderSeq([card],5).then(function(cvs){return toFile(cvs[0],'comparison.png');}).then(function(file){
      wrap.remove();
      if(canShareApi&&navigator.canShare({files:[file]})){
        navigator.share({files:[file],title:'Порівняння · Coffee Master'}).catch(function(err){console.log('[cpShare] share cancelled/err',err&&err.name);});
      } else {
        var url=URL.createObjectURL(file);var a=document.createElement('a');a.href=url;a.download='comparison.png';a.click();
        setTimeout(function(){URL.revokeObjectURL(url);},4000);toast('Картинку збережено');
      }
    }).catch(function(e){wrap.remove();toast('Помилка шерингу');console.log('[cpShare single]',e);});
  }
}
