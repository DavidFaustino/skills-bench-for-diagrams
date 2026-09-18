# skills-bench-for-diagrams

Cinco ferramentas de geração de diagramas técnicos de arquitetura, todas com o mesmo desenho
para fazer, comparadas com artefatos que você pode inspecionar e um comando que regera todos.

Junto vão seis skills: uma por ferramenta, para replicar cada teste, e uma otimizada
construída sobre a vencedora.

```bash
git clone https://github.com/DavidFaustino/skills-bench-for-diagrams.git
```

[Read in English](README.md) — o conteúdo do repositório está em inglês; este é o único
documento em português.

## Por que existe

Existem dezenas de skills que desenham diagramas. Não existe uma comparação honesta e
reproduzível das ferramentas por baixo delas — daquelas em que você vê a entrada, a saída e o
que quebrou no caminho.

Este repositório é essa comparação. Cada resultado foi produzido pela ferramenta a que é
atribuído, sobre o mesmo conteúdo, e as entradas estão versionadas ao lado das saídas.

## O desenho que todas fizeram

Um sistema fictício de inventário de versões: uma conta AWS central com VPC privada em duas
zonas de disponibilidade, portal e worker de coleta em subnets de aplicação, banco, evidências
e cofre de segredos em subnets de dados, saída controlada e, fora da conta, a rede de cada
ambiente — Staging, Homologation e Production — com ArgoCD e clusters Kubernetes.

**É um caso de teste, não uma arquitetura de referência.** Foi escrito para exercitar o que
diferencia as cinco: containers aninhados, ícones de fornecedor, rótulo em aresta e elementos
deliberadamente indefinidos. O nó "route to confirm" está ali de propósito, para mostrar como
marcar o que ainda não foi decidido.

## Resultado

| Ferramenta | Quem decide o layout | Saída | Editável | Funciona offline | Licença |
| --- | --- | --- | --- | --- | --- |
| [`diagrams`](https://github.com/mingrammer/diagrams) + Graphviz | a ferramenta | PNG, SVG | não | sim | MIT |
| [MCP infra-diagram](https://github.com/andrewmoshu/diagram-mcp-server) | a ferramenta | PNG, `.drawio` | sim | sim | Apache-2.0 |
| [MCP aws-samples](https://github.com/aws-samples/sample-architecture-diagram-mcp-server) | a ferramenta (ELK) | HTML interativo, `.drawio` | sim | sim | MIT-0 |
| [Eraser CLI](https://github.com/eraserlabs/eraser-diagrams) | você, com roteamento automático | PNG, HTML | não | **não** — busca ícones | MIT |
| **[drawio-skill](https://github.com/Agents365-ai/drawio-skill)** | **você, com validação** | **`.drawio`, PNG, SVG, HTML, PPTX** | **sim** | **sim** | **MIT** |

Medido sobre os artefatos versionados:

| Ferramenta | Imagem | Proporção | Arquivo |
| --- | --- | --- | --- |
| `diagrams` + Graphviz | 1682×1607 | 1,05 | 182 KB |
| MCP infra-diagram | 1682×1607 | 1,05 — mesma entrada do teste acima | 182 KB PNG, 292 KB `.drawio` |
| MCP aws-samples | interativo | reflui | 2,1 MB de HTML autocontido |
| Eraser CLI | 892×1032 | 0,86 | 88 KB, renderizado em 1,2 s |
| drawio-skill | 1505×1415 | 1,06 | 138 KB PNG, **11 KB** `.drawio` |

Duas coisas que essa tabela esconde.

**As proporções são as que chegamos, não as que saíram de primeira.** O `TB` padrão do
Graphviz deu 1073×1343, retrato que não cabe em 16:9 sem cortar. Virar para `LR` corrigiu a
proporção e deixou cerca de um terço da tela vazio. É o custo do layout automático: você ajusta
o botão que tem, não o layout que quer.

**A última coluna é a história real.** O `.drawio` escrito à mão tem 11 KB porque referencia
as formas pelo nome; o convertido a partir do Graphviz tem 292 KB porque embute cada ícone em
base64 — maior que o próprio PNG, e mais difícil de revisar num pull request.

Uma rodada anterior usou os mesmos desenhos com rótulos em português e acentuação. As cinco
lidam bem com UTF-8; os rótulos foram traduzidos para o repositório, não porque algo quebrou.

## Reproduzindo

Tudo que está em `benchmark-diagrams/results/` é regerado por um comando, a partir das
entradas versionadas ao lado de cada resultado.

No container, que é o único caminho que não exige nada instalado:

```bash
docker build -t skills-bench-for-diagrams . && docker run --rm -t \
  -v "$PWD/benchmark-diagrams/results:/app/benchmark-diagrams/results" skills-bench-for-diagrams
```

Direto na máquina:

```bash
./benchmark-diagrams/install.sh && ./benchmark-diagrams/bench.sh
```

O `install.sh` clona cada ferramenta no commit em que foi testada e fixa as versões de pacote.
O `bench.sh` roda os cinco, cronometra cada um e termina imprimindo as dimensões medidas de
cada artefato. Teste sem dependência é pulado com o motivo, em vez de derrubar a execução.

### Diferenças de plataforma

Os dois caminhos passam, mas não geram arquivos idênticos.

- **No Linux, a exportação do draw.io exige `--disable-gpu --disable-dev-shm-usage`.** Sem
  eles, ela morre com `Empty export data` assim que você passa `--scale` ou `--width`, o que
  parece bug de escala e não é: é rasterização por GPU. Com as flags, a mesma exportação em
  escala funciona nas duas plataformas. O `bench.sh` passa as flags e mantém a queda para a
  escala padrão caso alguma exportação falhe.
- **Electron headless trava em vez de falhar.** Num runner do GitHub Actions a exportação
  nunca retornou e consumiu o orçamento inteiro do job. Agora toda tentativa tem limite de
  tempo por `timeout`, e travamento é reportado como pulado, com o motivo — o `.drawio` é
  validado de qualquer forma.
- **As versões do Graphviz diferem**, então os dois primeiros diagramas saem um pouco maiores
  no container do que na máquina.
- **O Electron se recusa a rodar como root sem `--no-sandbox`**, que é o caso do container. O
  `bench.sh` detecta. Sem tela, ainda precisa de `xvfb-run` e do pacote `xauth`.

Como o container escreve pelo volume montado, rodá-lo substitui os artefatos versionados pelos
dele. Monte o volume quando quiser regerar; deixe de fora quando quiser só conferir que roda.

## Por que a vencedora ganhou

As três primeiras decidem o layout por você. Com containers aninhados — conta, VPC, subnets —
o layout automático erra a proporção de forma consistente, e não há parâmetro que resolva. Ou
você aceita, ou redesenha.

O Eraser inverte o acordo: você posiciona, ele roteia as arestas em volta dos obstáculos,
resolve ícones e mede o texto. O render leva cerca de um segundo, então iterar é barato.

A `drawio-skill` faz o mesmo acordo e acrescenta três coisas que nenhuma outra tem:

- **busca de forma em vez de chute** — um índice pesquisável com 10.446 formas oficiais, então
  `mxgraph.aws4.resourceIcon;resIcon=secrets_manager` é consultado, não inventado;
- **validação estrutural que devolve número** — sobreposições, cruzamentos e arestas
  atravessando caixas, contados. O diagrama versionado marca 0;
- **conserto automático** — quando dois rótulos de aresta colidem, um script redistribui as
  pontas pelos lados certos de cada forma.

E a saída é `.drawio`: seu time edita depois sem pedir nada a um agente.

## Estrutura

| Caminho | O que é |
| --- | --- |
| `benchmark-diagrams/` | A comparação: `install.sh`, `bench.sh` e `results/`, com cada entrada ao lado do resultado que produziu |
| `skills-architecture-diagrams/` | Seis skills: uma por ferramenta, a otimizada sobre a vencedora e uma mínima para validar um runtime novo |
| `skills-architecture-diagrams/architecture-drawio/` | A skill otimizada, autocontida — scripts, índice de formas, referência de estilos e um exemplo completo |
| `skills-architecture-diagrams/RUN-IN-YOUR-OWN-AGENT.md` | Para quem vai portar estas skills para outro runtime: os três comportamentos, um loader que roda, o que esperar de cada porte de modelo e o que conferir na licença do modelo |
| `NOTICE.md`, `licenses/` | Procedência de tudo que não foi escrito aqui |

## Rodando as skills no seu próprio agente

Skill é um diretório com um `SKILL.md` — formato aberto, não recurso de fornecedor. Um runtime
precisa de três comportamentos: anunciar nome e descrição de cada skill no prompt de sistema,
cerca de 440 tokens para as seis daqui; carregar o `SKILL.md` inteiro quando a tarefa casar; e
expor leitura de arquivo mais um shell. Nada além disso.

O `skills-architecture-diagrams/RUN-IN-YOUR-OWN-AGENT.md` tem os detalhes e um loader de
referência de sessenta linhas que você roda, além do que esperar de modelos de portes
diferentes e do que conferir na licença de um modelo antes de colocá-lo em produção.

## Quem mantém

Feito e mantido por David Faustino, engenheiro de computação com atuação em segurança de
aplicações e cloud, inteligência artificial e arquitetura de software.

Meu trabalho conecta engenharia de segurança e governança: traduzir riscos e requisitos em
decisões de arquitetura, controles automatizados e evidências que apoiem as decisões dos
times. Nessa atuação, combino experiência em desenvolvimento e plataformas com a construção e
avaliação de soluções de IA.

Atuo em quatro frentes complementares:

- IA aplicada à segurança — integração de modelos aos testes de segurança e à análise de
  achados de código, dependências, aplicações e runtime, apoiando investigação, priorização e
  correção com validação dos resultados e supervisão humana.
- Arquitetura e governança de segurança — desenvolvimento seguro (SSDLC), gestão de
  vulnerabilidades e controles em aplicações e cloud, conectando decisões técnicas,
  priorização por risco e evidências para conformidade e auditoria.
- Engenharia e avaliação de IA — infraestrutura e orquestração de agentes, skills, servidores
  MCP e avaliação de modelos de pesos abertos, sobre uma base anterior de machine learning.
  Qualidade, confiabilidade, custo e limites de uso orientam as decisões de adoção.
- Engenharia de capacidades de segurança e DevSecOps — desenvolvimento de operators,
  bibliotecas, integrações e automações para aplicações e ambientes cloud, incluindo gestão do
  ciclo de vida de certificados. Integração de análise, testes e proteção — SAST, SCA, DAST,
  IAST, RASP e sensores de runtime — do desenvolvimento à operação. Uso de CI/CD, GitOps,
  Kubernetes e AWS para transformar requisitos de segurança em capacidades reutilizáveis por
  diferentes times.

Este projeto faz parte dessa prática: compartilhar implementações, métodos e resultados para
que decisões técnicas possam ser examinadas, reproduzidas e aprimoradas pela comunidade.

Dúvidas, correções e resultados de outras ferramentas são bem-vindos. Abra uma issue neste
repositório ou entre em contato pelo e-mail
[davidfaustinoeng@gmail.com](mailto:davidfaustinoeng@gmail.com).

## Licenças

Este repositório é MIT. As ferramentas comparadas **não** estão aqui: cada uma é clonada da
origem, no commit testado. A única exceção é a skill otimizada, que leva três scripts MIT e um
índice de formas Apache 2.0 para funcionar sem instalar a skill original. Toda a procedência,
com a modificação aplicada, está em `NOTICE.md`.

Nenhum pacote de ícones é redistribuído. Os termos da AWS permitem usar os ícones em diagramas
de arquitetura — que é o que os PNG versionados fazem — mas não redistribuir o acervo.

Uma das ferramentas citadas, uma skill popular de Excalidraw, não declara licença. Sem licença
declarada não pode ser redistribuída, então aparece como referência, sem cópia.
