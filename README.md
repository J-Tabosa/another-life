# Another Life / Outra Vida

Protótipo em **Godot 4.5 / GDScript**, conforme o [GDD do Dia 0](docs/ANOTHER_LIFE_GDD_DIA0.md) e [AGENTS.md](AGENTS.md).

## Entrega atual

**P1-03 — TimeManager**, sobre o laboratório da primeira sessão técnica (seção 15 do GDD). Cena principal: `scenes/lab/scale_lab.tscn`.

- Personagem placeholder: cada quadro tem 128×128 px, corpo com margem transparente e colisão nos pés.
- Movimento em oito direções, diagonal normalizada e animação/idle em quatro direções.
- Dois mapas separados, câmera de seguimento, paredes e mobília com colisão.
- Porta interativa com destino e marcador de entrada; personagem preservado ao trocar de mapa.
- Comparação de tiles 32/64, porta, cama, mesa e fachada; arte e disposição provisórias.
- Labels em português por chaves traduzíveis. Inglês e espanhol entram antes da beta.
- Relógio externo: 1 segundo real = 1 minuto do jogo; data/hora visíveis no rodapé, preservadas nas transições. A ativação natural é restrita à rua.
- Minutos absolutos e eventos por minuto; meia-noite, 30 dias/estação, 120 dias/ano e continuidade dos dias da semana. Sem férias/agendas nesta tarefa.

**[PROPOSTA]** O teste começa na primavera 1, ano 1, às 06h. Segunda-feira é a origem provisória; `weekday_offset` do nó `TimeManager` permite escolher outra origem enquanto a decisão canônica está pendente.

## Como rodar

1. Importe `project.godot` na **Godot 4.5**.
2. Aguarde a importação dos recursos e pressione **F6** para executar a cena-laboratório ou **F5** para executar o projeto.
3. Caminhe até a porta e pressione **E** para sair/entrar.

| Tecla | Ação |
|---|---|
| WASD / setas | Caminhar |
| E | Atravessar a porta quando próximo |
| T | Alternar tiles/objetos entre 32 e 64; reposiciona em ponto seguro |
| F | Mostrar/ocultar quadro 128×128 e colisão dos pés |

A versão Steam encontrada nesta máquina é 4.7.2; a validação desta entrega usou a **Godot 4.5 oficial**, baixada em `.tools/` (ignorada pelo Git). Não depende de Steam ou de Drowned.

## Validação reproduzível

Com o executável Godot 4.5 no PATH:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/scale_lab_test.gd
godot --headless --path . --script res://tests/time_manager_test.gd
```

Nesta máquina:

```powershell
& '.\.tools\godot-4.5\Godot_v4.5-stable_win64_console.exe' --headless --path . --script res://tests/scale_lab_test.gd
& '.\.tools\godot-4.5\Godot_v4.5-stable_win64_console.exe' --headless --path . --script res://tests/time_manager_test.gd
```

Para reproduzir capturas com renderização, execute o runner **sem `--headless`**, acrescentando `-- --capture`. As imagens vão para `docs/screenshots/`.

O runner exercita movimento com o servidor de física, oito direções, idle, quadros, paredes, cama/mesa em ambas as escalas, aproximação física e interação nas portas, seis ciclos quarto↔rua, marcadores de entrada e ausência de mapas duplicados. Ele retorna código 1 em caso de falha.

O runner `time_manager_test.gd` verifica minutos inteiros/fracionários, equivalência de 3600 frames a 60 FPS, eventos intermediários em ordem, meia-noite, estações, ano, semanas e origem configurável. Acrescente `-- --realtime` para medir também **60 segundos reais** com o relógio de produção ativado na rua. `--capture` salva `docs/screenshots/time_clock.png` e exige execução sem `--headless`.

## Limites e próximo passo

Sem conteúdo narrativo nesta etapa. Sono, save, NPCs, universidade, férias e hobbies continuam nas tarefas posteriores. A escolha de nome do protagonista será feita no fluxo de nova partida; o laboratório não fixa nome canônico.

Veja [decisões, capturas e progresso](docs/decisions.md). Próxima tarefa: **P1-04 — consolidar e validar pausa temporal em interiores**, incluindo preservação da fração de segundo e ciclos repetidos de entrada/saída. A ativação mínima apenas na rua já protege a regra do GDD nesta entrega. Antes de arte em massa, confirmar a escala provisória com o criador. **P0-03 permanece pendente** de acesso explícito ao projeto Drowned.
