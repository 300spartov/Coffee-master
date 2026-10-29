/* FREEZE: keyboard-scroll-fix */
(function(){
  function onFocus(e){
    var el=e.target;
    if(el.tagName==='INPUT'||el.tagName==='TEXTAREA'||el.tagName==='SELECT'){
      setTimeout(function(){
        el.scrollIntoView({behavior:'smooth',block:'center'});
      },320); /* затримка поки клавіатура піднімається */
    }
  }
  document.addEventListener('focusin',onFocus,true);
  if(window.visualViewport){
    window.visualViewport.addEventListener('resize',function(){
      var el=document.activeElement;
      if(el&&(el.tagName==='INPUT'||el.tagName==='TEXTAREA')){
        setTimeout(function(){el.scrollIntoView({behavior:'smooth',block:'center'});},80);
      }
    });
  }
})();
