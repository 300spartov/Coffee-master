/* ══════════════════════════════════════════
   ПРОФІЛЬ v2 — XP, РІВНІ, АЧІВКИ, СТАТИСТИКА
══════════════════════════════════════════ */

/* XP & РІВНІ */
function calcXpForLevel(lvl){
  if(lvl<=1)return 0;
  if(lvl<=4)return Math.round(80+(lvl-2)*40);
  if(lvl<=12)return Math.round(200+(lvl-5)*55);
  var base=200+(12-5)*55;
  return Math.round(base*Math.pow(1.18,lvl-12));
}
function cumXpTo(lvl){var cum=0;for(var i=2;i<=lvl;i++)cum+=calcXpForLevel(i);return cum;}
function getLevelFromXp(xp){
  var lvl=1;
  while(lvl<88){var cumNext=cumXpTo(lvl+1);if(xp<cumNext)break;lvl++;}
  return Math.min(lvl,88);
}
var TIERS=[
  {name:'Зернятко',range:[1,4]},{name:'Новачок',range:[5,10]},
  {name:'Аматор',range:[11,18]},{name:'Любитель',range:[19,28]},
  {name:'Знавець',range:[29,40]},{name:'Гуру',range:[41,54]},
  {name:'Майстер',range:[55,66]},{name:'Меломан',range:[67,76]},
  {name:'Сектант',range:[77,84]},{name:'Легенда',range:[85,88]}
];
function getTier(lvl){return TIERS.find(function(t){return lvl>=t.range[0]&&lvl<=t.range[1];})||TIERS[0];}

/* XP нарахування при збереженні заварювання */
function computeTotalXp(target){
  target = target || S;
  var brewXp = (target.brews||[]).length * 15;
  var achXp = 0;
  var defs = buildAchievements();
  defs.forEach(function(a){
    if(target.achEarned && target.achEarned[a.id]) achXp += (a.xp||0);
  });
  return brewXp + achXp;
}
function addBrewXp(mode, methodName, brewId){
  if(!S.xp)S.xp=0;
  var oldLvl=getLevelFromXp(S.xp);
  var oldXp=S.xp;
  checkAchievements(true); /* позначити нові ачівки, без перерахунку — самі XP перерахуємо одразу нижче разом з рецептом */
  S.xp=computeTotalXp();
  var gained=S.xp-oldXp;
  save();
  var newLvl=getLevelFromXp(S.xp);
  var isEsp=(mode==='esp');
  var badgeId=isEsp?'esp-xp-badge':'brew-xp-badge';
  var valId=isEsp?'esp-xp-val':'brew-xp-val';
  var lvlId=isEsp?'esp-lvlup-badge':'brew-lvlup-badge';
  var lvlValId=isEsp?'esp-lvlup-val':'brew-lvlup-val';
  var badge=document.getElementById(badgeId);
  var valEl=document.getElementById(valId);
  var lvlBadge=document.getElementById(lvlId);
  var lvlVal=document.getElementById(lvlValId);
  if(valEl) valEl.textContent='+'+gained+' XP';
  if(badge){ badge.classList.remove('show'); void badge.offsetWidth; setTimeout(function(){badge.classList.add('show');},80); }
  if(newLvl>oldLvl && lvlBadge && lvlVal){
    lvlBadge.style.display='inline-flex';
    lvlVal.textContent='Рівень '+newLvl+' — '+getTier(newLvl).name;
    lvlBadge.classList.remove('show'); void lvlBadge.offsetWidth;
    setTimeout(function(){lvlBadge.classList.add('show');},200);
  } else if(lvlBadge){ lvlBadge.style.display='none'; lvlBadge.classList.remove('show'); }
  return {gained:gained, leveledUp:(newLvl>oldLvl), newLevel:newLvl, tierName:(newLvl>oldLvl?getTier(newLvl).name:'')};
}
