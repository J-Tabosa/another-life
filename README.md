# Another Life / Outra Vida

Protótipo em **Godot 4.5 / GDScript**, conforme o [GDD do Dia 0](docs/ANOTHER_LIFE_GDD_DIA0.md) e [AGENTS.md](AGENTS.md).

## Entrega atual

**P1-06 — diálogo/interação mínimos**, sobre o TimeManager e o laboratório da primeira sessão técnica (seção 15 do GDD). Cena principal: `scenes/lab/scale_lab.tscn`.

- Personagem placeholder: cada quadro tem 128×128 px, corpo com margem transparente e colisão nos pés.
- Movimento em oito direções, diagonal normalizada e animação/idle em quatro direções.
- Dois mapas separados, câmera de seguimento, paredes e mobília com colisão.
- Porta interativa com destino e marcador de entrada; personagem preservado ao trocar de mapa.
- Comparação de tiles 32/64, porta, cama, mesa e fachada; arte e disposição provisórias.
- Labels em português por chaves traduzíveis. Inglês e espanhol entram antes da beta.
- Relógio externo: 1 segundo real = 1 minuto do jogo; data/hora visíveis no rodapé, preservadas nas transições. A ativação natural é restrita à rua.
- No quarto, o relógio natural congela enquanto o personagem continua andando. Sair preserva a fração de segundo anterior, sem descontar o tempo passado dentro.
- Minutos absolutos e eventos por minuto; meia-noite, 30 dias/estação, 120 dias/ano e continuidade dos dias da semana. Sem férias/agendas nesta tarefa.
- Atividade placeholder de 60 minutos, acionada por R ou pelo botão: avança exatamente uma hora mesmo no quarto, preservando a pausa natural. Duração e chave de texto vêm de `data/activities/lab_activity.tres`, um recurso `TimedAction` reutilizável.
- `TimeManager.advance_minutes()` valida antes de avançar e emite os minutos/dias intermediários em ordem. A fração acumulada do tempo externo é preservada.
- NPC quadrado placeholder no quarto e na rua: aproxime-se e pressione E. A conversa tem duas falas traduzíveis em `data/dialogues/lab_conversation.tres`; painel reutilizável, sem consumir tempo.
- Durante diálogo, movimento, portas e atividade ficam bloqueados. Ao fechar, o tempo natural permanece parado no quarto e retoma na rua, preservando sua fração de segundo.

**[PROPOSTA]** O teste começa na primavera 1, ano 1, às 06h. Segunda-feira é a origem provisória; `weekday_offset` do nó `TimeManager` permite escolher outra origem enquanto a decisão canônica está pendente.

**[PROPOSTA]** Enquanto P1-07 não implementa o sono, ações que terminariam às 04h ou depois são recusadas antes de começar. Por exemplo, às 03:30 a atividade de 60 minutos não avança o relógio. **[PENDENTE]** UX definitiva de interrupção/truncamento no limite das 04h.

## Como rodar

1. Importe `project.godot` na **Godot 4.5**.
2. Aguarde a importação dos recursos e pressione **F6** para executar a cena-laboratório ou **F5** para executar o projeto.
3. Caminhe até a porta e pressione **E** para sair/entrar.
4. Aproxime-se do quadrado azul à esquerda do jogador e pressione **E** para conversar. Use **E/Enter** ou o botão para continuar; **Esc** ou o botão para fechar.

| Tecla | Ação |
|---|---|
| WASD / setas | Caminhar |
| E | Interagir com porta/NPC próximo; avançar diálogo |
| Enter / Esc | Avançar / fechar diálogo |
| T | Alternar tiles/objetos entre 32 e 64; reposiciona em ponto seguro |
| F | Mostrar/ocultar quadro 128×128 e colisão dos pés |
| R / botão de atividade | Avançar 60 minutos por uma atividade provisória |

A versão Steam encontrada nesta máquina é 4.7.2; a validação desta entrega usou a **Godot 4.5 oficial**, baixada em `.tools/` (ignorada pelo Git). Não depende de Steam ou de Drowned.

## Validação reproduzível

Com o executável Godot 4.5 no PATH:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/scale_lab_test.gd
godot --headless --path . --script res://tests/time_manager_test.gd
godot --headless --path . --script res://tests/interior_time_test.gd
godot --headless --path . --script res://tests/timed_action_test.gd
godot --headless --path . --script res://tests/dialogue_test.gd
```

Nesta máquina:

```powershell
& '.\.tools\godot-4.5\Godot_v4.5-stable_win64_console.exe' --headless --path . --script res://tests/scale_lab_test.gd
& '.\.tools\godot-4.5\Godot_v4.5-stable_win64_console.exe' --headless --path . --script res://tests/time_manager_test.gd
& '.\.tools\godot-4.5\Godot_v4.5-stable_win64_console.exe' --headless --path . --script res://tests/interior_time_test.gd
& '.\.tools\godot-4.5\Godot_v4.5-stable_win64_console.exe' --headless --path . --script res://tests/timed_action_test.gd
& '.\.tools\godot-4.5\Godot_v4.5-stable_win64_console.exe' --headless --path . --script res://tests/dialogue_test.gd
```

Para reproduzir capturas com renderização, execute o runner **sem `--headless`**, acrescentando `-- --capture`. As imagens vão para `docs/screenshots/`.

O runner exercita movimento com o servidor de física, oito direções, idle, quadros, paredes, cama/mesa em ambas as escalas, aproximação física e interação nas portas, seis ciclos quarto↔rua, marcadores de entrada e ausência de mapas duplicados. Ele retorna código 1 em caso de falha.

O runner `time_manager_test.gd` verifica minutos inteiros/fracionários, equivalência de 3600 frames a 60 FPS, eventos intermediários em ordem, meia-noite, estações, ano, semanas e origem configurável. Acrescente `-- --realtime` para medir também **60 segundos reais** com o relógio de produção ativado na rua. `--capture` salva `docs/screenshots/time_clock.png` e exige execução sem `--headless`.

O runner `interior_time_test.gd` verifica congelamento no quarto, movimento com relógio parado, portas, preservação de frações, 20 ciclos de entrada/saída e passagem de meia-noite apenas ao retomar tempo externo. Inclui uma espera real curta com ticks automáticos; acrescente `-- --realtime` para esperar **60 segundos reais dentro do quarto** e conferir que o relógio avança novamente ao sair pela porta. O intervalo real é medido por contador monotônico, separado do calendário do jogo.

Para conferir manualmente: anote a hora ao entrar no quarto, caminhe e espere; a hora fica igual. Saia com E: o rodapé muda para “Tempo externo” e volta a avançar.

O runner `timed_action_test.gd` verifica duração exata dentro/fora, frações, virada de data/ano, ordem dos eventos, recusa sem efeitos no limite das 04h, proteção contra avanço recursivo e integração com tecla R/botão/HUD. `--capture` salva `docs/screenshots/timed_action.png` e exige execução sem `--headless`. Na cena inicial, pressione R: 06:00 vira 07:00 e esperar no quarto conserva 07:00.

O runner `dialogue_test.gd` verifica proximidade física, propagação de teclado/cliques na GUI, falas em ordem, cancelamento, bloqueio de ações, pausa no quarto/rua, frações, retomada e interação em 32/64. Inclui 2 segundos reais de conversa externa com callbacks automáticos; `-- --realtime` amplia para 60 segundos. `--capture` salva `dialogue_room.png` e `dialogue_street.png` com renderização, exigindo execução sem `--headless`.

## Limites e próximo passo

As falas e os NPCs são placeholders técnicos. Escolhas/ramificações, elenco canônico, sono, save, universidade, férias e hobbies continuam nas tarefas posteriores. A escolha de nome do protagonista será feita no fluxo de nova partida; o laboratório não fixa nome canônico.

Veja [decisões, capturas e progresso](docs/decisions.md). Próxima tarefa: **P1-07 — sono, despertador e limite das 04h**, com casos dentro/fora de casa e despertar às 12h. O relógio natural ainda pode passar das 04h; avanços explícitos continuam protegidos contra o próximo limite pela regra provisória de P1-05. Antes de arte em massa, confirmar a escala provisória com o criador. **P0-03 permanece pendente** de acesso explícito ao projeto Drowned.
