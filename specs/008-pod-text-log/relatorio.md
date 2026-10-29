# Relatório da implementação: Pod e text log (spec 008)

**Data:** 2026-10-27 a 2026-10-29.

**Onde:**
- branch `008-pod-text-log` do repositório público;
- branch `lab-008` do repositório privado (laboratório), com o `lab/check-008`, o `lab/notify-client`
  e o passo `lab/provision-step notify`.

**Lab:** MVP (T001–T027) nas VMs `teste-a` e `teste-b` com 2 núcleos; da US2 em diante (2026-10-29),
uma frente só na `teste-b`, recriada depois do renome rien-OS → YoRHa-OS, com 4 núcleos e 4 GB
(instrução do dono). O `check-008` liga a VM no perfil hidpi (os dois modos existem). Tudo dentro de
sessões `lab/perf`.

**Status:** as 57 tarefas estão feitas. Faltam a aprovação visual do dono (SC-013), com a imagem de
revisão `out/008-revisao.png`, e as decisões pendentes do fim deste relatório.

## O que ficou pronto

- **Servidor e transmissões (US1):** o shell é o servidor de notificações (`NotificationServer` do
  Quickshell); cada notificação vira uma transmissão na faixa, digitando, no monitor em foco; mouse por
  cima pausa e completa, clique esquerdo dispara a ação padrão ou esconde, direito esconde; pilha de 3,
  agrupamento `×N`, substituição no lugar, `+N in log`, enxurrada em lote de 16 ms.
- **Urgência (US2):** bloco `medium-gray` / `light-yellow` / `alert`; a faixa crítica larga com
  `◂ 1/N ▸` e ×, que não expira e passa por cima do não perturbe e da tela cheia.
- **Ações e resposta (US3):** botões na ordem do app, a ação chega no app e fecha (a não ser residente);
  o campo de resposta pega o teclado (`Exclusive`) só enquanto está aberto e devolve pra janela de antes.
- **Text log (US4):** a `LogPage` (lista NOW/EARLIER, prévia digitando de novo, opções Do not disturb,
  Show, Clear all) num popup da 003 e pronta pra aba do menu de pausa; a lista cria só as linhas à vista
  (decisão do dono): o log de 100 abre em ≈ 60 ms (1080) e ≈ 100 ms (hidpi), antes 136–325 ms. O
  contador `LOG n` / `DND n` na barra.
- **OSD (US5):** volume, mudo, microfone e brilho, na faixa, um só, 1,2 s depois da última mudança,
  calado com o foco em Sound › Volume/Mute.
- **Não perturbe (US6):** tecla, comando, opções do log e das configurações; tela cheia segura igual
  (`In fullscreen: Hold`).
- **Opções (US7):** a categoria Notifications vale de verdade e troca ao vivo (inclusive o que está na
  tela); as escolhas e o log salvo (`Saved`, modo 600) ficam em `~/.local/state/yorha-os/`.
- **Galeria (T053):** páginas 4 (a faixa e as peças) e 5 (a `LogPage` no corpo do popup e no do menu de
  pausa, SC-016); a página 4 escala também pela largura, pra a 3ª coluna caber em 2560×1600 (decisão do
  dono).
- **Design system (T052):** `docs/design-system.md` §9.

## Evidência por critério

Rodadas finais do `lab/check-008` inteiro (T054), na sessão
`2026-10-29T123957-vm-teste-b-008-check-008-inteiro-em-1080-e-hidpi-t0`:
**1080 110/0** (`out/check-008-1080-20261029-125428`) e **hidpi 110/0** (`out/check-008-hidpi-20261029-131938`).

| Critério | Resultado (1080) | Bloco / `lab/perf` da história |
|---|---|---|
| SC-001 | Na tela 53 ms depois do `notify-send`, digitada 280 ms depois; nos quadros, aparece e muda digitando | `first`; MVP `2026-10-28T160556` |
| SC-002 | Pilha + crítica + OSD, log aberto, Top band, Subtitle, OSD no topo, `positions`, `long`: dois shots, 0 px, nos dois perfis | `shots` |
| SC-003 | Baixa sai 3980 ms e normal 5982 ms depois de digitadas; a crítica continua em 65 s; cores do bloco lidas no pixel | `urgency`; `2026-10-29T102807` |
| SC-004 | `later` e `default` no `notify-send --wait`; `replied ok thanks` no cliente; a janela em foco igual antes e depois e o comando digitado chega no kitty; Esc não manda nada | `actions`, `reply`; `2026-10-29T105454` |
| SC-005 | 100 em 1 s: ≤ 3 na tela, 100 no log, 99 não lidas e `LOG 99`; o log abre em 59 ms (hidpi 96 ms); CPU do `qs` 5 s depois igual ao de uma transmissão sozinha na tela (a última da enxurrada ainda anima a linha de tempo; hidpi: 3% contra 11%; tela vazia 2%) | `flood`; `2026-10-29T111419` |
| SC-006 | Cinco do mesmo app: uma transmissão `×5`, 5 entradas | `group` |
| SC-007 | DND por `ALT + CTRL + N`: 0 normais e 1 crítica, 6 no log, `DND 5`; continua depois de reiniciar o `qs` | `dnd`; `2026-10-29T115809` |
| SC-008 | 64 → 66 na tecla; três mudanças, um OSD com o valor do `wpctl` (70); some 1225 ms depois; MUTE apagado; MIC; brilho por comando; 120% | `osd`, `osd-quiet`; `2026-10-29T113600` |
| SC-009 | ALT + N, ↓ ↓, Enter, Delete, →, → ← no DND, Esc, Esc, com o `dump` certo a cada tecla | `log-keys`; `2026-10-29T111419` |
| SC-010 | Monitor headless em foco: transmissão, crítica e OSD só nele; ao remover, as dele vão pro log | `monitors` |
| SC-011 | Com `reduceMotion`, o primeiro quadro com a transmissão já é o final | `reduced` |
| SC-012 | Log de QML do roteiro inteiro sem erro nem aviso (só as duas linhas esperadas do outro servidor, filtradas); `qmllint` limpo | `lint` e o fim do roteiro |
| SC-013 | **Aguarda o dono:** `out/008-revisao.png` (mockup × VM 1080 × VM hidpi) | T055 |
| SC-014 | Position nas três por teclas reais, mudando o que está na tela e a próxima, mantendo o tempo; OSD position Top (e abaixo da crítica) | `prefs`; `2026-10-29T121451` |
| SC-015 | 5 entradas voltam depois de reiniciar o `qs` e a VM, `earlier`, sem ações; arquivo 600; Session only apaga; nada no `~/.config` | `saved`; `2026-10-29T121451` |
| SC-016 | A `LogPage` no corpo do popup e no do menu de pausa, sem vazar, em 1080 e hidpi | `gallery` |

**Regressão** (no fim de cada história, a partir de um snapshot do `shell/`): `check-u1` 15/0,
`check-003` 25/0 e `check-004` 58/0 em US4, US6 e US7. Em US3 e US5 houve uma falha instável cada
(o SC-005 de blink e o SC-004 de clique do `check-003`), que passaram 2/2 e 3/3 rodados de novo; em US5
também o aviso `id-shadows-member` do qmllint na galeria, corrigido. O seletor da 004 dá **0 px** de
diferença contra a branch `004-wallpaper-system` (T035/T036).

## Decisões e desvios

- **Lista do log sob demanda** (decisão do dono): `GroupedList.lazy` / `PickerLayout.lazyList`; o SC-005
  voltou a ser critério no bloco `flood`.
- **Trilha translúcida** (decisão do dono): o progresso e o OSD usam a trilha do mockup
  (`Tokens.notify.bandTrack`), não o `Meter` invertido; emenda em `contracts/components.md`, na spec
  (FR-028, US5, caso de borda "Progresso") e no design system.
- **Galeria em 2560×1600** (decisão do dono): as páginas 4 e 5 escalam por `min(altura/1080,
  largura/1920)`.
- **`PickerLayout` com os nomes da 007:** a `007-menu-de-pausa` fez o mesmo acréscimo em paralelo; a
  008 adotou `triggered`, toggle 0/1 e o rodapé `Enter <text>` dela.
- **Teclado da resposta:** `Exclusive` (spike T004), não `OnDemand` como o contrato dizia.
- **`notify dump`:** `screen[].controls` e `critical.controls` (caixas pros cliques), acréscimo no
  contrato.
- **Lista do log mais larga:** no modo `fluid` a lista vai até 24 px antes da prévia, como no mockup.

## Correções feitas no caminho

- `CriticalBand`: ◂ 1/2 ▸ e × saíam no canto esquerdo (a varredura deixava a largura errada) e os
  triângulos (`Canvas`) não pintavam; viraram um `progress` que só recorta e um `Shape`.
- Log salvo: não voltava num `qs` novo (a `FileView` sem `preload` não carrega no `reload()`); a
  leitura passou a ser explícita e síncrona.
- `Clock`: o aviso de `QDateTime` na recarga ao vivo.
- `LogPage`: margem no host `pause` (o trilho e o quadro encostavam).
- Lab: a `teste-b` recriada (sobras do rien-OS); o source nulo virou `Audio/Source` (o Quickshell não
  dá `audio` a `Audio/Source/Virtual`); `qs ipc call -- notify pref fullscreen show` (o `qs` toma a
  palavra `show`); `pkill -f` com o padrão escapado; o servidor falso morto pelo código; o aviso do
  portal do Qt 6.12 depois do reboot silenciado no `nier-ui-run`.

## Análise (T057, `/speckit-analyze`)

Passada de consistência entre spec, plano, tarefas e contratos depois da implementação. Corrigido:
- a spec ainda pedia o medidor invertido (FR-028, US5, "Progresso"): emendada pela decisão do dono;
- o research R16 e a T036 citavam `invoked`: anotado o `triggered`;
- o quickstart e o plano citavam `lab/provision notify` e a `teste-a` com 2 núcleos: `provision-step`
  e a `teste-b` com 4 núcleos;
- o filtro do log no bloco `lint` agora diz quais duas linhas são esperadas.
Nenhum conflito com a constituição: nada rodou no host além das ferramentas do lab (QEMU, ssh, rsync,
ImageMagick, python3, Docker pro Chromium do mockup), e toda tarefa tem evidência da VM.

## Custo no host (`lab/perf`)

| Sessão | Duração | CPU do host acima da base | CPU da VM |
|---|---|---|---|
| `2026-10-29T102807` US2 + recriar a VM | 1575 s | +8,9 pp | 491 s |
| `2026-10-29T105454` US3 | 1164 s | −0,6 pp | 394 s |
| `2026-10-29T111419` US4 | 1300 s | +1,8 pp | 466 s |
| `2026-10-29T113600` US5 + galeria | 1322 s | +4,4 pp | 464 s |
| `2026-10-29T115809` US6 | 1002 s | +3,1 pp | 368 s |
| `2026-10-29T121451` US7 | 1505 s | +5,2 pp | 611 s |
| `2026-10-29T123957` T054–T057 (o roteiro inteiro, 4 rodadas, e o mockup no container) | 3045 s | +3,2 pp | 1539 s |

A enxurrada de 100 custa pouco: o CPU do `qs` volta ao repouso em 5 s (4% contra 4%) e o log abre em
≈ 60 ms.

## Pendências pro dono

1. **Aprovação visual (SC-013):** `out/008-revisao.png`.
2. **Atalhos** `SUPER + N` / `SUPER + CTRL + N` (na VM, `ALT`): continuam provisórios.
3. **"Do not dist…" cortado** no quadro de opções do log (a largura do valor é a `stepperValueW` da
   003/004). Recomendação: uma coluna de valor mais estreita só pro toggle no modo `fluid`.
4. **Merge do `PickerLayout` com a 007:** mesma interface, texto diferente; recomendação: no merge,
   ficar com o da 007 e somar `fluid`, `lazyList` e a lista mais larga do modo `fluid`.
5. **Aviso do portal do Qt 6.12** (`qt.qpa.services`) silenciado no `guest/nier-ui-run` do lab;
   recomendação: manter até o Qt corrigir, como o `qt.qpa.wayland.textinput`.
6. **Brilho real:** só por comando na VM (sem luz de fundo); homologar na máquina do dono (U7).
