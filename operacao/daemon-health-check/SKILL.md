---
name: daemon-health-check
description: Health check de um daemon local — endpoint /health do serviço, dependências externas (ex.: um servidor Ollama local) e status da unit systemd. Use quando o usuário pedir "health check", "o serviço está de pé?", "checa o daemon" ou ao diagnosticar por que o serviço não responde.
---

# daemon-health-check — checagem de daemon + dependências + systemd (TOOL · v1.0.0 · Alex Jesus)

Rodar um health check do daemon/serviço do projeto:

1. Verificar se o daemon está respondendo:
   ```
   curl -sf http://127.0.0.1:<porta>/health
   ```

2. Verificar se as dependências externas estão disponíveis (ex.: um servidor
   Ollama local):
   ```
   curl -sf http://127.0.0.1:11434/api/tags
   ```

3. Verificar o status do serviço no systemd:
   ```
   systemctl status <nome-do-servico>.service --no-pager
   ```

4. Reportar ao usuário um resultado consolidado com o status de cada componente.
   Se algum componente estiver fora do ar, sugerir a ação corretiva.

## Quando NÃO usar

- Serviços que não expõem endpoint HTTP de health nem rodam sob systemd — adapte
  os passos antes (ver "Adaptação") em vez de reportar falso negativo.
- Diagnóstico profundo de falha (logs, tracing) — esta skill é a triagem rápida
  de "está de pé?"; depois dela, siga para os logs (`journalctl -u
  <nome-do-servico>.service`).

## Adaptação

- **Renomeada do nome genérico original ao ser publicada.**
- **`<porta>`** — a porta HTTP do daemon do seu projeto e o caminho do endpoint
  de health (`/health` é o convencional).
- **Passo 2** — liste as dependências externas reais do seu serviço, uma checagem
  por dependência (o exemplo usa a API de um servidor Ollama local em
  `127.0.0.1:11434`; troque/acrescente banco, fila, APIs etc.).
- **`<nome-do-servico>.service`** — o nome da unit systemd do seu daemon; se o
  serviço rodar como user unit, use `systemctl --user`.
