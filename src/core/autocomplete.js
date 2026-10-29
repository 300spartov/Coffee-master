/* ── AUTOCOMPLETE ENGINE ── */
const AC_BUILTIN={
  roasters:['Gardelli','Onyx Coffee Lab','Square Mile','Tim Wendelboe','Fuglen','Manhattan Coffee Roasters','Coffee Collective','Nomad','Tandem','Prolog','Drop Coffee','Five Elephant','Barn','Bonanza','Black Cab','Mame','Kurasu','Leaves & Roots','Caffenation','Father Coffee','Rosso','Monogram','April','Koppi','Has Bean','Workshop','Intelligentsia','Stumptown','Counter Culture','Heart','Sightglass','Blue Bottle','Verve','Madcap','Coava','Equator','Ritual','Проліска','Фундамент','Кавові традиції','Чорна карта'],
  beanNames:['Ethiopia Yirgacheffe','Ethiopia Guji','Ethiopia Sidama','Ethiopia Harrar','Colombia Huila','Colombia Nariño','Colombia El Carmen','Kenya AA','Kenya AB','Kenya Kiambu','Guatemala Huehuetenango','Guatemala Antigua','Brazil Cerrado','Brazil Sul de Minas','Costa Rica Tarrazu','Peru Cajamarca','Rwanda Nyamasheke','Burundi Kayanza','Yemen Mokha','Panama Geisha','Honduras Santa Barbara','El Salvador Santa Ana','Nicaragua Jinotega','Papua New Guinea Highlands','Sumatra Mandheling','Java Preanger'],
  countries:['Ефіопія','Колумбія','Кенія','Гватемала','Бразилія','Коста-Ріка','Перу','Руанда','Бурунді','Ємен','Панама','Гондурас','Сальвадор','Нікарагуа','Папуа Нова Гвінея','Суматра','Ява','Індія','Болівія','Еквадор','Мексика','Танзанія','Уганда','Конго'],
  milks:['Цільне 3.2%','Овесняне','Мигдальне','Кокосове','Соєве','Безлактозне'],
  juices:['Schweppes Tonic','Fever-Tree Tonic','Апельсиновий сік','Грейпфрутовий сік','Яблучний сік']
};
function acGetList(key){
  const learned=S[key]||[];
  const builtin=AC_BUILTIN[key]||[];
  return[...new Set([...learned,...builtin])];
}
function acSuggest(fieldId,listKey){
  const inp=document.getElementById(fieldId);
  const drop=document.getElementById('ac-'+fieldId);
  if(!inp||!drop)return;
  const q=(inp.value||'').trim().toLowerCase();
  const all=acGetList(listKey);
  const matches=q?all.filter(s=>s.toLowerCase().includes(q)).slice(0,8):all.slice(0,6);
  if(!matches.length){drop.classList.remove('open');return;}
  drop.innerHTML=matches.map(s=>{
    const hi=q?s.replace(new RegExp('('+q.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+')','gi'),'<em>$1</em>'):s;
    return`<div class="ac-item" onmousedown="acPick('${fieldId}','${s.replace(/'/g,"\\'")}','${listKey}')">${hi}</div>`;
  }).join('');
  drop.classList.add('open');
}
function acPick(fieldId,val,listKey){
  const inp=document.getElementById(fieldId);
  if(inp)inp.value=val;
  acClose(fieldId);
  if(fieldId==='bn-name'){
    const cmap={'Ethiopia':'Ефіопія','Colombia':'Колумбія','Kenya':'Кенія','Guatemala':'Гватемала','Brazil':'Бразилія','Costa Rica':'Коста-Ріка','Peru':'Перу','Rwanda':'Руанда','Burundi':'Бурунді','Yemen':'Ємен','Panama':'Панама','Honduras':'Гондурас','El Salvador':'Сальвадор','Nicaragua':'Нікарагуа','Papua':'Папуа Нова Гвінея','Sumatra':'Суматра','Java':'Ява','India':'Індія','Bolivia':'Болівія','Ecuador':'Еквадор','Mexico':'Мексика','Tanzania':'Танзанія','Uganda':'Уганда','Congo':'Конго'};
    const cel=document.getElementById('bn-country');
    if(cel&&!cel.value){for(const[en,ua]of Object.entries(cmap)){if(val.startsWith(en)){cel.value=ua;break;}}}
  }
}
function acClose(fieldId){const d=document.getElementById('ac-'+fieldId);if(d)d.classList.remove('open');}
function acCloseAll(){document.querySelectorAll('.ac-drop').forEach(d=>d.classList.remove('open'));}
document.addEventListener('click',function(e){if(!e.target.closest('.ac-wrap'))acCloseAll();});
