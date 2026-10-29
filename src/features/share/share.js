/* ── SHARE ── */
function shareRecipe(bid){
  var b=S.brews.find(function(x){return x.id===bid;});
  if(!b)return;

  /* Будуємо HTML двох карток і рендеримо через html2canvas */
  var wrap=document.createElement('div');
  wrap.style.cssText='position:fixed;left:-9999px;top:0;z-index:-1;display:flex;gap:0;background:transparent;border:none;outline:none;box-shadow:none';
  try{
    wrap.innerHTML=buildShareHTML(b);
  }catch(e){
    console.log('[shareRecipe] buildShareHTML error:', e.message, 'brew id:', bid, 'method:', b.method, 'has steps:', !!(b.steps&&b.steps.length), 'has espresso:', !!b.espresso);
    toast('Не вдалось підготувати картку — деталі в консолі');
    return;
  }
  document.body.appendChild(wrap);

  var slides=wrap.querySelectorAll('.sc');
  var promises=Array.from(slides).map(function(el){
    return html2canvas(el,{
      scale:2,useCORS:true,allowTaint:true,
      backgroundColor:null,logging:false,
      width:540,
      height:el.scrollHeight||960,
      windowWidth:540
    });
  });

  Promise.all(promises).then(function(canvases){
    document.body.removeChild(wrap);
    var files=canvases.map(function(c,i){
      return new Promise(function(res){
        c.toBlob(function(bl){res(new File([bl],'recipe_'+(i+1)+'.png',{type:'image/png'}));});
      });
    });
    Promise.all(files).then(function(fArr){
      var title=(b.beanName||'Кава')+' · '+parseFloat(b.rating||0).toFixed(1);
      var text='☕ '+title+'\nCoffee Master';
      if(navigator.share&&navigator.canShare&&navigator.canShare({files:fArr})){
        navigator.share({title:title,text:text,files:fArr}).catch(function(){});
      } else if(navigator.share){
        navigator.share({title:title,text:text}).catch(function(){});
      } else {
        canvases[0].toBlob(function(bl){
          var url=URL.createObjectURL(bl);
          var a=document.createElement('a');a.href=url;a.download='recipe.png';a.click();
          setTimeout(function(){URL.revokeObjectURL(url);},2000);
        });
        toast('Картинку збережено');
      }
    });
  }).catch(function(e){
    document.body.removeChild(wrap);
    console.error('html2canvas error',e);
    toast('Помилка генерації');
  });
}

function buildShareHTML(b){
  var rating=parseFloat(b.rating||0);
  var ratingColor=rating>=9?'#5fbf83':rating>=7?'#d89858':rating>=5?'#c7a93e':rating>=3?'#e09030':'#e05252';
  /* Grade by score */
  var gradeClass=rating>=8.0?'g-green':rating>=6.5?'g-lime':rating>=5.0?'g-yellow':rating>=3.5?'g-orange':'g-red';
  var gradeInk  =rating>=8.0?'#5fbf83':rating>=6.5?'#b9c64f':rating>=5.0?'#e2c64c':rating>=3.5?'#ea9b3c':'#ea6a52';

  /* Slide 2 glow override (blue — steps diagram) */
  var glowSlide2='radial-gradient(56% 52% at 100% 0%,rgba(63,143,214,.32),transparent 66%)';
  var method=b.method||'Альтернатива';
  var _liveBean=liveBeanInfo(b.beanId, b.beanName, b.roaster);
  var beanName=_liveBean.name||t('journal_no_name');
  var roaster=_liveBean.roaster||'';
  var dose=b.dose||'—';
  var totalMl=b.steps?b.steps.reduce(function(s,st){return s+(st.ml||0);},0):0;
  if(!totalMl&&b.espresso)totalMl=b.espresso.actualYield||b.espresso.targetYield||0;
  var ratio=b.ratio?'1:'+b.ratio:'—';
  var temp=b.temp?b.temp+'°':'—';
  var time=b.totalTime||'—';
  var clicks=b.clicks?b.clicks+' кл.':'—';

  /* Девайси */
  function devRow(icon,role,name,sub){
    if(!name)return'';
    return'<div class="sc-dev">'+
      '<span class="sc-dev-ic"><i class="ti '+icon+'"></i></span>'+
      '<div class="sc-dev-tx">'+
        '<div class="sc-dev-role">'+role+'</div>'+
        '<div class="sc-dev-name">'+name+'</div>'+
      '</div>'+
      (sub?'<span class="sc-dev-sub">'+sub+'</span>':'')+
    '</div>';
  }
  var devs=devRow('ti-filter','Воронка',liveDeviceName(b.dripperId,b.dripper),'')
          +devRow('ti-layers-subtract','Фільтр',liveDeviceName(b.filterId,b.filter),'')
          +devRow('ti-coffee','Кавомашина',liveDeviceName(b.espMachineId,b.espMachine),'')
          +devRow('ti-settings','Кавомолка',liveDeviceName(b.grinderId,b.grinder),b.clicks?b.clicks+' кл.':'');

  /* Pill color fallback palette by category keyword */
  var PILL_FALLBACKS={'фрукт':'#c84a6e','ягід':'#b03060','цитрус':'#d4891a','солод':'#d98b3a','шоколад':'#8a6a44','горіх':'#9a7040','карамел':'#c8903a','ваніл':'#c8a050','квіт':'#b25b86','трав':'#5a9e57','спец':'#b5453a','кислин':'#c7a93e','тютюн':'#9c5a3c','земл':'#7a6040','дерев':'#7a6040','чорн':'#6d56a6','лакриц':'#7d4a8e','мигдал':'#9a7040','темн':'#7a5030'};
  function pillColor(name){
    name=String(name||'');
    var c=noteColorByName(name);
    if(c)return c;
    var low=name.toLowerCase();
    for(var k in PILL_FALLBACKS){if(low.includes(k))return PILL_FALLBACKS[k];}
    return'#7d8893';
  }
  function pillsHTML(tags){
    if(!tags||!tags.length)return'';
    return tags.map(function(f){
      return'<span class="sc-pill" style="background:'+pillColor(f)+'">'+f+'</span>';
    }).join('');
  }
  var hasFlavors=(b.flavors&&b.flavors.length)||(b.aroma&&b.aroma.length);
  var notesBlock=hasFlavors?
    '<div class="sc-notes">'+
      (b.flavors&&b.flavors.length?
        '<div class="sc-note-col"><div class="sc-sec-lbl"><i class="ti ti-cup"></i>Смак</div>'+
        '<div class="sc-pills">'+pillsHTML(b.flavors)+'</div></div>':'')+
      (b.aroma&&b.aroma.length?
        '<div class="sc-note-col"><div class="sc-sec-lbl"><i class="ti ti-flower"></i>Аромат</div>'+
        '<div class="sc-pills">'+pillsHTML(b.aroma)+'</div></div>':'')+
    '</div>':'';

  var descBlock=b.notes?
    '<div class="sc-desc"><div class="sc-sec-lbl"><i class="ti ti-message-2"></i>Опис</div>'+
    '<div class="sc-quote"><i class="ti ti-quote sc-quote-mk"></i>'+
    '<div class="sc-quote-tx">'+b.notes+'</div></div></div>':'';

  /* ── СЛАЙД 1 ── */
  var slide1='<div class="sc dark '+gradeClass+'">'+
    '<div class="sc-vig"></div>'+
    '<div class="sc-page"><span class="sc-page-cur">1</span><span class="sc-page-tot">/2</span></div>'+
    '<div class="sc-body">'+
      '<div class="sc-head">'+
        '<div class="sc-method">'+(method==='Альтернатива'?'':method)+'</div>'+
        '<div class="sc-rating">'+
          '<div class="sc-rating-lbl">ОЦІНКА</div>'+
          '<div class="sc-rating-num" style="color:'+gradeInk+'">'+rating.toFixed(1)+'</div>'+
        '</div>'+
      '</div>'+
      '<div class="sc-title">'+
        '<div class="sc-name">'+beanName+'</div>'+
        (roaster?'<div style="font-size:30px;font-weight:600;color:var(--sc-ink2);letter-spacing:-1px;line-height:1;margin-top:4px">'+roaster+'</div>':'')+
      '</div>'+
      '<div class="sc-metrics">'+
        '<div class="sc-metric"><i class="ti ti-scale"></i><div class="sc-metric-v">'+dose+'<span class="sc-metric-u">г</span></div><div class="sc-metric-l">Доза</div></div>'+
        (totalMl?'<div class="sc-metric"><i class="ti ti-droplet"></i><div class="sc-metric-v">'+totalMl+'<span class="sc-metric-u">мл</span></div><div class="sc-metric-l">Об\'єм</div></div>':'')+
        '<div class="sc-metric"><i class="ti ti-arrows-right-left"></i><div class="sc-metric-v">'+ratio+'</div><div class="sc-metric-l">Пропорція</div></div>'+
        '<div class="sc-metric"><i class="ti ti-temperature"></i><div class="sc-metric-v">'+temp+'</div><div class="sc-metric-l">Темп.</div></div>'+
        '<div class="sc-metric"><i class="ti ti-clock"></i><div class="sc-metric-v">'+time+'</div><div class="sc-metric-l">Час</div></div>'+
      '</div>'+
      (devs?'<div class="sc-section"><div class="sc-sec-lbl"><i class="ti ti-tools"></i>Девайси</div><div class="sc-dev-list">'+devs+'</div></div>':'')+
      notesBlock+
      descBlock+
      '<div class="sc-foot">'+
        '<div class="sc-foot-tx"><div class="sc-foot-t">Зварено в Coffee\u00a0Master</div><div class="sc-foot-s">Скануй щоб завантажити</div></div>'+
        '<div class="sc-qr"><i class="ti ti-qrcode"></i></div>'+
      '</div>'+
    '</div>'+
  '</div>';

  /* ── СЛАЙД 2: кільце + кроки (або еспресо-метрики) ── */
  var steps=(b.steps||[]).filter(function(s){return s.type==='pour'||s.type==='pause'||s.type==='action';});

  /* Еспресо без кроків — замінюємо слайд 2 на картку шоту */
  if(!steps.length&&b.espresso){
    var esp=b.espresso;
    var slide2='<div class="sc dark '+gradeClass+'">'+
      '<div class="sc-vig"></div>'+
      '<div class="sc-page"><span class="sc-page-cur">2</span><span class="sc-page-tot">/2</span></div>'+
      '<div class="sc-body">'+
        '<div class="sc-head">'+
          '<div class="sc-method">Еспресо</div>'+
          '<div class="sc-step-badge"><i class="ti ti-coffee"></i>Параметри шоту</div>'+
        '</div>'+
        '<div class="sc-title sc-title-2">'+
          '<div class="sc-name sc-name-2">'+beanName+'</div>'+
          '<div class="sc-sub"><span class="sc-chip">'+dose+' г · '+(esp.actualYield||esp.targetYield||'?')+' мл · '+temp+'</span></div>'+
        '</div>'+
        '<div class="sc-ring">'+
          '<svg viewBox="0 0 300 300">'+
            '<circle cx="150" cy="150" r="118" fill="none" stroke="var(--sc-line)" stroke-width="24"></circle>'+
            '<circle cx="150" cy="150" r="118" fill="none" stroke="#C08552" stroke-width="24" stroke-linecap="butt" stroke-dasharray="725 16.2" transform="rotate(-90 150 150)"></circle>'+
          '</svg>'+
          '<div class="sc-ring-c">'+
            '<div class="sc-ring-t">'+time+'</div>'+
            '<div class="sc-ring-l">'+t('brew_total')+'</div>'+
          '</div>'+
        '</div>'+
        '<div class="sc-metrics" style="grid-template-columns:repeat(3,1fr);margin-top:24px">'+
          '<div class="sc-metric"><i class="ti ti-clock"></i><div class="sc-metric-v">'+time+'</div><div class="sc-metric-l">Час шоту</div></div>'+
          '<div class="sc-metric"><i class="ti ti-arrows-right-left"></i><div class="sc-metric-v">1:'+b.ratio+'</div><div class="sc-metric-l">Ratio</div></div>'+
          '<div class="sc-metric"><i class="ti ti-gauge"></i><div class="sc-metric-v">'+(String(esp.pressure||'9').replace(/\s*бар\s*/gi,'').trim()+' бар')+'</div><div class="sc-metric-l">Тиск</div></div>'+
        '</div>'+
        (esp.tdsActual?'<div class="sc-section" style="margin-top:24px"><div class="sc-sec-lbl"><i class="ti ti-droplet-half"></i>Екстракція</div>'+
          '<div class="sc-metrics" style="grid-template-columns:repeat(2,1fr)">'+
            '<div class="sc-metric"><div class="sc-metric-v">'+esp.tdsActual+'<span class="sc-metric-u">%</span></div><div class="sc-metric-l">TDS факт.</div></div>'+
            '<div class="sc-metric"><div class="sc-metric-v">'+(esp.tdsTarget||'—')+'<span class="sc-metric-u">%</span></div><div class="sc-metric-l">TDS ціль</div></div>'+
          '</div></div>':'')+
        '<div class="sc-foot">'+
          '<div class="sc-foot-tx"><div class="sc-foot-t">Зварено в Coffee\u00a0Master</div><div class="sc-foot-s">Пулловер · еспресо-метод</div></div>'+
          '<div class="sc-qr"><i class="ti ti-qrcode"></i></div>'+
        '</div>'+
      '</div>'+
    '</div>';
    return slide1+slide2;
  }

  var totalSec=steps.reduce(function(s,st){return s+(st.ph!=null?st.ph/1000:(st.dur||0));},0)||1;
  var pourLabel=['Блум','2-й влив','3-й влив','4-й влив','5-й влив','6-й влив'];
  var pourIdx=0;
  var _ACTION_COL={'Перемішування':'#5fbf83','Чавимо':'#7c5cbf','Свьорл':'#38C4B8','Взбалтування':'#B8A0E8'};
  var _SC_CX=150,_SC_CY=150,_SC_R=118,_SC_W=24,_SC_GAP=2.2;
  function _scPol(deg){var a=(deg-90)*Math.PI/180;return[_SC_CX+_SC_R*Math.cos(a),_SC_CY+_SC_R*Math.sin(a)];}
  function _scArc(a0,a1){var p0=_scPol(a0),p1=_scPol(a1);var lg=(a1-a0)>180?1:0;return'M'+p0[0].toFixed(2)+' '+p0[1].toFixed(2)+' A'+_SC_R+' '+_SC_R+' 0 '+lg+' 1 '+p1[0].toFixed(2)+' '+p1[1].toFixed(2);}
  var _scTotGap=(steps.length>1?(steps.length-1)*_SC_GAP:0)+_SC_GAP;
  var _scSpan=360-_scTotGap;
  var _scAngle=_SC_GAP/2;
  var rings=steps.map(function(st){
    var dur=st.ph!=null?st.ph/1000:(st.dur||0);
    var sp=dur/totalSec*_scSpan;
    var color=st.type==='pour'?'#3f8fd6':(st.type==='action'?(st.color||_ACTION_COL[st.label]||'#6C6C72'):'#e0922f');
    var el='<path d="'+_scArc(_scAngle,_scAngle+sp)+'" fill="none" stroke="'+color+'" stroke-width="'+_SC_W+'" stroke-linecap="butt"></path>';
    _scAngle+=sp+_SC_GAP;
    return el;
  }).join('');

  function fmtSec(ms){var s=Math.round((ms||0)/1000),m=Math.floor(s/60),sc=s%60;return m+':'+(sc<10?'0':'')+sc;}
  var pourCount=0;
  var stepsHTML=steps.map(function(st){
    var dur=st.ph!=null?Math.round(st.ph/1000):(st.dur||0);
    var isPour=st.type==='pour';
    var isAction=st.type==='action';
    var label=isPour?(pourLabel[pourCount++]||'Влив'):(isAction?(st.label||'Дія'):'Пауза');
    var timeStr=st.t!=null?fmtSec(st.t):'—';
    var ml=st.ml?'+'+Math.round(st.ml)+' мл':'';
    var railColor=isPour?'#3f8fd6':(isAction?(st.color||_ACTION_COL[st.label]||'#6C6C72'):'#e0922f');
    var tagClass=isPour?'is-pour':(isAction?'is-action':'is-pause');
    return'<div class="sc-step">'+
      '<span class="sc-step-rail" style="background:'+railColor+'"></span>'+
      '<span class="sc-step-time">'+timeStr+'</span>'+
      '<span class="sc-step-tag '+tagClass+'" '+(isAction?('style="background:'+railColor+'"'):'')+'>'+label+'</span>'+
      '<span class="sc-step-dur">'+dur+'с</span>'+
      '<span class="sc-step-ml">'+ml+'</span>'+
    '</div>';
  }).join('');

  var pourCnt=steps.filter(function(s){return s.type==='pour';}).length;
  var slide2='<div class="sc dark '+gradeClass+'">'+
    '<div class="sc-vig"></div>'+
    '<div class="sc-page"><span class="sc-page-cur">2</span><span class="sc-page-tot">/2</span></div>'+
    '<div class="sc-body">'+
      '<div class="sc-head">'+
        '<div class="sc-method">'+(method==='Альтернатива'?'':method)+'</div>'+
        '<div class="sc-step-badge"><i class="ti ti-droplet"></i>Етапи проливу</div>'+
      '</div>'+
      '<div class="sc-title sc-title-2">'+
        '<div class="sc-name sc-name-2">'+beanName+'</div>'+
        '<div class="sc-sub"><span class="sc-chip">'+dose+' г · '+(totalMl||'?')+' мл · '+temp+'</span></div>'+
      '</div>'+
      '<div class="sc-ring">'+
        '<svg viewBox="0 0 300 300">'+
          '<circle cx="150" cy="150" r="118" fill="none" stroke="var(--sc-line)" stroke-width="24"></circle>'+
          rings+
        '</svg>'+
        '<div class="sc-ring-c">'+
          '<div class="sc-ring-t">'+time+'</div>'+
          '<div class="sc-ring-l">'+t('brew_total')+'</div>'+
        '</div>'+
      '</div>'+
      (function(){
        var _actionSteps=steps.filter(function(s){return s.type==='action';});
        var _seenActions={};
        var _legendActions='';
        _actionSteps.forEach(function(s){
          if(_seenActions[s.label])return;
          _seenActions[s.label]=1;
          var c=s.color||_ACTION_COL[s.label]||'#6C6C72';
          _legendActions+='<span class="sc-leg"><span class="sc-leg-dot" style="background:'+c+'"></span>'+s.label+'</span>';
        });
        return '<div class="sc-legend">'+
          '<span class="sc-leg"><span class="sc-leg-dot" style="background:#3f8fd6"></span>Влив</span>'+
          '<span class="sc-leg"><span class="sc-leg-dot" style="background:#e0922f"></span>Пауза</span>'+
          _legendActions+
        '</div>';
      })()+
      (stepsHTML?'<div class="sc-steps">'+stepsHTML+'</div>':'')+
      '<div class="sc-foot">'+
        '<div class="sc-foot-tx">'+
          '<div class="sc-foot-t">Зварено в Coffee\u00a0Master</div>'+
          '<div class="sc-foot-s">'+pourCnt+' влив'+(pourCnt===1?'':'и')+' · пульс-пролив</div>'+
        '</div>'+
        '<div class="sc-qr"><i class="ti ti-qrcode"></i></div>'+
      '</div>'+
    '</div>'+
  '</div>';

  return slide1+slide2;
}
