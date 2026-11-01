# Relatório da 012: linhas do boot na hora

Branch `012-linhas-do-boot`, de 29.10.2026. Spec, plano e tarefas aprovados pelo dono no mesmo dia
("pronto agora roda ele"). Uma frente só, sem agentes paralelos, na VM `teste-011` (camada `boot-iso`,
com a 011 instalada pelo módulo).

## O que mudou

- **`typing=instant`, o novo padrão:** cada linha aparece inteira no quadro em que a etapa chega, sem
  digitação, letra sorteada, nascimento apagado ou intervalo entre linhas. Só o glitch se mexe.
- **Até 4 linhas novas por quadro**, porque cada linha desenha três imagens (texto, cópia vermelha e
  brilho).
- **As linhas de grupo** ("Starting system services (5)") saem no máximo a cada 0,5 s, com a contagem
  acumulada.
- **`typing=game`** guarda a digitação da 011 como opção.
- **A película com metade da opacidade (0,5).** O dono viu na janela da VM e aprovou junto.
- **Documentação:** a opção está no `config`, no README do tema e no contrato
  `specs/011-boot-e-login/contracts/plymouth-theme.md`, que ganhou também a linha do `debug`.

## Evidência (VM do lab, `teste-011`, 4 núcleos / 4 GB, `--soft` em 1920×1080)

| Critério | Resultado | Evidência |
|---|---|---|
| SC-001: ≥ 15 linhas antes da saída, nenhuma pela metade | ✅ 32 linhas em ~2,5 s (até 20 na tela de uma vez); nenhum dos quadros da rajada mostra linha cortada | `out/bootcap-teste-011-20261030-194219` (um quadro a cada 0,1 s; a lista vai de 5,9 s a 8,4 s, o login sobe em 9,7 s) |
| SC-002: ≥ 25 quadros/s na rajada | ✅ 35,4 quadros/s no segundo da rajada (14,3 no primeiro, que é a entrada de 1 s, como na 011) | `out/bootcap-teste-011-20261030-194455`, com `debug=on` |
| SC-003: login ≤ +1 s em relação ao boot sem tema | ✅ +0,90 s: 3,01 s sem tema (3,0 / 3,0 / 3,0) e 3,91 s com a 012 (3,9 / 3,9 / 3,9) | `lab/011/boot-timing teste-011 3`, nas duas situações, no mesmo dia |
| SC-004: `typing=game` digita como a 011 | ✅ letra a letra com a letra sorteada na ponta; 2 linhas num boot rápido | `out/bootcap-teste-011-20261030-195217` |
| SC-005: o dono aprova na janela | ✅ 29.10: viu e gostou | sessão do `lab/perf` "012 instalar e testar" |

As pastas `out/` ficam em `~/.local/share/nier-lab/`.

**Relatórios do `lab/perf`:**

- `2026-10-30T194132-vm-012-t004-t005-evidencia-das-linhas-do-bo`: 11 min, CPU média 4,5 pp acima da
  base, 19 comandos, nenhum com erro.
- O relatório "012 instalar e testar", de 29.10, cobre a sessão do dono.

## O que aprendi no caminho

- **A captura pesa na medição.** Com um quadro a cada 0,1 s, os screendumps do QMP em 1080p tiram CPU
  da VM, e a rajada caiu pra 19,2 quadros/s. Com um a cada 0,5 s, deu 35,4. Pra medir quadros/s, use
  `--every 0.5` ou mais. A captura densa serve pra procurar linha cortada.
- **O `boot-timing` sobe a VM sozinho.** Sem `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G` no ambiente, ele usa
  o padrão do lab (8 núcleos e 8 GB). Eu medi assim na primeira vez (+0,90 s, 3,11 → 4,01 s) e refiz
  a 4/4, com a mesma diferença.
- **A conta da 011 mudou um pouco.** Ontem ficou +0,80 s, contra 3,05 s de base medida em outro dia.
  Hoje, com a base remedida, a 012 fica em +0,90 s. A 012 não mexe no caminho até o login (a saída
  continua de 0,4 s), então a diferença deve ser variação entre dias. Mesmo assim, a margem pro limite
  de 1 s está curta.

## Limites e pendências

- **Margem de 0,1 s no SC-003.** Se alguma coisa nova entrar no caminho até o login, o limite estoura.
  As saídas possíveis já estão na revisão da 011: cortar o fade da saída (~0,45 s) ou enxugar o tema
  no initramfs.
- **Só no `--soft` em 1080p.** O perfil hidpi não foi medido nesta spec. A 012 não muda nada que
  dependa da resolução além do que a 011 já cobria.
