# Another Life / Outra Vida

Protótipo em **Godot 4.7 / GDScript**, validado na **4.7.2 oficial**. Cânone e roadmap no [GDD](docs/ANOTHER_LIFE_GDD_DIA0.md); instruções em [AGENTS.md](AGENTS.md); [migração da engine](docs/godot_4_7_migration.md). As referências à 4.5 no GDD são históricas.

## Entrega atual

**P2-02 — universidade e sala de aula**, com a reformulação urbana solicitada pelo criador. Principal: `scenes/lab/scale_lab.tscn`.

- Bairro residencial com praça, casas de proporções variadas, ruas secundárias e um circuito alternativo.
- Via do rio com curvas, ponte, rampa/escadaria entre taludes e ramificações para locais futuros. O corredor reto anterior foi substituído.
- Campus com pátio, circuito alternativo, desnível e espaços reservados para biblioteca/café.
- Hall navegável da Horizonte, guia NPC placeholder, sala de História com carteiras, conversa e ponto de aula. A atividade acadêmica real entra em P2-03; nenhum registro de presença/notas é criado aqui.
- Fade-out → troca de mapa sob tela preta → fade-in nas portas, carregamento e retorno obrigatório para casa. Durante fade, movimento/interações/ticks naturais ficam bloqueados e a fração do relógio é preservada.
- Placas somente nos cruzamentos; locais e marcos ajudam a navegar. Nenhuma arte final ou asset externo foi adicionado.
- Escala preservada: quadro 128×128, corpo 40×56, câmera zoom 1 e fullscreen sem stretch. Resolução maior mostra mais cenário. T continua comparando mobília 32/64 no quarto; o esqueleto urbano usa geometria com dimensões fixas, ainda sem tilemap de arte.
- Sono, despertador, limite das 04h, calendário clicável, filtros sazonais e saves manual/auto separados continuam disponíveis.

Veja o [esqueleto das regiões, referências e imagens](docs/city_layout.md). Layout e locais reservados são **[PROPOSTA]**, não cânone geográfico definitivo. Os desníveis são representados em 2D por patamares, barreiras e passagens de rampa; não existe física 3D, salto ou eixo de altura do personagem.

## Como rodar

Importe `project.godot` na **Godot 4.7** e pressione **F5**. Use janela de jogo separada do editor para conferir a resolução real da tela.

| Controle | Ação |
|---|---|
| WASD / setas | Caminhar em oito direções |
| E | Porta, NPC, cama ou ponto de aula próximos |
| E / Enter / Esc no diálogo | Avançar / avançar / fechar |
| T | Comparação 32/64 e reposicionamento seguro; reinicia a medição |
| F | Mostrar/ocultar quadro e colisão dos pés |
| R / botão | Atividade provisória de 60 minutos |
| C / botão | Calendário debug, nome de teste, autosave e carregar slots |
| F11 / botão | Alternar fullscreen e janela |

**Ida:** saia do quarto com E, siga a rua curva pela praça até a passagem ao sul/leste do bairro. Use E para entrar na via do rio. Atravesse a ponte, siga a curva para a rampa ao norte e continue pela rua sinuosa até o acesso do campus no nordeste. No campus, siga o caminho principal pelo pátio e pela rampa até a fachada; E entra na Horizonte.

**Faculdade:** explore o hall, converse com o quadrado do guia e siga o corredor à direita e depois para cima. Use E para entrar na sala de História. Caminhe pelo corredor entre as carteiras e use E no ponto de aula. O diálogo informa que a atividade estará disponível em uma próxima versão. Volte pelas mesmas portas. Interiores congelam o relógio natural, com liberdade para andar/conversar.

**Orientação:** ruas secundárias chegam aos espaços reservados de comércio, escola, música, fliperama, skate, biblioteca/café e acessos futuros de calçadão/floresta. Esses rótulos não ativam novos sistemas ou mapas completos. O bairro e o campus têm circuitos alternativos, e rio/taludes impedem cortar caminho fora de ponte/rampa. O jogador pode caminhar pelo terreno livre e chegar tarde.

**Medição:** começa na saída de casa e termina diante da entrada do prédio. HUD mostra chegada e margem até as 09h como referência de laboratório. Não simula calendário de aulas, fins de semana/férias ou frequência. Segundos incluem pausas/fades; minutos seguem as pausas naturais. Debug/load/T/retorno ao quarto reiniciam o ensaio; começar diretamente na via do rio identifica um trajeto parcial.

**Sono/calendário:** E na cama configura o alarme e oferece salvar/dormir. C permite escolher ano/estação/horário e clicar em uma data futura. O salto não simula noites intermediárias; destino exatamente às 04h dispara sono obrigatório. Fora de casa, inclusive dentro da universidade, retorna e acorda às 12h do mesmo dia. Em casa respeita o próximo despertador. Primavera rosa, verão azul, outono laranja e inverno branco são filtros técnicos.

## Dados e salvamentos

Mapa em `data/world/regions.json`: regiões, ruas com pontos de curva, lotes, praças, água, taludes/rampas, árvores-placeholder, placas, portas e spawns. `WorldLayouts` fornece os mesmos limites ao renderer e ao save; `city_area.gd` materializa os dados. Reinicie a execução após editar o JSON. Personagem/relógio persistem entre regiões, com uma área ativa de cada vez.

| Área | Dimensões |
|---|---|
| Quarto | 960×640 |
| Bairro | 3200×2400 |
| Via do rio | 6000×3600 |
| Campus | 3200×2600 |
| Hall | 1600×1100 |
| Sala de História | 1400×1000 |

`user://saves/slot_01/manual.json` e `auto.json`; preferência em `user://settings.json`. Windows padrão: `%APPDATA%\Godot\app_userdata\AnotherLife`; consulte Projeto → Abrir pasta de dados do usuário no editor.

Esquema **2**, com leitura/migração do esquema 1. Saves antigos externos são reposicionados na entrada segura da mesma região, pois suas coordenadas pertenciam ao corredor antigo. Nome, relógio/fração, alarme/contexto e tile são conservados; a migração não regrava o arquivo original. Saves atuais mantêm posição exata; novos números fracionários são escritos com precisão completa. Arquivos inválidos são recusados antes de alterar a partida.

Manual guarda estado antes do sono e retoma a escolha ao carregar; auto, opcional/desligado por padrão, guarda ao acordar e trocar de mapa. Um slot não substitui o outro. A inicialização não sobrescreve/carrega automaticamente o auto. Sono/save/fade falhos não devem criar salvamento silencioso; erro do manual permite tentar novamente ou dormir sem salvar. Somente sistemas implementados são persistidos.

## Validação reproduzível

Com Godot 4.7 no PATH:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/city_university_test.gd
godot --headless --path . --script res://tests/scale_lab_test.gd
godot --headless --path . --script res://tests/time_manager_test.gd
godot --headless --path . --script res://tests/interior_time_test.gd
godot --headless --path . --script res://tests/timed_action_test.gd
godot --headless --path . --script res://tests/dialogue_test.gd
godot --headless --path . --script res://tests/sleep_save_test.gd
godot --headless --path . --script res://tests/travel_display_test.gd
```

Nesta máquina: substitua `godot` por `& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'`. Engine e logs de `test-results/` ignorados pelo Git. Todos os runners usam `user://test_runs/`, sem modificar seus slots. Retornam código 1 em caso de falha.

O runner urbano padrão usa `Engine.time_scale = 6` para acelerar testes de física/tempo; `-- --walk` conserva a proporção real na primeira ida. Retorno e testes de acessos secundários continuam acelerados. Para renderizar dez capturas, retire `--headless` e acrescente `-- --walk --capture`. `signposted_journey_test.gd` é agora um alias do runner urbano, não uma segunda suíte independente. `travel_display_test.gd` cobre escala/HUD e passagens; a caminhada completa migrou para o runner urbano.

Resultados, duração real, contagens e inspeção de capturas no [registro da entrega](docs/decisions.md). Não foi realizado playtest humano. As medições antigas de 68/79 segundos referiam-se ao mapa reto e permanecem somente no histórico.

Validação de 13/10/2026: **90 verificações urbanas + 270 de regressão = 360**, zero falhas. Variante renderizada: **100 verificações**, zero falhas, dez capturas inspecionadas. Ida na proporção real: **106,445 s**, **+105 minutos**, chegada **07:45**, **75 minutos antes das 09h**. O ensaio padrão usa aceleração; suas durações de parede não representam o jogo. Importação/editor headless na Godot 4.7.2 sem erros.

## Hipóteses e próximo passo

**[PROPOSTA]** Início na primavera 1, ano 1, 06h, segunda-feira; origem da semana configurável. Alarme inicial 06h; igual ao instante de deitar vale no dia seguinte. Fração natural reinicia ao acordar; atraso excedente do frame que atinge 04h é descartado. Autosave em transição/despertar e nome no debug são UX de laboratório.

**[PENDENTE]** Tile definitivo, arte, nomes/layout final dos locais, consequências do sono curto, fronteira de alarme exatamente às 04h e UX de atividades que atingiriam o limite (ainda recusadas previamente). Textos pt_BR por chaves; en/es entram antes da beta. Sem energia/crafting. Drowned não foi alterado; P0-03 depende de acesso explícito.

Próxima tarefa: **P2-03 — agenda acadêmica mínima manhã/tarde**, avanço das aulas e presença/falta. Horários provisórios do GDD não devem ser promovidos a cânone sem decisão.
