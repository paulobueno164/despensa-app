# Pantry ("Despensa") — Plano do App

App de controle de despensa/estoque doméstico, **Flutter (Dart)**, **dados locais (SQLite)**, **Android primeiro**.
Réplica fiel das telas de referência (Início / Estoque / Listas / Perfil).

> ✅ Requisitos dos áudios (Ana Beatriz) + ideias do usuário incorporados (ver §4.3 e §8).
> Dados continuam **locais (SQLite)**; recursos de IA/nota fiscal usam serviço em nuvem (ver §8).

---

## 1. Stack e decisões técnicas

| Área | Escolha | Por quê |
|------|---------|---------|
| Linguagem/Framework | **Flutter 3.x / Dart** | Pedido do usuário; UI polida, um código → Android (e iOS depois) |
| Banco de dados | **Drift** (SQLite tipado e reativo) | Queries reativas (`Stream`) → dashboard atualiza sozinho ao mudar o estoque |
| Estado | **Riverpod** (`flutter_riverpod`) | Simples, testável, integra com streams do Drift |
| Navegação | **go_router** com `StatefulShellRoute` | Bottom nav com 4 abas mantendo estado de cada aba |
| Formatação | **intl** (locale `pt_BR`) | Datas ("Hoje, 09:24", "Ontem"), números ("1,2 kg") |
| Ícones | Material Icons (+ `flutter_svg` se preciso) | Cobre os ícones das telas |
| Fontes | `google_fonts` (Inter ou similar) | Tipografia próxima da referência |

**Arquitetura:** feature-first + repository pattern. UI nunca fala direto com o banco — passa por repositórios expostos como providers Riverpod.

---

## 2. Estrutura de pastas

```
lib/
  main.dart
  app.dart                      # MaterialApp.router, tema, ProviderScope
  core/
    theme/
      app_colors.dart           # paleta extraída das telas
      app_theme.dart            # ThemeData, typography, shapes
      app_spacing.dart
    db/
      database.dart             # AppDatabase (Drift)
      tables.dart               # definição das tabelas
      daos/                     # ItemsDao, MovementsDao, CategoriesDao, ListsDao
      seed.dart                 # dados iniciais = telas de referência
    format/
      quantity_format.dart      # "500g", "1,2 kg", "2 rolos", "Quase vazio"
      date_format.dart          # "Hoje, 09:24", "Ontem, 18:10"
    widgets/                    # cartões, barra de progresso, etc. reutilizáveis
  features/
    home/                       # aba Início (dashboard)
    inventory/                  # aba Estoque
    lists/                      # aba Listas
    profile/                    # aba Perfil
    items/                      # detalhe/criação/edição de item (compartilhado)
    movements/                  # registrar compra/retirada (o botão +)
  routing/
    app_router.dart
```

---

## 3. Modelo de dados (tabelas SQLite)

**categories**
- `id` PK, `name`, `icon_key` (ex: `basket`, `sparkles`, `drop`, `cup`, `paw`, `dots`), `color_hex`, `sort_order`

**items**
- `id` PK, `name`, `category_id` FK
- `quantity` (double), `unit` (`g`,`kg`,`un`,`rolos`,`caixas`,`pacote`,`L`…)
- `min_quantity` (limite p/ "está acabando"), `full_quantity` (100% da barra de progresso)
- `low_label` (opcional, ex: "Quase vazio" quando não há número)
- `note`, `image_path` (opcional), `expires_at` (opcional, p/ validade futura)
- `created_at`, `updated_at`

**movements** (movimentações)
- `id` PK, `item_id` FK, `type` (`in` | `out`)
- `quantity`, `unit`, `note`, `created_at`

**shopping_lists**
- `id` PK, `name`, `is_template` (bool — lista salva/modelo reutilizável), `archived` (bool), `completed_at` (nullable), `created_at`

**shopping_list_items**
- `id` PK, `list_id` FK, `item_id` FK (nullable — null = item ainda não existe no estoque), `name`, `quantity`, `unit`, `checked` (bool — "já peguei"), `created_at`

**household** (linha única — perfil/config)
- `id` PK, `display_name` ("Família Silva"), `avatar_key`, settings (tema, etc.)

### Regras derivadas (queries reativas)
- **Está acabando / "Acabando"**: `items WHERE quantity <= min_quantity`
- **Barra de progresso**: `quantity / full_quantity` (clamp 0–1), cor laranja quando acabando
- **Stats do topo**: total de itens, contagem de acabando, contagem de categorias
- **Categorias (contagem)**: `COUNT(items) GROUP BY category_id`
- **Últimas movimentações**: `movements ORDER BY created_at DESC LIMIT n`
- Registrar movimento (`in`/`out`) **ajusta** `items.quantity` automaticamente (transação)

---

## 4. Telas (a partir das imagens)

### 4.1 Início (Home / dashboard) — réplica fiel
- **Topo:** avatar (folha, verde) · "Bom dia, **Família Silva**" (saudação por horário) · sino com badge vermelho
- **Hero card verde:** "SUA DESPENSA HOJE" / "Você tem **N** itens que precisam de atenção." / subtítulo "Toque em + para registrar uma compra ou retirada."
- **3 cartões de stats:** `84 Itens` · `6 Acabando` (laranja) · `12 Categorias`
- **"Está acabando"** + "Ver tudo ›": linhas com ícone de alerta, nome, quantidade à direita, barra de progresso laranja (Arroz branco 500g, Café em pó 100g, Papel higiênico 2 rolos, Detergente "Quase vazio"…)
- **"Categorias"**: grid 3×2 (Alimentos 32, Limpeza 14, Higiene 11, Bebidas 9, Pets 6, Outros 12) com ícone e contagem
- **"Últimas movimentações"**: linha com ícone de seta (entra=verde ↙ / sai=vermelho ↗), nome, "Hoje 09:24 / Ontem 18:10", valor (+6 caixas / −1 pacote / +1,2 kg)
- **FAB +** verde → folha de ação "Registrar compra (entrada) / Registrar retirada (saída)"
- **Bottom nav:** Início · Estoque · Listas · Perfil

### 4.2 Estoque (Inventory)
- Lista completa de itens com busca e filtro por categoria; toque abre detalhe do item; editar quantidade, limite mínimo, categoria; criar novo item. *(layout a refinar — não há imagem ainda)*

### 4.3 Listas (Shopping lists) — **fluxo definido pelos áudios**
Funcionalidade central da v1. Fluxo:
1. **Sugestão automática:** a lista já mostra o que está **acabando/faltando** na despensa (vem dos `items WHERE quantity <= min_quantity`) — um toque adiciona à lista.
2. **Adição manual:** a pessoa pode acrescentar qualquer item (vinculado a um item do estoque ou texto livre, ex. "Manga").
3. **Listas salvas / modelos (templates):** dá pra ter várias listas pré-prontas reutilizáveis (ex.: lista "Frutas", "Compra do mês"). Salvar uma lista como modelo e recriar depois.
4. **Modo mercado (tickar):** dentro da lista, cada item tem checkbox "já peguei". Marca conforme pega no mercado.
5. **Concluir → vai pra despensa automático:** ao finalizar/salvar a lista, os itens marcados geram **movimentações de entrada** e **atualizam o estoque** automaticamente — sem cadastrar produto por produto. (É a dor central: "tirar a preguiça".)
   - Itens marcados que já existem no estoque: soma a quantidade.
   - Itens novos: cria o item (pede categoria/unidade, com defaults).

Telas: lista de listas (ativas + modelos) → detalhe da lista (itens, checkboxes, "+ adicionar", botão "Concluir compra"). *(sem imagem de referência — desenho proposto por mim, validamos depois.)*

### 4.4 Perfil
- Nome da família/avatar, gerenciar categorias, preferências (tema, notificações de validade/estoque baixo). *(sem imagem)*

---

## 5. Tema / design tokens (extraídos das telas)
- **Verde primário (hero/CTA):** ~`#2F5D50` / `#356B5A`
- **Fundo creme:** ~`#F1F4EF`
- **Cartões:** branco, cantos ~20px, sombra suave
- **Alerta (acabando):** laranja ~`#E8852B`
- **Entrada:** verde · **Saída:** vermelho ~`#D5573B`
- Tipografia: títulos seção em negrito ~18px; números de stats grandes ~28px

---

## 6. Etapas de execução (depois do "ok")

1. **Instalar Flutter SDK** (não está na máquina) e rodar `flutter doctor`; aceitar licenças Android. *(Android SDK já existe; falta criar um emulador/AVD ou conectar um celular.)*
2. `flutter create` na pasta `C:\projetos\pantry` (org/bundle id, ex. `com.familiasilva.pantry`).
3. Adicionar dependências (drift, sqlite3_flutter_libs, path_provider, flutter_riverpod, go_router, intl, google_fonts).
4. Implementar **tema** + tokens.
5. Implementar **banco Drift** (tabelas, DAOs) + **seed** idêntico às telas.
6. Repositórios + providers Riverpod.
7. **Aba Início** pixel-a-pixel + FAB (registrar entrada/saída).
8. Esqueleto navegável de **Estoque / Listas / Perfil**.
9. Rodar no Android (emulador ou device) e ajustar visual.
10. Iterar nas demais abas conforme requisitos dos áudios.

---

## 8. Fase 2 — IA & Nota fiscal (recursos "inteligentes")

> Estes recursos **precisam de internet + serviço de IA na nuvem** (caminho recomendado: **API da Claude**).
> Os dados da despensa continuam locais; só a imagem da nota / a lista de itens são enviadas à IA quando o recurso é usado.

### 8.1 Foto da nota do mercado (OCR de cupom fiscal)
- Usuário tira foto / escolhe imagem do cupom.
- Imagem enviada para um modelo de **visão** (Claude) → retorna lista estruturada `[{produto, quantidade, unidade, preço}]`.
- App mostra os itens reconhecidos para o usuário **revisar/ajustar** (casar com itens existentes, escolher categoria) e confirma → vira **entrada no estoque** (mesmo destino do "concluir lista").
- Considerações: custo por chamada, qualidade do OCR de cupom brasileiro, tela de revisão obrigatória (IA erra).

### 8.2 Receitas com IA
- "O que dá pra cozinhar?" → envia os itens disponíveis na despensa para a Claude → sugestões de receitas usando o que se tem (e o que falta comprar → vira lista).
- Pode marcar quais ingredientes "consumir" → gera **saídas** no estoque.

### 8.3 Arquitetura para IA
- Camada `ai/` com um cliente HTTP para a API.
- **Chave de API não pode ficar no app** (segurança). Opções:
  - (a) v1 simples: chave em config local só para testes/dev.
  - (b) recomendado para produção: um pequeno **proxy/back-end** (function serverless) que guarda a chave e fala com a Claude. Entra quando formos publicar.

---

## 9. Escopo da v1 (decidido: tudo junto)
- **Início** (dashboard réplica)
- **Estoque** com itens, categorias, **validade + alerta de vencimento**
- **Listas de compras** com fluxo completo (sugestão automática, manual, modelos salvos, tickar, concluir → estoque)
- **Perfil / categorias / preferências**
- **IA (online, API da Claude):** foto da nota fiscal (OCR) → entrada no estoque · receitas com base na despensa
- **Alertas:** estoque baixo ("está acabando") + validade próxima

### Pré-requisitos extras (por causa da IA)
- **Chave de API da Anthropic** (o usuário precisa ter/criar uma). v1: chave em config local (`--dart-define`/arquivo não versionado) para desenvolvimento; **proxy serverless** quando for publicar na loja.
- Permissões Android: **câmera** + leitura de imagem (foto da nota), **internet**.
- **notifications** (flutter_local_notifications) para avisos de validade/estoque.

---

## 10. Decisões tomadas
- Stack **Flutter** · dados **locais SQLite (Drift)** · **Android** primeiro.
- IA e nota fiscal **na v1**, via **API da Claude (Anthropic)**.
- **Validade com alerta** na v1.

## 11. Pendências / a confirmar
- **Chave de API da Anthropic:** o usuário tem uma? (necessária para testar OCR/receitas).
- Detalhe visual de **Estoque / Listas / Perfil** (sem imagens — proponho o layout e validamos).
- `bundle id` do app (sugestão: `com.familiasilva.pantry`).
- Sync em nuvem entre celulares da família: fora da v1 (decidido local-first).
- Dispositivo de teste: criar **emulador (AVD)** ou conectar **celular** com depuração USB.
