# Automacao de Publicacao de Conteudo

## O que esta configurado
- Workflow diario no GitHub Actions em `.github/workflows/publish-scheduled-content.yml`
- Fila de publicacao em `agendamentos/fila-publicacao.json`
- Rascunhos prontos para entrar no ar em `agendamentos/rascunhos/`
- Insercao automatica de novos cards na home e de novas URLs no sitemap

## Como funciona
1. O workflow roda todo dia.
2. O script compara a data atual com `publishDate`.
3. Quando chega a data, ele copia o HTML do rascunho para `textos/`.
4. Em seguida, adiciona o card do artigo na home e inclui a URL no sitemap.
5. A fila marca o item como `published` para nao repetir a publicacao.

## O que esta automatizado
- Publicar artigos ja escritos na data certa
- Atualizar a vitrine da home
- Atualizar o sitemap para indexacao

## O que nao esta automatizado
- Escrever artigos novos com qualidade clinica
- Revisar tom de voz, SEO fino e links internos de cada texto

## Como adicionar os proximos artigos
1. Crie um novo HTML em `agendamentos/rascunhos/` seguindo o padrao dos artigos ativos.
2. Adicione um novo item em `agendamentos/fila-publicacao.json`.
3. Defina `publishDate` no formato `YYYY-MM-DD`.
4. Faça commit e envie para o GitHub.

## Uso recomendado
- Manter sempre pelo menos 4 a 6 artigos prontos na fila
- Publicar 2 artigos por semana no inicio
- A cada 15 dias, repor a fila com novos rascunhos do cluster principal
