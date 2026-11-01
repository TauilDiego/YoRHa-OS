# Sons da interface (spec 013)

Os sons do YoRHa-OS, todos nossos: gerados por receita em [`gen/synth.py`](gen/synth.py) (numpy e
`wave`, semente fixa por som). Nenhum arquivo, trecho ou amostra do jogo entra aqui. Os números das
receitas (brilho, duração, ordem de volume) descrevem só o caráter, medido no estudo de som da spec.
Ficam sob a licença do repositório.

- **Formato:** WAV PCM 16 bits, 48 kHz, mono; picos entre −16 e −8 dBFS.
- **Nomes:** um arquivo por evento (`specs/013-menus-do-jogo/data-model.md`). A pasta própria do
  usuário (`sound.folder`) usa os mesmos nomes.
- **`boot/`:** o som de início em volumes fixos (`boot-start-<nível>.wav`, ganho = nível²), pro
  serviço de boot tocar sem mexer no mixer.
- **Gerar de novo:** `lab/013/sounds-gen` (no lab privado, num container). `--check` confere se os
  arquivos daqui batem com a receita, e `--soft <pasta>` gera a variante com as frequências pela
  metade, pra ouvir.
