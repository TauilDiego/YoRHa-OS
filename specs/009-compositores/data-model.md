# Modelo de dados: estudo 009 (compositores)

Os dados do estudo são arquivos no repositório privado do lab (`lab/009/`) e no `$LAB_HOME`, mais o
documento público `docs/estudo-compositores.md`. Não há banco nem serviço. Os formatos de arquivo estão
nos contratos ([lab-compositor.md](contracts/lab-compositor.md), [amostras.md](contracts/amostras.md),
[relatorio.md](contracts/relatorio.md)); aqui ficam as entidades, os campos e as regras.

## Camada (existente, ganha a marca de compositor)

| Campo | Onde | Regra |
|---|---|---|
| `nome` | `$LAB_HOME/vms/<nome>.qcow2` | Único. As novas: `hypr-iso`, `niri-base`, `mango-base`, `teste-niri`, `teste-mango`; descartáveis: `spike-3d`, `hypr-plugins`, `teste-hiso`, `teste-<c>-custo` |
| `base` | `$LAB_HOME/vms/<nome>.base` | Como hoje (`hypr-base`, `arch-iso`, `iso:<versão>`, `incompleta:<passo>`) |
| `compositor` **novo** | `$LAB_HOME/vms/<nome>.compositor` | `hyprland`, `niri` ou `mango`. Gravado só nas bases que a preparação cria (`hypr-iso`, `niri-base`, `mango-base`). Uma camada sem o arquivo herda da base (sobe a cadeia do `.base`); sem nenhum na cadeia, `hyprland` (a `hypr-base` antiga e as camadas dela continuam funcionando sem mudança) |
| `congelada` | permissão do disco | Como hoje (`lab/freeze`) |
| `sha256` | `lab/009/bases.sha256` | Tirado das bases congeladas no começo e no fim do estudo (SC-002) |

**Transições da cadeia do Hyprland (US1):**

```
hypr-iso montada ──(roteiros 15/0, 25/0, 58/0)──▶ promovida (padrão do lab/new e do bootstrap)
      │                                                │
      └──(algum roteiro falha)──▶ não promovida         └─▶ teste-* recriadas, uma por vez, se livres
                                  (a hypr-base segue                (ocupada → pendente no resumão)
                                   a padrão)
hypr-base antiga ──(OK do dono)──▶ apagada   (o estudo nunca faz essa transição sozinho)
```

**Regra de "livre"** (FR-004): a camada não aparece ligada em `lab/ls`, nenhum processo
`qemu-system` cita o disco dela (`pgrep -af qemu-system`), não existe `run/<nome>.pid` com processo vivo,
e nenhuma outra camada tem ela como `.base`.

## Compositor sob estudo

| Campo | Exemplo | Regra |
|---|---|---|
| `id` | `niri` | `hyprland`, `niri`, `mango` |
| `pacote` | `niri 26.04-1 (extra)` / `mangowm 0.18.3-1 (extra)` / `hyprland 0.56.2-4 (extra)` | Os três do repositório oficial, na data fixa do Arch Linux Archive (research R15); a versão vai pro relatório (FR-012, FR-014) |
| `como_sobe` | `uwsm start hyprland.desktop` / `niri-session` / `mango` | O jeito oficial de cada um (research R5); uwsm no Niri e no Mango só como spike, anotado (FR-008) |
| `config_lab` | `lab/guest/niri/config.kdl` | Mesmos atalhos em ALT (FR-011) |
| `versoes` | compositor, Quickshell, Qt, mesa | Lidas na VM e guardadas em `lab/009/versoes/<id>.txt` (FR-014) |

## Resultado de ferramenta

Uma linha de `lab/009/ferramentas.tsv`: `ferramenta`, `compositor`, `resultado` (`ok`, `contorno`,
`falha`), `prova` (caminho do screenshot, saída ou id do `lab/perf`), `nota`. 10 ferramentas × 3
compositores = 30 linhas (SC-004).

## Item da UI

Uma linha de `lab/009/ui/itens.tsv`: `item` (barra, abas, título, relógio, bateria, papel de parede,
configurações, seletor, contraste), `compositor`, `perfil` (`1080`, `hidpi`), `estado` (`funciona`,
`parcial`, `quebra`), `screenshot`, `log` (as linhas do `ui.log`, ou `-`), `nota`. Junto, por compositor:
`lab/009/ui/<id>/ui.log` (a partida inteira) e `import-hyprland.txt` (o que o import fez; FR-021).

## Amostra

Uma consulta ou ação de uma linha do §6 do contrato, num compositor, num estado conhecido da VM.
Formato e índice em [contracts/amostras.md](contracts/amostras.md).

| Campo | Regra |
|---|---|
| `linha` | Uma das 10 linhas do §6 (`L01`…`L10`) ou uma pergunta extra (`Q-…`) |
| `compositor` | `hyprland` (referência), `niri`, `mango` |
| `cenario` | O estado da VM (`S0` vazio, `S1` padrão, `S2` hidpi, `S3` dois monitores) |
| `comando` | Exatamente o que rodou, pelo `lab/ipc` |
| `saida` | O arquivo com a saída crua (JSON ou texto) |
| `estado` | `confirmada`, `corrigida` ou `nao-existe` (FR-024) |
| `correcao` | O comando certo, se `corrigida`; o contorno, se `nao-existe` |

## Capacidades (proposta por compositor)

Os seis campos do §3 do contrato, cada um com as amostras que o justificam:
`workspaceModel`, `canFloat`, `canMoveToWorkspace`, `actsOnAnyWindow`, `hasGeometry`, `fullscreenKnown`.
Mais a regra de detecção (§1: a variável de ambiente que a sessão define). Guardadas em
`lab/009/capabilities.json` e copiadas pro relatório (FR-026).

## Medida de custo

Uma linha de `lab/009/custo.tsv`: `compositor`, `rodada` (1–3), `boot_ate_ui_s`, `ram_parado_mb`,
`cpu_parado_pct`, `perf_id`, `nota`. Regras: mesma VM (2 núcleos, 4 GB), perfil 1080, `--headless`, a
mesma UI (`main`), sem fixtures, sem janela aberta; a mediana e a maior diferença entre rodadas vão pro
relatório (FR-032, SC-009). Detalhes da coleta em [research.md](research.md) R10.

## Rajada de animação

Uma pasta `lab/009/rajadas/<id>/<acao>/` (`abrir`, `fechar`, `trocar-area`, `mover`), com os quadros e o
`times.txt` do `lab/burst`, mais `resumo.txt` (quadros com mudança, duração aparente, quadros quebrados
observados). Não vira nota: é evidência pra folha do dono (FR-033).

## Critério e nota

| Campo | Regra |
|---|---|
| `criterio` | Os 8 da spec (4 de experiência, 4 técnicos) |
| `peso` | Aprovado (15/15/10/20 e 15/10/10/5) |
| `quem_da` | `agente` nos técnicos; `dono` nos de experiência (Clarifications) |
| `nota` | 0–3, ou vazia enquanto o dono não preencher |
| `evidencia` | Caminhos, ids do `lab/perf` ou fontes marcadas "pesquisa" |
| `eliminatorio` | Os três da spec; um compositor eliminado sai da conta, mas fica no relatório |

**Pontuação:** `Σ (peso × nota) / 3`, de 0 a 100, com os pesos aprovados e com pesos iguais. Só é
calculada com as 8 notas presentes; antes das notas do dono, o relatório mostra só a parte técnica
(máximo 40) e escreve "recomendação pendente" (FR-035a).

## Folha de notas (sessão do dono)

`lab/009/sessao/folha.md`: por compositor (Hyprland, Hyprland com plugin de visão geral, Niri, Mango) e critério de
experiência, a evidência juntada pelo agente, as âncoras 0–3 e um campo vazio pra nota e um pra
comentário. O agente nunca preenche a nota. 4 critérios × 3 compositores = 12 campos obrigatórios, mais
1 da linha "com plugin" (visão geral; as colunas do Hyprland já são nativas, research A5), que não entra na conta oficial (FR-038).
