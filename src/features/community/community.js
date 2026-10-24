/* ── COMMUNITY FEED (хардкод, тред о кофе) ── */
const COMMUNITY=[
  {av:'М',name:'Марк Светлый',cat:'Бариста',time:'12 мин',text:'Перешёл на Origami M + бумага Cafec Abaca — пролив стал заметно быстрее, тело чище. Кто ещё на оригами, какой ratio крутите?',likes:34,replies:12,acc:true},
  {av:'Д',name:'dasha.brews',cat:'Любитель',time:'48 мин',text:'Ефіопія Іргачефе на V60, 1:16, 93°. Жасмин + чёрный чай + лимон. Ягодная сладость на остывании 🫐',likes:58,replies:9,recipe:{m:'V60',d:'15 г',r:'1:16',t:'2:45'}},
  {av:'К',name:'Костя Filter',cat:'Сектант',time:'2 ч',text:'Споры вечные: смачивать бумажный фильтр или нет? По блайнд-тесту разница есть только на дешёвой бумаге. На Cafec — не смачиваю.',likes:41,replies:27},
  {av:'A',name:'aeris.coffee',cat:'Профі',time:'5 ч',text:'Flower Dripper недооцінений. Пелюсткові ребра = рівна екстракція без каналінгу. На світлій обжарці топ за свої гроші.',likes:73,replies:15,acc:true},
  {av:'И',name:'Игорь Зерно',cat:'Любитель',time:'8 ч',text:'Aeropress Go в путешествии — спасение. Инвертед, 1:14, 80°, 1:30 настой. Везу с собой Comandante и не жалею о весе рюкзака.',likes:29,replies:6,recipe:{m:'Aeropress',d:'18 г',r:'1:14',t:'1:30'}}
];

/* ── COMMUNITY ── */
const commLikes={};
function renderCommunity(el){
  /* Community feature hidden — coming soon */
  el.innerHTML=`<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;padding:70px 30px;text-align:center;gap:14px">
    <i class="ti ti-messages" aria-hidden="true" style="font-size:42px;color:var(--copper-lt);opacity:.45;display:block"></i>
    <div style="font-size:17px;font-weight:700;color:var(--txt)">Скоро тут щось з'явиться</div>
    <div style="font-size:13px;color:var(--txt3);line-height:1.6;max-width:240px" data-i18n="community_coming">Ком'юніті кавоманів вже в розробці — слідкуй за оновленнями</div>
  </div>`;
}
function togglePostLike(i){commLikes[i]=!commLikes[i];renderFeed()}
