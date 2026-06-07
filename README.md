# Despensa 🥫

App de controle de despensa/estoque doméstico — **Flutter**, dados **locais (SQLite/Drift)**, Android primeiro.
Réplica das telas de referência: **Início · Estoque · Listas · Perfil**.

## Funcionalidades

- **Início (dashboard):** itens em atenção, contadores (itens / acabando / categorias), "Está acabando" com barra de progresso, grade de categorias e últimas movimentações.
- **Estoque:** busca, filtro por categoria, detalhe do item, validade com alerta, entrada/saída que ajusta o estoque.
- **Listas de compras:** sugere o que está acabando, adição manual, **modelos salvos** (reutilizáveis), marcar "já peguei" e **concluir → entra automático na despensa**.
- **IA (API da Claude):** escanear nota fiscal (foto → revisar → estoque) e receitas com base na despensa — cada receita tem **"adicionar o que falta à lista"**.
- **100% offline na UI:** fonte Inter empacotada como asset (sem download em runtime); só a IA usa a rede.

## Como rodar

Pré-requisitos: Flutter SDK (em `C:\flutter`), Android SDK, um emulador ou celular com depuração USB.

```powershell
# adiciona o Flutter ao PATH da sessão
$env:Path = "C:\flutter\bin;" + $env:Path

# instala dependências
flutter pub get

# gera o código do banco (Drift) — necessário após mexer nas tabelas
dart run build_runner build

# roda no dispositivo conectado
flutter run
```

### IA (nota fiscal + receitas)

As funções de IA chamam a API da Anthropic. A chave está **embutida no app de forma ofuscada**
(XOR) em `lib/core/ai/api_key.dart` — arquivo **não versionado** (`.gitignore`), porque nesta
fase não há backend. Assim o app funciona sem precisar passar a chave a cada build.

> ⚠️ **Ofuscação não é segurança real**: quem descompilar o APK consegue extrair a chave.
> Antes de publicar: defina um **limite de gasto** na chave (console da Anthropic),
> **rotacione** a chave e mova-a para um **proxy/serverless**.

Opcional — sobrescrever a chave embutida em build/run (tem prioridade):

```powershell
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-sua-chave
```

**Regerar a chave ofuscada** (ao trocar de chave): gere novos arrays XOR e cole-os em
`lib/core/ai/api_key.dart` (`_pad` e `_obf`). O modelo usado é `claude-sonnet-4-6` (visão + texto).

## Estrutura

```
lib/
  core/        # tema, banco (Drift), formatação, IA, widgets base
  data/        # providers Riverpod
  features/    # home, inventory (estoque), lists (listas), profile, ai, movements, shell
  routing/     # go_router (4 abas + telas de detalhe)
```

Plano detalhado e decisões em [`PLAN.md`](PLAN.md).
