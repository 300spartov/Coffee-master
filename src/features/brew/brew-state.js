/* ── BREW STATE ── */
let BS={bean:null,filter:null,dripper:null,grinder:null,espMachine:null,accessories:[],clicks:28,wet:true,dose:16,ratio:16,pours:3,mainInt:null,phaseInt:null,pauseInt:null,mainStart:null,phaseStart:null,elapsed:0,phaseMs:0,steps:[],pourCnt:0,phase:'idle',pouredFixed:0,firstDone:false,_pauseStart:null,_pauseLiveInt:null,espMethod:null,espNeedsMilk:false,espNeedsIce:false,milk:null,ice:null};
/* RATING STATE */
let RS={rating:8.0,flavors:[],aroma:[],notes:''};

/* ── МЕТОД ЗАВАРИВАНИЯ ── */
let brewMethod='alt'; // 'alt' | 'esp'

function setBrewMethod(m){
  brewMethod=m;
  const isEsp=m==='esp';
  /* B2: перемикач видалено — кнопки bm-alt/bm-esp більше не існують */
  // Заголовок
  document.getElementById('brew-title').textContent=isEsp?'Заварювання':'Заварювання';
  /* B2: ховаємо Normal/Inverted при переключенні методу */
  const _ao=document.getElementById('b-aeropress-opts');
  if(_ao) _ao.style.display='none';
  // Показ/скрытие карточек
  document.getElementById('bcard-dripper').style.display=isEsp?'none':'block';
  document.getElementById('bcard-filter').style.display=(isEsp||BS.altMethod==='Drip')?'none':'block';
  document.getElementById('bcard-acc').style.display=isEsp?'block':'none';
  document.getElementById('bcard-espmachine').style.display=isEsp?'block':'none';
  document.getElementById('bcard-pours-wrap').style.display=isEsp?'none':'block';
  document.getElementById('bcard-altcalc').style.display=isEsp?'none':'block';
  document.getElementById('bcard-esp-params').style.display=isEsp?'block':'none';
  // Аксесуары — подтягиваем из инвентаря (множинний вибір через BS.accessories)
  if(isEsp){
    renderBaccList();
  }
}
