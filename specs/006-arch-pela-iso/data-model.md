# Modelo de dados (Fase 1): Arch completo na VM

Tudo fica em `$LAB_HOME` (`~/.local/share/nier-lab/`) ou no repositório privado do laboratório. Nada
disso entra no repositório público.

## ISO fixada

| Campo | Exemplo | Regra |
|---|---|---|
| `file` | `archlinux-2026.10.01-x86_64.iso` | Nome oficial, sem mudança |
| `version` | `2026.10.01` | Tirada do nome |
| `sha256` | 64 hex | Igual no `images.lock` e no `sha256sums.txt` |
| `signer` | `3E80CA1A8B89F69CBA57D98A76A5EF9054449A5C` | Igual à impressão digital fixada |
| `source` | `mirror` / `archive` | De onde veio |

Estados: `ausente` → `baixada` → `verificada` (somente leitura) ou `recusada` (`*.rejected`).

## Configuração de instalação

O JSON do archinstall ([contracts/archinstall-config.md](contracts/archinstall-config.md)). Origem:
`lab/iso/archinstall.json` ou `--config`. O `disk_config` é gerado (a não ser que venha no arquivo).
A versão efetiva é o `user_configuration.json` que o archinstall salva na ISO, copiado pra pasta de
saída.

## Credenciais

`$LAB_HOME/vms/<nome>.creds` (modo 600): `user=arch` e `password=<gerada>`. Viram o
`user_credentials.json` só dentro da ISO, com o hash. Vida: a da camada.

## Camada `arch-iso`

| Arquivo | Conteúdo |
|---|---|
| `vms/<nome>.qcow2` | Disco raiz (sem camada de baixo), somente leitura depois de congelado |
| `vms/<nome>.vars.fd` | NVRAM do UEFI, com a entrada do systemd-boot gravada na instalação |
| `vms/<nome>.base` | `iso:<versão>`; `incompleta:<passo>` só com `--keep-on-fail` |
| `vms/<nome>.manifest.json` | Manifesto (abaixo) |
| `vms/<nome>.creds` | Credenciais |

Estados: `instalando` (disco gravável, sem `.base`) → `pronta` (`.base` = `iso:…`, congelada) ou
`incompleta` (`.base` = `incompleta:…`, gravável, nunca usada como base: o `lab/new --from` recusa).

## Manifesto (`manifest.json`)

```json
{
  "schema": 1,
  "layer": "arch-iso",
  "created": "2026-10-27T20:15:00-03:00",
  "iso": { "file": "archlinux-2026.10.01-x86_64.iso", "sha256": "…", "signer": "3E80…9A5C" },
  "archinstall": "4.5",
  "config": { "source": "lab/iso/archinstall.json", "sha256": "…" },
  "packages_from": "mirror:geo.mirror.pkgbuild.com",
  "lab_adaptations": ["openssh+sshd", "authorized_keys(arch)", "sudoers.d/90-nier-lab", "hostname=nier-lab"],
  "disk": { "virtual_gib": 40, "used_mb": 2400 },
  "checks": { "passed": 16, "failed": 0 },
  "packages": ["base 3-2", "linux 7.2.7.arch1-1", "…"],
  "run": "out/install-iso-20261027-201500",
  "perf_run": "<id da sessão do lab/perf, se houver>"
}
```

## Execução

A pasta `out/install-iso-<AAAAMMDD-HHMMSS>/` ([contracts/lab-install-iso.md](contracts/lab-install-iso.md),
"Arquivos"). O `steps.tsv` tem uma linha por passo: `passo`, `início`, `fim`, `resultado`
(`ok`/`falha`/`pulado`), `nota`.
