// Gastos - Google Apps Script backend
// Base de datos en Google Sheets (se crea automáticamente la primera vez).

const DB_NAME = 'GastosDB';
const SHEET_OBL = 'Obligaciones';
const SHEET_PAG = 'PagosObligaciones';
const SHEET_GAS = 'Gastos';
const SHEET_PAR = 'Parametros';

const SEED_OBLIGACIONES = [
  { nombre: 'Volleyball', monto: 270000, diaPago: 10, categoria: 'Ocio' },
  { nombre: 'Mercado', monto: 600000, diaPago: 10, categoria: 'Alimentación' },
  { nombre: 'Acueducto', monto: 300000, diaPago: 10, categoria: 'Vivienda' },
  { nombre: 'Hipoteca (Pago Total)', monto: 1000000, diaPago: 10, categoria: 'Vivienda' },
  { nombre: 'Gas Vanti', monto: 80000, diaPago: 10, categoria: 'Vivienda' },
  { nombre: 'Movistar Hogar', monto: 70000, diaPago: 10, categoria: 'Servicios' },
  { nombre: 'Enel Codensa', monto: 220000, diaPago: 10, categoria: 'Servicios' },
  { nombre: 'Carro Davivienda', monto: 2300000, diaPago: 25, categoria: 'Transporte' },
  { nombre: 'Hipoteca', monto: 1700000, diaPago: 25, categoria: 'Vivienda' },
  { nombre: 'Claro celular mamá', monto: 22000, diaPago: 25, categoria: 'Servicios' },
  { nombre: 'TC Bancolombia', monto: 200000, diaPago: 25, categoria: 'Deudas' },
  { nombre: 'Mercado', monto: 600000, diaPago: 25, categoria: 'Alimentación' },
  { nombre: 'Administración', monto: 400000, diaPago: 25, categoria: 'Vivienda' },
  { nombre: 'Música', monto: 20000, diaPago: null, categoria: 'Ocio' },
  { nombre: 'Gasolina', monto: 100000, diaPago: null, categoria: 'Transporte' },
];

const SEED_PARAMETROS = [
  { tipo: 'categoria', nombre: 'Alimentación' },
  { tipo: 'categoria', nombre: 'Vivienda' },
  { tipo: 'categoria', nombre: 'Servicios' },
  { tipo: 'categoria', nombre: 'Transporte' },
  { tipo: 'categoria', nombre: 'Ocio' },
  { tipo: 'categoria', nombre: 'Deudas' },
  { tipo: 'metodoPago', nombre: 'Efectivo' },
  { tipo: 'metodoPago', nombre: 'Tarjeta' },
  { tipo: 'metodoPago', nombre: 'Transferencia' },
  { tipo: 'metodoPago', nombre: 'Obligación' },
];

const DEFAULT_DB_ID = '1doD8FQFSHzUMH3RA55CZiYBKTEPGTucyp9k4MXDMnQM';

function ping(){return 'pong-'+new Date().getTime()}
function getDb() {
  const props = PropertiesService.getScriptProperties();
  let id = props.getProperty('DB_ID');
  const candidates = [];
  if (id) candidates.push(id);
  if (DEFAULT_DB_ID && candidates.indexOf(DEFAULT_DB_ID) === -1) candidates.push(DEFAULT_DB_ID);
  let ss = null;
  for (let i = 0; i < candidates.length; i++) {
    try { ss = SpreadsheetApp.openById(candidates[i]); if (ss) break; } catch (e) { ss = null; }
  }
  if (!ss) {
    ss = SpreadsheetApp.create(DB_NAME);
    props.setProperty('DB_ID', ss.getId());
    ensureSheets(ss);
    if (ss.getSheetByName(SHEET_OBL).getLastRow() <= 1) seedObligaciones(ss);
    if (ss.getSheetByName(SHEET_PAR).getLastRow() <= 1) seedParametros(ss);
    return ss;
  }
  // reuse existing sheet: make sure structure exists, but don't wipe data
  try { ensureSheets(ss); } catch (e) {}
  try { props.setProperty('DB_ID', ss.getId()); } catch (e) {}
  const obl = ss.getSheetByName(SHEET_OBL);
  if (obl && obl.getLastRow() <= 1) seedObligaciones(ss);
  const par = ss.getSheetByName(SHEET_PAR);
  if (par && par.getLastRow() <= 1) seedParametros(ss);
  return ss;
}

function ensureSheets(ss) {
  const defs = {};
  defs[SHEET_OBL] = ['id', 'nombre', 'monto', 'dia_pago', 'categoria', 'activa'];
  defs[SHEET_PAG] = ['id', 'obligacion_id', 'mes', 'gasto_id'];
  defs[SHEET_GAS] = ['id', 'monto', 'categoria', 'metodoPago', 'fecha', 'descripcion'];
  defs[SHEET_PAR] = ['id', 'tipo', 'nombre'];
  Object.keys(defs).forEach(function (name) {
    let sh = ss.getSheetByName(name);
    if (!sh) {
      sh = ss.insertSheet(name);
      sh.appendRow(defs[name]);
      sh.getRange(1, 1, 1, defs[name].length).setFontWeight('bold');
      sh.setFrozenRows(1);
    } else if (sh.getLastRow() === 0) {
      sh.appendRow(defs[name]);
    }
  });
  const defaultSheet = ss.getSheetByName('Hoja 1') || ss.getSheetByName('Sheet1');
  if (defaultSheet && ss.getSheets().length > 1) {
    try { ss.deleteSheet(defaultSheet); } catch (e) {}
  }
}

function nextId(sheet) {
  const last = sheet.getLastRow();
  if (last <= 1) return 1;
  const ids = sheet.getRange(2, 1, last - 1, 1).getValues().flat().map(Number);
  const max = ids.length ? Math.max.apply(null, ids) : 0;
  return (isNaN(max) ? 0 : max) + 1;
}

function readSheet(sheet) {
  if (!sheet) return [];
  const last = sheet.getLastRow();
  if (last <= 1) return [];
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const rows = sheet.getRange(2, 1, last - 1, sheet.getLastColumn()).getValues();
  return rows.map(function (r) {
    const o = {};
    headers.forEach(function (h, i) { o[h] = r[i]; });
    return o;
  });
}



function seedObligaciones(ss) {
  const sh = ss.getSheetByName(SHEET_OBL);
  SEED_OBLIGACIONES.forEach(function (o) {
    sh.appendRow([nextId(sh), o.nombre, o.monto, o.diaPago === null ? '' : o.diaPago, o.categoria, true]);
  });
}

function seedParametros(ss) {
  const sh = ss.getSheetByName(SHEET_PAR);
  SEED_PARAMETROS.forEach(function (p) {
    sh.appendRow([nextId(sh), p.tipo, p.nombre]);
  });
}

// ---------- Public API ----------

function doGet(e) {
  return HtmlService.createHtmlOutputFromFile('Index')
    .setTitle('Gastos')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL)
    .addMetaTag('viewport', 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no');
}

function getInitDataX() {
  const out = { obligaciones: [], pagos: [], gastos: [], parametros: [], mesActual: '', dbId: '', sheetNames: [], errors: [] };
  try {
    const ss = getDb();
    out.dbId = ss.getId();
    out.sheetNames = ss.getSheets().map(function(s){return s.getName();});
    const now = new Date();
    out.mesActual = Utilities.formatDate(now, Session.getScriptTimeZone(), 'yyyy-MM');
    // Obligaciones
    try { out.obligaciones = readSheet(ss.getSheetByName(SHEET_OBL)).map(function (r) { return { id: Number(r.id), nombre: r.nombre, monto: Number(r.monto), diaPago: r.dia_pago === '' || r.dia_pago === null || r.dia_pago === undefined ? null : Number(r.dia_pago), categoria: r.categoria, activa: r.activa === true || r.activa === 'TRUE' || r.activa === 'true' }; }); }
    catch (e) { out.errors.push('OBL: ' + (e && e.message ? e.message : e)); }
    // Pagos
    try { out.pagos = readSheet(ss.getSheetByName(SHEET_PAG)).map(function (r) { return { id: Number(r.id), obligacionId: Number(r.obligacion_id), mes: r.mes, gastoId: r.gasto_id === '' || r.gasto_id === null ? null : Number(r.gasto_id) }; }); }
    catch (e) { out.errors.push('PAG: ' + (e && e.message ? e.message : e)); }
    // Gastos
    try { out.gastos = readSheet(ss.getSheetByName(SHEET_GAS)).map(function (r) { return { id: Number(r.id), monto: Number(r.monto), categoria: r.categoria, metodoPago: r.metodoPago, fecha: r.fecha instanceof Date ? Utilities.formatDate(r.fecha, Session.getScriptTimeZone(), 'yyyy-MM-dd') : String(r.fecha), descripcion: r.descripcion }; }); }
    catch (e) { out.errors.push('GAS: ' + (e && e.message ? e.message : e)); }
    // Parametros
    try { out.parametros = readSheet(ss.getSheetByName(SHEET_PAR)).map(function (r) { return { id: Number(r.id), tipo: r.tipo, nombre: r.nombre }; }); }
    catch (e) { out.errors.push('PAR: ' + (e && e.message ? e.message : e)); }
    return out;
  } catch (e) {
    out.errors.push('FATAL: ' + (e && e.message ? e.message : e));
    return out;
  }
}






function agregarObligacion(o) {
  const ss = getDb();
  const sh = ss.getSheetByName(SHEET_OBL);
  const id = nextId(sh);
  sh.appendRow([id, String(o.nombre).trim(), Number(o.monto), (o.diaPago === null || o.diaPago === '' ? '' : Number(o.diaPago)), o.categoria, o.activa !== false]);
  return id;
}

function actualizarObligacion(id, o) {
  const ss = getDb();
  const sh = ss.getSheetByName(SHEET_OBL);
  const rows = readSheet(sh);
  for (let i = 0; i < rows.length; i++) {
    if (Number(rows[i].id) === Number(id)) {
      const r = i + 2;
      sh.getRange(r, 2).setValue(String(o.nombre).trim());
      sh.getRange(r, 3).setValue(Number(o.monto));
      sh.getRange(r, 4).setValue(o.diaPago === null || o.diaPago === '' ? '' : Number(o.diaPago));
      sh.getRange(r, 5).setValue(o.categoria);
      sh.getRange(r, 6).setValue(o.activa !== false);
      return true;
    }
  }
  return false;
}

function eliminarObligacion(id) {
  const ss = getDb();
  const sh = ss.getSheetByName(SHEET_OBL);
  const rows = sh.getDataRange().getValues();
  for (let i = rows.length - 1; i >= 1; i--) {
    if (Number(rows[i][0]) === Number(id)) {
      sh.deleteRow(i + 1);
      return true;
    }
  }
  return false;
}

function marcarPagada(obligacionId, mes) {
  const ss = getDb();
  const pagos = readSheet(ss.getSheetByName(SHEET_PAG));
  if (pagos.some(function (p) { return Number(p.obligacion_id) === Number(obligacionId) && p.mes === mes; })) {
    return null;
  }
  const obl = readSheet(ss.getSheetByName(SHEET_OBL)).filter(function (r) { return Number(r.id) === Number(obligacionId); })[0];
  if (!obl) throw new Error('Obligacion no encontrada');
  const dia = (obl.dia_pago === '' || obl.dia_pago === null || obl.dia_pago === undefined) ? 1 : Number(obl.dia_pago);
  const fecha = mes + '-' + String(dia).padStart(2, '0');
  const gSh = ss.getSheetByName(SHEET_GAS);
  const gastoId = nextId(gSh);
  gSh.appendRow([gastoId, Number(obl.monto), obl.categoria, 'Obligación', fecha, obl.nombre]);
  const pSh = ss.getSheetByName(SHEET_PAG);
  const pagoId = nextId(pSh);
  pSh.appendRow([pagoId, Number(obligacionId), mes, gastoId]);
  return { pagoId: pagoId, gastoId: gastoId };
}

function desmarcar(obligacionId, mes) {
  const ss = getDb();
  const pSh = ss.getSheetByName(SHEET_PAG);
  const pagos = readSheet(pSh);
  const pago = pagos.find(function (p) { return Number(p.obligacion_id) === Number(obligacionId) && p.mes === mes; });
  if (!pago) return false;
  const rows = pSh.getDataRange().getValues();
  for (let i = rows.length - 1; i >= 1; i--) {
    if (Number(rows[i][0]) === Number(pago.id)) { pSh.deleteRow(i + 1); break; }
  }
  if (pago.gasto_id) {
    const gSh = ss.getSheetByName(SHEET_GAS);
    const grows = gSh.getDataRange().getValues();
    for (let i = grows.length - 1; i >= 1; i--) {
      if (Number(grows[i][0]) === Number(pago.gasto_id)) { gSh.deleteRow(i + 1); break; }
    }
  }
  return true;
}

function agregarGasto(g) {
  const ss = getDb();
  const sh = ss.getSheetByName(SHEET_GAS);
  const id = nextId(sh);
  sh.appendRow([id, Number(g.monto), g.categoria, g.metodoPago, g.fecha, g.descripcion || '']);
  return id;
}

function eliminarGasto(id) {
  const ss = getDb();
  const sh = ss.getSheetByName(SHEET_GAS);
  const rows = sh.getDataRange().getValues();
  for (let i = rows.length - 1; i >= 1; i--) {
    if (Number(rows[i][0]) === Number(id)) { sh.deleteRow(i + 1); return true; }
  }
  return false;
}

function agregarParametro(tipo, nombre) {
  const ss = getDb();
  const sh = ss.getSheetByName(SHEET_PAR);
  const id = nextId(sh);
  sh.appendRow([id, tipo, String(nombre).trim()]);
  return id;
}

function eliminarParametro(id) {
  const ss = getDb();
  const sh = ss.getSheetByName(SHEET_PAR);
  const rows = sh.getDataRange().getValues();
  for (let i = rows.length - 1; i >= 1; i--) {
    if (Number(rows[i][0]) === Number(id)) { sh.deleteRow(i + 1); return true; }
  }
  return false;
}
