#!/usr/bin/env python3
"""Mede o peso (em caracteres unicode) de cada seção `## ` de um arquivo Markdown
e classifica cada seção como REGRA (manter inline) ou REFERÊNCIA (candidata a extrair).

Uso:
    python3 measure_sections.py CAMINHO/AGENTS.md [--limite 40000]

Por que caracteres unicode e não bytes: o aviso "Large AGENTS.md will impact
performance (NN.Nk chars > 40.0k)" conta CARACTERES. Em pt-BR, cada acento é 1 char
mas 2 bytes em UTF-8 — `wc -c` (bytes) superestima. Aqui usamos `len(str)`.

A classificação é uma HEURÍSTICA para priorizar o que olhar primeiro; a decisão
final é sempre do agente/humano (uma seção de regra nunca deve ser extraída só
porque contém uma tabela).
"""
import argparse
import re
import sys

# Sinais de que a seção é REFERÊNCIA/ÍNDICE/ARQUIVO (peso morto no contexto sempre-carregado)
REFERENCE_HINTS = [
    "inventário", "inventario", "catálogo", "catalogo", "referência", "referencia",
    "histórico", "historico", "removido", "arquivad", "clone:", "gh repo clone",
    "trade-off", "trade-offs", "setup por repo", "cuidados conhecidos", "snapshot",
    "tabela leve", "observações sobre", "observacoes sobre",
]
# Sinais de que a seção é REGRA/POLÍTICA/COMPORTAMENTO (fonte única — NÃO extrair)
RULE_HINTS = [
    "deve ", "devem ", "nunca ", "sempre ", "regra", "política", "politica",
    "obrigat", "proibid", "jamais", "não fazer", "nao fazer", "restrição", "restricao",
    "diretriz", "convenção", "convencao", "fonte única", "fonte unica", "definition of done",
]


def split_sections(text):
    """Quebra o texto em (titulo, corpo) por headers de nível 2 (`## `)."""
    lines = text.split("\n")
    sections = []
    cur_title = "(preâmbulo)"
    buf = []
    for ln in lines:
        if ln.startswith("## "):
            sections.append((cur_title, "\n".join(buf)))
            cur_title = ln[3:].strip()
            buf = [ln]
        else:
            buf.append(ln)
    sections.append((cur_title, "\n".join(buf)))
    return sections


def classify(body):
    """Retorna ('REFERÊNCIA'|'REGRA'|'MISTO', score_ref, score_rule)."""
    low = body.lower()
    score_ref = sum(low.count(h) for h in REFERENCE_HINTS)
    score_rule = sum(low.count(h) for h in RULE_HINTS)
    # Tabela grande puxa para referência; muitos ~~tachados~~ idem
    table_rows = len([l for l in body.split("\n") if l.strip().startswith("|")])
    strikes = body.count("~~") // 2
    score_ref += table_rows // 3 + strikes
    if score_ref >= score_rule * 2 and score_ref >= 3:
        return "REFERÊNCIA", score_ref, score_rule
    if score_rule >= score_ref:
        return "REGRA", score_ref, score_rule
    return "MISTO", score_ref, score_rule


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--limite", type=int, default=40000,
                    help="limiar de chars do aviso de performance (default 40000)")
    ap.add_argument("--margem", type=int, default=2000,
                    help="folga abaixo do limite que se quer atingir (default 2000)")
    args = ap.parse_args()

    try:
        text = open(args.path, encoding="utf-8").read()
    except OSError as e:
        print(f"erro ao ler {args.path}: {e}", file=sys.stderr)
        sys.exit(2)

    total = len(text)
    alvo = args.limite - args.margem
    print(f"arquivo: {args.path}")
    print(f"chars (unicode): {total}   bytes (utf-8): {len(text.encode('utf-8'))}")
    print(f"limite do aviso: {args.limite}   alvo (c/ margem): {alvo}")
    excesso = total - alvo
    if total <= args.limite:
        print(f"STATUS: OK ({total} <= {args.limite}) — sem aviso de performance.")
    else:
        print(f"STATUS: ACIMA — precisa cortar ~{excesso} chars para chegar no alvo.")
    print()

    sections = split_sections(text)
    sections_sorted = sorted(sections, key=lambda s: len(s[1]), reverse=True)
    print(f"{'chars':>7}  {'%':>5}  {'classe':<11} seção")
    print("-" * 72)
    for title, body in sections_sorted:
        c = len(body)
        pct = 100 * c / total if total else 0
        klass, sr, ru = classify(body)
        print(f"{c:7d}  {pct:5.1f}  {klass:<11} {title[:48]}")

    print()
    print("Candidatas a EXTRAIR (classe REFERÊNCIA, ordenadas por ganho):")
    cum = 0
    for title, body in sections_sorted:
        klass, *_ = classify(body)
        if klass != "REFERÊNCIA":
            continue
        cum += len(body)
        marca = "  <-- já resolve" if (total - cum) <= args.limite else ""
        print(f"  - {title[:50]:<50} ({len(body)} chars){marca}")
    if cum == 0:
        print("  (nenhuma seção classificada como REFERÊNCIA — revisar manualmente as MISTO)")


if __name__ == "__main__":
    main()
