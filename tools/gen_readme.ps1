$ErrorActionPreference = 'Stop'

$csvPath = Join-Path $PSScriptRoot 'sys32_inventory.csv'
$tmp     = $PSScriptRoot
$outPath = 'D:\Project\Windows\README.md'

function Import-Curated {
    param([string]$Path)
    $h = @{}
    $dropped = 0
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        $l = $line.Trim()
        if ($l.Length -eq 0 -or $l.StartsWith('#')) { continue }
        if ($l -notmatch '^([^|=?\s]+)\|(.+)$') { $dropped++; continue }
        $k = $matches[1]
        $v = $matches[2].Trim()
        $v = ($v -replace '[^\x20-\x7E]', '') -replace '\s+', ' '
        $v = $v.Trim()
        if ($k -notmatch '^[A-Za-z0-9_.\-\+]+$') { $dropped++; continue }
        if ($v.Length -lt 12) { $dropped++; continue }
        if ($v -match '[-"]$' -or $v -match '\bN/A\b') { $dropped++; continue }
        $h[$k] = $v
    }
    return @{ Map = $h; Dropped = $dropped }
}

$exeC = Import-Curated (Join-Path $PSScriptRoot 'curated_exe.txt')
$dllC = Import-Curated (Join-Path $PSScriptRoot 'curated_dll.txt')
$curated = @{}
foreach ($k in $exeC.Map.Keys) { $curated[$k] = $exeC.Map[$k] }
foreach ($k in $dllC.Map.Keys) { $curated[$k] = $dllC.Map[$k] }

$cats = @(
  @{ Key='core';   Title='Inti Kernel, System dan Runtime C/C++'; Short='Inti Kernel';
     Desc='Lapisan paling dasar: kernel NT, Win32 core, WOW64, dan runtime C/C++ (UCRT serta Visual C++ Runtime). Hampir semua proses Windows memuat beberapa file dari kategori ini, sehingga file di sini praktis tidak boleh hilang atau diganti.' },
  @{ Key='proc';   Title='Proses, Layanan dan Service Host'; Short='Proses dan Service';
     Desc='Executable dan pustaka yang menjalankan siklus hidup proses serta service: start, boot, logon, penjadwalan, dan pelaporan error.' },
  @{ Key='sec';    Title='Keamanan, Identitas dan Kripto'; Short='Keamanan';
     Desc='Autentikasi, otorisasi, sertifikat, penyimpanan kunci, TPM, biometrik, Windows Defender, SmartScreen, dan firmware keamanan.' },
  @{ Key='net';    Title='Jaringan, Internet dan Remote Access'; Short='Jaringan';
     Desc='Stack Winsock, HTTP, DNS, Active Directory via LDAP, Wi-Fi, VPN, broadband seluler, Bluetooth, dan protokol jaringan lama.' },
  @{ Key='ui';     Title='Shell, Explorer dan Antarmuka Pengguna'; Short='Shell dan UI';
     Desc='Semua yang membentuk tampilan Windows: jendela, kontrol, dialog, ikon, context menu, shell Explorer, dan aksesibilitas.' },
  @{ Key='gfx';    Title='Grafis, Direct3D dan DirectWrite'; Short='Grafis';
     Desc='Rendering 3D dan 2D: Direct3D 9 sampai 12, DXGI, DirectWrite, DirectComposition, OpenGL, Vulkan, dan pustaka driver GPU pihak ketiga.' },
  @{ Key='mm';     Title='Multimedia, Audio dan Video'; Short='Multimedia';
     Desc='Media Foundation, DirectShow, AVI, codec audio lawas, enkode video, dan scheduler real-time untuk multimedia.' },
  @{ Key='input';  Title='Input, Keyboard, Mouse dan Gamepad'; Short='Input dan Gamepad';
     Desc='Keyboard, mouse, HID, DirectInput, dan XInput untuk kontroler game.' },
  @{ Key='store';  Title='Penyimpanan, File System dan Volume'; Short='Penyimpanan';
     Desc='Volume manager, filter file system, BitLocker, Offline Files, kompresi CAB, dan lapisan internal FAT, NTFS, serta ReFS.' },
  @{ Key='dev';    Title='Perangkat Keras, Driver dan PnP'; Short='Driver dan PnP';
     Desc='Plug and Play, Device Manager, BIOS/ACPI, TPM, sensor, dan firmware mikrokode CPU.' },
  @{ Key='data';   Title='Data, Database dan Serialisasi'; Short='Data dan Database';
     Desc='Windows Installer, basis data (ODBC, OLE DB, SQLite, ESE), XML, Structured Query Language, dan property system.' },
  @{ Key='netfx';  Title='Runtime .NET, WinRT dan Library Bahasa'; Short='.NET dan WinRT';
     Desc='Hosting .NET Framework, proyeksi WinRT, dan pustaka C++ seperti ATL serta MFC.' },
  @{ Key='locale'; Title='Bahasa, Locale, Font dan Teks'; Short='Bahasa dan Font';
     Desc='Data NLS, normalisasi Unicode, font, shaping teks, keyboard layout, dan MUI.' },
  @{ Key='debug';  Title='Pengembangan, Debug dan Diagnostik'; Short='Debug dan Diagnostik';
     Desc='Simbol dan dump untuk debugging, performance counter, WMI, Error Reporting, serta alat ukur performa.' },
  @{ Key='print';  Title='Cetak, Scan dan Imaging'; Short='Cetak dan Scan';
     Desc='Print Spooler, driver filter, dialog printer, XPS/IPP, serta WIA untuk scanner dan kamera.' },
  @{ Key='vm';     Title='Virtualisasi, Kontainer dan VM'; Short='Virtualisasi';
     Desc='Hyper-V, Host Compute Service, VMBus, Windows Sandbox, Container, dan komponen virtual machine.' },
  @{ Key='policy'; Title='Kebijakan, CSP, dan MDM'; Short='Kebijakan dan MDM';
     Desc='Configuration Service Provider (CSP), Group Policy, kepatuhan, dan endpoint management yang dikelola tim TI. File di sini sering ditambahkan atau diubah lewat baseline kebijakan, bukan lewat aplikasi biasa.' },
  @{ Key='settings'; Title='Settings, Repository dan Personalisasi'; Short='Settings';
     Desc='Mesin di balik Windows Settings: penyimpan state, handler tiap halaman pengaturan, wallpaper, lockscreen, tile Start, dan data pengguna yang disimpan per aplikasi.' },
  @{ Key='msapps'; Title='Produk dan Layanan Microsoft'; Short='Produk Microsoft';
     Desc='Edge, Xbox Game Bar, Maps, People, App Installer, telemetry, dan komponen produk yang di-host di System32.' },
  @{ Key='3rd';    Title='Pihak Ketiga dan Driver Vendor'; Short='Vendor Ketiga';
     Desc='Berkas driver dan pustaka non-Microsoft yang ikut terpasang di System32, misalnya Intel Graphics, OpenSSL, atau plugin keamanan pihak ketiga.' },
  @{ Key='other';  Title='Lain-lain / Tidak terkategori'; Short='Lain-lain';
     Desc='Berkas yang tidak cocok dengan pola kategori lain, umumnya komponen internal Microsoft tanpa dokumentasi publik.' }
)

$rules = @(
  @{ Key='policy'; P='CSP\.dll$|^Enforcement|^Conditional.?Access|^admx|^GroupPolicy|^Mdm|^MDM|^Intune|^Exo|^AAD|^aad|^AzureAD|^Sense|^MMA|^Ma[A-Za-z]*Api|^wdigest|^Hgc|^Mgmt|MdmManagement|^Policy|^ADMX|^SystemPolicy' },
  @{ Key='settings'; P='^(sett|SystemSettings|StateRepository|StartTile|TileData|Lock|Password|UserData|UserDevice|UXInit|Wallpaper|backdrop|Personal|CloudDesktop|SecHealth|TabSvc|TaskFlow|UserActivity|Autofill)' },
  @{ Key='netfx';  P='^(mscoree|mscor[a-z]*|clrjit|clrhost|coreclr|hostfxr|hostpolicy|System\.|Microsoft\.|Windows\.|UIAutomation(Client|ClientSideProviders)|Presentation(Core|Framework)|WindowsBase|Accessibility|NETStandard|netstandard|api-ms-win-core-managed|vcomp\d|vcamp\d|vccorlib\d|mfc\d|mfcm\d|atl(thunk)?|atl100)' },
  @{ Key='msapps'; P='^(MicrosoftEdge|microsoftEdge|msedge|Edge|GameBar|GameInput|GamePanel|xbox|Xbl|Xbox|Map|Maps|People|AppInstaller|AppX|Appx|WindowsStore|Store|Widgets|Copilot|Cortana|msdt|Microsoft\.Data|Microsoft\.Uev|Microsoft\.Internal|OneDrive|OneCore|dm[a-z]+|Diag|diagtrack|Search|sync[^t]|phon[^o]|enterprise|clou|micr)' },
  @{ Key='vm';     P='^(vm[a-z]|vmbus|vmic|HvSocket|Hv[A-Z]|hcs|hyper|Hyper|container|wsl|bcd|vmcompute)' },
  @{ Key='sec';    P='^(advapi32|bcrypt|ncrypt|crypt|wintrust|secur32|sspicli|sspisrv|sspi|lsa|sam|netlogon|vault|cred|authz|auth|authui|capauthz|token|keyiso|schannel|msasn1|softpub|dpapi|rsaenh|kdcom|kdnet|kdstub|tbs|Tpm|webauthn|winbio|Bio|face|fingerprint|pluton|secfw|mcupdate|dsreg|pku2u|Cert|credui|cryptui|libcrypto|libssl|eap|raschap|cng|pki|wlid|smar|eas|consent|KeyCred|localSec|Seclogon)' },
  @{ Key='net';    P='^(ws2_32|wsock32|mswsock|winhttp|wininet|urlmon|dns|iphlp|netapi32|httpapi|Firewall|wldap|rasapi32|rasman|ras|mpr|netman|netprof|snmp|wsnmp|mshtml|mshtmled|chakra|Chakra|edgehtml|iertutil|ncsi|ncb|netbios|NTlanman|wkssvc|srvcli|ipnathlp|tapi|icmp|HNetCfg|net|network|Wlan|wlansvc|wlan|WWAN|MPSSVC|netiohlp|iprtprio|IKEEXT|vpnike|NapCRYPT|NlaApi|ipsec|nsi|winrnr|winr|dnscache|httpprx|WebSocket|rpcns|rpcnsh|wship6|wshtcpip|cookie|bth|btserv|Bluetooth|rdp|peer|dot3|wifi|tap|winrs)' },
  @{ Key='gfx';    P='^(d3d|D3D|dxgi|DXGI|DXCore|dwrite|DWrite|d2d1|Direct2D|DirectML|directml|dcomp|WindowsCodecs|opengl32|glu32|vulkan|opencl|dxva2|D3DSCache|dxtmsft|ig[a-z]|igfx|igd|IGFX|nv[a-z]+|ig4icd|igdde|igdumd|dxilconv|dxdiagn|dxtrans|dxp|disp|Display|GL)' },
  @{ Key='mm';     P='^(mf[a-z]|MF[A-Z]|MediaFoundation|avrt|avicap32|avifil32|winmm|msvfw32|msacm32|mci[a-z]|dsound|MMDevAPI|mmgaclient|mmgaproxystub|evr|qedit|wmvcore|msmpeg2|wmdm|wmsgapi|MSVidCtl|msvidc32|tsbyuv|midi|Midi|audi|Audi|play|Play|RtpMedia|MM[A-Z])' },
  @{ Key='input';  P='^(input|dinput|hid|XInput|xinput|GameInput|softkbd|globinput|umdhpm)' },
  @{ Key='ui';     P='^(user32|gdi32|GdiPlus|dwmapi|dwmcore|uDWM|uxtheme|uxlib|uireng|uxinit|UXFrame|imm32|comctl32|comdlg32|shell32|shlwapi|propsys|oleacc|UIAutomationCore|msctf|usp10|twin|directmanipulation|shcore|SHCore|shfolder|shdocvw|shimgvw|shpafact|shsetup|shsvcs|ExplorerFrame|DesktopShellExt|thumbcache|StructuredQuery|Taskbar|SwitcherDataModel|StartTileData|taskbarcpl|UIAnimation|Logon|Lock|clip|Clip|acti|Acti|boot|auto|Auto|usercpl|Theme)' },
  @{ Key='store';  P='^(fltlib|flt|fve|cscapi|Csc|StorageUsage|storagewmi|defragproxy|defragres|ulib|ufat|uexfat|untfs|uReFS|Wof|cabinet|cabapi|ntfs|dfs|clfs|stor|wof|sdengin|disk|fsutil|vss|UnionFS|LinkInfo|iscs|Work|work)' },
  @{ Key='dev';    P='^(cfgmgr32|setupapi|devobj|newdev|devpkey|DevPropMgr|devinv|devmgr|pnp|PnP|hidclass|usb|Usb|acpi|ACPI|HalExt|hal|wdf|Wdf|WUDF|wudf|wudriver|wcm|Hdcp|BthPan|usbceip|HidCfu|hidserv|CompPkg|drvstore|cimfs|Sensors|sensor|batt|devi|Devi|Devic|prov|prov)' },
  @{ Key='data';   P='^(msi|oledb32|odbc|sqlsrv32|winsqlite3|esent|StructuredQuery|xmllite|msxml|xmlprovi|xmlfilter|json|GeoCommon|sqmapi|AppxPackaging|unattend)' },
  @{ Key='locale'; P='^(Nls|NLS|getuname|normaliz|mlang|BCP47|Language|KBD|kbd|fnt|Fnt|font|TextShaping|Riched|riched|lingu|Enumerat|locale|Locale|BaseN)' },
  @{ Key='print';  P='^(print|Print|spool|wia|Wia|Scanner|WSDPrint|XpsPrint|Camera|MFP)' },
  @{ Key='debug';  P='^(dbghelp|dbgcore|DbgModel|dbgeng|psapi|pdh|verifier|wer|wevt|wbem|wmi|wmiclnt|wmidx|imagehlp|apphelp|diagperf|DiagCpl|WinSAT|windiag|WPP|clfsw32|sqm|Microsoft-Windows-|sysmain|syssetup|SysFxUI|DiagnosticData|powercpl|energy|dbnetlib|perf|Perf|kd_|sdiag)' },
  @{ Key='proc';   P='^(services|svchost|lsass|smss|csrss|wininit|winlogon|userinit|taskhostw|dllhost|conhost|sechost|spoolsv|dwm|sihost|RuntimeBroker|Background|background|ApplicationFrame|LogonUI|LockAppHost|wuau|wusa|wuapi|UsoClient|TrustedInstaller|SecurityHealth|wermgr|WerFault|wecutil|wecapi|Reg|regsvc|regapi|trkwks|taskschd|sched|relog|proquota|AppV|SyncHost|sppsvc|sfc|Dism|comppkg|CompPkg|appi|task|Task|scannow|upfc|updatecli)' },
  @{ Key='core';   P='^(ntoskrnl|ntdll|kernel32|KernelBase|kernel\.appcore|hal|win32u|wow64|msvcrt|ucrtbase|vcruntime|msvcp|msvcr|vcomp|concrt|api-ms-win-|ext-ms-win-|oldnames|nul$|nlaapi|NlaApi|vfpapi|boot|core|Core)' },
  @{ Key='3rd';    P='^(igfx|igd|ig4|iglh|libcrypto|libssl|liblouis|libsmartscreen|webthreatdef|nvspcap|vbox|vmware)' }
)

function Get-ApiSetCat {
    param([string]$Name)
    if ($Name -match '^(?:api|ext)-ms-win-(?<g>[a-z0-9]+)-') {
        $g = $matches['g']
        switch -Regex ($g) {
            '^(core|downlevel|nt|base|synch|priv|profile|registry|system|lifetime|sxs|winrt|namespace|service|heap|time)' { return 'core' }
            '^(security|crypt|sspi|sspicli|ntlsa|lsa|tpm|credential|biometric|identity)' { return 'sec' }
            '^(net|networking|ip|http|winhttp|wininet|dns|schannel|wlan|wwan|bluetooth|websocket|rpc-http)' { return 'net' }
            '^(ui|ntuser|shell|comctl32|gdi|wingdi|winuser|uiautomation|xaml|winui|propsys|winsta|input|dwm|sidebyside|com|ole|rpc|midl)' { return 'ui' }
            '^(graphics|dxgi|d3d|direct2d|dxgi-|imaging)' { return 'gfx' }
            '^(media|audio|video|mf)' { return 'mm' }
            '^(storage|fs|ntio|io-|volume)' { return 'store' }
            '^(globalization|intl|text)' { return 'locale' }
            default { return 'other' }
        }
    }
    return $null
}

function Get-Cat {
    param([string]$Name)
    if ($Name -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-') { return 'policy' }
    $api = Get-ApiSetCat $Name
    if ($api) { return $api }
    foreach ($r in $rules) { if ($Name -match $r.P) { return $r.Key } }
    return 'other'
}

function Clean-Desc {
    param([string]$D, [string]$Name)
    if ([string]::IsNullOrWhiteSpace($D)) { return $null }
    $s = ($D -replace '[^\x20-\x7E]', '') -replace '\s+', ' '
    $s = $s -replace '\s*\(.*\)\s*$', ''
    $s = $s -replace '\s*[-]\s*(64|32)-bit.*$', ''
    $s = $s -replace '\s*[-]\s*Windows.*$', ''
    $s = ($s.Trim() -replace '[\s\-\.]+$', '')
    if ($s.Length -gt 150) { $s = $s.Substring(0,147) + '...' }
    if ($s.Length -lt 3) { return $null }
    # deskripsi yang isinya cuma mengulang nama file tidak menambah informasi
    $bare = [IO.Path]::GetFileNameWithoutExtension($Name)
    if ($s -ieq $bare -or $s -ieq $Name) { return $null }
    return $s
}

function Clean-Ver {
    param([string]$V)
    if ([string]::IsNullOrWhiteSpace($V)) { return '-' }
    return ($V -replace '\s*\(.*\)\s*$', '').Trim()
}

function Fmt-Size {
    param([double]$Bytes)
    if ($Bytes -ge 1MB) { return ('{0:0.0} MB' -f ($Bytes/1MB)) }
    if ($Bytes -ge 1KB) { return ('{0} KB' -f [math]::Round($Bytes/1KB)) }
    return ('{0} B' -f [math]::Round($Bytes))
}

function Esc {
    param([string]$S)
    if ($null -eq $S) { return '' }
    return ($S -replace '\|', '/' -replace '\s+', ' ').Trim()
}

$raw = Import-Csv -LiteralPath $csvPath
$list = New-Object System.Collections.Generic.List[object]
foreach ($r in $raw) {
    $dc = Clean-Desc $r.Description $r.Name
    if ($curated.ContainsKey($r.Name)) { $ex = $curated[$r.Name]; $sc = 'kurasi' }
    elseif ($dc) { $ex = $dc; $sc = 'metadata' }
    else { $ex = 'Komponen internal tanpa metadata versi; fungsi spesifiknya tidak terdokumentasi publik.'; $sc = 'kosong' }
    $list.Add([PSCustomObject]@{
        Name        = $r.Name
        Ext         = $r.Ext
        SizeBytes   = [double]($r.SizeKB) * 1KB
        FileVersion = (Clean-Ver $r.FileVersion)
        Cat         = (Get-Cat $r.Name)
        Expl        = $ex
        Src         = $sc
    })
}
$rows = $list.ToArray()

$used = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($r in $rows) { [void]$used.Add($r.Name) }
$unmatched = @($curated.Keys | Where-Object { -not $used.Contains($_) })

$exe = @($rows | Where-Object { $_.Ext -eq 'EXE' } | Sort-Object Name)
$dll = @($rows | Where-Object { $_.Ext -eq 'DLL' } | Sort-Object Name)

$now = Get-Date -Format 'yyyy-MM-dd HH:mm'
$os  = Get-CimInstance Win32_OperatingSystem
$totalSize = ($rows | Measure-Object -Property SizeBytes -Sum).Sum
$curCount  = @($rows | Where-Object { $_.Src -eq 'kurasi' }).Count
$metaCount = @($rows | Where-Object { $_.Src -eq 'metadata' }).Count
$noneCount = @($rows | Where-Object { $_.Src -eq 'kosong' }).Count

$apiCount = @($dll | Where-Object { $_.Name -match '^(api|ext)-ms-win-' }).Count

$deep = @(
 @{ N='ntdll.dll'; T='Lantai bawah Windows';
   B='Semua syscall Windows melewati ntdll.dll. Nama fungsi berawalan Nt (misalnya NtCreateFile atau NtAllocateVirtualMemory) adalah lapisan internal yang tidak dijamin stabil antar versi, sedangkan Zw adalah alias yang sama untuk mode user. Karena itu file ini jadi sasaran pertama tool debugging, antivirus, dan teknik hooking.' },
 @{ N='kernel32.dll'; T='Gerbang Win32';
   B='Pintu masuk API Win32 yang paling sering dipakai aplikasi: CreateFile, CreateProcess, VirtualAlloc, HeapAlloc, ReadFile, ExitProcess. Pada Windows modern sebagian besar implementasi dipindahkan ke KernelBase.dll sehingga kernel32 menjadi lapisan tipis yang meneruskan ke ntdll. Urutan load ntdll, kernel32, lalu KernelBase di Process Explorer mencerminkan chain ini.' },
 @{ N='KernelBase.dll'; T='Implementasi Win32 yang tidak diekspor';
   B='Berisi implementasi nyata Win32 yang tidak lagi diekspor sebagai API publik. kernel32.dll tetap mengekspor nama fungsi yang sama, tetapi panggilan pertama sudah masuk ke sini. Aplikasi tidak boleh mengimpornya langsung.' },
 @{ N='hal.dll'; T='Hardware Abstraction Layer';
   B='Lapisan paling tipis di atas kernel: menyembunyikan perbedaan chipset (interrupt controller, timer, cache, DMA) dari kernel. Varian seperti HalExtIntcLpioDMA.dll adalah pisau HAL khusus vendor. Kerusakan di sini biasanya muncul sebagai BSOD pada tahap boot paling awal.' },
 @{ N='win32u.dll'; T='Jembatan USER dan GDI mode user';
   B='Semua panggilan USER (window, message, input) dan GDI (drawing) dari mode user melewati win32u.dll menuju win32k.sys di kernel. Karena itu file ini penting saat menelusuri dialog yang menggantung: fungsi seperti NtUserMessageBox ada di sini.' },
 @{ N='advapi32.dll'; T='Registry, keamanan, service, dan akun';
   B='Bungkus API yang sudah berumur decades: registry (RegOpenKeyEx), security descriptor, akun pengguna, token, registrasi service, audit log, serta bridge ke API Event Log. Hampir setiap proses yang menyentuh registry atau hak akses memuatnya, sehingga file ini juga sering dipakai malware untuk persistensi.' },
 @{ N='user32.dll'; T='Jendela, pesan, dan input';
   B='Inti Win32 yang dilihat pengguna: CreateWindow, SendMessage, GetMessage, keyboard, mouse, dan dialog. Message loop berbasis window membuat program berjalan secara event driven; deadlock UI biasanya terlihat di sini. Gangguan di user32.dll sering muncul sebagai aplikasi tidak merespons.' },
 @{ N='ole32.dll dan oleaut32.dll'; T='COM, OLE, dan Automation';
   B='ole32.dll menangani object linking, moniker, dan storage streams. oleaut32.dll mengimplementasikan OLE Automation yang dipakai Excel dan Word untuk dikendalikan dari script. Keduanya berakhir di combase.dll sebagai implementasi modern.' },
 @{ N='comctl32.dll'; T='Kontrol common Windows';
   B='Control kit standar: TreeView, ListView, Tab, Toolbar, Status Bar, Progress Bar, dan DateTime Picker. Versi 6 sudah membawa visual styles sehingga tidak lagi butuh comctl32.dll lawas. Program yang masih menunjuk versi 5 biasanya kehilangan tema dan dukungan keyboard.' },
 @{ N='ws2_32.dll'; T='Winsock 2';
   B='API socket untuk semua proses mode user: socket, connect, send, recv, getaddrinfo, serta fungsi lanjutan seperti WSASend. Windows Filtering Platform bekerja di kernel, sehingga sebagian operasi socket tampak lambat atau gagal saat firewall dan antivirus menginspeksi trafik. Error yang sering muncul: WSAECONNRESET, WSAETIMEDOUT, WSAEACCES.' },
 @{ N='winhttp.dll'; T='HTTP untuk service dan aplikasi native';
   B='Dipakai oleh service, PowerShell, dan tool CLI karena tidak bergantung pada WinINet atau Internet Explorer, serta mendukung WinRM. Opsi SESSION_KEEPALIVE dipakai untuk koneksi panjang, dan file ini sering menjadi biang timeout saat ada proxy di tengah.' },
 @{ N='crypt32.dll'; T='Sertifikat, PKI, dan Certificate Store';
   B='Implementasi certificate store dan PKI: CertificateOpenStore, CertOpenSystemStore, dan CertVerifyCertificateChainPolicy. TLS dan BitLocker memakai WinTrust di atasnya. Kerusakan pada store sertifikat pengguna sering membuat validasi rantai sertifikat gagal.' },
 @{ N='bcrypt.dll'; T='Kriptografi modern (CNG)';
   B='Pengganti CryptoAPI: AES-GCM, RSA-OAEP, SHA-2 dan SHA-3, HKDF, serta key storage provider. Varian seperti msvcp140_atomic_wait.dll adalah bagian lain dari runtime yang punya nama mirip, bukan bagian dari bcrypt. Hampir semua proses modern memuatnya, termasuk antivirus dan browser.' },
 @{ N='shlwapi.dll'; T='Utilitas shell yang ringan';
   B='Path manipulation, URL parsing, registry string helper, dan bargaining string yang banyak dipakai kode lama. Tidak sebesar user32.dll, tetapi sengaja dibuat ringan agar aman dipanggil dari banyak konteks.' },
 @{ N='msvcrt.dll dan ucrtbase.dll'; T='Dua generasi C runtime';
   B='msvcrt.dll adalah runtime Visual C++ lama yang masih jadi default PATH search untuk aplikasi warisan, sedangkan ucrtbase.dll adalah Universal C Runtime modern. Inilah sebabnya sebagian aplikasi lebih dulu memuat msvcr100.dll atau vcruntime140.dll. Mencampur versi yang salah sering menghasilkan STATUS_ENTRYPOINT_NOT_FOUND.' },
 @{ N='api-ms-win-* dan ext-ms-win-*'; T='API Set stub';
   B='Bukan implementasi, melainkan stub yang memetakan nama API ke DLL asli. Contohnya api-ms-win-core-synch-l1-1-0.dll diarahkan ke KernelBase.dll. Windows memuatnya saat proses start, sehingga pada Windows lama jumlahnya sangat banyak. Pada Windows 11 build terbaru stub seperti ini tidak lagi ada di System32, dan dipindah ke lokasi internal lain. Jika stub hilang, proses gagal start dengan ERROR_MOD_NOT_FOUND walaupun file aslinya masih ada.' }
)

$md = New-Object System.Collections.Generic.List[string]
function A([string]$s) { $md.Add($s) }

A '# Inventaris File C:\Windows\System32 - EXE dan DLL'
A ''
A '> **Halaman interaktif:** https://adyoi.github.io/system32-inventory/ - versi lengkap dengan pencarian, filter, dan sortir. Buka juga secara lokal lewat `docs\index.html` tanpa server.'
A '>'
A '> Repo dokumentasi pribadi, tidak berafiliasi dengan atau didukung Microsoft.'
A ''
A 'Inventaris lengkap file .exe dan .dll di C:\Windows\System32, disortir per kategori dan per nama, dengan penjelasan singkat fungsi tiap file.'
A ''
A ("- **Sistem ini:** $($os.Caption), versi $($os.Version) (build $($os.BuildNumber))")
A ("- **Waktu generate:** $now")
A ("- **Jumlah file:** $($rows.Count) total, yaitu $($exe.Count) EXE dan $($dll.Count) DLL")
A ("- **Total ukuran:** $(Fmt-Size $totalSize)")
A ("- **Sumber penjelasan:** $curCount file punya penjelasan kurasi manual, $metaCount file memakai FileDescription dari metadata versi, $noneCount file tidak punya metadata sehingga ditandai eksplisit.")
A ''
A '## Daftar isi'
A ''
A '1. [Cara memakai dokumen ini](#1-cara-memakai-dokumen-ini)'
A '2. [Apa itu System32](#2-apa-itu-system32)'
A '3. [Kategori file](#3-kategori-file)'
A '4. [File inti](#4-file-inti)'
A '5. [Catatan praktis](#5-catatan-praktis)'
A '6. [Cara regenerate](#appendix-cara-regenerate)'
A ''
A '---'
A ''
A '## 1. Cara memakai dokumen ini'
A ''
A '**Inventaris lengkapnya ada di [docs/index.html](docs/index.html)** atau online di **https://adyoi.github.io/system32-inventory/** - satu file HTML yang bisa dibuka langsung di browser, tanpa server dan tanpa koneksi internet. README ini hanya ringkasan; daftar 4.267 file per kategori tidak diulang di sini.'
A ''
A 'Yang bisa dilakukan di halaman HTML:'
A ''
A '- **Cari** nama file atau kata kunci di penjelasannya, misalnya `ws2_32`, `BitLocker`, atau `font`.'
A '- **Saring** berdasarkan tipe (EXE/DLL), kategori, atau tombol **Kurasi saja** untuk melihat file yang penjelasannya ditulis manual.'
A '- **Urutkan** dengan klik header kolom File, Ukuran, Versi, atau Kategori, atau lewat dropdown pengurutan.'
A '- **Unduh CSV** hasil filter yang sedang aktif.'
A '- **Ganti tema** terang/gelap; di layar sempit tabel berubah menjadi kartu.'
A '- **Baca penjelasan file inti** di blok "Penjelasan file inti (deep dive)" di bagian atas halaman.'
A ''
A 'Kolom yang dipakai di halaman HTML:'
A ''
A '| Kolom | Arti |'
A '|---|---|'
A '| File | Nama file apa adanya di System32, termasuk kapitalisasinya |'
A '| Ukuran | Ukuran file di disk dalam KB atau MB |'
A '| Versi | Ambil dari sumber daya versi file (FileVersion), bukan versi produk |'
A '| Kategori | Kelompok fungsi file; urutan kategori mengikuti urutan logis di bagian 3 |'
A '| Penjelasan | Kurasi manual, atau FileDescription dari metadata file, atau catatan bahwa tidak terdokumentasi |'
A ''
A '## 2. Apa itu System32'
A ''
A 'C:\Windows\System32 adalah direktori inti sistem operasi Windows. Nama "System32" berasal dari pustaka untuk sistem 32-bit, dan itu benar untuk Windows 95/98 serta edisi 32-bit. Pada Windows 64-bit, folder ini berisi pustaka 64-bit, sedangkan pustaka 32-bit pindah ke C:\Windows\SysWOW64 (WOW64 berarti Windows on Windows 64-bit, bukan kebalikannya).'
A ''
A 'Isi folder ini pada dasarnya empat kelompok:'
A ''
A '- **Executable sistem dan utilitas** - proses boot seperti smss.exe, csrss.exe, dan winlogon.exe; host service svchost.exe; serta utilitas command prompt seperti ipconfig.exe dan robocopy.exe. Perhatikan bahwa pada Windows 11 build terbaru beberapa executable justru berada di C:\Windows (contohnya explorer.exe), bukan di System32.'
A '- **API DLL** - implementasi Win32 dan WinNT yang dipakai semua aplikasi: kernel32.dll, user32.dll, advapi32.dll, gdi32.dll.'
A '- **Komponen produk Microsoft** - Edge, Xbox Game Bar, Maps, App Installer, serta API modern WinRT dan .NET yang masih di-host di sini.'
A '- **Driver dan pustaka vendor** - Intel Graphics (igd*.dll), OpenSSL (libcrypto*.dll), atau plugin keamanan pihak ketiga yang ikut terpasang di System32.'
A ''
A 'Selain .exe dan .dll, folder ini juga berisi driver .sys, pustaka 32-bit warisan, Control Panel applet .cpl, font metric, dan command script. Dokumen ini sengaja hanya mencakup .exe dan .dll.'
A ''
A '> **Penting:** folder ini dilindungi Windows Resource Protection. File di dalamnya tidak boleh dipindah, diubah nama, dihapus, atau "dibersihkan" manual. Perubahan yang tidak disengaja dapat membuat Windows gagal boot atau service tidak berjalan.'
A ''
A '## 3. Kategori file'
A ''
A 'Jumlah file per kategori (EXE dan DLL digabung):'
A ''
A '| # | Kategori | Jumlah |'
A '|---:|---|---:|'
$ci = 0
foreach ($c in $cats) {
    $ci++
    A "| $ci | $($c.Title) | $(@($rows | Where-Object { $_.Cat -eq $c.Key }).Count) |"
}
A ''
foreach ($c in $cats) {
    A "- **$($c.Title)** - $($c.Desc)"
}
A ''
A '## 4. File inti'
A ''
A 'Kalau bermasalah dengan satu file, biasanya ini daftar file yang paling sering ditanya. Penjelasan lengkapnya ada di blok deep dive di [halaman interaktif](https://adyoi.github.io/system32-inventory/).'
A ''
A '| File | Fungsi |'
A '|---|---|'
foreach ($d in $deep) {
    if ($apiCount -eq 0 -and $d.N -match 'api-ms-win-\*') { continue }
    A "| ``$($d.N)`` | $($d.T) |"
}
A ''
A '## 5. Catatan praktis'
A ''
A '- **Jangan menebak file yang "bisa dihapus".** Ukuran System32 yang besar itu normal. Kalau HDD atau SSD penuh, jalur aman adalah Storage Sense, `Dism.exe /Online /Cleanup-Image /StartComponentCleanup`, atau mematikan hibernasi dengan `powercfg /h off`.'
A '- **Duplikasi itu normal.** Banyak file juga ada di C:\Windows\WinSxS dan C:\Windows\SysWOW64 karena Windows menyimpan beberapa versi tiap komponen untuk rollback pembaruan.'
A '- **Error Bad Image atau ERROR_MOD_NOT_FOUND** sering berarti versi file tidak cocok antar komponen, bukan file hilang. Urutan perbaikan yang wajar: `Dism.exe /Online /Cleanup-Image /RestoreHealth` lalu `sfc.exe /scannow`.'
A '- **Blue screen dengan kode STOP 0x0000007E atau 0x000000EF** biasanya menunjuk ke file driver tertentu yang disebut di akhir layar; kolom pada tabel ini membantu mencocokkan nama file tersebut.'
A '- **Perspektif keamanan** - beberapa DLL di sini bisa disalahgunakan sebagai living-off-the-land binary, misalnya regsvr32.exe, rundll32.exe, mshta.exe, dan msiexec.exe. Sysinternals Sigcheck dan Sysmon membantu membedakan pemakaian yang wajar.'
A '- **Dokumen ini read-only** - isinya deskripsi file, bukan daftar file yang boleh dihapus.'
if ($apiCount -eq 0) {
    A '- **Tidak ada stub API set** (api-ms-win-* atau ext-ms-win-*) di System32 pada sistem ini. Pada Windows versi lama file seperti itu sangat banyak; pada build terbaru Windows menyimpannya di lokasi lain sehingga System32 jauh lebih bersih.'
} else {
    A "- **Termasuk $apiCount stub API set** (api-ms-win-* dan ext-ms-win-*)."
}
$none = @($rows | Where-Object { $_.Src -eq 'kosong' })
A "- **$($none.Count) file tanpa metadata versi** tidak punya FileDescription, jadi penjelasannya tidak bisa diambil otomatis. Di halaman HTML, cari dengan filter **Kurasi saja** untuk melihat mana yang sudah dijelaskan manual."
A ''
A '---'
A ''
A '## Appendix: cara regenerate'
A ''
A '```powershell'
A 'powershell -NoProfile -ExecutionPolicy Bypass -File tools\gen_docs.ps1'
A '```'
A ''
A '`tools\gen_readme.ps1` mengumpulkan inventaris dari metadata versi file lalu menulis README.md dan `tools\sys32_inventory.csv`. `tools\gen_docs.ps1` memakai skrip itu dan menulis halaman interaktif ke `docs\index.html`, yang menjadi sumber GitHub Pages repo ini. Data inventaris diambil langsung dari sumber daya versi file, tanpa alat pihak ketiga:'
A ''
A '```powershell'
A 'Get-ChildItem C:\Windows\System32 -File |'
A '  Where-Object { $_.Extension -in ".dll", ".exe" } |'
A '  ForEach-Object {'
A '    [PSCustomObject]@{'
A '      Name        = $_.Name'
A '      SizeKB      = [math]::Round($_.Length/1KB)'
A '      FileVersion = $_.VersionInfo.FileVersion'
A '      Description = $_.VersionInfo.FileDescription'
A '    }'
A '  }'
A '```'
A ''

[IO.File]::WriteAllLines($outPath, $md, (New-Object System.Text.UTF8Encoding($false)))

"OK -> $outPath"
"lines : $($md.Count)"
"rows  : $($rows.Count) (EXE $($exe.Count) / DLL $($dll.Count))"
"curated valid : $($curated.Count) (dropped EXE $($exeC.Dropped), dropped DLL $($dllC.Dropped))"
"curated unused: $($unmatched.Count)"
if ($unmatched.Count -gt 0) { "UNUSED: $($unmatched -join ', ')" }
"explain       : kurasi $curCount / metadata $metaCount / kosong $noneCount"
foreach ($c in $cats) { $n = @($rows | Where-Object { $_.Cat -eq $c.Key }).Count; "  $($c.Key): $n" }