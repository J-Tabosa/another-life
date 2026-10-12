# Another Life / Outra Vida

Protótipo em **Godot 4.5 / GDScript**, conforme o [GDD do Dia 0](docs/ANOTHER_LIFE_GDD_DIA0.md) e [AGENTS.md](AGENTS.md).

## Entrega atual

**Primeira sessão técnica — seção 15 do GDD:** laboratório de proporções, movimento e quarto↔rua. Cena principal: `scenes/lab/scale_lab.tscn`.

- Personagem placeholder: cada quadro tem 128×128 px, corpo com margem transparente e colisão nos pés.
- Movimento em oito direções, diagonal normalizada e animação/idle em quatro direções.
- Dois mapas separados, câmera de seguimento, paredes e mobília com colisão.
- Porta interativa com destino e marcador de entrada; personagem preservado ao trocar de mapa.
- Comparação de tiles 32/64, porta, cama, mesa e fachada; arte e disposição provisórias.
- Labels em português por chaves traduzíveis. Inglês e espanhol entram antes da beta.

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
```

Nesta máquina:

```powershell
& '.\.tools\godot-4.5\Godot_v4.5-stable_win64_console.exe' --headless --path . --script res://tests/scale_lab_test.gd
```

Para reproduzir capturas com renderização, execute o runner **sem `--headless`**, acrescentando `-- --capture`. As imagens vão para `docs/screenshots/`.

O runner exercita movimento com o servidor de física, oito direções, idle, quadros, paredes, cama/mesa em ambas as escalas, aproximação física e interação nas portas, seis ciclos quarto↔rua, marcadores de entrada e ausência de mapas duplicados. Ele retorna código 1 em caso de falha.

## Limites e próximo passo

Sem conteúdo narrativo nesta etapa. O laboratório não inicia relógio, sono, save, NPCs, universidade ou hobbies. A escolha de nome do protagonista será feita no fluxo de nova partida; o laboratório não fixa nome canônico.

Veja [decisões, capturas e progresso](docs/decisions.md). Próxima tarefa de gameplay: **P1-03 — TimeManager**, mantendo 1 segundo real = 1 minuto de jogo. Antes de arte em massa, confirmar a escala provisória com o criador. **P0-03 permanece pendente** de acesso explícito ao projeto Drowned.
