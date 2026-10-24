/* АЧІВКИ */
function buildAchievements(){
  var st=getProfileStats();
  return[
    {id:'brew_1',cat:'Заварювання',icon:'ti-coffee',name:'Перше заварювання',desc:'Перший запис у щоденнику',xp:25,check:function(){return st.brews>=1;},progress:function(){return{cur:Math.min(st.brews,1),max:1};}},
    {id:'brew_50',cat:'Заварювання',icon:'ti-coffee',name:'Піввотні',desc:'50 заварювань',xp:75,check:function(){return st.brews>=50;},progress:function(){return{cur:Math.min(st.brews,50),max:50};}},
    {id:'brew_100',cat:'Заварювання',icon:'ti-coffee',name:'Ціла сотня',desc:'100 заварювань',xp:150,check:function(){return st.brews>=100;},progress:function(){return{cur:Math.min(st.brews,100),max:100};}},
    {id:'brew_500',cat:'Заварювання',icon:'ti-crown',name:'Кавовий архів',desc:'500 заварювань',xp:300,check:function(){return st.brews>=500;},progress:function(){return{cur:Math.min(st.brews,500),max:500};}},
    {id:'streak_7',cat:'Серії',icon:'ti-flame',name:'Кавовий тиждень',desc:'7 днів поспіль',xp:50,check:function(){return st.streak>=7;},progress:function(){return{cur:Math.min(st.streak,7),max:7};}},
    {id:'streak_30',cat:'Серії',icon:'ti-flame',name:'Місяць кави',desc:'30 днів поспіль',xp:150,check:function(){return st.streak>=30;},progress:function(){return{cur:Math.min(st.streak,30),max:30};}},
    {id:'streak_90',cat:'Серії',icon:'ti-calendar',name:'Квартал кавоман',desc:'90 днів без пропуску',xp:300,check:function(){return st.streak>=90;},progress:function(){return{cur:Math.min(st.streak,90),max:90};}},
    {id:'streak_365',cat:'Серії',icon:'ti-award',name:'Кавовий сектант',desc:'365 днів. Ти вже культ.',xp:1000,check:function(){return st.streak>=365;},progress:function(){return{cur:Math.min(st.streak,365),max:365};}},
    {id:'pack_1',cat:'Пачки',icon:'ti-package',name:'Перша пачка',desc:'Перший крок у безодню',xp:20,check:function(){return st.packs>=1;},progress:function(){return{cur:Math.min(st.packs,1),max:1};}},
    {id:'pack_5',cat:'Пачки',icon:'ti-package',name:"П'ять пачок",desc:'Тебе вже не зупинити',xp:50,check:function(){return st.packs>=5;},progress:function(){return{cur:Math.min(st.packs,5),max:5};}},
    {id:'pack_10',cat:'Пачки',icon:'ti-packages',name:'10 пачок',desc:'Ти точно кавоман',xp:100,check:function(){return st.packs>=10;},progress:function(){return{cur:Math.min(st.packs,10),max:10};}},
    {id:'espresso_10',cat:t('method_esp'),icon:'ti-coffee',name:'Еспресо-новачок',desc:'10 чашок еспресо',xp:25,check:function(){return(st.methodCount[t('method_esp')]||0)+(st.methodCount['Espresso']||0)>=10;},progress:function(){var c=(st.methodCount[t('method_esp')]||0)+(st.methodCount['Espresso']||0);return{cur:Math.min(c,10),max:10};}},
    {id:'espresso_100',cat:t('method_esp'),icon:'ti-star',name:'Еспресо-гуру',desc:'100 чашок еспресо',xp:150,check:function(){return(st.methodCount[t('method_esp')]||0)+(st.methodCount['Espresso']||0)>=100;},progress:function(){var c=(st.methodCount[t('method_esp')]||0)+(st.methodCount['Espresso']||0);return{cur:Math.min(c,100),max:100};}},
    {id:'filter_50',cat:'Фільтр',icon:'ti-droplet',name:'Фільтр-любитель',desc:'50 чашок фільтр-кави',xp:75,check:function(){var c=(st.methodCount['V60']||0)+(st.methodCount['Chemex']||0)+(st.methodCount['Альтернатива']||0);return c>=50;},progress:function(){var c=(st.methodCount['V60']||0)+(st.methodCount['Chemex']||0)+(st.methodCount['Альтернатива']||0);return{cur:Math.min(c,50),max:50};}},
    {id:'dev_1',cat:'Девайси',icon:'ti-tool',name:'Перший девайс',desc:'Додав перший пристрій',xp:20,check:function(){return st.equipment>=1;},progress:function(){return{cur:Math.min(st.equipment,1),max:1};}},
    {id:'dev_5',cat:'Девайси',icon:'ti-tool',name:'Колекціонер',desc:'5 пристроїв в арсеналі',xp:50,check:function(){return st.equipment>=5;},progress:function(){return{cur:Math.min(st.equipment,5),max:5};}},
    {id:'dev_10',cat:'Девайси',icon:'ti-tool',name:'Справжній арсенал',desc:'10 пристроїв',xp:100,check:function(){return st.equipment>=10;},progress:function(){return{cur:Math.min(st.equipment,10),max:10};}},
    {id:'avg_8',cat:'Якість',icon:'ti-chart-bar',name:'Висока планка',desc:'Середня оцінка 8.0+',xp:100,check:function(){return st.avgRating>=8.0;},progress:function(){return{cur:Math.min(+(st.avgRating.toFixed(1)),8),max:8};}},
    {id:'avg_9',cat:'Якість',icon:'ti-crown',name:'Золоті руки',desc:'Середня оцінка 9.0+',xp:300,check:function(){return st.avgRating>=9.0;},progress:function(){return{cur:Math.min(+(st.avgRating.toFixed(1)),9),max:9};}},
  ];
}

function checkAchievements(markOnly){
  if(!S.achEarned) S.achEarned={};
  var defs=buildAchievements();
  var newlyEarned=false;
  defs.forEach(function(a){
    if(!S.achEarned[a.id]&&a.check()){
      S.achEarned[a.id]=Date.now();
      newlyEarned=true;
    }
  });
  if(newlyEarned && !markOnly){
    S.xp=computeTotalXp();
  }
}

/* РЕНДЕР АЧІВОК */
function renderAchievements(){
  if(!S.achEarned)S.achEarned={};
  var defs=buildAchievements();
  var earnedIds=Object.keys(S.achEarned);
  var total=defs.length,earned=earnedIds.length;
  var ec=document.getElementById('ach-earned-count');if(ec)ec.textContent=earned;
  var tc=document.getElementById('ach-total-count');if(tc)tc.textContent=total;
  var he=document.getElementById('hero-earned');if(he)he.textContent=earned;
  var ht=document.getElementById('hero-total');if(ht)ht.textContent=total;
  var hf=document.getElementById('hero-fill');if(hf)hf.style.width=Math.round(earned/total*100)+'%';
  var cats={};
  defs.forEach(function(a){if(!cats[a.cat])cats[a.cat]=[];cats[a.cat].push(a);});
  var html='<div style="height:4px"></div>';
  Object.entries(cats).forEach(function(entry){
    var cat=entry[0],items=entry[1];
    html+='<div class="ach-section"><div class="ach-section-lbl">'+cat+'</div><div class="ach-list">';
    items.forEach(function(a){
      var done=earnedIds.includes(a.id);
      var prog=a.progress();
      var pctBar=done?100:Math.round(prog.cur/prog.max*100);
      var progressLabel=done?t('ach_received')+' ✓':prog.cur+' / '+prog.max;
      html+='<div class="ach-card'+(done?' earned':prog.cur===0?' locked':'') + '">'
        +'<div class="ach-card-top">'
        +'<div class="ach-card-icon '+(done?'copper':prog.cur>0?'steel':'dim')+'"><i class="ti '+a.icon+'"></i></div>'
        +'<div class="ach-card-body"><div class="ach-card-name">'+a.name+'</div><div class="ach-card-desc">'+a.desc+'</div></div>'
        +'<div class="ach-card-right"><div class="ach-card-status '+(done?'done':'prog')+'">'+(done?'✓':'+'+a.xp+' XP')+'</div></div>'
        +'</div>'
        +'<div class="ach-prog-row"><span class="ach-prog-lbl">'+progressLabel+'</span>'
        +(!done?'<span class="ach-prog-val">'+pctBar+'%</span>':'')+'</div>'
        +'<div class="ach-card-bar"><div class="ach-card-bar-fill'+(done?' full':'')+'" style="width:'+pctBar+'%"></div></div>'
        +'</div>';
    });
    html+='</div></div>';
  });
  var achScr=document.getElementById('ach-scr');if(achScr)achScr.innerHTML=html;
}

/* Роутинг для ачівок */
function showScrAch(){showScr('scr-ach');}
