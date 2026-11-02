# Research: Primeira release pública

As decisões técnicas da 015, uma por seção, cada uma com o que foi escolhido, por quê e o que ficou de
fora. O ponto de partida é o código da 014 na `main` (070ea6c): `install.sh`, `bin/yorha`,
`lib/yorha/*.sh`, `shell/services/Updater.qml` e o `lab/014/canal`.

## R1. O canal público: as releases do GitHub, sem a API

**Decision:** o produto lê as releases do GitHub pelos endereços comuns de `github.com`, nunca pela
API (`api.github.com`):

| O que | Endereço (`<origem>` = `https://github.com/TauilDiego/YoRHa-Shell`) |
|---|---|
| A versão estável mais nova | `<origem>/releases/latest/download/latest` (um arquivo de texto com o número, que vai em toda release) |
| A versão mais nova do canal de teste | o maior `v<versão>` de `<origem>/releases.atom` (o feed lista as pré-releases também) |
| Os arquivos de uma versão | `<origem>/releases/download/v<versão>/<arquivo>` |
| O instalador da estável | `<origem>/releases/latest/download/install.sh` (o comando do README) |

- O `/releases/latest` do GitHub já ignora pré-releases (FR-008): o canal estável não precisa filtrar
  nada.
- Conferido em 02.11 num repositório com pré-releases: o `releases.atom` traz as tags `nightly` e
  `stable` junto das normais, e o `/releases/latest/download/<arquivo>` responde 302 pra release
  marcada como mais nova.
- O GitHub responde com redirecionamento: todo `curl` do produto passa a usar `-L` (o da 014 não
  usava, porque o canal do lab não redireciona).

**Rationale:**
- A API anônima tem limite de 60 pedidos por hora por IP e responde JSON. Ler JSON em bash sem o `jq`
  é frágil, e o `jq` não pode ser pré-requisito do `install.sh`. Os endereços de `github.com` não
  entram nesse limite, e uma conferência por hora por máquina fica muito longe de qualquer limite
  (FR-012).
- O mesmo formato de endereços serve pro canal do lab e, na 016, pro espelho na VPS: o código do
  produto é um só pras três origens (R3).

**Alternatives considered:**
- **A API do GitHub:** limite de acessos e JSON, como acima.
- **Um `version.txt` na branch principal, como o Serpantinum:** amarra a versão a uma branch, não a um
  pacote testado, e não tem canal de teste.
- **Uma release fixa "canal" com os ponteiros:** aparece na lista de releases do repositório e
  precisa ser reescrita a cada publicação.

## R2. A numeração: MAJOR.MINOR.PATCH, sem sufixo

**Decision:**
- Toda versão é `MAJOR.MINOR.PATCH` só com números (`0.1.0`, `0.1.1`), e a tag é `v<versão>`
  (FR-003).
- Ser de teste é uma marca da release (a pré-release do GitHub), não um sufixo no número. Uma versão
  de teste aprovada vira estável trocando a marca (`promote`): o pacote é o mesmo, com o mesmo
  checksum.
- As comparações continuam pelo `sort -V`, que acerta com números puros. O `is_newer` da 014 fica, e
  a regex passa a ser `^[0-9]+\.[0-9]+\.[0-9]+$`.
- As versões que só existem no lab são `0.0.N`, menores que qualquer versão publicável. Uma VM com
  uma versão do lab recebe a 0.1.0 como update.

**Rationale:**
- O `sort -V` põe `0.2.0-rc.1` depois de `0.2.0`, ao contrário do semver: um sufixo pediria um
  comparador próprio.
- Promover sem remontar é o que garante que o pacote testado é o publicado (SC-003).

**Alternatives considered:**
- **Sufixos do semver (`-rc.1`):** pedem um comparador próprio.
- **Manter o `0.<commits>` da 014:** depende da branch (a `main` deu 0.73 e a branch da 014 deu 0.98)
  e não diz nada a quem instala.

## R3. As origens e o espelho

**Decision:**
- A máquina guarda as origens em `$YORHA_HOME/origins`, uma por linha, a principal primeiro (FR-018).
  O instalador escreve o arquivo a partir de `YORHA_ORIGIN`, quando a variável existe, ou das origens
  padrão do `name.sh` daquela versão.
- Cada pedido tenta as origens em ordem e usa a primeira que responde. Os arquivos de uma versão (o
  pacote, o checksum e o `latest`) vêm todos da mesma origem, e uma origem que falha no meio é
  trocada pela próxima desde o começo da versão.
- Na 0.1.0, as origens padrão são só o GitHub. O espelho da VPS e a conferência cruzada do checksum
  entram na 016, só acrescentando uma linha no `name.sh`.
- O canal (`stable` ou `testing`) fica em `$YORHA_HOME/channel`. O instalador lê `YORHA_CHANNEL`, e o
  `yorha channel <stable|testing>` troca depois.

**Rationale:** as duas variáveis cobrem o FR-002. `YORHA_ORIGIN` aponta o lab ou um espelho, e
`YORHA_CHANNEL` escolhe o canal de teste. Elas trocam o `YORHA_OS_CHANNEL` da 014, que juntava as duas
coisas e tinha o nome provisório.

**Alternatives considered:** misturar arquivos de origens diferentes numa mesma versão. Foi
descartado porque um checksum vindo de outra origem é justamente a proteção da 016, e lá ela entra
de propósito, com regra própria.

## R4. Montar e publicar: uma ferramenta do lab

**Decision:** `lab/015/release`, um script python3 do lab, só com a biblioteca padrão, que roda no
host (contracts/release.md):
- **`build <versão> [--pre] [--ref <ref>] [--lab-only]`** monta a release numa pasta do lab:
  - o pacote vem do `git archive` da ref (a `main`, por padrão), com o `VERSION` virtual, como no
    canal da 014;
  - o `.gitattributes` passa a marcar `specs/`, `.specify/`, `.claude/` e `.github/` como
    `export-ignore`, e o pacote cai de 12 MB pra uns 10 MB;
  - junto saem o `.sha256`, o `latest`, as notas (`NOTES.md`) e o `install.sh` daquela ref, com a
    origem padrão gravada a partir do `name.sh` da mesma ref.
- **As recusas de `build`** (FR-005):
  - mudança não commitada no checkout de origem;
  - número fora do formato;
  - número já usado, ou menor ou igual ao último: confere o índice local e as tags do GitHub (`git
    ls-remote --tags`);
  - arquivo proibido ou o nome provisório no pacote (contracts/nome.md).
- **`--lab-only`** exige um número `0.0.N` e marca a release como impublicável. É o que os testes usam
  antes da `main` existir, e é o que permite montar a versão com o nome de mentira (R6).
- **`publish <versão>`** cria a release no GitHub:
  - roda `gh release create v<versão> --target <commit>`, com as notas, a marca de pré-release, se
    houver, e os arquivos montados;
  - depois baixa de novo cada arquivo do GitHub e compara os checksums (SC-003);
  - recusa uma release `--lab-only`, e recusa se o commit ainda não estiver no GitHub.
- **`promote <versão>`** tira a marca de pré-release e marca a versão como a mais nova
  (`gh release edit`).
- **`publish` e `promote` pedem confirmação no terminal** e só rodam depois do OK do dono no chat
  (FR-007).
- **As notas da 0.1.0** são escritas à mão, porque são 97 commits. Das próximas versões em diante, o
  `build` faz um rascunho com os assuntos dos commits desde a última tag, e o dono revê na página da
  release (SC-008).

**Rationale (princípio I):**
- Montar a release é o que o canal da 014 já fazia no host: `git archive`, `sha256sum` e copiar
  texto. Nada do projeto é executado.
- Os shaders compilam na máquina de destino (`yorha_prepare`), e a fonte do boot é regerada na VM
  (R5).
- Publicar usa o `gh`, que já está instalado e autenticado, com o OK do dono a cada vez.

**Alternatives considered:**
- **Montar no GitHub Actions:** aí o lab não testaria o mesmo arquivo que vai ser publicado.
- **Pôr o script no repositório público:** só o dono publica, e o fluxo depende do lab, que é
  privado.

## R5. A troca do nome

**Decision:** uma tabela de troca aplicada de uma vez (contracts/nome.md):
- `yorha-os` vira `yorha-shell` (pastas, arquivos e pacotes);
- `YoRHa-OS` vira `YoRHa-Shell` (textos);
- `YORHA_OS_*` vira `YORHA_*`: sai o `_OS`, e o prefixo, que é o do comando, fica. Assim
  `YORHA_OS_ROOT` vira `YORHA_ROOT`, que no supervisor e no `bin/yorha` já quer dizer "a pasta da
  versão";
- o comando `yorha` fica.

O que entra na troca:
- **Arquivos e pastas renomeados com `git mv`:**
  - `system/hypr/yorha-shell.lua`;
  - os temas `system/boot/plymouth/yorha-shell/` e `system/login/sddm/yorha-shell/`;
  - o módulo `system/boot-login/yorha-shell-boot-login` e os serviços `yorha-shell-boot-*`;
  - o tema do cursor, "YoRHa-Shell Cursors".
- **A fonte do boot:** "YoRHa-OS Boot" vira "YoRHa-Shell Boot" e é regerada pelo `gen/assets.py`
  dentro da VM, porque é código do projeto.
- **O QML** ganha um singleton `services/Product.qml`:
  - o nome e as pastas do produto saem dele, e não de strings soltas;
  - hoje há `yorha-os` escrito à mão em `Updater.qml`, `Sounds.qml` e em outros serviços;
  - ele lê `YORHA_NAME`, que o supervisor exporta a partir do `name.sh`, e cai em `yorha-shell` no
    lab, onde o shell roda direto do repositório.
- **O lab** acompanha na `lab-015`: os roteiros ativos (`check-003` a `check-014`, `guest/`, `011/`,
  `014/` e `lib.sh`). Os estudos antigos (`u2/`, `009/` e `mockups/`) ficam como estão, porque são
  histórico.
- **Fica com o nome antigo:** as specs, o histórico do git, os créditos e os trechos de histórico
  listados no contrato.

**Rationale:**
- Trocar agora custa só editar arquivos: as instalações existem só nas VMs, que são refeitas.
- O singleton tira de vez o nome do código QML, que é a outra metade do FR-017.

**Alternatives considered:**
- **Deixar as variáveis `YORHA_OS_*`:** mantém o nome provisório no ambiente de quem instala.
- **Renomear as pastas locais do projeto** (`YoRHa-OS/`, `-private`, `-wt`, `-relatorios`):
  - mexe nos caminhos do lab, no CLAUDE.md e na memória sem mudar nada pra quem instala;
  - fica pra quando o dono pedir.

## R6. O update que sabe trocar o nome (FR-017)

**Decision:** a 0.1.0 já sai com as duas peças que a versão antiga precisa ter. O resto mora na versão
nova, que é quem conhece os dois nomes.

1. **O update entrega o fim pra versão nova.** Depois de baixar e conferir, o `yorha update` da
   versão em uso chama `<nova>/bin/<cmd> _finish-update --from <versão> --from-home <pasta>`. A versão
   nova faz o resto: a troca, as migrations e o reinício do shell. Na 014, a versão antiga trocava e a
   nova só migrava.
2. **O supervisor segue a mudança.** Quando o `current` some da pasta dele e aparece
   `<pasta>/renamed-to`, ele roda o `shell start --relaunch` do comando novo, em vez de parar, e o
   shell não cai.

Quando os nomes diferem, a versão nova:
- **Move as pastas:** `share`, `state` e `config` vão pro nome novo. No `state` e no `config`, o
  caminho antigo vira um link pro novo, então o conteúdo da pessoa não muda e os dois caminhos
  continuam valendo (princípio III).
- **Deixa a pasta antiga funcionando:** `~/.local/share/<antigo>` vira uma pasta com:
  - `current/system/hypr/<antigo>.lua`, um arquivo de uma linha que carrega o novo;
  - o `renamed-to`.

  A linha que a pessoa pôs no `hyprland.lua` continua funcionando, e o arquivo dela nunca é editado
  (princípios II e III).
- **Mantém o comando antigo:** ele vira um atalho pro novo. Os atalhos de teclado que o Hyprland já
  carregou continuam funcionando até o próximo login.
- **Avisa a pessoa:** uma transmissão diz a linha nova pro `hyprland.lua`, e o `status` mostra o
  mesmo até ela trocar.
- **O rollback desfaz:** a versão em uso lê o `name.sh` da anterior, e se os nomes forem diferentes,
  faz o caminho de volta antes de trocar.

**Fora:** com o boot e o login instalados, a troca avisa pra reinstalar o módulo pelo comando novo.
Os temas antigos continuam funcionando até lá.

**O teste:** uma versão `--lab-only` montada de uma branch de teste, com `name.sh` dizendo
`fake-shell` e `fakecmd`. A VM vai da `yorha-shell` pra `fake-shell` pelo update e volta pelo
rollback. Nas duas pontas confere-se:
- as pastas e os links;
- o atalho do comando;
- a linha antiga carregando o shell;
- o shell no ar e o log sem erro de QML.

**Rationale:** a versão antiga nunca sabe o nome da próxima. Por isso a 0.1.0 só precisa entregar o
fim do update pra nova e seguir o `renamed-to`. Todo o resto pode ser escrito, e corrigido, na versão
que fizer a troca.

**Alternatives considered:**
- **Editar o `hyprland.lua` da pessoa:** viola os princípios II e III.
- **Uma migration comum:** as migrations rodam depois da troca, com as pastas do nome novo, que ainda
  não existem.
- **Deixar a troca de nome sem teste:** a proteção só vale se funcionar no dia em que for preciso.

## R7. O sinal de versão nova (FR-011)

**Decision:** duas opções novas em SYSTEM › Updates (contracts/sinal.md):
- **`sign`** (choice), com cinco valores: `bar`, `menu`, `both` (o padrão), `login` e `off`;
- **`auto-check`** (toggle, ligado): R8.

O que cada forma usa:
- **Barra:** um `hud/UpdateTag.qml` no molde do `LogCounter`. É um quadrado com `UPDATE <versão>`,
  antes do LOG, e segue o tom e a placa da barra. O clique emite o `Updater.showUpdates`, que o
  `shell.qml` já liga em SYSTEM › Updates.
- **Menu:** a `Tag` "NEW" que o LOG já usa, na linha da categoria Updates. O `TabBar` ganha uma
  `tag` por aba, pra marcar SYSTEM.
- **Login:** a transmissão volta uma vez por login. O teste de "uma vez por login" é a trava por
  `mkdir` em `$XDG_RUNTIME_DIR`, a mesma do som de entrada (spec 013, research S5).
- **Some:** o sinal depende de `Updater.available`. Depois do update, o shell sobe na versão nova, o
  `available` fica falso e o sinal some em qualquer forma.
- **A troca vale na hora,** por binding, sem reiniciar o shell.

**Rationale:** reaproveita peças que já existem (o contador do LOG, a `Tag` e a trava do login) e
segue a regra de pôr as alternativas de design como opções.

## R8. A conferência automática desligável (FR-019)

**Decision:** os dois `Timer` do `Updater` (30 s e 1 h) passam a rodar só com
`installed && autoCheck`. Desligada, o `check()` só roda quando a pessoa entra em SYSTEM › Updates ou
pelo IPC. O `yorha update` no terminal continua conferindo sempre.

**O teste (ajuste no SC-010):** em vez de esperar uma hora, o teste:
- desliga a opção;
- reinicia o shell;
- confere no log do canal que nenhum pedido saiu em 3 minutos (o primeiro sairia aos 30 s);
- confere no `updates dump` que os dois timers estão parados.

## R9. O repositório público em ordem (US6)

**Decision**, nesta ordem, e cada passo com o OK do dono:
1. **Uma auditoria antes do push**, sobre o histórico que vai subir:
   - caminhos do repositório privado;
   - padrões de token e chave;
   - arquivos binários grandes;
   - arquivos do jogo.
2. **O push da `main`**, que tem 97 commits ou mais à frente.
3. **Renomear o repositório:** `gh repo rename YoRHa-Shell`. O GitHub redireciona o endereço antigo.
4. **Apagar as branches velhas:** há 13 hoje, todas mescladas.
5. **A verificação automática verde:**
   - o `lint.yml` está ativo, mas tem zero execuções desde 27.10, apesar dos pushes;
   - ganha um `workflow_dispatch`, pra poder rodar à mão;
   - o motivo das zero execuções é investigado depois do push;
   - antes do push, o mesmo lint (`shellcheck` e `qmllint`) roda numa VM do lab, nunca no host.

## R10. O lab da 015

**Decision**, na branch `lab-015` do repositório privado:
- **`lab/015/canal`** substitui o `lab/014/canal`:
  - serve as releases montadas, no formato de endereços do GitHub (R1), incluindo o
    `releases.atom` gerado;
  - pode subir em mais de uma porta (8714 e 8715), pra simular a origem principal e o espelho;
  - o `stop --port` derruba uma delas;
  - o log fica em JSON, uma linha por pedido, como na 014.
- **A camada `t015`:** sai da `hypr-iso`, como a `t014`, com o `hyprland.lua` de uma pessoa comum.
- **`check-015` em blocos**, um arquivo por frente em `lab/015/check.d/`, pra que as frentes
  paralelas não editem o mesmo arquivo.
- **A regressão:** `check-003`, `004`, `007`, `008` e `013`, mais o `check-014` adaptado ao canal novo.
- **Toda sessão** é aberta com `lab/perf begin` e fechada com `lab/perf end`.

## R11. Quem executa: os agentes, o modelo e o esforço

**Decision** (regras do dono de 02.11: a sessão principal só planeja e confere; código com o Opus 5.5
em esforço médio): cada frente vai pra um agente com worktree, branch e VM próprios, no máximo 4 VMs
ao mesmo tempo, com `NIER_LAB_CPUS=4 NIER_LAB_MEM=4G`. A sessão principal escreve os briefings,
confere a evidência de cada entrega e conversa com o dono.

| Frente | Modelo · esforço | O trabalho |
|---|---|---|
| Setup do lab (canal, `release build`, `t015`) | Opus 5.5 · médio | Código novo, pequeno |
| Troca do nome (a tabela) | Haiku · baixo | Mecânico, com a tabela e a busca de conferência prontas |
| Fonte do boot e regressão depois da troca | Opus 5.5 · médio | Roda na VM e lê os resultados |
| Núcleo do canal (`lib/yorha/channel.sh`) | Opus 5.5 · médio | O contrato que as frentes usam |
| A: instalar e atualizar pelo canal público | Opus 5.5 · médio | Código e testes no lab |
| B: o sinal e a conferência desligável | Opus 5.5 · médio | QML com screenshots |
| C: o update que troca o nome | Opus 5.5 · médio | Código com testes de ida e volta |
| D: README, constituição, PLAN, lint e auditoria | Opus 5.5 · médio | Texto no estilo do projeto e conferências |
| Junção (check-015 inteiro, regressão) | Opus 5.5 · médio | Roda e lê |

Os passos que vão pra fora (push, renomear, apagar branches, publicar e promover) são poucos
comandos, e a sessão principal roda cada um depois do OK do dono.
