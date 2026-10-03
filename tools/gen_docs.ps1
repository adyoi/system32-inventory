$ErrorActionPreference = 'Stop'

# Reuse the whole data pipeline (categories, curated explanations, stats) from the README generator.
. (Join-Path $PSScriptRoot 'gen_readme.ps1') | Out-Null

$projectRoot = Split-Path -Parent $outPath
$docsDir = Join-Path $projectRoot 'docs'
if (-not (Test-Path -LiteralPath $docsDir)) { New-Item -ItemType Directory -Path $docsDir | Out-Null }

# ---------------------------------------------------------------- data payloads
$data = foreach ($r in $rows) {
    $o = [ordered]@{
        n = $r.Name
        e = $r.Ext
        s = [int][math]::Round($r.SizeBytes)
        v = $r.FileVersion
        c = $r.Cat
        k = $r.Src
        d = (Esc $r.Expl)
    }
    ConvertTo-Json -InputObject $o -Compress
}
$dataJson = '[' + ($data -join ',') + ']'

$catPayload = foreach ($c in $cats) {
    [ordered]@{
        key = $c.Key
        title = $c.Title
        short = $c.Short
        desc = $c.Desc
        exe = @($exe | Where-Object { $_.Cat -eq $c.Key }).Count
        dll = @($dll | Where-Object { $_.Cat -eq $c.Key }).Count
    }
}

$deepPayload = foreach ($d in $deep) {
    if ($apiCount -eq 0 -and $d.N -match 'api-ms-win-\*') { continue }
    [ordered]@{ name = $d.N; title = $d.T; body = $d.B }
}

$infoJson = ConvertTo-Json -Compress -Depth 6 -InputObject ([ordered]@{
    os       = "$($os.Caption) build $($os.BuildNumber)"
    generated= $now
    total    = $rows.Count
    totalExe = $exe.Count
    totalDll = $dll.Count
    size     = (Fmt-Size $totalSize)
    curated  = $curCount
    metadata = $metaCount
    unknown  = $noneCount
    cats     = @($catPayload)
    deep     = @($deepPayload)
})

function Json-Safe {
    # JSON placed inside <script type="application/json"> is raw text, so HTML entities must NOT be used.
    # The only sequence that can terminate the element is "</" which is a valid escape inside JSON strings.
    param([string]$S)
    if ($null -eq $S) { return '' }
    return (($S -replace '</', '<\/') -replace [char]0x2028, '\u2028' -replace [char]0x2029, '\u2029')
}

$dataJsonSafe = Json-Safe $dataJson
$infoJsonSafe = Json-Safe $infoJson

# ---------------------------------------------------------------- page template
$html = @'
<!DOCTYPE html>
<html lang="id" data-theme="light">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Inventaris System32 - EXE dan DLL</title>
<meta name="description" content="Daftar lengkap file .exe dan .dll di C:\Windows\System32 yang dikelompokkan per kategori, dengan penjelasan fungsi tiap file.">
<style>
/* ------------------------------------------------------------ design tokens */
:root{
  color-scheme:light;
  --bg:#ffffff; --surface:#ffffff; --surface-2:#f6f8fa; --surface-3:#eef1f5;
  --border:#d0d7de; --border-strong:#b6bfca;
  --text:#1f2328; --text-muted:#59636e;
  --accent:#0969da; --accent-weak:#ddf4ff; --accent-contrast:#ffffff;
  --ok:#1a7f37; --ok-weak:#dafbe1;
  --radius:8px; --radius-lg:12px;
  --shadow-sm:0 1px 2px rgba(31,35,40,.08);
  --shadow-md:0 8px 24px -16px rgba(31,35,40,.28);
  --font:-apple-system,BlinkMacSystemFont,"Segoe UI",Inter,Roboto,Helvetica,Arial,sans-serif;
  --mono:ui-monospace,SFMono-Regular,"SF Mono",Menlo,Consolas,"Liberation Mono",monospace;
}
html[data-theme="dark"]{
  color-scheme:dark;
  --bg:#0d1117; --surface:#161b22; --surface-2:#1c2129; --surface-3:#21262d;
  --border:#30363d; --border-strong:#444c56;
  --text:#e6edf3; --text-muted:#9198a1;
  --accent:#2f81f7; --accent-weak:#121d2f; --accent-contrast:#0d1117;
  --ok:#3fb950; --ok-weak:#0f2417;
  --shadow-sm:0 1px 2px rgba(1,4,9,.4);
  --shadow-md:0 8px 24px -16px rgba(1,4,9,.8);
}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%;scrollbar-color:var(--border-strong) var(--bg)}
body{
  margin:0;background:var(--bg);color:var(--text);
  font:15px/1.6 var(--font);
  font-feature-settings:"cv02","cv03","cv04","cv11";
  -webkit-font-smoothing:antialiased;
}
.wrap{max-width:1280px;margin:0 auto;padding:0 24px}
a{color:var(--accent)}

/* ------------------------------------------------------------ masthead */
.masthead{border-bottom:1px solid var(--border);background:var(--surface)}
.masthead .wrap{padding-top:28px;padding-bottom:20px}
.eyebrow{
  display:inline-flex;align-items:center;gap:7px;
  font-size:11px;font-weight:600;letter-spacing:.08em;text-transform:uppercase;
  color:var(--text-muted);margin:0 0 10px
}
.eyebrow::before{content:"";width:14px;height:2px;background:var(--accent);border-radius:2px}
h1{margin:0 0 8px;font-size:clamp(21px,2.2vw,27px);line-height:1.25;letter-spacing:-.02em;font-weight:650}
.lede{margin:0;color:var(--text-muted);max-width:78ch}
.facts{display:flex;flex-wrap:wrap;gap:8px;margin-top:18px}
.fact{
  display:flex;align-items:baseline;gap:6px;
  background:var(--surface-2);border:1px solid var(--border);border-radius:999px;
  padding:5px 12px;font-size:12.5px;color:var(--text-muted)
}
.fact b{color:var(--text);font-weight:600;font-variant-numeric:tabular-nums}

/* ------------------------------------------------------------ toolbar */
.toolbar{
  position:sticky;top:0;z-index:30;
  background:transparent;border-bottom:1px solid transparent;
  transition:background .12s ease,border-color .12s ease
}
.toolbar.stuck{background:var(--surface);border-bottom-color:var(--border)}
.toolbar .wrap{display:flex;gap:8px;align-items:center;padding-top:10px;padding-bottom:10px;flex-wrap:wrap}
.tools{display:flex;gap:8px;align-items:center;flex-wrap:wrap;min-width:0}
.field{position:relative;flex:1 1 260px;min-width:0}
.field svg{position:absolute;left:11px;top:50%;transform:translateY(-50%);width:15px;height:15px;fill:var(--text-muted);pointer-events:none}
input[type=search],select{
  width:100%;font:inherit;font-size:14px;color:var(--text);
  background:var(--surface-2);border:1px solid var(--border);border-radius:var(--radius);
  padding:8px 12px;transition:border-color .12s ease,box-shadow .12s ease
}
input[type=search]{padding-left:33px}
input[type=search]::placeholder{color:var(--text-muted);opacity:1}
select{width:auto;min-width:150px;cursor:pointer}
option{background:var(--surface);color:var(--text)}
input[type=search],select{accent-color:var(--accent)}
input[type=search]:focus,select:focus{outline:none;border-color:var(--accent);box-shadow:0 0 0 3px var(--accent-weak)}
button{
  font:inherit;font-size:13.5px;font-weight:500;color:var(--text);cursor:pointer;
  background:var(--surface-2);border:1px solid var(--border);border-radius:var(--radius);
  padding:8px 13px;white-space:nowrap;
  transition:border-color .12s ease,background .12s ease,color .12s ease
}
button:hover{border-color:var(--border-strong);background:var(--surface-3)}
button[aria-pressed="true"]{background:var(--accent);border-color:var(--accent);color:var(--accent-contrast)}
button.link{background:transparent;border-color:transparent;color:var(--accent);padding-inline:6px}
button.link:hover{background:var(--accent-weak);border-color:transparent}

/* ------------------------------------------------------------ layout */
.layout{display:grid;grid-template-columns:264px minmax(0,1fr);gap:28px;padding:24px 0 56px}
aside{align-self:start}
aside h2{
  margin:0 0 10px;font-size:11px;font-weight:600;letter-spacing:.08em;
  text-transform:uppercase;color:var(--text-muted)
}
.cat{
  display:flex;width:100%;gap:10px;align-items:baseline;justify-content:space-between;
  padding:7px 10px;border:1px solid transparent;border-left:2px solid transparent;
  border-radius:0 var(--radius) var(--radius) 0;background:transparent;
  font-size:13.5px;color:var(--text);text-align:left;line-height:1.4
}
.cat:hover{background:var(--surface-2)}
@media (min-width:1001px){
  /* the generic button:hover border must not draw a box around the sidebar row;
     placed before the pressed rule so the accent bar still wins while hovering */
  .cat:hover{border-color:transparent}
}
.cat[aria-pressed="true"]{background:var(--surface-2);border-color:var(--border);border-left-color:var(--accent);color:var(--text);font-weight:600}
.cat .n{color:var(--text-muted);font-size:12px;font-variant-numeric:tabular-nums;flex:none}
.cat .lbl{flex:1 1 auto;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.cat[aria-pressed="true"] .n{color:var(--text)}
main{min-width:0}
.resultbar{display:flex;flex-wrap:wrap;gap:10px;align-items:baseline;justify-content:space-between;margin:0 0 12px}
.resultbar .count{color:var(--text-muted);font-size:13.5px;margin:0}
.resultright{display:flex;flex-wrap:wrap;gap:10px;align-items:center;justify-content:flex-end}
.active-filters{display:flex;flex-wrap:wrap;gap:6px}
.tag{
  display:inline-flex;align-items:center;gap:6px;font-size:12px;color:var(--text-muted);
  background:var(--surface-2);border:1px solid var(--border);border-radius:999px;padding:3px 10px
}
.tag b{color:var(--text);font-weight:600}

/* ------------------------------------------------------------ table */
.panel{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-lg);box-shadow:var(--shadow-sm)}
.scroll-x{overflow:visible}
table{width:100%;table-layout:auto;border-collapse:collapse}
thead th{
  position:sticky;top:var(--toolbar-h,0px);z-index:10;
  background:var(--surface-2);border-bottom:1px solid var(--border);
  text-align:left;padding:0;font-size:11.5px;font-weight:600;letter-spacing:.06em;
  text-transform:uppercase;color:var(--text-muted);white-space:nowrap
}
thead th .lbl{display:flex;align-items:center;gap:6px;padding:10px 12px;width:100%}
thead th.num .lbl{justify-content:flex-end}
th.sortable{cursor:pointer;user-select:none}
th.sortable:hover .lbl{color:var(--text)}
th.sortable:focus-visible{outline:2px solid var(--accent);outline-offset:-2px}
th .ind{opacity:0;font-size:9px;line-height:1}
th[aria-sort="ascending"] .ind,th[aria-sort="descending"] .ind{opacity:1;color:var(--accent)}
th[aria-sort="ascending"] .ind::after{content:"\25B2"}
th[aria-sort="descending"] .ind::after{content:"\25BC"}
tbody td{padding:10px 12px;border-bottom:1px solid var(--border);vertical-align:top;font-size:13.5px;overflow-wrap:anywhere}
thead th:first-child{border-top-left-radius:var(--radius-lg)}
thead th:last-child{border-top-right-radius:var(--radius-lg)}
tbody tr:last-child td:first-child{border-bottom-left-radius:var(--radius-lg)}
tbody tr:last-child td:last-child{border-bottom-right-radius:var(--radius-lg)}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover{background:var(--surface-2)}
td.name{font-family:var(--mono);font-size:13px;overflow-wrap:anywhere;word-break:normal}
td.name .ext{color:var(--text-muted)}
td.size{text-align:right;white-space:nowrap;color:var(--text-muted);font-variant-numeric:tabular-nums}
td.ver{color:var(--text-muted);font-size:12.5px;font-variant-numeric:tabular-nums;overflow-wrap:anywhere}
td.desc{color:var(--text)}
.badge{
  display:inline-block;font-size:11.5px;line-height:18px;padding:0 8px;border-radius:999px;
  background:var(--surface-3);color:var(--text-muted);border:1px solid var(--border);white-space:nowrap
}
.badge.k{color:var(--ok);background:var(--ok-weak);border-color:transparent}
tr.letter td{
  background:var(--surface-2);color:var(--text-muted);
  font-size:11px;font-weight:600;letter-spacing:.09em;text-transform:uppercase;padding:7px 14px
}
.more{flex:none;padding:6px 14px;white-space:nowrap}
.note{margin:16px 0 0;font-size:12.5px;color:var(--text-muted)}

/* ------------------------------------------------------------ deep dive */
details{margin:20px 0;border:1px solid var(--border);border-radius:var(--radius-lg);background:var(--surface);overflow:hidden}
summary{
  cursor:pointer;list-style:none;padding:13px 16px;font-size:14px;font-weight:600;
  display:flex;align-items:center;justify-content:space-between;gap:10px
}
summary::-webkit-details-marker{display:none}
summary::after{content:"+";color:var(--text-muted);font-weight:400;font-size:18px;line-height:1}
details[open] summary::after{content:"-"}
summary:hover{background:var(--surface-2)}
.deepgrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:0;border-top:1px solid var(--border)}
.deepitem{padding:14px 16px;border-bottom:1px solid var(--border)}
.deepitem b{font-family:var(--mono);font-size:12.5px;font-weight:600}
.deepitem .t{display:block;color:var(--text-muted);font-size:12.5px;margin:2px 0 0}
.deepitem p{margin:6px 0 0;font-size:13px;color:var(--text-muted)}

footer{border-top:1px solid var(--border);background:var(--surface-2);color:var(--text-muted);font-size:13px}
footer .wrap{padding-top:20px;padding-bottom:28px}
footer code{font-family:var(--mono);font-size:12.5px;background:var(--surface-3);padding:1px 5px;border-radius:4px}

/* ------------------------------------------------------------ scroll to top */
.to-top{
  position:fixed;right:20px;bottom:20px;z-index:40;
  width:42px;height:42px;padding:0;border-radius:50%;
  display:none;align-items:center;justify-content:center;
  background:var(--surface);border:1px solid var(--border-strong);
  color:var(--text);box-shadow:var(--shadow-md)
}
.to-top.show{display:inline-flex}
.to-top:hover{background:var(--surface-2);border-color:var(--accent);color:var(--accent)}
.to-top:focus-visible{outline:2px solid var(--accent);outline-offset:3px}
.to-top svg{width:19px;height:19px;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}

/* ------------------------------------------------------------ responsive */
@media (max-width:1000px){
  .layout{grid-template-columns:1fr;gap:20px}
  aside{position:static}
  aside h2{margin-top:4px}
  .catlist{display:flex;flex-wrap:wrap;gap:6px}
  .cat{
    width:auto;border:1px solid var(--border);border-radius:999px;
    padding:5px 11px;background:var(--surface-2);font-size:12.5px
  }
  .cat .lbl{flex:0 1 auto}
  .cat[aria-pressed="true"]{border-color:var(--accent);background:var(--accent-weak);color:var(--accent)}
  .cat:hover{background:var(--surface-3)}
  .cat:hover{background:var(--surface-3)}
}
@media (max-width:1000px){
  tbody td{padding:9px 10px}
  thead th .lbl{padding:9px 10px}
}
@media (max-width:880px){
  .wrap{padding:0 16px}
  .toolbar .wrap{padding-top:8px;padding-bottom:8px;flex-wrap:nowrap;gap:6px}
  .field{flex:1 1 auto}
  /* the controls stay on one line and scroll sideways, so the sticky toolbar stays short */
  .tools{flex-wrap:nowrap;overflow-x:auto;overscroll-behavior-x:contain;scrollbar-width:none}
  .tools::-webkit-scrollbar{display:none}
  select{min-width:0;flex:0 0 auto}
  button{padding:8px 11px}
  .facts{gap:6px}
  .fact{font-size:12px;padding:4px 10px}

  /* the 5-column table becomes a card list so long text wraps and nothing is cut off */
  table,tbody,tr,td{display:block;width:100%}
  thead{display:none}
  .panel{background:transparent;border:none;box-shadow:none;border-radius:0}
  tbody tr{
    background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-lg);
    box-shadow:var(--shadow-sm);padding:12px 14px;margin-bottom:10px
  }
  tbody tr.letter{
    background:transparent;border:none;box-shadow:none;padding:14px 2px 6px;margin-bottom:2px
  }
  tbody tr.letter td{border:none;padding:0}
  tbody td{border:none;padding:3px 0}
  tbody td::before{
    content:attr(data-label);display:block;margin-bottom:1px;
    font-size:10.5px;font-weight:600;letter-spacing:.07em;text-transform:uppercase;color:var(--text-muted)
  }
  td.name{font-size:13.5px;margin-bottom:6px}
  td.name::before{display:none}
  td.size{text-align:left}
  .resultbar{gap:6px}
  .resultright{justify-content:flex-start}
}
@media print{
  .toolbar,aside,.more,.to-top,footer{display:none}
  .panel{border:none;box-shadow:none}
  body{font-size:11pt}
}
</style>
</head>
<body>

<header class="masthead">
  <div class="wrap">
    <p class="eyebrow">Dokumentasi Windows</p>
    <h1>Inventaris C:\Windows\System32</h1>
    <p class="lede">Daftar lengkap file .exe dan .dll di System32, dikelompokkan per kategori dan diurutkan sesuai kolom yang dipilih, dengan penjelasan fungsi tiap file.</p>
    <div class="facts" id="facts"></div>
  </div>
</header>

<div class="wrap">
  <details>
    <summary>Penjelasan file inti (deep dive)</summary>
    <div class="deepgrid" id="deep"></div>
  </details>
</div>

<div class="toolbar">
  <div class="wrap">
    <label class="field">
      <svg viewBox="0 0 16 16" aria-hidden="true"><path d="M11.7 10.3a6 6 0 1 0-1.4 1.4l3 3a1 1 0 0 0 1.4-1.4l-3-3ZM7 11a4 4 0 1 1 0-8 4 4 0 0 1 0 8Z"/></svg>
      <input id="q" type="search" placeholder="Cari nama file atau penjelasan: ws2_32, BitLocker, service, font..." aria-label="Cari file" autocomplete="off">
    </label>
    <div class="tools">
    <select id="ext" aria-label="Filter tipe file">
      <option value="all">Semua tipe</option>
      <option value="EXE">EXE</option>
      <option value="DLL">DLL</option>
    </select>
    <select id="sort" aria-label="Urutkan">
      <option value="n:1">Nama (A-Z)</option>
      <option value="n:-1">Nama (Z-A)</option>
      <option value="s:-1">Ukuran terbesar</option>
      <option value="s:1">Ukuran terkecil</option>
      <option value="v:1">Versi</option>
      <option value="c:1">Kategori</option>
    </select>
    <button id="curated" aria-pressed="false" title="Tampilkan hanya file dengan penjelasan kurasi manual">Kurasi saja</button>
    <button id="csv">Unduh CSV</button>
    <button id="theme" title="Ganti tema terang atau gelap">Gelap</button>
    </div>
  </div>
</div>

<div class="wrap">
  <div class="layout">
    <aside>
      <h2>Kategori</h2>
      <div class="catlist" id="cats"></div>
    </aside>
    <main>
      <div class="resultbar">
        <p class="count" id="count"></p>
        <div class="resultright">
          <div class="active-filters" id="tags"></div>
          <button class="more" id="more">Tampilkan lebih banyak</button>
        </div>
      </div>
      <div class="panel">
        <div class="scroll-x">
          <table id="tbl">
            <thead>
              <tr>
                <th class="sortable" data-key="n" scope="col" aria-sort="ascending"><span class="lbl">File <span class="ind" aria-hidden="true"></span></span></th>
                <th class="sortable num" data-key="s" scope="col"><span class="lbl">Ukuran <span class="ind" aria-hidden="true"></span></span></th>
                <th class="sortable" data-key="v" scope="col"><span class="lbl">Versi <span class="ind" aria-hidden="true"></span></span></th>
                <th class="sortable" data-key="c" scope="col"><span class="lbl">Kategori <span class="ind" aria-hidden="true"></span></span></th>
                <th scope="col"><span class="lbl">Penjelasan</span></th>
              </tr>
            </thead>
            <tbody id="rows"></tbody>
          </table>
        </div>
      </div>
      <p class="note" id="legend"></p>
    </main>
  </div>
</div>

<footer>
  <div class="wrap">
    Halaman dihasilkan otomatis dari metadata versi setiap file. Versi markdown yang sama ada di <code>README.md</code>.
    Jangan menghapus file di System32: folder itu dilindungi Windows Resource Protection.
    Sumber: <a href="https://github.com/adyoi/system32-inventory">github.com/adyoi/system32-inventory</a>.
  </div>
</footer>

<button id="toTop" class="to-top" type="button" aria-label="Kembali ke atas" title="Kembali ke atas">
  <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M12 19V5M5 12l7-7 7 7"/></svg>
</button>

<script id="payload" type="application/json">__DATA__</script>
<script id="info" type="application/json">__INFO__</script>
<script>
(function(){
  "use strict";
  var DATA = JSON.parse(document.getElementById('payload').textContent);
  var INFO = JSON.parse(document.getElementById('info').textContent);
  var PAGE = 400;
  var state = { q:"", ext:"all", cat:"all", key:"n", dir:1, curated:false, shown:PAGE };
  var catName = {}, catShort = {}, catDesc = {};
  INFO.cats.forEach(function(c){ catName[c.key] = c.title; catShort[c.key] = c.short || c.title; catDesc[c.key] = c.desc; });

  function fmtSize(b){
    if (b >= 1048576) return (b/1048576).toFixed(1) + " MB";
    if (b >= 1024) return Math.round(b/1024) + " KB";
    return b + " B";
  }
  function fmtNum(n){ return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, "."); }

  /* ---------------------------------------------------------- masthead facts */
  var facts = document.getElementById('facts');
  [["File", fmtNum(INFO.total)], ["EXE", fmtNum(INFO.totalExe)], ["DLL", fmtNum(INFO.totalDll)],
   ["Ukuran total", INFO.size], ["Kurasi manual", fmtNum(INFO.curated)],
   ["Dari metadata", fmtNum(INFO.metadata)], ["Tanpa metadata", fmtNum(INFO.unknown)],
   ["Sistem", INFO.os]].forEach(function(p){
    var d = document.createElement('div'); d.className = 'fact';
    d.innerHTML = "<b>" + p[1] + "</b> " + p[0]; facts.appendChild(d);
  });

  /* ---------------------------------------------------------- deep dive */
  var deepBox = document.getElementById('deep');
  INFO.deep.forEach(function(d){
    var el = document.createElement('div'); el.className = 'deepitem';
    el.innerHTML = "<b>" + d.name + "</b><span class='t'>" + d.title + "</span><p>" + d.body + "</p>";
    deepBox.appendChild(el);
  });
  document.getElementById('legend').textContent =
    "Penjelasan berlabel hijau berasal dari kurasi manual; sisanya diambil dari FileDescription pada metadata versi file. " +
    "Baris tanpa keterangan berarti file tidak punya metadata deskripsi sehingga fungsinya tidak terdokumentasi publik.";

  /* ---------------------------------------------------------- category filter */
  var catsBox = document.getElementById('cats');
  function catButton(key, label, total, full){
    var b = document.createElement('button');
    b.className = 'cat'; b.dataset.key = key; b.type = 'button';
    b.title = (full || label) + (catDesc[key] ? ' - ' + catDesc[key] : '');
    b.setAttribute('aria-pressed', String(state.cat === key));
    b.innerHTML = "<span class='lbl'>" + label + "</span><span class='n'>" + fmtNum(total) + "</span>";
    b.addEventListener('click', function(){
      /* klik kategori yang sedang aktif akan melepas filter kembali ke semua kategori */
      state.cat = (state.cat === key && key !== 'all') ? 'all' : key;
      state.shown = PAGE; paintCats(); render();
    });
    catsBox.appendChild(b);
    return b;
  }
  catButton('all', 'Semua kategori', INFO.total, 'Semua kategori');
  INFO.cats.forEach(function(c){ if (c.exe + c.dll > 0) catButton(c.key, c.short || c.title, c.exe + c.dll, c.title); });
  function paintCats(){
    var kids = catsBox.querySelectorAll('.cat');
    for (var i = 0; i < kids.length; i++){
      kids[i].setAttribute('aria-pressed', String(kids[i].dataset.key === state.cat));
    }
  }

  /* ---------------------------------------------------------- filtering + sort */
  function matches(d){
    if (state.ext !== 'all' && d.e !== state.ext) return false;
    if (state.cat !== 'all' && d.c !== state.cat) return false;
    if (state.curated && d.k !== 'kurasi') return false;
    if (!state.q) return true;
    var q = state.q;
    return d.n.toLowerCase().indexOf(q) >= 0 || d.d.toLowerCase().indexOf(q) >= 0;
  }
  function byName(a, b){
    var x = a.n.toLowerCase(), y = b.n.toLowerCase();
    return x < y ? -1 : (x > y ? 1 : 0);
  }
  function byCat(a, b){
    var x = (catName[a.c] || a.c).toLowerCase(), y = (catName[b.c] || b.c).toLowerCase();
    return x < y ? -1 : (x > y ? 1 : 0);
  }
  function current(){
    var q = state.q.trim().toLowerCase();
    var out = [];
    for (var i = 0; i < DATA.length; i++){
      var d = DATA[i];
      if (state.ext !== 'all' && d.e !== state.ext) continue;
      if (state.cat !== 'all' && d.c !== state.cat) continue;
      if (state.curated && d.k !== 'kurasi') continue;
      if (q && d.n.toLowerCase().indexOf(q) < 0 && d.d.toLowerCase().indexOf(q) < 0) continue;
      out.push(d);
    }
    var dir = state.dir;
    out.sort(function(a, b){
      var r = 0;
      if (state.key === 's') r = a.s - b.s;
      else if (state.key === 'v') r = String(a.v).localeCompare(String(b.v), undefined, {numeric:true});
      else if (state.key === 'c') r = byCat(a, b);
      else r = byName(a, b);
      if (r === 0) r = byName(a, b);
      return r * dir;
    });
    return out;
  }

  /* ---------------------------------------------------------- header sorting */
  var sortSelect = document.getElementById('sort');
  var ths = [].slice.call(document.querySelectorAll('th.sortable'));
  function paintSort(){
    ths.forEach(function(th){
      if (th.dataset.key === state.key){
        th.setAttribute('aria-sort', state.dir === 1 ? 'ascending' : 'descending');
      } else {
        th.removeAttribute('aria-sort');
      }
    });
    sortSelect.value = state.key + ":" + state.dir;
  }
  ths.forEach(function(th){
    th.setAttribute('tabindex', '0');
    th.setAttribute('role', 'columnheader');
    function activate(){
      if (state.key === th.dataset.key){ state.dir = -state.dir; }
      else { state.key = th.dataset.key; state.dir = 1; }
      state.shown = PAGE; paintSort(); render();
    }
    th.addEventListener('click', activate);
    th.addEventListener('keydown', function(ev){
      if (ev.key === 'Enter' || ev.key === ' '){ ev.preventDefault(); activate(); }
    });
  });
  sortSelect.addEventListener('change', function(){
    var parts = sortSelect.value.split(':');
    state.key = parts[0]; state.dir = parseInt(parts[1], 10);
    state.shown = PAGE; paintSort(); render();
  });

  /* ---------------------------------------------------------- rendering */
  var tbody = document.getElementById('rows');
  var countEl = document.getElementById('count');
  var tagsEl = document.getElementById('tags');
  var moreEl = document.getElementById('more');

  function cell(label, cls, text){
    var td = document.createElement('td');
    td.className = cls; td.setAttribute('data-label', label); td.textContent = text;
    return td;
  }

  function render(){
    var list = current();
    tbody.textContent = "";
    var frag = document.createDocumentFragment();
    var end = Math.min(state.shown, list.length);
    var lastCat = null, lastLetter = null;
    for (var i = 0; i < end; i++){
      var d = list[i];
      var L = d.n.substring(0,1).toUpperCase();
      if (state.cat === 'all' && (d.c !== lastCat || L !== lastLetter)){
        var hr = document.createElement('tr'); hr.className = 'letter';
        var hc = document.createElement('td'); hc.colSpan = 5;
        hc.textContent = catName[d.c] || d.c;
        hr.appendChild(hc); frag.appendChild(hr);
        lastCat = d.c; lastLetter = L;
      }
      var tr = document.createElement('tr');
      var name = document.createElement('td');
      name.className = 'name'; name.setAttribute('data-label', 'File');
      var dot = d.n.lastIndexOf('.');
      name.appendChild(document.createTextNode(dot > 0 ? d.n.slice(0, dot) : d.n));
      var ext = document.createElement('span'); ext.className = 'ext';
      ext.textContent = dot > 0 ? d.n.slice(dot) : '';
      name.appendChild(ext);
      name.title = d.n;
      tr.appendChild(name);
      tr.appendChild(cell('Ukuran', 'size', fmtSize(d.s)));
      tr.appendChild(cell('Versi', 'ver', d.v));
      var cat = document.createElement('td'); cat.setAttribute('data-label', 'Kategori');
      var badge = document.createElement('span');
      badge.className = 'badge' + (d.k === 'kurasi' ? ' k' : '');
      badge.textContent = catShort[d.c] || d.c; badge.title = (catName[d.c] || '') + (catDesc[d.c] ? ' - ' + catDesc[d.c] : '');
      cat.appendChild(badge);
      tr.appendChild(cat);
      tr.appendChild(cell('Penjelasan', 'desc', d.d));
      frag.appendChild(tr);
    }
    tbody.appendChild(frag);

    countEl.textContent = "Menampilkan " + fmtNum(end) + " dari " + fmtNum(list.length) + " file";

    tagsEl.textContent = "";
    function tag(label, value){
      var t = document.createElement('span'); t.className = 'tag';
      t.innerHTML = label + " <b>" + value + "</b>";
      tagsEl.appendChild(t);
    }
    if (state.q.trim()) tag("pencarian", '"' + state.q.trim() + '"');
    if (state.ext !== 'all') tag("tipe", state.ext);
    if (state.cat !== 'all') tag("kategori", catName[state.cat] || state.cat);
    if (state.curated) tag("filter", "kurasi saja");
    if (tagsEl.childNodes.length){
      var reset = document.createElement('button');
      reset.className = 'link'; reset.type = 'button'; reset.textContent = 'Reset';
      reset.addEventListener('click', function(){
        state.q = ""; state.ext = "all"; state.cat = "all"; state.curated = false; state.shown = PAGE;
        document.getElementById('q').value = "";
        document.getElementById('ext').value = "all";
        document.getElementById('curated').setAttribute('aria-pressed', 'false');
        paintCats(); render();
      });
      tagsEl.appendChild(reset);
    }

    moreEl.style.display = (list.length > state.shown) ? '' : 'none';
    moreEl.textContent = 'Tampilkan ' + fmtNum(Math.min(PAGE, list.length - state.shown)) + ' file lagi';
  }

  /* ---------------------------------------------------------- controls */
  document.getElementById('q').addEventListener('input', function(ev){
    state.q = ev.target.value.toLowerCase(); state.shown = PAGE; render();
  });
  document.getElementById('ext').addEventListener('change', function(ev){
    state.ext = ev.target.value; state.shown = PAGE; render();
  });
  var curatedBtn = document.getElementById('curated');
  curatedBtn.addEventListener('click', function(){
    state.curated = !state.curated;
    curatedBtn.setAttribute('aria-pressed', String(state.curated));
    state.shown = PAGE; render();
  });
  moreEl.addEventListener('click', function(){ state.shown += PAGE; render(); });
  document.getElementById('csv').addEventListener('click', function(){
    var list = current();
    var out = ["File,Tipe,Ukuran_byte,Versi,Kategori,Penjelasan"];
    list.forEach(function(d){
      out.push([d.n, d.e, d.s, '"' + d.v + '"', '"' + (catName[d.c] || d.c) + '"', '"' + d.d.replace(/"/g, '""') + '"'].join(','));
    });
    var blob = new Blob(["\ufeff" + out.join("\r\n")], {type:"text/csv;charset=utf-8"});
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob); a.download = "system32-inventory.csv";
    document.body.appendChild(a); a.click(); a.remove();
    URL.revokeObjectURL(a.href);
  });

  /* ---------------------------------------------------------- theme */
  var themeBtn = document.getElementById('theme');
  function applyTheme(t){
    document.documentElement.setAttribute('data-theme', t);
    themeBtn.textContent = (t === 'dark') ? 'Terang' : 'Gelap';
  }
  var saved = null;
  try { saved = localStorage.getItem('sys32-theme'); } catch (err) {}
  applyTheme(saved || 'dark');
  themeBtn.addEventListener('click', function(){
    var next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    applyTheme(next);
    try { localStorage.setItem('sys32-theme', next); } catch (err) {}
  });

  /* ---------------------------------------------------------- sticky toolbar */
  var toolbar = document.querySelector('.toolbar');
  function syncToolbar(){
    var r = toolbar.getBoundingClientRect();
    /* "stuck" hanya saat toolbar benar-benar menempel di tepi atas viewport;
   toleransi 1px untuk layout yang menghasilkan posisi pecahan */
    toolbar.classList.toggle('stuck', r.top <= 1);
    document.documentElement.style.setProperty('--toolbar-h', Math.round(r.height) + 'px');
  }
  window.addEventListener('scroll', syncToolbar, { passive: true });
  window.addEventListener('resize', syncToolbar);
  if (window.ResizeObserver) { new ResizeObserver(syncToolbar).observe(toolbar); }
  syncToolbar();

  /* ---------------------------------------------------------- scroll to top */
  var toTop = document.getElementById('toTop');
  var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  function syncToTop(){
    toTop.classList.toggle('show', window.scrollY > 400);
  }
  toTop.addEventListener('click', function(){
    window.scrollTo({ top: 0, behavior: reduceMotion ? 'auto' : 'smooth' });
    toTop.blur();
  });
  window.addEventListener('scroll', syncToTop, { passive: true });
  syncToTop();

  paintSort();
  render();
})();
</script>
</body>
</html>
'@

$page = $html.Replace('__DATA__', $dataJsonSafe).Replace('__INFO__', $infoJsonSafe)
$outFile = Join-Path $docsDir 'index.html'
[IO.File]::WriteAllText($outFile, $page, (New-Object System.Text.UTF8Encoding($false)))

# GitHub Pages: skip Jekyll processing
$nojekyll = Join-Path $docsDir '.nojekyll'
if (-not (Test-Path -LiteralPath $nojekyll)) { [IO.File]::WriteAllText($nojekyll, '', (New-Object System.Text.UTF8Encoding($false))) }

"OK -> $outFile"
"size: $([math]::Round((Get-Item $outFile).Length/1KB,1)) KB"
"payload entries: $($rows.Count)"