/* ══════════════════════════════════════════
   MARKETPLACE
   ══════════════════════════════════════════ */
const MKT_COFFEES=[
  {id:1,name:'Ethiopia Shakiso',roaster:'Penyora',country:'Ефіопія',region:'Оромія',station:'Оддо Шакісо',variety:'Heirloom',process:'Natural',roast:'Світла',brew:[t('method_esp'),'Омні'],weight:250,price:490,score:87,sweetness:85,acidity:72,bitterness:12,descriptors:['Персик','Апельсин','Гранат','Порічка','Квіти'],color:'#E8904A',inStock:false,url:'https://specialtycoffee.com.ua/shop/product/f240-espresso-ethiopia-shakiso-espresso'},
  {id:2,name:'Rwanda Gitoki',roaster:'Penyora',country:'Руанда',region:'Північна провінція',station:'Gitoki',variety:'Red Bourbon',process:'Washed',roast:'Світла',brew:['Фільтр','Омні'],weight:250,price:490,score:89,sweetness:82,acidity:70,bitterness:10,descriptors:['Чорна смородина','Кленовий сироп','Банан','Жовті фрукти'],color:'#D06030',inStock:true,url:'https://specialtycoffee.com.ua/shop/product/19bc3-filter-rwanda-gitoki-filter-250g'},
  {id:3,name:'Colombia Decaf',roaster:'Penyora',country:'Колумбія',region:'Уїла',station:null,variety:'Castillo',process:'Sugar Cane Decaf',roast:'Середня',brew:[t('method_esp'),'Омні'],weight:250,price:520,score:85,sweetness:78,acidity:45,bitterness:30,descriptors:['Червоне яблуко','Слива','Молочний шоколад','Какао'],color:'#A07040',inStock:true,url:'https://specialtycoffee.com.ua/shop/66fb3-espresso-colombia-decaf-250g'},
  {id:4,name:'Ethiopia Ayla Bombe',roaster:'Penyora',country:'Ефіопія',region:'Гуджі',station:'Ayla Bombe',variety:'Heirloom',process:'Washed',roast:'Світла',brew:['Фільтр','Омні'],weight:250,price:510,score:90,sweetness:75,acidity:85,bitterness:8,descriptors:['Жасмин','Лимон','Персик','Квітковий чай'],color:'#F0D060',inStock:true,url:'https://specialtycoffee.com.ua/shop'},
  {id:5,name:'Colombia Santa Monica',roaster:'Penyora',country:'Колумбія',region:'Уїла',station:'Santa Monica',variety:'Caturra',process:'Washed',roast:'Середня',brew:[t('method_esp'),'Омні','Фільтр'],weight:1000,price:1590,score:88,sweetness:72,acidity:60,bitterness:32,descriptors:['Карамель','Червоне яблуко','Темний шоколад','Горіх'],color:'#C08040',inStock:true,url:'https://specialtycoffee.com.ua/shop/product/3652e-espresso-colombia-santa-monica-espresso-1000g'},
  {id:6,name:'Salvador Filter',roaster:'Penyora',country:'Сальвадор',region:'Santa Ana',station:null,variety:'Pacamara',process:'Washed',roast:'Світла',brew:['Фільтр'],weight:250,price:460,score:86,sweetness:80,acidity:65,bitterness:15,descriptors:['Жовта слива','Ваніль','Манго','Цедра'],color:'#D4A050',inStock:true,url:'https://specialtycoffee.com.ua/shop'},
  {id:7,name:'Peru Espresso',roaster:'Penyora',country:'Перу',region:'Cajamarca',station:null,variety:'Typica',process:'Washed',roast:'Середня',brew:[t('method_esp'),'Омні'],weight:250,price:440,score:84,sweetness:82,acidity:42,bitterness:38,descriptors:['Молочний шоколад','Коричневий цукор','Горіх',"М'ята"],color:'#B09050',inStock:true,url:'https://specialtycoffee.com.ua/shop'},
  {id:8,name:'Honduras Espresso',roaster:'Penyora',country:'Гондурас',region:'Marcala',station:null,variety:'Catuai',process:'Washed',roast:'Середня',brew:[t('method_esp')],weight:1000,price:1350,score:83,sweetness:78,acidity:38,bitterness:48,descriptors:['Карамель','Темний шоколад','Сухофрукти'],color:'#906030',inStock:true,url:'https://specialtycoffee.com.ua/shop'},
  {id:9,name:'Kenya Kirinyaga',roaster:'Wonder&Full',country:'Кенія',region:'Кіріньяга',station:'Kegwa',variety:'SL-28, SL-34',process:'Washed',roast:'Світла',brew:['Фільтр','Омні'],weight:250,price:580,score:88,sweetness:62,acidity:90,bitterness:10,descriptors:['Чорна смородина','Томат','Грейпфрут','Хібіскус'],color:'#C03820',inStock:true,url:'https://wonderfull.coffee/kava/'},
  {id:10,name:'Kenya Kahuro Gikaru',roaster:'Wonder&Full',country:'Кенія',region:'Мурангʼа',station:'Kahuro Gikaru',variety:'SL-28, Ruiru 11',process:'Washed',roast:'Світла',brew:['Фільтр'],weight:250,price:680,score:87,sweetness:65,acidity:88,bitterness:8,descriptors:['Ягідна солодкість','Квіти','Чорна смородина'],color:'#B02818',inStock:true,url:'https://wonderfull.coffee/kava/'},
  {id:11,name:'Ethiopia Coromii Kochere',roaster:'Wonder&Full',country:'Ефіопія',region:'Єргачеффе',station:'Coromii Kochere',variety:'Heirloom',process:'Washed',roast:'Світла',brew:['Фільтр','Омні'],weight:250,price:520,score:91,sweetness:78,acidity:88,bitterness:10,descriptors:['Жасмин','Бергамот','Персик','Чорний чай'],color:'#E8C060',inStock:true,url:'https://wonderfull.coffee/kava/'},
  {id:12,name:'Ethiopia Yirgacheffe',roaster:'Wonder&Full',country:'Ефіопія',region:'Єргачеффе',station:null,variety:'Heirloom',process:'Natural',roast:'Світла',brew:['Фільтр','Омні'],weight:250,price:490,score:89,sweetness:88,acidity:68,bitterness:8,descriptors:['Чорниця','Полуниця','Троянда','Тропіки'],color:'#C84020',inStock:true,url:'https://wonderfull.coffee/kava/'},
  {id:13,name:'Rwanda Gishyita',roaster:'Wonder&Full',country:'Руанда',region:'Ківу',station:'Gishyita',variety:'Red Bourbon',process:'Washed',roast:'Світла',brew:['Фільтр','Омні'],weight:250,price:500,score:88,sweetness:80,acidity:72,bitterness:12,descriptors:['Слива','Малина','Карамель','Жасмин'],color:'#D07030',inStock:true,url:'https://wonderfull.coffee/kava/'},
  {id:14,name:'Colombia Geisha',roaster:'Wonder&Full',country:'Колумбія',region:'Уїла',station:'Barahona',variety:'Geisha',process:'Washed',roast:'Світла',brew:['Фільтр'],weight:100,price:980,score:94,sweetness:88,acidity:78,bitterness:5,descriptors:['Жасмин','Мандарин','Персик','Нектар'],color:'#F0C860',inStock:true,url:'https://wonderfull.coffee/kava/'},
  {id:15,name:'Indonesia Wanagiri',roaster:'Wonder&Full',country:'Індонезія',region:'Балі',station:'Wanagiri',variety:'Typica',process:'Honey',roast:'Середня',brew:[t('method_esp'),'Омні'],weight:250,price:520,score:85,sweetness:75,acidity:30,bitterness:60,descriptors:['Темний шоколад','Тютюн','Спеції','Кедр'],color:'#704020',inStock:true,url:'https://wonderfull.coffee/kava/'},
  {id:16,name:'Peru Levi',roaster:'Wonder&Full',country:'Перу',region:'Cajamarca',station:'Levi',variety:'Typica',process:'Washed',roast:'Середня',brew:['Фільтр',t('method_esp'),'Омні'],weight:250,price:460,score:84,sweetness:80,acidity:45,bitterness:30,descriptors:['Карамель','Мед','Горіх','Зелене яблуко'],color:'#B08840',inStock:true,url:'https://wonderfull.coffee/kava/'},
  {id:17,name:'Colombia Decaf',roaster:'Wonder&Full',country:'Колумбія',region:'Уїла',station:null,variety:'Castillo',process:'Sugar Cane Decaf',roast:'Середня',brew:['Фільтр',t('method_esp'),'Омні'],weight:250,price:500,score:83,sweetness:75,acidity:42,bitterness:25,descriptors:['Молочний шоколад','Карамель','Сухофрукти'],color:'#907040',inStock:true,url:'https://wonderfull.coffee/kava/'},
  {id:18,name:'Black Honey Anaerob',roaster:'Wonder&Full',country:'Колумбія',region:'Антіокія',station:null,variety:'Castillo',process:'Anaerobic Honey',roast:'Світла',brew:['Фільтр','Омні'],weight:250,price:650,score:90,sweetness:92,acidity:60,bitterness:8,descriptors:['Троянда','Панела','Бергамот','Вино'],color:'#A03080',inStock:true,url:'https://wonderfull.coffee/kava/anaerobnij-blek-hani'},
  {id:19,name:'ТВОЯ кава',roaster:'Wonder&Full',country:'Blend',region:'Blend',station:null,variety:'Blend',process:'Washed',roast:'Середня',brew:['Фільтр',t('method_esp'),'Омні'],weight:250,price:480,score:87,sweetness:85,acidity:55,bitterness:20,descriptors:['Молочний шоколад','Персик','Кокос','Карамель'],color:'#C87040',inStock:true,url:'https://wonderfull.coffee/kava/tvoya_kava_natkhnenna_pochuttyamy'},
];

const ROAST_COLORS_MKT={'Світла':{bg:'rgba(160,200,60,.18)',c:'#9cc040'},'Середня':{bg:'rgba(200,135,42,.18)',c:'var(--copper-lt)'},'Темна':{bg:'rgba(180,60,20,.18)',c:'#d05030'}};
const BAR_COLORS_MKT={sweetness:'var(--copper-lt)',acidity:'#E86040',bitterness:'#6b6862'};

/* ── SVG-ПАЧКИ ── */
const SC_STRIPES=['#4A7EC8','#D4901C','#58A848','#C84838'];
const PENYORA_LABEL={1:'#B84060',2:'#2E6C38',3:'#2A5098',4:'#966010',5:'#703060',6:'#706010',7:'#2E6020',8:'#703018'};
function bagSvg(c,W,H){
  const isPen=c.roaster==='Penyora';
  const rx=7,sw=9,uid='bg'+c.id;
  const method=c.brew[0]||'';
  const parts=c.name.split(' ');
  const l1=parts[0]||'',l2=parts.slice(1).join(' ')||'';
  if(isPen){
    const lc=PENYORA_LABEL[c.id]||'#7A4060';
    const segH=Math.round((H-4)/4);
    const segs=SC_STRIPES.map((col,i)=>{const y=2+i*segH,h=i===3?(H-4)-3*segH:segH;return`<rect x="2" y="${y}" width="${sw}" height="${h}" fill="${col}"/><rect x="${W-2-sw}" y="${y}" width="${sw}" height="${h}" fill="${col}"/>`;}).join('');
    return`<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg" style="display:block;flex-shrink:0">
<defs><clipPath id="${uid}"><rect x="2" y="2" width="${W-4}" height="${H-4}" rx="${rx}"/></clipPath></defs>
<ellipse cx="${W/2}" cy="${H-1}" rx="${W/2-4}" ry="3" fill="rgba(0,0,0,.10)"/>
<rect x="2" y="2" width="${W-4}" height="${H-4}" rx="${rx}" fill="#F0EDE7" stroke="#D0CAC2" stroke-width="0.7"/>
<g clip-path="url(#${uid})">${segs}<rect x="2" y="2" width="${W-4}" height="17" fill="#FFFFFF"/></g>
<text x="${W/2}" y="13" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?5.2:4.5}" font-weight="700" fill="#1A1818" letter-spacing="1.5">${method.toUpperCase()}</text>
<text x="${W/2}" y="28" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?4.5:4}" font-weight="700" fill="#252220" letter-spacing="1.5">PENYORA</text>
<rect x="${W*.18}" y="33" width="${W*.64}" height="${H*.27}" rx="3" fill="${lc}"/>
<text x="${W*.38}" y="${33+H*.155}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?14:11}" font-weight="700" fill="#fff">${c.score}</text>
<text x="${W*.38}" y="${33+H*.22}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="3.5" fill="rgba(255,255,255,.65)">SCA</text>
<text x="${W*.72}" y="${33+H*.12}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${l1.length>5?(W>70?3.8:3.2):(W>70?5.2:4.2)}" font-weight="700" fill="#fff" textLength="${Math.min(l1.length*(W>70?3.0:2.4),W*.3)}" lengthAdjust="spacingAndGlyphs">${l1.toUpperCase()}</text>
<text x="${W*.72}" y="${33+H*.19}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${l2.length>6?(W>70?3.6:3.0):(W>70?5.2:4.2)}" font-weight="700" fill="#fff" textLength="${Math.min(l2.length*(W>70?3.0:2.4),W*.3)}" lengthAdjust="spacingAndGlyphs">${l2.toUpperCase()}</text>
<text x="${W*.72}" y="${33+H*.245}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="3.5" fill="rgba(255,255,255,.6)">${c.process}</text>
<text x="${W/2}" y="${H*.73}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?7.5:6.5}" font-weight="600" fill="#252220">${l1}</text>
<text x="${W/2}" y="${H*.83}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?7.5:6.5}" font-weight="600" fill="#252220">${l2}</text>
<rect x="${W*.2}" y="${H*.88}" width="${W*.6}" height="${H*.09}" rx="${H*.045}" fill="#E4DED6"/>
<text x="${W/2}" y="${H*.935}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?5.8:5}" font-weight="600" fill="#2A2520">${c.weight} г</text>
</svg>`;}
  const acc=c.color||'#C83820';
  return`<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg" style="display:block;flex-shrink:0">
<defs><clipPath id="${uid}"><rect x="2" y="2" width="${W-4}" height="${H-4}" rx="${rx}"/></clipPath>
<radialGradient id="gl${uid}" cx="40%" cy="45%" r="60%"><stop offset="0%" stop-color="${acc}" stop-opacity="0.32"/><stop offset="100%" stop-color="${acc}" stop-opacity="0"/></radialGradient></defs>
<ellipse cx="${W/2}" cy="${H-1}" rx="${W/2-4}" ry="3" fill="rgba(0,0,0,.13)"/>
<rect x="2" y="2" width="${W-4}" height="${H-4}" rx="${rx}" fill="#181614" stroke="#2C2826" stroke-width="0.7"/>
<g clip-path="url(#${uid})"><rect x="2" y="2" width="${W-4}" height="${H-4}" fill="url(#gl${uid})"/><rect x="2" y="2" width="${W-4}" height="15" fill="#111010"/></g>
<text x="${W/2}" y="11.5" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?6:5}" font-weight="600" fill="#C8C0B0" letter-spacing="1.5">${method.toUpperCase()}</text>
<text x="${W/2}" y="${H*.33}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?12:9}" font-weight="900" fill="#fff" letter-spacing="-0.3">WONDER</text>
<text x="${W/2}" y="${H*.44}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?11:9}" font-weight="900" fill="${acc}">&amp;</text>
<text x="${W/2}" y="${H*.55}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?12:9}" font-weight="900" fill="#fff" letter-spacing="-0.3">FULL</text>
<rect x="5" y="${H*.6}" width="${W-10}" height="${H*.32}" rx="3" fill="rgba(0,0,0,.65)"/>
<rect x="${W-24}" y="${H*.62}" width="18" height="14" rx="3" fill="${acc}"/>
<text x="${W-15}" y="${H*.62+9}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?9:8}" font-weight="700" fill="#fff">${c.score}</text>
<text x="9" y="${H*.71}" font-family="Helvetica Neue,sans-serif" font-size="${W>70?6.5:5.5}" font-weight="600" fill="#E8E0D0">${l1}</text>
<text x="9" y="${H*.80}" font-family="Helvetica Neue,sans-serif" font-size="${W>70?6.5:5.5}" font-weight="600" fill="#E8E0D0">${l2}</text>
<text x="9" y="${H*.88}" font-family="Helvetica Neue,sans-serif" font-size="3.8" fill="#706860">${c.descriptors.slice(0,2).join(' · ')}</text>
<text x="${W/2}" y="${H*.96}" text-anchor="middle" font-family="Helvetica Neue,sans-serif" font-size="${W>70?5.5:4.8}" font-weight="600" fill="#E0D8C8">${c.weight} г</text>
</svg>`;}

let MKT={roast:[],brew:[],country:[],process:[],roaster:[],inStockOnly:false,cart:[],expanded:null,filterOpen:false};

function mktToggleFilter(){
  MKT.filterOpen=!MKT.filterOpen;
  const sb=document.getElementById('mkt-sidebar');
  const btn=document.getElementById('mkt-filter-btn');
  if(sb)sb.style.display=MKT.filterOpen?'block':'none';
  if(btn)btn.classList.toggle('active',MKT.filterOpen);
  mktRender();
}

function mktFilteredList(){
  const q=(document.getElementById('mkt-q')||{}).value?.toLowerCase()||'';
  const sort=(document.getElementById('mkt-sort')||{}).value||'score';
  let list=MKT_COFFEES.filter(c=>{
    if(MKT.roast.length&&!MKT.roast.includes(c.roast))return false;
    if(MKT.brew.length&&!MKT.brew.some(b=>c.brew.includes(b)))return false;
    if(MKT.country.length&&!MKT.country.includes(c.country))return false;
    if(MKT.process.length&&!MKT.process.includes(c.process))return false;
    if(MKT.roaster&&MKT.roaster.length&&!MKT.roaster.includes(c.roaster))return false;
    if(MKT.inStockOnly&&!c.inStock)return false;
    if(q&&![c.name,c.roaster,c.country,...c.descriptors].some(v=>v.toLowerCase().includes(q)))return false;
    return true;
  });
  if(sort==='score')list.sort((a,b)=>b.score-a.score);
  else if(sort==='price_asc')list.sort((a,b)=>a.price-b.price);
  else if(sort==='price_desc')list.sort((a,b)=>b.price-a.price);
  else list.sort((a,b)=>a.name.localeCompare(b.name,'uk'));
  return list;
}

function mktToggle(key,val){
  const arr=MKT[key];const i=arr.indexOf(val);
  if(i>=0)arr.splice(i,1);else arr.push(val);
  mktRender();
}

function mktReset(){
  MKT.roast=[];MKT.brew=[];MKT.country=[];MKT.process=[];MKT.roaster=[];MKT.inStockOnly=false;
  const q=document.getElementById('mkt-q');if(q)q.value='';
  mktRender();
}

function mktExpandCard(id){
  MKT.expanded=MKT.expanded===id?null:id;
  mktRender();
}

function mktRender(){
  const list=mktFilteredList();
  const filterOpen=MKT.filterOpen;
  const activeCount=[MKT.roast,MKT.brew,MKT.country,MKT.process,MKT.roaster].reduce((n,a)=>n+(a.length?1:0),0)+(MKT.inStockOnly?1:0);

  // Sidebar фильтров
  const sb=document.getElementById('mkt-sidebar');
  if(sb&&filterOpen){
    const allCountries=[...new Set(MKT_COFFEES.map(c=>c.country))].sort();
    const allProcesses=[...new Set(MKT_COFFEES.map(c=>c.process))].sort();
    const allRoasters=[...new Set(MKT_COFFEES.map(c=>c.roaster))].sort();
    sb.innerHTML=`
      <div class="mkt-pill-group">
        <span class="mkt-pill-lbl">Наявність</span>
        <button class="mkt-pill ${MKT.inStockOnly?'on':''}" onclick="MKT.inStockOnly=!MKT.inStockOnly;mktRender()">В наявності</button>
      </div>
      <div class="mkt-divider"></div>
      <div class="mkt-pill-group">
        <span class="mkt-pill-lbl">Обсмажувач</span>
        ${allRoasters.map(v=>`<button class="mkt-pill ${MKT.roaster.includes(v)?'on':''}" onclick="mktToggle('roaster','${v}')">${v}</button>`).join('')}
      </div>
      <div class="mkt-divider"></div>
      <div class="mkt-pill-group">
        <span class="mkt-pill-lbl">Обжарка</span>
        ${['Світла','Середня','Темна'].map(v=>`<button class="mkt-pill ${MKT.roast.includes(v)?'on':''}" onclick="mktToggle('roast','${v}')">${v}</button>`).join('')}
      </div>
      <div class="mkt-pill-group">
        <span class="mkt-pill-lbl">Заварювання</span>
        ${['Фільтр',t('method_esp'),'Омні'].map(v=>`<button class="mkt-pill ${MKT.brew.includes(v)?'on':''}" onclick="mktToggle('brew','${v}')">${v}</button>`).join('')}
      </div>
      <div class="mkt-pill-group">
        <span class="mkt-pill-lbl">Обробка</span>
        ${allProcesses.map(v=>`<button class="mkt-pill ${MKT.process.includes(v)?'on':''}" onclick="mktToggle('process','${v}')">${v}</button>`).join('')}
      </div>
      <div class="mkt-divider"></div>
      <div class="mkt-pill-group">
        <span class="mkt-pill-lbl">Країна</span>
        ${allCountries.map(v=>`<button class="mkt-pill ${MKT.country.includes(v)?'on':''}" onclick="mktToggle('country','${v}')">${v}</button>`).join('')}
      </div>
      ${activeCount?`<div style="padding:0 8px"><button onclick="mktReset()" style="width:100%;font-size:9px;padding:5px;border-radius:7px;background:none;border:0.5px solid var(--copper-dk);color:var(--copper-lt);cursor:pointer;font-family:inherit;margin-top:2px">Скинути</button></div>`:''}`;
  }

  // Filter count badge
  const filterBtn=document.getElementById('mkt-filter-btn');
  const cntEl=document.getElementById('mkt-filter-cnt');
  if(cntEl){cntEl.textContent=activeCount||'';cntEl.style.display=activeCount?'flex':'none';}

  // Active pills bar
  const pillsBar=document.getElementById('mkt-active-pills');
  if(pillsBar){
    const tags=[];
    MKT.roast.forEach(v=>tags.push({k:'roast',v}));
    MKT.brew.forEach(v=>tags.push({k:'brew',v}));
    MKT.country.forEach(v=>tags.push({k:'country',v}));
    MKT.process.forEach(v=>tags.push({k:'process',v}));
    MKT.roaster.forEach(v=>tags.push({k:'roaster',v}));
    if(MKT.inStockOnly)tags.push({k:'inStockOnly',v:'В наявності'});
    if(tags.length){
      pillsBar.style.display='flex';
      pillsBar.innerHTML=tags.map(t=>`<span style="font-size:9px;padding:2px 7px;border-radius:20px;background:rgba(184,115,51,.18);color:var(--copper-lt);cursor:pointer;font-family:var(--mono);font-weight:600;border:0.5px solid var(--copper-dk)" onclick="mktToggle('${t.k}','${t.v}')">${t.v} ×</span>`).join('');
    } else {
      pillsBar.style.display='none';
    }
  }

  // Count
  const cnt=document.getElementById('mkt-count');
  if(cnt)cnt.textContent=list.length+' позиц'+(list.length===1?'ія':list.length<5?'ії':'ій');

  // Grid
  const grid=document.getElementById('mkt-grid');
  if(!grid)return;

  const gridClass=filterOpen?'mkt-grid-1':'mkt-grid-2';

  if(!list.length){
    grid.outerHTML='<div id="mkt-grid"></div>';
    document.getElementById('mkt-grid').innerHTML=`<div class="mkt-empty"><i class="ti ti-coffee" aria-hidden="true"></i><div style="font-size:13px;font-weight:600;color:var(--txt2);margin-bottom:6px">Нічого не знайдено</div><button onclick="mktReset()" style="font-size:11px;color:var(--copper-lt);background:none;border:none;cursor:pointer;font-family:inherit">Скинути фільтри</button></div>`;
    return;
  }

  const rclrMap={'Світла':'rgba(160,200,60,.18):#9cc040','Середня':'rgba(200,135,42,.18):var(--copper-lt)','Темна':'rgba(180,60,20,.18):#d05030'};

  grid.className=gridClass;
  grid.innerHTML=list.map(c=>{
    const rParts=(rclrMap[c.roast]||'rgba(255,255,255,.08):#aaa').split(':');
    const rBg=rParts[0],rC=rParts[1];
    const inCart=MKT.cart.includes(c.id);
    const isExp=MKT.expanded===c.id;

    // Expand panel HTML
    const expandHtml=isExp?`<div class="cc-expand">
      <div class="cc-bars">
        ${[['sweetness','Солодкість'],['acidity','Кислотність'],['bitterness','Гіркота']].map(([k,l])=>`
        <div class="cc-bar-row">
          <span class="cc-bar-lbl">${l}</span>
          <div class="cc-bar-track"><div class="cc-bar-fill" style="width:${c[k]}%;background:${BAR_COLORS_MKT[k]}"></div></div>
          <span style="font-family:var(--mono);font-size:9px;color:var(--txt3);width:22px;text-align:right">${c[k]}</span>
        </div>`).join('')}
      </div>
      <div class="cc-descs">${c.descriptors.map(d=>`<span>${d}</span>`).join('')}</div>
      <div style="display:flex;gap:6px;align-items:center">
        <span class="cc-price">${c.price.toLocaleString('uk-UA')} ₴</span>
        ${!c.inStock?'<span class="cc-nostock-badge">немає в наявності</span>':`<button class="cc-cart ${inCart?'added':''}" onclick="event.stopPropagation();mktAddCart(${c.id})">${inCart?'✓ У кошику':'+ Купити'}</button>`}
        <button class="cc-add-inv" style="flex:1" onclick="event.stopPropagation();mktAddToInventory(${c.id})"><i class="ti ti-seeding" style="font-size:11px;vertical-align:middle;margin-right:4px"></i>В інвентар</button>
      </div>
    </div>`:'';

    if(filterOpen){
      // Горизонтальна карточка — 1 колонка
      return`<div class="cc ${isExp?'expanded':''}" onclick="mktExpandCard(${c.id})">
        <div class="cc-row">
          <div class="cc-row-ico" style="background:transparent;padding:0;overflow:hidden;width:52px;height:68px;flex-shrink:0">
            ${bagSvg(c,52,68)}
          </div>
          <div class="cc-row-info">
            <div class="cc-name">${c.name}</div>
            <div class="cc-sub">${c.roaster} · ${c.weight}г · ${c.country}</div>
            <div class="cc-brew-pills">
              ${c.brew.map(b=>`<span>${b}</span>`).join('')}
              <span class="proc">${c.process}</span>
            </div>
          </div>
          <div class="cc-row-right">
            <span class="cc-score">${c.score}</span>
            <span class="cc-roast-pill" style="background:${rBg};color:${rC}">${c.roast}</span>
            <span class="cc-price">${c.price.toLocaleString('uk-UA')} ₴</span>
          </div>
        </div>
        ${expandHtml}
      </div>`;
    } else {
      // Карточка-квадрат — 2 колонки
      return`<div class="cc ${isExp?'expanded':''}" onclick="mktExpandCard(${c.id})">
        <div class="cc-sq-img" style="background:transparent;padding:0;overflow:hidden;height:110px;display:flex;align-items:center;justify-content:center;position:relative">
          ${bagSvg(c,84,104)}
          ${!c.inStock?`<div style="position:absolute;inset:0;background:rgba(0,0,0,.45);display:flex;align-items:center;justify-content:center"><span style="font-family:var(--mono);font-size:7px;color:var(--txt3);letter-spacing:.6px">НЕМАЄ</span></div>`:''}
        </div>
        <div class="cc-sq-body">
          <div class="cc-name">${c.name}</div>
          <div class="cc-sub">${c.roaster} · ${c.weight}г</div>
          <div class="cc-brew-pills" style="margin-top:4px">
            ${c.brew.slice(0,2).map(b=>`<span>${b}</span>`).join('')}
          </div>
          <div style="display:flex;align-items:center;justify-content:space-between;margin-top:6px">
            <span class="cc-price">${c.price.toLocaleString('uk-UA')} ₴</span>
            <i class="ti ti-chevron-${isExp?'up':'down'}" style="font-size:12px;color:var(--txt3)"></i>
          </div>
        </div>
        ${expandHtml}
      </div>`;
    }
  }).join('');

  // Бейдж корзины
  const badge=document.getElementById('cart-badge');
  if(badge){badge.textContent=MKT.cart.length;badge.style.display=MKT.cart.length?'flex':'none';}
}

function mktAddCart(id){
  if(!MKT.cart.includes(id))MKT.cart.push(id);
  mktRender();
  const c=MKT_COFFEES.find(x=>x.id===id);
  if(c)toast('У кошик: '+c.name);
}

function mktAddToInventory(id){
  const c=MKT_COFFEES.find(x=>x.id===id);if(!c)return;
  // Добавляем в инвентарь зерна
  S.beans.unshift({id:++S.id,name:c.name,roaster:c.roaster,total:c.weight,current:c.weight});
  save();
  toast('Додано в інвентар: '+c.name);
}

function mktShowCart(){
  const items=MKT.cart.map(id=>MKT_COFFEES.find(c=>c.id===id)).filter(Boolean);
  if(!items.length){toast(t('trash_empty'));return;}
  const total=items.reduce((s,c)=>s+c.price,0);
  alert('Кошик:\n'+items.map(c=>`• ${c.name} — ${c.price.toLocaleString('uk-UA')} ₴`).join('\n')+'\n\nРазом: '+total.toLocaleString('uk-UA')+' ₴\n\n(Оплата з\'явиться в наступній версії)');
}
