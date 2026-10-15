# Instruções para Codex — Another Life

Leia **`docs/ANOTHER_LIFE_GDD_DIA0.md`** antes de modificar o projeto. Este arquivo contém o cânone do Dia 0, escopo e roadmap. Se o GDD estiver na raiz em vez de `docs/`, use o caminho existente e não duplique o conteúdo desnecessariamente.

## Workflow obrigatório

1. Inspecione a estrutura e os scripts existentes antes de propor código.
2. Identifique a **tarefa atual** (`P0-01`, `P1-03` etc.) e execute **apenas** ela.
3. Apresente um plano curto, arquivos envolvidos e eventuais dependências.
4. Faça alterações pequenas, idiomáticas para **Godot 4.7 / GDScript** e fáceis de revisar. A engine foi atualizada por solicitação do criador; veja `docs/godot_4_7_migration.md`. As referências históricas à 4.5 no GDD permanecem como registro.
5. Prefira dados e eventos reutilizáveis a lógica narrativa acoplada a cenas específicas.
6. Use placeholders quando arte e conteúdo final não existirem; identifique-os claramente.
7. Faça testes reais sempre que possível; **não afirme que testou se não conseguiu executar**.
8. Ao entregar: arquivos alterados, como rodar, validações, limitações e próxima tarefa sugerida.
9. Questões ainda não decididas são **[PENDENTE]**; hipóteses técnicas devem ser documentadas, nunca tratadas como cânone.
10. **Preserve o projeto Drowned**: só reutilize recursos se explicitamente disponíveis e apropriados; não altere seu repositório.

## Restrições não negociáveis

- Protagonista: nome escolhido, visual-base fixo, sprite com quadro **128×128**, 8 direções de movimento e 4 de animação.
- Visão 2D superior em 3/4; mapas por transição; tile 32/64 **a testar**.
- Relógio externo: **1 segundo real = 1 minuto do jogo**; interior congela relógio, atividades avançam tempo.
- Às **04h** o jogador dorme compulsoriamente: se fora, acorda **12h** após 8 horas de sono; se em casa, respeita despertador.
- **Sem barra de energia. Sem crafting.**
- História fixa na Universidade Horizonte, cidade Fliegen.
- Hobbies iniciais **somente** skate, música e fliperama/videogames.
- Autosave opcional e manual em **arquivos separados**, manual oferecido ao dormir.
- Informações sociais parciais: relações reais e conhecimento do protagonista são dados distintos. Diário automático só mostra informações descobertas.
- Romances NPC↔NPC: pares elegíveis escritos previamente, com resultados dinâmicos por agenda e eventos; sem matchmaking aleatório.
- Idiomas-alvo da primeira beta: `pt_BR`, `en`, `es`; planejar textos por chaves traduzíveis.

## Prioridade atual

A primeira sessão é **laboratório de escala + movimento + quarto↔rua**, conforme seção 15 do GDD. Não implementar o jogo inteiro, nem os managers de todas as fases antecipadamente.

**P2-06 concluída:** banco em `data/questions/history.json`, primeira questão na primeira aula da tarde frequentada, quatro alternativas (mouse/1–4), reação e registro acadêmico por IDs estáveis. Cancelar antes da escolha não gasta tempo nem concede presença; responder conclui o turno e grava resposta/presença juntas, com auto opcional. Fechar a reação não apaga a escolha. `academics.question_answers` opcional no esquema 3; arquivos anteriores sem o campo continuam válidos. Atrasos/dias perdidos têm retomada; se a apresentação estiver pendente, antecede a pergunta. Conteúdo inicial é de teste; pesos/notas e recompensa numérica são **[PENDENTE]**. Sem cronômetro/seminário nesta tarefa.

P2-05 preservada: colega placeholder, primeiro contato e almoço, rotina mínima em `data/npcs/classmate.json` (dias letivos, sala 06h–12h/13h–17h; hall 12h–13h), encontros conhecidos separados da disponibilidade. Bloco `classmate` opcional, manual/auto separados. Nome, visual, biografia, falas finais e rotina completa continuam **[PENDENTE]**; não antecipar relações/diário completos.

P2-04 preservada: professor, apresentação na primeira aula frequentada, avanço/presença ao concluir a atividade, cancelamento seguro e flag acadêmica persistida. Cidade da referência 6×, 22 locais e três setores/fade; agenda 09h–12h e 13h–17h autorizada nesta etapa; escala, sono, calendário, filtros e migrações 1/2 preservados. Consulte README, `docs/reference_city.md` e o último registro de `docs/decisions.md`. Próxima tarefa: **P2-07 — eventos curtos de pai/irmã e música no quarto**, descoberta dos hobbies previstos no GDD.
