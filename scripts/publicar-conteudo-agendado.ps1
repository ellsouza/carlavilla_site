param(
    [string]$Today,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Get-SaoPauloDate {
    $tz = $null
    foreach ($candidate in @("America/Sao_Paulo", "E. South America Standard Time")) {
        try {
            $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($candidate)
            break
        }
        catch {
        }
    }

    if (-not $tz) {
        throw "Nao foi possivel localizar o fuso horario de Sao Paulo."
    }

    $nowUtc = [DateTime]::UtcNow
    return [System.TimeZoneInfo]::ConvertTimeFromUtc($nowUtc, $tz).ToString("yyyy-MM-dd")
}

function Read-TextFile {
    param([string]$Path)

    return [System.IO.File]::ReadAllText($Path)
}

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Get-MarkerBlock {
    param(
        [string]$Content,
        [string]$StartMarker,
        [string]$EndMarker
    )

    $startParts = $Content -split [regex]::Escape($StartMarker), 2
    if ($startParts.Count -ne 2) {
        throw "Marcador inicial nao encontrado: $StartMarker"
    }

    $endParts = $startParts[1] -split [regex]::Escape($EndMarker), 2
    if ($endParts.Count -ne 2) {
        throw "Marcador final nao encontrado: $EndMarker"
    }

    return $endParts[0].Trim()
}

function Set-MarkerBlock {
    param(
        [string]$Content,
        [string]$StartMarker,
        [string]$EndMarker,
        [string]$Block
    )

    $startParts = $Content -split [regex]::Escape($StartMarker), 2
    if ($startParts.Count -ne 2) {
        throw "Marcador inicial nao encontrado: $StartMarker"
    }

    $endParts = $startParts[1] -split [regex]::Escape($EndMarker), 2
    if ($endParts.Count -ne 2) {
        throw "Marcador final nao encontrado: $EndMarker"
    }

    $newBlock = $Block.Trim()
    if ($newBlock.Length -gt 0) {
        $newBlock = "`r`n$newBlock`r`n"
    }
    else {
        $newBlock = "`r`n"
    }

    return $startParts[0] + $StartMarker + $newBlock + $EndMarker + $endParts[1]
}

function New-ArticleCard {
    param([pscustomobject]$Item)

    return @"
<article class="texto-card">

<h3>$($Item.cardTitle)</h3>

<p>
$($Item.cardDescription)
</p>

<a href="textos/$($Item.slug).html" class="ler-artigo">
Ler artigo &rarr;
</a>

</article>
"@.Trim()
}

function New-SitemapUrl {
    param([pscustomobject]$Item)

    return @"
  <url>
    <loc>https://carlavilla.com.br/textos/$($Item.slug).html</loc>
    <lastmod>$($Item.publishDate)</lastmod>
    <changefreq>$($Item.changefreq)</changefreq>
    <priority>$($Item.priority)</priority>
  </url>
"@.TrimEnd()
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$queuePath = Join-Path $repoRoot "agendamentos/fila-publicacao.json"
$indexPath = Join-Path $repoRoot "index.html"
$sitemapPath = Join-Path $repoRoot "sitemap.xml"

if (-not $Today) {
    $Today = Get-SaoPauloDate
}

$queue = Get-Content $queuePath -Raw | ConvertFrom-Json
$dueItems = @($queue | Where-Object { $_.status -eq "scheduled" -and $_.publishDate -le $Today } | Sort-Object publishDate, slug)

if ($dueItems.Count -eq 0) {
    Write-Host "Nenhum artigo agendado para publicar em $Today."
    exit 0
}

$indexContent = Read-TextFile -Path $indexPath
$sitemapContent = Read-TextFile -Path $sitemapPath
$currentCards = Get-MarkerBlock -Content $indexContent -StartMarker "<!-- AUTO-TEXTOS-START -->" -EndMarker "<!-- AUTO-TEXTOS-END -->"
$currentUrls = Get-MarkerBlock -Content $sitemapContent -StartMarker "<!-- AUTO-URLS-START -->" -EndMarker "<!-- AUTO-URLS-END -->"

$newCards = @()
$newUrls = @()
$publishedAny = $false

foreach ($item in $dueItems) {
    $draftPath = Join-Path $repoRoot $item.draftPath
    $livePath = Join-Path $repoRoot $item.livePath
    $liveHref = "textos/$($item.slug).html"
    $liveUrl = "https://carlavilla.com.br/textos/$($item.slug).html"

    if (-not (Test-Path $draftPath)) {
        throw "Rascunho agendado nao encontrado: $($item.draftPath)"
    }

    if (-not (Test-Path $livePath)) {
        if (-not $DryRun) {
            Copy-Item -Path $draftPath -Destination $livePath -Force
            Write-Host "Arquivo publicado: $liveHref"
        }
        else {
            Write-Host "Arquivo seria publicado: $liveHref"
        }
        $publishedAny = $true
    }

    if (($indexContent -notlike "*$liveHref*") -and ($currentCards -notlike "*$liveHref*")) {
        $newCards += New-ArticleCard -Item $item
        $publishedAny = $true
    }

    if (($sitemapContent -notlike "*$liveUrl*") -and ($currentUrls -notlike "*$liveUrl*")) {
        $newUrls += New-SitemapUrl -Item $item
        $publishedAny = $true
    }

    $item.status = "published"
    if ($item.PSObject.Properties.Name -contains "publishedAt") {
        $item.publishedAt = $Today
    }
    else {
        $item | Add-Member -NotePropertyName "publishedAt" -NotePropertyValue $Today
    }
}

if (-not $publishedAny) {
    Write-Host "Os artigos agendados ja estavam publicados."
}

$updatedCards = @($newCards + @($currentCards) | Where-Object { $_ -and $_.Trim() }) -join "`r`n`r`n"
$updatedUrls = @($newUrls + @($currentUrls) | Where-Object { $_ -and $_.Trim() }) -join "`r`n"

$indexContent = Set-MarkerBlock -Content $indexContent -StartMarker "<!-- AUTO-TEXTOS-START -->" -EndMarker "<!-- AUTO-TEXTOS-END -->" -Block $updatedCards
$sitemapContent = Set-MarkerBlock -Content $sitemapContent -StartMarker "<!-- AUTO-URLS-START -->" -EndMarker "<!-- AUTO-URLS-END -->" -Block $updatedUrls

if (-not $DryRun) {
    Write-TextFile -Path $indexPath -Content $indexContent
    Write-TextFile -Path $sitemapPath -Content $sitemapContent
    $queueJson = $queue | ConvertTo-Json -Depth 5
    Write-TextFile -Path $queuePath -Content $queueJson
}

Write-Host "Publicacao agendada processada para $Today."
