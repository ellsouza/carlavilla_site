param(
    [string]$StartDate = "2026-03-17",
    [string]$EndDate = "2026-12-31"
)

$ErrorActionPreference = "Stop"

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Add-TopicsFromText {
    param(
        [string]$Cluster,
        [string]$Text,
        [System.Collections.Generic.List[object]]$Target
    )

    $lines = $Text -split "`r?`n" | Where-Object { $_.Trim() }
    foreach ($line in $lines) {
        $parts = $line.Split("|")
        if ($parts.Count -ne 3) {
            throw "Linha invalida para o cluster '$Cluster': $line"
        }

        $Target.Add([pscustomobject]@{
            slug = $parts[0].Trim()
            title = $parts[1].Trim()
            keyword = $parts[2].Trim()
            cluster = $Cluster
        })
    }
}

$topics = [System.Collections.Generic.List[object]]::new()

$expatriacao = @'
ansiedade-morando-no-exterior|Ansiedade morando no exterior: por que a mente fica em alerta|ansiedade morando no exterior
como-se-adaptar-a-outro-pais|Como se adaptar a outro país sem se perder de si|como se adaptar a outro país
culpa-por-morar-fora-da-familia|Culpa por morar fora da família: é normal?|culpa por morar fora da família
nao-me-sinto-em-casa-em-nenhum-lugar|Não me sinto em casa em nenhum lugar: e agora?|não me sinto em casa em nenhum lugar
choque-cultural-sintomas|Choque cultural: sintomas emocionais que aparecem na rotina|choque cultural sintomas
como-fazer-amigos-morando-fora|Como fazer amigos morando fora sem se forçar|como fazer amigos morando fora
solidao-morando-no-exterior|Solidão morando no exterior: quando isso começa a pesar|solidão morando no exterior
saudade-da-familia-morando-fora|Saudade da família morando fora: como lidar|saudade da família morando fora
crise-de-identidade-morando-fora|Crise de identidade morando fora: por que isso acontece?|crise de identidade morando fora
terapia-para-brasileiros-no-exterior-funciona|Terapia para brasileiros no exterior funciona?|terapia para brasileiros no exterior funciona
sindrome-do-impostor-morando-fora|Síndrome do impostor morando fora: como isso aparece|síndrome do impostor morando fora
medo-de-nao-dar-certo-no-exterior|Medo de não dar certo no exterior: o que isso revela|medo de não dar certo no exterior
ansiedade-para-falar-outro-idioma|Ansiedade para falar outro idioma: como reduzir o travamento|ansiedade para falar outro idioma
comparacao-com-outros-brasileiros-no-exterior|Comparação com outros brasileiros no exterior: por que isso desgasta?|comparação com outros brasileiros no exterior
dificuldade-de-pertencimento-no-exterior|Dificuldade de pertencimento no exterior: por que isso persiste?|dificuldade de pertencimento no exterior
feriados-longe-de-casa|Feriados longe de casa: como lidar emocionalmente|como lidar com feriados longe de casa
casamento-em-crise-morando-fora|Casamento em crise morando fora: o que muda na relação?|casamento em crise morando fora
relacionamento-abalado-pela-mudanca-de-pais|Relacionamento abalado pela mudança de país: por que isso pesa tanto?|relacionamento abalado pela mudança de país
exaustao-emocional-de-recomecar-em-outro-pais|Exaustão emocional de recomeçar em outro país|exaustão emocional de recomeçar em outro país
sentir-que-ficou-para-tras-morando-fora|Morar fora e sentir que ficou para trás: como entender|morar fora e sentir que ficou para trás
medo-de-voltar-para-o-brasil|Medo de voltar para o Brasil: o que esse conflito mostra?|medo de voltar para o Brasil
culpa-por-nao-visitar-a-familia|Culpa por não visitar a família: como elaborar|culpa por não visitar a família
terapia-online-em-portugues-morando-fora|Terapia online em português morando fora: quando buscar|terapia online em português morando fora
morar-fora-piorou-minha-ansiedade|Morar fora piorou minha ansiedade: o que fazer?|morar fora piorou minha ansiedade
como-lidar-com-a-solidao-no-primeiro-ano-fora|Como lidar com a solidão no primeiro ano fora|como lidar com a solidão morando fora
sinto-falta-de-quem-eu-era-no-brasil|Sinto falta de quem eu era no Brasil: o que isso significa?|sinto falta de quem eu era no Brasil
vale-a-pena-fazer-terapia-em-portugues-morando-fora|Vale a pena fazer terapia em português morando fora?|terapia em português morando fora
o-que-e-luto-cultural|O que é luto cultural e como ele aparece|luto cultural
me-sinto-deslocada-mesmo-depois-de-anos-fora|Por que me sinto deslocada mesmo depois de anos fora?|me sinto deslocada morando fora
rotina-emocional-em-outro-pais|Como criar rotina emocional em outro país|rotina emocional morando fora
morar-fora-sobrecarga-emocional|Quando morar fora deixa de ser sonho e vira sobrecarga|morar fora sobrecarga emocional
psicologa-brasileira-no-exterior-como-escolher|Psicóloga brasileira no exterior: como escolher|psicóloga brasileira no exterior
'@

$ansiedade = @'
a-mente-nao-desliga-a-noite|A mente não desliga à noite: por que isso acontece?|a mente não desliga à noite
por-que-penso-demais-em-tudo|Por que penso demais em tudo?|por que penso demais
preocupacao-excessiva-o-tempo-todo|Preocupação excessiva o tempo todo: quando isso vira ansiedade?|preocupação excessiva o tempo todo
medo-constante-de-decepcionar-pessoas|Medo constante de decepcionar pessoas: o que está por trás?|medo constante de decepcionar pessoas
sintomas-fisicos-da-ansiedade-no-trabalho|Sintomas físicos da ansiedade no trabalho: quando o corpo fala|sintomas físicos da ansiedade no trabalho
ansiedade-no-trabalho-como-perceber|Ansiedade no trabalho: como perceber antes de estourar|ansiedade no trabalho
cansaco-mental-constante|Cansaço mental constante: quando a mente nunca descansa|cansaço mental constante
mente-acelerada-o-que-fazer|Mente acelerada: o que fazer quando parece impossível desligar?|mente acelerada o que fazer
como-parar-pensamentos-repetitivos|Como parar pensamentos repetitivos sem brigar com a mente|como parar pensamentos repetitivos
por-que-reviso-conversas-na-cabeca|Por que fico revisando conversas na cabeça?|por que reviso conversas na cabeça
ansiedade-antes-de-dormir|Ansiedade antes de dormir: por que o corpo não relaxa?|ansiedade antes de dormir
ansiedade-por-mensagem-nao-respondida|Ansiedade por mensagem não respondida: por que isso mexe tanto?|ansiedade por mensagem não respondida
ansiedade-ao-tomar-decisao|Ansiedade ao tomar decisão: quando escolher parece perigoso|ansiedade ao tomar decisão
como-saber-se-minha-ansiedade-precisa-de-terapia|Como saber se minha ansiedade precisa de terapia?|como saber se minha ansiedade precisa de terapia
ansiedade-e-procrastinacao|Ansiedade e procrastinação: por que travo mesmo querendo agir?|ansiedade e procrastinação
ansiedade-e-controle|Ansiedade e necessidade de controle: por que é tão difícil soltar?|ansiedade e controle
medo-de-errar-o-tempo-todo|Medo de errar o tempo todo: quando isso começa a limitar sua vida|medo de errar o tempo todo
aperto-no-peito-e-ansiedade-emocional|Aperto no peito e ansiedade emocional: o que isso pode mostrar?|aperto no peito e ansiedade emocional
ansiedade-sem-motivo-aparente|Ansiedade sem motivo aparente: por que isso acontece?|ansiedade sem motivo aparente
ansiedade-alta-pela-manha|Ansiedade alta pela manhã: por que o dia começa no alerta?|ansiedade alta pela manhã
'@

$autocobranca = @'
sensacao-de-estar-sempre-atrasado-na-vida|Sensação de estar sempre atrasado na vida: de onde vem isso?|sensação de estar sempre atrasado na vida
por-que-me-cobro-tanto-mesmo-quando-tudo-esta-bem|Por que me cobro tanto mesmo quando tudo está bem?|por que me cobro tanto
sindrome-do-impostor-no-trabalho|Síndrome do impostor no trabalho: quando nada parece suficiente|síndrome do impostor no trabalho
comparacao-constante-com-os-outros|Comparação constante com os outros: por que isso desgasta tanto?|comparação constante com os outros
autocritica-excessiva|Autocrítica excessiva: quando a voz interna nunca alivia|autocrítica excessiva
medo-de-nao-ser-bom-o-suficiente|Medo de não ser bom o suficiente: por que isso persiste?|medo de não ser bom o suficiente
dificuldade-de-comemorar-conquistas|Dificuldade de comemorar conquistas: por que nada parece bastante?|dificuldade de comemorar conquistas
necessidade-de-agradar-todo-mundo|Necessidade de agradar todo mundo: o custo emocional desse padrão|necessidade de agradar todo mundo
dificuldade-de-dizer-nao-sem-culpa|Dificuldade de dizer não sem culpa: por que isso pesa tanto?|dificuldade de dizer não sem culpa
exaustao-de-ter-que-dar-conta-de-tudo|Exaustão de ter que dar conta de tudo: quando a cobrança vira peso|exaustão de ter que dar conta de tudo
produtividade-toxica|Produtividade tóxica: quando descansar parece errado|produtividade tóxica
necessidade-de-controle-e-perfeccionismo|Necessidade de controle e perfeccionismo: por que é tão difícil flexibilizar?|necessidade de controle e perfeccionismo
vergonha-de-falhar|Vergonha de falhar: o que essa dor tenta evitar?|vergonha de falhar
medo-de-decepcionar-a-familia|Medo de decepcionar a família: quando a cobrança vem de dentro|medo de decepcionar a família
culpa-ao-descansar|Culpa ao descansar: por que parar parece perigoso?|culpa ao descansar
nada-do-que-faco-parece-suficiente|Nada do que faço parece suficiente: por que essa sensação não passa?|nada do que faço parece suficiente
autoexigencia-de-ser-forte-o-tempo-todo|Autoexigência de ser forte o tempo todo: quando isso vira exaustão|autoexigência de ser forte o tempo todo
preciso-dar-conta-de-tudo-sozinha|Preciso dar conta de tudo sozinha: por que isso me esgota?|preciso dar conta de tudo sozinha
'@

$relacionamentos = @'
como-colocar-limites-sem-culpa|Como colocar limites sem culpa|como colocar limites sem culpa
por-que-evito-conflito|Por que evito conflito mesmo quando estou sofrendo?|por que evito conflito
sensacao-de-carregar-a-relacao-sozinha|Sensação de carregar a relação sozinha: quando isso desgasta demais|sensação de carregar a relação sozinha
medo-de-abandono-em-relacionamentos|Medo de abandono em relacionamentos: o que isso costuma revelar?|medo de abandono em relacionamentos
dificuldade-de-confiar-nas-pessoas|Dificuldade de confiar nas pessoas: de onde vem esse alerta?|dificuldade de confiar nas pessoas
por-que-engulo-emocoes|Por que engulo emoções e depois explodo?|por que engulo emoções
relacionamento-e-autocobranca|Relacionamento e autocobrança: quando amar vira desempenho|relacionamento e autocobrança
me-sinto-responsavel-pelas-emocoes-dos-outros|Por que me sinto responsável pelas emoções dos outros?|me sinto responsável pelas emoções dos outros
carencia-emocional-ou-necessidade-de-vinculo|Carência emocional ou necessidade de vínculo: como diferenciar?|carência emocional
por-que-escolho-pessoas-indisponiveis|Por que escolho pessoas indisponíveis?|por que escolho pessoas indisponíveis
relacao-desgasta-minha-autoestima|Quando a relação desgasta minha autoestima|relação desgasta minha autoestima
limites-com-a-familia-adulta|Limites com a família adulta: como se posicionar sem romper tudo|limites com a família adulta
dificuldade-de-pedir-ajuda|Dificuldade de pedir ajuda: por que isso pesa tanto?|dificuldade de pedir ajuda
'@

Add-TopicsFromText -Cluster "expatriacao" -Text $expatriacao -Target $topics
Add-TopicsFromText -Cluster "ansiedade" -Text $ansiedade -Target $topics
Add-TopicsFromText -Cluster "autocobranca" -Text $autocobranca -Target $topics
Add-TopicsFromText -Cluster "relacionamentos" -Text $relacionamentos -Target $topics

$start = [datetime]::Parse($StartDate)
$end = [datetime]::Parse($EndDate)
$dates = @()
for ($d = $start; $d -le $end; $d = $d.AddDays(1)) {
    if ($d.DayOfWeek -in @([System.DayOfWeek]::Tuesday, [System.DayOfWeek]::Friday)) {
        $dates += $d
    }
}

if ($topics.Count -ne $dates.Count) {
    throw "A quantidade de temas ($($topics.Count)) nao bate com a quantidade de datas ($($dates.Count))."
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$agendaDir = Join-Path $repoRoot "agendamentos"
$catalogPath = Join-Path $agendaDir "catalogo-artigos.json"
$queuePath = Join-Path $agendaDir "fila-publicacao.json"
$calendarPath = Join-Path $repoRoot "CALENDARIO-SEO-ATE-DEZEMBRO-2026.md"

$catalog = [System.Collections.Generic.List[object]]::new()
$queue = [System.Collections.Generic.List[object]]::new()

for ($i = 0; $i -lt $topics.Count; $i++) {
    $topic = $topics[$i]
    $publishDate = $dates[$i].ToString("yyyy-MM-dd")

    $catalog.Add([pscustomobject]@{
        slug = $topic.slug
        title = $topic.title
        keyword = $topic.keyword
        cluster = $topic.cluster
        publishDate = $publishDate
    })

    $queue.Add([pscustomobject]@{
        slug = $topic.slug
        publishDate = $publishDate
        status = "scheduled"
    })
}

$calendarLines = @(
    "# Calendario SEO ate Dezembro de 2026",
    "",
    "- Ritmo: 2 artigos por semana",
    "- Dias de publicacao: terca e sexta",
    "- Clusters: expatriacao, ansiedade, autocobranca e relacionamentos",
    "",
    "| Data | Cluster | Titulo | Keyword |",
    "|---|---|---|---|"
)

foreach ($item in $catalog) {
    $clusterLabel = switch ($item.cluster) {
        "expatriacao" { "Brasileiros no exterior" }
        "ansiedade" { "Ansiedade" }
        "autocobranca" { "Autocobranca" }
        default { "Relacionamentos" }
    }

    $calendarLines += "| $($item.publishDate) | $clusterLabel | $($item.title) | $($item.keyword) |"
}

Write-TextFile -Path $catalogPath -Content ($catalog | ConvertTo-Json -Depth 4)
Write-TextFile -Path $queuePath -Content ($queue | ConvertTo-Json -Depth 4)
Write-TextFile -Path $calendarPath -Content ($calendarLines -join "`r`n")

Write-Host "Catalogo gerado com $($catalog.Count) artigos agendados ate dezembro de 2026."
