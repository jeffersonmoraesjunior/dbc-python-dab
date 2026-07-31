# Prompt do build — Databricks + Claude Code

Prompt usado ao vivo para construir o pipeline medalhão (bronze → silver → gold) e o dashboard AI/BI.

## Prompt completo

```text
Vamos construir um pipeline de dados completo em arquitetura medalhão (bronze → silver →
gold) e, no fim, um dashboard AI/BI. A fonte é o `samples.bakehouse`, que é somente
leitura — nunca escreva nada nele.

O contexto de negócio: a Bakehouse é uma rede com 48 franquias em 9 países. O que
interessa acompanhar é receita, número de pedidos, ticket médio, mix de produtos,
desempenho por franquia e por país, e a satisfação dos clientes.

Antes de começar, uma coisa que vale mais que todo o resto: o nome do catálogo não pode
aparecer escrito em lugar nenhum. Este projeto roda em dev e em produção, e a única coisa
que muda entre os dois é o catálogo — quem decide isso é o bundle, não o arquivo. Então
nos YAMLs o catálogo vem de `${var.catalog}` e no SQL vem de `${medallion_catalog}`. Se
escapar um `bakehouse_dev` hardcoded em algum arquivo, o deploy de produção vai ficar
verde, o pipeline vai rodar verde, e as tabelas vão parar no catálogo de desenvolvimento
sem um único erro para te avisar. Já aconteceu comigo. Também não use `USE CATALOG`.

Sobre a estrutura: quero um schema por camada, com os nomes exatos `bronze`, `silver` e
`gold`, declarados como recursos `schemas:` do bundle. Como o schema já é a camada, o
nome da tabela não repete isso: é `bronze.customers` e `silver.customers`, nunca
`bronze_customers`. O catálogo já existe, não precisa criar.

Na bronze, ingestão bruta de `sales_transactions`, `sales_franchises`, `sales_customers`,
`sales_suppliers` e `media_customer_reviews`, virando `transactions`, `franchises`,
`customers`, `suppliers` e `reviews`, com colunas de metadados de ingestão.

Na silver, os dados limpos e conformados: tipos corretos, colunas de data derivadas
(dia, mês), padronização de país (a fonte tem `US` nas franquias e `USA` nos clientes),
transações enriquecidas com franquia e cliente, e expectations como regras de qualidade.
As tabelas são `customers`, `franchises`, `transactions` e `reviews_sentiment` — esta
última usando `ai_analyze_sentiment` sobre o texto dos reviews.

Na gold, os marts prontos para BI: `daily_sales_by_franchise`, `sales_by_product`,
`franchise_performance` (com cidade, país, latitude e longitude), `sales_by_country`,
`top_customers` e `sentiment_by_franchise`.

Organize o SQL em `src/pipelines/bakehouse/transformations/{bronze,silver,gold}/`, um
arquivo por tabela, cada um na pasta da sua camada. Use um único Lakeflow Declarative
Pipeline serverless para as três camadas, com um `configuration:` declarando
`medallion_catalog`, `bronze_schema`, `silver_schema` e `gold_schema` — o catálogo ligado
a `${var.catalog}` e os schemas a `${resources.schemas.<camada>.name}`, para que o recurso
do bundle seja a fonte única de verdade dos nomes.

Depois disso, monte o dashboard AI/BI (Lakeview) sobre as tabelas gold: KPIs de receita
total, pedidos, ticket médio e franquias ativas; série temporal de receita diária; receita
por produto; ranking de franquias; um mapa geográfico das franquias por receita; mix de
meio de pagamento; e uma visão do sentimento dos reviews. Teste todas as queries antes de
publicar — quero ver os números batendo, não só o widget renderizando.

Por fim, adicione um Job que orquestra o pipeline, faça o deploy no target `dev` e rode o
pipeline para materializar as tabelas. No fim, valide os dados com contagens por camada.

Vá explicando cada passo enquanto trabalha.
```

## Versão em 3 passos

Mesma coisa, quebrada em checkpoints — foi assim que rodou na live.

1. `Explore samples.bakehouse e me proponha o desenho medalhão com um schema por camada (bakehouse_dev.bronze/silver/gold, tabelas sem prefixo) + o dashboard. Só o plano, ainda não construa.`
2. `Implemente o Lakeflow Declarative Pipeline serverless (bronze→silver→gold) como recurso de Asset Bundle, com os 3 schemas como recursos schemas:. NUNCA escreva bakehouse_dev em arquivo nenhum — catálogo vem de ${var.catalog} nos YAMLs e ${medallion_catalog} no SQL. Deploy no dev e rode.`
3. `Crie o dashboard AI/BI sobre as tabelas gold (KPIs, receita diária, ranking, mapa, sentimento). Teste as queries e publique como recurso do bundle.`
