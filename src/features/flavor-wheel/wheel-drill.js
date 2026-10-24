/* ============================================================
   РЕЖИМ «Колесо» — пошагова навігація з об'ємом.
   • Пройдені рівні лишаються тонкими кільцями на ~30% прозорості.
   • Поточний рівень — зовнішнє кільце рівних блоків з м'якою тінню.
   • Невибрані ноти трохи тьмяніші; вибрана — у тонкій рамці,
     трохи піднята над рештою (тінь знизу).
   • Центр — об'ємна кнопка (градієнт + тінь + блік).
     Ур.1 категорії → тап → Ур.2 → тап → Ур.3 ноти
   ============================================================ */
(function(){
  function render(svg){
    svg.innerHTML='';
    WC.defs3D(svg);
    var TAU=WC.TAU, START=-TAU/4;
    var V=window.VIEW, matches=STORE.searchMatches();
    var acCat=V.active?STORE.findCat(V.active):null;
    var acSub=(acCat&&V.activeSub)?STORE.findSub(acCat,V.activeSub):null;

    /* ── Рівень 1: категорії ── */
    if(!acCat){
      optionRing(svg, 100, 172, window.FLAVORS.map(function(cat){
        return { label:cat.label, color:cat.color, count:STORE.countCat(cat.id), big:true,
          dim: matches && !matches.cats[cat.id], leaf:false,
          onClick:function(){ enterCat(cat); } };
      }), START, true);
      var tot=STORE.total();
      hub(svg, 96, null, function(g){
        WC.text(g,0,-14, tot?String(tot):'☕', 30, tot?'#e8a85a':'#8a857c', true);
        WC.text(g,0,18, tot?t('wheel_notes_selected'):t('wheel_choose_cat'), 11, '#9a968f', false);
      });
      return;
    }

    /* ── Рівень 2: підкатегорії (категорія-крихта всередині, ~30%) ── */
    if(!acSub){
      crumbRing(svg, 44, 90, acCat.color, acCat.label, true, function(){ window.VIEW.active=null; window.APP_RENDER(); });
      optionRing(svg, 96, 172, acCat.subs.map(function(sub,j){
        return { label:sub.label, color:STORE.subColor(acCat,j), count:STORE.countUnder(acCat.id,sub.id),
          dim: matches && !matches.subs[acCat.id+'▸'+sub.id], leaf:false,
          onClick:function(){ enterSub(acCat,sub); } };
      }), START, false);
      hub(svg, 40, acCat, null);
      return;
    }

    /* ── Рівень 3: ноти (категорія+група всередині, ~30%) ── */
    crumbRing(svg, 44, 78, acCat.color, acCat.label, true, function(){ window.VIEW.active=null; window.VIEW.activeSub=null; window.APP_RENDER(); });
    crumbRing(svg, 84, 120, STORE.subColor(acCat, acCat.subs.indexOf(acSub)), acSub.label, false,
      function(){ window.VIEW.activeSub=null; if(acCat.subs.length===1){window.VIEW.active=null;} window.APP_RENDER(); });
    optionRing(svg, 126, 172, acSub.desc.map(function(d,k){
      var _dKey=typeof d==='object'?d.ua:d;
      var _dLabel=typeof d==='object'?(currentLang==='en'?d.en:d.ua):d;
      return { label:_dLabel, color:STORE.noteColor(acCat, acCat.subs.indexOf(acSub), k, acSub.desc.length),
        sel:STORE.isSel(acCat.id,acSub.id,_dKey), leaf:true,
        dim: matches && !matches.notes[acCat.id+'▸'+acSub.id+'▸'+_dKey],
        onClick:function(){
            STORE.toggle(acCat.id,acSub.id,_dKey);
            if(STORE.isSel(acCat.id,acSub.id,_dKey)){
              /* L3 selected → remove L2 (chain shown instead: Солодке › Цукор › Кор. цукор) */
              STORE.remove(STORE.pathId(acCat.id,acSub.id));
            } else if(STORE.countUnder(acCat.id,acSub.id)===0){
              /* Last L3 deselected → restore L2 as fallback */
              STORE.toggle(acCat.id,acSub.id);
            }
          } };
    }), START, true);
    hub(svg, 40, acCat, null);
  }

  /* зовнішнє кільце рівних блоків (поточний рівень) */
  function optionRing(parent, r1, r2, items, start, anim){
    var TAU=WC.TAU, n=items.length, step=TAU/n, rMid=(r1+r2)/2;
    var base=WC.ns('g'); base.setAttribute('filter','url(#liftRing)'); parent.appendChild(base);
    var raised=WC.ns('g'); parent.appendChild(raised); // вибрані ноти — поверх, з тінню

    items.forEach(function(it,i){
      var a1=start+i*step, a2=a1+step, am=(a1+a2)/2;
      var lifted = it.leaf && it.sel;
      var host=WC.ns('g');
      if(anim && !lifted){ host.style.transformOrigin='0 0'; host.style.animation='ringIn .26s cubic-bezier(.33,1.1,.55,1) '+(i*20)+'ms both'; }
      (lifted?raised:base).appendChild(host);

      var fill, stroke, sw, op, R1=r1, R2=r2;
      if(it.leaf){
        if(it.sel){
          R1=r1-3; R2=r2+5;                    // піднята над рештою
          fill=WC.shade(it.color,0.04); stroke='#f4ede3'; sw=1.6; op=1;
          host.setAttribute('filter','url(#liftSel)');
        } else { fill=WC.shade(it.color,-0.04); stroke=WC.shade(it.color,-0.34); sw=0.9; op=it.dim?0.16:0.82; }
      } else {
        fill=it.color; stroke=WC.shade(it.color,-0.3); sw=1.1; op=it.dim?0.16:1;
      }
      WC.path(host, WC.arcPath(R1,R2,a1,a2,0.014), fill, {
        stroke:stroke, sw:sw, op:op, lj:true, onClick:function(e){ e.stopPropagation(); it.onClick(); }
      });
      if(!it.dim){
        var avail=step*rMid;
        var fs=Math.max(8.5, Math.min(it.big?13.5:13, avail/(it.label.length*0.6)));
        WC.textArc(host, rMid, a1,a2, it.label, fs, (it.leaf&&!it.sel)?WC.shade(it.color,-0.55):WC.ink(it.color), true);
        if(!it.leaf) WC.textArc(host, r2-12, a1,a2, '›', 12, WC.shade(it.color,-0.45), true);
        if(it.count) badge(host, Math.cos(am)*(r1+11), Math.sin(am)*(r1+11), it.count);
        if(lifted) badge(host, Math.cos(am)*(R2-11), Math.sin(am)*(R2-11), '✓');
      }
    });
  }

  /* внутрішнє кільце-крихта (пройдений рівень, ~30% прозорості) */
  function crumbRing(parent, r1, r2, color, label, withChevron, onClick){
    var g=WC.ns('g'); g.style.cursor='pointer'; g.setAttribute('opacity','0.32');
    g.addEventListener('click',function(e){ e.stopPropagation(); onClick(); });
    parent.appendChild(g);
    var d='M'+r2+',0 A'+r2+','+r2+' 0 1 1 '+(-r2)+',0 A'+r2+','+r2+' 0 1 1 '+r2+',0 '
        +'M'+r1+',0 A'+r1+','+r1+' 0 1 0 '+(-r1)+',0 A'+r1+','+r1+' 0 1 0 '+r1+',0 Z';
    var p=WC.ns('path'); p.setAttribute('d',d); p.setAttribute('fill-rule','evenodd');
    p.setAttribute('fill',color); p.setAttribute('stroke',WC.shade(color,-0.3)); p.setAttribute('stroke-width',1);
    g.appendChild(p);
    /* підпис тримаємо чіткішим за тло */
    var lg=WC.ns('g'); lg.setAttribute('opacity','2.6'); /* компенсує 0.32 групи → ~0.83 */
    g.appendChild(lg);
    var rMid=(r1+r2)/2;
    WC.text(lg, 0, -rMid+(withChevron?-2:0), label.length>14?label.slice(0,13)+'…':label, 9.5, WC.ink(color), true);
    if(withChevron) WC.text(lg, 0, -rMid+9, '‹ назад', 6.5, WC.ink(color), false);
  }

  /* об'ємна центральна кнопка */
  function hub(parent, r, cat, drawInner){
    var g=WC.ns('g'); g.setAttribute('filter','url(#hubLift)');
    if(cat){ g.style.cursor='pointer'; g.addEventListener('click',function(e){ e.stopPropagation(); goBack(); }); }
    parent.appendChild(g);
    var c=WC.ns('circle'); c.setAttribute('r',r-3); c.setAttribute('fill','url(#hubGrad)');
    c.setAttribute('stroke', cat?cat.color:'#3f444b'); c.setAttribute('stroke-width', cat?2:1.4); g.appendChild(c);
    var hi=WC.ns('circle'); hi.setAttribute('r',r-4); hi.setAttribute('fill','url(#hubHi)'); hi.setAttribute('pointer-events','none'); g.appendChild(hi);
    var content=WC.ns('g'); content.setAttribute('pointer-events','none'); g.appendChild(content);
    if(cat){
      WC.text(content,0,-7,'‹',22,cat.color,true);
      WC.text(content,0,12,'назад',7.5,'#9a968f',false);
    } else if(drawInner){ drawInner(content); }
  }

  function enterCat(cat){
    /* Mark L1 immediately when tapping category */
    if(STORE.countCat(cat.id)===0) STORE.toggle(cat.id);
    window.VIEW.active=cat.id;
    window.VIEW.activeSub = (cat.subs.length===1)?cat.subs[0].id:null;
    if(window.VIEW.activeSub){ _enterSub(cat, cat.subs[0]); return; }
    window.APP_RENDER();
  }
  function enterSub(cat,sub){ _enterSub(cat,sub); }
  function _enterSub(cat,sub){
    /* Mark L2: remove bare L1 (L2 already implies L1), add L2 if not there */
    STORE.remove(STORE.pathId(cat.id));
    if(STORE.countUnder(cat.id,sub.id)===0) STORE.toggle(cat.id,sub.id);
    window.VIEW.active=cat.id; window.VIEW.activeSub=sub.id;
    window.APP_RENDER();
  }
  function goBack(){
    var V=window.VIEW;
    if(V.activeSub){ var cat=STORE.findCat(V.active); V.activeSub=null; if(cat&&cat.subs.length===1) V.active=null; }
    else { V.active=null; }
    window.APP_RENDER();
  }

  function badge(parent,x,y,txt){
    var leaf=String(txt)==='✓';
    var c=WC.ns('circle'); c.setAttribute('cx',x); c.setAttribute('cy',y); c.setAttribute('r',leaf?8:8.5);
    c.setAttribute('fill','#e8a85a'); c.setAttribute('stroke','#1c130a'); c.setAttribute('stroke-width',1.2);
    c.setAttribute('pointer-events','none'); parent.appendChild(c);
    WC.text(parent,x,y,String(txt),leaf?8:7.2,'#1c130a',true);
  }

  window.MODES=window.MODES||{};
  window.MODES.drill=render;
})();
