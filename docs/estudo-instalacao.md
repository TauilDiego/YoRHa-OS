# Estudo de instalação (U2)

Fase U2 do `PLAN.md`. Spec, plano e desenho dos experimentos em
[`specs/005-estudo-instalacao/`](../specs/005-estudo-instalacao/). Medido em 2026-10-27 no laboratório
privado; nada foi publicado (decisão 1 do dono).

## 1. Resumo

**Escolha: método D (versões lado a lado), com a tag do git como origem de cada versão e um tarball
assinado como transporte.** Cada versão da camada fica em `~/.local/share/yorha-os/versions/<v>/`, um
link `current` troca de forma atômica, o estado do usuário é copiado antes de cada migration, e
`yorha rollback` volta a versão **e** o estado num comando. D venceu com os pesos do dono (83,3) e com
pesos iguais (83,3); nenhum método foi eliminado pelos critérios obrigatórios.

| | A. script + git | B. AUR | C. repositório pacman | **D. versões lado a lado** | A+D (composição) |
|---|---|---|---|---|---|
| Pesos do dono | 76,7 | 48,3 | 61,7 | **83,3** | 81,7 |
| Pesos iguais | 76,7 | 53,3 | 63,3 | **83,3** | 80,0 |

**Por que D:**
- é o único em que a volta restaura o estado do usuário (S5);
- a versão em uso nunca é tocada durante o update: o corte de energia no meio da extração deixou a
  versão anterior intacta (S6b);
- é o mais leve na primeira instalação: 1 comando, 1 `sudo`, 2,4 s (S1);
- recusou a carga adulterada nos dois níveis (S8a e S8b);
- publicar custa só uma chave GPG e um lugar pros arquivos (GitHub Releases serve).

**O que muda na S3:** o instalador é o `install-d.sh` do protótipo, reescrito no público:
- baixa, confere sha256 e assinatura, e desempacota em `versions/<v>`;
- instala as dependências da lista `packages` com um `pacman`;
- compila os shaders no destino;
- liga `current` e os pontos de entrada em `~/.local/bin`.

**O que muda na S4:**
- **ordem do `yorha update`:** buscar e conferir → desempacotar → dependências → shaders → copiar o
  estado → trocar `current` → migrations → reiniciar a UI;
- **migrations:** rodam também no começo da sessão (`yorha-shell`);
- **aviso:** um arquivo `latest` de poucos bytes, sem root.

**Hipótese de partida** (experimentos §1, "A+D vence"): **confirmada em parte**.
- **Confirmado:** o layout de D é o que decide; ele vence K2 (volta) e K7 (instalação).
- **Não confirmado:** o transporte por `git clone` de A não acrescenta nada. Ele exige `git` (e o
  `perl` junto, 60 MB) na máquina do usuário e um segundo `sudo`. Por isso A+D (81,7) ficou atrás de
  D puro (83,3).
- **C:** ganhou em confiança e sem rede, como previsto, mas não em desinstalação (o repositório e a
  chave ficam no sistema).
- **B:** perdeu em manutenção, como previsto, e também em confiança: aceitou a carga de um atacante
  que refez a receita (S8b).

## 2. Como foi medido

| Peça | Como |
|---|---|
| Base | `u2-base`: Arch limpo (imagem oficial arch-boxes, raiz em btrfs) + Hyprland 0.56, uwsm e login automático, **sem** Quickshell, Qt 6 extra, `qt6-shadertools`, `jq` nem `git` |
| Pacotes | Arch Linux Archive fixo em **2026-10-26**, servido por um cache no lab: as mesmas versões em todas as execuções |
| Carga | `shell/` do commit `422cca7` (4,7 MB). **0.1** = a UI como está. **0.2** = "YORHA 0.2" + um selo webp na barra, dependência nova `qt6-imageformats`, e o estado do papel de parede no formato 2 (migration `monitors` → `outputs`). **0.3** = erro de QML de propósito + migration pro formato 3 |
| Servidor | container do lab fazendo o papel de GitHub, AUR e repositório pacman; registra os bytes de cada pedido (separa carga e dependências) |
| Fábrica | container de Arch sem privilégio: `makepkg`, `repo-add`, assinaturas, com uma chave descartável do lab e uma chave de "atacante" pro S8b |
| VM | uma por vez, 2 núcleos e 4 GB (limite do dono), 1920×1080 |
| Registro | um JSON por execução ([`run.schema.json`](../specs/005-estudo-instalacao/contracts/run.schema.json)), com screenshot e sha256, log de QML, `sudo` do journal, soma de `~/.config` antes e depois, e o id da sessão `lab/perf` |

**Os quatro protótipos** cumprem o mesmo [contrato](../specs/005-estudo-instalacao/contracts/contrato-de-entrega.md)
(`yorha-shell`, `yorha version`, `yorha update [--check]`, `yorha rollback`, `yorha migrate`, `yorha uninstall`):

| | Instala | Atualiza | Volta | Confere |
|---|---|---|---|---|
| **A** | `curl …/boot.sh \| bash`: `pacman -Syu git`, clone, checkout da maior tag assinada | `git fetch --tags`, backup do que o usuário editou, checkout, migrations | checkout da tag anterior | hash do git + `git verify-tag` com a chave fixada no `boot.sh` |
| **B** | `pacman -S base-devel git`, `git clone` da receita, `makepkg -si` | `git pull` + `makepkg -si` (o que um helper faz) | `pacman -U` do pacote montado antes | `sha256sums` da receita |
| **C** | chave (`pacman-key --add` e `--lsign-key`), bloco `[yorha-os]` no `pacman.conf`, `pacman -Syu yorha-os` | `pacman -Syu` + migrations | `pacman -U` do cache | assinatura GPG do pacote e do banco |
| **D** | `curl …/install-d.sh \| bash`: tarball + sha256 + assinatura, `versions/<v>`, `current` | o mesmo pra versão nova, cópia do estado, troca atômica, migrations | troca `current` de volta e restaura a cópia do estado | sha256 + assinatura com a chave fixada no `install-d.sh` |

**Execuções:**
- **tempo:** 12 cadeias S1 → S4 → S2 → S3, uma VM nova por cadeia, nas ordens A B C D, D C B A, A B C D;
- **função:** S5–S11 uma vez por método, a partir de uma camada com a 0.1 instalada;
- **S12:** a publicação, num container;
- **total:** 4 validações + 48 execuções de tempo + 51 de função + 4 publicações.

**Desvios do plano:**
- **Cadeias de tempo:** S1–S4 rodaram encadeados numa VM e numa sessão `lab/perf` por cadeia, com uma
  marca por cenário. O plano previa uma VM por cenário. O S2 de uma cadeia parte de uma 0.1 recém
  instalada, que é o mesmo ponto de partida.
- **Tudo em sequência:** as execuções de função também rodaram uma de cada vez, pelo limite do host (no
  máximo 4 VMs; esta fase, uma). Numa passagem, um defeito do roteiro deixou 4 VMs do estudo ligadas
  ao mesmo tempo. O lote foi parado e o roteiro passou a desligar a VM em qualquer saída e a recusar
  subir uma segunda.
- **S9:** a "entrada do segundo usuário" foi simulada rodando o `yorha-shell` como `beta`, sem sessão
  gráfica. As migrations rodam antes da UI, então o resultado é o mesmo.
- **S6b:** o corte é um `sysrq b` dentro da VM, que reinicia sem gravar o cache de disco, no instante
  em que o primeiro arquivo da carga muda. O desligamento pelo QMP, a partir do host, chegaria tarde
  demais pra uma extração de menos de 1 s.
- **S13 (cursor):** não rodou; ficou opcional pela decisão 3, por falta de tempo.

## 3. Matriz

Notas 0–3 com as âncoras de experimentos §5. Fontes: `X/Sn-k` = registro do método X, cenário Sn,
repetição k; `S12/x` = publicação; R-n = [research.md](../specs/005-estudo-instalacao/research.md).

| Critério (peso) | A | B | C | D |
|---|---|---|---|---|
| **K1** update correto (15) | **3**: S2, S3 3/3 ok (`A/S2-1..3`, `A/S3-1..3`) | **2**: `yorha update` ok, mas o comando nativo (`B/S2n-1`) deixa a 0.2 no ar com o estado velho até o próximo login | **2**: idem (`C/S2n-1`) | **3**: `D/S2-1..3`, `D/S3-1..3` |
| **K2** volta (15) | **2**: 1 comando, 1,2 s, estado no formato 3: a 0.2 perde a escolha do usuário (`A/S5-1`) | **2**: 1 comando, 0,8 s, estado não restaurado (`B/S5-1`) | **2**: 1 comando, 0,7 s, estado não restaurado; o próximo `-Syu` volta pra 0.3 (`C/S5-1`) | **3**: 1 comando, 0,8 s, estado restaurado (`D/S5-1`) |
| **K3** interrupção (10) | **2**: UI no ar nos 3 pontos; download e troca terminam com 1 `yorha update`, migration sozinha no login (`A/S6a..c-1`) | **2**: idem (`B/S6a..c-1`) | **2**: idem (`C/S6a..c-1`) | **2**: idem; na troca, a versão em uso não foi tocada (`D/S6a..c-1`) |
| **K4** sem rede (5) | **2**: mensagem do curl, nada instalado, mas `curl \| bash` sai com 0 (`A/S7a-1`); update recusa limpo (`A/S7b-1`) | **1**: `base-devel` e `git` ficam; no update, `qt6-imageformats` entra antes do download falhar (`B/S7a-1`, `B/S7b-1`) | **3**: nada feito; transação abortada inteira (`C/S7a-1`, `C/S7b-1`) | **2**: como A; fica só uma pasta `downloads/` vazia (`D/S7a-1`, `D/S7b-1`) |
| **K5** confiança (10) | **3**: S8a recusado (hash do git), S8b recusado (tag sem a assinatura fixada) (`A/S8a-1`, `A/S8b-1`) | **2**: S8a recusado; **S8b aceito, HUD com "PWNED 0.2"** (`B/S8b-1`) | **3**: S8a e S8b recusados (`C/S8a-1`, `C/S8b-1`) | **3**: S8a (sha256) e S8b (assinatura) recusados (`D/S8a-1`, `D/S8b-1`) |
| **K6** manutenção (20) | **2**: 2 passos, 0,1 s; segredo: chave GPG das tags (`S12/a`) | **0**: 8 passos, 6,6 s; toda versão passa pelo AUR, terceiro com regras e disponibilidade próprias (`S12/b`, R3) | **1**: 7 passos, 4,7 s; chave + hospedagem do repositório, CI na prática (`S12/c`, R2, R4) | **2**: 7 passos (6 com GitHub Releases), 0,3 s; chave GPG + Releases (`S12/d`) |
| **K7** primeira instalação (5) | **2**: 1 comando, 2 `sudo` (`A/S1-1..3`) | **2**: 3 comandos, 4 `sudo` (`B/S1-1..3`) | **1**: 5 comandos, edita `/etc/pacman.conf` (`C/S1-1..3`) | **3**: 1 comando, 1 `sudo` (`D/S1-1..3`) |
| **K8** aviso (5) | **3**: sem root, 0,1 s, 308 B (`A/S4-1..3`) | **3**: sem root, <0,1 s, 578 B (`B/S4-1..3`) | **2**: sem root, 0,8 s, 9,0 MB (`checkupdates` sincroniza cópias dos bancos) (`C/S4-1..3`) | **3**: sem root, <0,1 s, 4 B (`D/S4-1..3`) |
| **K9** desinstalação (5) | **2**: sobram `git` e as dependências (`A/S11-1`) | **1**: sobram a receita em `~/.cache`, `base-devel`, `git`, `qt6-shadertools` órfão (`B/S11-1`) | **1**: as dependências saem, o bloco `[yorha-os]` e a chave ficam; o `yorha` avisa, o `pacman -Rns` sozinho não (`C/S11-1`) | **2**: sobram as dependências (`D/S11-1`) |
| **K10** encaixe (10) | **2**: camada por usuário (o segundo usuário instala de novo, `A/S9-1`); camada pessoal = clone privado | **1**: o AUR não serve pra camada pessoal; `/usr/share` só editável como root e sobrescrito sem aviso (`B/S10-1`) | **2**: módulos e hardware viram pacotes, vários usuários ok (`C/S9-1`); camada pessoal exige repositório privado com autenticação | **2**: camada por usuário (`D/S9-1`); camada pessoal = tarballs privados, o mesmo código |

## 4. Conta

`pontos = Σ peso × nota / 3`, de 0 a 100. Pra refazer com outros pesos, troque a coluna "peso".

| Critério | Peso do dono | Peso igual | A | B | C | D |
|---|---|---|---|---|---|---|
| K1 | 15 | 10 | 3 | 2 | 2 | 3 |
| K2 | 15 | 10 | 2 | 2 | 2 | 3 |
| K3 | 10 | 10 | 2 | 2 | 2 | 2 |
| K4 | 5 | 10 | 2 | 1 | 3 | 2 |
| K5 | 10 | 10 | 3 | 2 | 3 | 3 |
| K6 | 20 | 10 | 2 | 0 | 1 | 2 |
| K7 | 5 | 10 | 2 | 2 | 1 | 3 |
| K8 | 5 | 10 | 3 | 3 | 2 | 3 |
| K9 | 5 | 10 | 2 | 1 | 1 | 2 |
| K10 | 10 | 10 | 2 | 1 | 2 | 2 |
| **Pesos do dono** | 100 | | **76,7** | **48,3** | **61,7** | **83,3** |
| **Pesos iguais** | | 100 | **76,7** | **53,3** | **63,3** | **83,3** |

**A+D** (sem protótipo próprio; experimentos §5): K5–K8 vêm de A, K2–K4 e K9 de D, e K1 e K10 são
iguais nos dois. Dá 81,7 com os pesos do dono e 80,0 com pesos iguais. Fica abaixo de D puro só no K7
(o `git` exige um segundo `sudo` e 60 MB). Pela regra de empate (≤ 5 pontos; K6, depois K2), D e A+D
empatam em K6 e K2, e o desempate cai na conta: **D**.

**A escolha não depende dos pesos:**
- D fica na frente com os dois jogos de pesos;
- A, em segundo, também ganharia de B e C nos dois;
- só um K6 de A em 3 (publicar sem assinar as tags, 2 passos, sem segredo) levaria A a 83,3. Mas aí o
  K5 de A cairia pra 2 (o S8b passaria), e A voltaria a 80,0.

## 5. Eliminados (G1–G3)

Nenhum.
- **G1:** em 103 execuções contadas, a soma de todos os arquivos de `~/.config` foi igual antes e depois.
- **G2:** os quatro rodam migrations por usuário, com marcadores em `~/.local/state/yorha-os/migrations/`.
  - **B e C:** as do segundo usuário rodam na entrada dele (`B/S9-1`, `C/S9-1`).
  - **A e D:** a camada é por usuário; o segundo usuário não tem UI até instalar a dele (`A/S9-1`,
    `D/S9-1`). Isso pesa em K10, não elimina.
- **G3:** em todas as interrupções a UI voltou no ar ao religar, e um comando recuperou.

## 6. Medidas

Mediana e mínimo–máximo de 3 repetições (VM com 2 núcleos; servidor local, então os tempos de download
são otimistas igualmente pros quatro).

**S1, primeira instalação** (carga 0.1, do zero):

| | tempo (s) | UI no ar (s) | carga (MB) | dependências (MB) | `sudo` | comandos | carga no disco (MB) |
|---|---|---|---|---|---|---|---|
| A | 5,2 (4,5–5,3) | 5,9 | 2,68 | 59,7 | 2 | 1 | 8 (com o `.git`) |
| B | 9,0 (8,6–9,4) | 9,6 | 2,65 | 155,5 | 4 | 3 | 5 |
| C | 4,1 (3,9–4,3) | 4,6 | 2,43 | 26,6 | 4 | 5 | 5 |
| D | 2,4 (2,1–2,4) | 3,1 | 2,65 | 28,4 | 1 | 1 | 5 (por versão; guarda 3) |

O que muda nas dependências:
- **A:** traz `git` (e o `perl` junto);
- **B:** traz `base-devel` inteiro;
- **C:** não precisa de `qt6-shadertools`, porque os `.qsb` vêm prontos, mas precisa de `pacman-contrib`
  e `fakeroot` pro aviso.

**S2, update 0.1 → 0.2:**

| | tempo (s) | UI 0.2 no ar (s) | carga (MB) | dependências (MB) | `sudo` |
|---|---|---|---|---|---|
| A | 0,9 (0,9–0,9) | 2,3 | 2,68 | 0,8 | 1 |
| B | 2,3 (2,3–2,4) | 3,7 | 2,65 | 0,8 | 2 |
| C | 1,4 (1,4–1,9) | 2,8 | 2,43 | 0,8 | 1 |
| D | 0,8 (0,7–0,8) | 2,1 | 2,65 | 0,8 | 1 |

Nas 12 cadeias, a dependência nova entrou sozinha, a migration rodou uma vez, a UI 0.2 abriu com a
escolha do usuário preservada e o log não teve erro de QML.

**S3, update repetido:** nenhum arquivo da carga reescrito, nenhuma migration de novo, nos quatro.
- **A, B, D:** 0,1 s, sem `sudo`.
- **C:** 0,9 s e 1 `sudo`, porque o update é um `pacman -Syu` inteiro.

**S4, aviso:**
- **A:** 0,1 s, 308 B;
- **B:** <0,1 s, 578 B;
- **C:** 0,8 s, 9,0 MB;
- **D:** <0,1 s, 4 B.

Nenhum precisou de root.

**Carga maior:** a carga do estudo tem 2,6 MB comprimida; a camada inteira (padrões, `bin/`,
migrations) deve ficar abaixo de 10 MB (estimativa, não medida). A, B e D baixam a carga inteira a
cada versão. Nesse tamanho isso não muda a escolha.

## 7. O que deu errado, por método

**Versão quebrada (S5):** nos quatro, a 0.3 não abre (`Syntax error @shell.qml`), e o `u2-ui-run` do
lab tenta de novo a cada segundo. O `yorha rollback` volta pra 0.2 em menos de 1,5 s.
- **D:** devolve também o estado (formato 2, a escolha do usuário de volta).
- **A, B e C:** a 0.2 fica lendo um estado no formato 3, que ela não entende: o papel de parede do
  monitor volta ao padrão. Pra recuperar, o usuário copia à mão o arquivo de `backups/`.

**Interrupção (S6):** em todos os cortes, ao religar, a UI abriu em menos de 90 s.
- **Download (a) e troca dos arquivos (b):** a máquina voltou na 0.1, e um `yorha update` terminou o
  serviço (2–4 s).
- **Migration (c):** a máquina voltou já na 0.2. A migration pendente rodou sozinha quando o
  `yorha-shell` abriu no login.

Detalhes por método:
- **A (b):** o corte no meio do `git checkout` deixou a árvore em parte 0.1, em parte 0.2, e a UI abriu
  mesmo assim. O update seguinte tratou os arquivos meio trocados como "edições do usuário": guardou em
  `backups/` e seguiu.
- **B e C (b):** o corte caiu no primeiro arquivo extraído pelo `pacman`, antes de qualquer coisa
  chegar ao disco, e não sobrou `db.lck`. Um corte mais tarde, numa transação maior, pode deixar a
  trava e arquivos pela metade. O wiki manda apagar `/var/lib/pacman/db.lck` e reinstalar (pesquisa,
  [Pacman](https://wiki.archlinux.org/title/Pacman)). Não foi medido aqui.
- **D (b):** a extração vai pra `versions/.0.2.part`; a versão em uso não foi tocada, e o update
  seguinte apagou a sobra.

**Sem rede (S7):**
- **A e D:** `curl … | bash` com o servidor fora mostra `curl: (52)` e sai com **0**. Nada é instalado,
  mas um roteiro que encadeie a instalação acha que deu certo.
- **C:** sai com o erro do `curl`.
- **B:** instala `base-devel` e `git` antes de falhar no `git clone`.
- **Update com o download cortado:** os quatro mantiveram a 0.1 no ar. B instalou antes a dependência
  nova (o `makepkg -s` resolve dependências antes de baixar a fonte).

**Carga adulterada (S8):**
- **S8a:** os quatro recusaram, cada um com sua mensagem:
  - **A:** `Cannot obtain needed blob … fetch failed`, mas o protótipo resume como "could not reach":
    a mensagem precisa melhorar;
  - **B:** `sha256sums … FAILED`;
  - **C:** `failed to retrieve some files`, porque o tamanho difere do banco;
  - **D:** `checksum mismatch`.
- **S8b** (o atacante refaz soma, receita, banco ou tag sem a chave do dono):
  - **A** recusa: `tag v0.2 is not signed by the YoRHa-OS key`;
  - **C** recusa: chave desconhecida. O `pacman` tenta importar a chave e falha; mesmo importada, ela
    não teria a assinatura local do usuário;
  - **D** recusa: `not signed by the YoRHa-OS key`;
  - **B instala a carga do atacante.**

**Arquivo gerenciado editado (S10):**
- **A:** guarda a edição em `backups/managed-<data>/` e avisa.
- **B e C:** sobrescrevem sem aviso; a edição só foi possível com `sudo`.
- **D:** não toca a versão editada; a edição fica em `versions/0.1` até ela ser descartada.
- Nos quatro, a UI 0.2 abriu.

**Comando nativo em B e C (S2n):** o `makepkg -si` ou `pacman -Syu`, sem o `yorha`, troca os arquivos
debaixo do Quickshell em execução.
- O Quickshell recarrega a 0.2 na hora, no mesmo processo, com o estado ainda no formato 1.
- A escolha do usuário some da tela até o próximo login, quando o `yorha-shell` roda a migration.
- **Vale pra qualquer método que troque arquivos no lugar:** em A acontece por um instante, entre o
  `checkout` e o reinício.

## 8. Entradas pra S3 (instalador)

- **Estrutura** (`PLAN.md` §5, ajustada ao método D):
  - `~/.local/share/yorha-os/versions/<v>/` (imutável, uma por versão; guarda 3);
  - `~/.local/share/yorha-os/current` → `versions/<v>` (link relativo, trocado com `ln -s` + `mv -T`);
  - `~/.local/share/yorha-os/trust/` (a chave pública, num `GNUPGHOME` próprio, nunca o `~/.gnupg`
    do usuário);
  - `~/.local/bin/{yorha,yorha-shell}` → `current/bin/…`;
  - `~/.local/state/yorha-os/` (estado, marcadores de migration, `backups/`).
  - O `~/.config/yorha-os/` é só do usuário (nenhuma execução o alterou).
- **Ponto de entrada:**
  - um `install.sh` público baixado e conferido **antes** de rodar: `bash <(curl -fsSL …)`, ou baixar
    e rodar, em vez de `curl … | bash`, que sai com 0 quando o download falha (S7a);
  - a chave pública e a impressão digital vão fixadas no script, então a confiança é no primeiro
    download (HTTPS do GitHub).
- **Release:** a tag `vX.Y` no git é a origem. O tarball da tag, o `.sha256` e o `.sig` vão pro GitHub
  Releases, e o arquivo `latest` vem do endereço `releases/latest` (6 passos no S12). Um `bin/` de
  release do dono pode reduzir isso a 1 comando.
- **Dependências:**
  - uma lista `packages` por versão (mais `packages-build` com o `qt6-shadertools`, pros `.qsb`);
  - instaladas com um único `sudo pacman -S --needed`, só se faltar alguma;
  - **cuidado com atualização parcial:** se o banco local estiver mais novo que o sistema, isso vira
    atualização parcial (R4, wiki [System maintenance](https://wiki.archlinux.org/title/System_maintenance)).
    A S3 precisa decidir entre `-Syu --needed` (como o Omarchy) e pedir ao usuário um `pacman -Syu`
    antes.
- **Shaders:** compilados no destino pelo `shell/shaders/build.sh` (`qsb` do `qt6-shadertools`).
  Funcionou nos quatro; o método C mostrou que os `.qsb` prontos também servem.
- **Instalação nova:** marca como feitas as migrations que já vêm na versão (como o Omarchy).
- **`~/.local/bin` no PATH:** o Arch não põe sozinho. Hoje o `yorha-shell` é chamado pelo caminho; a S3
  precisa resolver o PATH do usuário.

## 9. Entradas pra S4 (`yorha update` e migrations)

- **Passos do update** (o protótipo D, testado em S2, S6 e S8):
  1. lê `latest`;
  2. se for igual, roda as migrations pendentes e para;
  3. baixa tarball, `.sha256` e `.sig` pra `downloads/<v>`;
  4. confere sha256 e assinatura contra a chave fixada (recusa e apaga se falhar);
  5. desempacota em `versions/.<v>.part` e renomeia pra `versions/<v>`;
  6. instala as dependências que faltam;
  7. compila os shaders;
  8. copia o estado pra `backups/<versão-atual>/`;
  9. troca `current`;
  10. roda as migrations da versão nova;
  11. apaga versões além das 3 últimas e sobras `.part`;
  12. reinicia a UI.
- **Onde rodam as migrations:**
  - no `yorha update` e no começo de toda sessão (`yorha-shell`), por usuário;
  - a primeira que falhar para a fila (sem "pular e seguir"); a próxima tentativa recomeça dela;
  - toda migration é idempotente e copia o arquivo antes de escrever.
  - O S6c mostrou o valor disso: com o corte no meio da migration, o login seguinte terminou o serviço.
- **Volta:** `yorha rollback` troca `current` pra versão anterior e restaura `backups/<anterior>/`. O que
  o usuário mudou depois do update se perde na volta; isso precisa ser dito na mensagem.
- **Aviso:** `yorha update --check` lê `latest` (4 B, sem root). O indicador na barra pode rodar isso de
  hora em hora, como o Omarchy v3.
- **Nunca trocar arquivos debaixo da UI em execução** (S2n): com versões em pastas separadas isso não
  acontece; vale como regra pra qualquer parte da camada que fique fora de `versions/`.
- **Canais:** não medidos; com `latest` por canal (`latest-edge`), o desenho comporta.

## 10. Pesquisa (não medido)

Fontes conferidas ao vivo em 2026-10-27, no texto-fonte do wiki do Arch (`action=raw`; a página
renderizada bloqueia leitura automática).

| Afirmação | Fonte | Conferida |
|---|---|---|
| O AUR não aceita o que já está nos repositórios oficiais; "Will anyone else want to use this package?"; sufixos `-git` e `-bin`; `.SRCINFO` regenerado a cada mudança; `LICENSE` ou `REUSE.toml` no repositório do pacote | [AUR submission guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines) | ✅ |
| "AUR packages are user-produced content. These PKGBUILDs are completely unofficial and have not been thoroughly vetted. Any use of the provided files is at your own risk."; `base-devel` é pressuposto; revisar o PKGBUILD | [Arch User Repository](https://wiki.archlinux.org/title/Arch_User_Repository) | ✅ (a citação do research.md estava abreviada) |
| `pkgver()` de pacote `-git` com `git describe` ou `r<n>.<hash>` | a página do wiki agora redireciona pro [manual do desenvolvedor](https://gitlab.archlinux.org/archlinux/developer-manual) (`package-guidelines/vcs`) | ✅ (mudou de lugar) |
| `repo-add` monta o banco; `--sign` e `--verify` | [Pacman/Tips and tricks](https://wiki.archlinux.org/title/Pacman/Tips_and_tricks), [repo-add(8)](https://man.archlinux.org/man/repo-add.8) | ✅ |
| `pacman-key --recv-keys`, `--finger`, `--lsign-key` | [Pacman/Package signing](https://wiki.archlinux.org/title/Pacman/Package_signing) | ✅ |
| Atualização parcial não é suportada; `checkupdates` checa sem atualizar | [System maintenance](https://wiki.archlinux.org/title/System_maintenance) | ✅ |
| Mirror do Arch Linux Archive por data (`Server = …/repos/AAAA/MM/DD/$repo/os/$arch`) | [Arch Linux Archive](https://wiki.archlinux.org/title/Arch_Linux_Archive) | ✅ (usado no estudo) |
| `pacman` interrompido deixa `db.lck`; reparo de upgrade interrompido | [Pacman](https://wiki.archlinux.org/title/Pacman) | ✅ |
| `checkupdates` usa um banco à parte em `TMPDIR` | [checkupdates(8)](https://man.archlinux.org/man/checkupdates.8) | ✅; **medido:** ele precisa de `fakeroot` (só "opcional" no `pacman-contrib`): sem ele o aviso do C falhou na validação |
| Hooks do `pacman` (`alpm-hooks`) rodam na transação, e a página não diz com qual usuário | [alpm-hooks(5)](https://man.archlinux.org/man/alpm-hooks.5) | ✅ (o protótipo não usou hook) |
| Omarchy v3 (git) → v4 (pacotes, migrations avisadas no login); problemas do modelo git (#240, #1298, #12436, #7078) | research R1, R2 (GitHub do Omarchy) | não reconferido nesta fase |
| `/etc/xdg/quickshell/<nome>` como caminho de config de pacote | research R14 | **não verificado** |
| Um update do Qt invalida `.qsb` gerados antes? | research R7 | **não verificado** (o mirror fixo não muda o Qt); o `build.sh` recompila quando falta o `.qsb` |
| Snapshot do sistema (btrfs) restaura a raiz, não o `/home` | research R9 | pesquisa; a raiz do lab é btrfs (conferido), mas a camada escolhida mora no `/home`, então o snapshot não substitui o `yorha rollback` |

**B-ref** (o AUR de verdade, só leitura): ver §12.

**Camada pessoal (US5 #2):**
- **D** serve pro módulo pessoal com o mesmo código: tarballs assinados num lugar privado (repositório
  privado do GitHub com token, ou o próprio repositório privado). O custo é a autenticação no download.
- **A** serviria com um clone por SSH.
- **C** precisaria de um repositório pacman privado com autenticação.
- **B** não serve (o AUR é público).

**Niri (S5) e Omarchy (S7):**
- nenhum método depende do compositor; a carga fala com ele por um adaptador;
- pro pacote do Omarchy (S7), o precedente é o C (o Omarchy v4 é pacote). Um pacote que só instale o
  `install.sh` de D, ou empacote a versão, fica pra S7 decidir.

## 11. Riscos e ameaças à validade

**Riscos da escolha:**
- **O updater é nosso:** sem a maturidade do `pacman`. Ele precisa ser pequeno e testado no lab a
  cada mudança (os S5–S8 deste estudo viram o roteiro de regressão da S4).
- **A chave de assinatura:**
  - perder ou vazar a chave obriga a trocar a chave fixada no `install.sh` de todos;
  - a S6 precisa de um plano de rotação (por exemplo, a versão N traz a chave nova assinada pela velha).
- **Confiança no primeiro download:** o primeiro `install.sh` vem por HTTPS sem outra verificação
  (risco `curl | bash` do `PLAN.md`); mitiga com a impressão digital publicada no README.
- **Camada por usuário:** um segundo usuário precisa instalar a dele. Se a S3 quiser partes do sistema
  inteiro (greeter, `/etc`), elas vão por pacote ou `sudo`, fora de `versions/`.
- **Dependências de sistema:** continuam no `pacman`, com o risco de atualização parcial (§8).
- **A volta descarta o que o usuário mudou depois do update:** o estado volta ao de antes da migration.
- **Disco:** 3 versões × ~5 MB hoje; com a camada inteira, estimado em < 50 MB.

**Ameaças à validade:**
- **VM:** disco e rede virtuais. Os tempos comparam métodos entre si; não são promessa pro usuário.
- **Servidor local:** sem latência de internet. Os bytes valem; os tempos de download ficam otimistas.
  O cache do mirror estava quente em todas as execuções de tempo: a primeira validação de A levou
  14,8 s, contra 5,2 s de mediana.
- **AUR simulado:** sem API, sem helper e sem revisão humana da receita. O B-ref completa com o AUR real.
- **Corte de energia:** num ponto só por fase, e cedo no caso do `pacman` (§7). Cortes mais tardios
  numa transação grande não foram medidos.
- **Autor dos protótipos = autor da hipótese:**
  - os pesos e as âncoras foram fixados antes de medir (commit da 005 antes das execuções);
  - a conta com pesos iguais está ao lado;
  - as notas cuja âncora pedia interpretação têm a leitura registrada: K3, igual pros quatro; K6 de B,
    "terceiro a cada versão".
- **Refeitas por erro do protótipo ou do roteiro** (experimentos §6.7):
  - **protótipo:** rollback de B e C (pipeline com `set -e`); aviso de C sem `fakeroot`. As duas antes
    das execuções contadas, com a camada refeita;
  - **roteiro:**
    - o vigia do S6b olhava o `$HOME` do root, e não houve corte;
    - S6 de A morria antes de gravar (variáveis vazias);
    - a cadeia S8a → S7b → S8b de A deixava o S8b partir da 0.2;
    - o S8b de B herdou o tarball do S8a no cache do `makepkg`;
    - o S12 de C montava a árvore sem `bin/`.
  - Os registros substituídos ficaram guardados no lab.
- **Sessões descartadas:** 11 sessões `lab/perf` deste estudo terminaram como `fail`. Foram três do
  laço de tempo, que rodou no zsh sem separar a ordem em palavras; seis do S6 de A, antes das correções
  do roteiro; e duas de depuração da validação. Nenhum registro contado vem delas.

## 12. B-ref: o AUR de verdade

Feito numa `u2-base` nova (mirror fixo de 2026-10-26, AUR ao vivo, só leitura): `base-devel` + `git`,
`yay-bin` montado do AUR e `caelestia-shell` instalado pelo `yay`.

@@BREF@@
