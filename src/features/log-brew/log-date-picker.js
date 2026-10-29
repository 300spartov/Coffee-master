/* ── LOG BREW DATE PICKER ── */
var _lbPickerDate = new Date();

function lbDatePickerToggle(){
  var dp = document.getElementById('lb-date-picker');
  if(!dp) return;
  var isOpen = dp.style.display === 'block';
  dp.style.display = isOpen ? 'none' : 'block';
  if(!isOpen){ _lbPickerDate = new Date(); lbPickerRender(); }
}

function lbPickerNav(dir){
  _lbPickerDate.setMonth(_lbPickerDate.getMonth() + dir);
  lbPickerRender();
}

function lbPickerQuick(offsetDays){
  var d = new Date();
  d.setDate(d.getDate() + offsetDays);
  lbPickerSelect(d.getFullYear(), d.getMonth()+1, d.getDate());
  document.getElementById('lb-date-picker').style.display = 'none';
}

function lbPickerSelect(y, m, d){
  var padded = y+'-'+String(m).padStart(2,'0')+'-'+String(d).padStart(2,'0');
  var el = document.getElementById('lb-date'); if(el) el.value = padded;
  var today = new Date(); var isToday = (y===today.getFullYear()&&m===today.getMonth()+1&&d===today.getDate());
  var yesterday = new Date(); yesterday.setDate(yesterday.getDate()-1);
  var isYest = (y===yesterday.getFullYear()&&m===yesterday.getMonth()+1&&d===yesterday.getDate());
  var MONTHS_UA=['Січень','Лютий','Березень','Квітень','Травень','Червень','Липень','Серпень','Вересень','Жовтень','Листопад','Грудень'];
  var lbl = isToday ? 'Сьогодні' : isYest ? 'Вчора' : d+' '+MONTHS_UA[m-1]+' '+y;
  var lblEl = document.getElementById('lb-date-lbl'); if(lblEl) lblEl.textContent = lbl;
  document.getElementById('lb-date-picker').style.display = 'none';
  lbPickerRender();
}

function lbPickerRender(){
  var MONTHS_UA=['Січень','Лютий','Березень','Квітень','Травень','Червень','Липень','Серпень','Вересень','Жовтень','Листопад','Грудень'];
  var y = _lbPickerDate.getFullYear(), m = _lbPickerDate.getMonth();
  var titleEl = document.getElementById('lb-picker-title');
  if(titleEl) titleEl.textContent = MONTHS_UA[m] + ' ' + y;
  var grid = document.getElementById('lb-picker-grid'); if(!grid) return;
  var firstDay = new Date(y, m, 1).getDay(); // 0=Sun
  firstDay = (firstDay + 6) % 7; // Mon=0
  var daysInMonth = new Date(y, m+1, 0).getDate();
  var today = new Date();
  var selVal = (document.getElementById('lb-date')||{}).value || '';
  var cells = '';
  for(var i=0; i<firstDay; i++) cells += '<div></div>';
  for(var d=1; d<=daysInMonth; d++){
    var padded = y+'-'+String(m+1).padStart(2,'0')+'-'+String(d).padStart(2,'0');
    var isToday = (d===today.getDate()&&m===today.getMonth()&&y===today.getFullYear());
    var isSel = padded === selVal;
    var isFuture = new Date(y, m, d) > today;
    var style = 'text-align:center;border-radius:7px;padding:6px 2px;font-family:var(--mono);font-size:12px;cursor:pointer;border:none;';
    if(isSel) style += 'background:var(--copper);color:#1c130a;font-weight:700;';
    else if(isToday) style += 'background:rgba(184,115,51,.18);color:var(--copper-lt);font-weight:700;';
    else if(isFuture) style += 'opacity:.3;cursor:default;color:var(--txt3);background:none;';
    else style += 'background:none;color:var(--txt2);';
    var click = isFuture ? '' : 'onclick="lbPickerSelect('+y+','+(m+1)+','+d+')"';
    cells += '<button type="button" style="'+style+'" '+click+'>'+d+'</button>';
  }
  grid.innerHTML = cells;
}
