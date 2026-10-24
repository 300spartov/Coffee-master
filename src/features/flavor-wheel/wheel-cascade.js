/* ============================================================
   РЕЖИМ «Пошук + каскад» — швидкий список з розкриттям рівнів.
   Любой уровень выбирается тапом по строке (полный путь в лог).
   Розкриття/згортання — по шеврону. Пошук фільтрує ноти.
   ============================================================ */
(function(){
  var OPEN={}; // catId / catId.subId → раскрыто

  function el(tag,cls,txt){ var e=document.createElement(tag); if(cls)e.className=cls; if(txt!=null)e.textContent=txt; return e; }

  function render(container){
    container.innerHTML='';
    var matches=STORE.searchMatches();

    /* режим поиска → плоский список найденных нот */
    if(matches){
      var hits=window.FLAT_NOTES.filter(function(f){
        return matches.notes[f.cat.id+'▸'+f.sub.id+'▸'+f.note];
      });
      if(!hits.length){ container.appendChild(el('div','casc-empty','Нічого не знайдено')); return; }
      var head=el('div','casc-reshead', hits.length+' знайдено'); container.appendChild(head);
      hits.forEach(function(f,i){
        var sel=STORE.isSel(f.cat.id,f.sub.id,f.note);
        var _fLabel=f.desc&&typeof f.desc==='object'?(currentLang==='en'?f.desc.en:f.desc.ua):f.note;
        var row=el('div','casc-hit'+(sel?' on':''));
        row.style.setProperty('--c', STORE.noteColor(f.cat, f.cat.subs.indexOf(f.sub), f.sub.desc.findIndex(function(x){return (typeof x==='object'?x.ua:x)===f.note;}), f.sub.desc.length));
        var dot=el('span','casc-dot'); dot.style.background=f.cat.color; row.appendChild(dot);
        var txt=el('div','casc-hit-txt');
        txt.appendChild(el('span','casc-hit-note',_fLabel));
        var crumb = f.sub.label!==f.cat.label ? f.cat.label+' › '+f.sub.label : f.cat.label;
        txt.appendChild(el('span','casc-hit-crumb',crumb));
        row.appendChild(txt);
        row.appendChild(el('span','casc-check', sel?'✓':'+'));
        row.addEventListener('click',function(){ STORE.toggle(f.cat.id,f.sub.id,f.note); });
        container.appendChild(row);
      });
      return;
    }

    /* обычный каскад-аккордеон */
    window.FLAVORS.forEach(function(cat){
      var ci=window.FLAVORS.indexOf(cat);
      var catOpen=OPEN[cat.id];
      var cnt=STORE.countCat(cat.id);
      var crow=el('div','casc-cat'+(catOpen?' open':'')+(STORE.isSel(cat.id)?' on':''));
      crow.style.borderColor=cat.color;
      var cbar=el('span','casc-bar'); cbar.style.background=cat.color; crow.appendChild(cbar);
      var ctitle=el('button','casc-ctitle');
      ctitle.appendChild(el('span','casc-chev',catOpen?'▾':'▸'));
      ctitle.appendChild(el('span','casc-clabel',cat.label));
      if(cnt) ctitle.appendChild(el('span','casc-count',String(cnt)));
      ctitle.addEventListener('click',function(){ OPEN[cat.id]=!OPEN[cat.id]; render(container); });
      crow.appendChild(ctitle);
      var cpick=el('button','casc-pick'+(STORE.isSel(cat.id)?' on':''), STORE.isSel(cat.id)?'✓ вся':'+ вся');
      cpick.title='';cpick.style.display='none';
      /* cpick hidden */
      crow.appendChild(cpick);
      container.appendChild(crow);

      if(!catOpen) return;
      cat.subs.forEach(function(sub,si){
        var skey=cat.id+'.'+sub.id, subOpen=OPEN[skey];
        var single=(cat.subs.length===1 && sub.label===cat.label);
        if(!single){
          var srow=el('div','casc-sub'+(subOpen?' open':'')+(STORE.isSel(cat.id,sub.id)?' on':''));
          var stitle=el('button','casc-stitle');
          stitle.appendChild(el('span','casc-chev',subOpen?'▾':'▸'));
          stitle.appendChild(el('span',null,sub.label));
          var sc=STORE.countUnder(cat.id,sub.id);
          if(sc) stitle.appendChild(el('span','casc-count',String(sc)));
          stitle.addEventListener('click',function(){ OPEN[skey]=!OPEN[skey]; render(container); });
          srow.appendChild(stitle);
          /* spick hidden */
          container.appendChild(srow);
        }
        if(single || subOpen){
          var wrap=el('div','casc-notes');
          sub.desc.forEach(function(d,di){
            var _dKey=typeof d==='object'?d.ua:d;
            var _dLabel=typeof d==='object'?(currentLang==='en'?d.en:d.ua):d;
            var sel=STORE.isSel(cat.id,sub.id,_dKey);
            var chip=el('button','casc-chip'+(sel?' on':''),_dLabel);
            var col=STORE.noteColor(cat,si,di,sub.desc.length);
            if(sel){ chip.style.background=col; chip.style.borderColor=col; chip.style.color=WC.ink(col); }
            else { chip.style.borderColor=WC.shade(col,-0.1); chip.style.color=WC.shade(col,0.35); }
            chip.addEventListener('click',function(){ STORE.toggle(cat.id,sub.id,d); });
            wrap.appendChild(chip);
          });
          container.appendChild(wrap);
        }
      });
    });
  }

  window.MODES=window.MODES||{};
  window.MODES.cascade=render;
})();
