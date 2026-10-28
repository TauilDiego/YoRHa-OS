# Contrato: o relatório, a colinha e a folha de notas

## `docs/estudo-compositores.md` (repositório público, português)

Sai em **duas etapas** (FR-035a):

| Etapa | Quando | O que tem | O que não tem |
|---|---|---|---|
| **1. Técnica** | Depois das US1–US4 e da preparação da sessão | Tudo abaixo, com as notas técnicas e a evidência de experiência | Nota de experiência, conta completa, recomendação ("pendente: notas do dono") |
| **2. Final** | Depois que o dono devolve a folha de notas | As notas do dono copiadas da folha, a conta completa (pesos aprovados e iguais), a recomendação | — |

Seções, nesta ordem:

1. **Resumo** (uma página): a pergunta, o que foi feito, os números principais, a recomendação (ou
   "pendente").
2. **Como foi medido:** as camadas (todas sobre a `arch-iso`), a VM (2 núcleos, 4 GB, virgl), a UI
   (`main` `a3a9120`), os limites da VM (fluidez, gestos de touchpad, um monitor).
3. **Tabela Hyprland × Niri × Mango** (uma coluna por compositor, mais "Hyprland com plugin" onde fizer
   sentido):
   - instalação: repositório oficial ou AUR, versão, data fixa dos pacotes, dependências que vieram junto;
   - como sobe: uwsm ou outro, login automático;
   - protocolos que a UI e o lab usam: layer-shell, captura de tela, gerência de saídas, lista de
     janelas;
   - IPC: o que lê, o que faz (em qualquer janela ou só na em foco), eventos;
   - `capabilities` propostas;
   - a UI da `main`: o que funciona, o que é parcial, o que quebra; o efeito do `import
     Quickshell.Hyprland`;
   - custo medido: boot até a UI, RAM e CPU parado (mediana de 3 e a maior diferença);
   - riscos de manutenção: cadência de lançamentos, quebras recentes de config ou IPC, quantas pessoas
     mantêm, plugins (só Hyprland);
   - os quatro critérios de experiência: a evidência e, na etapa 2, a nota do dono.
4. **Conta:** pesos, notas e o resultado, com os pesos aprovados e com pesos iguais, numa tabela que dá
   pra refazer à mão. Eliminados, com o motivo.
5. **Recomendação:** a regra aprovada aplicada; se o relatório recomendar diferente, o porquê.
6. **Proposta de mudança no contrato da 007:** a tabela §6 corrigida (do `lab/009/tabela-s6.md`), as
   `capabilities` de cada compositor e a regra de detecção do §1 confirmada ou corrigida.
7. **O que fica pra S5:** o que o `NiriBackend`/`MangoBackend` precisam, o que a fachada precisa
   esconder, e os riscos.
8. **Fontes:** cada afirmação de pesquisa com link; as evidências do lab citadas por id (`lab/perf`,
   amostra, screenshot), sem caminhos do host.

**Regras:** toda célula tem evidência ou a marca **(pesquisa)** com fonte (FR-037). Nada de dados
pessoais, caminhos do host do dono ou segredos (FR-042). Os screenshots não vão pro repositório público;
o relatório cita o id e o sha256 que o `lab/shot` registrou.

## Colinha da sessão manual (`lab/009/sessao/colinha-<id>.md`, até 30 linhas cada)

Por compositor (Hyprland, Niri, Mango; mais uma pro Hyprland com plugin):

```
Ligar:     NIER_LAB_VM=teste-niri NIER_LAB_CPUS=2 NIER_LAB_MEM=4G lab/up teste-niri --window
           (depois: lab/profile 1080   ou   NIER_LAB_PROFILE=hidpi … e lab/profile hidpi)
Desligar:  lab/down teste-niri
Atalhos do lab (ALT): Enter kitty · Q fecha · I configurações · W papel de parede · 1…5 áreas
Atalhos nativos que valem testar (já trocados pra ALT na config do lab):
  visão geral: …   coluna/rolagem: …   mover janela: …   tela cheia: …   flutuar: …
O que olhar:
  visão geral — …
  colunas — …
  animações — abrir, fechar, trocar de área, mover (a VM não serve pra julgar fluidez)
  uso diário — …
Gestos de touchpad: não passam pela VM; o que a documentação diz: … (pesquisa)
Colisões: atalhos nativos que o ALT do lab escondeu: …
```

## Folha de notas (`lab/009/sessao/folha.md`)

Uma tabela por critério de experiência. Exemplo:

```
### Visão geral das janelas (peso 15)
Âncoras: 0 não existe nem por plugin · 1 só por plugin/script · 2 nativa, limitada · 3 nativa, completa

| Compositor | Evidência (agente) | Nota do dono (0–3) | Comentário |
|---|---|---|---|
| Hyprland | (o que vem no Hyprland puro: …) | | |
| Hyprland com plugin* | (cópia da comunidade do hyprexpo: rajada …, screenshot …) | | |
| Niri | (toggle-overview: rajada …, screenshot …, doc …) | | |
| Mango | (toggleoverview: …) | | |
* não entra na conta oficial (FR-038)
```

O agente preenche só a coluna "Evidência". Quando o dono devolver a folha, as notas vão pro relatório
(etapa 2) sem mudança.
