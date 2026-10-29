/* ══════════════════════════════════════════
   EDIT BREW
   ══════════════════════════════════════════ */
var _editBrewId = null;

function openEditBrew(bid){
  var b = S.brews.find(function(x){return x.id===bid;});
  if(!b) return;
  _editBrewId = bid;

  // Заповнюємо поля
  var rSlider = document.getElementById('edit-rate-slider');
  var rNum = document.getElementById('edit-rate-num');
  var rv = parseFloat(b.rating||8);
  rSlider.value = rv;
  rNum.textContent = rv.toFixed(1);
  applyRatingColor('edit-rate-num','edit-rate-slider', rv);

  document.getElementById('edit-dose').value = parseFloat(b.dose||16);
  document.getElementById('edit-ratio').value = parseFloat(b.ratio||16);
  document.getElementById('edit-temp').value = parseFloat(b.temp||93);
  document.getElementById('edit-notes').value = b.notes||'';

  var _dt = new Date(b.ts||Date.now());
  var _pad = function(n){return (n<10?'0':'')+n;};
  document.getElementById('edit-datetime').value = _dt.getFullYear()+'-'+_pad(_dt.getMonth()+1)+'-'+_pad(_dt.getDate())+'T'+_pad(_dt.getHours())+':'+_pad(_dt.getMinutes());

  // Еспресо-рецепти редагують час проливу окремим полем замість кроків
  var _isEspBrew = !!b.espresso;
  var _espTimeBlock = document.getElementById('edit-esp-time-block');
  var _stepsBlock = document.getElementById('edit-steps-block');
  if(_espTimeBlock) _espTimeBlock.style.display = _isEspBrew ? 'block' : 'none';
  if(_stepsBlock) _stepsBlock.style.display = _isEspBrew ? 'none' : 'block';
  if(_isEspBrew){
    var _curSec = parseInt(b.totalTime) || (b.espresso&&b.espresso.shotTime) || 0;
    document.getElementById('edit-esp-time').value = _curSec;
  }

  // Кроки
  editRenderSteps(b.steps||[]);

  // Переміщуємо колесо смаку/аромату
  var tb = document.getElementById('taste-block');
  var mount = document.getElementById('edit-taste-mount');
  if(tb && mount) mount.appendChild(tb);

  // Виставляємо вже вибрані ноти в колесі
  if(window.nwSetSelected) window.nwSetSelected(b.flavors||[], b.aroma||[]);

  document.getElementById('ov-edit-brew').classList.add('open');
  document.body.style.overflow='hidden';
}

function closeEditBrew(){
  // Повертаємо колесо назад
  var tb = document.getElementById('taste-block');
  var origMount = document.getElementById('alt-taste-mount');
  if(tb && origMount) origMount.appendChild(tb);

  document.getElementById('ov-edit-brew').classList.remove('open');
  document.body.style.overflow='';
  _editBrewId = null;
}

function editRenderSteps(steps){
  var list = document.getElementById('edit-steps-list');
  if(!list) return;
  list.innerHTML = (steps||[]).map(function(st, i){
    var isPour = st.type==='pour';
    var isPause = st.type==='pause';
    var durSec = st.ph!=null ? Math.round(st.ph/1000) : (st.dur||0);
    return '<div style="display:flex;align-items:center;gap:6px;background:var(--card-lo);border-radius:9px;padding:8px 10px" id="edit-step-'+i+'">'
      +'<select onchange="editStepChange('+i+',\'type\',this.value)" style="background:var(--card-hi);border:1px solid var(--line-soft);color:var(--txt);border-radius:6px;padding:5px 6px;font-size:11px;font-family:inherit;cursor:pointer">'
        +'<option value="pour"'+(isPour?' selected':'')+'>Влив</option>'
        +'<option value="pause"'+(isPause?' selected':'')+'>Пауза</option>'
      +'</select>'
      +(isPour ? '<input type="number" placeholder="мл" value="'+(Math.round(st.ml)||0)+'" min="0" max="500" onchange="editStepChange('+i+',\'ml\',+this.value)" style="width:60px;background:var(--card-hi);border:1px solid var(--line-soft);color:var(--txt);border-radius:6px;padding:5px;font-size:12px;font-family:var(--mono);text-align:center">' : '<div style="width:60px"></div>')
      +'<input type="number" placeholder="сек" value="'+durSec+'" min="0" max="999" onchange="editStepChange('+i+',\'dur\',+this.value)" style="width:60px;background:var(--card-hi);border:1px solid var(--line-soft);color:var(--txt);border-radius:6px;padding:5px;font-size:12px;font-family:var(--mono);text-align:center">'
      +'<span style="font-size:10px;color:var(--txt3);font-family:var(--mono)">с</span>'
      +'<button onclick="editRemoveStep('+i+')" style="margin-left:auto;background:none;border:none;color:var(--txt3);cursor:pointer;font-size:16px;padding:2px 4px"><i class="ti ti-trash"></i></button>'
    +'</div>';
  }).join('');
}

function _getEditSteps(){
  var b = S.brews.find(function(x){return x.id===_editBrewId;});
  return b ? (b.steps||[]).map(function(s){return Object.assign({},s);}) : [];
}

function editStepChange(idx, field, val){
  var steps = _getEditSteps();
  if(!steps[idx]) return;
  if(field==='type'){ steps[idx].type=val; editRenderSteps(steps); }
  else if(field==='ml'){ steps[idx].ml=val; }
  else if(field==='dur'){ steps[idx].ph=val*1000; steps[idx].dur=val; }
  // Зберігаємо в brew одразу щоб не загубити
  var b=S.brews.find(function(x){return x.id===_editBrewId;});
  if(b) b.steps=steps;
}

function editAddStep(){
  var steps = _getEditSteps();
  steps.push({type:'pour', ml:50, ph:15000, dur:15, t: steps.length>0 ? (steps[steps.length-1].t||0)+15000 : 0});
  var b=S.brews.find(function(x){return x.id===_editBrewId;});
  if(b) b.steps=steps;
  editRenderSteps(steps);
}

function editRemoveStep(idx){
  var steps = _getEditSteps();
  steps.splice(idx,1);
  var b=S.brews.find(function(x){return x.id===_editBrewId;});
  if(b) b.steps=steps;
  editRenderSteps(steps);
}

function saveEditBrew(){
  var b = S.brews.find(function(x){return x.id===_editBrewId;});
  if(!b) return;

  // Основні поля
  b.rating = Math.round(parseFloat(document.getElementById('edit-rate-slider').value||8)*10)/10;
  b.dose = document.getElementById('edit-dose').value;
  b.ratio = parseFloat(document.getElementById('edit-ratio').value||16).toFixed(1);
  b.temp = document.getElementById('edit-temp').value;
  b.notes = document.getElementById('edit-notes').value.trim();

  // Дата та час створення
  var _dtVal = document.getElementById('edit-datetime').value;
  if(_dtVal){
    var _newTs = new Date(_dtVal).getTime();
    if(!isNaN(_newTs)) b.ts = _newTs;
  }

  // Смак/аромат — читаємо ДО закриття (поки колесо ще в оверлеї)
  b.flavors = (window.nwGetFlavors?window.nwGetFlavors():[]);
  b.aroma = (window.nwGetAroma?window.nwGetAroma():[]);

  // Перераховуємо totalTime зі steps (Альтернатива) або зберігаємо ручний час проливу (Еспресо)
  if(b.espresso){
    var _newSec = parseInt(document.getElementById('edit-esp-time').value) || 0;
    b.totalTime = _newSec+'с';
    b.espresso.shotTime = _newSec;
  } else {
    var steps = b.steps||[];
    var totalMs = steps.reduce(function(s,st){return s+(st.ph!=null?st.ph:(st.dur||0)*1000);},0);
    if(totalMs>0){
      var tsec=Math.round(totalMs/1000), tm=Math.floor(tsec/60), ts=tsec%60;
      b.totalTime=tm+':'+(ts<10?'0':'')+ts;
    }
    b.totalMl = steps.filter(function(s){return s.type==='pour';}).reduce(function(s,st){return s+(st.ml||0);},0);
  }

  // Оновлюємо log
  var logEntry = S.log.find(function(l){return l.id===b.id;});
  if(logEntry){ logEntry.rating=b.rating; logEntry.ts=b.ts; }

  // Дата могла змінитись — перевпорядковуємо і оновлюємо календар/стрік
  S.brews.sort(function(x,y){return (y.ts||0)-(x.ts||0);});
  S.log.sort(function(x,y){return (y.ts||0)-(x.ts||0);});

  save();
  closeEditBrew();
  renderFeed();
  if(typeof renderCalendar==='function')renderCalendar();
  if(typeof renderStreak==='function')renderStreak();
  toast('Рецепт оновлено!');
}
