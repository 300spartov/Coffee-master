/* ============================================================
   Общие утилиты колеса: SVG-хелперы, геометрия дуг, оттенки,
   текст вдоль дуги. Используется всеми режимами.
   ============================================================ */
(function(){
  var NS='http://www.w3.org/2000/svg';
  var TAU=Math.PI*2;

  function ns(t){ return document.createElementNS(NS,t); }

  /* hex → {r,g,b} */
  function hx(c){
    c=c.replace('#','');
    if(c.length===3) c=c.split('').map(function(x){return x+x;}).join('');
    return {r:parseInt(c.slice(0,2),16),g:parseInt(c.slice(2,4),16),b:parseInt(c.slice(4,6),16)};
  }
  function toHex(n){ n=Math.max(0,Math.min(255,Math.round(n))); var s=n.toString(16); return s.length<2?'0'+s:s; }
  /* осветлить (t>0) / затемнить (t<0) к белому/чёрному */
  function shade(hex,t){
    var c=hx(hex);
    if(t>=0) return '#'+toHex(c.r+(255-c.r)*t)+toHex(c.g+(255-c.g)*t)+toHex(c.b+(255-c.b)*t);
    var k=1+t; return '#'+toHex(c.r*k)+toHex(c.g*k)+toHex(c.b*k);
  }
  /* подмешать к серому (десатурация) */
  function mute(hex,t){
    var c=hx(hex); var g=(c.r+c.g+c.b)/3;
    return '#'+toHex(c.r+(g-c.r)*t)+toHex(c.g+(g-c.g)*t)+toHex(c.b+(g-c.b)*t);
  }
  /* читаемый цвет текста на фоне */
  function ink(hex){
    var c=hx(hex); var L=(0.299*c.r+0.587*c.g+0.114*c.b);
    return L>150?'#1a1206':'#ffffff';
  }

  /* кольцевой сектор */
  function arcPath(r1,r2,a1,a2,gap){
    var g=gap==null?0.01:gap;
    var a1g=a1+g,a2g=a2-g;
    if(a2g<=a1g){a1g=a1;a2g=a2;}
    var lg=(a2g-a1g)>Math.PI?1:0;
    var c=Math.cos,s=Math.sin;
    return 'M'+(c(a1g)*r1)+','+(s(a1g)*r1)
      +' A'+r1+','+r1+' 0 '+lg+',1 '+(c(a2g)*r1)+','+(s(a2g)*r1)
      +' L'+(c(a2g)*r2)+','+(s(a2g)*r2)
      +' A'+r2+','+r2+' 0 '+lg+',0 '+(c(a1g)*r2)+','+(s(a1g)*r2)+' Z';
  }

  function path(parent,d,fill,opts){
    opts=opts||{};
    var p=ns('path');
    p.setAttribute('d',d); p.setAttribute('fill',fill);
    p.setAttribute('stroke',opts.stroke||'#15161a');
    p.setAttribute('stroke-width',opts.sw==null?1:opts.sw);
    if(opts.op!=null) p.setAttribute('opacity',opts.op);
    if(opts.lj) p.setAttribute('stroke-linejoin','round');
    if(opts.onClick){ p.style.cursor='pointer'; p.addEventListener('click',opts.onClick); }
    parent.appendChild(p); return p;
  }

  var _tpId=0;
  /* текст вдоль дуги (радиальная середина r) */
  function textArc(parent,r,a1,a2,txt,size,fill,bold){
    var am=(a1+a2)/2;
    var c=Math.cos,s=Math.sin;
    var flip=(am>0&&am<Math.PI);
    var aa1=flip?a2:a1, aa2=flip?a1:a2;
    var lg=Math.abs(aa2-aa1)>Math.PI?1:0;
    var sweep=flip?0:1;
    var d='M'+c(aa1)*r+','+s(aa1)*r+' A'+r+','+r+' 0 '+lg+','+sweep+' '+c(aa2)*r+','+s(aa2)*r;
    var pid='tp'+(++_tpId);
    var pe=ns('path'); pe.setAttribute('id',pid); pe.setAttribute('d',d); pe.setAttribute('fill','none');
    parent.appendChild(pe);
    var t=ns('text');
    t.setAttribute('font-size',size); t.setAttribute('fill',fill);
    t.setAttribute('font-family','-apple-system,Helvetica Neue,sans-serif');
    t.setAttribute('font-weight',bold?'700':'500');
    t.setAttribute('letter-spacing','.2');
    t.setAttribute('pointer-events','none'); t.setAttribute('text-anchor','middle');
    var tp=ns('textPath');
    tp.setAttributeNS('http://www.w3.org/1999/xlink','href','#'+pid);
    tp.setAttribute('startOffset','50%'); tp.textContent=txt;
    t.appendChild(tp); parent.appendChild(t); return t;
  }

  /* текст вдоль РАДИУСА (для узких внешних колец — читается наружу) */
  function textRadial(parent,r1,r2,am,txt,size,fill,bold){
    var c=Math.cos,s=Math.sin;
    var deg=am*180/Math.PI;
    var flip=(am>Math.PI/2 && am<Math.PI*1.5);
    var rot=flip?deg+180:deg;
    var rr=flip?r1:r2; var anchor=flip?'start':'end';
    var rm=flip?r1+3:r2-3;
    var t=ns('text');
    t.setAttribute('x',c(am)*rm); t.setAttribute('y',s(am)*rm);
    t.setAttribute('font-size',size); t.setAttribute('fill',fill);
    t.setAttribute('font-family','-apple-system,Helvetica Neue,sans-serif');
    t.setAttribute('font-weight',bold?'700':'500');
    t.setAttribute('text-anchor',anchor); t.setAttribute('dominant-baseline','middle');
    t.setAttribute('pointer-events','none');
    t.setAttribute('transform','rotate('+rot+','+c(am)*rm+','+s(am)*rm+')');
    t.textContent=txt; parent.appendChild(t); return t;
  }

  function text(parent,x,y,txt,size,fill,bold){
    var t=ns('text'); t.setAttribute('x',x); t.setAttribute('y',y);
    t.setAttribute('text-anchor','middle'); t.setAttribute('dominant-baseline','middle');
    t.setAttribute('fill',fill); t.setAttribute('font-size',size);
    t.setAttribute('font-family','-apple-system,Helvetica Neue,sans-serif');
    t.setAttribute('font-weight',bold?'700':'500'); t.setAttribute('pointer-events','none');
    t.textContent=txt; parent.appendChild(t); return t;
  }

  /* тёмный ореол под белым текстом → читается на любом цвете сегмента */
  function outline(node,color,w){
    node.setAttribute('stroke', color||'#120d07');
    node.setAttribute('stroke-width', w==null?2.2:w);
    node.setAttribute('stroke-opacity','0.62');
    node.setAttribute('paint-order','stroke');
    node.setAttribute('stroke-linejoin','round');
    node.setAttribute('stroke-linecap','round');
    return node;
  }

  window.WC={ NS:NS, TAU:TAU, ns:ns, shade:shade, mute:mute, ink:ink,
    arcPath:arcPath, path:path, textArc:textArc, textRadial:textRadial, text:text, outline:outline, defs3D:defs3D };

  /* фільтри/градієнти для об'ємних ефектів */
  function defs3D(svg){
    var d=ns('defs');
    d.innerHTML =
      '<filter id="liftSel" x="-60%" y="-60%" width="220%" height="220%">'
      +'<feDropShadow dx="0" dy="2.4" stdDeviation="2.6" flood-color="#000" flood-opacity="0.55"/></filter>'
      +'<filter id="liftRing" x="-25%" y="-25%" width="150%" height="150%">'
      +'<feDropShadow dx="0" dy="2" stdDeviation="3" flood-color="#000" flood-opacity="0.42"/></filter>'
      +'<filter id="hubLift" x="-60%" y="-60%" width="220%" height="220%">'
      +'<feDropShadow dx="0" dy="3.5" stdDeviation="5" flood-color="#000" flood-opacity="0.6"/></filter>'
      +'<radialGradient id="hubGrad" cx="50%" cy="50%" r="50%">'
      +'<stop offset="0%" stop-color="#23262a"/><stop offset="62%" stop-color="#212429"/>'
      +'<stop offset="82%" stop-color="#16181b"/>'
      +'<stop offset="100%" stop-color="#08090a"/></radialGradient>'
      +'<radialGradient id="hubHi" cx="50%" cy="50%" r="58%">'
      +'<stop offset="0%" stop-color="#ffffff" stop-opacity="0.06"/>'
      +'<stop offset="60%" stop-color="#ffffff" stop-opacity="0.03"/>'
      +'<stop offset="100%" stop-color="#ffffff" stop-opacity="0"/></radialGradient>';
    svg.appendChild(d);
    return d;
  }
})();
