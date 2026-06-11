---
name: pytest-async-testing
description: Receitas e armadilhas para escrever testes pytest-asyncio em serviços Python assíncronos (FastAPI + httpx + subprocess) — mocking assíncrono, patch de singletons module-level, exercício real de timeouts e sincronização determinística entre tasks. Carregue antes de escrever testes, especialmente em dúvida sobre AsyncMock, onde aplicar patch, como resetar singletons ou como testar um timeout de verdade.
---

# pytest-async-testing — receitas pytest-asyncio para serviços assíncronos (TOOL · v1.0.0 · Alex Jesus)

Receitas concretas para escrever testes no estilo de um serviço Python assíncrono
(daemon FastAPI com clientes httpx e chamadas de subprocess). Esta skill complementa
o documento de convenções de teste do repositório (se houver — ex.:
`.claude/rules/tests.md`) com templates funcionais para adaptar. Nos exemplos,
`app` é o pacote raiz do projeto (ver "Adaptação").

## Receita 1 — Testar um endpoint FastAPI novo

**Quando usar:** você adicionou um router em `app/api/<name>.py` e precisa de cobertura.

**Template:**

```python
"""Testes para o endpoint POST /api/v1/<name> (app/api/<name>.py)."""
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.<name> import router


@pytest.fixture
def client_and_mocks():
    app_test = FastAPI()
    app_test.include_router(router, prefix="/api/v1")

    # Mock TODOS os singletons que o endpoint importa dinamicamente
    # de app.main. Para endpoints que recebem project, sempre 3 mocks:
    # o singleton principal do domínio do endpoint, rate_limiter e registry.
    main_mock = MagicMock()
    main_mock.send_message = AsyncMock(return_value={"message_id": 42})

    rate_limiter_mock = MagicMock()
    rate_limiter_mock.allow = MagicMock(return_value=True)

    registry_mock = MagicMock()
    registry_mock.heartbeat = MagicMock()

    with patch("app.main.<singleton>", main_mock), \
         patch("app.main.rate_limiter", rate_limiter_mock), \
         patch("app.main.registry", registry_mock):
        with TestClient(app_test) as client:
            yield client, main_mock, rate_limiter_mock, registry_mock
```

**Armadilhas:**

- **Não use `TestClient(app.main.app)`** — dispara o lifespan real, que inicia o
  loop de polling do daemon. Sempre monte um `FastAPI()` novo só com o router em teste.
- **Aplique o patch em `app.main.<name>`**, não no módulo do endpoint. O endpoint
  faz `from app.main import X` dinamicamente a cada chamada — o alvo do patch é
  onde o atributo vive, não onde ele é lido.
- **Ordem dos testes para a checagem tripla** (rate limit → heartbeat → corpo):
  sempre `rate_limiter.allow` PRIMEIRO, depois `heartbeat`, depois a lógica de
  negócio. No projeto-origem essa ordem era fixada por ADR — confira a convenção
  do seu repo (ver "Adaptação").

## Receita 2 — Testar um cliente httpx assíncrono

**Quando usar:** você adicionou/alterou código que usa `httpx.AsyncClient`
(ex.: o cliente de uma dependência externa, como um servidor Ollama local).

**Template:**

```python
def _make_response(json_data=None, status_code=200, raise_exc=None):
    resp = MagicMock()
    resp.status_code = status_code
    resp.json = MagicMock(return_value=json_data or {})
    if raise_exc:
        resp.raise_for_status = MagicMock(side_effect=raise_exc)
    else:
        resp.raise_for_status = MagicMock()
    return resp


def _make_client(response=None, side_effect=None):
    client = MagicMock()
    if side_effect:
        client.post = AsyncMock(side_effect=side_effect)
    else:
        client.post = AsyncMock(return_value=response)
    client.__aenter__ = AsyncMock(return_value=client)
    client.__aexit__ = AsyncMock(return_value=None)
    return client


@pytest.mark.asyncio
async def test_xxx():
    client = _make_client(response=_make_response({"ok": True}))
    with patch("app.llm_client.httpx.AsyncClient", return_value=client):
        result = await chat("msg")
    assert result == ...
```

**Armadilhas:**

- **`__aenter__` e `__aexit__` precisam ser `AsyncMock`**, não `MagicMock` comum.
  Sem eles, o `async with` falha silenciosamente ou levanta `AttributeError`.
- **Prefira subclasses concretas do httpx** no `side_effect` (`httpx.ReadTimeout`,
  `httpx.ConnectError`) à abstrata `httpx.TimeoutException` — a abstrata levanta
  `TypeError` em alguns contextos.
- **Aplique o patch no ponto de uso do módulo** (`app.<modulo>.httpx.AsyncClient`),
  não em `httpx.AsyncClient` globalmente.

## Receita 3 — Testar uma chamada de subprocess

**Quando usar:** o código usa `asyncio.create_subprocess_exec` (ex.: módulos que
envolvem uma CLI externa ou coletam contexto via subprocess).

**Template:**

```python
def _make_proc_mock(returncode=0, stdout=b"", stderr=b""):
    proc = MagicMock()
    proc.returncode = returncode
    proc.communicate = AsyncMock(return_value=(stdout, stderr))
    proc.kill = MagicMock()
    return proc


@pytest.mark.asyncio
async def test_success():
    proc = _make_proc_mock(stdout=b"resposta")
    with patch(
        "app.cli_client.asyncio.create_subprocess_exec",
        new=AsyncMock(return_value=proc),
    ):
        result = await query_project("q", "/tmp")
    assert result == "resposta"
```

**Armadilhas:**

- **`proc.communicate` precisa ser `AsyncMock`**, retornando a tupla. Se faltar,
  o await silencioso devolve um `MagicMock`.
- **`proc.kill` como `MagicMock`** (síncrono). Asserte com `.assert_called_once()`.
- **Patch em `app.<modulo>.asyncio.create_subprocess_exec`** — o namespace do
  módulo, não o módulo global `asyncio`.

## Receita 4 — Testar um timeout real (não o handler)

**Quando usar:** você quer verificar que o `asyncio.wait_for(..., timeout=X)`
realmente dispara.

```python
@pytest.mark.asyncio
async def test_timeout_real():
    async def slow_communicate():
        await asyncio.sleep(10)           # bem mais longo que o timeout
        return (b"", b"")

    proc = MagicMock()
    proc.returncode = 0
    proc.communicate = slow_communicate   # NÃO AsyncMock side_effect=TimeoutError!
    proc.kill = MagicMock()

    with patch(
        "app.cli_client.asyncio.create_subprocess_exec",
        new=AsyncMock(return_value=proc),
    ):
        result = await query_project("q", "/tmp", timeout=0.1)

    assert "Timeout" in result
    proc.kill.assert_called_once()
```

**Armadilhas:**

- **NUNCA** use `side_effect=asyncio.TimeoutError()` no `communicate`. Isso
  curto-circuita o `asyncio.wait_for` — o teste passa mesmo que o módulo deixe de
  usar `wait_for` por completo. Um refactor que remova o timeout real passa
  despercebido.
- **Timeout float pequeno (0.1 ou menos)** para o teste terminar rápido e ainda
  assim exercitar o relógio de verdade.

## Receita 5 — Sincronizar tasks num teste de concorrência

**Quando usar:** você tem uma task que precisa atingir um estado específico antes
de o teste assertar.

```python
@pytest.mark.asyncio
async def test_concurrent_state():
    entered_second_iter = asyncio.Event()

    async def fake_get_updates(timeout=30):
        if not entered_second_iter.is_set():
            entered_second_iter.set()  # sinal: 1ª iteração concluída
            return []
        await asyncio.sleep(10)        # 2ª iteração estaciona aqui até ser cancelada

    task = asyncio.create_task(main._polling_loop())
    await entered_second_iter.wait()   # sincronização determinística
    task.cancel()
    with contextlib.suppress(asyncio.CancelledError):
        await task
```

**Armadilhas:**

- **NUNCA** use `await asyncio.sleep(0.05)` como primitiva de sincronização. É
  baseado em timing e flaqueia sob carga no CI.
- **`asyncio.Event`** é o idioma para "espere até X acontecer".

## Receita 6 — Patch de singletons module-level

**Quando usar:** o código de produção tem um objeto a nível de módulo (ex.:
`app.command_router.conversation`, `app.cli_client._semaphore`) e seu teste
precisa de isolamento.

```python
@pytest.fixture(autouse=True)
def reset_conversation():
    """Reseta o histórico de conversas antes de cada teste para isolamento."""
    original = command_router.conversation
    command_router.conversation = ConversationHistory()
    yield command_router.conversation
    command_router.conversation = original


@pytest.fixture(autouse=True)
def reset_semaphore():
    """Reseta o semáforo module-level entre testes."""
    cli_client._semaphore = asyncio.Semaphore(2)
    yield
    cli_client._semaphore = asyncio.Semaphore(2)
```

**Armadilhas:**

- **`autouse=True`** é obrigatório para isolamento. Sem ele, o estado vaza entre
  testes rodados no mesmo arquivo.
- **Reconstrua o objeto, não o mute.** `conversation._history.clear()` é frágil —
  reatribuir um `ConversationHistory()` novo é robusto.

## Receita 7 — Validação defensiva de payload

**Quando usar:** você está testando um handler que lê de um dict de schema aberto
(ex.: o campo `payload` de um request de notificação).

```python
@pytest.mark.parametrize(
    "weird_value",
    [
        {"nested": "dict"},      # dict onde se espera string
        42,                       # int onde se espera string
        None,                     # null
        ["a", "b"],              # list
    ],
)
def test_resilient_to_non_string(client_and_mocks, weird_value):
    client, main_mock, _, _ = client_and_mocks
    resp = client.post(
        "/api/v1/notify",
        json=_payload(payload={"summary": weird_value}),
    )
    assert resp.status_code == 200
    main_mock.send_message.assert_awaited_once()
```

**Armadilhas:**

- Uma função de escape de Markdown (ex.: `escape_md`) itera caracteres. Um dict
  itera chaves (saída embaralhada, sem crash). Um int levanta `TypeError`
  (capturado por `try/except` no endpoint). Os dois caminhos devem ser testados.
- **Use `parametrize`** em vez de múltiplos testes quando a única variável é a
  entrada.

## Checklist pré-commit

Antes de o agente de escrita de testes (ou você) commitar:

1. `make test` verde.
2. `make lint` limpo para o arquivo de teste novo.
3. `make lint-arch` mantido (você não introduziu import cross-layer) — se o repo
   tiver lint de arquitetura.
4. Cada teste tem docstring em pt-BR (ou no idioma convencionado pelo repo).
5. Cada asserção usa `call_args.kwargs["x"]` / `call_args.args[n]` — sem
   desempacotamento de tupla.
6. Sem imports de `pytest-mock`/`pytest-cov` se a política do repo for
   `unittest.mock` puro com superfície de dependências deliberada (era o caso do
   projeto-origem).

## Referência rápida: padrões a imitar

| O que você está testando | Onde está o padrão |
|---|---|
| Endpoint FastAPI novo | Receita 1 |
| Cliente httpx assíncrono | Receita 2 |
| Subprocess + timeout | Receitas 3 e 4 |
| Sincronização entre tasks concorrentes | Receita 5 |
| Reset de singleton module-level | Receita 6 |
| Validação defensiva de payload | Receita 7 |

O projeto-origem mantinha essa tabela apontando para arquivos de teste de
referência do próprio repo (incluindo padrões sem receita aqui: máquina de
estados com callback, integração assíncrona com o `main` e validator de campo
Pydantic). Reconstrua a tabela com os arquivos exemplares do seu repositório.

## Quando NÃO usar

- Código síncrono simples sem asyncio — `unittest.mock` básico resolve; estas
  receitas adicionam maquinário desnecessário.
- Projetos que não usam pytest/pytest-asyncio (outro framework de teste tem seus
  próprios idiomas de async).
- Para rodar a suíte e triar falhas — isso é a skill `pytest-run-triage`.
- Testes de integração contra serviços reais (sem mock) — as receitas aqui são de
  isolamento por mock.

## Adaptação

- **Renomeada do nome genérico original ao ser publicada.**
- **`app`** — placeholder do pacote raiz do projeto; substitua pelo nome real
  (ex.: `app.main`, `app.api.<name>`, `app.llm_client`, `app.cli_client`,
  `app.command_router` → os módulos equivalentes do seu código).
- **`app.main` como dono dos singletons** — o desenho do projeto-origem
  concentrava singletons (cliente principal, `rate_limiter`, `registry`) no
  módulo `main`, importados dinamicamente pelos endpoints; ajuste os alvos de
  patch ao desenho do seu projeto.
- **Ordem rate limit → heartbeat → corpo (Receita 1)** — convenção fixada por ADR
  no projeto-origem; mantenha apenas se o seu repo tiver checagem equivalente, na
  ordem que o seu ADR/convenção definir.
- **`make test` / `make lint` / `make lint-arch`** — substitua pelos comandos
  canônicos do seu repo (ex.: `uv run pytest`, `ruff check`, import-linter).
- **Documento de convenções** — o projeto-origem mantinha as convenções em
  `.claude/rules/tests.md`; aponte para o documento equivalente do seu repo.
- **Política de dependências de teste (item 6 do checklist)** — reflete a escolha
  do projeto-origem por `unittest.mock` puro; adapte à política do seu repo.
- **`ConversationHistory`, `query_project`, `chat`, `escape_md`** — nomes
  ilustrativos do domínio do projeto-origem; troque pelos equivalentes do seu
  código mantendo o padrão da receita.
