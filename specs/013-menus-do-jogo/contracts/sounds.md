# Contrato: sons

## Os nossos

- **Onde:** `system/sounds/<evento>.wav`, com os nomes da tabela de eventos (data-model.md).
- **Origem:** gerados por `lab/013/sounds-gen` (privado), num container, com as receitas da frente C.
  Versionados no repo público, com a licença do projeto.
- **Formato:** a definir na research S1/S2 (provável WAV PCM, 48 kHz, mono, picos em −1 dBFS, cada um
  com menos de 1,5 s).

## A pasta própria (`sound.folder`)

- Pra cada evento, o serviço procura `<pasta>/<evento>.wav` e depois `<pasta>/<evento>.ogg`. Achando,
  usa esse arquivo; senão, o nosso.
- Um arquivo que não abre (corrompido, formato errado) cai no nosso e gera uma linha de aviso no log,
  uma vez só.
- Trocar a pasta vale na hora. Os arquivos são lidos de novo.
- O `docs/sons-do-jogo.md` explica, com links pras ferramentas e guias da comunidade, como extrair os
  sons de menu da própria cópia de PC do jogo e dar os nomes dos eventos. Nunca linka arquivos
  prontos.

## Regras

- **Volume e mudo:** o volume de interface (`sound.volume`) multiplica o do sistema; o mudo do
  sistema cala tudo.
- **Notificações:** `notify` e `notifyCritical` respeitam o "não perturbe" e a tela cheia segurada da
  008.
- **Repetições:**
  - `move`, `change` e `typing` não se acumulam: um novo corta o anterior do mesmo evento;
  - `typing` toca no máximo um a cada 45 ms.
- **Tempo:** o som começa em até 50 ms depois da ação (SC-008).
- **Reduce motion** não muda os sons.
