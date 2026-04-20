param(
    [string]$Today,
    [switch]$DryRun,
    [switch]$RegenerateAll
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
    # Use ${1} / ${3} to avoid ambiguity when $Date starts with digits (e.g. 2026...).
    return [regex]::Replace($Content, $pattern, "`${1}$Date`${3}", 1)
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
    return $Title.Trim()
}

function Get-MetaDescription {
    param([pscustomobject]$Article)

    $keyword = $Article.keyword
    $variant = Get-VariantIndex -Slug $Article.slug -Length 5

    switch ($Article.cluster) {
        "expatriacao" {
            $templates = @(
                "Se você pesquisou $keyword, entenda por que isso acontece morando fora e como a terapia online em português pode ajudar.",
                "$keyword pode ser parte do luto migratório. Veja sinais, gatilhos e caminhos para lidar com isso (em português).",
                "Entenda $keyword no contexto da expatriação: solidão, adaptação cultural e pertencimento — e como a psicoterapia online ajuda.",
                "O que $keyword costuma significar para brasileiros no exterior e como iniciar terapia em português (online).",
                "Guia direto sobre ${keyword}: por que pesa, o que mantém o ciclo e como a terapia online em português pode ajudar."
            )
            return $templates[$variant]
        }
        "ansiedade" {
            $templates = @(
                "Entenda ${keyword}: sinais de alerta e como a terapia online ajuda a reduzir ruminação, tensão e estado de alerta.",
                "Se sua mente não desliga, este texto explica $keyword e o que costuma ajudar na prática (com apoio terapêutico).",
                "Ansiedade não é só nervosismo. Veja como $keyword aparece e como a psicoterapia online pode ajudar.",
                "Guia direto sobre ${keyword}: por que se repete, o que mantém o ciclo e como a terapia online pode ajudar.",
                "Quando procurar ajuda? Entenda $keyword e o que esperar de um processo de psicoterapia online."
            )
            return $templates[$variant]
        }
        "autocobranca" {
            $templates = @(
                "Entenda ${keyword}: por que a autocobrança vira ansiedade e como a psicoterapia online ajuda a flexibilizar esse padrão.",
                "$keyword pode parecer força, mas custa caro por dentro. Veja sinais e caminhos para mudar com consistência.",
                "Guia direto sobre ${keyword}: gatilhos, crenças e estratégias terapêuticas para sair do ciclo de pressão interna.",
                "Entenda como $keyword se forma, o que mantém o padrão e como a terapia online ajuda na prática.",
                "Quando a autocobrança vira sofrimento: entenda ${keyword} e como começar a mudar com apoio terapêutico."
            )
            return $templates[$variant]
        }
        default {
            $templates = @(
                "Entenda ${keyword}: por que isso se repete nos vínculos e como a psicoterapia ajuda a construir limites e clareza.",
                "Guia direto sobre ${keyword}: sinais, o que mantém o ciclo e como a terapia online pode ajudar.",
                "Quando $keyword começa a desgastar relações, vale olhar com cuidado. Entenda por onde começar.",
                "Entenda $keyword e como fortalecer posicionamento, limites e segurança emocional na prática.",
                "Veja como $keyword aparece nos relacionamentos e como a psicoterapia ajuda a interromper o padrão."
            )
            return $templates[$variant]
        }
    }
}

function Get-CardDescription {
    param([pscustomobject]$Article)

    $keyword = $Article.keyword
    $variant = Get-VariantIndex -Slug $Article.slug -Length 5

    switch ($Article.cluster) {
        "expatriacao" {
            $templates = @(
                "Uma resposta clara para quem pesquisou $keyword morando fora: por que pesa e o que costuma ajudar.",
                "Sinais e gatilhos de $keyword na expatriação — com caminhos práticos para atravessar a fase.",
                "Quando morar fora vira sobrecarga: como $keyword aparece e como a terapia em português ajuda.",
                "$keyword pode ter a ver com luto migratório. Entenda o ciclo e por onde começar.",
                "Solidão, adaptação e pertencimento: entenda $keyword e próximos passos (sem romantizar)."
            )
            return $templates[$variant]
        }
        "ansiedade" {
            $templates = @(
                "Entenda $keyword e o que ajuda a reduzir ruminação, tensão e estado de alerta (na prática).",
                "Sinais de ansiedade que passam despercebidos e como a terapia online ajuda a interromper o ciclo.",
                "Quando a mente não desliga: o que é $keyword e como começar a cuidar com consistência.",
                "Um guia direto sobre $keyword para quem quer parar de viver em alerta o tempo todo.",
                "Por que $keyword se repete e como a psicoterapia online ajuda com método e continuidade."
            )
            return $templates[$variant]
        }
        "autocobranca" {
            $templates = @(
                "Quando nada parece suficiente: entenda $keyword e como flexibilizar a pressão interna.",
                "Por que $keyword cansa tanto por dentro — e como a terapia ajuda a mudar o padrão sem perder direção.",
                "Sinais, gatilhos e caminhos para sair do ciclo de $keyword com mais estabilidade emocional.",
                "$keyword costuma esconder medo e culpa. Veja como a terapia trabalha isso na prática.",
                "Entenda $keyword e próximos passos para se relacionar consigo com mais humanidade."
            )
            return $templates[$variant]
        }
        default {
            $templates = @(
                "Como $keyword aparece nos vínculos, o que mantém o ciclo e por onde começar a mudar.",
                "Um texto direto sobre $keyword para quem quer mais limites, clareza e menos desgaste.",
                "Sinais de $keyword e caminhos práticos para fortalecer posicionamento e segurança emocional.",
                "Entenda $keyword sem culpa: por que se repete e como a terapia ajuda a interromper o padrão.",
                "Quando $keyword pesa nas relações, vale olhar com cuidado. Veja próximos passos."
            )
            return $templates[$variant]
        }
    }
}

function Get-ServiceLink {
    param([string]$Cluster)

    switch ($Cluster) {
        "expatriacao" { return [pscustomobject]@{ href = "../psicologa-online-brasileiros-no-exterior.html"; label = "Página para brasileiros no exterior" } }
        "ansiedade" { return [pscustomobject]@{ href = "../terapia-online-para-ansiedade.html"; label = "Terapia online para ansiedade" } }
        "autocobranca" { return [pscustomobject]@{ href = "../terapia-online-autocobranca.html"; label = "Terapia online para autocobrança" } }
        "relacionamentos" { return [pscustomobject]@{ href = "../terapia-online-relacionamentos.html"; label = "Terapia online para relacionamentos" } }
        default { return [pscustomobject]@{ href = "../terapia-cognitivo-comportamental-online.html"; label = "TCC online" } }
    }
}

function Select-RelatedArticles {
    param(
        [pscustomobject]$Article,
        [object[]]$AllArticles,
        [int]$Count = 3
    )

    $sameCluster = @($AllArticles | Where-Object { $_.cluster -eq $Article.cluster -and $_.slug -ne $Article.slug } | Sort-Object publishDate -Descending)
    if ($sameCluster.Count -le $Count) {
        return $sameCluster
    }

    $start = Get-VariantIndex -Slug $Article.slug -Length $sameCluster.Count
    $selected = @()
    for ($i = 0; $i -lt $Count; $i++) {
        $selected += $sameCluster[($start + $i) % $sameCluster.Count]
    }

    return $selected
}

function Get-RelatedLinks {
    param(
        [pscustomobject]$Article,
        [object[]]$AllArticles
    )

    $serviceLink = Get-ServiceLink -Cluster $Article.cluster
    $relatedArticles = Select-RelatedArticles -Article $Article -AllArticles $AllArticles -Count 3

    $links = @(
        [pscustomobject]@{ href = $serviceLink.href; label = $serviceLink.label }
    )

    foreach ($item in $relatedArticles) {
        $links += [pscustomobject]@{ href = "$($item.slug).html"; label = $item.title }
    }

    return $links
}

function Get-Signs {
    param([string]$Cluster)

    switch ($Cluster) {
        "expatriacao" {
            return @(
                "dificuldade de relaxar mesmo quando não há urgência prática",
                "saudade, culpa ou sensação de não pertencimento (nem lá, nem aqui)",
                "ansiedade com visto, trabalho, idioma e futuro no exterior",
                "solidão mesmo com pessoas por perto, por falta de rede de apoio real",
                "cansaço emocional por precisar ""dar certo"" o tempo todo"
            )
        }
        "ansiedade" {
            return @(
                "pensamentos repetitivos e dificuldade de desligar a mente",
                "tensão no corpo, irritabilidade ou cansaço constante",
                "sono ruim, insônia ou sensação de alerta no fim do dia",
                "antecipação exagerada de cenários e problemas",
                "dificuldade de descansar sem continuar preocupado(a)"
            )
        }
        "autocobranca" {
            return @(
                "sensação frequente de que nunca é suficiente",
                "culpa ao descansar ou diminuir o ritmo",
                "dificuldade de reconhecer conquistas com tranquilidade",
                "comparação constante e medo de falhar",
                "exaustão por sentir que precisa dar conta de tudo"
            )
        }
        default {
            return @(
                "dificuldade de se posicionar com clareza",
                "medo de conflito, rejeição ou afastamento",
                "tendência a engolir emoções para manter o vínculo",
                "cansaço por carregar responsabilidades emocionais demais",
                "culpa ao colocar limites ou pedir ajuda"
            )
        }
    }
}

function Get-FAQs {
    param([string]$Cluster)

    switch ($Cluster) {
        "expatriacao" {
            return @(
                [pscustomobject]@{ q = "Isso é normal morando fora?"; a = "Mudanças de país costumam ativar saudade, adaptação, perda simbólica e conflitos de pertencimento. Se isso se mantém por muito tempo ou começa a limitar sua vida, vale buscar cuidado." },
                [pscustomobject]@{ q = "Preciso escolher um país específico para a terapia fazer sentido?"; a = "Não. O importante é trabalhar a sua experiência real: rotina, vínculos, trabalho, identidade, solidão e o que a mudança de país ativou emocionalmente." },
                [pscustomobject]@{ q = "A terapia online em português ajuda?"; a = "Sim. Para muitos brasileiros no exterior, falar em português reduz isolamento e facilita nomear nuances emocionais que são difíceis de explicar em outra língua." },
                [pscustomobject]@{ q = "Como funciona o fuso horário?"; a = "As sessões são online e agendadas considerando seu fuso. No primeiro contato, alinhamos disponibilidade e combinamos um horário viável para continuidade." }
            )
        }
        "ansiedade" {
            return @(
                [pscustomobject]@{ q = "Isso pode ser ansiedade?"; a = "Quando alerta constante, preocupação excessiva, pensamentos repetitivos e dificuldade de relaxar começam a dominar a rotina, a ansiedade merece atenção clínica." },
                [pscustomobject]@{ q = "Quando procurar terapia para ansiedade?"; a = "Quando o padrão começa a afetar sono, trabalho, relações, decisões ou saúde física, a psicoterapia pode ser um recurso importante." },
                [pscustomobject]@{ q = "A terapia online ajuda com ruminação (pensamentos repetitivos)?"; a = "Sim. O trabalho clínico ajuda a identificar gatilhos, reduzir ruminação e construir respostas mais reguladas para lidar com incertezas." },
                [pscustomobject]@{ q = "O que eu faço se estiver em crise?"; a = "Em caso de risco de autoagressão, emergência ou crise intensa, procure suporte imediato e serviços locais da sua região. A terapia é um cuidado importante, mas não substitui atendimento de urgência." }
            )
        }
        "autocobranca" {
            return @(
                [pscustomobject]@{ q = "Autocobrança pode parecer força?"; a = "Pode. Muitas vezes ela se apresenta como disciplina ou responsabilidade, mas por dentro produz ansiedade, culpa e exaustão." },
                [pscustomobject]@{ q = "Quando esse padrão vira sofrimento?"; a = "Quando descansar parece errado, nada parece suficiente e a vida passa a ser guiada por pressão interna constante — mesmo quando você já está fazendo muito." },
                [pscustomobject]@{ q = "A terapia ajuda a flexibilizar esse jeito?"; a = "Sim. A psicoterapia ajuda a compreender de onde vem a cobrança, o que ela tenta evitar e como construir uma relação mais humana consigo mesmo(a)." },
                [pscustomobject]@{ q = "Vou perder desempenho se eu diminuir a cobrança?"; a = "O objetivo não é perder direção. É reduzir o custo interno e construir consistência sem viver em tensão, culpa e medo o tempo todo." }
            )
        }
        default {
            return @(
                [pscustomobject]@{ q = "Isso significa que há algo errado comigo?"; a = "Não. Em muitos casos, esse padrão foi aprendido ao longo da vida como forma de proteger vínculos ou evitar dor emocional." },
                [pscustomobject]@{ q = "Quando buscar terapia por causa dos relacionamentos?"; a = "Quando o sofrimento nas relações se repete, gera culpa, exaustão ou dificuldade de se posicionar, vale buscar cuidado." },
                [pscustomobject]@{ q = "A terapia ajuda a construir limites?"; a = "Sim. O trabalho terapêutico ajuda a reconhecer necessidades, flexibilizar medos e sustentar posicionamentos com mais clareza." },
                [pscustomobject]@{ q = "Como saber se eu estou em um ciclo repetitivo?"; a = "Quando você vive sempre a mesma dinâmica (evitar conflito, agradar demais, sentir culpa por dizer não) e isso traz desgaste, é um sinal de padrão que merece ser compreendido." }
            )
        }
    }
}

function Get-ClusterCopy {
    param([pscustomobject]$Article)

    $variant = Get-VariantIndex -Slug $Article.slug -Length 5
    $keyword = Html $Article.keyword

    switch ($Article.cluster) {
        "expatriacao" {
            $intros = @(
                @("Se você pesquisou <strong>$keyword</strong>, provavelmente não é falta de gratidão por morar fora. É um sinal de que algo por dentro começou a pesar.", "A expatriação mistura conquista com perdas simbólicas: idioma, rede de apoio, rotina, papel na família e pertencimento.", "A terapia online em português pode ser um espaço para elaborar esse processo com clareza — sem precisar se traduzir."),
                @("<strong>$keyword</strong> costuma aparecer quando a adaptação exige que você funcione o tempo todo: trabalho, documentos, idioma, decisões e recomeços.", "Por fora, a vida anda. Por dentro, cresce cansaço, solidão, culpa e um estado de alerta difícil de desligar.", "Quando esse custo emocional se acumula, buscar ajuda deixa de ser luxo e vira cuidado."),
                @("Morar fora pode ser certo e, ao mesmo tempo, difícil. <strong>$keyword</strong> é um tema comum entre brasileiros no exterior.", "Muitas vezes, isso tem relação com o luto migratório: o que ficou para trás, o que mudou em você e a falta de rede de apoio.", "A psicoterapia ajuda a organizar esse emaranhado e construir recursos para atravessar a fase com mais estabilidade."),
                @("Às vezes, <strong>$keyword</strong> não é sobre o país. É sobre o que a mudança ativou: identidade, vínculos, autocobrança e medo de não dar certo.", "Quando você precisa se adaptar sem a mesma rede de antes, o corpo entra em modo de sobrevivência.", "A terapia online em português ajuda a reduzir isolamento e a dar nome ao que está acontecendo."),
                @("Se você está vivendo <strong>$keyword</strong>, talvez esteja cansado(a) de ""dar conta"" e ainda assim sentir que não pertence.", "Esse tipo de sofrimento não é fraqueza: é uma transição complexa acontecendo por dentro.", "Com método e continuidade, é possível elaborar perdas, reconstruir pertencimento e sair do modo alerta.")
            )

            return @{
                intro = $intros[$variant]
                section1 = @(
                    "Esse tema costuma aparecer em fases de mudança: primeiros meses, troca de cidade, ajustes de trabalho, processos de visto ou quando a saudade encontra pouco espaço para ser vivida.",
                    "Também pode surgir quando a pessoa percebe que está vivendo a vida toda em outra língua — e que isso cansa mais do que parecia no início."
                )
                section2 = @(
                    "O peso costuma vir da soma: perdas simbólicas, distância da família, necessidade de performar competência e a falta de uma rede que acolha sem explicação.",
                    "Quando não existe espaço para ambivalência (amar a escolha e sofrer com ela), o sofrimento tende a virar culpa e isolamento."
                )
                section3 = @(
                    "O ciclo se mantém quando você tenta resolver tudo sozinho(a), trata sofrimento como fracasso e adia o cuidado para depois de ""estabilizar"" a vida.",
                    "A autocobrança de precisar dar certo pode empurrar emoções para baixo do tapete — e elas voltam em forma de ansiedade, irritação ou vazio."
                )
                section4 = @(
                    "Na psicoterapia, o foco é mapear gatilhos, nomear perdas, trabalhar pertencimento e construir estratégias para regular ansiedade e solidão no cotidiano.",
                    "O processo ajuda a sustentar escolhas com mais clareza, sem viver em guerra interna entre ""tenho que aguentar"" e ""não dou conta""."
                )
                section5 = @(
                    "Alguns passos ajudam a reduzir a sobrecarga (sem substituir terapia):",
                    "Se isso estiver muito difícil, conversar com um(a) psicólogo(a) em português pode facilitar muito o caminho."
                )
                steps = @(
                    "Nomeie o que você perdeu e o que você ganhou com a mudança (sem romantizar).",
                    "Crie micro-rotinas de pertencimento: 1 contato de qualidade por semana + 1 lugar/atividade fixa.",
                    "Observe o modo ""alerta"": sono, café, telas e decisões sem pausa costumam piorar o ciclo.",
                    "Procure espaços em português quando possível (sem se isolar do país atual)."
                )
            }
        }
        "ansiedade" {
            $intros = @(
                @("Se você pesquisou <strong>$keyword</strong>, talvez já esteja cansado(a) de tentar controlar a mente e ainda assim sentir que ela não desliga.", "Ansiedade não é só preocupação: envolve corpo em tensão, interpretações automáticas e estratégias de controle que se retroalimentam.", "A terapia online ajuda a entender gatilhos e construir respostas mais reguladas para o dia a dia."),
                @("<strong>$keyword</strong> pode aparecer como modo de funcionamento: antecipar cenários, revisar mentalmente, ficar em alerta mesmo quando nada está acontecendo.", "Com o tempo, isso afeta sono, humor, relações e a capacidade de descansar sem culpa.", "Buscar ajuda é um passo de cuidado — não um sinal de fraqueza."),
                @("Muita gente tenta resolver <strong>$keyword</strong> com força: produtividade, distração, evitar sentir. E isso pode até aliviar por minutos.", "Mas o ciclo volta porque a raiz não foi trabalhada: gatilhos, crenças e hábitos que alimentam ruminação.", "Na psicoterapia, a gente trabalha método e continuidade para reduzir esse padrão."),
                @("Quando a mente entra em modo de prever tudo para não sofrer, <strong>$keyword</strong> vira um ""trabalho"" que nunca acaba.", "Esse esforço drena energia e mantém o corpo em alerta.", "A terapia ajuda a lidar com incerteza e a flexibilizar pensamentos automáticos."),
                @("<strong>$keyword</strong> pode coexistir com uma vida funcionando por fora — e exausta por dentro.", "Se a ansiedade começa a atravessar várias áreas, vale olhar com cuidado e estrutura.", "A psicoterapia online é um caminho possível para reduzir sofrimento e recuperar clareza.")
            )

            return @{
                intro = $intros[$variant]
                section1 = @(
                    "Esse tema costuma aparecer quando a ansiedade começa a atravessar mais áreas: trabalho, relacionamentos, sono e decisões.",
                    "Muitas pessoas descrevem como ""mente acelerada"", ""pensamento repetindo"" e sensação de alerta constante."
                )
                section2 = @(
                    "A ansiedade pesa porque envolve corpo e mente: tensão, hiperatenção e interpretações que fazem o mundo parecer mais perigoso do que ele é naquele momento.",
                    "Quando o descanso vira um lugar onde a mente corre solta, a pessoa passa a evitar parar — e isso mantém o ciclo."
                )
                section3 = @(
                    "Ruminação, checagens, evitar situações, tentar controlar tudo e buscar certeza o tempo todo são estratégias comuns — e esgotantes.",
                    "Elas aliviam no curto prazo, mas aumentam ansiedade no longo prazo."
                )
                section4 = @(
                    "Na psicoterapia, trabalhamos gatilhos, pensamentos automáticos, regulação emocional e estratégias práticas para reduzir ruminação e sustentar escolhas.",
                    "Com consistência, é possível sair do modo alerta e construir uma relação mais segura com a própria mente."
                )
                section5 = @(
                    "Alguns passos ajudam no dia a dia (sem substituir terapia):",
                    "Se o sofrimento estiver intenso, procure ajuda profissional e suporte local em caso de crise."
                )
                steps = @(
                    "Faça uma pausa curta quando perceber ruminação: nomeie ""estou ruminando"" e volte para uma ação simples.",
                    "Observe gatilhos: sono irregular, excesso de telas e cafeína costumam aumentar o estado de alerta.",
                    "Separe ""tempo de preocupação"": 10–15 min com papel ajuda a reduzir o loop mental.",
                    "Busque apoio: falar em voz alta com alguém de confiança reduz a sensação de estar sozinho(a) com a mente."
                )
            }
        }
        "autocobranca" {
            $intros = @(
                @("Existe diferença entre responsabilidade e <strong>$keyword</strong>. Quando a autocobrança domina, descanso vira culpa e conquista vira insuficiente.", "Muita gente é vista como forte por fora, mas por dentro vive em tensão e medo de falhar.", "A terapia ajuda a entender de onde vem esse padrão e a flexibilizar a pressão interna."),
                @("Se você pesquisou <strong>$keyword</strong>, talvez esteja cansado(a) de viver em modo desempenho.", "Quando tudo precisa ser perfeito, o corpo não relaxa e a mente não descansa.", "O trabalho terapêutico ajuda a construir consistência sem violência interna."),
                @("<strong>$keyword</strong> costuma vir junto de medo: falhar, decepcionar, perder valor ou controle.", "A pessoa tenta se proteger cobrando mais — e o custo vira ansiedade, irritação e exaustão.", "Na psicoterapia, a gente trabalha crenças, gatilhos e estratégias para sair desse ciclo."),
                @("Às vezes, <strong>$keyword</strong> aparece como disciplina. Mas, por dentro, é uma voz que nunca está satisfeita.", "Quando nada parece suficiente, a vida vira uma lista interminável de ""ainda falta"".", "A terapia ajuda a reconstruir uma relação mais humana consigo mesmo(a)."),
                @("Se você vive <strong>$keyword</strong>, talvez já tenha tentado reduzir a cobrança — e logo se sentiu culpado(a).", "Isso é comum: o padrão se mantém porque parece garantir segurança e aprovação.", "Com método e continuidade, é possível flexibilizar sem perder direção.")
            )

            return @{
                intro = $intros[$variant]
                section1 = @(
                    "Esse padrão costuma aparecer em pessoas responsáveis, comprometidas e acostumadas a funcionar sob pressão — inclusive quando estão cansadas.",
                    "O problema começa quando a cobrança deixa de ajudar e passa a produzir culpa, comparação e sensação de insuficiência crônica."
                )
                section2 = @(
                    "A autocobrança pesa porque faz a vida parecer uma prova constante. O corpo vive em tensão e o descanso perde o sentido.",
                    "Com o tempo, prazer, espontaneidade e reconhecimento de limites ficam menores."
                )
                section3 = @(
                    "O ciclo costuma se manter por comparação, medo de desapontar, perfeccionismo e a ideia de que ""se eu relaxar, tudo desanda"".",
                    "Quanto mais você vive pela lógica do ""ainda não basta"", maior o risco de ansiedade e exaustão."
                )
                section4 = @(
                    "Na psicoterapia, o foco é entender a origem da cobrança, o que ela tenta evitar e como construir um padrão mais flexível e sustentável.",
                    "O objetivo não é perder responsabilidade, mas reduzir o custo interno e recuperar humanidade."
                )
                section5 = @(
                    "Alguns passos ajudam a diminuir a pressão (sem substituir terapia):",
                    "Se você percebe sofrimento constante, buscar ajuda é um passo importante."
                )
                steps = @(
                    "Troque ""tenho que"" por ""eu escolho"": isso muda a relação com a tarefa.",
                    "Defina um ""bom o suficiente"" para hoje (e pare quando chegar nele).",
                    "Observe a culpa ao descansar: ela costuma ser um gatilho, não uma verdade.",
                    "Reconheça 1 conquista por dia sem acrescentar ""mas""."
                )
            }
        }
        default {
            $intros = @(
                @("Se você pesquisou <strong>$keyword</strong>, talvez esteja vivendo um ciclo que se repete nos vínculos: você se adapta demais e some de si.", "Por fora, a relação pode parecer ok. Por dentro, cresce medo, culpa, cansaço e ressentimento.", "Entender o padrão é o primeiro passo para construir limites e clareza."),
                @("<strong>$keyword</strong> costuma aparecer quando o medo de conflito ou rejeição fica maior do que o espaço para autenticidade.", "A pessoa evita falar, engole emoções e tenta manter o clima — até esgotar.", "A terapia ajuda a fortalecer posicionamento e segurança emocional."),
                @("Algumas pessoas só percebem o peso de <strong>$keyword</strong> quando já estão cansadas demais.", "Não é falta de vontade: é um padrão aprendido para proteger vínculos e evitar dor.", "Na psicoterapia, a gente compreende a lógica do padrão e constrói novas formas de se relacionar."),
                @("<strong>$keyword</strong> pode parecer ""meu jeito"", mas muitas vezes é uma estratégia antiga funcionando no automático.", "O custo aparece em forma de desgaste, solidão dentro da relação e medo de se posicionar.", "Com método e prática, dá para construir relações mais honestas e leves."),
                @("Se <strong>$keyword</strong> se repete, vale olhar com cuidado: o problema não é você ser sensível demais.", "O problema é carregar sozinho(a) o trabalho emocional de manter o vínculo.", "A terapia ajuda a sair desse lugar e a sustentar limites sem culpa.")
            )

            return @{
                intro = $intros[$variant]
                section1 = @(
                    "Esse tema costuma aparecer em relações amorosas, familiares e até profissionais, especialmente quando você sente que precisa administrar o clima emocional o tempo todo.",
                    "Nesses casos, o vínculo continua existindo, mas à custa de muito esforço interno e pouco espaço para autenticidade."
                )
                section2 = @(
                    "Padrões relacionais persistem porque, em algum momento, fizeram sentido como proteção ou forma de pertencimento.",
                    "O problema é que aquilo que um dia ajudou pode, no presente, produzir medo, desgaste e sensação de aprisionamento."
                )
                section3 = @(
                    "O ciclo costuma se manter por culpa, antecipação de rejeição e dificuldade de tolerar frustração ou conflito.",
                    "Quanto menos você se posiciona com clareza, mais aumenta o acúmulo emocional — e a chance de repetir a mesma dinâmica."
                )
                section4 = @(
                    "Na psicoterapia, o foco é compreender o lugar que você ocupa nos vínculos e construir formas mais seguras de se posicionar.",
                    "O trabalho ajuda a fortalecer limites, reconhecer necessidades e sustentar relações com menos medo e mais clareza."
                )
                section5 = @(
                    "Alguns passos ajudam a começar (sem substituir terapia):",
                    "Se isso estiver se repetindo e te desgastando, buscar ajuda pode encurtar muito o caminho."
                )
                steps = @(
                    "Identifique 1 situação recorrente e o que você evita dizer nela.",
                    "Faça um pedido pequeno e específico (em vez de engolir tudo).",
                    "Observe a culpa: ela aparece quando você tenta mudar o padrão.",
                    "Treine limites curtos: ""eu não consigo"", ""hoje não"", ""preciso pensar""."
                )
            }
        }
    }
}

function Get-ClusterCopy_Old {
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
    param(
        [pscustomobject]$Article,
        [object[]]$AllArticles
    )

    $copy = Get-ClusterCopy -Article $Article
    $metaDescription = Get-MetaDescription -Article $Article
    $serviceLink = Get-ServiceLink -Cluster $Article.cluster
    $relatedLinks = Get-RelatedLinks -Article $Article -AllArticles $AllArticles
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
    $stepsHtml = ""
    if ($copy.PSObject.Properties.Name -contains "steps" -and $copy.steps) {
        $stepsHtml = ($copy.steps | ForEach-Object { "<li>$(Html $_)</li>" }) -join "`r`n"
    }
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
 <p>Esse tema costuma aparecer quando as exig&ecirc;ncias dessa fase come&ccedil;am a atravessar mais &aacute;reas da vida do que parecia no in&iacute;cio.</p>
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

<h2>O que pode ajudar no dia a dia</h2>
<p>$($copy.section5[0])</p>
<ul>
$stepsHtml
</ul>
<p>$($copy.section5[1])</p>

<h2>Perguntas frequentes</h2>
$faqHtml

<div class="artigo-links">
<a href="$whatsHref" class="link-editorial">
Quero agendar uma conversa &rarr;
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

function Select-HomeArticles {
    param([object[]]$Articles)

    $priority = @("expatriacao", "ansiedade", "autocobranca", "relacionamentos")
    $selected = @()

    foreach ($cluster in $priority) {
        $item = @($Articles | Where-Object { $_.cluster -eq $cluster } | Sort-Object publishDate -Descending | Select-Object -First 1)
        if ($item) {
            $selected += $item[0]
        }
    }

    if ($selected.Count -lt 4) {
        $remaining = @($Articles | Where-Object { $selected.slug -notcontains $_.slug } | Sort-Object publishDate -Descending)
        $selected += @($remaining | Select-Object -First (4 - $selected.Count))
    }

    return @($selected | Select-Object -First 4)
}

function New-ArchiveCardsGroupedHtml {
    param([object[]]$Articles)

    $clusters = @(
        [pscustomobject]@{ key = "expatriacao"; id = "exterior"; kicker = "Brasileiros no exterior"; title = "Saudade, solidão, adaptação e pertencimento"; lead = "Textos para quem mora fora e quer entender o que está pesando por dentro — e por onde começar." },
        [pscustomobject]@{ key = "ansiedade"; id = "ansiedade"; kicker = "Ansiedade"; title = "Mente acelerada, ruminação e estado de alerta"; lead = "Buscas comuns: ansiedade sem motivo, pensamentos repetitivos, dificuldade de relaxar e de dormir." },
        [pscustomobject]@{ key = "autocobranca"; id = "autocobranca"; kicker = "Autocobrança"; title = "Perfeccionismo, culpa e sensação de insuficiência"; lead = "Textos para sair do ciclo do ""nunca é suficiente"" sem perder direção e responsabilidade." },
        [pscustomobject]@{ key = "relacionamentos"; id = "relacionamentos"; kicker = "Relacionamentos"; title = "Limites, medo de conflito e padrões que se repetem"; lead = "Textos para entender dinâmicas nos vínculos e construir posicionamento com mais clareza." }
    )

    $blocks = @()
    foreach ($cluster in $clusters) {
        $items = @($Articles | Where-Object { $_.cluster -eq $cluster.key } | Sort-Object publishDate -Descending)
        if ($items.Count -eq 0) {
            continue
        }

        $cards = ($items | ForEach-Object { New-CardHtml -Article $_ -HrefPrefix "" }) -join "`r`n`r`n"

        $blocks += @"
<section id="$($cluster.id)" class="archive-cluster">
<p class="landing-kicker">$($cluster.kicker)</p>
<h2>$($cluster.title)</h2>
<p class="landing-lead">
$($cluster.lead)
</p>
<div class="textos-grid archive-grid">
$cards
</div>
</section>
"@.Trim()
    }

    return ($blocks -join "`r`n`r`n")
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

$publishedAll = @($catalog | Sort-Object publishDate -Descending)

if ($RegenerateAll) {
    foreach ($article in $publishedAll) {
        $livePath = Join-Path $repoRoot "textos/$($article.slug).html"
        $html = New-ArticleHtml -Article $article -AllArticles $publishedAll

        if (-not $DryRun) {
            Write-TextFile -Path $livePath -Content $html
            Write-Host "Arquivo regenerado: textos/$($article.slug).html"
        }
        else {
            Write-Host "Arquivo seria regenerado: textos/$($article.slug).html"
        }
    }

    $homeSelection = Select-HomeArticles -Articles $publishedAll
    $homeCards = ($homeSelection | ForEach-Object { New-CardHtml -Article $_ -HrefPrefix "textos/" }) -join "`r`n`r`n"
    $archiveCards = New-ArchiveCardsGroupedHtml -Articles $publishedAll
    $articleUrls = ($publishedAll | Sort-Object publishDate | ForEach-Object { New-SitemapUrl -Article $_ }) -join "`r`n"

    $indexContent = Set-MarkerBlock -Content (Read-TextFile -Path $indexPath) -StartMarker "<!-- AUTO-TEXTOS-START -->" -EndMarker "<!-- AUTO-TEXTOS-END -->" -Block $homeCards
    $archiveContent = Set-MarkerBlock -Content (Read-TextFile -Path $archivePath) -StartMarker "<!-- AUTO-ARQUIVO-START -->" -EndMarker "<!-- AUTO-ARQUIVO-END -->" -Block $archiveCards
    $sitemapContent = Set-MarkerBlock -Content (Read-TextFile -Path $sitemapPath) -StartMarker "<!-- AUTO-URLS-START -->" -EndMarker "<!-- AUTO-URLS-END -->" -Block $articleUrls
    $sitemapContent = Update-SitemapLastmod -Content $sitemapContent -Loc "https://carlavilla.com.br/" -Date $Today
    $sitemapContent = Update-SitemapLastmod -Content $sitemapContent -Loc "https://carlavilla.com.br/psicologa-online-brasileiros-no-exterior.html" -Date $Today
    $sitemapContent = Update-SitemapLastmod -Content $sitemapContent -Loc "https://carlavilla.com.br/terapia-online-para-ansiedade.html" -Date $Today
    $sitemapContent = Update-SitemapLastmod -Content $sitemapContent -Loc "https://carlavilla.com.br/terapia-online-luto-migratorio.html" -Date $Today
    $sitemapContent = Update-SitemapLastmod -Content $sitemapContent -Loc "https://carlavilla.com.br/terapia-cognitivo-comportamental-online.html" -Date $Today
    $sitemapContent = Update-SitemapLastmod -Content $sitemapContent -Loc "https://carlavilla.com.br/terapia-online-autocobranca.html" -Date $Today
    $sitemapContent = Update-SitemapLastmod -Content $sitemapContent -Loc "https://carlavilla.com.br/terapia-online-relacionamentos.html" -Date $Today
    $sitemapContent = Update-SitemapLastmod -Content $sitemapContent -Loc "https://carlavilla.com.br/textos/" -Date $Today

    if (-not $DryRun) {
        Write-TextFile -Path $indexPath -Content $indexContent
        Write-TextFile -Path $archivePath -Content $archiveContent
        Write-TextFile -Path $sitemapPath -Content $sitemapContent
    }

    Write-Host "Regeneracao concluida para $Today."
    exit 0
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
    $html = New-ArticleHtml -Article $article -AllArticles $publishedAll

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
$publishedArticles = @($publishedItems | ForEach-Object { $catalogIndex[$_.slug] })
$homeSelection = Select-HomeArticles -Articles $publishedArticles
$homeCards = ($homeSelection | ForEach-Object { New-CardHtml -Article $_ -HrefPrefix "textos/" }) -join "`r`n`r`n"
$archiveCards = New-ArchiveCardsGroupedHtml -Articles $publishedArticles
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

