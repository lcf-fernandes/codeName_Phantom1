# GDD — Unidade Fantasma

**Game Design Document · Versão 0.2**

Tactical Strategy / Tactical RPG / Base Management

Campanha single-player narrativa com progressão de base e combate por turnos

**Engine:** Godot · **Plataforma inicial:** PC · **Modo:** Single Player

*Documento de conceito e escopo inicial*

---

## Sumário

1. [Visão geral](#1-visão-geral)
2. [Pilares do jogo](#2-pilares-do-jogo)
3. [Tom e identidade](#3-tom-e-identidade)
4. [Premissa narrativa e arco da campanha](#4-premissa-narrativa-e-arco-da-campanha)
5. [Estrutura da campanha](#5-estrutura-da-campanha)
6. [O ataque à base](#6-o-ataque-à-base)
7. [Core loop](#7-core-loop)
8. [A base](#8-a-base)
9. [Recursos e financiamento](#9-recursos-e-financiamento)
10. [Squad e operadores](#10-squad-e-operadores)
11. [Progressão e consequências](#11-progressão-e-consequências)
12. [Combate tático](#12-combate-tático)
13. [Missões](#13-missões)
14. [Inimigos](#14-inimigos)
15. [Inteligência, interrogatórios e conspiração](#15-inteligência-interrogatórios-e-conspiração)
16. [Exposição e segredo](#16-exposição-e-segredo)
17. [Decisões narrativas](#17-decisões-narrativas)
18. [Final e desfechos](#18-final-e-desfechos)
19. [Direção artística](#19-direção-artística)
20. [Escopo do primeiro jogo](#20-escopo-do-primeiro-jogo)
21. [Vertical Slice — primeira meta de desenvolvimento](#21-vertical-slice--primeira-meta-de-desenvolvimento)
22. [Possíveis expansões futuras](#22-possíveis-expansões-futuras)
23. [Resumo da experiência desejada](#23-resumo-da-experiência-desejada)

---

## 1. Visão geral

**Unidade Fantasma** é um jogo de estratégia tática inspirado na estrutura de XCOM, combinado com gerenciamento de uma unidade especial e uma campanha narrativa fechada.

O jogador assume o comando de uma unidade policial de elite criada em caráter emergencial para combater uma escalada generalizada do crime organizado. No início, a ameaça parece ser simplesmente o crescimento descontrolado de diferentes organizações criminosas.

À medida que as operações avançam, porém, surgem indícios de que esse crescimento não é natural. Diferentes grupos aparentemente independentes começam a apresentar conexões, recursos e comportamentos coordenados. A investigação conduz o comandante até uma organização unificadora misteriosa — e, posteriormente, até a descoberta de quem realmente está por trás dela.

> **Premissa central:** o jogador começa acreditando que está combatendo o crime organizado. Aos poucos percebe que está desmontando uma conspiração muito maior.

### 1.1 Formato

- **Gênero:** Tactical Strategy / Tactical RPG / Base Management
- **Modo:** Single Player
- **Estrutura:** campanha linear com progressão, escolhas e desfecho
- **Plataforma inicial:** PC
- **Engine:** Godot
- **Câmera:** isométrica / top-down 3D
- **Duração-alvo:** aproximadamente 8–15 horas na primeira campanha

---

## 2. Pilares do jogo

### 2.1 Combate tático

Missões por turnos nas quais posicionamento, cobertura, habilidades e composição do Squad são fundamentais.

### 2.2 Gestão da unidade

Entre operações, o jogador recruta, treina, equipa e trata operadores, além de construir e melhorar a base.

### 2.3 Investigação

Informações coletadas em operações revelam progressivamente uma rede criminosa maior.

### 2.4 Progressão

A unidade cresce em capacidade enquanto os inimigos também se tornam mais organizados e perigosos.

### 2.5 Consequências

Mortes, ferimentos, decisões narrativas, exposição e desempenho afetam a campanha e o desfecho.

---

## 3. Tom e identidade

A abordagem será séria, tensa e predominantemente fictícia. A intenção não é reproduzir uma operação policial real nem transformar a experiência em uma caricatura simples de "polícia contra bandidos".

A história deve explorar pressão, responsabilidade, lealdade, corrupção, sobrevivência, eficiência, legitimidade e consequências.

Os nomes de organizações criminosas, personagens políticos e estruturas centrais da conspiração serão fictícios, mesmo quando o universo for inspirado no Brasil.

> **Direção temática:** quanto mais o comandante avança, mais difícil fica separar uma guerra contra o crime de uma guerra política.

---

## 4. Premissa narrativa e arco da campanha

### 4.1 O começo — uma missão de avaliação

A campanha não começa na base. O jogador é chamado para participar de uma avaliação secreta. É apresentado como candidato a assumir o comando de uma nova unidade especial e recebe apenas informações mínimas.

Ele é colocado no comando de quatro soldados que não conhece. A missão é apresentada como uma avaliação extremamente importante para determinar se ele será selecionado para comandar a unidade.

O jogador aprende o funcionamento do combate durante essa primeira operação. A missão pode ser vencida ou perdida. O resultado, inclusive baixas, influencia a formação da equipe inicial.

> **Decisão de design:** para o universo do jogo, o protagonista será um Capitão assumindo a função de comandante da unidade. "Comandante" será o cargo/função dentro da unidade, não necessariamente a patente. Isso evita que o termo pareça ser uma patente específica.

Após a missão, os sobreviventes tornam-se o núcleo inicial da unidade. O desempenho de cada um na avaliação determina sua classe inicial ou sua especialização mais adequada.

### 4.2 Ato I — O crime generalizado

A unidade começa combatendo diferentes células e organizações criminosas. As primeiras missões parecem desconectadas.

- intervenções e operações de baixo e médio risco;
- recrutamento de novos operadores;
- construção das primeiras instalações;
- pesquisa e recuperação de equipamentos;
- primeiros interrogatórios e análises de inteligência.

Pouco a pouco surgem coincidências: equipamentos semelhantes, movimentações coordenadas, informações cruzadas e organizações diferentes agindo de maneira estranhamente sincronizada.

### 4.3 Ato II — Existe algo maior

O comandante começa a suspeitar que o crescimento das organizações criminosas não é espontâneo. Investigações revelam uma estrutura intermediária que parece coordenar grupos diferentes. Surge a ideia de uma organização unificadora misteriosa.

Nesse estágio, o inimigo deixa de ser apenas uma coleção de facções e passa a parecer uma rede com objetivos comuns.

É também neste período que entram os seis assassinos de elite, enviados especificamente para localizar e eliminar a unidade do jogador.

### 4.4 Os seis caçadores

Os seis assassinos de elite funcionam como antagonistas recorrentes, inspirados estruturalmente nos Chosen de XCOM 2.

Cada um deve possuir identidade, estilo de combate, personalidade, habilidades e relação própria com o comandante.

- aparecem em momentos específicos da campanha;
- podem interferir em missões ou perseguir a unidade;
- aprendem e reagem ao desempenho do jogador;
- podem provocar ferimentos ou mortes de operadores;
- podem ser derrotados individualmente antes do confronto final.

A ideia é que eles funcionem como uma ameaça persistente, criando tensão fora das missões normais. O jogador deve começar a reconhecer cada caçador e desenvolver uma relação de rivalidade com eles.

### 4.5 Ato III — A organização unificadora

A unidade finalmente identifica a organização que coordena as diferentes facções criminosas.

A investigação revela que o grupo possui recursos, proteção institucional e influência muito superiores ao que o comandante imaginava.

A unidade passa a perceber que parte das dificuldades enfrentadas desde o começo pode ter sido deliberadamente provocada ou facilitada.

### 4.6 A descoberta do verdadeiro responsável

No estágio final da investigação, o comandante descobre que a organização unificadora é controlada secretamente por um senador de Brasília, personagem fictício que utiliza sua influência política para proteger e coordenar a estrutura criminosa.

O senador será o antagonista principal e *final boss* narrativo da campanha. O confronto final não precisa ser apenas uma batalha física: deve representar a conclusão de toda a investigação e das escolhas feitas pelo jogador.

> **Importante:** o senador é um personagem fictício. A campanha deve evitar associá-lo diretamente a uma pessoa política real.

---

## 5. Estrutura da campanha

A campanha será organizada em aproximadamente 3 atos + prólogo + missão final, com cerca de 15–20 missões principais como referência inicial.

| Fase | Função narrativa | Principais sistemas |
| --- | --- | --- |
| Prólogo | Missão de avaliação e formação do Squad inicial | Tutorial, combate, desempenho |
| Ato I | Combate ao crime generalizado | Base, recrutamento, pesquisa, investigação |
| Ato II | Descoberta da rede e surgimento dos 6 caçadores | Inteligência, antagonistas recorrentes, pressão |
| Ato III | Descoberta da organização e do senador | Operações avançadas, decisões, crise |
| Final | Operação decisiva contra a estrutura central | Squad, sobreviventes, consequências, desfecho |

---

## 6. O ataque à base

Em determinado ponto da campanha, a base sofre um ataque direto. Esse evento marca uma mudança importante: até então, o jogador era quem escolhia onde e quando combater. A partir desse momento, o inimigo demonstra que consegue localizar e atingir a própria unidade.

O ataque pode funcionar como uma missão especial de defesa da base.

- operadores presentes na base podem participar da defesa;
- instalações podem ser temporariamente danificadas;
- recursos podem ser perdidos;
- um personagem importante pode ser ferido ou capturado;
- o evento pode ser consequência do nível de exposição ou de uma descoberta feita pelo inimigo.

Após o ataque, a sensação de segurança desaparece. A unidade passa a operar sabendo que está sendo caçada.

---

## 7. Core loop

O ciclo principal do jogo será:

```text
BASE → ANALISAR SITUAÇÃO → ESCOLHER OPERAÇÃO → PREPARAR SQUAD →
MISSÃO TÁTICA → RESULTADO → XP / FERIMENTOS / INTELIGÊNCIA / RECURSOS →
BASE
```

Esse ciclo deve ser divertido mesmo antes de todos os sistemas narrativos estarem implementados.

---

## 8. A base

A base começa pequena e cresce ao longo da campanha.

### Centro de Comando

Seleção de operações, acompanhamento da campanha e administração geral.

### Arsenal

Equipamentos, armas e modificações.

### Centro Médico

Tratamento e recuperação dos operadores.

### Centro de Treinamento

Treinamento, progressão e especializações.

### Laboratório

Pesquisa, análise de materiais e desenvolvimento.

### Inteligência

Processamento de informações, investigação e desbloqueio de operações.

---

## 9. Recursos e financiamento

### Dinheiro

Usado para recrutamento, equipamentos, construção, pesquisa e manutenção.

### Inteligência

Obtida por meio de operações, documentos, interrogatórios e investigação. Usada para descobrir alvos e desbloquear informações.

### Materiais

Obtidos durante operações e utilizados em desenvolvimento e melhorias.

### Financiamento

A unidade começa com orçamento emergencial. Conforme a campanha avança, pode obter recursos de patrocinadores privados discretos. O desempenho influencia a capacidade de atrair e manter financiamento.

---

## 10. Squad e operadores

O jogador poderá possuir vários operadores, mas apenas uma parte participará de cada missão. O tamanho inicial será de 4 operadores, podendo crescer posteriormente.

### Assalto

Combate próximo, avanço e resistência.

### Atirador

Longo alcance, cobertura e alvos prioritários.

### Suporte

Cura, suporte e equipamentos auxiliares.

### Reconhecimento

Mobilidade, descoberta de inimigos e coleta de informações.

### Especialista

Tecnologia, equipamentos e interação com objetivos.

Cada operador terá nome, aparência, classe, nível, atributos, habilidades, equipamento, estado físico, histórico e características de personalidade.

---

## 11. Progressão e consequências

### Experiência

Operadores ganham XP durante operações e desbloqueiam habilidades. O nível-alvo inicial será 1–10.

### Ferimentos

Operadores podem sair ilesos, sofrer ferimentos leves, ferimentos graves ou morrer.

### Morte permanente

A morte será permanente dentro da campanha. O desaparecimento de um operador deve ter impacto emocional e estratégico.

### Moral

Mortes, derrotas, falta de recursos e decisões podem afetar a moral da unidade.

### Relacionamentos

Operadores podem desenvolver amizade, rivalidade, respeito ou desconfiança. No primeiro escopo, isso será usado principalmente para eventos narrativos.

---

## 12. Combate tático

O combate será baseado em turnos e utilizará grid, cobertura, pontos de ação, habilidades e objetivos.

- movimentação;
- ataque;
- habilidades;
- uso de equipamentos;
- cobertura parcial e completa;
- turno do jogador e turno inimigo.

O posicionamento deve ser tão importante quanto o poder do equipamento.

---

## 13. Missões

### Intervenção

Entrar em determinada área e cumprir um objetivo.

### Resgate

Localizar e retirar uma pessoa.

### Captura

Localizar um alvo prioritário.

### Recuperação

Recuperar documentos, materiais ou equipamentos.

### Investigação

Obter informações relevantes.

### Defesa da base

Responder a um ataque direto contra a unidade.

### Operação de alto valor

Missões especiais ligadas à história.

### Confrontos com caçadores

Missões ou encontros especiais envolvendo os seis assassinos de elite.

As missões terão objetivo principal, objetivos secundários e uma condição de extração/evacuação.

---

## 14. Inimigos

### Combatente básico

Unidade padrão.

### Combatente pesado

Maior resistência e capacidade de manter posições.

### Atirador

Especialista em longo alcance.

### Especialista

Equipamentos e funções especiais.

### Líder

Pode melhorar ou coordenar outros inimigos.

### Caçadores de elite

Seis antagonistas únicos e recorrentes, cada um com identidade e comportamento próprios.

---

## 15. Inteligência, interrogatórios e conspiração

Informações coletadas em campo serão levadas à base e transformadas em pistas.

```text
DOCUMENTO / EVIDÊNCIA → PESSOA → ORGANIZAÇÃO → LOCAL → NOVA PISTA →
NOVA OPERAÇÃO
```

Interrogatórios de alvos importantes podem fornecer informações, mas serão representados principalmente por decisões e eventos narrativos no primeiro escopo.

O sistema de investigação deve servir tanto ao gameplay quanto à progressão da história, fazendo o jogador sentir que está montando um quebra-cabeça.

---

## 16. Exposição e segredo

A unidade existe em segredo. Um indicador de exposição representa o quanto sua existência e suas ações estão se tornando conhecidas.

Exposição elevada pode provocar:

- maior pressão política;
- mais atenção dos inimigos;
- eventos negativos;
- dificuldade para manter patrocinadores;
- maior risco de ataques contra a base.

---

## 17. Decisões narrativas

Entre operações, o jogador encontrará eventos que exigem decisões.

- aceitar ou recusar apoio de determinado patrocinador;
- priorizar uma investigação ou outra;
- proteger um operador ou assumir um risco operacional;
- decidir como lidar com informações sensíveis;
- escolher entre eficiência imediata e menor exposição.

Essas decisões contribuem para os finais da campanha.

---

## 18. Final e desfechos

A campanha culmina em uma operação contra a estrutura central da organização unificadora. O senador que está por trás da rede é o principal antagonista da conclusão.

O resultado final dependerá do desempenho do jogador, dos operadores sobreviventes, da exposição, das decisões narrativas e do estado da unidade.

### Final 1 — Vitória institucional

A unidade cumpre sua missão mantendo relativa legitimidade e consegue encerrar a ameaça.

### Final 2 — Vitória a qualquer custo

A ameaça é derrotada, mas as decisões tomadas deixam consequências graves para a unidade e seus integrantes.

### Final 3 — Queda

A unidade perde o controle da situação, é exposta ou desmantelada antes de conseguir concluir sua missão.

---

## 19. Direção artística

3D estilizado com leitura clara e realismo moderado. Não será objetivo do primeiro projeto alcançar fotorealismo.

Os ambientes serão fictícios, mas inspirados em características urbanas brasileiras. Isso permite maior liberdade artística e reduz a necessidade de reproduzir locais reais.

---

## 20. Escopo do primeiro jogo

O foco é uma campanha single-player fechada. Multiplayer, coop e PvP ficam explicitamente fora do escopo inicial.

- 15–20 missões principais como referência;
- 3 atos + prólogo + missão final;
- uma organização criminosa principal e 2–3 grupos secundários;
- 6 caçadores de elite recorrentes;
- 5 classes iniciais;
- base com instalações essenciais;
- pesquisa e equipamentos;
- ferimentos e morte permanente;
- investigação e interrogatórios simplificados;
- ataque à base;
- 3 finais principais.

### 20.1 Fora do escopo inicial

- multiplayer;
- coop online;
- PvP 4v4;
- mapa estratégico de uma cidade inteira;
- geração procedural complexa;
- veículos como sistema completo;
- dezenas de classes e armas;
- simulação policial realista;
- sistema profundo de relacionamentos;
- mundo aberto.

---

## 21. Vertical Slice — primeira meta de desenvolvimento

Antes de desenvolver a campanha inteira, o projeto deve provar o seguinte ciclo:

```text
BASE → ESCOLHER 4 OPERADORES → EQUIPAR → INICIAR MISSÃO → MAPA TÁTICO →
COMBATE → OBJETIVO → EVACUAÇÃO → RESULTADO → XP / FERIMENTOS /
RECOMPENSAS → BASE
```

O vertical slice ideal será uma versão jogável da missão de avaliação inicial. Ele deverá apresentar os quatro soldados desconhecidos, permitir que o jogador aprenda o combate e retornar à base com os sobreviventes e seus resultados.

A partir desse ponto, os sistemas de base, progressão e campanha podem ser construídos incrementalmente.

---

## 22. Possíveis expansões futuras

Somente depois de uma campanha single-player completa e estável poderão ser avaliados:

- campanhas adicionais;
- novas facções e antagonistas;
- coop para 2–4 jogadores;
- PvP 4v4;
- novos mapas e operações;
- modo procedural;
- novas unidades e especializações.

---

## 23. Resumo da experiência desejada

> O jogador começa comandando quatro desconhecidos em uma missão de avaliação. Termina a campanha comandando uma unidade formada por pessoas que conheceu, treinou e perdeu ao longo de uma guerra clandestina — depois de descobrir que o crime que combatia fazia parte de uma conspiração política muito maior.

A identidade do jogo nasce da combinação de três experiências: comandar pessoas, administrar uma unidade e descobrir uma conspiração enquanto o inimigo aprende a caçar o próprio jogador.
