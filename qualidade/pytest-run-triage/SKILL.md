---
name: pytest-run-triage
description: Roda a suíte pytest do projeto, resume contagens de pass/fail e tria as falhas com caminho de arquivo e causa curta (file:line). Use quando o usuário pedir para rodar os testes, checar a suíte, investigar testes falhando ou perguntar "por que o teste X quebrou".
---

# pytest-run-triage — rodar a suíte pytest e triar falhas com file:line (TOOL · v1.0.0 · Alex Jesus)

Rodar e analisar a suíte pytest do projeto.

## 1. Rodar a suíte

```
uv run pytest tests/ -q
```

Se o usuário perguntou sobre um módulo específico, estreite a invocação:

```
uv run pytest tests/test_<module>.py -v
```

## 2. Interpretar o resultado

- **Tudo verde:** reporte `<N> passed in <T>s`. Pare aqui, a menos que o usuário
  tenha pedido outra coisa (ex.: cobertura).
- **Qualquer vermelho:** NÃO resuma só a última linha. Colete os IDs dos testes
  falhos na seção de short summary (`FAILED tests/test_x.py::TestY::test_z`).

## 3. Triar as falhas

Para cada falha:

1. Rode de novo só aquele teste com `-v` para obter o traceback completo:
   ```
   uv run pytest tests/test_x.py::TestY::test_z -v
   ```
2. Classifique a causa a partir do traceback:
   - `AssertionError` → desvio de comportamento; leia o teste e o código ao redor
   - `AttributeError` / `ImportError` → mudança de API ou alvo de mock errado
   - `TimeoutError` → problema na maquinaria async; verifique se o
     `asyncio.wait_for` está sendo exercitado corretamente
   - Qualquer `httpx.*` → problema de rede/mocking; verifique o setup do mock
3. Proponha a correção em uma frase, com referências `file:line`.

## 4. Formato do relatório

```
Suite: <N passed / M failed / T seconds>

Failures:
- tests/test_x.py::TestY::test_z — <causa em 1 linha> — fix em <file:line>
- ...

Recommendation: <aplicar fix direto | investigar mais | perguntar ao usuário>
```

## Notas

- Nunca instale `pytest-cov`, `pytest-mock` ou qualquer dependência de teste para
  "ajudar", se a superfície de dependências do projeto for deliberada (consulte o
  documento de convenções de teste do repo).
- Não "conserte" teste flaky adicionando retries. Se um teste flaqueia, investigue
  a causa raiz (geralmente sincronização baseada em timing que deveria usar
  `asyncio.Event`).
- Se todos os testes passam mas o usuário suspeita de lacuna, rode de novo com
  `--collect-only` para listar o escopo coberto e cruze com os módulos do
  pacote-fonte do projeto.

## Quando NÃO usar

- Para **escrever** testes novos ou corrigir padrões de mocking async — isso é a
  skill `pytest-async-testing`.
- Em projetos que não usam pytest (outro runner tem outra semântica de saída e de
  short summary).
- Para medir cobertura como objetivo principal sem que o projeto já tenha a
  tooling de cobertura instalada (ver a primeira nota: não instalar dependências
  por conta própria).

## Adaptação

- **Renomeada do nome genérico original ao ser publicada.**
- **`uv run pytest`** — substitua pelo invocador do seu projeto (`poetry run
  pytest`, `pytest` direto no venv, `make test`, etc.).
- **`tests/`** — ajuste ao layout de testes do seu repo.
- **Classes de causa (passo 3.2)** — a lista reflete um serviço async com httpx;
  acrescente as classes de erro típicas da sua stack (ex.: erros de ORM, de
  driver de banco).
- **Documento de convenções de teste** — o projeto-origem mantinha a política de
  dependências em `.claude/rules/tests.md`; aponte para o equivalente do seu repo.
