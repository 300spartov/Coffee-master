let currentBrewScreen='bv-method-pick';
function showBV(id){currentBrewScreen=id;['bv-method-pick','bv-setup','bv-active','bv-rate','bv-result','bv-esp-active','bv-esp-milk','bv-esp-result'].forEach(v=>{const el=document.getElementById(v);if(el)el.style.display=v===id?'block':'none';});
  /* Скидаємо «залиплу» рамку вибору (hover-обведення лишається на тач-екрані після тапу).
     Без цього при поверненні на вибір методу картки лишаються «обраними» і накопичуються — і для альтернативи, і для еспресо. */
  if(id==='bv-method-pick'){var _sg=document.getElementById('bv-alt-subgrid');if(_sg)_sg.querySelectorAll('button').forEach(function(b){b.style.borderColor='var(--line-soft)';});}
  /* переносимо єдиний блок колеса в активний екран (альтернатива / еспресо) */
  var _tb=document.getElementById('taste-block');
  if(_tb){
    if(id==='bv-esp-result'){var _m=document.getElementById('esp-taste-mount');if(_m&&_tb.parentElement!==_m)_m.appendChild(_tb);}
    else if(id==='bv-rate'){var _a=document.getElementById('alt-taste-mount');if(_a&&_tb.parentElement!==_a)_a.appendChild(_tb);}
  }
  const scrEl=document.getElementById('scr-brew');if(scrEl)scrEl.scrollTop=0;
}
