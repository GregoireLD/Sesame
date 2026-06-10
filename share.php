<?php
$langs = [
  'fr' => ['title' => 'Sesame — Code d\'accès partagé', 'desc' => 'Quelqu\'un a partagé un code d\'accès avec vous. Ouvrez pour le voir.', 'image' => 'https://sesame-app.com/images/sesame_newcode_fr.png'],
  'de' => ['title' => 'Sesame — Geteilter Zugangscode', 'desc' => 'Jemand hat einen Zugangscode mit dir geteilt. Öffnen, um ihn anzuzeigen.', 'image' => 'https://sesame-app.com/images/sesame_newcode_de.png'],
  'es' => ['title' => 'Sesame — Código de acceso compartido', 'desc' => 'Alguien ha compartido un código de acceso contigo. Ábrelo para verlo.', 'image' => 'https://sesame-app.com/images/sesame_newcode_es.png'],
  'it' => ['title' => 'Sesame — Codice di accesso condiviso', 'desc' => 'Qualcuno ha condiviso un codice di accesso con te. Aprilo per vederlo.', 'image' => 'https://sesame-app.com/images/sesame_newcode_it.png'],
  'ja' => ['title' => 'Sesame — アクセスコードが共有されました', 'desc' => 'アクセスコードが共有されました。開いて確認してください。', 'image' => 'https://sesame-app.com/images/sesame_newcode_ja.png'],
  'ko' => ['title' => 'Sesame — 출입 코드가 공유되었습니다', 'desc' => '누군가 출입 코드를 공유했습니다. 열어서 확인하세요.', 'image' => 'https://sesame-app.com/images/sesame_newcode_ko.png'],
  'zh' => ['title' => 'Sesame — 共享的门禁代码', 'desc' => '有人与您共享了门禁代码。打开查看。', 'image' => 'https://sesame-app.com/images/sesame_newcode_zh.png'],
  'ar' => ['title' => 'Sesame — رمز دخول مشترك', 'desc' => 'شارك شخص ما رمز دخول معك. افتحه لرؤيته.', 'image' => 'https://sesame-app.com/images/sesame_newcode_ar.png'],
];

$title = 'Sesame — Shared Access Code';
$desc  = 'Someone shared an access code with you. Open to view it.';
$ogimage = 'https://sesame-app.com/images/sesame_newcode_en.png';
$url   = 'https://sesame-app.com/share';

$accept = $_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? '';
foreach ($langs as $code => $strings) {
  if (stripos($accept, $code) !== false) {
    $title = $strings['title'];
    $desc  = $strings['desc'];
    $ogimage = $strings['image'];
    break;
  }
}

// connect-src 'none' is the load-bearing line: structurally forbids the page
// from sending the URL fragment (which contains the access code) over the network.
header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; img-src 'self' https://sesame-app.com data:; connect-src 'none'");
?>
<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />

  <title><?= htmlspecialchars($title) ?></title>
  <meta name="description" content="<?= htmlspecialchars($desc) ?>" />
  <meta property="og:title" content="<?= htmlspecialchars($title) ?>" />
  <meta property="og:description" content="<?= htmlspecialchars($desc) ?>" />
  <meta property="og:url" content="<?= htmlspecialchars($url) ?>" />

  <meta property="og:image" content="<?= htmlspecialchars($ogimage) ?>" />
  <meta property="og:type" content="website" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:image" content="<?= htmlspecialchars($ogimage) ?>" />

  <link rel="icon" href="https://sesame-app.com/images/sesame.png" />
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;1,400&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet" />

  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --gold: #c9a84c;
      --gold-light: #e0c070;
      --radius: 20px;
      --radius-sm: 12px;
      --transition: 0.2s ease;
    }

    :root {
      --bg: #0d1b2a;
      --bg-card: #162032;
      --bg-code: #0a1520;
      --border: rgba(201,168,76,0.18);
      --text-primary: #f5f0e8;
      --text-secondary: rgba(245,240,232,0.6);
      --text-tertiary: rgba(245,240,232,0.35);
      --btn-primary-bg: #c9a84c;
      --btn-primary-text: #0d1b2a;
      --btn-secondary-bg: transparent;
      --btn-secondary-border: rgba(201,168,76,0.3);
      --btn-secondary-text: rgba(245,240,232,0.7);
    }

    @media (prefers-color-scheme: light) {
      :root {
        --bg: #f5f0e8;
        --bg-card: #ffffff;
        --bg-code: #eee8da;
        --border: rgba(139,107,40,0.18);
        --text-primary: #0d1b2a;
        --text-secondary: rgba(13,27,42,0.6);
        --text-tertiary: rgba(13,27,42,0.35);
        --btn-primary-bg: #c9a84c;
        --btn-primary-text: #ffffff;
        --btn-secondary-bg: transparent;
        --btn-secondary-border: rgba(13,27,42,0.2);
        --btn-secondary-text: rgba(13,27,42,0.6);
      }
    }

    html, body {
      min-height: 100dvh;
      background: var(--bg);
      color: var(--text-primary);
      font-family: 'DM Sans', sans-serif;
      font-weight: 300;
      line-height: 1.6;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px;
      gap: 16px;
    }

    /* ── Language bar ─────────────────────────────────────── */
    .lang-bar {
      position: fixed;
      top: 0; left: 0; right: 0;
      z-index: 100;
      background: rgba(13,27,42,0.88);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--border);
      padding: 0 16px;
      height: 44px;
      display: flex;
      align-items: center;
      justify-content: flex-end;
      gap: 3px;
      direction: ltr;
      unicode-bidi: isolate;
    }

    @media (prefers-color-scheme: light) {
      .lang-bar { background: rgba(245,240,232,0.92); }
    }

    .lang-pills { display: flex; gap: 3px; flex-wrap: nowrap; }

    .lang-btn {
      background: none;
      border: 1px solid transparent;
      color: var(--text-secondary);
      font-family: 'DM Sans', sans-serif;
      font-size: 10px;
      font-weight: 500;
      letter-spacing: 0.04em;
      padding: 3px 7px;
      border-radius: 5px;
      cursor: pointer;
      transition: all 0.2s;
      white-space: nowrap;
    }

    .lang-btn:hover { color: var(--gold-light); border-color: var(--border); }
    .lang-btn.active { color: var(--gold); border-color: var(--gold); background: rgba(201,168,76,0.08); }

    .lang-select-wrap { display: none; }
    .lang-select {
      background: var(--bg-card);
      border: 1px solid var(--border);
      color: var(--text-primary);
      font-family: 'DM Sans', sans-serif;
      font-size: 12px;
      padding: 5px 10px;
      border-radius: 7px;
      cursor: pointer;
      outline: none;
    }

    @media (max-width: 780px) {
      .lang-pills { display: none; }
      .lang-select-wrap { display: block; }
    }

    /* ── Card ────────────────────────────────────────────── */
    .card {
      width: 100%;
      max-width: 420px;
      background: var(--bg-card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 36px 32px;
      box-shadow: 0 24px 64px rgba(0,0,0,0.25);
      animation: fadeUp 0.4s ease both;
      margin-top: 44px;
    }

    @keyframes fadeUp {
      from { opacity: 0; transform: translateY(12px); }
      to   { opacity: 1; transform: translateY(0); }
    }

    .header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 28px;
    }

    .app-icon {
      width: 44px;
      height: 44px;
      border-radius: 10px;
      flex-shrink: 0;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    }

    .header-text { display: flex; flex-direction: column; gap: 1px; }

    .app-name {
      font-family: 'Cormorant Garamond', serif;
      font-size: 20px;
      font-weight: 600;
      color: var(--text-primary);
      line-height: 1;
    }

    .shared-by { font-size: 12px; color: var(--text-tertiary); letter-spacing: 0.02em; }

    .entry {
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      padding: 20px;
      margin-bottom: 24px;
    }

    .entry-label {
      font-family: 'Cormorant Garamond', serif;
      font-size: 26px;
      font-weight: 600;
      color: var(--text-primary);
      line-height: 1.1;
      margin-bottom: 6px;
    }

    .entry-address {
      font-size: 13px;
      color: var(--text-secondary);
      margin-bottom: 20px;
      display: flex;
      align-items: flex-start;
      gap: 6px;
    }

    .entry-address svg { flex-shrink: 0; margin-top: 1px; opacity: 0.5; }

    .divider { height: 1px; background: var(--border); margin-bottom: 20px; }

    .code-label {
      font-size: 10px;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      color: var(--text-tertiary);
      margin-bottom: 8px;
    }

    .code-display {
        background: var(--bg-code);
        border: 1px solid var(--border);
        border-radius: 8px;
        padding: 14px 16px;
        display: flex;
        align-items: flex-start; /* ← change from center to flex-start for multiline */
        justify-content: space-between;
        gap: 12px;
    }

    .code-wrap {
        position: relative;
        flex: 1;
        min-width: 0;
    }

    .code-sizer {
        display: block;
        opacity: 0;
        pointer-events: none;
        user-select: none;
        -webkit-user-select: none;
        font-family: 'SF Mono', 'Menlo', 'Consolas', monospace;
        font-size: 13px;
        font-weight: 500;
        line-height: 1.4;
        word-break: break-all;
    }

    .code-overlay {
        position: absolute;
        top: 0; left: 0; right: 0;
        font-family: 'SF Mono', 'Menlo', 'Consolas', monospace;
        font-size: 13px;
        font-weight: 500;
        color: var(--gold);
        word-break: break-all;
        line-height: 1.4;
    }

    .code-overlay.is-masked {
        font-size: 18px;
        letter-spacing: 0.2em;
        line-height: 1;
    }

    .reveal-btn {
      background: none;
      border: 1px solid var(--border);
      border-radius: 6px;
      padding: 6px 10px;
      cursor: pointer;
      color: var(--text-tertiary);
      font-size: 11px;
      font-family: 'DM Sans', sans-serif;
      transition: all var(--transition);
      white-space: nowrap;
      flex-shrink: 0;
    }

    .reveal-btn:hover { color: var(--gold); border-color: var(--gold); }

    .extra-fields { margin-top: 16px; display: flex; flex-direction: column; gap: 10px; }
    .extra-field { display: flex; gap: 8px; align-items: flex-start; }
    .extra-field svg { flex-shrink: 0; margin-top: 2px; opacity: 0.45; }
    .extra-field-content { display: flex; flex-direction: column; gap: 2px; }
    .extra-field-label { font-size: 10px; letter-spacing: 0.1em; text-transform: uppercase; color: var(--text-tertiary); }
    .extra-field-value { font-size: 13px; color: var(--text-secondary); line-height: 1.5; }

    .actions { display: flex; flex-direction: column; gap: 10px; }

    .btn-primary {
      display: flex; align-items: center; justify-content: center; gap: 8px;
      background: var(--btn-primary-bg); color: var(--btn-primary-text);
      font-family: 'DM Sans', sans-serif; font-weight: 500; font-size: 15px;
      padding: 14px 20px; border-radius: var(--radius-sm); border: none;
      cursor: pointer; text-decoration: none; transition: all var(--transition); width: 100%;
    }

    .btn-primary:hover { background: var(--gold-light); transform: translateY(-1px); box-shadow: 0 8px 20px rgba(201,168,76,0.25); }

    .btn-secondary {
      display: flex; align-items: center; justify-content: center; gap: 8px;
      text-align: center;
      background: var(--btn-secondary-bg); color: var(--btn-secondary-text);
      font-family: 'DM Sans', sans-serif; font-weight: 400; font-size: 13px;
      padding: 12px 20px; border-radius: var(--radius-sm);
      border: 1px solid var(--btn-secondary-border);
      cursor: pointer; text-decoration: none; transition: all var(--transition); width: 100%;
    }

    .btn-secondary:hover { border-color: var(--gold); color: var(--gold-light); }

    .note { margin-top: 20px; font-size: 11px; color: var(--text-tertiary); text-align: center; line-height: 1.6; }
    .note a { color: var(--text-tertiary); text-decoration: underline; text-underline-offset: 2px; }

    .error-state { text-align: center; padding: 12px 0; }
    .error-icon { font-size: 40px; margin-bottom: 16px; }
    .error-title { font-family: 'Cormorant Garamond', serif; font-size: 24px; font-weight: 600; color: var(--text-primary); margin-bottom: 8px; }
    .error-body { font-size: 13px; color: var(--text-secondary); margin-bottom: 24px; line-height: 1.6; }
  </style>
</head>
<body>

<!-- Language bar -->
<nav class="lang-bar" dir="ltr">
  <div class="lang-pills">
    <button class="lang-btn" data-code="en">🇬🇧 EN</button>
    <button class="lang-btn" data-code="fr">🇫🇷 FR</button>
    <button class="lang-btn" data-code="de">🇩🇪 DE</button>
    <button class="lang-btn" data-code="es">🇪🇸 ES</button>
    <button class="lang-btn" data-code="it">🇮🇹 IT</button>
    <button class="lang-btn" data-code="ja">🇯🇵 JA</button>
    <button class="lang-btn" data-code="ko">🇰🇷 KO</button>
    <button class="lang-btn" data-code="zh-hans">🇨🇳 ZH</button>
    <button class="lang-btn" data-code="zh-hant">🇹🇼 TW</button>
    <button class="lang-btn" data-code="ar">🇸🇦 AR</button>
  </div>
  <div class="lang-select-wrap">
    <select class="lang-select" id="lang-select">
      <option value="en">🇬🇧 EN</option>
      <option value="fr">🇫🇷 FR</option>
      <option value="de">🇩🇪 DE</option>
      <option value="es">🇪🇸 ES</option>
      <option value="it">🇮🇹 IT</option>
      <option value="ja">🇯🇵 JA</option>
      <option value="ko">🇰🇷 KO</option>
      <option value="zh-hans">🇨🇳 ZH</option>
      <option value="zh-hant">🇹🇼 TW</option>
      <option value="ar">🇸🇦 AR</option>
    </select>
  </div>
</nav>

<div class="card" id="card"></div>

<script>
  const APP_STORE_URL = 'https://apps.apple.com/fr/app/sesame-access-codes/id6760468434';
  const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.duval.sesamelite';
  const HOMEPAGE_URL  = 'https://sesame-app.com/';
  const LANGS = ['en','fr','de','es','it','ja','ko','zh-hans','zh-hant','ar'];
  const RTL_LANGS = ['ar'];

  // ── Translations ────────────────────────────────────────
  const T = {
    shared_by: {
      en: 'Shared access code', fr: 'Code d\'accès partagé', de: 'Geteilter Zugangscode',
      es: 'Código de acceso compartido', it: 'Codice di accesso condiviso',
      ja: '共有されたアクセスコード', ko: '공유된 출입 코드',
      'zh-hans': '共享的门禁代码', 'zh-hant': '共享的門禁代碼', ar: 'رمز دخول مشترك'
    },
    access_code: {
      en: 'Access code', fr: 'Code d\'accès', de: 'Zugangscode',
      es: 'Código de acceso', it: 'Codice di accesso',
      ja: 'アクセスコード', ko: '출입 코드',
      'zh-hans': '门禁代码', 'zh-hant': '門禁代碼', ar: 'رمز الدخول'
    },
    show: {
      en: 'Show', fr: 'Afficher', de: 'Anzeigen',
      es: 'Mostrar', it: 'Mostra',
      ja: '表示', ko: '보기',
      'zh-hans': '显示', 'zh-hant': '顯示', ar: 'إظهار'
    },
    hide: {
      en: 'Hide', fr: 'Masquer', de: 'Verbergen',
      es: 'Ocultar', it: 'Nascondi',
      ja: '非表示', ko: '숨기기',
      'zh-hans': '隐藏', 'zh-hant': '隱藏', ar: 'إخفاء'
    },
    location_details: {
      en: 'Location details', fr: 'Détails de l\'emplacement', de: 'Standortdetails',
      es: 'Detalles de ubicación', it: 'Dettagli posizione',
      ja: '場所の詳細', ko: '위치 세부 정보',
      'zh-hans': '位置详情', 'zh-hant': '位置詳情', ar: 'تفاصيل الموقع'
    },
    comment: {
      en: 'Comment', fr: 'Commentaire', de: 'Kommentar',
      es: 'Comentario', it: 'Commento',
      ja: 'コメント', ko: '코멘트',
      'zh-hans': '备注', 'zh-hant': '備註', ar: 'تعليق'
    },
    detection_radius: {
      en: 'Detection radius', fr: 'Rayon de détection', de: 'Erkennungsradius',
      es: 'Radio de detección', it: 'Raggio di rilevamento',
      ja: '検出半径', ko: '감지 반경',
      'zh-hans': '检测半径', 'zh-hant': '檢測半徑', ar: 'نطاق الاكتشاف'
    },
    add_to_sesame: {
      en: 'Add to Sesame', fr: 'Ajouter à Sesame', de: 'Zu Sesame hinzufügen',
      es: 'Añadir a Sesame', it: 'Aggiungi a Sesame',
      ja: 'Sesameに追加', ko: 'Sesame에 추가',
      'zh-hans': '添加到 Sesame', 'zh-hant': '新增到 Sesame', ar: 'أضف إلى Sesame'
    },
    download_ios: {
      en: 'Don\'t have Sesame? Download on the App Store',
      fr: 'Pas encore Sesame ? Télécharger sur l\'App Store',
      de: 'Sesame noch nicht? Im App Store laden',
      es: '¿Sin Sesame? Descargar en el App Store',
      it: 'Non hai Sesame? Scarica dall\'App Store',
      ja: 'Sesameをお持ちでない方はApp Storeから',
      ko: 'Sesame이 없으신가요? App Store에서 다운로드',
      'zh-hans': '没有 Sesame？在 App Store 下载',
      'zh-hant': '沒有 Sesame？在 App Store 下載',
      ar: 'ليس لديك Sesame؟ حمّله من App Store'
    },
    download_ios_soon: {
      en: 'iOS version coming soon',
      fr: 'Version iOS bientôt disponible',
      de: 'iOS-Version demnächst verfügbar',
      es: 'Versión iOS próximamente',
      it: 'Versione iOS in arrivo',
      ja: 'iOSバージョン近日公開',
      ko: 'iOS 버전 출시 예정',
      'zh-hans': 'iOS 版本即将推出',
      'zh-hant': 'iOS 版本即將推出',
      ar: 'إصدار iOS قريباً'
    },
    download_android: {
      en: 'Don\'t have Sesame? Download on the Google Play Store',
      fr: 'Pas encore Sesame ? Télécharger sur le Google Play Store',
      de: 'Sesame noch nicht? Im Google Play laden',
      es: '¿Sin Sesame? Descargar en el Google Play Store',
      it: 'Non hai Sesame? Scarica dal Google Play Store',
      ja: 'Sesameをお持ちでない方はGoogle Play Storeから',
      ko: 'Sesame이 없으신가요? Google Play Store에서 다운로드',
      'zh-hans': '没有 Sesame？在 Google Play Store 下载',
      'zh-hant': '沒有 Sesame？在 Google Play Store 下載',
      ar: 'ليس لديك Sesame؟ حمّله من Google Play Store'
    },
    download_android_soon: {
      en: 'Android version coming soon',
      fr: 'Version Android bientôt disponible',
      de: 'Android-Version demnächst verfügbar',
      es: 'Versión Android próximamente',
      it: 'Versione Android in arrivo',
      ja: 'Androidバージョン近日公開',
      ko: 'Android 버전 출시 예정',
      'zh-hans': 'Android 版本即将推出',
      'zh-hant': 'Android 版本即將推出',
      ar: 'إصدار Android قريباً'
    },
    note: {
      en: 'You don\'t need Sesame to use this code — it\'s shown above. Sesame can notify you automatically when you arrive, and keep all your access codes in one place.',
      fr: 'Vous n\'avez pas besoin de Sesame pour utiliser ce code — il est affiché ci-dessus. Sesame peut vous notifier automatiquement à l\'arrivée et centraliser tous vos codes d\'accès.',
      de: 'Du brauchst Sesame nicht, um diesen Code zu verwenden — er steht oben. Sesame kann dich automatisch bei Ankunft benachrichtigen und alle Zugangscodes an einem Ort verwalten.',
      es: 'No necesitas Sesame para usar este código — está arriba. Sesame puede notificarte automáticamente al llegar y centralizar todos tus códigos de acceso.',
      it: 'Non hai bisogno di Sesame per usare questo codice — è mostrato sopra. Sesame può notificarti automaticamente all\'arrivo e raccogliere tutti i tuoi codici in un unico posto.',
      ja: 'このコードを使用するためにSesameは必要ありません — 上に表示されています。Sesameは到着時に自動通知し、すべてのアクセスコードを一か所で管理できます。',
      ko: '이 코드를 사용하기 위해 Sesame이 필요하지 않습니다 — 위에 표시되어 있습니다. Sesame은 도착 시 자동으로 알리고 모든 출입 코드를 한 곳에서 관리할 수 있습니다.',
      'zh-hans': '您不需要 Sesame 来使用此代码 — 已显示在上方。Sesame 可以在您到达时自动通知您，并将所有门禁代码集中管理。',
      'zh-hant': '您不需要 Sesame 來使用此代碼 — 已顯示在上方。Sesame 可以在您到達時自動通知您，並將所有門禁代碼集中管理。',
      ar: 'لا تحتاج إلى Sesame لاستخدام هذا الرمز — فهو معروض أعلاه. يمكن لـ Sesame إخطارك تلقائيًا عند وصولك وتجميع جميع رموز دخولك في مكان واحد.'
    },
    learn_more: {
      en: 'Learn more about Sesame', fr: 'En savoir plus sur Sesame',
      de: 'Mehr über Sesame erfahren', es: 'Más información sobre Sesame',
      it: 'Scopri di più su Sesame', ja: 'Sesameについて詳しく',
      ko: 'Sesame 더 알아보기', 'zh-hans': '了解更多关于 Sesame',
      'zh-hant': '了解更多關於 Sesame', ar: 'اعرف المزيد عن Sesame'
    },
    error_title: {
      en: 'No entry found', fr: 'Aucune entrée trouvée', de: 'Kein Eintrag gefunden',
      es: 'No se encontró ninguna entrada', it: 'Nessuna voce trovata',
      ja: 'エントリが見つかりません', ko: '항목을 찾을 수 없습니다',
      'zh-hans': '未找到条目', 'zh-hant': '未找到條目', ar: 'لم يتم العثور على إدخال'
    },
    error_body: {
      en: 'This link doesn\'t contain a valid access code, or it may have been truncated when shared.',
      fr: 'Ce lien ne contient pas de code d\'accès valide, ou il a peut-être été tronqué lors du partage.',
      de: 'Dieser Link enthält keinen gültigen Zugangscode oder wurde beim Teilen möglicherweise abgeschnitten.',
      es: 'Este enlace no contiene un código de acceso válido, o puede haberse truncado al compartirlo.',
      it: 'Questo link non contiene un codice di accesso valido, o potrebbe essere stato troncato durante la condivisione.',
      ja: 'このリンクには有効なアクセスコードが含まれていないか、共有時に切り詰められた可能性があります。',
      ko: '이 링크에 유효한 출입 코드가 없거나 공유 시 잘렸을 수 있습니다.',
      'zh-hans': '此链接不包含有效的门禁代码，或者在共享时可能被截断。',
      'zh-hant': '此連結不包含有效的門禁代碼，或者在共享時可能被截斷。',
      ar: 'لا يحتوي هذا الرابط على رمز دخول صالح، أو ربما تم اقتطاعه عند المشاركة.'
    },
    go_to_sesame: {
      en: 'Go to Sesame', fr: 'Aller sur Sesame', de: 'Zu Sesame gehen',
      es: 'Ir a Sesame', it: 'Vai a Sesame',
      ja: 'Sesameへ', ko: 'Sesame으로 이동',
      'zh-hans': '前往 Sesame', 'zh-hant': '前往 Sesame', ar: 'اذهب إلى Sesame'
    },
    update_title: {
      en: 'Update required', fr: 'Mise à jour requise', de: 'Update erforderlich',
      es: 'Actualización requerida', it: 'Aggiornamento richiesto',
      ja: 'アップデートが必要です', ko: '업데이트 필요',
      'zh-hans': '需要更新', 'zh-hant': '需要更新', ar: 'تحديث مطلوب'
    },
    update_body: {
      en: 'This link was shared from a newer version of Sesame. Download the latest version to import it.',
      fr: 'Ce lien a été partagé depuis une version plus récente de Sesame. Téléchargez la dernière version pour l\'importer.',
      de: 'Dieser Link wurde von einer neueren Version von Sesame geteilt. Lade die neueste Version herunter, um ihn zu importieren.',
      es: 'Este enlace fue compartido desde una versión más reciente de Sesame. Descarga la última versión para importarlo.',
      it: 'Questo link è stato condiviso da una versione più recente di Sesame. Scarica l\'ultima versione per importarlo.',
      ja: 'このリンクは新しいバージョンのSesameから共有されました。インポートするには最新バージョンをダウンロードしてください。',
      ko: '이 링크는 더 최신 버전의 Sesame에서 공유되었습니다. 가져오려면 최신 버전을 다운로드하세요.',
      'zh-hans': '此链接来自更新版本的 Sesame。请下载最新版本以导入它。',
      'zh-hant': '此連結來自更新版本的 Sesame。請下載最新版本以匯入它。',
      ar: 'تمت مشاركة هذا الرابط من إصدار أحدث من Sesame. قم بتنزيل أحدث إصدار لاستيراده.'
    },
    update_sesame: {
      en: 'Update Sesame', fr: 'Mettre à jour Sesame', de: 'Sesame aktualisieren',
      es: 'Actualizar Sesame', it: 'Aggiorna Sesame',
      ja: 'Sesameを更新', ko: 'Sesame 업데이트',
      'zh-hans': '更新 Sesame', 'zh-hant': '更新 Sesame', ar: 'تحديث Sesame'
    },
    no_code: {
      en: 'No code — check location details',
      fr: 'Pas de code — voir les détails d\'accès',
      de: 'Kein Code — Standortdetails prüfen',
      es: 'Sin código — ver detalles de ubicación',
      it: 'Nessun codice — vedere i dettagli posizione',
      ja: 'コードなし — 場所の詳細を確認',
      ko: '코드 없음 — 위치 세부 정보 확인',
      'zh-hans': '无代码 — 查看位置详情',
      'zh-hant': '無代碼 — 查看位置詳情',
      ar: 'لا يوجد رمز — راجع تفاصيل الموقع'
    }
  };

  // ── Language ─────────────────────────────────────────────
  let currentLang = 'en';

  function t(key) {
    return T[key]?.[currentLang] || T[key]?.['en'] || key;
  }

  function detectLang() {
    const stored = localStorage.getItem('sesame-share-lang');
    if (stored && LANGS.includes(stored)) return stored;
    const stored_main = localStorage.getItem('sesame-lang');
    if (stored_main && LANGS.includes(stored_main)) return stored_main;
    const browser = (navigator.language || '').toLowerCase();
    if (browser.startsWith('fr')) return 'fr';
    if (browser.startsWith('de')) return 'de';
    if (browser.startsWith('es')) return 'es';
    if (browser.startsWith('it')) return 'it';
    if (browser.startsWith('ja')) return 'ja';
    if (browser.startsWith('ko')) return 'ko';
    if (browser.startsWith('zh-hant') || browser.startsWith('zh-tw') || browser.startsWith('zh-hk')) return 'zh-hant';
    if (browser.startsWith('zh')) return 'zh-hans';
    if (browser.startsWith('ar')) return 'ar';
    return 'en';
  }

  function getPlatform() {
    const ua = navigator.userAgent || '';
    if (/android/i.test(ua)) return 'android';
    if (/iphone|ipad|ipod|macintosh/i.test(ua)) return 'ios';
    return 'unknown';
  }

  function applyLang(code, rerender) {
    currentLang = code;
    document.documentElement.lang = code;
    document.documentElement.dir = RTL_LANGS.includes(code) ? 'rtl' : 'ltr';
    document.querySelectorAll('.lang-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.code === code);
    });
    document.getElementById('lang-select').value = code;
    localStorage.setItem('sesame-share-lang', code);
    if (rerender) rerender();
  }

  // ── Icons ────────────────────────────────────────────────
  const iconPin = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>`;
  const iconInfo = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>`;
  const iconMsg  = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>`;
  const iconApple = `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>`;
  const iconAndroid = `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M17.523 15.341 19 17.006a.75.75 0 1 1-1.14.976l-1.55-1.812A7.955 7.955 0 0 1 12 17a7.955 7.955 0 0 1-4.31-1.83L6.14 16.982A.75.75 0 0 1 5 16.006l1.477-1.665A7.975 7.975 0 0 1 4 9h16a7.975 7.975 0 0 1-2.477 6.341zM8.5 11a1 1 0 1 0 0 2 1 1 0 0 0 0-2zm7 0a1 1 0 1 0 0 2 1 1 0 0 0 0-2zM7.319 4.338 6.14 3.018A.75.75 0 1 1 7.28 2.04l1.308 1.44A7.957 7.957 0 0 1 12 3c1.12 0 2.185.23 3.15.645L16.72 2.04a.75.75 0 1 1 1.14.978l-1.179 1.32A7.992 7.992 0 0 1 20 8H4a7.992 7.992 0 0 1 3.319-3.662z"/></svg>`;

  // ── Helpers ──────────────────────────────────────────────
  function esc(str) {
    return String(str)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function base64URLDecode(str) {
    try {
      let b64 = str.replace(/-/g, '+').replace(/_/g, '/');
      const pad = b64.length % 4;
      if (pad) b64 += '='.repeat(4 - pad);
      return decodeURIComponent(escape(atob(b64)));
    } catch { return null; }
  }

  const _crc32Table = (() => {
    const t = new Uint32Array(256);
    for (let i = 0; i < 256; i++) {
      let c = i;
      for (let j = 0; j < 8; j++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      t[i] = c;
    }
    return t;
  })();

  function computeCRC32(str) {
    let crc = 0xFFFFFFFF;
    for (let i = 0; i < str.length; i++) {
      crc = _crc32Table[(crc ^ str.charCodeAt(i)) & 0xFF] ^ (crc >>> 8);
    }
    return ((crc ^ 0xFFFFFFFF) >>> 0).toString(16).padStart(8, '0');
  }

  function parseFragment() {
    let raw = window.location.hash.slice(1);
    if (!raw) return null;

    // Strip leading/trailing whitespace, %20, and periods added by copy-paste or auto-punctuation
    raw = raw.replace(/^(?:%20|[\s.])+/i, '').replace(/(?:%20|[\s.])+$/i, '');
    if (!raw) return null;

    // Try base64url decode first; fall back to plain
    const decoded = base64URLDecode(raw);
    let str = (decoded && decoded.includes('=')) ? decoded : raw;

    // Verify CRC32 if present, then strip it
    const crcIdx = str.lastIndexOf('&crc32=');
    if (crcIdx !== -1) {
      const candidate = str.slice(crcIdx + 7);
      const payload   = str.slice(0, crcIdx);
      if (!/^[0-9a-f]{8}$/i.test(candidate)) return null;
      if (computeCRC32(payload) !== candidate.toLowerCase()) return null;
      str = payload;
    }

    const params = {};
    str.split('&').forEach(pair => {
      const eqIndex = pair.indexOf('=');
      if (eqIndex === -1) return;
      const key = decodeURIComponent(pair.slice(0, eqIndex));
      const value = decodeURIComponent(pair.slice(eqIndex + 1));
      if (key) params[key] = value;
    });

    if (!Object.keys(params).length) return null;
    params._isBase64 = !!(decoded && decoded.includes('='));
    if (params._isBase64) params._raw = raw;
    return params;
  }

  function buildSesameURL(params) {
    if (params._isBase64) return `sesame://import#${params._raw}`;
    const items = [['v', '1'], ['label', params.label]];
    if (params.address) items.push(['address', params.address]);
    if (params.code)    items.push(['code',    params.code]);
    if (params.lat)     items.push(['lat',     params.lat]);
    if (params.lon)     items.push(['lon',     params.lon]);
    if (params.radius)  items.push(['radius',  params.radius]);
    if (params.details) items.push(['details', params.details]);
    if (params.comment) items.push(['comment', params.comment]);
    const qs = items.map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`).join('&');
    return `sesame://import#${qs}`;
  }

  // ── Render ───────────────────────────────────────────────
  let currentParams = null;
  let currentMode = 'entry'; // 'entry' | 'error' | 'update'
  let codeRevealed = false;

  function render() {
    if (currentMode === 'entry' && currentParams) {
      renderEntry(currentParams);
    } else if (currentMode === 'update') {
      renderUpdate();
    } else {
      renderError();
    }
  }

  function renderHeader() {
    return `
      <div class="header">
        <img class="app-icon" src="https://sesame-app.com/images/sesame.png" alt="Sesame" />
        <div class="header-text">
          <span class="app-name">Sesame</span>
          <span class="shared-by">${t('shared_by')}</span>
        </div>
      </div>`;
  }

  function renderEntry(params) {
    const sesameURL = buildSesameURL(params);
    const platform = getPlatform();
    const downloadBtn = platform === 'android'
      ? `<a href="#" class="btn-secondary" style="opacity:0.5;pointer-events:none;cursor:default;">${iconAndroid} ${t('download_android_soon')}</a>`
      : `<a href="${APP_STORE_URL}" class="btn-secondary">${iconApple} ${t('download_ios')}</a>`;


    let extraFields = '';
    if (params.details) {
      extraFields += `<div class="extra-field">${iconInfo}<div class="extra-field-content"><span class="extra-field-label">${t('location_details')}</span><span class="extra-field-value">${esc(params.details)}</span></div></div>`;
    }
    if (params.comment) {
      extraFields += `<div class="extra-field">${iconMsg}<div class="extra-field-content"><span class="extra-field-label">${t('comment')}</span><span class="extra-field-value">${esc(params.comment)}</span></div></div>`;
    }
    if (params.radius) {
      const m = parseFloat(params.radius);
      const display = m >= 1000 ? `${(m/1000).toFixed(1)} km` : `${Math.round(m)} m`;
      extraFields += `<div class="extra-field"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-top:2px;opacity:.45"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/></svg><div class="extra-field-content"><span class="extra-field-label">${t('detection_radius')}</span><span class="extra-field-value">${display}</span></div></div>`;
    }

    document.getElementById('card').innerHTML = `
      ${renderHeader()}
      <div class="entry">
        <div class="entry-label">${esc(params.label)}</div>
        ${params.address ? `
        <a href="${getMapsURL(params.address, params.lat, params.lon)}"
          class="entry-address"
          style="text-decoration:none;">
          ${iconPin}<span>${esc(params.address)}</span>
        </a>
      ` : ''}
        ${params.code ? `
        ${params.address ? '<div class="divider"></div>' : ''}
        <div class="code-label">${t('access_code')}</div>
        <div class="code-display">
          <div class="code-wrap">
            <span class="code-sizer">${esc(params.code)}</span>
            <span class="code-overlay is-masked" id="code-value">••••••</span>
          </div>
          <button class="reveal-btn" id="reveal-btn" onclick="toggleCode()">${t('show')}</button>
        </div>
      ` : `
        <div class="divider"></div>
        <div class="code-label">${t('access_code')}</div>
        <div class="code-display" style="justify-content:center;">
          <span style="font-size:13px;color:var(--text-tertiary);">${t('no_code')}</span>
        </div>
      `}
        ${extraFields ? `<div class="extra-fields">${extraFields}</div>` : ''}
      </div>
      <div class="actions">
        <a href="${sesameURL}" class="btn-primary">${t('add_to_sesame')}</a>
        ${downloadBtn}
      </div>
      <p class="note">
        ${t('note')}<br>
        <a href="${HOMEPAGE_URL}">${t('learn_more')}</a>
      </p>`;

    // Restore revealed state after re-render (e.g. language switch)
    if (codeRevealed && params.code) {
      const overlay = document.getElementById('code-value');
      overlay.classList.remove('is-masked');
      overlay.textContent = params.code;
      document.getElementById('reveal-btn').textContent = t('hide');
    }
  }

  function renderError() {
    document.getElementById('card').innerHTML = `
      ${renderHeader()}
      <div class="error-state">
        <div class="error-icon">🔑</div>
        <div class="error-title">${t('error_title')}</div>
        <div class="error-body">${t('error_body')}</div>
        <a href="${HOMEPAGE_URL}" class="btn-primary" style="display:inline-flex;width:auto;padding:12px 28px;">${t('go_to_sesame')}</a>
      </div>`;
  }

  function renderUpdate() {
    const platform = getPlatform();
    const updateBtn = platform === 'android'
      ? `<a href="${PLAY_STORE_URL}" class="btn-primary" style="display:inline-flex;width:auto;padding:12px 28px;">${iconAndroid} ${t('update_sesame')}</a>`
      : `<a href="${APP_STORE_URL}" class="btn-primary" style="display:inline-flex;width:auto;padding:12px 28px;">${iconApple} ${t('update_sesame')}</a>`;
    document.getElementById('card').innerHTML = `
      ${renderHeader()}
      <div class="error-state">
        <div class="error-icon">⬆️</div>
        <div class="error-title">${t('update_title')}</div>
        <div class="error-body">${t('update_body')}</div>
        ${updateBtn}
      </div>`;
  }

  function toggleCode() {
      codeRevealed = !codeRevealed;
      const overlay = document.getElementById('code-value');
      const btn = document.getElementById('reveal-btn');
      if (codeRevealed) {
          overlay.classList.remove('is-masked');
          overlay.textContent = currentParams.code;
          btn.textContent = t('hide');
      } else {
          overlay.classList.add('is-masked');
          overlay.textContent = '••••••';
          btn.textContent = t('show');
      }
  }

  // ── Init ─────────────────────────────────────────────────
  (function init() {
    // Language switcher wiring
    document.querySelectorAll('.lang-btn').forEach(btn => {
      btn.addEventListener('click', () => applyLang(btn.dataset.code, render));
    });
    document.getElementById('lang-select').addEventListener('change', e => {
      applyLang(e.target.value, render);
    });

    // Detect language first
    const lang = detectLang();

    // Parse fragment
    const params = parseFragment();

    if (!params) {
      window.location.replace(HOMEPAGE_URL);
      return;
    }

    if (!params.label) {
      currentMode = 'error';
    } else if (params.v && params.v !== '1') {
      currentMode = 'update';
    } else {
      currentMode = 'entry';
      currentParams = params;
    }

    window.addEventListener('hashchange', () => {
      codeRevealed = false;
      const params = parseFragment();
      if (!params) {
        window.location.replace(HOMEPAGE_URL);
        return;
      }
      if (!params.label) {
        currentMode = 'error';
        currentParams = null;
      } else if (params.v && params.v !== '1') {
        currentMode = 'update';
        currentParams = null;
      } else {
        currentMode = 'entry';
        currentParams = params;
      }
      render();
    });

    // Apply language and render
    applyLang(lang, render);
  })();

  function getMapsURL(address, lat, lon) {
    if (!address) return '#'; // Safety check
    
    const ua = navigator.userAgent || '';
    const isIOS = /iphone|ipad|ipod/i.test(ua);
    const isMac = /macintosh/i.test(ua) && !('ontouchend' in document);
      
    if (isIOS || isMac) {
        // Apple Maps
        if (lat && lon) {
            return `maps://maps.apple.com/?ll=${lat},${lon}&q=${encodeURIComponent(address)}`;
        }
        return `maps://maps.apple.com/?q=${encodeURIComponent(address)}`;
    } else {
        // Google Maps for Android and everything else
        if (lat && lon) {
            return `https://www.google.com/maps/search/?api=1&query=${lat},${lon}`;
        }
        return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`;
    }
  }

</script>
</body>
</html>
