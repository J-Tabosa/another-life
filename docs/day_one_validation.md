# P2-08 — Dia 1 do começo ao fim

Validação em 16/10/2026, Godot 4.7.2 oficial. O roteiro é uma apresentação esperada, não uma lista de obrigações: é permitido faltar, cancelar conversas, descobrir interesses em outra ordem e dormir com conteúdo pendente.

## Como jogar

1. Abra `project.godot` na Godot 4.7 e pressione F5. A cena começa às 06h, em uma partida nova; os slots existentes ficam intactos. C abre o calendário/configurações de teste, onde é possível escolher o nome e ativar auto opcionalmente.
2. E perto do pai e da irmã abre os cumprimentos da manhã. E/Enter continua; Esc cancela.
3. Saia pela porta, percorra bairro → centro → campus e entre na Horizonte. O mapa M ajuda na orientação. Vá pelo hall até a sala de História e use E no ponto de aula.
4. Espere até 09h e participe. Conclua a apresentação para chegar ao meio-dia. Saia da sala e procure a colega no hall; se ainda não a conhece, a primeira conversa apresenta a colega e a segunda é o almoço.
5. Volte à sala, espere até 13h e participe. Escolha uma das quatro alternativas; a aula termina às 17h com presença, tanto no acerto quanto no erro.
6. Volte a pé para casa. Pai e irmã apresentam skate e jogos no período doméstico de teste das 17h às 23h. O ponto roxo no quarto apresenta música. H consulta apenas interesses descobertos.
7. E perto da cama abre o encerramento. Confira a data completa do despertar, ajuste o alarme e escolha **1 — Salvar e dormir** ou **2 — Dormir sem salvar manualmente**; o mouse também funciona. Esc cancela o sono voluntário. As teclas numéricas continuam editando o alarme quando o campo está em foco.
8. Ao acordar, o relógio mostra a nova data e os controles ficam disponíveis. C permite carregar manual/auto separadamente. O manual é anterior ao sono e restaura essa escolha; o auto, se habilitado, guarda o estado após acordar.

Falhar uma gravação mantém a escolha de sono e o progresso atual. É possível tentar novamente ou dormir sem salvar manualmente. Às 04h, Esc não cancela o sono obrigatório; a opção de prosseguir sem manual continua disponível. Fora de casa, a volta ocorre com fade e o despertar é às 12h do mesmo dia do limite; em casa, vale o alarme.

## Teste contínuo reproduzível

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/day_one_flow_test.gd
```

O runner executa duas partidas novas completas: tile 32 com auto ligado/resposta correta/alarme 06h; tile 64 com auto desligado/resposta incorreta/alarme 07h15. Usa teclado/mouse, colisões, caminhada pelos caminhos, portas com fade, aulas, duas conversas no hall, hobbies, cama, gravação e reinício da cena para carregar o arquivo real. Nessas duas partidas não usa `change_area`, teleporte, `restore_clock` ou salto debug para vencer trajetos/horários: avança apenas por caminhada exterior e atividades acadêmicas/sono da interface.

Por padrão, acelera a simulação 6× para encurtar o teste, preservando velocidade/escala de produção. Para executar o primeiro percurso completo em velocidade normal e produzir quatro capturas:

```powershell
godot --path . --script res://tests/day_one_flow_test.gd -- --walk --capture
```

O segundo percurso usa 6×. A seção adicional de desvios usa configurações diretas de mapa/relógio para alcançar limites e falhas; essa seção não é apresentada como caminhada contínua. Todos os saves/settings ficam em `user://test_runs/day_one_*`, sem tocar nos slots reais.

## Critérios do GDD conferidos

| Critério | Evidência |
|---|---|
| Abrir e iniciar partida nova | Duas cenas novas, mais reinício com slots existentes; nenhum slot sobrescrito ao iniciar |
| Nome escolhido em diálogo/save | Entrada Unicode pelo campo real; cumprimento nomeado e restauração de contexto após load |
| Movimento 8 direções/4 animações | Suíte de escala; os dois percursos contínuos usam o controlador de produção |
| Casa/rua/universidade | Ida e volta por todas as portas, movimento e fade, em tiles 32/64 |
| Relógio externo/interior | Caminhada com relógio automático; aulas, conversas e sono conferidos; suíte do relógio |
| Aula/presença/falta | Manhã/tarde presentes na rota principal; faltar ao dia inteiro não bloqueia a retomada |
| Colega/almoço | Primeiro contato e almoço no hall após a aula da manhã, com cancelamento e retomada |
| Questão/reação/registro | Acerto na partida 32, erro na 64; suíte de questões cobre as quatro alternativas e reações |
| Três hobbies | Pai, irmã e ponto de música, preservados ao acordar e ao carregar |
| Cama/manual opcional | Cancelar, salvar, prosseguir sem manual, teclado/mouse e falha real de escrita |
| Load sem perder estado | Nova instância carrega os arquivos de manual/auto: posição, nome, tempo, alarme e todos os registros |
| Próximo dia correto | Dia 2/terça-feira às 06h ou 07h15, movimentação liberada |
| Minigames dispensáveis | Apenas descobertas; conteúdo pendente não impede dormir nem avançar |

## Desvios e recuperação

- Cancelar apresentação, almoço, questão e sono e tentar novamente no mesmo contexto.
- Dormir imediatamente sem conhecer ninguém/nenhum hobby, com ambas as formas de save desligadas; acordar normalmente e registrar faltas.
- Retomar a primeira apresentação/pergunta numa tarde posterior, inclusive chegando atrasado e errando.
- Limite de 04h com frame exterior longo: retorno para casa e despertar às 12h; em casa, alarme respeitado.
- Falha real de escrita causada por arquivo no lugar da pasta de destino: estado e manual anterior preservados, opção de prosseguir e tentativa posterior funcionando.
- Load de arquivo inválido: partida preservada e painel dismissível.
- Callback de salvar repetido após acordar: não regrava manual nem inicia outro sono.
- Alarme em foco: digitar 1 não escolhe automaticamente salvar/dormir.
- Decisões de sono acessíveis em 960×540.

## Limites

Sem playtest humano. A validação demonstra ausência de bloqueios nas rotas e desvios testados; não cobre todas as combinações possíveis de hardware/entrada. F5 ainda inicia diretamente o laboratório e o nome é escolhido em C; menu principal dedicado, arte, instrumento, minigames, notas/recompensas e rotinas completas permanecem pendentes. Horários domésticos continuam hipótese de teste. O checkpoint P2 apresenta o dia inteiro; a próxima tarefa é P3-01, revisar/completar calendário e férias, preservando o que já existe.
