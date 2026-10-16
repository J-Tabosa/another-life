# Another Life / Outra Vida

Protótipo em **Godot 4.7 / GDScript**, validado na **4.7.2 oficial**. Cânone e roadmap no [GDD](docs/ANOTHER_LIFE_GDD_DIA0.md), instruções em [AGENTS.md](AGENTS.md) e [migração da engine](docs/godot_4_7_migration.md).

## Entrega atual — P3-01

Calendário e férias auditados: **4 estações de 30 dias, 120 dias por ano**, dias da semana e número da semana contínuos entre estações/anos. **Verão 1–7 e inverno 24–30** são férias corridas; a Horizonte funciona de segunda a sexta fora desses intervalos. O retorno considera fins de semana, inclusive na primavera do ano seguinte. A origem semanal continua configurável; segunda-feira no início é **hipótese técnica**, não decisão de cânone.

**C** abre o calendário: **A** indica dia letivo, **F** férias e **—** fim de semana. Hoje aparece em azul, com data completa, semana e motivo da suspensão de aulas; o painel informa o próximo dia letivo. Passe o cursor sobre uma data para ver detalhes, inclusive férias coincidentes com sábado/domingo. Ano/estação permitem consultar datas passadas sem voltar o tempo; clicar numa data habilitada avança ao horário selecionado. **J** também explica férias/fim de semana e o retorno. Os painéis têm fundo legível e rolagem em 960×540.

Regras derivadas centralizadas no `TimeManager`, reutilizadas pela agenda, rotina da colega e validação dos saves. Férias não geram presença nem falta. Consultar datas não altera horário, fração do relógio ou progresso. Manual/auto, esquema 3 e migrações anteriores preservados. Validação: **590 verificações aprovadas**, incluindo **223** do calendário renderizado e as regressões de relógio, agenda, sono/save, colega e Dia 1 completo. [Regras, testes e limites](docs/calendar_validation.md).

## Dia 1 — P2-08 preservada

Dia 1 validado em partidas contínuas, de **06h em casa até a manhã seguinte**: cumprimentos familiares, caminhada até a Horizonte, aula da manhã, colega e almoço, questão à tarde, volta para casa, descoberta dos três hobbies e sono/salvamento. Dois percursos com física e portas reais, tiles 32/64, resposta correta/incorreta e auto ligado/desligado. [Roteiro, critérios e comandos](docs/day_one_validation.md).

A cama agora mostra **data, estação, ano e dia da semana do despertar**, além de horário/duração. **1** salva manualmente e dorme; **2** dorme sem manual; o mouse continua disponível. Digitar no alarme não aciona os atalhos de sono. Esc cancela o sono voluntário. Conversas usam contexto traduzível para o nome escolhido em C, preservado ao carregar. Uma chamada repetida de salvar após acordar não substitui o manual anterior.

É permitido dormir sem concluir o roteiro. Foram testados cancelamentos, dia inteiro perdido e retomada posterior, sono obrigatório às 04h, gravação falhando com recuperação e load inválido sem perda do estado atual. O manual continua anterior ao sono; o auto opcional é separado e captura o despertar. [Validação detalhada](docs/day_one_validation.md).

## Família e hobbies — P2-07 preservada

Pai e irmã placeholders agora têm **cumprimentos de manhã e eventos distintos de apresentação dos hobbies à noite**. No mesmo interior de teste da casa/quarto, converse com E: pai apresenta **skate**, irmã apresenta **fliperama e videogames**; o quadrado roxo do cantinho de música permite descobrir **música**. Concluir a última fala registra a descoberta. **Esc/Fechar cancela** sem registrar; repetir após concluir usa uma fala curta, sem duplicar eventos. Conversas não gastam minutos nem concedem presença acadêmica.

**[HIPÓTESE TÉCNICA]** Presença doméstica de teste: pai/irmã das **06h às 08h** e das **17h às 23h**, todos os dias; cumprimentos na manhã e apresentações dos hobbies à noite. A rotina completa de trabalho/escola continua **[PENDENTE]**. Não há requisito de frequentar aula, cumprimentar primeiro ou seguir uma ordem entre os três hobbies. Perder o primeiro dia permite retomar em outra noite. Música fica disponível no quarto também antes das aulas; 04h continua reservada ao sono obrigatório.

Abra **H / botão Interesses** para consultar somente hobbies já descobertos. Conhecimento é registrado apenas após interação concluída; mudanças de horário/localização não fabricam descobertas. Os três interesses persistem no bloco opcional `home_introductions` do esquema 3, com manual antes do sono e auto opcional separados. Saves anteriores sem o bloco continuam válidos e começam sem esses eventos conhecidos. Esta etapa apresenta os hobbies: minigames, prática musical com áudio/instrumento definitivo, níveis, recompensas e arcos familiares completos pertencem às etapas seguintes.

[Pai e skate](docs/screenshots/home_father_skate.png) · [Irmã e jogos](docs/screenshots/home_sister_games.png) · [Música no quarto](docs/screenshots/home_music_discovery.png) · [Interesses descobertos](docs/screenshots/home_hobbies.png) · [Janela 960×540](docs/screenshots/home_hobbies_notebook.png)

## Primeira pergunta — P2-06 preservada

Banco em `data/questions/history.json` e **primeira pergunta na primeira aula da tarde frequentada**. Na sala, abra a agenda com E/J e escolha **Participar** entre 13h e 17h de um dia letivo. São quatro alternativas: clique ou use **1–4**, sem cronômetro. A pergunta inicial trata do ano do Grito do Ipiranga; conteúdo de teste com [fonte na Biblioteca Nacional](https://bndigital.bn.gov.br/dossies/gramaticas-e-dicionarios-do-portugues/linha-do-tempo/sobre-as-efemerides/1822-independencia-do-brasil/), sem definir a ementa final do curso.

Responder registra alternativa, acerto/erro, data/hora de entrada e turno, concede presença e avança os minutos restantes até **17h**. O professor reage com incentivo ou correção gentil; erro não acrescenta penalidade. A reação fica aberta até **Continuar/Enter/Esc**. **Cancelar/Esc antes de responder** volta à agenda sem gastar tempo ou conceder presença. Depois da escolha, fechar não apaga nem troca a resposta. J mostra o registro ao final do histórico, inclusive depois de carregar a partida. Um acerto fica registrado para o progresso acadêmico; pesos/notas/recompensas numéricas permanecem **[PENDENTE]**.

Se perder a manhã ou o primeiro dia, a pergunta espera a primeira participação elegível à tarde. Caso a apresentação do professor ainda esteja pendente, ela vem antes das alternativas; a conclusão só é gravada junto da resposta/presença. Saves do esquema 3 anteriores à P2-06 continuam válidos: ausência de `academics.question_answers` significa nenhuma resposta registrada. Manual antes do sono e auto opcional preservam a resposta separadamente; carregar um save anterior restaura o estado daquele momento. A pergunta não se repete após uma resposta, mesmo incorreta.

[Quatro alternativas](docs/screenshots/class_question.png) · [Reação ao acerto](docs/screenshots/class_question_correct.png) · [Reação ao erro](docs/screenshots/class_question_incorrect.png) · [Janela 960×540](docs/screenshots/class_question_notebook.png)

## Colega e almoço — P2-05 preservada

Primeira colega de História placeholder com **duas conversas distintas**: primeiro contato e conversa do almoço. E perto do quadrado rosa inicia o diálogo. **Concluir** registra o encontro; **Esc/Fechar** cancela e permite tentar novamente. Conversas pausam movimento/relógio e não dão presença acadêmica. Nome, aparência, biografia e falas finais continuam **[PENDENTE]**.

Rotina mínima de teste em dias letivos fora das férias: **06h–12h na sala, 12h–13h no hall, 13h–17h na sala**. A posição depende do horário, não de já conhecer o jogador. As duas conversas cabem no mesmo dia: conheça a colega antes da aula e encontre-a no hall ao meio-dia. Se o primeiro contato ocorrer no almoço, conclua a apresentação e interaja novamente para a conversa do intervalo. Se perder o horário, ela continua disponível em outro dia letivo. Não há encontro obrigatório ou conversa automática após a aula.

Datas de conclusão persistem no bloco opcional `classmate` do **esquema 3**. Saves anteriores sem o bloco iniciam os encontros como desconhecidos e mantêm horário/posição/frequência. Auto opcional grava após cada conversa nova concluída; cancelar ou repetir não grava nem duplica registros. Manual e auto continuam independentes. Nenhuma conversa é registrada apenas porque a colega mudou de sala fora de cena. Não há amizade numérica, romance ou diário novo nesta etapa.

[Primeiro contato](docs/screenshots/classmate_introduction.png) · [Conversa no almoço](docs/screenshots/classmate_lunch.png)

## Professor e primeira aula — P2-04 preservada

Professor de História placeholder na sala, com conversa de orientação e apresentação em quatro falas na primeira aula frequentada. Nome, aparência e biografia continuam **[PENDENTE]**. E perto dele abre a conversa; E no ponto de aula ou J abre a agenda. Escolha **Participar** durante um turno: a apresentação congela o relógio. Concluir a última fala com E/Enter/Continuar avança até o fim da manhã e registra presença; na primeira tarde, continua para a pergunta da P2-06 antes de concluir a aula. **Esc/Fechar cancela** e volta à agenda sem tempo gasto nem presença; pode tentar novamente.

A apresentação ocorre uma única vez por partida salva. Se perder a manhã ou o primeiro dia, aparece na primeira aula elegível que frequentar; faltas anteriores são preservadas. O save continua no **esquema 3**, com flag opcional de conclusão. Saves anteriores sem a flag iniciam com a apresentação pendente, sem mudar posição/frequência. Auto, quando habilitado, grava presença e conclusão juntos após a aula. Carregar um manual anterior restaura a apresentação pendente.

[Diálogo e primeira aula](docs/screenshots/professor_introduction.png) · [Presença após concluir](docs/screenshots/professor_first_lesson_done.png)

## Cidade e agenda — P2-03 preservada

Cidade reconstruída nas proporções da imagem fornecida pelo criador, ampliada uniformemente **6×**: planta total de **9720×5826**, com **22 locais identificados, 33 trechos de ruas/caminhos e a ferrovia**. O esqueleto anterior foi substituído. Cenário jogável geométrico: prédios, costa, rio, pontes, parques, bairros, centro e porto são placeholders; a imagem original serve de comparação no mapa M. [Planta, dados e limites](docs/reference_city.md).

A cidade continua dividida em mapas com fade. Todas as ruas que atravessam os limites têm passagens de ida e volta: **14 ligações entre regiões**, incluindo alternativas ao percurso principal. Câmera em zoom 1, quadro 128×128, movimento e escala do personagem preservados. Interiores existentes do quarto, hall e sala de História permanecem navegáveis. Os outros locais têm acesso externo e identificação; lojas, hobbies, transporte e interiores adicionais ficam para suas próprias tarefas.

**Agenda acadêmica:** manhã **09h–12h**, tarde **13h–17h**, de segunda a sexta fora das férias canônicas. Horários autorizados pelo criador para esta etapa. Na sala, espere explicitamente até a próxima aula ou participe para avançar até o encerramento. O relógio natural continua parado em interiores. Presença é registrada pela participação; encerrar um turno sem participar registra falta, inclusive durante sono e saltos futuros do calendário. J consulta hoje e os últimos sete dias. Chegada atrasada ainda permite participar antes do fim e guarda o horário de entrada; regras de penalidade/notas permanecem **[PENDENTE]**.

## Como rodar

Importe `project.godot` na Godot 4.7 e pressione **F5**. Use a janela separada do jogo para conferir a resolução real.

| Controle | Ação |
|---|---|
| WASD / setas | Caminhar em oito direções |
| E | Porta, local, NPC, colega, cama ou aula próximos |
| M | Mapa de referência com sua posição em vermelho |
| J | Consultar agenda; participar/esperar somente na sala |
| H / botão Interesses | Consultar apenas os hobbies descobertos |
| Esc | Fechar painel; sono obrigatório não pode ser cancelado |
| E / Enter no diálogo | Avançar conversa |
| 1–4 / mouse na pergunta | Escolher alternativa; Enter fecha a reação |
| 1 / 2 na escolha de sono | Salvar e dormir / dormir sem manual; mouse também disponível |
| T | Comparar mobília 32/64; reposiciona e reinicia medição |
| F | Mostrar/ocultar quadro e colisão dos pés |
| R / botão | Atividade provisória de 60 minutos |
| C / botão | Calendário debug, nome, autosave e carregar slots |
| F11 / botão | Alternar fullscreen e janela sem ampliar o personagem |

**Caminho inicial:** saia de casa em Residential Block. Siga para oeste até a avenida vertical e suba até a rua ao sul da estação. E na passagem leva ao centro; siga para oeste, E para a região da Horizonte, atravesse a ponte e desça pelo campus até o prédio principal. E entra no hall. Siga à direita e depois acima para a sala; E no ponto de aula abre a agenda. Use **Esperar** para chegar às 09h, **Participar**, conclua a apresentação do professor para avançar às 12h e depois espere até 13h para o turno da tarde. Outras passagens permitem explorar o norte, o sul e o porto sem voltar à mesma interseção.

**Colega e almoço:** na sala, aproxime-se do quadrado rosa ao lado direito das carteiras inferiores e converse com E. Depois da aula da manhã, saia para o hall e caminhe até a área central de convivência: a colega estará ali das 12h às 13h. Converse antes de esperar até a aula das 13h. Caso ainda não a conheça, a primeira interação apresenta a colega e a seguinte abre a conversa de almoço.

**Família e hobbies:** antes de sair às 06h, pai fica à esquerda e irmã à direita no interior de teste; E perto de cada um abre seu cumprimento. Ao retornar após 17h, interaja novamente para os convites de skate e videogames. Para música, caminhe pelo centro do quarto até o quadrado roxo acima do ponto inicial, entre cama e mesa. Nenhuma descoberta é obrigatória para sair ou dormir. Para conferir rapidamente a noite, C permite avançar o calendário; isso registra as aulas não frequentadas como faltas.

**Tempo e sono:** exterior: 1 segundo real = 1 minuto do jogo. Interiores, conversas, mapa, agenda e fades pausam o avanço natural. Atividades avançam minutos explicitamente. Às 04h há sono obrigatório; fora de casa retorna e acorda às 12h; em casa respeita o despertador. C mostra o calendário clicável, permite saltar apenas para o futuro e registra as aulas perdidas; não simula cada noite intermediária. Filtros: primavera rosa, verão azul, outono laranja e inverno branco.

## Dados e saves

- `data/world/reference_city.json`: fonte de coordenadas da referência, escala, costa/rio, vias, locais e fachadas.
- `data/world/regions.json`: recortes, portas/spawns, percurso de medição e interiores.
- `data/schedules/academic.json`: turnos e horários; textos usam chaves em `localization/lab.csv`.
- `scripts/world/reference_city.gd` / `reference_renderer.gd`: geometria, colisões e desenho dos exteriores; `city_area.gd` mantém o instanciamento compartilhado.
- `scripts/core/academic_schedule.gd` / `scripts/ui/academic_panel.gd`: agenda, eventos, frequência e flag de apresentação.
- `data/dialogues/professor_*.tres`: falas por chaves; `DialoguePanel.finished` distingue conclusão de cancelamento, integrado pelo controlador do laboratório.
- `data/npcs/classmate.json` / `data/dialogues/classmate_*.tres`: horários, posições e diálogos da colega. `ClassmateEncounter` separa disponibilidade pelo relógio dos encontros efetivamente presenciados.
- `data/questions/history.json` / `scripts/core/class_question_bank.gd`: questões com IDs estáveis, quatro opções, gabarito, reação, explicação e fonte. Não reutilize IDs para outra pergunta/alternativa; reinicie após editar o banco.
- `scripts/ui/class_question_panel.gd`: escolhas/reação; `AcademicSchedule.question_answers` guarda o resultado, validado junto das presenças pelo save existente.
- `data/events/home_introductions.json` / `data/dialogues/father_*.tres`, `sister_*.tres`, `music_*.tres`: atores, posições, janelas de teste, três hobbies e falas por chaves.
- `scripts/core/home_introductions.gd`, `scripts/world/home_event_point.gd` e `scripts/ui/hobbies_panel.gd`: eventos concluídos/conhecimento, interação contextual e consulta dos interesses. O NPC genérico do quarto foi substituído pelo pai; o NPC de laboratório da rua permanece para os testes anteriores.

| Área | Dimensões |
|---|---|
| Quarto | 960×640 |
| Leste / bairro / praias / porto | 4200×5826 |
| Centro / estação | 2460×5826 |
| Oeste / Horizonte / parque / camping | 3660×5826 |
| Hall | 1600×1100 |
| Sala de História | 1400×1000 |

Os recortes têm pequenas sobreposições para as transições; não somar suas larguras para obter a planta total. Reinicie o jogo após alterar JSON.

Manual em `user://saves/slot_01/manual.json`, auto em `auto.json`, preferência separada em `user://settings.json`. Windows padrão: `%APPDATA%\Godot\app_userdata\AnotherLife`. Esquema **3**, com migração de **1 e 2**: conserva relógio/fração, nome, alarme e tile; reposiciona áreas externas na entrada segura da mesma região e inicia o registro acadêmico no horário carregado, sem inventar faltas anteriores. Não regrava o original ao carregar. Saves atuais preservam posição exata e frequência; manual e auto nunca substituem um ao outro.

Manual é oferecido antes de dormir, retomando a escolha ao carregar. Auto é opcional/desligado por padrão, grava após despertar, transição e espera/participação acadêmica. Nenhum slot é carregado ou sobrescrito automaticamente ao iniciar. Faltas usam um intervalo de acompanhamento e presenças explícitas, evitando milhões de registros nos saltos de calendário.

## Validação reproduzível

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/city_university_test.gd
godot --headless --path . --script res://tests/academic_schedule_test.gd
godot --headless --path . --script res://tests/professor_intro_test.gd
godot --headless --path . --script res://tests/classmate_encounter_test.gd
godot --headless --path . --script res://tests/class_question_test.gd
godot --headless --path . --script res://tests/home_introductions_test.gd
godot --headless --path . --script res://tests/day_one_flow_test.gd
godot --headless --path . --script res://tests/scale_lab_test.gd
godot --headless --path . --script res://tests/time_manager_test.gd
godot --headless --path . --script res://tests/calendar_vacations_test.gd
godot --headless --path . --script res://tests/interior_time_test.gd
godot --headless --path . --script res://tests/timed_action_test.gd
godot --headless --path . --script res://tests/dialogue_test.gd
godot --headless --path . --script res://tests/sleep_save_test.gd
godot --headless --path . --script res://tests/travel_display_test.gd
```

Nesta máquina, substitua `godot` por `& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'`. Todos os runners usam diretórios isolados `user://test_runs/`; não alteram os slots da partida. Logs ignorados em `test-results/`.

Runner urbano: física de caminhada real, consulta de colisões nas vias, conectividade dos 22 locais, passagens alternativas, interiores e fade. Aceleração 6× somente no teste. Acrescente `-- --walk` para medir a ida na velocidade real. Para seis capturas, execute sem `--headless` e acrescente `-- --walk --capture`. A visão geral usa câmera de inspeção apenas no runner. `signposted_journey_test.gd` é alias da suíte urbana. Agenda: botões reais de espera/participação, eventos por minuto, faltas, férias, sono, debug e saves/migrações. Variante sem `--headless`, com `-- --capture`, grava a agenda.

Validação da P2-08 em **16/10/2026**: **1032 verificações, zero falhas** — 141 do fluxo completo (inclui quatro capturas), 109 domésticas, 100 da questão, 80 da colega, 47 do professor, 58 acadêmicas, 227 urbanas e 270 de regressão. Godot **4.7.2** oficial; importação/editor sem erros. As mensagens de erro de diretório na seção de falhas são provocadas intencionalmente para verificar recuperação de save, sem falha nas verificações. Execute o runner do Dia 1 sem `--headless`, com `-- --walk --capture`, para repetir o primeiro percurso em velocidade normal e gravar quatro capturas. Os demais percursos são acelerados somente no runner. [Critérios, comandos e limites](docs/day_one_validation.md); resultados completos no último registro de [decisions.md](docs/decisions.md). Sem playtest humano.

A medição da cidade na P2-03 permanece referência histórica: ida em velocidade normal de 42,360 s, +39 minutos, chegada 06:39, margem 141 minutos até 09h. Na P2-08, o primeiro Dia 1 inteiro também foi executado em velocidade normal: a ida exterior levou 41,548 s de parede, chegada 06:40 e margem 140 minutos até 09h, com interações/fades na rota. A validação final com atalhos de sono foi repetida com aceleração de teste; não somar execuções repetidas à contagem.

## Próximo passo

**P3-01 concluída. Próxima tarefa: P3-02 — mesada semanal e saldo inicial de 100**. Valor da mesada e nome/símbolo da moeda continuam **[PENDENTE]**, a resolver nessa tarefa. Minigames, avaliações/seminários, notas finais e elenco completo continuam para etapas posteriores. **[PENDENTE]** Tile definitivo, instrumento musical, arte final, nomes/layout finais e consequências acadêmicas do atraso. Referência histórica de calendário inicial: primavera 1, ano 1, segunda-feira, 06h; origem semanal configurável. Sem energia/crafting. Drowned preservado.
