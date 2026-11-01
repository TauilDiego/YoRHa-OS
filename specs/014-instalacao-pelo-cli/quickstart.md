# Quickstart: como validar a 014 no lab

Tudo no lab privado, medido com o `lab/perf`. Nada roda na máquina do dono.

1. **O canal:**
   - `lab/014/canal follow ../YoRHa-OS-wt/t014-canal t014-canal`;
   - `lab/014/canal start`;
   - `curl -s 127.0.0.1:8714/latest` responde `0.N`.
2. **A VM limpa:**
   - `lab/new t014 --from hypr-iso`;
   - `lab/014/prep t014`, que põe o `hyprland.lua` comum (sem o shell do lab).
3. **Instalar (US1):**
   - na VM, `YORHA_OS_CHANNEL=http://10.0.2.2:8714 bash <(curl -fsSL http://10.0.2.2:8714/install.sh)`;
   - aceitar as dependências;
   - incluir a linha mostrada;
   - relogar: a barra aparece, e `yorha ipc pause dump` responde.
4. **A correção chega (US2):**
   - commitar no `t014-canal` uma mudança visível (por exemplo, um texto do HUD) e uma migration de
     teste;
   - `yorha update --check` → `available`;
   - `yorha update`: o shell volta com a mudança, e a marca da migration existe uma vez só.
5. **Rollback:** `yorha rollback`. A versão anterior volta, e o estado é igual byte a byte ao de antes.
6. **Interrupção:** `lab/check-014 --only interrupt` derruba o update em 3 pontos. A versão em uso sobe
   em todos.
7. **O aviso (US3):**
   - commitar outra mudança;
   - `yorha ipc updates check` → chega a transmissão;
   - clicar → SYSTEM › Updates → "Update now": o `kitty` roda o `yorha update`, e o shell volta na
     versão nova.
8. **Boot e login (US5):** na `teste-011`, `yorha boot-login install`, reboot, `uninstall`, reboot.
   Os hashes ficam como antes.
9. **Desinstalar (US6):** `yorha uninstall`. Nada do produto sobra fora da config e do estado.
10. **Regressão:** `check-003`, `004`, `007`, `008` e `013` como sempre, e o `check-014` completo.
