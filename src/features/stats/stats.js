/* ─────────── СТАТИСТИКА ─────────── */
var ST_GRADES=[[8,'#5fbf83'],[6.5,'#b9c64f'],[5,'#e2c64c'],[3.5,'#ea9b3c'],[0,'#ea6a52']];
function stInk(r){for(var i=0;i<ST_GRADES.length;i++)if(r>=ST_GRADES[i][0])return ST_GRADES[i][1];return '#ea6a52'}
var FLAV_AXES={'фрукти':[1,.4,.5,0,0],'ягоди':[1,.5,.4,0,0],'цитрус':[.9,.2,.9,0,0],'сухофрукти':[.8,.7,.1,.3,0],'солодке':[0,1,0,.2,0],'карамель':[0,1,0,.4,.1],'мед':[.2,1,.1,.2,0],'ваніль':[0,.9,0,.3,0],'шоколад':[0,.7,0,.6,.3],'квіти':[.6,.4,.3,0,0],'горіхи':[0,.5,0,.6,.2],'спеції':[.1,.3,.1,.5,.3],'смажене':[0,.1,0,.6,.9],'кисле':[.3,0,1,0,.1]};
var stPeriod='month';
/* ДЕМО: заміни на агрегати з S.brews у renderStats() */
var ST_DEMO={
  donut:[{k:'Фільтр',g:540,c:'#E8955C'},{k:'Еспресо',g:420,c:'#A4C287'},{k:'Омні',g:220,c:'#c2b4a2'}],
  radar:[0.85,0.8,0.55,0.35,0.15],
  methods:[{k:'V60',v:8.9},{k:'Еспресо',v:7.8},{k:'Аеропрес',v:7.2}]
};
function stSetPeriod(p,btn){stPeriod=p;document.querySelectorAll('#st-seg button').forEach(function(b){b.classList.remove('on')});btn.classList.add('on');
  document.getElementById('st-period-lbl').textContent=p==='week'?'Тиждень':p==='month'?'Місяць':'Рік';renderStats()}
function renderStats(){
  /* Оновлюємо підпис поточного табу */
  var periodNames={week:'Тиждень',month:'Місяць',year:'Рік'};
  var pl=document.getElementById('st-period-lbl');
  if(pl)pl.textContent=periodNames[stPeriod]||stPeriod;

  /* ── Фільтр по обраному пеіоду ── */
  var now=Date.now();
  var fromTs=stPeriod==='week'?(function(){var d=new Date();d.setDate(d.getDate()-d.getDay()+1);return new Date(d.getFullYear(),d.getMonth(),d.getDate()).getTime();}()):
             stPeriod==='month'?(function(){var d=new Date();return new Date(d.getFullYear(),d.getMonth(),1).getTime();}()):
             new Date(new Date().getFullYear(),0,1).getTime();
  var brews=(S.brews||[]).filter(function(b){return (b.ts||0)>=fromTs;});
  var log=(S.log||[]).filter(function(e){return (e.ts||0)>=fromTs;});

  /* ── Напої по методах ── */
  var methodVol={};
  log.forEach(function(e){var m=e.method||'Інше';methodVol[m]=(methodVol[m]||0)+(e.vol||0);});
  var drinks=Object.keys(methodVol).map(function(m){return{name:m,ml:Math.round(methodVol[m])};}).sort(function(a,b){return b.ml-a.ml;});
  var totalMl=drinks.reduce(function(s,x){return s+x.ml;},0)||1;
  var DCOLS=['#E0A93B','#7b6cc8','#5fbf83','#8198AE','#c9a86a'];
  var drinkHTML=drinks.slice(0,5).map(function(d,i){
    var pct=Math.round(d.ml/totalMl*100);
    var fmtMl=d.ml>=1000?(d.ml/1000).toFixed(1)+' л':d.ml+' мл';
    return '<div style="display:flex;align-items:center;gap:8px">'
      +'<div style="width:8px;height:8px;border-radius:50%;background:'+DCOLS[i%5]+';flex-shrink:0"></div>'
      +'<div style="flex:1;font-size:13px;font-weight:600;color:var(--txt);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">'+d.name+'</div>'
      +'<div style="font-size:11px;color:'+DCOLS[i%5]+';font-weight:700;font-family:var(--mono);min-width:32px;text-align:right">'+pct+'%</div>'
      +'<div style="font-size:11px;color:var(--txt3);font-family:var(--mono);min-width:48px;text-align:right">'+fmtMl+'</div>'
      +'</div>';
  }).join('');
  var dl=document.getElementById('st-drinks-list');
  if(dl)dl.innerHTML=drinkHTML||'<div style="color:var(--txt3);font-size:13px">Немає даних за цей період</div>';

  /* ── Донат по типу обсмаження ── */
  var byType={filter:0,espresso:0,omni:0};
  brews.forEach(function(b){
    var dose=parseFloat(b.dose)||16;
    var lb=typeof liveBeanInfo==="function"?liveBeanInfo(b.beanId,b.beanName,b.roaster):{roastType:""};
    var type=lb.roastType||b.roastType||(typeof getRoastType==="function"?getRoastType(b.method):"filter");
    if(!byType.hasOwnProperty(type))type="filter";
    byType[type]+=dose;
  });
  var donutData=[
    {k:"Фільтр",g:Math.round(byType.filter),c:"#E0A93B"},
    {k:"Еспресо",g:Math.round(byType.espresso),c:"#A85A2E"},
    {k:"Омні",g:Math.round(byType.omni),c:"#8198AE"}
  ].filter(function(x){return x.g>0;});
  if(!donutData.length) donutData=[{k:"Немає даних",g:1,c:"#333"}];
  var total=donutData.reduce(function(s,x){return s+x.g;},0),C=289,off=0;
  var svg="<circle cx=\"60\" cy=\"60\" r=\"46\" fill=\"none\" stroke=\"#12100d\" stroke-width=\"15\"/>",leg="";
  donutData.forEach(function(x){
    var seg=x.g/total*C;
    if(seg>1)svg+="<circle cx=\"60\" cy=\"60\" r=\"46\" fill=\"none\" stroke=\""+x.c+"\" stroke-width=\"15\" stroke-dasharray=\""+(seg-5)+" "+C+"\" stroke-dashoffset=\""+(- off)+"\" stroke-linecap=\"round\" transform=\"rotate(-90 60 60)\"/>";
    off+=seg;
    var val=x.g>=1000?(x.g/1000).toFixed(2)+" кг":x.g+" г";
    leg+="<div class=\"st-leg\"><span><span class=\"st-sw\" style=\"background:"+x.c+"\"></span>"+x.k+"</span><b>"+val+"</b></div>";
  });
  var tv=total>=1000?(total/1000).toFixed(2):total;
  svg+="<text x=\"60\" y=\"57\" text-anchor=\"middle\" fill=\"#EDE7DD\" font-family=\"JetBrains Mono\" font-size=\"18\" font-weight=\"700\">"+tv+"</text><text x=\"60\" y=\"73\" text-anchor=\"middle\" fill=\"#877a6a\" font-family=\"JetBrains Mono\" font-size=\"9\">"+( total>=1000?"КГ":"Г")+"</text>";
  document.getElementById("st-donut").innerHTML=svg;
  document.getElementById("st-donut-leg").innerHTML=leg;

  /* ── Радар смакового профілю ── */
  var axes=[0,0,0,0,0];
  var axisW=0;
  brews.forEach(function(b){
    var w=parseFloat(b.rating)||5;
    var notes=(b.flavors||[]).concat(b.aroma||[]);
    notes.forEach(function(note){
      var n=(typeof note==="string"?note:(note&&note.ua?note.ua:String(note))).toLowerCase();
      var found=null;
      Object.keys(FLAV_AXES).forEach(function(k){if(n.includes(k)||k.includes(n.split(" ")[0]))found=k;});
      if(found){var v=FLAV_AXES[found];for(var i=0;i<5;i++)axes[i]+=v[i]*w;}
    });
    if(notes.length)axisW+=w;
  });
  var norm=axisW>0?axes.map(function(v){return Math.min(1,v/axisW/3);}):[0,0,0,0,0];
  var hasProfile=norm.some(function(v){return v>0.05;});

  var names=["фруктовість","солодкість","кислотність","тіло","гіркота"];
  var cx=65,cy=62,R=52;
  function pt(v,i){var a=-Math.PI/2+i*2*Math.PI/5,r=8+v*(R-8);return [(cx+Math.cos(a)*r).toFixed(1),(cy+Math.sin(a)*r).toFixed(1)];}
  function grid(f){return [0,1,2,3,4].map(function(i){var a=-Math.PI/2+i*2*Math.PI/5;return (cx+Math.cos(a)*R*f).toFixed(1)+","+(cy+Math.sin(a)*R*f).toFixed(1);}).join(" ");}
  var pts=norm.map(pt);
  var rs="<polygon points=\""+grid(1)+"\" fill=\"none\" stroke=\"#2c2721\"/><polygon points=\""+grid(.55)+"\" fill=\"none\" stroke=\"#2c2721\"/>";
  if(hasProfile){
    rs+="<polygon points=\""+pts.map(function(p){return p.join(",");}).join(" ")+"\" fill=\"rgba(232,149,92,.2)\" stroke=\"#E8955C\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/>";
    pts.forEach(function(p){rs+="<circle cx=\""+p[0]+"\" cy=\""+p[1]+"\" r=\"4\" fill=\"#F2B285\"/>";});
  } else {
    rs+="<text x=\"65\" y=\"68\" text-anchor=\"middle\" fill=\"#555\" font-size=\"10\">немає нот</text>";
  }
  document.getElementById("st-radar").innerHTML=rs;
  document.getElementById("st-radar-leg").innerHTML=names.map(function(n,i){
    var dots=Math.round(norm[i]*5);
    return "<div class=\"cp-lbl\" style=\"margin:0"+(i===0?";color:#E8955C":"")+"\">"+n+" "+"●".repeat(dots)+"○".repeat(5-dots)+"</div>";
  }).join("");
  var top=hasProfile?names[norm.indexOf(Math.max.apply(null,norm))]:"—";
  document.getElementById("st-radar-hint").textContent=hasProfile?"Домінує "+top+". Профіль зважений на оцінки чашок.":"Вибери ноти смаку в рецептах щоб побачити профіль.";

  /* ── Рейтинг методів ── */
  var methodMap={};
  brews.forEach(function(b){
    var m=b.method||"Інше";
    if(!methodMap[m])methodMap[m]={sum:0,cnt:0};
    methodMap[m].sum+=parseFloat(b.rating)||0;
    methodMap[m].cnt++;
  });
  var methods=Object.keys(methodMap).map(function(k){return{k:k,v:methodMap[k].cnt>0?methodMap[k].sum/methodMap[k].cnt:0};}).sort(function(a,b){return b.v-a.v;}).slice(0,5);
  document.getElementById("st-methods").innerHTML=methods.length?methods.map(function(m){
    var c=m.v>=8?"#5fbf83":m.v>=6.5?"#b9c64f":m.v>=5?"#e2c64c":"#ea6a52";
    return "<div class=\"cp-row\" style=\"margin-bottom:8px\"><span style=\"width:74px;font-size:12px;font-weight:700;overflow:hidden;text-overflow:ellipsis;white-space:nowrap\">"+m.k+"</span><div class=\"st-mbar\"><span style=\"width:"+(m.v*10)+"%%;background:"+c+"\"></span></div><b class=\"cp-mono\" style=\"font-size:12px;color:"+c+"\">"+m.v.toFixed(1)+"</b></div>";
  }).join(""):"<div style=\"color:#555;font-size:12px\">Немає даних за цей період</div>";
}
/* автозапуск демо */
/* Compare/Stats screens render on demand — triggered by user navigation */

