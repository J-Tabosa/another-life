# Verificação da migração para Godot 4.7

Em 12/10/2026 o criador solicitou desenvolvimento em **Godot 4.7**, substituindo a referência histórica 4.5. O projeto já tinha sido convertido localmente pelo editor. Validação desta entrega: binário oficial **4.7.2.stable.official.ed1daf0bf**, mesma versão encontrada na instalação Steam. O GDD histórico não foi reescrito.

## Documentação oficial consultada

- [Migração 4.6 → 4.7](https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html).
- [Migração 4.5 → 4.6](https://docs.godotengine.org/en/4.6/tutorials/migrating/upgrading_to_godot_4.6.html).
- [Resoluções e stretch na 4.7](https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html).
- [Release 4.7](https://godotengine.org/releases/4.7/) e [binários 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/).
- [DirAccess.rename_absolute](https://docs.godotengine.org/en/4.7/classes/class_diraccess.html), para substituir o save após escrita temporária.

## Mudanças relevantes

| Mudança documentada | Aplicação/verificação |
|---|---|
| Projetos novos 4.7 usam canvas_items/expand por padrão | Stretch explicitamente `disabled` e Camera2D.zoom = (1,1); maior resolução amplia a área visível, mantendo escala em pixels. |
| IDs de teclado/mouse mudaram | Runner de diálogo usa InputEvent.DEVICE_ID_KEYBOARD/MOUSE e objetos distintos para pressionar/soltar. |
| Suavização de linhas mudou | Grade/debug usam desenho simples, sem depender de espessura adicional de antialiasing. Capturas conferidas. |
| Sincronização de blend spaces mudou | Personagem usa AnimatedSprite2D; não há AnimationTree/blend spaces a converter. |
| Setters de arrays compactados mudaram | Não há setter desse tipo no protótipo. |
| Compatibilidade de esqueletos e configurações 3D | Protótipo 2D; configurações inseridas pela conversão foram preservadas, sem dependência 3D na jogabilidade. |

HUD e diálogo acompanham o viewport; sono/calendário usam containers e scroll. Tela cheia borderless usa Window.MODE_FULLSCREEN; F11 alterna janela. Quadro 128×128 e corpo 40×56 mantêm escala.

## Evidência e limites

Importação/editor headless, sete runners, caminhada completa com física/tempo automático e capturas renderizadas na 4.7.2. Resultados/comandos no README e em `docs/decisions.md`; logs locais em `test-results/`. Captura de tela cheia nesta máquina: 1366×767, conforme viewport disponível. Teste automatizado também verifica configurações 960×540, 1366×768 e 1920×1080, conservando câmera/escala e HUD.

Não houve playtest humano nem teste em todos os monitores/DPIs. Não há conteúdo final, animações avançadas ou subsistemas 3D a validar. Futuras atualizações da engine devem repetir a importação e os runners antes de serem assumidas compatíveis.
