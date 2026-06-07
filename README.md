# 🥫 Despensa

> App mobile (Flutter) de controle de **despensa/estoque doméstico**, 100% offline na UI, com
> dados locais (SQLite/Drift) e recursos de **IA** — escanear nota fiscal e sugerir receitas.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Drift](https://img.shields.io/badge/Drift_(SQLite)-0B5394)
![Riverpod](https://img.shields.io/badge/Riverpod-42A5F5)
![Claude](https://img.shields.io/badge/Claude_Vision-D97757?logo=anthropic&logoColor=white)

**[Português](#-português) · [English](#-english)**

---

## 🇧🇷 Português

### Sobre

App Android para gerenciar o estoque da casa: o que tem, o que está acabando, validades e listas de
compras — funcionando **offline** (só as funções de IA usam a rede). Organizado em 4 abas:
**Início · Estoque · Listas · Perfil**.

### Destaques técnicos

- **Persistência local tipada com Drift (SQLite)** — schema com geração de código (`build_runner`),
  consultas reativas.
- **Gerência de estado com Riverpod** e navegação com **go_router** (4 abas + telas de detalhe).
- **IA multimodal (Claude Vision)**: foto da **nota fiscal** → revisar → entra no estoque; e
  **receitas** com base no que há na despensa, com botão "adicionar o que falta à lista".
- **Fluxo de listas inteligente**: sugere o que está acabando, **modelos reutilizáveis** e
  "concluir compra → entra automático na despensa".
- **Offline-first**: fonte empacotada como asset (sem download em runtime); rede só para IA.
- **Cuidado com segredos**: a chave da IA fica **fora do versionamento** (ofuscada, com aviso
  explícito de que ofuscação não é segurança real — roadmap para proxy/serverless + limite de gasto).

### Estrutura

```
lib/
  core/        # tema, banco (Drift), formatação, IA, widgets base
  data/        # providers Riverpod
  features/    # home, inventory, lists, profile, ai, movements, shell
  routing/     # go_router (4 abas + telas de detalhe)
```

### Stack

Flutter · Dart · Drift/SQLite · Riverpod · go_router · Anthropic Claude (visão + texto).

### Como rodar

```bash
flutter pub get
dart run build_runner build   # gera o código do banco (Drift)
flutter run                   # dispositivo/emulador conectado
```

> A chave da IA é opcional para navegar o app; veja `lib/core/ai/` para o ponto de integração.
> O app foi pensado para receber a chave via `--dart-define` ou, em produção, um proxy/serverless.

---

## 🇺🇸 English

### About

An Android app to manage your household pantry: what you have, what's running low, expiry dates and
shopping lists — working **offline** (only the AI features use the network). Organized in 4 tabs:
**Home · Inventory · Lists · Profile**.

### Technical highlights

- **Typed local persistence with Drift (SQLite)** — code-generated schema (`build_runner`) and
  reactive queries.
- **State management with Riverpod** and navigation with **go_router** (4 tabs + detail screens).
- **Multimodal AI (Claude Vision)**: snap a **receipt** → review → add to inventory; and **recipes**
  based on what's in the pantry, with an "add missing items to list" button.
- **Smart list flow**: suggests low-stock items, **reusable templates**, and "complete purchase →
  auto-adds to pantry".
- **Offline-first**: bundled font asset (no runtime download); network only for AI.
- **Secret hygiene**: the AI key is **kept out of version control** (obfuscated, with an explicit
  note that obfuscation isn't real security — roadmap toward a proxy/serverless + spend limit).

### Stack

Flutter · Dart · Drift/SQLite · Riverpod · go_router · Anthropic Claude (vision + text).

### Getting started

```bash
flutter pub get
dart run build_runner build   # generate the Drift database code
flutter run                   # connected device/emulator
```

---

<sub>Autor / Author: **Paulo Bueno** · [github.com/paulobueno164](https://github.com/paulobueno164)</sub>
