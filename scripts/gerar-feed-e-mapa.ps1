param(
    [string]$BaseUrl = "https://carlavilla.com.br"
)

$ErrorActionPreference = "Stop"

function Read-JsonFile {
    param([string]$Path)
    return (Get-Content -Path $Path -Raw -Encoding utf8 | ConvertFrom-Json)
}

function Read-TextSmart {
    param([string]$Path)

    $utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
    $cp1252 = [System.Text.Encoding]::GetEncoding(1252)
    $bytes = [System.IO.File]::ReadAllBytes($Path)

    try {
        return $utf8Strict.GetString($bytes)
    }
    catch {
        return $cp1252.GetString($bytes)
    }
}

function To-Rfc822Date {
    param([datetime]$Date)
    return $Date.ToUniversalTime().ToString("r")
}

function XmlEscape {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    return [System.Security.SecurityElement]::Escape([string]$Text)
}

function Normalize-BaseUrl {
    param([string]$Url)
    return $Url.TrimEnd("/")
}

function Get-SlugFromFile {
    param([System.IO.FileInfo]$File)
    return [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
}

function HtmlDecode {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    return [System.Net.WebUtility]::HtmlDecode([string]$Text)
}

function Get-ArticleTitleFromHtml {
    param([string]$Html)

    $h1 = [regex]::Match($Html, '(?is)<h1[^>]*>(.*?)</h1>')
    if ($h1.Success) {
        return (HtmlDecode $h1.Groups[1].Value).Trim()
    }

    $t = [regex]::Match($Html, '(?is)<title>(.*?)</title>')
    if ($t.Success) {
        $title = (HtmlDecode $t.Groups[1].Value).Trim()
        $title = $title -replace '\s*\|\s*Carla Villa.*$', ''
        return $title.Trim()
    }

    return ""
}

function Get-ArticleDateFromHtml {
    param([string]$Html, [datetime]$Fallback)

    $m = [regex]::Match($Html, '"datePublished"\s*:\s*"(\d{4}-\d{2}-\d{2})"', 'IgnoreCase')
    if ($m.Success) {
        return [datetime]::ParseExact($m.Groups[1].Value, "yyyy-MM-dd", $null)
    }

    return $Fallback
}

function New-FeedXml {
    param(
        [hashtable]$CatalogIndex,
        [System.IO.FileInfo[]]$TextFiles,
        [string]$BaseUrl
    )

    $site = Normalize-BaseUrl -Url $BaseUrl
    $now = Get-Date
    $items = @()

    foreach ($file in $TextFiles) {
        $slug = Get-SlugFromFile -File $file
        $entry = $CatalogIndex[$slug]
        if (-not $entry) {
            continue
        }
        $items += $entry
    }

    $items = @($items | Sort-Object publishDate -Descending | Select-Object -First 50)

    $itemXml = foreach ($item in $items) {
        $link = "$site/textos/$($item.slug).html"
        $file = $TextFiles | Where-Object { (Get-SlugFromFile -File $_) -eq $item.slug } | Select-Object -First 1
        if (-not $file) { continue }

        $html = Read-TextSmart -Path $file.FullName
        $title = Get-ArticleTitleFromHtml -Html $html
        if (-not $title) { $title = [string]$item.slug }

        $published = Get-ArticleDateFromHtml -Html $html -Fallback $file.LastWriteTime
        $cluster = [string]$item.cluster
        @"
  <item>
    <title>$(XmlEscape $title)</title>
    <link>$link</link>
    <guid isPermaLink="true">$link</guid>
    <pubDate>$(To-Rfc822Date $published)</pubDate>
    <category>$(XmlEscape $cluster)</category>
    <description>$(XmlEscape "Psicoterapia online em portugues. Texto do site Carla Villa.")</description>
  </item>
"@.TrimEnd()
    }

    return @"
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
  <title>Carla Villa Psicologia - Textos</title>
  <link>$site/textos/</link>
  <description>Textos autorais sobre ansiedade, vida no exterior, autocobranca e relacionamentos.</description>
  <language>pt-BR</language>
  <lastBuildDate>$(To-Rfc822Date $now)</lastBuildDate>
$($itemXml -join "`n")
</channel>
</rss>
"@.Trim() + "`n"
}

function New-SitemapHtml {
    param(
        [hashtable]$CatalogIndex,
        [System.IO.FileInfo[]]$RootHtmlFiles,
        [System.IO.FileInfo[]]$TextFiles,
        [string]$BaseUrl,
        [string]$CssHref
    )

    $site = Normalize-BaseUrl -Url $BaseUrl

    $rootLinks = foreach ($file in $RootHtmlFiles | Sort-Object Name) {
        if ($file.Name -ieq "mapa-do-site.html") { continue }
        if ($file.Name -ieq "404.html") { continue }
        $href = "$site/$($file.Name)"
        "<li><a href=""$href"">$($file.Name)</a></li>"
    }

    $clusters = @("expatriacao", "ansiedade", "autocobranca", "relacionamentos")
    $clusterLabels = @{
        expatriacao = "Brasileiros no exterior"
        ansiedade = "Ansiedade"
        autocobranca = "Autocobran&ccedil;a"
        relacionamentos = "Relacionamentos"
    }

    $byCluster = @{}
    foreach ($key in $clusters) { $byCluster[$key] = @() }

    foreach ($file in $TextFiles) {
        $slug = Get-SlugFromFile -File $file
        $entry = $CatalogIndex[$slug]
        if (-not $entry) { continue }
        $key = [string]$entry.cluster
        if (-not $byCluster.ContainsKey($key)) { continue }
        $byCluster[$key] += $entry
    }

    $clusterBlocks = foreach ($key in $clusters) {
        $items = @($byCluster[$key] | Sort-Object publishDate -Descending)
        if ($items.Count -eq 0) { continue }
        $lis = foreach ($item in $items) {
            $href = "$site/textos/$($item.slug).html"
            $file = $TextFiles | Where-Object { (Get-SlugFromFile -File $_) -eq $item.slug } | Select-Object -First 1
            $label = $item.slug
            if ($file) {
                $html = Read-TextSmart -Path $file.FullName
                $t = Get-ArticleTitleFromHtml -Html $html
                if ($t) { $label = $t }
            }
            "<li><a href=""$href"">$(XmlEscape $label)</a></li>"
        }

        @"
<section class="landing-block">
  <p class="landing-kicker">$(XmlEscape $clusterLabels[$key])</p>
  <h2>Textos</h2>
  <ul class="landing-checklist">
    $($lis -join "`n    ")
  </ul>
</section>
"@.TrimEnd()
    }

    return @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mapa do site | Carla Villa</title>
  <meta name="description" content="Mapa do site com links para p&aacute;ginas e textos publicados de Carla Villa Psicologia.">
  <meta name="robots" content="index, follow, max-image-preview:large">
  <link rel="canonical" href="$site/mapa-do-site.html">
  <link rel="stylesheet" href="$CssHref">
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="alternate" type="application/rss+xml" title="Carla Villa Psicologia - Textos" href="$site/feed.xml">
  <link rel="icon" href="favicon.ico?v=20260307" sizes="any">
  <link rel="shortcut icon" href="favicon.ico?v=20260307" type="image/x-icon">
  <link rel="icon" type="image/png" sizes="32x32" href="imagens/logo.png?v=20260307">
  <link rel="apple-touch-icon" href="imagens/logo.png?v=20260307">
</head>
<body>
  <header class="artigo-topo" id="topo-artigo">
    <div class="artigo-topo-inner">
      <a href="index.html#inicio" class="artigo-marca">
        <img src="imagens/logo.png" class="logo" alt="Logo Carla Villa">
        <span>Carla Villa Psicologia</span>
      </a>
      <a href="index.html#inicio" class="artigo-voltar">Voltar ao in&iacute;cio</a>
    </div>
    <div class="linha-metalica"></div>
  </header>

  <main class="landing-servico">
    <section class="landing-hero">
      <div class="landing-panel landing-copy">
        <p class="landing-kicker">Mapa do site</p>
        <h1>Links para p&aacute;ginas e textos</h1>
        <p class="landing-lead">
          Se voc&ecirc; est&aacute; procurando um tema espec&iacute;fico, comece pelo arquivo de textos ou pelos blocos abaixo.
        </p>
        <div class="landing-buttons">
          <a class="btn" href="$site/textos/">Arquivo de textos</a>
          <a class="btn" href="$site/feed.xml">RSS (feed)</a>
        </div>
      </div>
      <aside class="landing-panel landing-side">
        <p class="landing-kicker">P&aacute;ginas</p>
        <h2>Principais p&aacute;ginas do site</h2>
        <ul class="landing-checklist">
          <li><a href="$site/">Home</a></li>
          <li><a href="$site/textos/">Arquivo de textos</a></li>
          <li><a href="$site/psicologa-online-brasileiros-no-exterior.html">Brasileiros no exterior</a></li>
          <li><a href="$site/terapia-online-para-ansiedade.html">Terapia para ansiedade</a></li>
          <li><a href="$site/terapia-online-relacionamentos.html">Terapia para relacionamentos</a></li>
          <li><a href="$site/terapia-online-autocobranca.html">Terapia para autocobran&ccedil;a</a></li>
        </ul>
      </aside>
    </section>

    <section class="landing-block">
      <p class="landing-kicker">Outras p&aacute;ginas</p>
      <h2>P&aacute;ginas em HTML na raiz</h2>
      <ul class="landing-checklist">
        $($rootLinks -join "`n        ")
      </ul>
    </section>

    $($clusterBlocks -join "`n`n    ")
  </main>

  <hr class="divider">
  <div data-site-footer data-base="."></div>
  <script src="footer.js"></script>
</body>
</html>
"@.Trim() + "`n"
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$catalogPath = Join-Path $repoRoot "agendamentos/catalogo-artigos.json"
$catalog = Read-JsonFile -Path $catalogPath

$catalogIndex = @{}
foreach ($entry in $catalog) {
    $catalogIndex[[string]$entry.slug] = $entry
}

$queuePath = Join-Path $repoRoot "agendamentos/fila-publicacao.json"
$publishedSlugs = @{}
if (Test-Path $queuePath) {
    $queue = Read-JsonFile -Path $queuePath
    foreach ($item in $queue | Where-Object { $_.status -eq "published" }) {
        $publishedSlugs[[string]$item.slug] = $true
    }
}

$rootHtmlFiles = Get-ChildItem -Path $repoRoot -File -Filter *.html
$textFiles = Get-ChildItem -Path (Join-Path $repoRoot "textos") -File -Filter *.html | Where-Object {
    $_.Name -ine "index.html" -and $publishedSlugs.ContainsKey((Get-SlugFromFile -File $_))
}

$feedPath = Join-Path $repoRoot "feed.xml"
$mapPath = Join-Path $repoRoot "mapa-do-site.html"

$feedXml = New-FeedXml -CatalogIndex $catalogIndex -TextFiles $textFiles -BaseUrl $BaseUrl
[System.IO.File]::WriteAllText($feedPath, $feedXml, (New-Object System.Text.UTF8Encoding($false)))

# Usa a versão do CSS já presente na home (se houver), para manter consistência e facilitar cache busting.
$cssHref = "style.css"
try {
    $indexPath = Join-Path $repoRoot "index.html"
    $indexHtml = Get-Content -Path $indexPath -Raw
    $m = [regex]::Match($indexHtml, 'href=\"(style\\.css\\?v=[^\"]+)\"', 'IgnoreCase')
    if ($m.Success) {
        $cssHref = $m.Groups[1].Value
    }
} catch {
    # mantém default
}

$mapHtml = New-SitemapHtml -CatalogIndex $catalogIndex -RootHtmlFiles $rootHtmlFiles -TextFiles $textFiles -BaseUrl $BaseUrl -CssHref $cssHref
[System.IO.File]::WriteAllText($mapPath, $mapHtml, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Gerado: feed.xml e mapa-do-site.html"
