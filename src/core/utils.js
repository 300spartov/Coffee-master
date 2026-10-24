/* ══════════════════════════════════════ */

/* ── Колір рейтингу за значенням ── */
function ratingColor(v){
  if(v>=8.0) return {num:'#5fbf83',thumb:'#5fbf83',glow:'rgba(95,191,131,.45)'};
  if(v>=6.5) return {num:'#b9c64f',thumb:'#b9c64f',glow:'rgba(185,198,79,.45)'};
  if(v>=5.0) return {num:'#e2c64c',thumb:'#e2c64c',glow:'rgba(226,198,76,.45)'};
  if(v>=3.5) return {num:'#ea9b3c',thumb:'#ea9b3c',glow:'rgba(234,155,60,.45)'};
  return       {num:'#ea6a52',thumb:'#ea6a52',glow:'rgba(234,106,82,.45)'};
}
function applyRatingColor(numId,sliderId,v){
  var c=ratingColor(v);
  var n=document.getElementById(numId); if(n){n.style.color=c.num;n.style.textShadow='0 0 26px '+c.glow;}
  var s=document.getElementById(sliderId); if(s)s.style.setProperty('--thumb-color',c.thumb);
}

function fmt(ms){const s=Math.floor(ms/1000),m=Math.floor(s/60),sc=s%60;return m+':'+(sc<10?'0':'')+sc}
function toast(msg){const t=document.getElementById('toast');t.textContent=msg;t.classList.add('on');setTimeout(()=>t.classList.remove('on'),2500)}
