# Another Life / Outra Vida

Protótipo em **Godot 4.7 / GDScript**, validado na **4.7.2 oficial**, conforme o [GDD](docs/ANOTHER_LIFE_GDD_DIA0.md) e [AGENTS.md](AGENTS.md). Referências à 4.5 no GDD são históricas; veja a [verificação da migração](docs/godot_4_7_migration.md).

## Entrega atual

**P2-01 — trajeto residencial → Horizonte sinalizado**, sobre o laboratório com sono/salvamentos da P1. Cena principal: `scenes/lab/scale_lab.tscn`.

Placas na rua, a cada 640 px do percurso e no pátio orientam a ida e a volta. A medição começa ao sair de casa e termina no retângulo em frente à entrada do prédio; entrar apenas no pátio não conclui o trajeto. O HUD informa chegada e margem em relação às 09h. Trata-se de referência de teste, sem agenda acadêmica, frequência ou bloqueio por atraso. Começar diretamente no percurso produz uma medição identificada como parcial. Saltar datas, carregar, retornar ao quarto ou usar T reinicia a medição.

- Personagem placeholder com quadro 128×128, corpo visível 40×56 e colisão nos pés; movimento em oito direções e animação/idle em quatro.
- Tela cheia inicial, câmera com zoom 1 e stretch desativado: resolução maior mostra mais cenário, mantendo o tamanho em pixels. HUD e painéis acompanham a janela. Não há escalonamento automático para monitores de densidade muito alta.
- Quarto, rua, percurso de 12.800×1.600 e pátio da Universidade Horizonte de 2.400×1.600, por transição. Edificações, mobília, NPCs e placas são placeholders. Tiles 32/64 para comparação.
- Tempo externo: 1 segundo real = 1 minuto; interiores e diálogos congelam os ticks naturais. Atividade provisória de 60 minutos avança tempo explicitamente.
- Calendário com 30 dias/estação, 120 dias/ano e dias da semana contínuos. Debug clicável para avançar data/hora e filtros: primavera rosa, verão azul, outono laranja, inverno branco claro. O filtro afeta o mundo; a interface permanece legível.
- Cama interativa para sono voluntário, despertador com horas/minutos, opção de salvar antes de dormir e cancelamento do sono voluntário.
- Às 04h o relógio natural para exatamente no limite, inclusive após um frame muito longo. Sono obrigatório não pode ser cancelado: fora retorna ao quarto e desperta às 12h do mesmo dia; em casa usa o próximo toque do despertador.
- Salvamentos manual e automático separados; autosave desligado por padrão, habilitado no painel C. Dados inválidos são recusados antes de alterar a partida. Carregar o manual feito ao dormir retoma a escolha de sono anterior ao avanço do relógio.
- Textos por chaves traduzíveis em pt_BR. Inglês/espanhol permanecem pendentes para a beta.

## Como rodar e testar manualmente

Importe `project.godot` na **Godot 4.7**, aguarde a importação e pressione **F5**. Para testar a resolução real da tela, use uma janela de jogo separada do editor; o painel de jogo embutido pode redimensionar sua prévia.

| Controle | Ação |
|---|---|
| WASD / setas | Caminhar |
| E | Interagir com porta, NPC ou cama próximos |
| E / Enter / Esc no diálogo | Avançar / avançar / fechar |
| T | Comparar tiles 32/64, reposicionando em ponto seguro |
| F | Mostrar/ocultar quadro 128×128 e colisão |
| R / botão | Atividade provisória de 60 minutos |
| C / botão | Calendário de debug, nome para testar persistência, autosave e carregar cada slot |
| F11 / botão | Alternar tela cheia e janela |

**Sono:** aproxime-se da cama e use E. Ajuste o despertador e escolha salvar e dormir ou dormir sem salvar. Para conferir o limite, saia para a rua, abra C, escolha 03:59 e clique numa data disponível; aguarde um segundo após o salto. O quarto e a oferta de salvamento aparecem às 04h, sem opção de cancelar; o despertar é às 12h. Para conferir em casa, o debug pode posicionar o relógio exatamente às 04h dentro do quarto.

**Calendário:** selecione ano, estação e horário, depois clique no dia desejado. Datas anteriores ao relógio atual ficam desabilitadas. Abrir o painel congela o tempo; Esc fecha. O salto não executa agendas, atividades ou noites intermediárias. Um destino exatamente às 04h respeita o sono obrigatório. O quadro contém os 30 dias alinhados com seus dias da semana.

**Percurso:** saia do quarto usando E na porta; siga a placa à direita da rua e use E na passagem. Caminhe para a direita pelas placas até a passagem da faculdade; use E para entrar no pátio. Siga à direita e depois para cima, conforme a placa, até o retângulo em frente à fachada. O HUD registra horário de chegada, segundos e minutos gastos, além da margem até as 09h. Para voltar, siga as placas do bairro para a esquerda e a indicação de casa na rua. Velocidade atual de 180 px/s; dimensões e escala preservadas. Esperas e menus entram nos segundos decorridos, enquanto os minutos respeitam as pausas. Uma saída às 08h demonstra chegada tardia sem bloquear a exploração. A medição anterior de 68,717 s referia-se só ao percurso grande até o pátio; o teste da P2-01 cobre também rua e entrada do prédio.

## Salvamentos

Partida em `user://saves/slot_01/manual.json` e `auto.json`; preferência de autosave em `user://settings.json`. No Windows padrão, `user://` corresponde a `%APPDATA%\Godot\app_userdata\AnotherLife`. Consulte Projeto → Abrir pasta de dados do usuário no editor.

O manual guarda o estado **antes do sono**; o automático, quando habilitado, guarda após acordar e ao trocar de mapa. Iniciar o laboratório não sobrescreve o auto existente nem carrega automaticamente: use C e o botão do slot desejado. Um auto não substitui um manual.

Esquema versão 1: minutos/fração e origem da semana, nome escolhido no campo de teste, área/posição, despertador/contexto do sono e tile. Somente sistemas já implementados são persistidos; futuros estados acadêmicos, sociais e inventário precisarão ampliar o esquema. Escrita em temporário seguida de renomeação na mesma pasta; erro mantém a oferta aberta para tentar novamente ou dormir sem salvar.

## Validação reproduzível

Com o executável Godot 4.7 no PATH:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/scale_lab_test.gd
godot --headless --path . --script res://tests/time_manager_test.gd
godot --headless --path . --script res://tests/interior_time_test.gd
godot --headless --path . --script res://tests/timed_action_test.gd
godot --headless --path . --script res://tests/dialogue_test.gd
godot --headless --path . --script res://tests/sleep_save_test.gd
godot --headless --path . --script res://tests/travel_display_test.gd
godot --headless --path . --script res://tests/signposted_journey_test.gd
```

Nesta máquina, substitua `godot` por `& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'`; engine e logs em `test-results/` ignorados pelo Git. Não depende de Steam ou Drowned.

Resultados da entrega P1, em 12/10/2026 (novas validações da P2-01 abaixo):

- Sono/save: **51 verificações, zero falhas**, com cama 32/64, 04h dentro/fora, despertador, eventos, cliques de GUI, carregar/salvar, arquivos independentes, preferências, arquivos inválidos, calendário e filtros.
- Regressões: laboratório **60**, relógio **41**, interiores **42**, atividades **34** e diálogo **30**, todas sem falhas na 4.7.2. Esperas reais curtas confirmam congelamento no quarto/diálogo externo; medições anteriores de 60 segundos não foram repetidas nesta entrega.
- Exibição/percurso: **12 verificações, zero falhas**, escala/HUD em 960×540, 1366×768 e 1920×1080, física e portas. Acrescente `-- --walk` para rota completa com ticks naturais: **14 verificações, zero falhas** no ensaio executado.
- Sete capturas renderizadas: runner `travel_display_test.gd` sem `--headless`, acrescentando `-- --capture`: **19 verificações, zero falhas**. Imagens em `docs/screenshots/`, incluindo calendário, sono, tela cheia e estações, inspecionadas visualmente.

Sono/save e percurso usam diretórios isolados em `user://test_runs/`, sem escrever nos slots da partida. Runners retornam código 1 em caso de falha. Caminhada completa leva aproximadamente 70 segundos. Não foi realizado playtest humano.

### Validação da P2-01

`signposted_journey_test.gd`: caminhada com física real e transições por E, placas de ida/volta, chegada antes das 09h, retorno, partida tardia, escala 32/64 e reinício da medição por debug/load/T. O runner padrão acelera a física e o relógio com `Engine.time_scale = 8` para repetir os percursos; seus segundos de parede não representam a proporção real do jogo.

Acrescente `-- --walk` para executar a primeira ida na proporção real 1s = 1 minuto. O retorno e a saída tardia continuam acelerados. Para capturas, rode sem `--headless` e acrescente `-- --walk --capture`: placas da rua/percurso/pátio e chegada em 1280×720 e 960×540. Testes usam `user://test_runs/`, sem alterar seus saves. Resultados da entrega em [decisions.md](docs/decisions.md).

Entrega de 13/10/2026: **59 verificações padrão** e **65 no ensaio renderizado**, zero falhas; **153 verificações de regressão**, zero falhas. Ida em tempo real: **79,129 s**, chegada **07:19**, **101 minutos antes das 09h**, mantendo a proporção 1s = 1 minuto. As cinco capturas foram inspecionadas, e o HUD cabe em três linhas em 960×540. Importação/editor headless na Godot 4.7.2 sem erros; sem playtest humano.

## Hipóteses e próximo passo

**[PROPOSTA]** Início na primavera 1, ano 1, 06h, segunda-feira; origem da semana configurável. Alarme inicial 06h; se coincidir com o instante de deitar, vale o toque do dia seguinte. Ao acordar, a fração natural reinicia em zero. Atraso restante de um frame que atinge 04h é descartado. Autosave em transição/despertar e campo de nome no debug são UX de laboratório.

Ações comuns que terminariam às 04h ou depois continuam recusadas antes de iniciar, conforme P1-05. **[PENDENTE]** UX definitiva de atividades no limite e consequências do sono curto; não foi inventado efeito de fadiga nem barra de energia. Alarmes exatamente às 04h seguem o horário selecionado; esclarecer esse caso de fronteira antes do balanceamento final.

Próxima tarefa: **P2-02 — cena da universidade e sala de aula**. O percurso/pátio permanecem provisórios; chegar ao marcador não entra em um interior nem inicia aula. Grade/presença ficam para P2-03. A referência das 09h usada na medição não simula fins de semana/férias, pois esses calendários pertencem a tarefas posteriores. **P0-03 permanece pendente** de acesso explícito ao Drowned; seu repositório não foi alterado. Veja o [registro de decisões](docs/decisions.md).
