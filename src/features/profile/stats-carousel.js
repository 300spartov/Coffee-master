/* СТАТИСТИКА КАРУСЕЛІ */
var _RING_COLORS=[{stroke:'#F0A500'},{stroke:'#9B6DFF'},{stroke:'#2DD4A0'},{stroke:'#8198AE'}];
var _CIRCS=[358.1,263.9,169.6,75.4];
var _RING_BG_R=[57,42,27,12],_RING_SW=[12,12,12,9];
var _carIndex=0,_statsRendered=false,_statsOpen=false;

function _buildStatsDrinks(period, fromTs, toTs){
  var now=Date.now();
  var from, to;
  if(fromTs!==undefined){ from=fromTs; to=toTs||now; }
  else if(period==='week'){ var d=new Date(); d.setDate(d.getDate()-d.getDay()+1); from=new Date(d.getFullYear(),d.getMonth(),d.getDate()).getTime(); to=now; }
  else if(period==='month'){ var nd=new Date(); from=new Date(nd.getFullYear(),nd.getMonth(),1).getTime(); to=now; }
  else { var nd=new Date(); from=new Date(nd.getFullYear(),0,1).getTime(); to=now; }
  var log=(S.log||[]).filter(function(e){return e.ts>=from&&e.ts<=to;});
  var mc={};
  log.forEach(function(e){
    var m=e.method||'Інше';
    mc[m]=(mc[m]||0)+(e.vol||0);
  });
  var drinks=Object.keys(mc).map(function(m){return{name:m,ml:Math.round(mc[m]),cups:0};});
  drinks.sort(function(a,b){return b.ml-a.ml;});
  if(!drinks.length) drinks=[{name:'Немає даних',ml:1,cups:0}];
  return{cups:log.length,drinks:drinks};
}
function _fmtMl(v){return v>=1000?(v/1000).toFixed(v>=10000?0:1)+' л':v+' мл';}
function _buildPeriodHTML(period){
  var d=_buildStatsDrinks(period);
  var sorted=[].concat(d.drinks).sort(function(a,b){return b.ml-a.ml;});
  var top3=sorted.slice(0,3),rest=sorted.slice(3);
  var restTotal=rest.reduce(function(s,x){return s+x.ml;},0);
  var slices=top3.slice();
  if(restTotal>0)slices.push({name:'Інше',ml:restTotal,isOther:true,children:rest});
  var total=slices.reduce(function(s,sl){return s+sl.ml;},0)||1;
  var rings='';
  for(var i=0;i<4;i++)rings+='<circle cx="69" cy="69" r="'+_RING_BG_R[i]+'" fill="none" stroke="#1a1c1f" stroke-width="'+_RING_SW[i]+'"/>';
  for(var i=0;i<4;i++){
    var sl=slices[i];
    var col=_RING_COLORS[sl&&sl.isOther?3:i]||_RING_COLORS[3];
    var off=(sl&&sl.ml>0)?(_CIRCS[i]*(1-sl.ml/total)):_CIRCS[i];
    rings+='<circle cx="69" cy="69" r="'+_RING_BG_R[i]+'" fill="none" stroke="'+col.stroke+'" stroke-width="'+_RING_SW[i]+'" stroke-linecap="round" stroke-dasharray="'+_CIRCS[i]+'" stroke-dashoffset="'+off.toFixed(1)+'" transform="rotate(-90 69 69)" style="transition:stroke-dashoffset .7s"/>';
  }
  rings+='<circle cx="69" cy="69" r="5" fill="#2a2d31"/>';
  var legend=slices.map(function(sl,i){
    var col=_RING_COLORS[sl.isOther?3:i]||_RING_COLORS[3];
    var pct=Math.round(sl.ml/total*100);
    return'<div class="leg-row"><div class="leg-dot" style="background:'+col.stroke+'"></div>'
      +'<div class="leg-name">'+sl.name+'</div>'
      +'<div class="leg-right"><div class="leg-pct" style="color:'+col.stroke+'">'+pct+'%</div><div class="leg-ml">'+_fmtMl(sl.ml)+'</div></div></div>';
  }).join('');
  return '<div class="rings-card"><div style="flex-shrink:0;width:138px;height:138px"><svg viewBox="0 0 138 138" width="138" height="138">'+rings+'</svg></div>'
    +'<div class="legend">'+legend+'</div></div>'
    +'<div class="stat-grid-v2">'
    +'<div class="stat-tile"><div class="stat-v">'+d.cups+'</div><div class="stat-l">Чашок</div></div>'
    +'<div class="stat-tile"><div class="stat-v">'+(S.brews||[]).length+'</div><div class="stat-l">Всього</div></div>'
    +'</div>';
}
function _renderCarousel(){
  var track=document.getElementById('carousel-track');
  if(!track)return;
  var keys=['week','month','year'];
  keys.forEach(function(p,i){track.children[i].innerHTML=_buildPeriodHTML(p);});
  var dots=document.getElementById('carousel-dots');
  if(dots)dots.innerHTML=keys.map(function(p,i){return'<button class="cdot'+(i===_carIndex?' on':'')+'" onclick="goCarousel('+i+')" aria-label="'+p+'"></button>';}).join('');
}
function _setCarouselHeight(){
  var track=document.getElementById('carousel-track');if(!track)return;
  var slide=track.children[_carIndex];
  var car=document.getElementById('prof-carousel');
  if(slide&&car)car.style.height=slide.scrollHeight+'px';
}
function _updateCarousel(animate){
  var track=document.getElementById('carousel-track');if(!track)return;
  track.style.transition=animate?'transform .35s cubic-bezier(.4,0,.2,1)':'none';
  track.style.transform='translateX('+(-_carIndex*100)+'%)';
  document.querySelectorAll('#stats-collapse .ptab').forEach(function(t,i){t.classList.toggle('on',i===_carIndex);});
  document.querySelectorAll('#carousel-dots .cdot').forEach(function(dt,i){dt.classList.toggle('on',i===_carIndex);});
  _setCarouselHeight();
}
function goCarousel(i){_carIndex=Math.max(0,Math.min(2,i));_updateCarousel(true);}
function _updateCarouselStats(){
  var track=document.getElementById('carousel-track');if(!track)return;
  track.style.transition='none';
  track.style.transform='translateX('+(-_carIndex*100)+'%)';
  document.querySelectorAll('#carousel-dots .cdot').forEach(function(dt,i){dt.classList.toggle('on',i===_carIndex);});
  _setCarouselHeight();
}
function toggleStatsV2(){
  _statsOpen=!_statsOpen;
  var c=document.getElementById('stats-collapse');if(c)c.classList.toggle('open',_statsOpen);
  var ch=document.getElementById('stats-chev');if(ch)ch.classList.toggle('open',_statsOpen);
  var btn=document.getElementById('stats-toggle-btn');if(btn)btn.setAttribute('aria-expanded',_statsOpen);
  if(_statsOpen){
    if(!_statsRendered){_renderCarousel();_statsRendered=true;}
    setTimeout(function(){_updateCarousel(false);},40);
    setTimeout(function(){_setCarouselHeight();},440);
  }
}

function statShareCarousel(){
  /* Визначаємо діапазон по поточній вкладці */
  var keys=['week','month','year'];
  var p=keys[_carIndex]||'month';
  var periodNames={week:'Тиждень',month:'Місяць',year:'Рік'};
  var d=_buildStatsDrinks(p);
  var slices=[].concat(d.drinks).sort(function(a,b){return b.ml-a.ml;});
  var top3=slices.slice(0,3),rest=slices.slice(3);
  var restMl=rest.reduce(function(s,x){return s+x.ml;},0);
  if(restMl>0)top3.push({name:'Інше',ml:restMl});
  var totalMl=top3.reduce(function(s,x){return s+x.ml;},0)||1;
  var COLORS=['#c8a050','#7b6cc8','#5fbf83','#8198AE'];
  var CIRC2=2*Math.PI*118;
  var rHTML='<circle cx="150" cy="150" r="118" fill="none" stroke="#1c1e22" stroke-width="28"/>';
  var off2=0;
  top3.forEach(function(sl,i){
    var len=sl.ml/totalMl*CIRC2;
    if(len<2)return;
    rHTML+='<circle cx="150" cy="150" r="118" fill="none" stroke="'+COLORS[i%4]+'" stroke-width="28" stroke-linecap="butt" stroke-dasharray="'+len.toFixed(2)+' '+(CIRC2-len).toFixed(2)+'" stroke-dashoffset="'+(-off2).toFixed(2)+'" transform="rotate(-90 150 150)"/>';
    off2+=len+CIRC2*0.008;
  });
  var fmtMl2=function(ml){return ml>=1000?(ml/1000).toFixed(1)+' л':Math.round(ml)+' мл';};
  var legHTML=top3.map(function(sl,i){
    var pct=Math.round(sl.ml/totalMl*100);
    return'<div style="display:flex;align-items:center;gap:8px;margin-bottom:7px">'
      +'<div style="width:9px;height:9px;border-radius:50%;background:'+COLORS[i%4]+';flex-shrink:0"></div>'
      +'<div style="flex:1;font-size:12px;font-weight:600;color:#c8c0b4;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">'+sl.name+'</div>'
      +'<div style="font-size:11px;color:'+COLORS[i%4]+';font-weight:700;font-family:monospace">'+pct+'%</div>'
      +'<div style="font-size:11px;color:#888;font-family:monospace;min-width:48px;text-align:right">'+fmtMl2(sl.ml)+'</div>'
      +'</div>';
  }).join('');
  var html='<div style="width:340px;background:#17181a;border-radius:20px;overflow:hidden;font-family:system-ui,sans-serif">'
    +'<div style="background:linear-gradient(160deg,#1e2022 0%,#17181a 100%);padding:22px 20px 16px">'
    +'<div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:14px">'
    +'<div><div style="font-size:10px;letter-spacing:2px;color:#5a5550;margin-bottom:2px">COFFEE MASTER</div>'
    +'<div style="font-size:16px;font-weight:700;color:#f0ebe4">'+periodNames[p]+'</div></div>'
    +'<div style="text-align:right"><div style="font-size:9px;color:#5a5550;letter-spacing:1px">ВСЬОГО</div>'
    +'<div style="font-size:24px;font-weight:800;color:#c8a050;line-height:1">'+fmtMl2(totalMl)+'</div>'
    +'<div style="font-size:9px;color:#9a7040;font-weight:600">напою</div></div>'
    +'</div>'
    +'<div style="display:flex;align-items:center;gap:14px">'
    +'<div style="position:relative;width:130px;height:130px;flex-shrink:0"><svg viewBox="0 0 300 300" width="130" height="130">'+rHTML+'</svg>'
    +'<div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center">'
    +'<div style="font-family:monospace;font-size:18px;font-weight:700;color:#f0ebe4;line-height:1">'+d.cups+'</div>'
    +'<div style="font-size:9px;letter-spacing:1.5px;color:#6b6560;margin-top:2px">ЧАШОК</div>'
    +'</div></div>'
    +'<div style="flex:1">'+legHTML+'</div>'
    +'</div></div>'
    +'<div style="padding:12px 20px 18px;border-top:1px solid #222426;text-align:center;font-size:8px;color:#2e2c2a;letter-spacing:2px">ЗВАРЕНО В COFFEE MASTER</div>'
    +'</div>';
  var wrap=document.createElement('div');wrap.style.cssText='position:fixed;left:-9999px;top:0;z-index:-1';
  wrap.innerHTML=html;document.body.appendChild(wrap);
  if(typeof html2canvas!=='function'){toast('Шеринг недоступний');wrap.remove();return;}
  toast('Готуємо картку...');
  html2canvas(wrap.firstChild,{scale:2,backgroundColor:'#17181a',logging:false}).then(function(canvas){
    wrap.remove();
    canvas.toBlob(function(blob){
      var url=URL.createObjectURL(blob);
      if(navigator.share&&navigator.canShare&&navigator.canShare({files:[new File([blob],'stats.png',{type:'image/png'})]})){
        navigator.share({files:[new File([blob],'stats.png',{type:'image/png'})],title:'Coffee Stats'}).catch(function(){});
      } else {var a=document.createElement('a');a.href=url;a.download='stats.png';a.click();}
      setTimeout(function(){URL.revokeObjectURL(url);},5000);
    },'image/png');
  }).catch(function(e){wrap.remove();toast('Помилка шерингу');console.log(e);});
}
