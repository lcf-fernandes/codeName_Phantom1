# Unidade Fantasma

## Anotações de Pré-Desenvolvimento

**Status:** Documento de referência
**Relação com o GDD:** Complementar — **não altera o GDD atual**.

Este documento reúne decisões, dúvidas e pontos a serem desenvolvidos antes ou durante a pré-produção do jogo.

---

# 1. Classe inicial no prólogo

Durante a primeira missão, os quatro soldados precisam possuir habilidades/equipamentos que permitam jogar normalmente, mesmo antes de suas classes definitivas serem estabelecidas.

Após a primeira missão, decidir entre três possibilidades:

* **Classe aleatória:** cada sobrevivente recebe uma classe aleatoriamente.
* **Classe baseada no desempenho:** o sistema analisa como o soldado atuou na missão e define sua especialização.
* **Sistema de recomendação:** o jogo analisa o desempenho e apresenta uma classe recomendada ao Capitão. O jogador pode:

  * aceitar a recomendação;
  * escolher outra classe;
  * ou optar por uma atribuição aleatória.

**Decisão:** deixar em aberto até a fase de desenvolvimento do sistema de progressão.

---

# 2. Os seis Caçadores

Os seis Caçadores continuam como parte importante da proposta, mas sua implementação deve ser avaliada posteriormente devido ao risco de escopo.

## Pontos a decidir

* Criar um **framework comum** para os Caçadores.
* Evitar que cada Caçador exija um sistema completamente diferente.
* Usar características modulares:

  * habilidades;
  * armas;
  * comportamento;
  * traços;
  * fraquezas;
  * mobilidade;
  * reações às estratégias do jogador.

Também será necessário definir o que significa, mecanicamente, que os Caçadores **“aprendem e reagem”**.

Uma possibilidade simples é fazer com que eles desenvolvam resistência ou adaptação a determinadas estratégias utilizadas repetidamente pelo jogador.

## Justificativa narrativa

Precisamos responder:

> **Por que existem exatamente seis Caçadores?**

O número deve ter algum significado dentro da conspiração.

### Possível inspiração

Explorar a possibilidade de existir algum relacionamento familiar entre os Caçadores.

**Referência de inspiração:** os irmãos gêmeos de *Breaking Bad*.

Isso não significa necessariamente copiar a dinâmica, mas explorar como relações familiares poderiam afetar:

* personalidade;
* diálogos;
* história;
* rivalidade;
* morte de um Caçador;
* reação dos demais.

**Decisão:** desenvolver posteriormente.

---

# 3. Pressão de tempo

A camada estratégica deve impedir que o jogador simplesmente espere indefinidamente para:

* curar soldados;
* pesquisar tecnologias;
* treinar;
* preparar equipamentos;
* acumular recursos.

A referência principal será:

> **XCOM 2**

O objetivo é criar a sensação de que o jogador sempre precisa decidir **o que fazer agora e o que está disposto a deixar para depois**.

## Possíveis elementos

* Operações que expiram.
* Pesquisas que levam tempo.
* Ferimentos que exigem dias para recuperação.
* Eventos que avançam com o tempo.
* Mudanças no cenário estratégico conforme os dias passam.

**Decisão:** detalhar posteriormente.

---

# 4. Finais e derrota

Ainda será necessário definir:

* quais variáveis determinam os finais;
* quais valores/thresholds levam a cada final;
* como desempenho, exposição, sobreviventes e decisões afetam o resultado;
* quais derrotas são permanentes;
* quais derrotas apenas geram consequências.

## Possível separação de variáveis

Avaliar futuramente a existência de:

### Exposição

Quanto os inimigos e outras partes do mundo sabem sobre a Unidade Fantasma.

### Legitimidade

Quanto apoio institucional, político ou público a unidade possui.

Essas duas variáveis não precisam necessariamente evoluir juntas.

---

## Regras de Game Over

### Primeira missão

Se os quatro soldados morrerem:

> **Game Over**

A primeira missão funciona como uma exceção porque representa o estabelecimento do núcleo inicial da equipe.

### Demais missões

Perder soldados **não encerra a campanha**.

O jogador continua com:

* sobreviventes;
* equipamentos restantes;
* recursos disponíveis;
* consequências da derrota.

Isso pode gerar situações em que o jogador precisa continuar uma campanha muito mais difícil depois de sofrer perdas importantes.

---

# 5. Sistema de combate

Criar futuramente um documento separado:

> **Combat Design Document — Sistema de Combate**

Antes da implementação completa, precisamos decidir:

### Sistema de ações

* Pontos de ação?
* Movimento + ação?
* Quantas ações por turno?
* Atacar encerra o turno?
* Habilidades consomem ações?

### Precisão

* Chance de acerto percentual, como XCOM?
* Sistema determinístico?
* Críticos?
* Modificadores de distância?
* Modificadores de cobertura?

### Campo de batalha

* Grid quadrado?
* Haverá altura?
* Haverá diferença entre níveis?
* Haverá névoa de guerra?
* Como funcionará a visão?

### Cobertura

* Cobertura parcial e total?
* Cobertura destrutível?
* Flanqueamento?
* Como a cobertura afeta a precisão?

### Vigilância

* Haverá **Overwatch**?
* Como será ativado?
* Quando será disparado?
* Quais armas poderão utilizá-lo?

### IA inimiga

* Como escolhe alvos?
* Como avalia cobertura?
* Quando avança?
* Quando recua?
* Como reage ao jogador?
* Como funciona a IA dos inimigos comuns?
* Como funciona a IA dos Caçadores?

**Tarefa futura:** criar o documento completo do sistema de combate antes de avançar muito na implementação.

---

# 6. Pergunta central: quem criou a Unidade Fantasma e por quê?

Esta é atualmente uma das perguntas mais importantes de todo o projeto.

> **Quem criou a Unidade Fantasma e por quê?**

Ela deverá servir como **ponto de partida para a construção da narrativa**.

A história não deve ser construída simplesmente começando pelo vilão final.

Primeiro devemos descobrir:

1. Quem criou a Unidade Fantasma?
2. Qual era a verdadeira intenção?
3. Por que o Capitão foi escolhido?
4. Por que aqueles quatro soldados foram selecionados para a avaliação?
5. Por que a unidade recebeu tanta liberdade?
6. Por que o governo posteriormente retirou o apoio?
7. Quem se beneficia com a existência da Unidade Fantasma?
8. O que aconteceria se a unidade cumprisse sua missão?
9. O que aconteceria se ela fracassasse?

## Hipótese atual

Uma possibilidade é que a Unidade Fantasma tenha sido criada deliberadamente como um:

> **bode expiatório**

A unidade poderia receber autonomia, recursos e uma missão aparentemente legítima, mas ter sido criada para posteriormente ser responsabilizada por determinados acontecimentos.

Outra possibilidade é que:

> **o criador da Unidade Fantasma esteja diretamente ligado ao vilão final.**

Essa hipótese ainda **não está decidida**.

A resposta deverá ser definida antes da estrutura final da campanha, pois poderá determinar:

* o início da história;
* a avaliação inicial;
* a formação da unidade;
* os patrocinadores;
* a conspiração;
* os Caçadores;
* a retirada do apoio governamental;
* o ataque à base;
* o vilão final;
* os finais.

---

# 7. Mapas e reutilização de conteúdo

O desenvolvimento solo exige cuidado especial com a quantidade de mapas.

Em vez de criar um mapa completamente novo para cada missão, utilizar:

> **Mapas modulares + variações de missão**

## Elementos que podem ser reutilizados

Um mesmo mapa-base pode receber diferentes:

* objetivos;
* posições inimigas;
* composição de inimigos;
* horário;
* condições ambientais;
* NPCs;
* entradas;
* saídas;
* pontos de extração;
* locais de objetivo;
* eventos;
* condições especiais.

## Exemplo

Um mapa de comunidade pode ser utilizado para:

* resgate;
* captura;
* eliminação;
* investigação;
* recuperação de evidências;
* perseguição;
* confronto com um Caçador.

O mapa permanece reconhecível, mas a experiência muda de acordo com os elementos combinados.

## Referência

Utilizar o modelo de missões de **XCOM 2** como inspiração para aumentar a variedade sem criar proporcionalmente mais conteúdo.

**Objetivo de produção:**

> Criar uma quantidade relativamente pequena de mapas de alta qualidade e extrair deles muitas situações diferentes.

---

# 8. Ataque à base

O ataque à base será tratado como:

> **Evento narrativo scriptado.**

Ele ocorrerá:

* sempre;
* no mesmo momento da história;
* como um marco importante da campanha.

Neste momento, **não utilizar Exposição como gatilho**.

A causa narrativa será:

> **o resultado do trabalho de investigação do inimigo.**

O inimigo eventualmente consegue descobrir a localização da Unidade Fantasma e organizar uma invasão.

## Ainda definir

* composição dos invasores;
* duração;
* objetivos;
* áreas atacadas;
* possíveis danos à base;
* soldados presentes;
* possíveis baixas;
* consequências posteriores;
* relação com os Caçadores.

---

# 9. Capitão

O Capitão **não será uma unidade jogável normalmente**.

Ele permanecerá principalmente como:

* comandante;
* personagem central;
* responsável pelas decisões estratégicas.

## Exceção possível

Durante a invasão da base, o Capitão pode estar presente no mapa como um **objetivo de proteção**.

Se o inimigo alcançar o Capitão:

> **Missão perdida.**

A derrota nessa missão será:

> **Game Over**

Isso transforma o ataque à base em uma situação diferente das missões normais, na qual não basta simplesmente sobreviver ou completar um objetivo operacional.

---

# 10. Moral e personalidade

O sistema deve permanecer simples.

Não criar uma simulação psicológica excessivamente complexa.

Os traços de personalidade e moral devem produzir **efeitos mecânicos concretos**.

Exemplos futuros:

* bônus ou penalidade em determinadas situações;
* reação diferente à morte de companheiros;
* resistência ou vulnerabilidade ao estresse;
* comportamento modificado sob determinadas condições.

A princípio:

> **Dois ou três efeitos mecânicos relevantes são melhores do que dezenas de sistemas pequenos.**

---

# 11. Dificuldade

Não haverá um modo que simplesmente desative a morte permanente.

A morte permanente é parte fundamental da proposta de:

> **risco e recompensa.**

## Modo História

Voltado para jogadores que querem experimentar a campanha e a narrativa com menor dificuldade.

A principal diferença será favorecer o jogador nas probabilidades.

Exemplo:

* maiores chances de acerto;
* melhores probabilidades em determinadas situações;
* menor punição estatística.

A morte permanente continua existindo.

## Modo Normal

É a experiência principal planejada para o jogo.

Mantém:

* risco;
* morte permanente;
* consequências;
* decisões difíceis;
* necessidade de gerenciamento cuidadoso.

---

# 12. Riscos, roadmap e glossário

Criar posteriormente uma seção específica de **Riscos de Produção**.

Possíveis categorias:

* quantidade de mapas;
* quantidade de inimigos;
* seis Caçadores;
* animações;
* IA;
* sistemas de combate;
* quantidade de conteúdo;
* desenvolvimento solo;
* dependência de assets;
* escopo da campanha.

Também criar futuramente:

### Roadmap

Organizar o desenvolvimento em etapas, por exemplo:

1. Protótipo técnico
2. Protótipo de combate
3. Vertical Slice
4. Pré-produção
5. Produção
6. Alpha
7. Beta
8. Polimento
9. Lançamento

Os detalhes serão definidos posteriormente.

### Glossário

Criar uma lista dos termos importantes:

* Unidade Fantasma
* Capitão
* Caçadores
* organizações criminosas;
* recursos;
* exposição;
* legitimidade;
* operações;
* instalações;
* classes;
* etc.

---

# Diretriz narrativa principal

A pergunta:

> **“Quem criou a Unidade Fantasma e por quê?”**

deve permanecer como uma das perguntas centrais do projeto.

A resposta deverá ser definida **antes de fecharmos completamente a história da campanha**.

Ela servirá como ponto de partida para determinar:

* a verdadeira origem da unidade;
* o motivo da avaliação inicial;
* a escolha do Capitão;
* a seleção dos quatro soldados;
* a retirada do apoio governamental;
* os patrocinadores;
* a conspiração;
* os Caçadores;
* o ataque à base;
* o antagonista final;
* e os possíveis finais da campanha.

---

## Regra deste documento

**Estas são anotações de pré-desenvolvimento.**

Elas **não substituem nem alteram o GDD v0.2**.

As decisões aqui registradas deverão ser revisitadas quando o projeto entrar efetivamente na fase de pré-produção e desenvolvimento.
