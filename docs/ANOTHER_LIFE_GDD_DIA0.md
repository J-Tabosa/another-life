# ANOTHER LIFE / OUTRA VIDA

**Game Design Document (GDD) — Dia 0 + Roadmap Técnico para Codex**  
**Estado:** pré-produção; documento-base para implementação incremental  
**Período de planejamento:** 11–12/10/2026  
**Engine:** Godot 4.5 — GDScript  
**Escopo deste documento:** decisões estabelecidas nas conversas; propostas explicitamente identificadas; roadmap por entregas verificáveis.

> **Regra de leitura:** se algo estiver marcado como **[CANÔNICO]**, foi escolhido pelo criador e não deve ser alterado pelo Codex sem nova orientação. **[PROPOSTA]** é uma recomendação sujeita a teste. **[PENDENTE]** exige decisão ou validação. **[POSTERIOR]** é conteúdo planejado, mas fora do primeiro protótipo.
>
> **Regra de produção:** construir uma experiência pequena, jogável e agradável antes de ampliar o conteúdo. Não antecipar funcionalidades de versões futuras.

---

## 1. Visão do jogo

### 1.1. Identidade

| Campo | Definição | Status |
|---|---|---|
| Título provisório | **Another Life / Outra Vida** | [CANÔNICO] |
| Cidade | **Fliegen** | [CANÔNICO] |
| Instituição de ensino | **Horizonte** | [CANÔNICO] |
| Curso do protagonista | **História** | [CANÔNICO] |
| Gênero | Simulação de vida + RPG narrativo / slice of life | [CANÔNICO] |
| Inspirações estruturais | *Stardew Valley*, *Harvest Moon* e *Summertime Saga* | [CANÔNICO] |
| Engine | Godot 4.5, 2D | [CANÔNICO] |
| Idiomas da primeira beta | Português brasileiro, inglês, espanhol | [CANÔNICO] |
| Primeiro protótipo | Um dia completo, do despertar ao sono | [CANÔNICO — OBJETIVO] |

### 1.2. Fantasia e diferencial

O jogador controla um universitário de 20 anos que se muda com a família para Fliegen após ser aceito no prestigiado curso de História da Horizonte. A universidade fica numa região remota, mas é reconhecida por sua qualidade. O reconhecimento acadêmico do protagonista contrasta com a reputação criminosa da mãe, famosa por golpes milionários e atualmente foragida.

O jogo equilibra cotidiano universitário, vida familiar, amizades, romances e três hobbies iniciais. **O mundo não gira em torno do protagonista:** NPCs possuem rotinas, objetivos, compromissos, relações e acontecimentos que continuam progredindo sem a participação do jogador.

**Pilares de design:**

1. **Tempo é a principal moeda:** participar de uma atividade significa deixar de participar de outras.
2. **Cotidiano significativo:** família, aulas, lazer e pequenas conversas precisam ter valor próprio.
3. **NPCs com vida autônoma:** casais, amizades, afastamentos e partidas podem acontecer sem o jogador.
4. **Conhecimento parcial:** o jogador só sabe o que viu, ouviu ou descobriu.
5. **Desenvolvimento incremental:** cada nova atualização deve aproveitar sistemas existentes e adicionar conteúdo de forma controlada.

**Não é:** um mundo aberto contínuo, um RPG de combate, uma simulação de sobrevivência, um jogo focado em crafting, nem uma investigação policial obrigatória.

---

## 2. Protagonista e núcleo familiar

### 2.1. Protagonista — 20 anos [CANÔNICO]

- Cursa **História** na Horizonte; a aprovação dele motivou a mudança de toda a família.
- O jogador **escolhe o nome**.
- **Cabelo, rosto, cor de pele e aparência-base são fixos**: não há criador de personagem visual.
- Há **uma roupa padrão** e, futuramente, aproximadamente **3–4 trajes completos desbloqueáveis**; sem peças cosméticas modulares ou sistema de acessórios.
- A **personalidade é definida pelas escolhas** ao longo do jogo, e não por controles de atributos no início.
- O **passado familiar é fixo**.
- O jogador determina em quais hobbies investe tempo e como desenvolve os relacionamentos.
- Sabe claramente que o pai **conhecia e tolerava os crimes da mãe**. Essa informação **não é um segredo a revelar**.
- Sua competência acadêmica futura depende de frequência, respostas e avaliações; ter sido aceito na Horizonte não significa que sempre terá bom desempenho.

### 2.2. Mãe — 48 anos [CANÔNICO]

- Fugitiva famosa, procurada por **golpes milionários**, desaparecida há alguns anos.
- Antes da fuga, foi uma mãe **genuinamente boa, presente, carinhosa e marcante**.
- Ama verdadeiramente marido e filhos; em **contatos raros e ocasionais** demonstra esse amor.
- Também gosta da **adrenalina e do estilo de vida criminoso**; não está condenada a sofrer continuamente pela distância.
- Não escrever como vilã caricata, mártir sofredora ou inocente secreta por padrão.
- Figura narrativa relevante a longo prazo; **não é NPC de rotina do primeiro protótipo**.

### 2.3. Pai — 45 anos [CANÔNICO]

- Continua amando a esposa; **nunca pediu divórcio**.
- Sabia que ela cometia crimes e tolerava isso, **sem que participação criminosa esteja estabelecida**.
- Mudou de cidade para acompanhar a oportunidade universitária do filho.
- Começou um novo emprego, que o desgasta **em segredo**.
- Três arcos principais **[POSTERIOR]**:
  1. Tentar ser mais radical/aventureiro à maneira da esposa; **skate** será a conexão inicial.
  2. Uma **segunda mulher** demonstra interesse romântico por ele; ele continua casado e apaixonado pela mãe.
  3. Cansaço e sobrecarga do novo emprego, que tenta esconder dos filhos.
- Não retratá-lo como mero ingênuo, cúmplice confirmado ou NPC que só distribui problemas.

### 2.4. Irmã — 11 anos [CANÔNICO]

- Sente falta da mãe, sem ser permanentemente triste: tem infância, interesses e vida própria.
- Está numa escola nova por causa da mudança da família.
- Dois arcos principais **[POSTERIOR]**:
  1. **Bullying** na escola devido à notoriedade criminosa da mãe.
  2. Desejo de ficar próxima do irmão, brincando, conversando e **jogando videogame**.
- Não tornar o irmão seu único apoio possível: pai, amigos, colegas e escola também devem ter agência.

### 2.5. Tom familiar

Família funcional e afetuosa, que há anos se adaptou à ausência — **não** uma casa em crise recente e contínua. Combinar humor, afeto, pequenas rotinas e conflitos morais. Nenhum familiar deve existir apenas em função da mãe.

---

## 3. Geografia e estrutura do mundo

### 3.1. Fliegen [CANÔNICO]

- Cidade **pequena**, **costeira**, cercada por **floresta, campos e um rio que deságua numa praia nos arredores**.
- Universidade prestigiada apesar da localização remota.
- **Não é mundo aberto contínuo**: a exploração ocorre em **mapas/áreas separados por transições**, no espírito de *Harvest Moon* e *Stardew Valley*.
- Locais naturais favorecem história regional, pesquisa, lazer e eventos sazonais, sem criar novos hobbies obrigatórios.

**Macroáreas futuras [PROPOSTA DE ORGANIZAÇÃO]:** bairro residencial, campus Horizonte, centro comercial, praia/calçadão, rio, floresta e campos/zona rural.

**Mapas mínimos da vertical slice [OBJETIVO]:**

1. Casa: quarto e ambiente familiar navegável.
2. Rua residencial e caminho sinalizado até a universidade.
3. Universidade: entrada/área de convivência e sala de aula.
4. Retorno à casa para apresentação dos hobbies e interação com a cama.

**Não construir** praia, floresta, rio, campos, centro completo e todos os estabelecimentos no primeiro dia de implementação. Os cenários completos dos hobbies ficam para entregas subsequentes.

### 3.2. Deslocamento [CANÔNICO / EVOLUÇÃO]

- **Caminhada** no começo; o roteiro de abertura exige ir e voltar **a pé, seguindo placas**.
- Ônibus como alternativa de transporte inicial/contextual.
- Bicicleta e, posteriormente, motocicleta são melhorias de mobilidade.
- Moto pode proporcionar viagens rápidas (*fast travel*), **ainda consumindo tempo no mundo**.
- Mapas conectados por pontos de transição (portas, limites de área, passagens).

---

## 4. Arte, câmera e movimento

| Item | Especificação | Status |
|---|---|---|
| Estilo | Pixel art 2D | [CANÔNICO] |
| Perspectiva | Superior em 3/4, semelhante a *Stardew Valley* | [CANÔNICO] |
| Movimentação | Oito direções, com velocidade diagonal normalizada | [CANÔNICO] |
| Sprites de animação | Quatro direções: cima, baixo, esquerda, direita | [CANÔNICO] |
| Quadro do personagem | **128×128 px por frame** | [CANÔNICO] |
| Aparência | Um visual-base, com 3–4 trajes completos futuros | [CANÔNICO] |
| Tile base | **32×32 ou 64×64**, comparar visualmente | [PENDENTE] |
| Resolução interna | **960×540** como ponto de partida para teste | [PROPOSTA] |
| Zoom/câmera | Ajustar observando personagem, interiores e distâncias | [PENDENTE] |
| Retratos de diálogos | Podem ser úteis, mas não estão aprovados como requisito da vertical slice | [PROPOSTA] |
| Música/trilha | Definir depois; pode usar áudio provisório com licença apropriada | [POSTERIOR] |

**Nota crítica:** 128×128 é o tamanho do **quadro**, não necessariamente a caixa visual do corpo nem a colisão. O sprite pode conter margem transparente. Construções ocupam múltiplos tiles ou sprites próprios. O upscale aplica-se ao quadro renderizado, não determina a escala relativa dos objetos. Para pixel art, testar filtragem *nearest* e escala coerente.

**Teste gráfico obrigatório antes de produzir assets em massa:** personagem 128×128 + porta + cama + mesa + trecho de parede/fachada com tiles de 32 e depois 64. Escolher pelo resultado, não por suposição.

---

## 5. Calendário, relógio e sono

### 5.1. Calendário anual [CANÔNICO]

- **4 estações**, nesta ordem: primavera, verão, outono, inverno.
- **30 dias por estação**; **120 dias por ano**.
- Dias da semana: segunda a domingo; faculdade funciona **segunda a sexta**.
- **Férias de verão:** dias **1–7** do verão (7 dias corridos).
- **Férias de inverno:** dias **24–30** do inverno (7 dias corridos).
- O número da semana continua naturalmente entre os anos; não reiniciar o dia da semana a cada estação.
- **Dia da semana inicial do Ano 1: [PENDENTE].** Para teste técnico pode ser configurável ou começar em segunda, claramente como suposição provisória.

### 5.2. Universidade e turnos [CANÔNICO]

- O protagonista acorda normalmente às **06h**, e a primeira aula começa às **09h**.
- No início, aulas **de manhã e à tarde**, de segunda a sexta fora das férias.
- Em fases posteriores da graduação, a grade pode ficar **só pela manhã OU só pela tarde**.
- **Nunca há aulas noturnas** para o protagonista.
- **12h–13h de almoço e 13h–17h à tarde são horários provisórios** usados no planejamento, ainda a confirmar como grade oficial.
- O jogador pode faltar às aulas; o calendário segue independentemente dele.

### 5.3. Funcionamento do relógio [CANÔNICO]

- **60 segundos reais = 1 hora do jogo**; portanto, **1 segundo real = 1 minuto in-game**.
- **Áreas externas:** relógio corre continuamente enquanto o jogo não estiver pausado por UI/cutscene.
- **Interiores:** passagem natural do tempo fica **congelada**, permitindo exploração e diálogos com calma.
- **Ações e eventos com duração:** avançam tempo explicitamente mesmo em interiores (aulas, trabalho, treino, jogar, sono, transporte etc.).
- Ao entrar ou sair de uma área, conservar data e hora; o relógio só muda por tempo contínuo ou ação que consome tempo.
- Aulas usam avanço temporal até o fim do turno, com cenas/perguntas inseridas durante a atividade.
- Esperar até o começo da próxima aula dentro da faculdade: **[PROPOSTA NECESSÁRIA DE UX]**. Sem isso, chegar cedo e parar o relógio dentro do prédio impede alcançar 09h. Implementar após validação ou como solução mínima explicitamente documentada.
- Não existe barra de energia nem consumo de energia por andar, estudar, trabalhar ou jogar.

### 5.4. Sono [CANÔNICO]

- **Meia-noite NÃO encerra o dia**. A data muda às 00h; o jogador pode continuar acordado.
- **Às 04h ocorre limite obrigatório**. Texto sugerido: *“Acho que já deu por hoje...”*.
- **Se estiver FORA de casa às 04h:** retorno automático, dorme obrigatoriamente **8 horas**, acorda às **12h do mesmo dia de calendário das 04h**. Perde a manhã e compromissos correspondentes.
- **Se já estiver EM CASA:** é obrigado a dormir quando atinge 04h, mas o **despertador configurado** permite acordar no horário escolhido, mesmo com poucas horas de sono (por padrão 06h, sujeito a configuração).
- Ao dormir em casa antes de 04h, a lógica de despertador também se aplica.
- Sono insuficiente repetido pode levar aos **estados discretos** `Normal`, `Cansado`, `Exausto`, `Doente`.
- **Sem barra de energia ou fadiga visível.** Os limites exatos e consequências desses estados ficam para balanceamento.
- Evitar punição automática extrema após apenas uma noite ruim. O impacto principal é tempo perdido, cansaço narrativo e eventuais efeitos de rotina/avaliação.

**Casos de borda que o Codex deve tratar:**

1. Uma ação iniciada às 03h que tentaria terminar após 04h não pode ignorar o limite; interromper/agendar como previsto pela atividade (preferência: impedir ou truncar a ação antes de iniciar, até definição de UX).
2. O limite às 04h aplica-se mesmo em interiores se uma **ação** fizer o relógio avançar até lá.
3. O relógio congelado dentro de um prédio não faz o tempo avançar sozinho; não disparar 04h sem avanço temporal real.
4. Transição durante uma aula ou sono processa eventos intermediários **em ordem cronológica**, incluindo agendas dos NPCs.
5. Dormir às 04h de terça e acordar às 12h: **terça, 12h**, não quarta.
6. Se autosave estiver desligado e o jogador escolher não salvar manualmente, não salvar silenciosamente.

---

## 6. Economia e inventário

### 6.1. Economia [CANÔNICO]

- Dinheiro inicial do protagonista: **100 unidades monetárias**. **Nome/símbolo da moeda: [PENDENTE]**.
- Pai dá uma **mesada modesta semanal**; a ajuda não depende de missões familiares ou de agradar o pai.
- Bicos e empregos **opcionais** permitem acumular dinheiro e adquirir autonomia ao longo da partida.
- Tempo gasto trabalhando compete com compromissos acadêmicos, sociais e familiares.
- Despesas futuras: transporte, lazer, presentes, alguns materiais e veículos.
- **Valor da mesada, preços e pagamentos dos bicos: [PENDENTE — BALANCEAMENTO]**. Não congelar os exemplos numéricos usados em simulações anteriores.

### 6.2. Inventário [CANÔNICO]

- Uma **bolsa simples** guarda itens-chave, materiais/objetos ligados a atividades, documentos, presentes e objetos comuns funcionais.
- **Sem crafting**, receitas, combinação de materiais, durabilidade, fome, sede ou gerenciamento de peso.
- Para o protótipo, não exigir limite de slots/carga; itens-chave não podem ser descartados acidentalmente **[PROPOSTA DE UX]**.

---

## 7. Universidade Horizonte e atividades acadêmicas

### 7.1. Curso [CANÔNICO]

- Graduação **fixa em História**.
- Variações futuras por **eletivas, atividades extracurriculares e projetos**, não pela escolha de cursos diferentes.
- A vida acadêmica não deve dominar todo o jogo nem limitar o conteúdo de família/relacionamentos.

### 7.2. Três minigames acadêmicos aprovados [CANÔNICO]

1. **Perguntas em aulas normais:** professor faz questões ocasionais estilo *Persona*. Conhecimentos de história e cultura geral acessíveis, sem exigência constante de especialização. Acertos têm pequena recompensa acadêmica; erros recebem reações naturais, sem punição extrema. Evitar questões historicamente ambíguas.
2. **Seminários/apresentações:** preparação anterior ajuda; durante a apresentação, professor faz perguntas de múltipla escolha com **janela aproximada de 5–10 segundos**. Acerto, erro e silêncio geram falas distintas e afetam avaliação. **Modo sem limite de tempo por acessibilidade: [PROPOSTA]**.
3. **Pesquisa em biblioteca/arquivos:** localizar registros e comparar fontes/documentos, tanto em trabalhos acadêmicos quanto em histórias da cidade. Evolução incremental sem criar um minigame gigantesco inicialmente.

### 7.3. Notas e progressão de semestre [CANÔNICO — LIMITADO]

Na primeira versão, o desempenho acadêmico depende **somente** de:

- **Frequência às aulas**;
- **Acertos nas perguntas feitas em sala**;
- **Pontuações nas avaliações**, incluindo seminários e provas.

**Fórmula, pesos, notas de aprovação e reprovação: [PENDENTE].** Não criar atributos extras de inteligência, estresse, concentração ou sistema universitário complexo sem solicitação.

---

## 8. Hobbies — exatamente três no escopo inicial

| Categoria | Hobby oficial | Papel |
|---|---|---|
| Esporte | **Skate** | Progressão esportiva; conexão com pai e NPC da pista |
| Criatividade | **Música** | Prática no quarto; futuro NPC/área musical |
| Social | **Fliperama e videogames** | Minigame arcade; convivência com irmã e futuros amigos |

**[CANÔNICO]** Não adicionar pesca, fotografia, basquete, culinária, agricultura, mineração, artesanato ou outros hobbies ao escopo inicial.

### 8.1. Progressão híbrida [CANÔNICO]

- Poucos **níveis/graus simples de domínio**; sugestões de nomes: iniciante, intermediário, avançado.
- **Desbloqueios importantes por conquistas e eventos**, não apenas por XP acumulado.
- Ser habilidoso no minigame pode permitir bom desempenho mesmo num nível baixo; graus liberam conteúdo e oportunidades.
- Não há **nível geral obrigatório do protagonista**.
- Cada atividade deve ser divertida por si só, mesmo sem NPC presente.
- O progresso pode ocorrer separadamente em cada hobby; o jogador escolhe onde investir tempo.

### 8.2. Introdução no primeiro dia [CANÔNICO]

- **Pai** introduz skate em evento doméstico.
- **Irmã** introduz videogames em interação familiar.
- **Quarto** permite descobrir música.
- Essas introduções **não obrigam** a implementar os três minigames completos no Vertical Slice. Versões funcionais mínimas entram por incrementos na alpha.

---

## 9. Elenco e relações sociais

### 9.1. Oito NPCs cotidianos iniciais [CANÔNICO]

| # | NPC | Local/função inicial | Profundidade na primeira versão |
|---|---|---|---|
| 1 | **Pai** | Casa; apresentação de skate | Rotina simples + diálogos/evento inicial |
| 2 | **Irmã** | Casa; apresentação de videogames | Rotina simples + diálogos/evento inicial |
| 3 | **Professor** | Horizonte | Aula e primeira pergunta |
| 4 | **Primeira colega/amiga de turma** | Horizonte | Primeiro contato e diálogo no almoço |
| 5 | **NPC da primeira loja/bico** | Primeiro estabelecimento de trabalho | Oferece bico; sem arco complexo |
| 6 | **NPC do skate** | Local de prática | Introduz/apoia atividade; sem arco complexo |
| 7 | **NPC da música** | Local de prática musical | Introduz/apoia atividade; sem arco complexo |
| 8 | **NPC do fliperama** | Local de jogos | Introduz/apoia atividade; sem arco complexo |

A **mãe** é personagem relevante do núcleo narrativo, mas não NPC regular dos mapas no primeiro protótipo. **X/Y/Z** citados em exemplos de romances são exemplos de design **[POSTERIOR]**, não somar automaticamente ao elenco inicial.

**Nomes próprios, aparências e biografias dos NPCs além da família: [PENDENTE].**

### 9.2. Regras de relacionamentos [CANÔNICO]

- Relações têm estados internos como afinidade, confiança, interesse e fase do vínculo; **não mostrar números exatos ao jogador**.
- Relações entre NPCs possuem **pares possíveis pré-definidos pelo roteiro**, mas os resultados variam dinamicamente por agenda, reciprocidade, decisões e eventos.
- **Não** formar casais aleatórios entre quaisquer NPCs.
- Compromissos no calendário podem conflitar: um NPC pode recusar/remarcar encontro porque já tinha outro compromisso, inclusive com o protagonista.
- Uma recusa isolada não implica automaticamente antipatia; **padrões repetidos de indisponibilidade** podem provocar distanciamento e novas aproximações.
- NPCs podem iniciar convites e tomar decisões próprias. O jogador não é responsável por fazer tudo acontecer.
- Relações podem terminar em amizade, namoro, afastamento ou outros estados coerentes; nenhum namoro deve ser forçado.
- Vínculos românticos aplicam-se somente a personagens adultos com possibilidades narrativas apropriadas.

### 9.3. Memórias e conhecimento parcial [CANÔNICO]

- **Estado real do mundo** e **conhecimento do protagonista** devem ser armazenados separadamente.
- O protagonista só conhece acontecimentos que **presenciou**, que lhe foram **relatados** ou que ouviu como **boatos**.
- Fichas sociais exibem **vínculos e fatos conhecidos**, não sentimentos secretos, agendas privadas ou relações nunca descobertas.
- Boatos não equivalem a fatos confirmados; informações podem ficar desatualizadas sem desaparecer retroativamente.
- **Diário automático** registra acontecimentos relevantes **por personagem e data**, sem exigir anotações manuais.
- O diário não atualiza imediatamente só porque dois NPCs se aproximaram em algum lugar fora da tela.
- Memórias importantes alteram diálogos e consequências; não registrar cada fala rotineira.

### 9.4. Camadas de tempo da narrativa

- **Dias:** rotinas, conversas, convites, compromissos.
- **Estações:** projetos, oportunidades, mudança de vínculos, férias.
- **Anos:** formaturas, partidas da cidade e transformações de vida **[POSTERIOR]**.

**Prova técnica inicial:** pelo menos um evento de NPC ocorre fora de cena e altera seu estado, **sem** revelar informação oculta ao diário do jogador até que ela seja descoberta.

---

## 10. Interface e localização

### 10.1. HUD [PROPOSTA ALINHADA ÀS DECISÕES]

- Interface discreta: dia/estação, hora e dinheiro.
- Localização da área pode aparecer de forma transitória.
- Indicadores de condição (`Cansado`, `Exausto`, `Doente`) apenas quando relevantes; **sem energia**.

### 10.2. Celular [PROPOSTA ESTRUTURAL]

Aplicações: calendário pessoal (somente compromissos conhecidos), contatos, mensagens, diário de memórias e mapa de locais conhecidos. Abrir consulta de menu pode pausar a simulação **[PENDENTE UX]**, sem impedir que uma ação selecionada avance tempo.

### 10.3. Traduções [CANÔNICO PARA A BETA]

- Locales-alvo: `pt_BR`, `en`, `es` (variante exata de espanhol a decidir).
- **Usar identificadores de texto desde o primeiro dia** (`DIALOG_FATHER_INTRO_01`, `UI_SAVE_SLEEP`, etc.) em vez de amarrar regras a frases literais.
- Estrutura de tradução compatível com Godot (`.csv` ou `.po`) e `TranslationServer`.
- O protótipo pode conter texto em português apenas, mas deve ser **traduzível sem refatorar a lógica**.
- Diário e mensagens salvam **IDs de eventos e parâmetros**, não apenas uma frase pronta em um único idioma.

---

## 11. Sistema de salvamento [CANÔNICO]

- **Autosave habilitável/desabilitável** pelo jogador nas configurações.
- **Salvamento manual** prioritariamente na **cama, antes de dormir**, inspirado em *Harvest Moon* de SNES; oferecer "salvar e dormir" e "dormir sem salvar manualmente".
- **Manual e autosave em arquivos independentes**. Jamais sobrescrever um com o outro.
- Configuração de autosave persiste separada dos arquivos de partida.
- Se sono obrigatório às 04h: apresentar oportunidade de salvar; não permitir cancelar o sono. Se autosave estiver desligado e usuário recusar salvar, respeitar a decisão.
- O carregamento deverá distinguir o save manual do autosave da mesma partida.
- Dados mínimos: versão do save; data/hora/estação; mapa e ponto de entrada; nome; dinheiro; inventário; estado do sono; frequência/notas; hobbies; estados/memórias dos NPCs; compromissos; flags de eventos; conhecimento/diário; preferências da partida.
- Recomendação técnica: gravar primeiro em arquivo temporário e substituir atomicamente quando possível; validar versão e estrutura antes de carregar. **[PROPOSTA DE IMPLEMENTAÇÃO]**

**Exemplos de caminhos técnicos [PROPOSTA]:** `user://saves/slot_01/manual.json`, `user://saves/slot_01/auto.json`, `user://settings.json`. Nomes/extensões não são regras criativas; a separação dos arquivos é obrigatória.

---

## 12. Roteiro canônico — Primeiro dia jogável

**Nome interno:** `DAY_01_INTRO`  
**Objetivo:** apresentar movimentação, família, universidade, relógio, primeira escolha acadêmica e três hobbies, concluindo com sono/salvamento.

| Ordem | Situação | Interação do jogador | Sistema demonstrado |
|---|---|---|---|
| 1 | Acordar às 06h | Levantar, se arrumar, escolher nome quando pertinente | Personagem + interação |
| 2 | Conversar com pai e irmã | Conversas iniciais em casa | Diálogo e família |
| 3 | Ir a pé à Horizonte seguindo placas | Caminhar e cruzar transições | Relógio externo + mapa |
| 4 | Primeira aula às 09h | Participar da apresentação inicial | Agenda e avanço de aula |
| 5 | Conhecer a primeira colega/amiga | Diálogo introdutório | NPC social |
| 6 | Almoço/intervalo | Conversar novamente na faculdade | Interior com relógio pausado |
| 7 | Aula da tarde | Primeira pergunta do professor | Quiz acadêmico |
| 8 | Voltar a pé para casa | Repetir percurso com autonomia | Deslocamento e tempo |
| 9 | Pai introduz skate | Cena/dialogo curto | Hobby esporte |
| 10 | Irmã introduz videogames | Cena/dialogo curto | Hobby social |
| 11 | Música disponível no quarto | Interagir com ponto de prática | Hobby criativo |
| 12 | Dormir | Optar por save manual e avançar dia | Sono + SaveManager |

**Importante:** o roteiro acima descreve a **rota de apresentação esperada**, não autoriza bloquear todas as escolhas. O jogo deve manter a premissa de que o jogador eventualmente pode faltar às aulas e mudar compromissos. Na vertical slice, tratar os casos fora do caminho principal com implementações mínimas seguras e sem *softlocks*; consequências narrativas complexas ficam para depois.

**Timing:** primeira aula 09h e acordar 06h são fixos; encerramento matutino, hora do almoço e turno da tarde **ainda devem ser confirmados**, mesmo que se use 12h/13h/17h como configuração temporária. O percurso a pé deve permitir chegar sem pressa excessiva dentro da janela 06h–09h.

### 12.1. Critérios de aceitação do dia 1

- [ ] O jogo abre e permite iniciar nova partida.
- [ ] O nome escolhido persiste nos diálogos e no save.
- [ ] O protagonista anda em oito direções, anima-se em quatro e não corre mais na diagonal.
- [ ] O jogador transita entre casa, rua e universidade sem perder hora/data.
- [ ] Relógio avança externamente a 1 minuto de jogo por segundo real e fica parado em interiores.
- [ ] A ação de aula avança ao horário correto e contabiliza frequência.
- [ ] A primeira colega pode ser conhecida e reencontrada no almoço.
- [ ] O professor faz uma pergunta com alternativas, reação a acerto/erro e registro do resultado.
- [ ] Pai, irmã e instrumento/local de música apresentam os três hobbies.
- [ ] A cama oferece salvar manualmente antes de dormir.
- [ ] Uma partida salva carrega sem perder posição, horário, flags ou nome.
- [ ] O próximo dia aparece corretamente após o sono.
- [ ] Nada obriga implementar todos os minigames completos no Dia 1.

---

## 13. Arquitetura técnica para Godot 4.5

### 13.1. Princípio

Separar **dados**, **regras globais**, **cenas** e **conteúdo narrativo**. Managers são responsabilidades lógicas, **não exigem automaticamente nove Autoloads**. Só usar Autoload para o que realmente precisa sobreviver às mudanças de cena ou ser acessível globalmente.

### 13.2. Responsabilidades planejadas

| Módulo | Função | Prioridade para primeiro dia |
|---|---|---|
| `GameState` | Estado de partida, protagonista e flags básicas | Alta |
| `TimeManager` | Tempo contínuo e avanço explícito; calendário; 04h | Alta |
| `SceneTransitionManager` | Troca de áreas, spawn/retorno | Alta |
| `DialogueController` | Diálogos, escolha e interação | Alta; avaliar reaproveitamento de Drowned |
| `ScheduleManager` | Aulas, rotinas e compromissos | Mínimo para aula; expandir depois |
| `EventManager` | Gatilhos narrativos, condições e consequências | Mínimo para primeiro dia |
| `SaveManager` | Manual, autosave, carregamento e versão de save | Alta até fechar vertical slice |
| `InventoryManager` | Bolsa e objetos | Depois da movimentação e relógio |
| `ProgressionManager` | Notas e hobbies | Pequeno módulo após dia 1 |
| `RelationshipManager` | Vínculos NPC↔NPC e NPC↔jogador | Alpha posterior |
| `KnowledgeManager` | Fatos percebidos vs reais | Alpha posterior |
| `JournalManager` | Consulta de memórias descobertas | Alpha posterior |
| `MessageManager` | Mensagens e convites | Posterior |

### 13.3. Esboço de pastas **[PROPOSTA]**

```text
AnotherLife/
├── project.godot
├── README.md
├── AGENTS.md
├── docs/
│   ├── ANOTHER_LIFE_GDD_DIA0.md
│   └── decisions.md                # decisões posteriores ao Dia 0
├── assets/
│   ├── characters/
│   ├── tilesets/
│   ├── ui/
│   ├── audio/
│   └── placeholders/
├── scenes/
│   ├── core/
│   ├── player/
│   ├── world/
│   ├── interiors/
│   ├── university/
│   ├── npcs/
│   ├── activities/
│   └── ui/
├── scripts/
│   ├── core/
│   ├── components/
│   ├── player/
│   ├── world/
│   ├── narrative/
│   └── ui/
├── data/
│   ├── characters/
│   ├── events/
│   ├── schedules/
│   ├── items/
│   └── questions/
├── localization/
└── tests/
```

A estrutura pode ser simplificada por Codex; não criar pastas vazias só para cumprir um diagrama.

### 13.4. Modelo de dados ilustrativo **[PROPOSTA TÉCNICA]**

**Tempo:** manter contagem absoluta de minutos para evitar erros de rollover e derivar ano/estação/dia/semana. Configurar explicitamente a origem do dia da semana.

```text
world_minutes: int
minute_of_day = world_minutes % 1440
absolute_day = floor(world_minutes / 1440)
season_index = floor((absolute_day % 120) / 30)
day_of_season = (absolute_day % 30) + 1
year = floor(absolute_day / 120) + 1
weekday = (weekday_offset + absolute_day) % 7
```

O valor de `world_minutes` deve representar uma data-base coerente com o Ano 1; não confiar em relógio de sistema. Cada avanço explícito de tempo deve percorrer **limiares e eventos intermediários**, não apenas somar minutos e olhar o estado final.

**NPC [exemplo conceitual]:**

```text
npc_id
home_scene_id
basic_schedule_id
story_flags
relationships_by_npc_id
calendar_commitments
```

**Memória conhecida [exemplo conceitual]:**

```text
memory_id
subject_npc_id
event_id
discovered_at_world_minutes
source_type: witnessed | reported | rumor
localization_key
parameters
```

**Save [exemplo conceitual]:**

```text
schema_version
player: { name, money, scene_id, spawn_id, inventory, conditions }
world: { world_minutes, event_flags, npc_states, schedules }
progression: { attendance, questions, assessments, hobbies }
knowledge: { discovered_memories, known_relations }
```

> **Evitar:** reproduzir o mundo inteiro por simulação física quando NPCs estão fora de cena; as mudanças podem ser resolvidas logicamente na passagem do tempo e materializadas quando o mapa é carregado.

### 13.5. Reaproveitamento de Drowned

- [ ] **Inspecionar primeiro** as cenas/scripts existentes de movimentação, diálogos, interações e transições.
- [ ] Reaproveitar somente sistemas compatíveis, adaptando para visão superior 3/4 e contexto social.
- [ ] Não copiar combate, boss HUD, inimigos ou árvores de dependência desnecessárias.
- [ ] Manter **Drowned intacto** (projeto pausado, não descartado). Trabalhar em **novo repositório/projeto** ou cópia explicitamente separada.
- [ ] Não presumir que assets de Drowned combinam visualmente com Another Life.

---

## 14. Roadmap técnico — tarefas pequenas para Codex

### Organização geral

**Uma tarefa/PR por vez.** Antes de começar: ler GDD e `AGENTS.md`, inspecionar repositório, listar arquivos que serão alterados, implementar o mínimo e verificar critérios. Não adicionar sistemas adjacentes sem solicitação.

#### Fase 0 — Preparação, sem gameplay

| ID | Tarefa | Critério de aceite |
|---|---|---|
| `P0-01` | Criar novo projeto Godot 4.5 e repositório próprio | Projeto abre sem erros; Drowned preservado |
| `P0-02` | Adicionar GDD, `AGENTS.md`, README e `.gitignore` | Documentação acessível no repositório |
| `P0-03` | Auditar apenas o código reaproveitável de Drowned | Lista objetiva de scripts/cenas reutilizáveis e dependências |
| `P0-04` | Criar cena-laboratório de proporções | Personagem 128×128 + objetos com 32 e 64 px para comparação |
| `P0-05` | Escolher **provisoriamente** tile/câmera após teste | Screenshot e breve decisão documentada; sem produzir mapa completo |

#### Fase 1 — Protótipo técnico do cotidiano

| ID | Tarefa | Critério de aceite |
|---|---|---|
| `P1-01` | Controlador 2D com 8 direções e 4 animações | Diagonal normalizada; colisões e idle coerentes |
| `P1-02` | Casa simples, rua e porta interativa | Entrar/sair preserva spawn correto |
| `P1-03` | `TimeManager` com 60s reais/hora ao ar livre | Testes de minutos, meia-noite, estação/ano e dias da semana |
| `P1-04` | Pausa temporal em interiores | Relógio para ao entrar e volta ao sair |
| `P1-05` | Ações com duração explícita | Uma ação de 60min avança exatamente 60min mesmo em interior |
| `P1-06` | Sistema mínimo de diálogo/interação | Conversar não consome tempo por padrão |
| `P1-07` | Sono, despertador e limite das 04h | Casos em casa/fora de casa e despertar às 12h funcionando |
| `P1-08` | Save manual na cama + autosave opcional em arquivo separado | Carregar cada arquivo sem sobrescrever o outro |

**Checkpoint P1:** conseguir acordar, sair, explorar, voltar, dormir e continuar o dia seguinte; **sem universidade completa ainda**.

#### Fase 2 — Vertical Slice do Dia 1

| ID | Tarefa | Critério de aceite |
|---|---|---|
| `P2-01` | Trajeto residencial → Horizonte sinalizado | Chegar a pé para aula das 09h em ritmo viável |
| `P2-02` | Cena da universidade e sala de aula | Entrar, explorar, conversar, acessar aula |
| `P2-03` | Agenda acadêmica mínima manhã/tarde | Aulas acionam avanço temporal; presença/falta registrada |
| `P2-04` | Professor e primeira aula | Diálogo introdutório funcional |
| `P2-05` | Primeira colega/amiga + almoço | Duas oportunidades de conversa no mesmo dia |
| `P2-06` | Banco de questões e primeira pergunta | Quatro alternativas, resposta correta, reação e registro |
| `P2-07` | Eventos curtos de pai/irmã + música no quarto | Skate, videogame e música descobertos pelo jogador |
| `P2-08` | Fluxo do fim do dia e teste completo | Dia 1 jogável do começo ao fim; sem *softlock* |

**Checkpoint P2:** jogo consegue contar o primeiro dia inteiro, com roteiro descrito na seção 12.

#### Fase 3 — Alpha inicial de 14 dias

| ID | Tarefa | Critério de aceite |
|---|---|---|
| `P3-01` | Calendário completo e férias | 120 dias/ano, verão 1–7, inverno 24–30 |
| `P3-02` | Mesada semanal + saldo inicial de 100 | Pagamento uma vez por semana, sem duplicação em load |
| `P3-03` | Bolsa simples + um objeto-chave | Persistência e uso básico sem crafting |
| `P3-04` | Primeiro bico com NPC de loja | Tempo e pagamento contabilizados |
| `P3-05` | Skate básico e NPC do skate | Atividade curta funcional e persistência |
| `P3-06` | Música básica e NPC da música | Atividade curta funcional e persistência |
| `P3-07` | Arcade básico + NPC de jogos | Um jogo curto; irmã pode participar de interação familiar |
| `P3-08` | Rotinas mínimas para 8 NPCs | Horários/lugares consistentes após saltos de tempo |
| `P3-09` | Evento independente de NPC | Estado muda sem jogador presente |
| `P3-10` | Conhecimento parcial e diário automático mínimo | Evento não conhecido **não** aparece no diário |
| `P3-11` | Compromisso social com confirmação e falta | Agenda respeita conflitos e memórias de cumprimento/falta |
| `P3-12` | Teste de 14 dias, regressão de save e relógio | Sem duplicação de eventos, perda de estado ou travamentos |

**Checkpoint P3:** alpha compacta, 14 dias, com 8 NPCs iniciais e os três hobbies em versões mínimas.

#### Fase 4 — Expansões e primeira beta [POSTERIOR]

- Arcos completos do pai e da irmã; contatos raros da mãe.
- Seminários cronometrados, provas e pesquisas de biblioteca.
- Eletivas e mudanças de turno acadêmico.
- Relações NPC↔NPC com pares possíveis pré-escritos e ramificações por agenda.
- Novas regiões de Fliegen, eventos sazonais e viagens/partidas de personagens.
- Balanceamento financeiro, efeitos de `Cansado` / `Exausto` / `Doente`.
- Trajes completos desbloqueáveis, bicicleta/moto e transporte mais completo.
- Português (Brasil), inglês e espanhol revisados antes da **primeira beta**.
- Trilha sonora e acabamento audiovisual.

**Não tratar P4 como compromisso de implementar tudo antes do primeiro protótipo.**

---

## 15. Plano concreto da próxima sessão (primeiro dia de código)

**Objetivo único:** testar a escala visual e fazer o protagonista andar entre um quarto simples e uma rua com transição. **Não iniciar NPCs complexos, notas, romances, 3 minigames, save ou calendário completo nesta sessão.**

### Entrada

- Godot 4.5 disponível.
- GDD e `AGENTS.md` no repositório.
- Sprite 128×128, se já houver; caso contrário, usar **placeholder 128×128** identificado como provisório.
- Inspecionar Drowned **apenas se** houver acesso ao repositório; nunca presumir arquivos existentes.

### Tarefas atômicas

1. Inicializar repositório/projeto isolado `AnotherLife`.
2. Definir entrada principal com cena de teste.
3. Montar pequeno cenário de comparação com tiles 32×32 e 64×64, personagem e referência de porta/cama.
4. Implementar `CharacterBody2D`, `CollisionShape2D`, sprite/`AnimatedSprite2D` e câmera de seguimento.
5. Criar movimento 8 direções, animações 4 direções, idle coerente, velocidade diagonal normalizada.
6. Criar porta que transfere quarto↔rua, com ponto de entrada consistente.
7. Documentar imagens/capturas, escala escolhida provisoriamente e problemas.

### Definition of Done (DoD)

- [ ] Godot abre projeto sem erros vermelhos.
- [ ] Personagem anda fluido em 8 direções e anima em 4.
- [ ] Não anda mais rápido na diagonal.
- [ ] Colisões de porta/objetos funcionam.
- [ ] Quarto↔rua funciona sem alterar cena errada ou spawn.
- [ ] Escala de personagem, porta e mobília foi inspecionada visualmente.
- [ ] Não foi inserido nenhum sistema não solicitado.
- [ ] Uma nota de conclusão descreve arquivos alterados, como testar e próximos passos.

### Prompt de partida pronto para colar no Codex

```text
Você está trabalhando no projeto Another Life (Godot 4.5 / GDScript).
Leia primeiro AGENTS.md e docs/ANOTHER_LIFE_GDD_DIA0.md. As decisões marcadas [CANÔNICO] são requisitos. Não implemente sistemas [POSTERIOR] sem pedido.

Tarefa atual: executar somente a primeira sessão técnica descrita na seção 15 do GDD (cena-teste, comparação visual 32×32 vs 64×64, personagem de frame 128×128, movimentação 8 direções com 4 animações e transição quarto↔rua).

Antes de editar, inspecione a estrutura existente e resuma rapidamente o plano e os arquivos previstos. Se não houver arte final, use placeholders claramente identificados. Evite refatoração ampla e não altere Drowned. Não implemente inventário, romances, calendários, sistemas acadêmicos completos ou minigames nesta tarefa.

Depois, entregue: (1) arquivos alterados; (2) como executar; (3) testes feitos e seus resultados; (4) pendências visuais; (5) próxima tarefa sugerida. Se não conseguir abrir a Godot ou executar testes, declare isso sem inventar validação.
```

---

## 16. Matriz de testes prioritários para fases futuras

| Cenário | Resultado esperado |
|---|---|
| 60 segundos reais em área externa | +60 minutos do mundo |
| 60 segundos reais em interior, sem ação | +0 minutos do mundo |
| Atividade de 3 horas iniciada em interior | +180 minutos do mundo |
| Passagem de 23:59 para 00:00 | Dia seguinte, mesma estação ou próxima se dia 30 |
| Inverno dia 30 → dia seguinte | Primavera dia 1 do próximo ano |
| Verão 1–7 e inverno 24–30 | Sem aulas acadêmicas |
| Sábado/domingo fora das férias | Sem aula |
| Aula começa às 09h sem jogador | Acontece; frequência reflete ausência |
| Jogador fora de casa às 04h | Retorno e despertar às 12h do **mesmo dia** |
| Jogador em casa às 04h com alarme às 06h | Dorme obrigatoriamente e acorda às 06h, sujeito a condição de sono |
| Ação de várias horas cruza evento programado | Eventos são resolvidos em ordem correta |
| Autosave desligado | Nenhum arquivo de autosave é escrito por ação automática |
| Save manual e automático existentes | Um não sobrescreve o outro |
| Reload após mesada recebida | Não receber mesada duplicada |
| Dois NPCs interagem fora de tela | Estado real muda; conhecimento do jogador não é revelado automaticamente |
| Jogador descobre evento passado | Diário registra descoberta por personagem/data e origem |
| NPC tem convite com conflito de horário | Não cria dois compromissos impossíveis; aplica recusa/remarcação coerente |

---

## 17. Pendências deliberadamente NÃO fechadas no Dia 0

1. **Tamanho dos tiles:** escolher 32×32 ou 64×64 após teste visual.
2. **Resolução, zoom e escala de câmera:** testar; 960×540 é sugestão.
3. **Nomes, aparência e roteiros detalhados** dos NPCs secundários.
4. **Dia da semana inicial**, e horários oficiais de fim de aula/intervalo.
5. **Nome/símbolo da moeda**, mesada e tabela de preços/pagamentos.
6. **Fórmula das notas**, pesos de frequência, perguntas, provas e seminários.
7. **Efeitos quantitativos** de sono irregular e estados de condição.
8. **Instrumento de música**, regras de cada minigame completo, pontuação e domínio.
9. **Trajes alternativos** e quando serão desbloqueados.
10. **Nomes finais de arquivos**, detalhes concretos de formato e versionamento de save.
11. **Estilo e produção da trilha sonora**.
12. **Duração total e conteúdo completo dos anos/estações**; construir incrementalmente.
13. **Tratamento final de menus no relógio** e opção de esperar horários dentro de interiores.

> Quando surgir uma pendência, **não assumir silenciosamente que um exemplo anterior foi aprovado**. O Codex pode empregar um valor provisório tecnicamente necessário, documentando-o em `docs/decisions.md` ou nota de implementação, sem promovê-lo a cânone.

---

## 18. Regras negativas — O que o Codex NÃO deve adicionar

- **NÃO** adicionar barra de energia ou mecânicas de gasto de energia.
- **NÃO** adicionar crafting, mineração, agricultura ou inventário de sobrevivência.
- **NÃO** criar editor de cabelo, pele, rosto ou acessórios.
- **NÃO** transformar roupas em dezenas de peças cosméticas modulares.
- **NÃO** trocar História por outro curso ou oferecer seleção de cursos.
- **NÃO** criar aulas noturnas.
- **NÃO** transformar Fliegen num mundo aberto sem transições.
- **NÃO** adicionar mais hobbies além de skate, música e fliperama/videogames ao escopo inicial.
- **NÃO** transformar a mãe em vilã caricata, inocente secreta ou fonte de missões policiais constantes.
- **NÃO** supor que pai participou dos golpes por ter ciência deles.
- **NÃO** criar relações românticas aleatórias e universais entre NPCs.
- **NÃO** revelar sentimentos ocultos, agendas privadas ou memórias desconhecidas no celular/diário.
- **NÃO** sobrescrever saves manuais com autosave.
- **NÃO** alterar ou apagar Drowned.
- **NÃO** implementar todo o roadmap em um único pedido ou PR.

---

## 19. Definição de sucesso do projeto

**A primeira pergunta a responder é:** o jogador acorda em Fliegen, vai à Horizonte, conhece pessoas, volta para casa e **sente vontade de jogar o dia seguinte?**

O jogo deverá oferecer pequenas decisões com consequências compreensíveis, personagens que existem além do protagonista e atividades que valem o tempo investido. O objetivo não é produzir o maior jogo possível no primeiro lançamento, mas construir uma base que seja divertida de jogar, agradável de desenvolver e ampliável por pequenas atualizações.

**Fim do registro do Dia 0.** Próxima etapa: **P0 — laboratório de proporções, cena-teste e movimentação**, antes de expandir o conteúdo.
