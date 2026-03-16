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

    return [System.TimeZoneInfo]::ConvertTimeFromUtc([datetime]::UtcNow, $tz).ToString("yyyy-MM-dd")
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

function Html {
    param([string]$Text)
    if ($null -eq $Text) {
        return ""
    }
    return [System.Net.WebUtility]::HtmlEncode($Text)
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

    $trimmed = $Block.Trim()
    $newBlock = if ($trimmed) { "`r`n$trimmed`r`n" } else { "`r`n" }
    return $startParts[0] + $StartMarker + $newBlock + $EndMarker + $endParts[1]
}

function Update-SitemapLastmod {
    param(
        [string]$Content,
        [string]$Loc,
        [string]$Date
    )

    $pattern = "(?s)(<loc>$([regex]::Escape($Loc))</loc>\s*<lastmod>)(.*?)(</lastmod>)"
    return [regex]::Replace($Content, $pattern, "`$1$Date`$3", 1)
}

function Get-VariantIndex {
    param(
        [string]$Slug,
        [int]$Length
    )

    $sum = 0
    foreach ($char in $Slug.ToCharArray()) {
        $sum += [int][char]$char
    }

    return $sum % $Length
}

function Get-CardTitle {
    param([string]$Title)
    if ($Title -match ":") {
        return ($Title -split ":", 2)[0].Trim()
    }
    return $Title.Trim()
}

function Get-MetaDescription {
    param([pscustomobject]$Article)

    switch ($Article.cluster) {
        "expatriacao" { return "Entenda $($Article.keyword), por que isso pesa emocionalmente e como a psicoterapia online ajuda brasileiros no exterior." }
        "ansiedade" { return "Entenda $($Article.keyword), por que esse padrão mental se repete e como a psicoterapia online pode ajudar." }
        "autocobranca" { return "Entenda $($Article.keyword), por que esse padrão desgasta tanto e como a psicoterapia online pode ajudar." }
        default { return "Entenda $($Article.keyword), por que isso afeta vínculos e como a psicoterapia online ajuda a construir mudanças." }
    }
}

function Get-CardDescription {
    param([pscustomobject]$Article)

    switch ($Article.cluster) {
        "expatriacao" { return "Entenda como $($Article.keyword) aparece na experiência de morar fora e como a psicoterapia ajuda a elaborar esse processo." }
        "ansiedade" { return "Veja como $($Article.keyword) costuma aparecer na rotina e de que forma a psicoterapia ajuda a interromper esse ciclo." }
        "autocobranca" { return "Entenda por que $($Article.keyword) desgasta tanto por dentro e como a psicoterapia ajuda a flexibilizar esse padrão." }
        default { return "Saiba como $($Article.keyword) afeta vínculos, limites e desgaste emocional, e como a psicoterapia pode ajudar." }
    }
}

function Get-ServiceLink {
    param([string]$Cluster)

    switch ($Cluster) {
        "expatriacao" { return [pscustomobject]@{ href = "../psicologa-online-brasileiros-no-exterior.html"; label = "Página para brasileiros no exterior" } }
        "ansiedade" { return [pscustomobject]@{ href = "../terapia-online-para-ansiedade.html"; label = "Terapia online para ansiedade" } }
        default { return [pscustomobject]@{ href = "../terapia-cognitivo-comportamental-online.html"; label = "TCC online" } }
    }
}

function Get-RelatedLinks {
    param([string]$Cluster)

    switch ($Cluster) {
        "expatriacao" {
            return @(
                [pscustomobject]@{ href = "../psicologa-online-brasileiros-no-exterior.html"; label = "Psicóloga online para brasileiros no exterior" },
                [pscustomobject]@{ href = "../terapia-online-luto-migratorio.html"; label = "Terapia online para luto migratório" },
                [pscustomobject]@{ href = "luto-migratorio.html"; label = "Luto migratório: o impacto emocional de morar fora" }
            )
        }
        "ansiedade" {
            return @(
                [pscustomobject]@{ href = "../terapia-online-para-ansiedade.html"; label = "Terapia online para ansiedade" },
                [pscustomobject]@{ href = "../terapia-cognitivo-comportamental-online.html"; label = "Terapia Cognitivo-Comportamental online" },
                [pscustomobject]@{ href = "ansiedade-ruminacao.html"; label = "Ruminação mental: o que é e como parar" }
            )
        }
        "autocobranca" {
            return @(
                [pscustomobject]@{ href = "../terapia-cognitivo-comportamental-online.html"; label = "Terapia Cognitivo-Comportamental online" },
                [pscustomobject]@{ href = "autocobranca-perfeccionismo.html"; label = "Autocobrança e perfeccionismo" },
                [pscustomobject]@{ href = "autoestima-inseguranca.html"; label = "Autoestima e insegurança" }
            )
        }
        default {
            return @(
                [pscustomobject]@{ href = "relacionamentos-limites.html"; label = "Relacionamentos e limites" },
                [pscustomobject]@{ href = "../terapia-cognitivo-comportamental-online.html"; label = "Terapia Cognitivo-Comportamental online" },
                [pscustomobject]@{ href = "autocobranca-perfeccionismo.html"; label = "Autocobrança e perfeccionismo" }
            )
        }
    }
}

function Get-Signs {
    param([string]$Cluster)

    switch ($Cluster) {
        "expatriacao" { return @("dificuldade de relaxar mesmo sem urgência prática", "saudade, culpa ou sensação de não pertencimento", "medo de não dar conta da vida fora do Brasil", "mente acelerada com decisões, trabalho ou família", "cansaço emocional depois de tentar sustentar tudo sozinho(a)") }
        "ansiedade" { return @("pensamentos repetitivos e dificuldade de desligar a mente", "tensão no corpo, irritabilidade ou cansaço constante", "sono ruim ou sensação de alerta no fim do dia", "antecipação exagerada de cenários e problemas", "dificuldade de descansar sem continuar preocupado(a)") }
        "autocobranca" { return @("sensação frequente de que nunca é suficiente", "culpa ao descansar ou diminuir o ritmo", "dificuldade de reconhecer conquistas com tranquilidade", "comparação constante com outras pessoas", "exaustão por sentir que precisa dar conta de tudo") }
        default { return @("dificuldade de se posicionar com clareza", "medo de conflito, rejeição ou afastamento", "tendência a engolir emoções para manter o vínculo", "cansaço por carregar responsabilidades emocionais demais", "culpa ao colocar limites ou pedir ajuda") }
    }
}

function Get-FAQs {
    param([string]$Cluster)

    switch ($Cluster) {
        "expatriacao" { return @([pscustomobject]@{ q = "Isso é normal morando fora?"; a = "Mudanças de país costumam ativar saudade, adaptação, perda simbólica e conflitos de pertencimento. Quando isso pesa por muito tempo, merece cuidado." }, [pscustomobject]@{ q = "Quando procurar terapia morando no exterior?"; a = "Quando o sofrimento começa a afetar sono, trabalho, vínculos, humor ou capacidade de aproveitar a própria vida, já existe motivo suficiente para buscar ajuda." }, [pscustomobject]@{ q = "A terapia online em português ajuda?"; a = "Sim. Para muitos brasileiros no exterior, falar em português sobre o que vivem já reduz isolamento e facilita elaboração emocional." }) }
        "ansiedade" { return @([pscustomobject]@{ q = "Isso pode ser ansiedade?"; a = "Quando alerta constante, preocupação excessiva, pensamentos repetitivos e dificuldade de relaxar começam a dominar a rotina, a ansiedade merece atenção clínica." }, [pscustomobject]@{ q = "Quando procurar terapia para ansiedade?"; a = "Quando o padrão começa a afetar descanso, trabalho, relações ou decisões, a psicoterapia pode ser um recurso importante." }, [pscustomobject]@{ q = "A terapia online ajuda com pensamentos repetitivos?"; a = "Sim. O trabalho clínico ajuda a entender gatilhos, reduzir ruminação e construir respostas menos desgastantes." }) }
        "autocobranca" { return @([pscustomobject]@{ q = "Autocobrança pode parecer força?"; a = "Pode. Muitas vezes ela se apresenta como disciplina ou responsabilidade, mas por dentro produz ansiedade, culpa e exaustão." }, [pscustomobject]@{ q = "Quando esse padrão vira sofrimento?"; a = "Quando descansar parece errado, nada parece suficiente e a vida passa a ser guiada por pressão interna constante." }, [pscustomobject]@{ q = "A terapia ajuda a flexibilizar esse jeito?"; a = "Sim. A psicoterapia ajuda a compreender de onde vem a cobrança e a construir formas mais humanas de se relacionar consigo mesmo(a)." }) }
        default { return @([pscustomobject]@{ q = "Isso significa que há algo errado comigo?"; a = "Não. Em muitos casos, esse padrão foi aprendido ao longo da vida como forma de proteger vínculos ou evitar dor emocional." }, [pscustomobject]@{ q = "Quando buscar terapia por causa dos relacionamentos?"; a = "Quando o sofrimento nas relações começa a se repetir, gerar culpa, exaustão ou dificuldade de se posicionar, vale buscar cuidado." }, [pscustomobject]@{ q = "A terapia ajuda a construir limites?"; a = "Sim. O trabalho terapêutico ajuda a reconhecer necessidades, flexibilizar medos e sustentar posicionamentos com mais clareza." }) }
    }
}

function Get-ClusterCopy {
    param([pscustomobject]$Article)

    $variant = Get-VariantIndex -Slug $Article.slug -Length 3
    $keyword = Html $Article.keyword

    switch ($Article.cluster) {
        "expatriacao" {
            $intros = @(
                @("Morar fora pode fazer sentido e, ainda assim, trazer a sensa&ccedil;&atilde;o de que <strong>$keyword</strong> come&ccedil;ou a pesar mais do que parecia no in&iacute;cio.", "Isso n&atilde;o significa que a escolha de viver no exterior foi errada. Em muitos casos, mostra apenas o custo emocional de sustentar adapta&ccedil;&atilde;o, dist&acirc;ncia e reconstru&ccedil;&atilde;o de rotina ao mesmo tempo.", "Em termos cl&iacute;nicos, esse sofrimento costuma aparecer quando mudan&ccedil;a de pa&iacute;s, perdas simb&oacute;licas e necessidade de funcionar o tempo todo se acumulam sem espa&ccedil;o suficiente para elabora&ccedil;&atilde;o."),
                @("H&aacute; experi&ecirc;ncias no exterior que n&atilde;o aparecem primeiro como crise evidente, mas como uma sensa&ccedil;&atilde;o interna de que <strong>$keyword</strong> est&aacute; ocupando espa&ccedil;o demais.", "Mesmo quando a vida fora traz oportunidades, o psiquismo precisa lidar com saudade, idioma, pertencimento e press&atilde;o por fazer a mudan&ccedil;a dar certo.", "Quando isso n&atilde;o encontra tempo, v&iacute;nculo e linguagem emocional, o sofrimento tende a ficar silencioso e persistente."),
                @("Para muitos brasileiros no exterior, <strong>$keyword</strong> n&atilde;o come&ccedil;a como algo dram&aacute;tico. Ele aparece aos poucos, no corpo, no humor e na sensa&ccedil;&atilde;o de ter que sustentar tudo sozinho(a).", "A dificuldade costuma ser maior quando quase toda a energia vai para trabalho, burocracia, adapta&ccedil;&atilde;o cultural e manuten&ccedil;&atilde;o dos v&iacute;nculos &agrave; dist&acirc;ncia.", "Esse contexto favorece um tipo de sobrecarga em que a pessoa continua funcionando, mas vai se afastando da pr&oacute;pria estabilidade emocional.")
            )

            return @{
                intro = $intros[$variant]
                section1 = @("Quando esse tema aparece, muitas pessoas percebem que a rotina continua de p&eacute;, mas o mundo interno fica mais inst&aacute;vel. O custo costuma aparecer em forma de alerta, saudade, irrita&ccedil;&atilde;o, solid&atilde;o ou dificuldade de pertencer.", "Nem sempre existe vontade clara de voltar. &Agrave;s vezes, o que existe &eacute; cansa&ccedil;o por sustentar uma vida inteira sem a mesma rede de apoio emocional de antes.")
                section2 = @("Viver fora do Brasil mexe com idioma, identidade, v&iacute;nculos, papel familiar e senso de compet&ecirc;ncia. Por isso, sofrimentos ligados &agrave; expatria&ccedil;&atilde;o raramente s&atilde;o apenas &ldquo;falta de costume&rdquo;.", "Quanto menos espa&ccedil;o existe para nomear perdas e ambival&ecirc;ncias, maior a chance de o sofrimento se manter em sil&ecirc;ncio e se infiltrar na rotina.")
                section3 = @("Um dos fatores que mais mant&eacute;m esse ciclo &eacute; a ideia de que, por ter escolhido morar fora, a pessoa n&atilde;o deveria sentir tanta dificuldade.", "Essa l&oacute;gica aumenta culpa, autocobran&ccedil;a e isolamento, porque o sofrimento passa a ser tratado como fracasso pessoal e n&atilde;o como parte de uma transi&ccedil;&atilde;o complexa.")
                section4 = @("Na psicoterapia, o foco &eacute; compreender o peso emocional da mudan&ccedil;a sem invalidar a escolha de morar fora.", "O trabalho cl&iacute;nico ajuda a elaborar perdas, reconstruir pertencimento e desenvolver mais estabilidade interna para atravessar essa fase com menos sobrecarga.")
            }
        }
        "ansiedade" {
            $intros = @(
                @("Algumas pessoas convivem com a sensa&ccedil;&atilde;o de que <strong>$keyword</strong> come&ccedil;ou a ocupar espa&ccedil;o demais na mente e no corpo.", "Por fora, a rotina segue. Por dentro, a mente continua ligada, como se fosse dif&iacute;cil realmente baixar a guarda.", "Em termos cl&iacute;nicos, esse padr&atilde;o costuma aparecer quando preocupa&ccedil;&atilde;o, antecipa&ccedil;&atilde;o e tentativas de controle passam a manter o sofrimento em movimento."),
                @("Quando <strong>$keyword</strong> se repete com frequ&ecirc;ncia, o dia pode parecer normal para quem olha de fora, mas extremamente cansativo por dentro.", "A dificuldade n&atilde;o &eacute; apenas pensar muito. &Eacute; viver com a sensa&ccedil;&atilde;o de que sempre existe algo para prever, corrigir ou impedir.", "Esse funcionamento mant&eacute;m o corpo em alerta e reduz a possibilidade de descanso real, mesmo quando n&atilde;o h&aacute; uma amea&ccedil;a concreta naquele momento."),
                @("H&aacute; momentos em que <strong>$keyword</strong> deixa de ser um inc&ocirc;modo pontual e vira um modo de funcionar.", "A pessoa tenta tocar a rotina, mas percebe que o custo aparece em forma de tens&atilde;o, irritabilidade, ins&ocirc;nia ou dificuldade de relaxar.", "Quando esse estado se repete por tempo suficiente, ele passa a organizar escolhas, v&iacute;nculos e expectativas de forma silenciosa.")
            )

            return @{
                intro = $intros[$variant]
                section1 = @("Muitas vezes, esse padr&atilde;o aparece junto com sensa&ccedil;&atilde;o de urg&ecirc;ncia interna, necessidade de prever tudo e dificuldade de confiar que o corpo pode descansar.", "Mesmo tarefas simples podem ganhar um peso maior quando a mente est&aacute; funcionando em estado de antecipa&ccedil;&atilde;o constante.")
                section2 = @("Ansiedade n&atilde;o se mant&eacute;m apenas por causa do problema externo. Ela tamb&eacute;m se alimenta da forma como a pessoa tenta buscar seguran&ccedil;a o tempo todo.", "Quanto mais a mente tenta controlar o imprevis&iacute;vel, mais o sistema emocional recebe a mensagem de que precisa continuar em alerta.")
                section3 = @("Esse ciclo costuma ser refor&ccedil;ado por rumina&ccedil;&atilde;o, autocr&iacute;tica, checagens mentais e dificuldade de tolerar incerteza.", "O resultado &eacute; um desgaste que n&atilde;o depende s&oacute; da intensidade do problema, mas do modo como a pessoa foi aprendendo a responder a ele.")
                section4 = @("Na psicoterapia, o objetivo &eacute; entender o que mant&eacute;m a ansiedade ativa e criar respostas mais flex&iacute;veis diante da inseguran&ccedil;a.", "O trabalho cl&iacute;nico ajuda a interromper padr&otilde;es repetitivos, reduzir estado de alerta e construir mais regula&ccedil;&atilde;o emocional na vida real.")
            }
        }
        "autocobranca" {
            $intros = @(
                @("Em algumas fases, <strong>$keyword</strong> parece quase um modo de existir: sempre h&aacute; algo a melhorar, revisar ou provar.", "Mesmo quando as coisas v&atilde;o bem, a mente continua exigindo mais, como se descansar ou reconhecer conquistas fosse arriscado.", "Esse padr&atilde;o costuma aparecer quando valor pessoal, desempenho e sensa&ccedil;&atilde;o de seguran&ccedil;a emocional ficam excessivamente misturados."),
                @("Para muitas pessoas, <strong>$keyword</strong> n&atilde;o se apresenta como arrog&acirc;ncia, mas como uma press&atilde;o interna dif&iacute;cil de desligar.", "A vida pode at&eacute; funcionar por fora, mas por dentro existe uma cobran&ccedil;a constante que transforma descanso em culpa e erro em amea&ccedil;a.", "Clinicamente, isso costuma apontar para um modo de funcionamento em que a exig&ecirc;ncia virou ferramenta central para evitar dor emocional."),
                @("H&aacute; momentos em que <strong>$keyword</strong> deixa de parecer responsabilidade e come&ccedil;a a soar como exaust&atilde;o.", "Tudo passa a ser medido em termos de desempenho, produtividade, controle ou aprova&ccedil;&atilde;o, sem espa&ccedil;o suficiente para humanidade.", "Quando isso acontece por muito tempo, a pessoa tende a viver em tens&atilde;o constante e com pouco acesso a tranquilidade real.")
            )

            return @{
                intro = $intros[$variant]
                section1 = @("Esse tipo de cobran&ccedil;a costuma aparecer em pessoas respons&aacute;veis, comprometidas e acostumadas a funcionar mesmo sob press&atilde;o.", "O problema come&ccedil;a quando o padr&atilde;o deixa de ajudar e passa a produzir culpa, compara&ccedil;&atilde;o e sensa&ccedil;&atilde;o frequente de insufici&ecirc;ncia.")
                section2 = @("Muitas vezes, a autocobran&ccedil;a se mant&eacute;m porque oferece uma sensa&ccedil;&atilde;o tempor&aacute;ria de controle, valor ou preven&ccedil;&atilde;o de falhas.", "S&oacute; que, ao longo do tempo, ela tamb&eacute;m reduz espontaneidade, prazer e capacidade de reconhecer os pr&oacute;prios limites.")
                section3 = @("Esse ciclo tende a se fortalecer com compara&ccedil;&atilde;o constante, dificuldade de descansar e medo de desapontar outras pessoas.", "Quanto mais a vida &eacute; guiada pela l&oacute;gica do &ldquo;ainda n&atilde;o basta&rdquo;, maior o risco de ansiedade, irritabilidade e exaust&atilde;o emocional.")
                section4 = @("Na psicoterapia, o foco &eacute; entender de onde vem essa exig&ecirc;ncia, o que ela tenta evitar e como flexibilizar esse padr&atilde;o com consist&ecirc;ncia.", "O trabalho cl&iacute;nico ajuda a construir uma forma menos violenta de se relacionar consigo mesmo(a), sem perder responsabilidade nem dire&ccedil;&atilde;o.")
            }
        }
        default {
            $intros = @(
                @("Em muitos v&iacute;nculos, <strong>$keyword</strong> aparece de um jeito silencioso: a pessoa vai se ajustando, evitando conflito e deixando a si mesma para depois.", "Por fora, a rela&ccedil;&atilde;o pode at&eacute; parecer est&aacute;vel. Por dentro, cresce um ac&uacute;mulo de medo, culpa, cansa&ccedil;o ou ressentimento.", "Esse tipo de padr&atilde;o costuma se formar quando v&iacute;nculo e seguran&ccedil;a emocional ficam associados a agradar, ceder ou se proteger demais."),
                @("Algumas pessoas s&oacute; percebem o peso de <strong>$keyword</strong> quando j&aacute; est&atilde;o cansadas demais para continuar sustentando o mesmo lugar na rela&ccedil;&atilde;o.", "A dificuldade n&atilde;o &eacute; apenas dizer n&atilde;o, confiar ou pedir ajuda. &Eacute; o medo do que pode acontecer se isso for feito com clareza.", "Quando esse medo organiza os v&iacute;nculos por tempo suficiente, o custo aparece em forma de esgotamento e perda de espontaneidade."),
                @("H&aacute; sofrimentos relacionais que se repetem tanto que parecem parte da personalidade. <strong>$keyword</strong> costuma entrar nessa categoria.", "A pessoa tenta manter proximidade, evitar dor ou preservar v&iacute;nculos importantes, mas paga com sil&ecirc;ncio, sobrecarga ou inseguran&ccedil;a.", "Em termos cl&iacute;nicos, estamos falando de padr&otilde;es afetivos que merecem ser compreendidos, e n&atilde;o apenas controlados na for&ccedil;a.")
            )

            return @{
                intro = $intros[$variant]
                section1 = @("Esse tema costuma aparecer em rela&ccedil;&otilde;es amorosas, familiares e at&eacute; profissionais, principalmente quando a pessoa sente que precisa administrar o clima emocional o tempo todo.", "Nesses casos, o v&iacute;nculo pode continuar existindo, mas &agrave; custa de muito esfor&ccedil;o interno e pouco espa&ccedil;o para autenticidade.")
                section2 = @("Padr&otilde;es relacionais persistem porque, em algum momento da hist&oacute;ria, fizeram sentido como forma de prote&ccedil;&atilde;o ou pertencimento.", "O problema &eacute; que aquilo que um dia ajudou a manter v&iacute;nculo pode, no presente, produzir medo, desgaste e sensa&ccedil;&atilde;o de aprisionamento.")
                section3 = @("Esse ciclo costuma se manter por culpa, antecipa&ccedil;&atilde;o de rejei&ccedil;&atilde;o e dificuldade de tolerar frustra&ccedil;&atilde;o ou conflito.", "Quanto menos a pessoa consegue se posicionar de forma clara, mais aumenta o ac&uacute;mulo emocional e a chance de repetir a mesma din&acirc;mica.")
                section4 = @("Na psicoterapia, o foco &eacute; compreender o lugar que voc&ecirc; ocupa nos v&iacute;nculos e construir formas mais seguras de se posicionar.", "O trabalho cl&iacute;nico ajuda a fortalecer limites, reconhecer necessidades e sustentar rela&ccedil;&otilde;es com menos medo e mais clareza.")
            }
        }
    }
}

function New-CardHtml {
    param(
        [pscustomobject]$Article,
        [string]$HrefPrefix
    )

    $href = $HrefPrefix + $Article.slug + ".html"
    $cardTitle = Html (Get-CardTitle $Article.title)
    $cardDescription = Html (Get-CardDescription $Article)

    return @"
<article class="texto-card">

<h3>$cardTitle</h3>

<p>
$cardDescription
</p>

<a href="$href" class="ler-artigo">
Ler artigo &rarr;
</a>

</article>
"@.Trim()
}

function New-SitemapUrl {
    param([pscustomobject]$Article)

    return @"
  <url>
    <loc>https://carlavilla.com.br/textos/$($Article.slug).html</loc>
    <lastmod>$($Article.publishDate)</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
"@.TrimEnd()
}

function New-ArticleHtml {
    param([pscustomobject]$Article)

    $copy = Get-ClusterCopy -Article $Article
    $metaDescription = Get-MetaDescription -Article $Article
    $serviceLink = Get-ServiceLink -Cluster $Article.cluster
    $relatedLinks = Get-RelatedLinks -Cluster $Article.cluster
    $signs = Get-Signs -Cluster $Article.cluster
    $faqs = Get-FAQs -Cluster $Article.cluster
    $title = Html $Article.title
    $keyword = Html $Article.keyword
    $metaDescriptionHtml = Html $metaDescription
    $canonical = "https://carlavilla.com.br/textos/$($Article.slug).html"

    $jsonLd = [ordered]@{
        "@context" = "https://schema.org"
        "@type" = "Article"
        "@id" = "$canonical#article"
        mainEntityOfPage = $canonical
        headline = $Article.title
        description = $metaDescription
        inLanguage = "pt-BR"
        author = @{ "@type" = "Person"; name = "Carla Villa" }
        publisher = @{ "@type" = "Person"; name = "Carla Villa" }
        datePublished = $Article.publishDate
        dateModified = $Article.publishDate
        about = @($Article.keyword, "Psicoterapia online")
        isPartOf = @{ "@type" = "WebSite"; url = "https://carlavilla.com.br/" }
    } | ConvertTo-Json -Depth 6

    $signsHtml = ($signs | ForEach-Object { "<li>$(Html $_)</li>" }) -join "`r`n"
    $faqHtml = ($faqs | ForEach-Object { "<p><strong>$(Html $_.q)</strong><br>`r`n$(Html $_.a)</p>" }) -join "`r`n`r`n"
    $relatedHtml = ($relatedLinks | ForEach-Object { "<li><a href=""$($_.href)"">$(Html $_.label)</a></li>" }) -join "`r`n"

    $whatsText = switch ($Article.cluster) {
        "expatriacao" { "Olá! Moro fora do Brasil e quero conversar sobre o que estou vivendo." }
        "ansiedade" { "Olá! Quero conversar melhor sobre a minha ansiedade." }
        "autocobranca" { "Olá! Quero conversar sobre autocobrança e exaustão emocional." }
        default { "Olá! Quero conversar sobre padrões que se repetem nos meus relacionamentos." }
    }

    $whatsHref = "https://wa.me/5531993440038?text=$([System.Uri]::EscapeDataString($whatsText))"

    return @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>

<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>$title | Carla Villa</title>
<link rel="stylesheet" href="../style.css">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<meta name="description" content="$metaDescriptionHtml">
<meta name="robots" content="index, follow, max-image-preview:large">
<link rel="canonical" href="$canonical">
<meta property="og:locale" content="pt_BR">
<meta property="og:site_name" content="Carla Villa Psicologia">
<meta property="og:type" content="article">
<meta property="og:title" content="$title">
<meta property="og:description" content="$metaDescriptionHtml">
<meta property="og:url" content="$canonical">
<meta property="og:image" content="https://carlavilla.com.br/imagens/iniimg.png">
<meta property="og:image:alt" content="Psicoterapia online com Carla Villa">
<meta property="article:author" content="Carla Villa">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$title">
<meta name="twitter:description" content="$metaDescriptionHtml">
<meta name="twitter:image" content="https://carlavilla.com.br/imagens/iniimg.png">
<script type="application/ld+json">
$jsonLd
</script>
<link rel="icon" href="../favicon.ico?v=20260307" sizes="any">
<link rel="shortcut icon" href="../favicon.ico?v=20260307" type="image/x-icon">
<link rel="icon" type="image/png" sizes="32x32" href="../imagens/logo.png?v=20260307">
<link rel="apple-touch-icon" href="../imagens/logo.png?v=20260307">
</head>

<body>
<header class="artigo-topo" id="topo-artigo">
<div class="artigo-topo-inner">
<a href="../index.html#inicio" class="artigo-marca">
<img src="../imagens/logo.png" class="logo" alt="Logo Carla Villa">
<span>Carla Villa Psicologia</span>
</a>
<a href="../textos/" class="artigo-voltar">Voltar aos textos</a>
</div>
<div class="linha-metalica"></div>
</header>

<article class="artigo">

<div class="artigo-links artigo-links-topo">
<a href="../textos/" class="link-editorial">
&larr; Ver arquivo de textos
</a>
<a href="$($serviceLink.href)" class="link-editorial">
$(Html $serviceLink.label) &rarr;
</a>
</div>

<h1>$title</h1>

<p>$($copy.intro[0])</p>
<p>$($copy.intro[1])</p>
<p>$($copy.intro[2])</p>

<h2>Quando isso costuma aparecer</h2>
<p>Esse tema costuma aparecer quando <strong>$keyword</strong> come&ccedil;a a atravessar mais &aacute;reas da vida do que parecia no in&iacute;cio.</p>
<p>$($copy.section1[0])</p>
<ul>
$signsHtml
</ul>
<p>$($copy.section1[1])</p>

<h2>Por que esse padr&atilde;o pesa tanto</h2>
<p>$($copy.section2[0])</p>
<p>$($copy.section2[1])</p>

<h2>O que costuma manter esse ciclo</h2>
<p>$($copy.section3[0])</p>
<p>$($copy.section3[1])</p>

<h2>Como a psicoterapia ajuda</h2>
<p>$($copy.section4[0])</p>
<p>$($copy.section4[1])</p>

<h2>Perguntas frequentes</h2>
$faqHtml

<div class="artigo-links">
<a href="$whatsHref" class="link-editorial">
Agendar conversa &rarr;
</a>
<a href="$($serviceLink.href)" class="link-editorial">
$(Html $serviceLink.label) &rarr;
</a>
<a href="../textos/" class="link-editorial">
Ver arquivo de textos &rarr;
</a>
</div>

<section class="artigos-relacionados">
<h2>Continue lendo</h2>
<ul>
$relatedHtml
</ul>
</section>

</article>

<hr class="divider">
<div data-site-footer data-base=".."></div>
<script src="../footer.js"></script>
</body>
</html>
"@
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$queuePath = Join-Path $repoRoot "agendamentos/fila-publicacao.json"
$catalogPath = Join-Path $repoRoot "agendamentos/catalogo-artigos.json"
$indexPath = Join-Path $repoRoot "index.html"
$archivePath = Join-Path $repoRoot "textos/index.html"
$sitemapPath = Join-Path $repoRoot "sitemap.xml"

if (-not $Today) {
    $Today = Get-SaoPauloDate
}

$queue = Get-Content $queuePath -Raw -Encoding utf8 | ConvertFrom-Json
$catalog = Get-Content $catalogPath -Raw -Encoding utf8 | ConvertFrom-Json
$catalogIndex = @{}
foreach ($entry in $catalog) {
    $catalogIndex[$entry.slug] = $entry
}

$dueItems = @($queue | Where-Object { $_.status -eq "scheduled" -and $_.publishDate -le $Today } | Sort-Object publishDate, slug)
if ($dueItems.Count -eq 0) {
    Write-Host "Nenhum artigo agendado para publicar em $Today."
    exit 0
}

foreach ($item in $dueItems) {
    $article = $catalogIndex[$item.slug]
    if (-not $article) {
        throw "Artigo nao encontrado no catalogo: $($item.slug)"
    }

    $livePath = Join-Path $repoRoot "textos/$($item.slug).html"
    $html = New-ArticleHtml -Article $article

    if (-not $DryRun) {
        Write-TextFile -Path $livePath -Content $html
        Write-Host "Arquivo publicado: textos/$($item.slug).html"
    }
    else {
        Write-Host "Arquivo seria publicado: textos/$($item.slug).html"
    }

    $item.status = "published"
    if ($item.PSObject.Properties.Name -contains "publishedAt") {
        $item.publishedAt = $Today
    }
    else {
        $item | Add-Member -NotePropertyName "publishedAt" -NotePropertyValue $Today
    }
}

$publishedItems = @($queue | Where-Object { $_.status -eq "published" } | Sort-Object publishDate -Descending)
$homeCards = ($publishedItems | Select-Object -First 4 | ForEach-Object { New-CardHtml -Article $catalogIndex[$_.slug] -HrefPrefix "textos/" }) -join "`r`n`r`n"
$archiveCards = ($publishedItems | ForEach-Object { New-CardHtml -Article $catalogIndex[$_.slug] -HrefPrefix "" }) -join "`r`n`r`n"
$articleUrls = ($publishedItems | Sort-Object publishDate | ForEach-Object { New-SitemapUrl -Article $catalogIndex[$_.slug] }) -join "`r`n"

$indexContent = Set-MarkerBlock -Content (Read-TextFile -Path $indexPath) -StartMarker "<!-- AUTO-TEXTOS-START -->" -EndMarker "<!-- AUTO-TEXTOS-END -->" -Block $homeCards
$archiveContent = Set-MarkerBlock -Content (Read-TextFile -Path $archivePath) -StartMarker "<!-- AUTO-ARQUIVO-START -->" -EndMarker "<!-- AUTO-ARQUIVO-END -->" -Block $archiveCards
$sitemapContent = Set-MarkerBlock -Content (Read-TextFile -Path $sitemapPath) -StartMarker "<!-- AUTO-URLS-START -->" -EndMarker "<!-- AUTO-URLS-END -->" -Block $articleUrls
$sitemapContent = Update-SitemapLastmod -Content $sitemapContent -Loc "https://carlavilla.com.br/" -Date $Today
$sitemapContent = Update-SitemapLastmod -Content $sitemapContent -Loc "https://carlavilla.com.br/textos/" -Date $Today

if (-not $DryRun) {
    Write-TextFile -Path $indexPath -Content $indexContent
    Write-TextFile -Path $archivePath -Content $archiveContent
    Write-TextFile -Path $sitemapPath -Content $sitemapContent
    Write-TextFile -Path $queuePath -Content ($queue | ConvertTo-Json -Depth 4)
}

Write-Host "Publicacao automatica processada para $Today."
