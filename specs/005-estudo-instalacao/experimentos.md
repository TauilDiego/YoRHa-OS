# Desenho dos experimentos: Estudo de instalação

O que é medido em cada método, como, e como as medidas viram uma escolha. O roteiro de execução no
laboratório está no [quickstart.md](quickstart.md); as decisões que sustentam este desenho estão no
[research.md](research.md) (R-n).

## 1. Pergunta e hipótese

**Pergunta:** qual jeito de entregar e atualizar a camada (com a UI como carga) é o mais seguro pro
usuário e o mais barato de manter pro dono, sem violar a constituição III?

**Hipótese de partida (a testar, não uma conclusão):** a combinação **A+D** (tags do git como fonte,
versões lado a lado com troca atômica e `rien rollback`) ganha, porque fica com o custo de
infraestrutura do A (só git) e a volta do D. **C** deve ganhar em confiança, dependências e desinstalação,
mas custa uma chave, hospedagem e CI. **B** deve perder em manutenção e disponibilidade. O desenho abaixo
foi feito pra poder **derrubar** essa hipótese: os pesos vêm antes das medidas (R16) e a conta é mostrada
também com pesos iguais.

## 2. Ambiente

| Peça | Como | Por quê |
|---|---|---|
| **Camada `u2-base`** (congelada) | `arch-limpo` + Hyprland, uwsm, kitty, login automático e um `u2-ui-run` que abre `rien-shell` quando ele existir. **Sem** `quickshell`, Qt 6 extra, `qt6-shadertools` nem fontes da UI | Pra instalação ter que resolver as dependências da carga (FR-009). A `hypr-base` já traz tudo e esconderia isso |
| **Mirror fixo** | O pacman da `u2-base` aponta pro Arch Linux Archive numa data fixa (R13) | Mesmas versões de pacote em todas as execuções |
| **VMs de execução** | `lab/new u2-<método>-<n> --from u2-base`, apagadas no fim; `NIER_LAB_CPUS=2 NIER_LAB_MEM=4G` (limite do dono), perfil `1080`, uma por vez | Mesmo ponto de partida e mesmos recursos pros quatro. Não usa `teste-a/b/c`, que são de outros agentes |
| **Servidor de distribuição** | Container `nier-lab` com HTTP estático e log de bytes, porta só em `localhost`; a VM chega por `10.0.2.2` (R11) | Simula GitHub, AUR, repositório pacman e pacotes de versão sem publicar nada |
| **Fábrica** | Container de Arch (`nier-lab`), usuário sem privilégio: `makepkg`, `repo-add`, `gpg` com chave descartável do lab | Constituição I: build nunca no host |
| **Carga** | `shell/` do commit fixado + remendos 0.2 e 0.3 do lab ([data-model.md](data-model.md)) | Mesma carga pros quatro (FR-001, FR-002) |
| **Usuário de teste** | `arch` (sudo sem senha no lab) com `~/.config/rien-os/shell.json` e `~/.config/hypr/` de exemplo; `beta`, criado só no S9 | Prova da constituição III e caso de dois usuários |

## 3. Os quatro protótipos

Todos cumprem o [contrato de entrega](contracts/contrato-de-entrega.md): `rien-shell`, `rien version`,
`rien update [--check]`, `rien rollback`, `rien migrate`, `rien uninstall`, os mesmos caminhos de estado e
o mesmo formato de migration. A tabela mostra só o que muda.

| | **A. script + git** | **B. AUR (simulado)** | **C. repositório pacman** | **D. versões lado a lado** |
|---|---|---|---|---|
| **Instalar** | `curl …/boot.sh \| bash`: `pacman -S git`, `git clone --branch v0.1` em `~/.local/share/rien-os`, `install.sh` (dependências da lista com `pacman -S --needed`, shaders, `rien-shell` em `~/.local/bin`, migrations marcadas) | `pacman -S --needed base-devel git`, `git clone` da receita, `makepkg -si` (dependências pelo `depends=`, shaders no `build()`), carga em `/usr/share/rien-os` | importar a chave do lab (`pacman-key --add`, `--lsign-key`), bloco `[rien-os]` no `pacman.conf`, `pacman -Syu rien-os` | `curl …/install-d.sh \| bash`: baixa o tarball de 0.1 + soma + assinatura, confere, extrai em `versions/0.1`, dependências com `pacman -S --needed`, liga `current` |
| **Atualizar** | `rien update`: `fetch --tags`, backup dos arquivos gerenciados editados, `checkout` da maior tag, pacotes novos, shaders, migrations, reinicia a UI | `git pull` da receita + `makepkg -si`; migrations no próximo `rien-shell` (R8) | `rien update` = `sudo pacman -Syu` + migrations; ou só `pacman -Syu`, e as migrations rodam no próximo `rien-shell` | baixa e confere 0.2 em `versions/0.2`, pacotes novos, backup do estado, migrations, troca atômica de `current` (R5) |
| **Aviso** | `git ls-remote --tags` | `.SRCINFO` remoto | `checkupdates` | arquivo `latest` |
| **Voltar** | `git checkout` da tag anterior (o que acontece com o estado migrado é medido) | `makepkg` da receita anterior ou `pacman -U` do pacote montado antes | `sudo pacman -U` do pacote anterior no cache | `rien rollback`: troca `current` e restaura o backup do estado |
| **Desinstalar** | apaga a pasta e o `rien-shell`; dependências ficam | `pacman -Rns rien-os` | `pacman -Rns rien-os` + tirar o repositório e a chave | apaga `versions/`, `current`, `rien-shell`; dependências ficam |
| **Confiança** | HTTPS + tag assinada (`git verify-tag`), se ligado | `sha256sums` na receita | assinatura GPG do pacote e do banco (`SigLevel Required`) | `sha256` + assinatura destacada |

O protótipo mais simples que cumpre o contrato ganha (constituição VII): nada de menu `gum`, canais ou
indicador na barra; isso é S3/S4.

## 4. Cenários e o que é medido

Cada cenário roda numa VM nova, dentro de uma sessão `lab/perf` própria, e grava uma
[execução](contracts/run.schema.json). Ids como no [data-model.md](data-model.md).

| Cenário | Como | O que é medido |
|---|---|---|
| **S1** instalar 0.1 (×3) | comando de instalação do método numa `u2-base` nova; espera a UI | `dur_s`, `ui_s`, bytes de carga e de dependências, pedidos de `sudo`, passos manuais (comandos que o usuário digita), espaço em disco, screenshot, log de QML |
| **S2** atualizar 0.1 → 0.2 (×3) | publica 0.2 no servidor; `rien update` (ou o comando nativo, em B/C) | o mesmo de S1, mais: dependência nova instalada sozinha, migration aplicada (formato 2), `~/.config` igual |
| **S3** update de novo | `rien update` com 0.2 instalada | nada muda: nenhuma migration, nenhum arquivo reescrito (mtime e soma da carga), `dur_s` |
| **S4** aviso | 0.1 instalada, 0.2 publicada; `rien update --check` | detecta, precisa de root, bytes, tempo |
| **S5** versão quebrada e volta | 0.2 → 0.3 (UI não abre) → volta pra 0.2 pelo jeito do método | a UI 0.3 falha como esperado; a volta existe; passos, `sudo`, tempo até a UI 0.2 responder; estado legível pela 0.2 (formato 2 de volta, ou não) |
| **S6a/b/c** interrupção | `U2_PAUSE_AT=download\|apply\|migrate`, QMP `quit` na fase (R12); religa | a UI abre? qual versão? o estado (formato) é coerente? `rien update` seguinte conserta sozinho? passos e tempo de recuperação |
| **S7a/b** sem rede | servidor parado antes da instalação (a) e no meio do download do update (b) | mensagem de erro clara; nada pela metade no disco; a 0.1 continua no ar (b) |
| **S8a** carga adulterada | um QML trocado no artefato do servidor depois de publicar (metadados intactos) | o método recusa? com qual mensagem? |
| **S8b** carga e metadados adulterados | o mesmo, regerando soma/receita/banco **sem** a chave do dono (outra chave ou nenhuma) | recusa só quem tem assinatura; registra o que cada método confia |
| **S9** segundo usuário | depois do S2, cria `beta`, entra na sessão como `beta` | as migrations rodam pra `beta` na entrada; a casa de `beta` só muda dentro de `~/.local/state/rien-os` |
| **S10** arquivo gerenciado editado | antes do S2, edita um arquivo da carga instalada | conflito, sobrescrita silenciosa ou backup; a UI 0.2 abre? |
| **S11** desinstalar | `rien uninstall` (ou o nativo) com 0.2 instalada | arquivos que sobram (lista de `find` antes da S1 × depois), pacotes órfãos, repositório e chave que ficam |
| **S12** publicar 0.2 (dono) | um agente segue o passo a passo de publicar do protótipo, do commit pronto até a 0.2 disponível | passos manuais, tempo, segredos tocados, infraestrutura que precisa existir, o que obriga a republicar sem mudança no projeto |
| **S13** cursor (opcional) | instalar o tema de cursor como segunda carga: montado no destino (A, D) × pronto no pacote (B, C) | tempo, bytes, pacotes de build que ficam na máquina do usuário |

**Medidas comuns a toda execução:** soma de `~/.config` antes e depois (G1), `ui_s`, log de QML sem
erro (fora o S5), resumo do `lab/perf` (custo no host).

## 5. Critérios, pesos e notas (fixados antes de medir)

**Obrigatórios (eliminam antes da conta, FR-014):**

| id | Elimina se |
|---|---|
| G1 | algum arquivo do usuário em `~/.config` mudou sem backup, em qualquer execução |
| G2 | não há como rodar migrations por usuário (incluindo o segundo usuário, S9) |
| G3 | depois de uma interrupção (S6) a máquina fica sem UI **e** sem caminho de recuperação documentado |

**Pontuados (pesos de partida; somam 100; nota 0–3):**

| id | Critério | Peso | 3 | 2 | 1 | 0 | Cenários |
|---|---|---|---|---|---|---|---|
| K1 | Update correto | 15 | dependência nova, migration uma vez e idempotência, sem passo extra | um passo manual a mais | migration ou dependência exige intervenção | update falha | S2, S3, S9 |
| K2 | Volta de versão | 15 | um comando, estado restaurado, ≤ 1 min | um comando, estado não restaurado ou > 1 min | possível com vários passos manuais | não dá | S5 |
| K3 | Interrupção | 10 | os três pontos terminam com UI no ar, sem ação | o próximo update conserta sozinho | recuperação manual documentada ≤ 5 min | pior que isso | S6 |
| K4 | Sem rede | 5 | erro claro, nada pela metade, versão anterior no ar | erro confuso mas inofensivo | sobra lixo que o próximo update limpa | quebra a versão instalada | S7 |
| K5 | Confiança | 10 | recusa S8a e S8b; o usuário confia uma vez | recusa S8a; S8b passa | só HTTPS | nada | S8, pesquisa |
| K6 | Manutenção do dono | 20 | publicar ≤ 3 passos, sem segredo nem infraestrutura nova | ≤ 6 passos ou uma peça de infraestrutura | chave + hospedagem + CI | depende de terceiros fora do controle do dono pra cada release | S12, R3, R4, R7 |
| K7 | Primeira instalação | 5 | 1 comando, dependências sozinhas, ≤ 1 pedido de `sudo` | 2–3 comandos | passos manuais com edição de arquivo do sistema | falha | S1 |
| K8 | Aviso de update | 5 | sem root, ≤ 2 s, ≤ 10 KB | sem root, mais lento ou maior | precisa de root ou sincroniza o banco do sistema | não há | S4 |
| K9 | Desinstalação e disco | 5 | não sobra nada além do estado do usuário | sobram dependências | sobram arquivos do projeto fora de `~/.local` | sobra configuração do sistema (repositório, chave) sem aviso | S11, S1 |
| K10 | Encaixe no modelo | 10 | camadas, módulos, camada pessoal privada e S5/S7 sem nada novo | um deles pede adaptação | dois ou mais pedem | contraria a constituição II ou III | pesquisa, S10 |

**Conta:** `pontos = Σ peso × nota / 3` (0–100), só entre os que passaram nos G. Empate (≤ 5 pontos):
vence quem tiver K6 maior, depois K2. O documento também mostra a conta com pesos iguais (10 cada).

**A+D:** sem protótipo próprio. A nota de cada critério é tirada das execuções de A (transporte: K5, K6,
K7, K8) e de D (layout: K2, K3, K4, K9), e o documento diz de onde veio cada célula. Se A+D vencer, a S3
começa com um protótipo dela, medido de novo em S1, S2, S5 e S6.

## 6. Protocolo

1. **Antes de medir:** fixar o commit da carga, a data do mirror e este §5 num commit desta branch (R16).
   **Fixado em 2026-10-27:** carga = `shell/` do commit `422cca7`; mirror = Arch Linux Archive de
   2026-10-26; §5 sem mudança (pesos confirmados pelo dono).
2. **Montar uma vez:** a `u2-base`, o servidor e a fábrica (sessão `lab/perf` "005: preparação").
3. **Validar cada protótipo** com uma S1 sem contar (estado `prototipado`).
4. **Execuções de tempo (S1, S2, S3, S4, S13):** **uma VM por vez**, na ordem A, B, C, D, depois D, C,
   B, A, depois A, B, C, D (ordem alternada, pra um efeito de cache ou de horário não favorecer um
   método). Três repetições; o documento usa a mediana e mostra o mínimo e o máximo.
5. **Execuções de função (S5–S12):** rodam em sequência, uma VM por vez (limite do dono, 2026-10-27). Delas só se usam resultados e tempos grossos (o limite de 5 min do
   SC-006), não as medianas.
6. **Toda execução** fica numa sessão `lab/perf begin "005: <método> <cenário> #n" --kind 005-u2 --task 005/<T>`
   e termina com `lab/perf end --result pass|fail`. "fail" quer dizer que o cenário não rodou, não que o
   método perdeu: um método que quebra no S5 é um resultado válido, com `--result pass`.
7. **Uma execução que falha por erro do protótipo** (não do método) é corrigida e refeita; o documento
   conta quantas foram refeitas e por quê.

## 7. O documento final (`docs/estudo-instalacao.md`)

1. **Resumo (uma página):** a escolha, em três frases; a tabela de pontos; o que muda na S3 e na S4.
2. **Como foi medido:** ambiente, carga, cenários, pesos (link pra esta spec).
3. **Matriz:** critério × método, nota, justificativa e ids de execução ou fontes.
4. **Eliminados** e por quê (G1–G3).
5. **Medidas:** tabelas de tempo, bytes, `sudo` e disco (mediana, mín., máx.).
6. **O que deu errado em cada método** (S5–S10), com a recuperação.
7. **Entradas pra S3:** estrutura de pastas, ponto de entrada, dependências, instalação.
8. **Entradas pra S4:** passos do update, onde rodam as migrations, volta, aviso, canais (se houver).
9. **Pesquisa:** o que não foi medido, com fonte, marcado como pesquisa.
10. **Ameaças à validade** (§8).

Em português, sem nada do lab privado além do necessário (nada de portas, chaves ou caminhos da máquina
do dono).

## 8. Ameaças à validade

- **A VM não é a máquina real:** disco e rede virtuais; os tempos servem pra comparar métodos entre si,
  não como promessa de tempo pro usuário.
- **Servidor local:** sem latência de internet; os bytes valem, os tempos de download ficam otimistas
  igualmente pros quatro.
- **AUR simulado:** não mede a API do AUR, quedas nem a revisão do PKGBUILD pelo usuário; isso fica na
  pesquisa (R3) e na execução de referência com o yay.
- **Carga pequena** (~4,6 MB, quase tudo fonte): métodos que baixam a carga inteira a cada update não
  aparecem caros aqui; o documento extrapola com o tamanho esperado da camada inteira (S3), marcado como
  estimativa.
- **Autor dos protótipos = autor da hipótese:** pesos antes das medidas, conta com pesos iguais, e o
  dono revisa os protótipos antes das execuções de tempo, se quiser.
