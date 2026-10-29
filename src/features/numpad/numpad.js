/* ── NUMPAD ── */
var _npTarget='',_npMode='',_npVal='';
function openNumPad(sliderId,mode){
  _npTarget=sliderId;_npMode=mode;
  var sl=document.getElementById(sliderId)||{};
  if(mode==='clicks')_npVal=String(document.getElementById('clicks-val').textContent||'28');
  else if(mode==='alt-temp')_npVal=String((sl.value||93)).replace(/[^\d.]/g,'');
  else if(mode==='esp-temp')_npVal=String((sl.value||93)).replace(/[^\d.]/g,'');
  else if(mode==='dose')_npVal=String(document.getElementById('b-dose').value||'16');
  else if(mode==='ratio')_npVal=String(document.getElementById('b-ratio').value||'16');
  else if(mode==='vol')_npVal=String(document.getElementById('lb-vol').value||'240');
  else if(mode==='pour-ml')_npVal=String(sl.value||'0');
  else if(mode==='esp-dose')_npVal=String(document.getElementById('b-esp-dose').value||'18');
  else if(mode==='esp-ratio')_npVal=String(document.getElementById('b-esp-ratio-sel').value||'2.0');
  else if(mode==='esp-yield')_npVal=String(document.getElementById('esp-actual-yield').value||'0');
  else if(mode==='esp-tds')_npVal=String(sl.value||'0');
  else if(mode==='milk-temp')_npVal=String(document.getElementById('em-milk-temp').value||'60');
  else if(mode==='esp-res-time')_npVal=String(espSec||0);
  else if(mode==='edit-esp-time')_npVal=String(document.getElementById('edit-esp-time').value||'0');
  else if(mode==='milk-vol')_npVal=String(document.getElementById('em-milk-vol').value||'150');
  else if(mode==='ice-amt')_npVal=String(document.getElementById('em-ice-amount').value||'4');
  _npRefresh();
  var ov=document.getElementById('ov-numpad');
  ov.style.display='flex';
  requestAnimationFrame(function(){ov.classList.add('open');});
}
function closeNumPad(){
  var ov=document.getElementById('ov-numpad');
  ov.classList.remove('open');
  setTimeout(function(){ov.style.display='none';},220);
}
function _npRefresh(){
  var d=document.getElementById('np-display');if(!d)return;
  var suffix=_npMode==='clicks'?' кл.':_npMode==='dose'||_npMode==='esp-dose'?' г':_npMode==='ratio'||_npMode==='esp-ratio'?'':_npMode==='esp-tds'?'%':_npMode==='ice-amt'?' шт':(_npMode==='esp-res-time'||_npMode==='edit-esp-time')?' с':(_npMode==='vol'||_npMode==='pour-ml'||_npMode==='esp-yield'||_npMode==='milk-vol')?' мл':" °C";
  d.textContent=(_npVal||'—')+suffix;
}
function npKey(k){
  if(k==='del'){_npVal=_npVal.slice(0,-1);}
  else if(k==='.'){if(_npMode==='clicks')return;if(_npVal.indexOf('.')===-1)_npVal+='.';}
  else{if(_npVal.length>=5)return;_npVal+=String(k);}
  _npRefresh();
}
function npConfirm(){
  var v=parseFloat(_npVal);if(isNaN(v)){closeNumPad();return;}
  if(_npMode==='alt-temp'){
    v=Math.max(80,Math.min(100,Math.round(v)));
    var sl=document.getElementById('b-temp-sl');
    if(sl){sl.value=v;document.getElementById('b-temp-out').textContent=v+'°C';}
  } else if(_npMode==='esp-temp'){
    v=Math.max(88,Math.min(96,Math.round(v*2)/2));
    var sl2=document.getElementById('b-esp-temp-sl');
    if(sl2){sl2.value=v;document.getElementById('b-esp-temp-out').textContent=parseFloat(v).toFixed(1)+'°C';}
  } else if(_npMode==='clicks'){
    v=Math.max(1,Math.min(200,Math.round(v)));
    BS.clicks=v;
    var cv=document.getElementById('clicks-val');if(cv)cv.textContent=v;
  } else if(_npMode==='dose'){
    v=Math.max(1,Math.min(300,v));
    document.getElementById('b-dose').value=v;
    bCalc();
  } else if(_npMode==='ratio'){
    v=Math.round(Math.max(1,Math.min(30,v))*10)/10;
    document.getElementById('b-ratio').value=v;
    bCalc();
  } else if(_npMode==='vol'){
    v=Math.max(10,Math.min(1000,Math.round(v)));
    document.getElementById('lb-vol').value=v;
  } else if(_npMode==='pour-ml'){
    v=Math.max(0,Math.round(v*10)/10);
    var inp=document.getElementById(_npTarget);
    if(inp)inp.value=v.toFixed(1);
    var idx=parseInt(String(_npTarget).replace('em-',''),10);
    if(!isNaN(idx))bEditMl(idx);
  } else if(_npMode==='esp-dose'){
    v=Math.max(1,Math.min(30,v));
    document.getElementById('b-esp-dose').value=v;
    if(typeof bEspCalc==='function')bEspCalc();
  } else if(_npMode==='esp-ratio'){
    v=Math.round(Math.max(1,Math.min(5,v))*10)/10;
    document.getElementById('b-esp-ratio-sel').value=v.toFixed(1);
    if(typeof bEspCalc==='function')bEspCalc();
  } else if(_npMode==='esp-yield'){
    v=Math.max(0,Math.round(v*10)/10);
    document.getElementById('esp-actual-yield').value=v;
    var yieldInp=document.getElementById('esp-actual-yield');
    if(yieldInp&&yieldInp.oninput)yieldInp.oninput();
  } else if(_npMode==='esp-tds'){
    v=Math.max(0,Math.min(20,Math.round(v*10)/10));
    var tdsInp=document.getElementById(_npTarget);
    if(tdsInp)tdsInp.value=v;
  } else if(_npMode==='milk-temp'){
    v=Math.max(0,Math.min(90,Math.round(v)));
    document.getElementById('em-milk-temp').value=v;
  } else if(_npMode==='milk-vol'){
    v=Math.max(0,Math.min(600,Math.round(v)));
    document.getElementById('em-milk-vol').value=v;
  } else if(_npMode==='ice-amt'){
    v=Math.max(0,Math.min(30,Math.round(v)));
    document.getElementById('em-ice-amount').value=v;
  } else if(_npMode==='esp-res-time'){
    v=Math.max(0,Math.min(180,Math.round(v)));
    espSec=v;
    var secDiv=document.getElementById('esp-res-sec');
    if(secDiv)secDiv.textContent=v+'с';
    var lblDiv=document.getElementById('esp-res-time-lbl');
    if(lblDiv)lblDiv.textContent='Час проливу: '+v+' секунд';
  } else if(_npMode==='edit-esp-time'){
    v=Math.max(0,Math.min(180,Math.round(v)));
    document.getElementById('edit-esp-time').value=v;
  }
  closeNumPad();
}
