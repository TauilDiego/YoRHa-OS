# Quickstart: validar a 019

Tudo roda no lab privado (`YoRHa-OS-private/lab/`, branch `lab-019`), nunca no host. Cada rodada: `NIER_LAB_VM=<vm> NIER_LAB_CPUS=4 NIER_LAB_MEM=4G`, com
`lab/perf begin "<teste>"` antes e `lab/perf end --result …` depois. Nos dois perfis: 1080 e `NIER_LAB_PROFILE=hidpi` (`lab/profile hidpi`, escala 1,25). Os detalhes de
valores estão em `research.md` (R3) e `contracts/`.

## Preparar uma camada

```
lab/new t-<tema>-x --from hypr-iso
NIER_LAB_PROFILE=hidpi lab/up t-<tema>-x
lab/provision-step notify          # áudio nulo, brightnessctl, libnotify
lab/provision-step sound           # qt6-multimedia e os backends que o shell usa nos sons
lab/019/audio-sinks                # o segundo sink
YORHA_REPO=<worktree> lab/sync
```

## A prova da base (T003, antes de tudo)

```
lab/new t-prova-56 --from hypr-iso; lab/new t-prova-57 --from hypr-057
lab/019/prova-base t-prova-56; lab/019/prova-base t-prova-57
```

**Esperado:** P1 a P9 `PASS` nas duas versões, `sondagem.md` preenchida. Falha em P1 a P7: parar (R1).

## Rodar a check-019

```
lab/check-019 [--only contract,filewins,adapter,audio,reads,keyboard,appearance,catalog] [--profile 1080|hidpi|both] [pasta]
```

| Bloco | Cenários | Esperado em poucas palavras |
|---|---|---|
| `contract` | US1.1 a US1.3, US1.5 | A linha de prova lê, muda, fica apagada; valores velhos somem em duas subidas |
| `filewins` | US6.3, US6.4, US6.7 | A chave editada vale; JSON quebrado não esquece; `defaults.json` mudado não esquece |
| `adapter` | US7.1 a US7.4 | Linhas somem no `none`; `niri` nunca é Hyprland; a busca não acha código |
| `audio` | US2.1 a US2.8, US1.4 | `wpctl` e `settings dump` batem; a saída sobrevive ao reboot; sem cópia no estado |
| `reads` | US3.1 a US3.7 | Apagadas com o motivo certo na VM, valores do fixture, `monitors -j` igual, nas duas telas |
| `keyboard` | US4.1 a US4.11, US6.1, US6.5, US6.6, US6.8 | `getoption -j` depois de cada passo; `sha256sum` do `hyprland.lua` igual |
| `appearance` | US5.1 a US5.6, US6.2 | Nada cortado, `geometry` dentro da área, reset volta ao `shell.json` |
| `catalog` | SC-001, SC-002, SC-004, FR-035 a FR-038 | Nada falso no dump das 15; nada salvo de som e luz |

## A rodada inteira (SC-005)

Em 1080 e em 1,25, cada uma medida: `check-003`, `004`, `007`, `008`, `013`, `014`, `015`, `019`. **Esperado:** `results.txt` e `summary.txt` sem FAIL, `ui.log` sem WARN nem ERROR além dos
marcados `expected-warn` (o `no backend for "niri"`, o JSON inválido de propósito, e o `Ignoring dummy output` do Qt Multimedia, sem nenhuma saída de som). O `QSocketNotifier` não é marcado:
é um FAIL no bloco `audio` enquanto a causa não for corrigida (`fix-laco-log`).

## Antes e depois

Um screenshot por categoria mudada (Display, Sound, Keyboard, Appearance, Power), antes e depois, nas duas telas, em `out/019-antes-depois/`, pro dono (SC-006).
