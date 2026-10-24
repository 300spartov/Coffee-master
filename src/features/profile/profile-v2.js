/* СТАТИСТИКА / СТРІК */
function calcStreakV2(){
  var days=new Set((S.log||[]).map(function(e){var d=new Date(e.ts);return d.getFullYear()+'-'+(d.getMonth()+1)+'-'+d.getDate();}));
  var streak=0,d=new Date();
  while(true){var k=d.getFullYear()+'-'+(d.getMonth()+1)+'-'+d.getDate();if(!days.has(k))break;streak++;d.setDate(d.getDate()-1);}
  return streak;
}
function getProfileStats(){
  var brews=S.brews||[];var log=S.log||[];
  var streak=calcStreak(); /* uses the one correct calcStreak with grace period */
  var methodCount={};
  brews.forEach(function(b){var m=b.method||'Other';methodCount[m]=(methodCount[m]||0)+1;});
  var packs=(S.beans||[]).length;
  var shared=brews.filter(function(b){return b.likes>0||b.shared;}).length;
  var totalGrams=brews.reduce(function(s,b){var d=parseFloat(b.dose);return s+(isNaN(d)?16:d);},0);
  var ratings=brews.filter(function(b){return b.rating;}).map(function(b){return parseFloat(b.rating);});
  var avgRating=ratings.length?ratings.reduce(function(a,b){return a+b;},0)/ratings.length:0;
  return{brews:brews.length,streak:streak,packs:packs,shared:shared,totalGrams:totalGrams,avgRating:avgRating,equipment:(S.equipment||[]).length,methodCount:methodCount};
}

/* РЕНДЕР ПРОФІЛЮ v2 */
function renderProfile(){
  if(!S.xp)S.xp=0;
  if(!S.xpLog)S.xpLog=[];
  if(!S.achEarned)S.achEarned={};
  checkAchievements(true);
  applyLangToDOM();
  var xp=S.xp;
  var lvl=getLevelFromXp(xp);
  var tier=getTier(lvl);
  var cumCur=cumXpTo(lvl);
  var needNext=lvl<88?calcXpForLevel(lvl+1):1;
  var inLevel=xp-cumCur;
  var pct=Math.min(Math.round(inLevel/needNext*100),100);
  var st=getProfileStats();
  var daysEst=needNext>0?Math.round((needNext-inLevel)/Math.max(st.brews>0?5:2,1)):999;

  var name=(S.profile&&S.profile.name)||'?';
  var av=document.getElementById('pr-av');if(av){av.textContent=(S.profile&&S.profile.avEmoji)||name[0].toUpperCase();av.style.fontSize=(S.profile&&S.profile.avEmoji)?'24px':'21px';if(S.profile&&S.profile.avColor)av.style.background=S.profile.avColor;}
  var pn=document.getElementById('pr-name');if(pn)pn.textContent=name;
  var pe=document.getElementById('pr-era');if(pe)pe.textContent=tier.name;
  var pl=document.getElementById('pr-lvl');if(pl)pl.textContent=lvl;
  var px=document.getElementById('pr-xp');if(px)px.textContent=xp.toLocaleString('uk-UA')+' XP';
  var pnl=document.getElementById('pr-nextlvl');if(pnl)pnl.textContent=lvl+1;
  var pd=document.getElementById('pr-xp-detail');if(pd)pd.textContent=inLevel.toLocaleString('uk-UA')+' / '+needNext.toLocaleString('uk-UA')+' XP';
  var pb=document.getElementById('pr-xp-bar');if(pb)pb.style.width=pct+'%';
  var pxl=document.getElementById('pr-xp-left');if(pxl)pxl.textContent=(needNext-inLevel).toLocaleString('uk-UA')+' XP';
  var pxd=document.getElementById('pr-xp-days');if(pxd)pxd.textContent='~'+daysEst+' '+t('profile_days');
  var CIRC=175.9;
  var ring=document.getElementById('av-ring');if(ring)ring.setAttribute('stroke-dashoffset',(CIRC*(1-pct/100)).toFixed(1));
  var pst=document.getElementById('pr-streak-top');if(pst)pst.textContent=st.streak;
  var pdn=document.getElementById('pdate-num');if(pdn)pdn.textContent=st.streak;
  var sb=document.getElementById('st-brews');if(sb)sb.textContent=st.brews;
  var sk=document.getElementById('st-kg');if(sk)sk.textContent=(st.totalGrams/1000).toFixed(1);
  var skm=document.getElementById('st-kg-month');
  if(skm){var stm=getCoffeeWeightStats('month');skm.textContent=(stm.total/1000).toFixed(1);}
  var sa=document.getElementById('st-ach');if(sa)sa.textContent=Object.keys(S.achEarned).length;
  var sd=document.getElementById('st-devs');if(sd)sd.textContent=st.equipment;
  var tc=document.getElementById('trophy-count');if(tc)tc.textContent=Object.keys(S.achEarned).length;

  // Нещодавні ачівки чіпи
  var defs=buildAchievements();
  var earnedIds=Object.keys(S.achEarned);
  var earnedDefs=defs.filter(function(a){return earnedIds.includes(a.id);}).slice(-2);
  var inProgress=defs.filter(function(a){return!earnedIds.includes(a.id);})
    .map(function(a){return{a:a,p:a.progress()};}).filter(function(x){return x.p.cur>0;})
    .sort(function(x,y){return y.p.cur/y.p.max-x.p.cur/x.p.max;}).slice(0,2).map(function(x){return x.a;});
  var chips=earnedDefs.concat(inProgress).slice(0,4);
  var achRow=document.getElementById('pr-ach-row');
  if(achRow)achRow.innerHTML=chips.map(function(a){
    var done=earnedIds.includes(a.id);
    var prog=a.progress();
    var pctBar=done?100:Math.round(prog.cur/prog.max*100);
    return'<div class="ach-chip'+(done?' earned':'') + '" onclick="showScr(\'scr-ach\')">'
      +'<i class="ti '+a.icon+' ach-icon '+(done?'done':'locked')+'"></i>'
      +'<div class="ach-name'+(done?'':' locked')+'">'+a.name+'</div>'
      +'<div class="ach-bar"><div class="ach-bar-fill'+(done?' full':'')+'" style="width:'+pctBar+'%"></div></div>'
      +'</div>';
  }).join('');
}
// alias for showScr fn map
function renderProf(){ renderProfile(); }

var _prOpen=true;
function toggleProfileV2(){
  _prOpen=!_prOpen;
  var c=document.getElementById('pr-collapse');if(c)c.classList.toggle('open',_prOpen);
  var ch=document.getElementById('pr-chev');if(ch)ch.classList.toggle('open',_prOpen);
  var btn=document.getElementById('pr-toggle-btn');if(btn)btn.setAttribute('aria-expanded',_prOpen);
}

var _profCalOpen = false;
function toggleProfCalV2(){
  _profCalOpen = !_profCalOpen;
  var body = document.getElementById('prof-cal-body');
  var chev = document.getElementById('prof-cal-chev');
  if(body){ body.style.maxHeight = _profCalOpen ? body.scrollHeight+300+'px' : '0'; body.style.opacity = _profCalOpen ? '1' : '0'; }
  if(chev) chev.style.transform = _profCalOpen ? 'rotate(180deg)' : '';
  if(_profCalOpen) setTimeout(function(){ renderCalendar(); }, 50);
}
