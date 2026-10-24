/* END FREEZE: keyboard-scroll-fix */



/* Tab switcher: flavor / aroma */
var _NW_TAB = 'flavor';
var _NW_STORES = { flavor: null, aroma: null };

(function(){
  // Init two stores
  function cloneStore(){
    var SEL = {};
    // minimal clone of STORE API pointing to same FLAVORS
    return {
      SEL: function(){ return SEL; },
      toggle: STORE.toggle,
      isSel: function(e){ return !!SEL[STORE.pathId ? STORE.pathId(e) : (e.catId+(e.subId?'.'+e.subId:'')+(e.noteId?'.'+e.noteId:''))]; },
      reset: function(){ for(var k in SEL) delete SEL[k]; if(window.APP_RENDER) window.APP_RENDER(); },
      total: function(){ return Object.keys(SEL).length; },
      list: function(){ return Object.values(SEL); },
      grouped: STORE.grouped,
      label: STORE.label,
    };
  }

  // After original STORE is ready, snapshot it as flavor store, create aroma store
  function initTabs(){
    if(!window.STORE){ setTimeout(initTabs, 100); return; }
    _NW_STORES.flavor = window.STORE; // original STORE = flavor
    // Create separate SEL for aroma
    var _aSEL = {};
    _NW_STORES.aroma = Object.assign({}, window.STORE, {
      SEL: function(){ return _aSEL; },
    });
  }
  initTabs();
})();

window.nwSwitchTab = function(tab){
  _NW_TAB = tab;
  if(window.STORE && window.STORE.setTab) window.STORE.setTab(tab);
  // Update tab buttons
  var bf = document.getElementById('nw-tab-flavor');
  var ba = document.getElementById('nw-tab-aroma');
  if(bf&&ba){
    var onF = 'linear-gradient(160deg,#6bb8f0,#3a8fd6)';
    var onA = 'linear-gradient(160deg,#7ec98a,#4da85e)';
    var off = 'none';
    bf.style.background = tab==='flavor'?onF:off;
    bf.style.color = tab==='flavor'?'#0a1a2e':'var(--txt3)';
    ba.style.background = tab==='aroma'?onA:off;
    ba.style.color = tab==='aroma'?'#0d1f0f':'var(--txt3)';
  }
  window.VIEW.active = null; window.VIEW.activeSub = null;
  if(window.APP_RENDER) window.APP_RENDER();
};

window.nwGetFlavors = function(){
  if(window.STORE && window.STORE.labelsFor) return window.STORE.labelsFor('flavor');
  return [];
};
window.nwGetAroma = function(){
  if(window.STORE && window.STORE.labelsFor) return window.STORE.labelsFor('aroma');
  return [];
};
window.nwResetAll = function(){
  if(window.STORE && window.STORE.resetAll) window.STORE.resetAll();
  if(window.nwSwitchTab) window.nwSwitchTab('flavor');
};

/* Виставляє вже вибрані ноти в колесі перед редагуванням */
window.nwSetSelected = function(flavors, aroma){
  if(!window.STORE || !window.FLAT_NOTES) return;
  // Спочатку скидаємо
  if(window.STORE.resetAll) window.STORE.resetAll();

  function applyLabels(labels, tab){
    if(!labels || !labels.length) return;
    if(window.nwSwitchTab) window.nwSwitchTab(tab);
    labels.forEach(function(label){
      // Шукаємо ноту в FLAT_NOTES за назвою
      var found = window.FLAT_NOTES.find(function(f){
        return f.note === label;
      });
      if(found){
        // Виставляємо як вибрану — через toggle (вона зараз не вибрана після reset)
        window.STORE.toggle(found.cat.id, found.sub.id, found.note);
      }
    });
  }

  applyLabels(flavors, 'flavor');
  applyLabels(aroma, 'aroma');
  // Повертаємо на flavor tab
  if(window.nwSwitchTab) window.nwSwitchTab('flavor');
};

function fwReset(){RS._fwSel={_active:null,_activeSub:null,sel:{}};fwRender('fw');}
function awReset(){RS._awSel={_active:null,_activeSub:null,sel:{}};fwRender('aw');}
function buildAromaButtons(){}
