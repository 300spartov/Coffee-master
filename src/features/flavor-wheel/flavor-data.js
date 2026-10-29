/* == NEW WHEEL ENGINE == */

/* ============================================================
   Повна таксономія смаків кави (Taster's Flavor Wheel) — UA
   3 рівні: категорія → підкатегорія → нота
   ============================================================ */
/* ── FLAVORS: двомовна структура UA/EN ──
   label — геттер, завжди повертає поточну мову.
   Зворотна сумісність: при збереженні в рецепт завжди
   зберігається UA-значення (desc[i].ua).             */
function _mkSub(id, ua, en, descPairs) {
  return {
    id: id,
    label_ua: ua,
    label_en: en,
    get label(){ return currentLang === 'en' ? this.label_en : this.label_ua; },
    desc: descPairs,
    get descLabels(){ var cl=currentLang; return this.desc.map(function(d){ return cl==='en' ? d.en : d.ua; }); }
  };
}
function _mkCat(id, ua, en, color, subs) {
  return {
    id: id,
    label_ua: ua,
    label_en: en,
    get label(){ return currentLang === 'en' ? this.label_en : this.label_ua; },
    color: color,
    subs: subs
  };
}

window.FLAVORS = [
  _mkCat('fruit','Фрукти','Fruit','#d44a7b',[
    _mkSub('citrus','Цитрус','Citrus',[
      {ua:'Лимон',en:'Lemon'},{ua:'Лайм',en:'Lime'},{ua:'Грейпфрут',en:'Grapefruit'},
      {ua:'Клементин',en:'Clementine'},{ua:'Апельсин',en:'Orange'},{ua:'Черв. апельсин',en:'Blood orange'}
    ]),
    _mkSub('pome','Ябл./Груша','Apple/Pear',[
      {ua:'Зел. яблуко',en:'Green apple'},{ua:'Черв. яблуко',en:'Red apple'},{ua:'Аз. груша',en:'Asian pear'}
    ]),
    _mkSub('melon','Диня','Melon',[
      {ua:'Кавун',en:'Watermelon'},{ua:'Медова диня',en:'Honeydew'},{ua:'Канталупа',en:'Cantaloupe'}
    ]),
    _mkSub('grape','Виноград','Grape',[
      {ua:'Білий виноград',en:'White grape'},{ua:'Зел. виноград',en:'Green grape'},
      {ua:'Черв. виноград',en:'Red grape'},{ua:'Конкорд',en:'Concord'}
    ]),
    _mkSub('trop','Тропічні','Tropical',[
      {ua:'Лічі',en:'Lychee'},{ua:'Карамбола',en:'Starfruit'},{ua:'Тамаринд',en:'Tamarind'},
      {ua:'Маракуйя',en:'Passion fruit'},{ua:'Ананас',en:'Pineapple'},{ua:'Манго',en:'Mango'},
      {ua:'Папайя',en:'Papaya'},{ua:'Ківі',en:'Kiwi'},{ua:'Банан',en:'Banana'},{ua:'Кокос',en:'Coconut'}
    ]),
    _mkSub('stone','Кісточкові','Stone fruit',[
      {ua:'Персик',en:'Peach'},{ua:'Нектарин',en:'Nectarine'},{ua:'Абрикос',en:'Apricot'},
      {ua:'Слива',en:'Plum'},{ua:'Вишня',en:'Cherry'},{ua:'Чорна вишня',en:'Black cherry'}
    ]),
    _mkSub('berry','Ягоди','Berry',[
      {ua:'Журавлина',en:'Cranberry'},{ua:'Малина',en:'Raspberry'},{ua:'Полуниця',en:'Strawberry'},
      {ua:'Чорниця',en:'Blueberry'},{ua:'Ожина',en:'Blackberry'},{ua:'Смородина',en:'Currant'}
    ]),
    _mkSub('dried','Сухофрукти','Dried fruit',[
      {ua:'Зол. родзинки',en:'Golden raisin'},{ua:'Родзинки',en:'Raisin'},
      {ua:'Інжир',en:'Fig'},{ua:'Фінік',en:'Date'},{ua:'Чорнослив',en:'Prune'}
    ]),
  ]),
  _mkCat('choco','Шоколад','Chocolate','#5a3420',[
    _mkSub('dark','Темний','Dark',[
      {ua:'Кондитерський',en:'Baking chocolate'},{ua:'Темний шоколад',en:'Dark chocolate'},{ua:'Гіркий шоколад',en:'Bitter chocolate'}
    ]),
    _mkSub('milk','Молочний','Milk',[
      {ua:'Молочний шоколад',en:'Milk chocolate'},{ua:'Білий шоколад',en:'White chocolate'},{ua:'Какао',en:'Cocoa'}
    ]),
  ]),
  _mkCat('sweet','Солодке','Sweet','#d99a3a',[
    _mkSub('sugar','Цукор','Sugar',[
      {ua:'Карамель',en:'Caramel'},{ua:'Кор. цукор',en:'Brown sugar'},{ua:'Трост. цукор',en:'Cane sugar'},
      {ua:'Сироп',en:'Syrup'},{ua:'Клен. сироп',en:'Maple syrup'},{ua:'Меляса',en:'Molasses'},{ua:'Кола',en:'Cola'}
    ]),
    _mkSub('vanil','Ваніль','Vanilla',[
      {ua:'Ваніль',en:'Vanilla'},{ua:'Марципан',en:'Marzipan'},{ua:'Нуга',en:'Nougat'}
    ]),
    _mkSub('creamy','Вершкове','Creamy',[
      {ua:'Мед',en:'Honey'},{ua:'Масло',en:'Butter'},{ua:'Вершки',en:'Cream'},{ua:'Маршмелоу',en:'Marshmallow'}
    ]),
  ]),
  _mkCat('nut','Горіхи','Nuts','#a9723f',[
    _mkSub('nuts','Горіхи','Nuts',[
      {ua:'Мигдаль',en:'Almond'},{ua:'Фундук',en:'Hazelnut'},{ua:'Пекан',en:'Pecan'},
      {ua:'Кеш’ю',en:'Cashew'},{ua:'Арахіс',en:'Peanut'},{ua:'Волоський',en:'Walnut'}
    ]),
  ]),
  _mkCat('grain','Зернові','Grain','#c2a063',[
    _mkSub('cereal','Зерно','Cereal',[
      {ua:'Свіжий хліб',en:'Fresh bread'},{ua:'Солод',en:'Malt'},{ua:'Ячмінь',en:'Barley'},
      {ua:'Пшениця',en:'Wheat'},{ua:'Жито',en:'Rye'},{ua:'Крекер',en:'Cracker'},
      {ua:'Вівсянка',en:'Oatmeal'},{ua:'Випічка',en:'Pastry'},{ua:'Попкорн',en:'Popcorn'}
    ]),
  ]),
  _mkCat('roast','Обсмаження','Roast','#6f757b',[
    _mkSub('roasted','Обсмаження','Roasted',[
      {ua:'Вугілля',en:'Charcoal'},{ua:'Димне',en:'Smoky'},{ua:'Палений цукор',en:'Burnt sugar'},{ua:'Тост',en:'Toast'}
    ]),
  ]),
  _mkCat('spice','Спеції','Spices','#d2674f',[
    _mkSub('spices','Спеції','Spices',[
      {ua:'Гвоздика',en:'Clove'},{ua:'Лакриця',en:'Licorice'},{ua:'Кмин',en:'Cumin'},
      {ua:'Мускат',en:'Nutmeg'},{ua:'Імбир',en:'Ginger'},{ua:'Коріандр',en:'Coriander'},
      {ua:'Кориця',en:'Cinnamon'},{ua:'Біл. перець',en:'White pepper'},{ua:'Чорн. перець',en:'Black pepper'}
    ]),
  ]),
  _mkCat('savory','Пікантне','Savory','#bd3f2c',[
    _mkSub('sav','Пікантне','Savory',[
      {ua:'В’ялений томат',en:'Sun-dried tomato'},{ua:'Соєвий соус',en:'Soy sauce'},
      {ua:'М’ясне',en:'Meaty'},{ua:'Шкіра',en:'Leather'}
    ]),
  ]),
  _mkCat('veg','Трави · Земля','Herbs · Earth','#4e9e4a',[
    _mkSub('herb','Трави','Herbs',[
      {ua:'Бергамот',en:'Bergamot'},{ua:'Хміль',en:'Hop'},{ua:'Чорний чай',en:'Black tea'},
      {ua:'Зелений чай',en:'Green tea'},{ua:'М’ята',en:'Mint'},{ua:'Шавлія',en:'Sage'},
      {ua:'Кріп',en:'Dill'},{ua:'Трав’янисте',en:'Herbal'}
    ]),
    _mkSub('veget','Овочеве','Vegetal',[
      {ua:'Ревінь',en:'Rhubarb'},{ua:'Дух. горошок',en:'Sweet pea'},{ua:'Томат',en:'Tomato'},
      {ua:'Морква',en:'Carrot'},{ua:'Кабачок',en:'Zucchini'},{ua:'Зел. перець',en:'Green pepper'},
      {ua:'Олива',en:'Olive'},{ua:'Зелень',en:'Greens'}
    ]),
    _mkSub('earth','Земля','Earth',[
      {ua:'Гриби',en:'Mushroom'},{ua:'Солома',en:'Straw'},{ua:'Тютюн',en:'Tobacco'},
      {ua:'Кедр',en:'Cedar'},{ua:'Дерево',en:'Wood'},{ua:'Ґрунт',en:'Soil'}
    ]),
  ]),
  _mkCat('floral','Квіти','Floral','#9b7fc0',[
    _mkSub('flowers','Квіти','Flowers',[
      {ua:'Гібіскус',en:'Hibiscus'},{ua:'Троянда',en:'Rose'},{ua:'Лаванда',en:'Lavender'},
      {ua:'Магнолія',en:'Magnolia'},{ua:'Жимолость',en:'Honeysuckle'},
      {ua:'Жасмин',en:'Jasmine'},{ua:'Цвіт апельсина',en:'Orange blossom'}
    ]),
  ]),
];

/* Плоский індекс усіх нот для пошуку: {note, cat, sub} */
window.FLAT_NOTES = (function(){
  var out=[];
  window.FLAVORS.forEach(function(c){
    c.subs.forEach(function(s){
      s.desc.forEach(function(d){ var note=typeof d==='object'?d.ua:d; out.push({note:note, cat:c, sub:s, desc:d}); });
    });
  });
  return out;
})();

/* ── Note color lookup (build after FLAVORS defined) ── */
var _NOTE_COLOR_MAP = {};
(function(){
  (window.FLAVORS||[]).forEach(function(cat){
    cat.subs.forEach(function(sub,si){
      sub.desc.forEach(function(note,di){
        /* note is now {ua, en} object */
        var ua=typeof note==='object'?note.ua:note;
        var en=typeof note==='object'?note.en:note;
        _NOTE_COLOR_MAP[ua] = cat.color;
        if(en && en!==ua) _NOTE_COLOR_MAP[en] = cat.color;
      });
    });
    /* also map sub labels and category label — both langs */
    _NOTE_COLOR_MAP[cat.label_ua||cat.label] = cat.color;
    if(cat.label_en) _NOTE_COLOR_MAP[cat.label_en] = cat.color;
    cat.subs.forEach(function(sub){
      _NOTE_COLOR_MAP[sub.label_ua||sub.label] = cat.color;
      if(sub.label_en) _NOTE_COLOR_MAP[sub.label_en] = cat.color;
    });
  });
})();
function noteColorByName(name){
  return _NOTE_COLOR_MAP[name] || null;
}
