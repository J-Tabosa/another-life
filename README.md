# Another Life / Outra Vida

Protótipo em **Godot 4.7 / GDScript**, validado na **4.7.2 oficial**. Cânone e roadmap no [GDD](docs/ANOTHER_LIFE_GDD_DIA0.md), instruções em [AGENTS.md](AGENTS.md) e [migração da engine](docs/godot_4_7_migration.md).

## Entrega atual — P2-04

Professor de História placeholder na sala, com conversa de orientação e apresentação em quatro falas na primeira aula frequentada. Nome, aparência e biografia continuam **[PENDENTE]**. E perto dele abre a conversa; E no ponto de aula ou J abre a agenda. Escolha **Participar** durante um turno: a apresentação congela o relógio e, ao concluir a última fala com E/Enter/Continuar, avança até o fim do turno e registra presença. **Esc/Fechar cancela** e volta à agenda sem tempo gasto nem presença; pode tentar novamente.

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
| E | Porta, local, NPC, cama ou aula próximos |
| M | Mapa de referência com sua posição em vermelho |
| J | Consultar agenda; participar/esperar somente na sala |
| Esc | Fechar painel; sono obrigatório não pode ser cancelado |
| E / Enter no diálogo | Avançar conversa |
| T | Comparar mobília 32/64; reposiciona e reinicia medição |
| F | Mostrar/ocultar quadro e colisão dos pés |
| R / botão | Atividade provisória de 60 minutos |
| C / botão | Calendário debug, nome, autosave e carregar slots |
| F11 / botão | Alternar fullscreen e janela sem ampliar o personagem |

**Caminho inicial:** saia de casa em Residential Block. Siga para oeste até a avenida vertical e suba até a rua ao sul da estação. E na passagem leva ao centro; siga para oeste, E para a região da Horizonte, atravesse a ponte e desça pelo campus até o prédio principal. E entra no hall. Siga à direita e depois acima para a sala; E no ponto de aula abre a agenda. Use **Esperar** para chegar às 09h, **Participar**, conclua a apresentação do professor para avançar às 12h e depois espere até 13h para o turno da tarde. Outras passagens permitem explorar o norte, o sul e o porto sem voltar à mesma interseção.

**Tempo e sono:** exterior: 1 segundo real = 1 minuto do jogo. Interiores, conversas, mapa, agenda e fades pausam o avanço natural. Atividades avançam minutos explicitamente. Às 04h há sono obrigatório; fora de casa retorna e acorda às 12h; em casa respeita o despertador. C mostra o calendário clicável, permite saltar apenas para o futuro e registra as aulas perdidas; não simula cada noite intermediária. Filtros: primavera rosa, verão azul, outono laranja e inverno branco.

## Dados e saves

- `data/world/reference_city.json`: fonte de coordenadas da referência, escala, costa/rio, vias, locais e fachadas.
- `data/world/regions.json`: recortes, portas/spawns, percurso de medição e interiores.
- `data/schedules/academic.json`: turnos e horários; textos usam chaves em `localization/lab.csv`.
- `scripts/world/reference_city.gd` / `reference_renderer.gd`: geometria, colisões e desenho dos exteriores; `city_area.gd` mantém o instanciamento compartilhado.
- `scripts/core/academic_schedule.gd` / `scripts/ui/academic_panel.gd`: agenda, eventos, frequência e flag de apresentação.
- `data/dialogues/professor_*.tres`: falas por chaves; `DialoguePanel.finished` distingue conclusão de cancelamento, integrado pelo controlador do laboratório.

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
godot --headless --path . --script res://tests/scale_lab_test.gd
godot --headless --path . --script res://tests/time_manager_test.gd
godot --headless --path . --script res://tests/interior_time_test.gd
godot --headless --path . --script res://tests/timed_action_test.gd
godot --headless --path . --script res://tests/dialogue_test.gd
godot --headless --path . --script res://tests/sleep_save_test.gd
godot --headless --path . --script res://tests/travel_display_test.gd
```

Nesta máquina, substitua `godot` por `& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'`. Todos os runners usam diretórios isolados `user://test_runs/`; não alteram os slots da partida. Logs ignorados em `test-results/`.

Runner urbano: física de caminhada real, consulta de colisões nas vias, conectividade dos 22 locais, passagens alternativas, interiores e fade. Aceleração 6× somente no teste. Acrescente `-- --walk` para medir a ida na velocidade real. Para seis capturas, execute sem `--headless` e acrescente `-- --walk --capture`. A visão geral usa câmera de inspeção apenas no runner. `signposted_journey_test.gd` é alias da suíte urbana. Agenda: botões reais de espera/participação, eventos por minuto, faltas, férias, sono, debug e saves/migrações. Variante sem `--headless`, com `-- --capture`, grava a agenda.

Validação da P2-04 em **15/10/2026**: **601 verificações, zero falhas** — 47 do professor (inclui duas capturas), 57 acadêmicas, 227 urbanas e 270 de regressão. Godot **4.7.2** oficial; importação/editor sem erros. Runner do professor cobre teclado/mouse, cancelamento, conclusão, faltas, compatibilidade e persistência. Execute sem `--headless`, com `-- --capture`, para reproduzir as duas capturas. Resultados e limites no último registro de [decisions.md](docs/decisions.md). Sem playtest humano.

A medição da cidade na P2-03 permanece referência histórica: ida em velocidade normal de 42,360 s, +39 minutos, chegada 06:39, margem 141 minutos até 09h. Na P2-04 a circulação foi repetida com aceleração apenas de teste; não houve nova medição de parede em velocidade normal.

## Próximo passo

**P2-05 — primeira colega/amiga e almoço**, com duas oportunidades de conversa no mesmo dia. Não há avaliação, quiz, notas ou elenco completo nesta entrega. **[PENDENTE]** Tile definitivo, arte final, nomes/layout finais e consequências acadêmicas do atraso. Referência histórica de calendário inicial: primavera 1, ano 1, segunda-feira, 06h; origem semanal configurável. Sem energia/crafting. Drowned preservado.
