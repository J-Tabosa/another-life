# Primeira sessão técnica — 12/10/2026

## Escopo e ordem

Registro da primeira entrega: **primeira sessão técnica da seção 15 do GDD**, conforme a prioridade do AGENTS.md. Apenas o laboratório de escala, movimento e quarto↔rua. A tarefa atual P1-04 está registrada ao final deste documento.

| Roadmap | Estado nesta entrega |
|---|---|
| P0-01 | Projeto próprio e Git inicializados; Godot 4.5 executada |
| P0-02 | GDD/AGENTS preservados; README e gitignore adicionados/complementados |
| P0-03 | **[PENDENTE]** Nenhum caminho/recurso de Drowned foi disponibilizado; nenhuma auditoria nem reutilização presumida |
| P0-04 | Laboratório com quadro 128×128, porta, cama, mesa e fachada; alternância 32/64 |
| P0-05 | Comparação visual registrada; 32 escolhido somente como padrão técnico provisório |
| P1-01 | Movimento 8 direções, animações/idle 4 direções, diagonal normalizada |
| P1-02 | Mapas de teste quarto/rua e porta interativa com marcadores de entrada |

P0-03 não impede a seção 15: o GDD condiciona a inspeção de Drowned ao acesso. Nenhum arquivo daquele projeto foi lido ou alterado.

## Hipóteses técnicas, sem alteração do cânone

- **[PROPOSTA]** Viewport 960×540, câmera sem suavização e zoom 1; filtro nearest. Valores ajustáveis após playtest.
- **[PROPOSTA]** Tile padrão 32 px. Com o mesmo corpo placeholder, cama de 64×128 e porta de 64 px têm proporções mais compactas; em 64, a cama passa a 128×256 e a porta a 128 px. A comparação permanece acessível com T; não há produção de tiles finais.
- **[PENDENTE]** Aprovação criativa do tile e câmera. Os screenshots validam legibilidade técnica; não substituem playtest de conforto pelo criador.
- **[PROPOSTA]** Velocidade 180 px/s, corpo desenhado com 40×56 e pés, dentro de quadro 128×128; colisão 24×14 junto aos pés. Quadro não é tamanho do corpo.
- **[PROPOSTA]** Empates diagonais usam orientação horizontal. Parado, retém a última orientação.
- **[PROPOSTA]** Interação por E dentro da área de porta. A transição ocorre diferida, fora da atualização física; um personagem e uma área ativos, sem manager global prematuro.
- **[PROPOSTA]** T reposiciona o jogador no marcador seguro para evitar sobreposição após aumentar a mobília.
- **[PENDENTE]** Arte, nomes, disposição definitiva de casa/rua, localização completa en/es. Nada no mapa de teste determina geografia canônica.

## Capturas da engine

As quatro imagens foram renderizadas pela Godot 4.5 e inspecionadas visualmente. Personagem conserva a escala ao alternar o tile.

| Quarto 32 | Quarto 64 |
|---|---|
| ![Quarto 32](screenshots/room_32.png) | ![Quarto 64](screenshots/room_64.png) |

| Rua 32 | Rua 64 |
|---|---|
| ![Rua 32](screenshots/street_32.png) | ![Rua 64](screenshots/street_64.png) |

## Resultado da validação

Engine: `4.5.stable.official.876b29033`. Importação no editor headless; runner com física real; renderização OpenGL para screenshots. Logs locais em `test-results/`, ignorados pelo Git.

O runner cobre movimento/idle, dimensões dos quadros, tradução, colisões de parede/cama/mesa, portas acessíveis caminhando, recusa de interação distante, seis ciclos ida/volta com spawn correto em 32 e 64 e apenas uma área ativa. **60 verificações headless; mais 4 capturas no modo renderizado.** Não foi feito playtest humano nem validação de arte final.

Problema corrigido na inspeção: HUD encobria os objetos no enquadramento inicial; cama, mesa e fachada foram deslocadas para ficarem visíveis. O runner aguarda a sincronização de overlaps do servidor físico antes de interagir.

## Próxima tarefa sugerida

Após a primeira sessão, foi sugerida **P1-03 — TimeManager**, executada na entrega abaixo.

---

## P1-03 — relógio externo — 12/10/2026

**Escopo autorizado:** TimeManager com 60 segundos reais por hora do jogo e testes de minutos, meia-noite, estação/ano e dias da semana. Não foram adicionadas atividades com duração, férias, agendas, sono ou saves.

### Implementação e hipóteses

- `scripts/core/time_manager.gd`: nó reutilizável com minutos absolutos; não usa o relógio/data do sistema para definir o calendário. O laboratório conserva uma única instância nas trocas de mapa, sem Autoload nesta etapa.
- Um segundo de `_process(delta)` equivale a um minuto. Frações são acumuladas; cada minuto intermediário emite `minute_changed`, e cada meia-noite emite `day_changed`, nessa ordem. A tolerância numérica de 1e-9 s evita perder um minuto ao somar frames de 1/60 s.
- Calendário derivado: quatro estações de 30 dias; 120 dias por ano; dias da semana e número da semana continuam entre estações/anos. Sem lógica de férias/compromissos (P3-01).
- **[PROPOSTA]** Origem do laboratório: primavera 1, ano 1, 06h. **[PENDENTE]** Dia da semana canônico inicial. `weekday_offset` vai de 0 (segunda) a 6 (domingo), com 0 como padrão técnico provisório.
- A rua ativa o relógio; o quarto não o ativa. Essa conexão mínima é necessária para não avançar tempo natural em interiores contra o GDD. P1-04 continua como tarefa própria para consolidar e verificar a pausa, preservação de frações e transições repetidas; não foi criado sistema de UI/cutscene ou atividades.
- O nó usa o modo pausable padrão da Godot. UI de pausa ainda não existe.
- Label no rodapé usa chaves traduzíveis para data/hora, estações, dias da semana e estado do relógio. Foi regenerado `lab.pt_BR.translation` com a Godot 4.5.

### Como testar

Abra o projeto na Godot 4.5 e execute F5. O rodapé começa em 06:00; saia pela porta com E e observe o minuto mudar a cada segundo. Voltar ao quarto preserva a data/hora, com tempo natural desativado. Os demais controles do laboratório continuam disponíveis.

Runners reproduzíveis e opções de medição/captura estão no README. `time_manager_test.gd` executa testes determinísticos pela própria Godot e, com `--realtime`, mede também um minuto real em execução externa. Os testes chamam o mesmo callback de produção; não existe API de atividade com duração nesta entrega.

### Validações executadas

- Godot `4.5.stable.official.876b29033`: importação/editor headless sem erros de script ou recurso.
- **41 verificações determinísticas do relógio, zero falhas**, incluindo eventos cronológicos e integração com HUD/transições.
- Medição na engine renderizada: **60,028 segundos reais → +60 minutos do jogo**, sem aceleração artificial. A captura também passou; execução completa: **43 verificações, zero falhas**.
- Regressão do laboratório: **60 verificações de movimento, colisões e portas, zero falhas**.
- Captura abaixo inspecionada visualmente: rodapé legível, sem encobrir os controles. A captura mostra 08h porque o runner avançou uma hora deterministicamente antes de medir a hora em tempo real.

![Relógio externo no laboratório](screenshots/time_clock.png)

Limitações desta tarefa: sem playtest humano, menu de pausa, atividades com duração ou sono compulsório. O limite das 04h continua fora desta entrega, conforme P1-07. A origem do dia da semana continua **[PENDENTE]**.

### Próxima tarefa

**P1-04 — consolidar e validar pausa temporal em interiores.** P1-05 adicionará atividades com duração; P1-07 fará o limite de sono às 04h.

---

## P1-04 — pausa temporal em interiores — 12/10/2026

**Critério de aceite:** o relógio natural para ao entrar e volta ao sair, preservando data/hora. A ligação `time_manager.running = area.exterior` já havia sido incluída em P1-03 para respeitar o GDD. A validação desta tarefa confirmou esse comportamento sem exigir alteração do código de produção.

### Alterações e cobertura

- `tests/interior_time_test.gd`: runner dedicado na Godot 4.5, com relógio/cenas/portas reais do laboratório.
- Congelamento de 60 segundos simulados no quarto, sem eventos de minuto ou dia; jogador continua andando com o SceneTree ativo.
- Entrada/saída pelo caminho de interação E e overlap da porta; vinte ciclos adicionais de troca de mapa, preservando a instância do relógio e apenas uma área ativa.
- Frações verificadas por comportamento observável: 0,75 s fora + espera dentro + 0,25 s fora = exatamente um minuto; vinte ciclos com 0,1 s fora cada = dois minutos, sem duplicação/perda.
- Às 23:59, esperar dentro conserva a data e não emite meia-noite; ao sair e completar a fração externa restante, emite uma única mudança de dia.
- HUD conserva a hora e indica tempo parado/correndo conforme a área.
- Medição com ticks automáticos em uma cena nova: movimento continua durante espera real dentro; depois a porta leva à rua e o relógio volta a avançar. A opção `--realtime` usa contador monotônico para garantir pelo menos 60 segundos reais; execução padrão usa uma espera de 2 segundos.
- README atualizado com os comandos e o próximo passo. Nenhuma nova decisão de cânone.

### Como executar

Na Godot 4.5, F5. Espere/caminhe no quarto: a hora permanece igual. Use E na porta para sair, observe os minutos avançarem, volte e confira o congelamento. Automação:

```powershell
& '.\.tools\godot-4.5\Godot_v4.5-stable_win64_console.exe' --headless --path . --script res://tests/interior_time_test.gd
& '.\.tools\godot-4.5\Godot_v4.5-stable_win64_console.exe' --headless --path . --script res://tests/interior_time_test.gd -- --realtime
```

### Limitações e próxima tarefa

**Validações executadas:** Godot `4.5.stable.official.876b29033`, importação/editor headless sem erros. Runner de interiores: **42 verificações, zero falhas**, incluindo **60,069 segundos reais dentro do quarto → +0 minutos**, movimento ativo e retomada automática na rua após a porta. Regressões: **41 verificações do TimeManager** e **60 do laboratório**, todas sem falhas. Logs locais em `test-results/interior-*.log` (ignorados pelo Git).

Validação automatizada em headless, sem playtest humano nesta entrega. O congelamento aplica-se ao tempo natural, não ao SceneTree. Atividades com duração, diálogos, menu de pausa, sono e saves continuam nas tarefas correspondentes. Dia da semana inicial e escala visual seguem **[PENDENTE]** conforme as notas anteriores.

**P1-05 — ações com duração explícita:** uma atividade de 60 minutos deve avançar exatamente 60 minutos mesmo dentro do quarto, respeitando a ordem dos eventos intermediários.
