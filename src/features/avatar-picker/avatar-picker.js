/* ── AVATAR PICKER ── */
var AV_EMOJIS = ['☕','🫖','🌱','⚡','🔥','🏆','✨','💎','🎯','🌙','❄️','🍊','🍋','🫐','🌸','🎸','🦁','🐺','🌊','🏔️','🎨','🚀','🦊','🐻'];
var AV_COLORS = ['#2a1e10','#0d1f1a','#151e27','#1a1215','#1a1a2e','#0d1a0d','#2a1010','#1a1a1a'];

function openAvPicker(){
  var grid = document.getElementById('av-emoji-grid');
  var curEmoji = (S.profile&&S.profile.avEmoji)||'';
  if(grid){
    grid.innerHTML='';
    AV_EMOJIS.forEach(function(e){
      var btn=document.createElement('button');
      btn.className='av-emoji-btn'+(e===curEmoji?' selected':'');
      btn.textContent=e;
      btn.onclick=function(){ pickAvEmoji(e); };
      grid.appendChild(btn);
    });
  }
  var row = document.getElementById('av-color-row');
  var curColor = (S.profile&&S.profile.avColor)||'#2a1e10';
  if(row){
    row.innerHTML='';
    AV_COLORS.forEach(function(c){
      var d=document.createElement('div');
      d.className='av-color-btn'+(c===curColor?' selected':'');
      d.style.background=c;
      d.onclick=function(){ pickAvColor(c); };
      row.appendChild(d);
    });
  }
  var ov = document.getElementById('av-picker');
  if(ov) ov.classList.add('open');
}

function closeAvPicker(){
  var ov = document.getElementById('av-picker');
  if(ov) ov.classList.remove('open');
}

function pickAvEmoji(emoji){
  if(!S.profile) S.profile={};
  S.profile.avEmoji = emoji;
  save(); applyAvatar();
  // Update grid selection
  var grid = document.getElementById('av-emoji-grid');
  if(grid) grid.querySelectorAll('.av-emoji-btn').forEach(function(b){
    b.classList.toggle('selected', b.textContent===emoji);
  });
}

function pickAvColor(color){
  if(!S.profile) S.profile={};
  S.profile.avColor = color;
  save(); applyAvatar();
  var row = document.getElementById('av-color-row');
  if(row) row.querySelectorAll('.av-color-btn').forEach(function(b){
    b.classList.toggle('selected', b.style.background===color||b.style.backgroundColor===color);
  });
}

function applyAvatar(){
  var p = S.profile||{};
  var avEl = document.getElementById('pr-av');
  if(!avEl) return;
  if(p.avEmoji){
    avEl.textContent = p.avEmoji;
    avEl.style.fontSize = '24px';
  } else {
    var name = p.name||'?';
    avEl.textContent = name[0].toUpperCase();
    avEl.style.fontSize = '21px';
  }
  if(p.avColor) avEl.style.background = p.avColor;
}
