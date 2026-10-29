/* ── СЕРИЯ + КАЛЕНДАРЬ ── */
function methodCat(m){m=(m||'').toLowerCase();if(m.includes('еспрес')||m.includes('espres'))return 'espresso';if(m.includes('aero')||m.includes('аеро')||m.includes('френч')||m.includes('гейзер')||m.includes('турка')||m.includes('пресс'))return 'other';return 'filter';}
function getRoastType(method){
  if(!method)return'filter';
  var m=method.toLowerCase();
  if(m.indexOf('espresso')>-1||m.indexOf('еспресо')>-1||m.indexOf('cappuccino')>-1||m.indexOf('капучино')>-1||m.indexOf('flat white')>-1||m.indexOf('latte')>-1||m.indexOf('латте')>-1||m.indexOf('bumble')>-1||m.indexOf('tonic')>-1||m.indexOf('тонік')>-1)return'espresso';
  if(m.indexOf('omni')>-1||m.indexOf('омні')>-1)return'omni';
  return'filter';
}
/* ── Живі посилання: якщо назву змінили в Девайси/Зерно — старі рецепти підхоплюють нову ── */
function liveDeviceName(id, fallbackName){
  if(id!=null){
    var item=S.equipment.find(function(x){return x.id===id;});
    if(item)return item.name;
  }
  if(fallbackName){
    var fb=(''+fallbackName).trim().toLowerCase();
    var match=S.equipment.find(function(x){return (''+x.name).trim().toLowerCase()===fb;});
    if(match)return match.name;
  }
  return fallbackName||'';
}
function liveBeanInfo(id, fallbackName, fallbackRoaster){
  var item=null;
  if(id!=null) item=(S.beans||[]).find(function(x){return x.id===id;});
  if(!item&&fallbackName){
    var fn=(''+fallbackName).trim().toLowerCase(), fr=(''+(fallbackRoaster||'')).trim().toLowerCase();
    item=(S.beans||[]).find(function(x){return (''+x.name).trim().toLowerCase()===fn&&(''+(x.roaster||'')).trim().toLowerCase()===fr;});
  }
  return item?{name:item.name,roaster:item.roaster||'',roastType:item.roastType||''}:{name:fallbackName||'',roaster:fallbackRoaster||'',roastType:''};
}
function getCoffeeWeightStats(period){
  var brews=S.brews||[];
  var now=Date.now();
  var cutoff=0;
  if(period==='day')cutoff=now-24*3600*1000;
  else if(period==='week')cutoff=now-7*24*3600*1000;
  else if(period==='month')cutoff=now-30*24*3600*1000;
  /* 'year' та відсутність фільтра — рахувати по всіх S.brews */
  var filtered=cutoff?brews.filter(function(b){return b.ts>=cutoff;}):brews;
  var byType={filter:0,espresso:0,omni:0};
  var total=0;
  filtered.forEach(function(b){
    var dose=parseFloat(b.dose);
    if(isNaN(dose))dose=16;
    var liveBean=liveBeanInfo(b.beanId, b.beanName, b.roaster);
    var type=liveBean.roastType||b.roastType||getRoastType(b.method);
    if(!byType.hasOwnProperty(type))type='filter';
    byType[type]+=dose;
    total+=dose;
  });
  var brewCount=filtered.length;
  var avgDose=brewCount?Math.round(total/brewCount):0;
  return{total:total,byType:byType,brewCount:brewCount,avgDose:avgDose};
}
