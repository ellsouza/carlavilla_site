# Automacao de Publicacao de Conteudo

## O que esta configurado
- Workflow diario no GitHub Actions em `.github/workflows/publish-scheduled-content.yml`
- Fila de publicacao em `agendamentos/fila-publicacao.json`
- Catalogo de artigos em `agendamentos/catalogo-artigos.json`
- Insercao automatica de novos cards na home, no arquivo de textos e no sitemap

## Como funciona
1. O workflow roda todo dia.
2. O script compara a data atual com `publishDate`.
3. Quando chega a data, ele gera o HTML do artigo a partir do catalogo e publica em `textos/`.
4. Em seguida, atualiza os cards da home, o arquivo em `textos/` e a URL no sitemap.
5. A fila marca o item como `published` para nao repetir a publicacao.

## O que esta automatizado
- Publicar artigos do catalogo na data certa
- Atualizar a vitrine da home
- Atualizar o arquivo de textos
- Atualizar o sitemap para indexacao

## O que nao esta automatizado
- Definir novos temas fora do catalogo atual
- Revisar periodicamente o tom, o SEO fino e o calendario

## Como adicionar os proximos artigos
1. Adicione o novo tema no script `scripts/gerar-calendario-ate-dezembro.ps1`.
2. Rode o script para regenerar `catalogo-artigos.json`, `fila-publicacao.json` e o calendario em Markdown.
3. Faça commit e envie para o GitHub.

## Uso recomendado
- Manter sempre pelo menos 4 a 6 artigos prontos na fila
- Publicar 2 artigos por semana no inicio
- A cada 15 dias, repor a fila com novos rascunhos do cluster principal
