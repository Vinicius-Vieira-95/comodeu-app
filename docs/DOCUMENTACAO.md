# Documentação — Aplicação COMO D'EU

Documentação técnica do app e de suas configurações. Para subir o projeto rapidamente, veja também o [QUICK_START.md](../QUICK_START.md).

## Sumário

1. [Visão geral](#1-visão-geral)
2. [Arquitetura](#2-arquitetura)
3. [Funcionalidades e fluxo de uso](#3-funcionalidades-e-fluxo-de-uso)
4. [O instrumento COMO D'EU](#4-o-instrumento-como-deu)
5. [Modelo de dados](#5-modelo-de-dados)
6. [Autenticação e segurança](#6-autenticação-e-segurança)
7. [API REST](#7-api-rest)
8. [Configuração do backend](#8-configuração-do-backend)
9. [Configuração do frontend](#9-configuração-do-frontend)
10. [Como rodar em desenvolvimento](#10-como-rodar-em-desenvolvimento)
11. [Como rodar em produção](#11-como-rodar-em-produção)
12. [Solução de problemas](#12-solução-de-problemas)
13. [Limitações conhecidas](#13-limitações-conhecidas)

---

## 1. Visão geral

O **COMO D'EU** é uma aplicação para avaliar espaços culturais (museus, galerias, teatros, bibliotecas) com base em um instrumento de **17 itens**. A avaliação acontece em duas fases:

| Fase | Quando | O que o avaliador faz |
|---|---|---|
| **Registro** | Durante a visita | Fotografa um ponto do espaço, marca o elemento na foto e escreve uma nota curta |
| **Classificação** | Depois da visita | Para cada foto, escolhe os itens COMO D'EU relacionados e escreve uma análise pessoal |

Na classificação, o app **sugere itens automaticamente** a partir das palavras da nota, mas o avaliador pode escolher qualquer um dos 17 itens.

---

## 2. Arquitetura

```
┌──────────────────────────┐        HTTP + JSON         ┌──────────────────────────┐        JDBC        ┌──────────────┐
│  App Flutter (frontend)  │  ───────────────────────▶  │  API Spring Boot         │  ───────────────▶  │  PostgreSQL  │
│  Android / Web           │  Authorization: Bearer JWT │  (backend) :8080/api     │                    │  banco       │
│                          │  ◀───────────────────────  │                          │  ◀───────────────  │  "comodeu"   │
└──────────────────────────┘                            └──────────────────────────┘                    └──────────────┘
```

| Camada | Tecnologia | Pasta |
|---|---|---|
| App | Flutter / Dart 3 (Material 3, tema claro/escuro automático) | `frontend/` |
| API | Spring Boot 3.5, Java 25, Gradle | `backend/` |
| Segurança | Spring Security + JWT (jjwt 0.12), senhas com BCrypt | `backend/.../security`, `config` |
| Banco | PostgreSQL (JPA/Hibernate, tabelas criadas automaticamente) | — |
| Documentação da API | springdoc-openapi (Swagger UI) | `backend/.../config/OpenApiConfig.java` |

### Organização do código

```
como-deu-app/
├── backend/
│   ├── build.gradle
│   ├── init-db.sql                    # script opcional de criação do banco/tabelas
│   └── src/main/
│       ├── java/com/comodeu/
│       │   ├── ComoDeUApiApplication.java   # entrada; cria os 17 itens ao iniciar
│       │   ├── config/        # segurança, CORS, Swagger, usuário admin de dev
│       │   ├── controller/    # endpoints REST
│       │   ├── dto/           # objetos de entrada/saída (auth, evidência, item)
│       │   ├── entity/        # entidades JPA (tabelas)
│       │   ├── repository/    # acesso a dados (Spring Data JPA)
│       │   ├── security/      # JWT: geração, validação e filtro
│       │   └── service/       # regras de negócio e sugestão de itens
│       └── resources/
│           ├── application.yml        # configuração comum
│           ├── application-dev.yml    # perfil dev (padrão)
│           └── application-prod.yml   # perfil prod
└── frontend/
    ├── pubspec.yaml
    ├── android/                # projeto Android (permissões, manifest)
    ├── web/                    # projeto Web
    └── lib/
        ├── main.dart           # entrada; decide entre Login e Home
        ├── models/             # Evaluation, Evidence, ComoItem
        ├── screens/            # telas
        └── services/api_service.dart   # todas as chamadas HTTP + sessão
```

---

## 3. Funcionalidades e fluxo de uso

```
Login ──▶ Home ──▶ Nova Avaliação ──▶ Registrar Evidência
            │          (formulário)       (foto + marca + nota)
            │                                     │
            └──▶ Avaliação (evidências) ◀─────────┘
                    │  ├─ Nova evidência ──▶ Registrar Evidência
                    │  ├─ Concluir avaliação
                    │  └─ Segurar evidência ──▶ Apagar
                    └──▶ Classificar Evidência (itens + análise, editar, apagar)
```

| Tela | Arquivo | O que faz |
|---|---|---|
| **Login** | `login_screen.dart` | Entrar com e-mail e senha, ou criar conta (nome, e-mail, senha de 6 a 72 caracteres). O token fica salvo no aparelho. |
| **Home** | `home_screen.dart` | Lista as avaliações **do usuário logado**, com status *Não enviada*, *Em Progresso* ou *Concluída*. Toque em uma para abri-la. Mostra avisos de "sem conexão" e de itens aguardando envio, com o botão **Sincronizar**. Puxe para baixo para atualizar. |
| **Nova Avaliação** | `evaluation_form_screen.dart` | Nome do visitante, nome do espaço e tipo (Museu, Galeria, Teatro, Biblioteca, Outro). Sem conexão, a avaliação fica guardada no aparelho. |
| **Registrar Evidência** | `capture_screen.dart` | Abre a câmera (qualidade 85%, no máximo 1920 px). Um toque na foto marca o elemento (coordenadas X/Y). A nota rápida tem até 200 caracteres. A foto é enviada como arquivo (upload multipart). Sem conexão, a evidência fica guardada no aparelho. |
| **Avaliação** | `gallery_screen.dart` | Grade com as evidências e o status de cada uma: *Registrada* (laranja), *Classificada* (verde), *Não enviada* (cinza) ou *Erro ao enviar* (vermelho). Tem o botão **Nova evidência** e o ✔ **Concluir avaliação** na barra superior. Tocar em uma evidência abre a classificação, e segurar permite apagá-la. |
| **Classificar Evidência** | `classification_screen.dart` | Mostra a foto, a nota, os **itens sugeridos** (⭐) e **todos os 17 itens**. Se a evidência já foi classificada, os itens e a análise salvos aparecem preenchidos ("Editar Classificação"). Salvar **substitui** a classificação anterior, sem duplicar. A lixeira na barra superior apaga a evidência. Precisa de conexão. |

**Sessão:** se a API responder `401` (token expirado ou inválido), o app encerra a sessão e volta para o Login (`ApiService.onUnauthorized` em `main.dart`). O token vale **24 horas**. Nesse caso, as pendências offline **são mantidas** e enviadas quando a mesma conta entrar de novo.

**Concluir avaliação:** depois de concluída, a avaliação não aceita novas evidências, mas as já registradas ainda podem ser classificadas.

### Modo offline (Android)

Durante a visita a conexão pode falhar. Por isso, no Android, o app continua funcionando sem internet:

| Ação sem conexão | O que acontece |
|---|---|
| Ver avaliações e evidências | Mostra a última versão salva no aparelho (e as fotos já vistas) |
| Criar avaliação | Fica guardada no aparelho como *Não enviada* |
| Registrar evidência | Fica guardada no aparelho (com a foto) como *Não enviada* |
| Classificar evidência | **Não disponível**: precisa de conexão |

**Sincronização:** o app envia as pendências automaticamente ao abrir a Home ou uma avaliação, ao puxar para atualizar, e pelo botão **Sincronizar**. Primeiro são enviadas as avaliações, depois as evidências. Se o servidor recusar uma evidência (por exemplo, a avaliação foi concluída nesse meio-tempo), ela fica marcada como *Erro ao enviar* com o motivo, e o usuário pode apagá-la.

**Onde fica:** banco SQLite do app (`comodeu_offline.db`, em `lib/services/offline_store.dart`). Os dados ficam ligados à conta: se outra conta entrar no aparelho, eles são apagados. Ao tocar em **Sair**, o app avisa se há pendências, porque sair apaga tudo o que ainda não foi enviado.

No **Flutter Web** o modo offline não existe (o `sqflite` não roda no navegador): sem conexão, as ações mostram erro.

---

## 4. O instrumento COMO D'EU

Os 17 itens são criados automaticamente na primeira vez que o backend sobe (`ComoItemService.initializeComoItems`, chamado em `ComoDeUApiApplication`). Se a tabela já tiver itens, nada é recriado.

| # | Item | Categoria | Palavras-chave (para sugestão) |
|---|---|---|---|
| 1 | Acessibilidade Física | Acessibilidade | rampa, escada, porta, acesso, acessível, elevador, desnível |
| 2 | Conforto Térmico | Conforto | temperatura, frio, quente, clima, ventilação |
| 3 | Conforto Acústico | Conforto | barulho, som, ruído, acústica, silêncio |
| 4 | Qualidade da Iluminação | Conforto | luz, iluminação, escuro, brilho, claro, ofuscamento |
| 5 | Mobiliário Apropriado | Conforto | banco, cadeira, assento, descanso, mobiliário |
| 6 | Sinalização Clara | Informação | placa, sinal, indicação, direção, localizar, mapa |
| 7 | Informações Legíveis | Informação | letra, fonte, pequena, contraste, legível, ilegível, wcag |
| 8 | Acesso à Informação | Informação | informação, guia, folheto, audioguia, descrição |
| 9 | Comodidades Gerais | Informação | banheiro, água, café, loja, guarda-volumes, serviço |
| 10 | Clareza Expositiva | Experiência | explicação, contexto, história, significado, interpretação |
| 11 | Engajamento do Visitante | Experiência | fila, espera, longa, congestionado, aglomeração, engajamento |
| 12 | Diversidade de Conteúdo | Experiência | conteúdo, diversidade, perspectiva, variedade |
| 13 | Segurança e Privacidade | Segurança | segurança, risco, privacidade, proteção |
| 14 | Gestão do Tempo | Segurança | tempo, pressa, rápido, longo, duração |
| 15 | Qualidade do Atendimento | Segurança | atendimento, staff, guia, funcionário, profissional |
| 16 | Recursos Educacionais | Segurança | educação, aprendizado, material, workshop, atividade |
| 17 | Impressão Geral / Satisfação | Segurança | satisfação, impressão, geral, recomendação |

### Como funciona a sugestão automática

`SuggestionService.suggestItems` recebe a nota rápida e:

1. Separa a nota em palavras, em minúsculas e sem `. , ! ?`.
2. Compara cada palavra com as palavras-chave de cada item:
   - **+5 pontos** quando a palavra é igual à palavra-chave;
   - **+2 pontos** quando a palavra-chave *contém* a palavra (só para palavras com mais de 2 letras).
3. Devolve até **3 itens** com maior pontuação.

A comparação não trata plural nem variações. Por exemplo, "rampas" não é igual a "rampa". Por isso a tela de classificação sempre mostra também a lista completa.

---

## 5. Modelo de dados

As tabelas são criadas e atualizadas pelo Hibernate (`ddl-auto: update`). As relações são feitas por IDs numéricos simples (sem chaves estrangeiras declaradas no JPA).

```
users ──1:N──▶ evaluations ──1:N──▶ evidences ──1:N──▶ classifications ◀──N:1── como_items
     (owner_id)                        │
                                       └── photo_path ──▶ arquivo na pasta de fotos
```

| Tabela | Campos principais | Observações |
|---|---|---|
| `users` | `id`, `name`, `email` (único), `password` (hash BCrypt), `role` (`USER`/`ADMIN`), `created_at` | O cadastro público sempre cria `USER`. |
| `evaluations` | `id`, `owner_id`, `visitor_name`, `cultural_space_name`, `space_type`, `visit_date`, `created_at`, `completed_at`, `status` | `owner_id` é o usuário dono. `status`: `IN_PROGRESS` → `COMPLETED`. |
| `evidences` | `id`, `evaluation_id`, `photo_path`, `mark_x`, `mark_y`, `quick_note` (≤200), `capture_time`, `status` | `photo_path` é o nome do arquivo da foto. `status`: `REGISTERED` ⇄ `CLASSIFIED`. A coluna `photo_data` é legada (ver abaixo). |
| `como_items` | `id`, `item_number` (1–17), `name`, `description`, `category`, `keywords`, `active` | Criados na inicialização. |
| `classifications` | `id`, `evidence_id`, `como_item_id`, `personal_analysis` (≤2000), `classification_time` | Uma linha por item escolhido. **No máximo uma por (evidência, item).** |

### Fotos

As fotos ficam **em arquivos**, na pasta definida por `app.storage.photos-dir` (variável `PHOTOS_DIR`, padrão `uploads/photos`, relativa à pasta onde o backend roda). No banco fica só o nome do arquivo, um UUID gerado pelo servidor, como `3a16…cad5.jpg`.

- O servidor aceita **JPEG, PNG ou WebP**, identificados pelo conteúdo do arquivo (não pela extensão). O limite é de 10 MB.
- Ao apagar uma evidência ou avaliação, o arquivo também é apagado, só depois que o banco confirmar a exclusão.
- A pasta `backend/uploads/` está no `.gitignore`.

### Ajustes automáticos de dados antigos (`DataMaintenance`)

A cada inicialização, o backend corrige dados criados por versões anteriores. Rodar de novo não causa efeito extra.

1. **Fotos no banco:** evidências com a foto na coluna `photo_data` (formato antigo) têm a imagem movida para a pasta de fotos, e a coluna é limpa.
2. **Classificações duplicadas:** quando a mesma evidência tem o mesmo item mais de uma vez, fica só a classificação mais recente.

Avaliações antigas, criadas antes de existir `owner_id`, ficam **sem dono** e são visíveis apenas para ADMIN.

---

## 6. Autenticação e segurança

- **Login/cadastro:** `POST /auth/login` ou `POST /auth/register` devolvem um token JWT:
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86400,
    "user": { "id": 1, "name": "Administrador", "email": "admin@comodeu.dev", "role": "ADMIN" }
  }
  ```
- **Uso do token:** toda requisição protegida envia `Authorization: Bearer <token>`. No app, isso é feito automaticamente por `_AuthClient` em `api_service.dart`.
- **Token:** assinado com HS256 usando `jwt.secret` (mínimo de **32 bytes**, senão a API não sobe). Validade de `jwt.expiration` (24 h).
- **Rotas públicas:** só `POST /auth/register`, `POST /auth/login` e `/error`. Todas as outras respondem `401` sem token válido.
- **Dono dos dados:** cada avaliação pertence ao usuário que a criou. Um `USER` só vê e altera as próprias avaliações, e as evidências, fotos e classificações delas. Um `ADMIN` vê todas, inclusive as antigas sem dono. Pedir um registro de outro usuário responde **`404`**, como se ele não existisse, para não revelar que existe.
- **Senhas:** guardadas apenas como hash BCrypt. O login responde a mesma mensagem para e-mail inexistente e senha errada.
- **Sem sessão/cookies:** a API é *stateless* e o CSRF fica desligado, porque a autenticação vai no header.
- **CORS:** só importa para o Flutter **Web**, já que o app Android não passa por CORS. As origens permitidas são configuradas por perfil (ver [seção 8](#8-configuração-do-backend)).
- **Swagger:** liberado sem login só no perfil `dev`. Em `prod` fica desligado por padrão.

---

## 7. API REST

URL base: `http://localhost:8080/api`. 🔓 = pública. Todas as outras exigem token.

### Autenticação
| Método | Rota | Descrição |
|---|---|---|
| POST 🔓 | `/auth/register` | Cria uma conta (`name`, `email`, `password`) e devolve o token |
| POST 🔓 | `/auth/login` | Login (`email`, `password`) e devolve o token |
| GET | `/auth/me` | Dados do usuário logado |

### Avaliações
Só as do usuário logado (ADMIN: todas).

| Método | Rota | Descrição |
|---|---|---|
| POST | `/evaluations` | Cria (`visitorName`, `culturalSpaceName`, `spaceType`). O dono é o usuário logado |
| GET | `/evaluations` | Lista, das mais recentes para as mais antigas |
| GET | `/evaluations/{id}` | Busca uma |
| GET | `/evaluations/status/in-progress` | Lista as em andamento |
| PUT | `/evaluations/{id}/complete` | Marca como concluída (bloqueia novas evidências) |
| DELETE | `/evaluations/{id}` | Apaga a avaliação, com as evidências, fotos e classificações |

### Evidências
| Método | Rota | Descrição |
|---|---|---|
| POST | `/evidences` | Registra. Corpo **`multipart/form-data`**: `evaluationId`, `quickNote`, `markX` e `markY` (opcionais) e o arquivo **`photo`** |
| GET | `/evidences/evaluation/{evaluationId}` | Lista as evidências de uma avaliação (sem a foto, só `hasPhoto`) |
| GET | `/evidences/{id}` | Busca uma |
| GET | `/evidences/{id}/photo` | **Bytes da foto** (`image/jpeg`, `image/png` ou `image/webp`) |
| GET | `/evidences/{id}/classifications` | Classificações salvas da evidência |
| PUT | `/evidences/{id}/classifications` | **Salva a classificação completa** (`comoItemIds`, `personalAnalysis`), substituindo a anterior. `[]` remove |
| PUT | `/evidences/{id}/classify` | Marca como classificada |
| DELETE | `/evidences/{id}` | Apaga a evidência, a foto e as classificações dela |

Exemplo de upload com `curl`:
```bash
curl -X POST http://localhost:8080/api/evidences \
  -H "Authorization: Bearer <token>" \
  -F evaluationId=1 -F "quickNote=letra pequena" -F markX=120 -F markY=80 \
  -F "photo=@foto.jpg"
```

### Itens COMO D'EU
| Método | Rota | Descrição |
|---|---|---|
| GET | `/como-items` | Lista os 17 itens |
| GET | `/como-items/{id}` | Busca um |
| GET | `/como-items/category/{category}` | Filtra por categoria |
| POST | `/como-items/suggest` | Sugere até 3 itens (`quickNote`) |
| POST | `/como-items/initialize` | Cria os itens se a tabela estiver vazia |

### Classificações
| Método | Rota | Descrição |
|---|---|---|
| POST | `/classifications` | Cria (`evidenceId`, `comoItemId`, `personalAnalysis`) e marca a evidência como classificada. Se a evidência já tiver esse item, só atualiza a análise |
| GET | `/classifications/evidence/{evidenceId}` | Lista as classificações de uma evidência |
| GET | `/classifications/item/{comoItemId}` | Lista as classificações de um item (só das avaliações do usuário) |
| GET | `/classifications/{id}` | Busca uma |
| DELETE | `/classifications/{id}` | Apaga. Se era a última, a evidência volta a *Registrada* |

### Erros
Todas as rotas respondem erros em JSON:

| Código | Quando | Exemplo de corpo |
|---|---|---|
| `400` | Dados inválidos ou faltando, foto que não é imagem, evidência em avaliação concluída | `{"status":400,"error":"Dados inválidos","fields":{"visitorName":"..."}}` |
| `401` | Sem token ou token inválido | — |
| `404` | Registro inexistente **ou de outro usuário** | `{"status":404,"error":"Evidência não encontrada: 99"}` |
| `413` | Foto maior que 10 MB | `{"status":413,"error":"Foto muito grande (máximo 10 MB)"}` |

### Swagger UI (perfil dev)
- Interface: <http://localhost:8080/api/swagger-ui.html>
- JSON OpenAPI: <http://localhost:8080/api/v3/api-docs>
- Para testar rotas protegidas: faça `POST /auth/login`, copie o `token`, clique em **Authorize** e cole só o token (sem "Bearer").

---

## 8. Configuração do backend

### Perfis

| Perfil | Quando é usado | Banco | Swagger | Usuário admin automático |
|---|---|---|---|---|
| `dev` | **Padrão**, quando nenhum perfil é informado | PostgreSQL local | Ligado, sem login | Sim |
| `prod` | `SPRING_PROFILES_ACTIVE=prod` | PostgreSQL (variáveis obrigatórias) | Desligado (ative com `SWAGGER_ENABLED=true`) | Não |

### Arquivos de configuração

**`application.yml`** — comum a todos os perfis:

| Propriedade | Valor | Significado |
|---|---|---|
| `server.port` | `${PORT:8080}` | Porta (variável `PORT`, padrão 8080) |
| `server.servlet.context-path` | `/api` | Prefixo de todas as rotas |
| `spring.profiles.default` | `dev` | Perfil quando nenhum é informado |
| `spring.servlet.multipart.max-file-size` / `max-request-size` | `10MB` | Limite de upload multipart |
| `jwt.expiration` | `86400000` | Validade do token (24 h, em ms) |

**`application-dev.yml`** — desenvolvimento:

| Propriedade | Valor |
|---|---|
| `spring.datasource.url` | `${DB_URL:jdbc:postgresql://localhost:5432/comodeu}` |
| `spring.datasource.username` / `password` | `${DB_USERNAME:postgres}` / `${DB_PASSWORD:postgres}` |
| `spring.jpa.hibernate.ddl-auto` | `update` (cria/atualiza tabelas e mantém os dados) |
| `spring.jpa.show-sql` | `true` |
| `app.cors.allowed-origins` | `http://localhost:*,http://127.0.0.1:*` |
| `app.dev-user.*` | Admin criado se não existir: **`admin@comodeu.dev` / `admin123`** |
| `jwt.secret` | Chave fixa de desenvolvimento (**não usar em produção**) |
| Log `com.comodeu` | `DEBUG` |

**`application-prod.yml`** — produção. Tudo vem de variáveis de ambiente:

| Variável | Obrigatória | Padrão | Descrição |
|---|---|---|---|
| `SPRING_PROFILES_ACTIVE` | sim | — | Deve ser `prod` |
| `DB_PASSWORD` | **sim** | — | Senha do PostgreSQL |
| `JWT_SECRET` | **sim** | — | Chave de assinatura do JWT, com 32 bytes ou mais |
| `DB_URL` | não | `jdbc:postgresql://localhost:5432/comodeu` | URL JDBC |
| `DB_USERNAME` | não | `postgres` | Usuário do banco |
| `CORS_ALLOWED_ORIGINS` | não | vazio (nenhuma origem web) | Origens do Flutter Web, separadas por vírgula |
| `PHOTOS_DIR` | não | `uploads/photos` | Pasta das fotos. **Em produção, use um disco persistente e inclua no backup** |
| `SWAGGER_ENABLED` | não | `false` | Liga o Swagger UI |
| `PORT` | não | `8080` | Porta HTTP |

Sem `DB_PASSWORD` ou `JWT_SECRET`, o backend **não sobe**. Isso é proposital.

### Dependências principais (`build.gradle`)
Spring Boot Web, Data JPA, Validation e Security · driver PostgreSQL · Lombok · jjwt 0.12.6 · springdoc-openapi 2.8 · commons-io. A toolchain Java é a **25**.

---

## 9. Configuração do frontend

### URL da API

Definida em `ApiService.baseUrl` (`lib/services/api_service.dart`), nesta ordem de prioridade:

1. Valor passado em `--dart-define=API_BASE_URL=...`
2. **Android** (emulador): `http://10.0.2.2:8080/api` (`10.0.2.2` é o "localhost do PC" visto de dentro do emulador)
3. Outros (Web, desktop): `http://localhost:8080/api`

| Onde o app roda | Como configurar |
|---|---|
| Emulador Android | Nada a fazer |
| Chrome (Flutter Web) | Nada a fazer |
| **Celular físico** (mesma rede Wi-Fi do PC) | `flutter run --dart-define=API_BASE_URL=http://<IP-do-PC>:8080/api` |
| Produção | `flutter build ... --dart-define=API_BASE_URL=https://seu-dominio/api` |

No **Android Studio**, o `--dart-define` vai em *Run → Edit Configurations… → Additional run args*.

### Android (`frontend/android/app/src/main/AndroidManifest.xml`)
- Permissão `INTERNET`.
- `android:usesCleartextTraffic="true"` libera HTTP sem TLS, necessário para `http://10.0.2.2`. Em produção, use HTTPS.
- `applicationId`: `com.comodeu.como_deu_app`.

### Dados salvos no aparelho
- `shared_preferences`: token (`auth_token`), nome (`auth_user_name`) e e-mail (`auth_user_email`) do usuário.
- SQLite `comodeu_offline.db` (só fora do navegador): cache das listas e fotos, e as pendências do modo offline (ver [seção 3](#modo-offline-android)).

O botão **Sair** apaga tudo isso. A sessão expirada apaga só o token e mantém as pendências.

### Dependências (`pubspec.yaml`)
Em uso: `http`, `shared_preferences`, `image_picker`, `sqflite` e `path` (modo offline). Declaradas mas **ainda não usadas** no código: `provider`, `image`, `flutter_svg`, `google_fonts`, `intl`, `uuid`.

---

## 10. Como rodar em desenvolvimento

### Pré-requisitos
- Java 25 (o Gradle Wrapper já vem no projeto)
- PostgreSQL 12+ rodando em `localhost:5432`
- Flutter 3 + Android Studio com um emulador configurado

### 1. Banco de dados (só na primeira vez)
```sql
CREATE DATABASE comodeu;
```
As tabelas e os 17 itens são criados automaticamente. O `backend/init-db.sql` é opcional.

### 2. Backend
```powershell
cd backend
./gradlew bootRun
```
Se o PostgreSQL não usar `postgres/postgres`, defina antes `$env:DB_USERNAME` e `$env:DB_PASSWORD`.

Verifique: <http://localhost:8080/api/swagger-ui.html>. Login de teste: `admin@comodeu.dev` / `admin123`.

### 3. App
**Android Studio:** abra a pasta `frontend`, selecione o emulador e clique em **Run ▶**.

**Terminal:**
```powershell
cd frontend
flutter pub get
flutter run
```

> 💡 Depois de alterar o código Flutter, use **Hot Restart** (⟳ no Android Studio, ou `R` no terminal). O Hot Reload (⚡ / `r`) às vezes mantém a versão antiga das telas.

---

## 11. Como rodar em produção

### Backend
```powershell
# Gerar uma chave JWT segura (uma vez) e guardar em local seguro
[Convert]::ToBase64String((1..48 | % { Get-Random -Max 256 }))

$env:SPRING_PROFILES_ACTIVE = "prod"
$env:DB_URL                 = "jdbc:postgresql://<host>:5432/comodeu"
$env:DB_USERNAME            = "<usuario>"
$env:DB_PASSWORD            = "<senha>"
$env:JWT_SECRET             = "<chave gerada acima>"
$env:CORS_ALLOWED_ORIGINS   = "https://<dominio-do-app-web>"   # só se houver versão web

cd backend
./gradlew bootJar
java -jar build/libs/como-deu-api-1.0.0.jar
```

### App
```powershell
cd frontend
flutter build apk --release --dart-define=API_BASE_URL=https://<dominio-da-api>/api
```

### Checklist
- [ ] `JWT_SECRET` próprio, diferente do valor do perfil dev
- [ ] API atrás de HTTPS e `usesCleartextTraffic` removido do Android
- [ ] Considerar `ddl-auto: validate` com migrações (ex.: Flyway)
- [ ] Configurar assinatura (signing) do APK/AAB para a Play Store

---

## 12. Solução de problemas

| Sintoma | Causa provável | Solução |
|---|---|---|
| Mudança no app não aparece (ex.: tela antiga) | Build antigo rodando no emulador | **Stop ■ → Run ▶** ou Hot Restart (⟳). Se persistir: `flutter clean`, `flutter pub get`, Run |
| App não conecta ("Não foi possível conectar com o servidor") | Backend parado ou URL errada | Confirme o backend em `:8080`. Em celular físico, use `--dart-define=API_BASE_URL` com o IP do PC |
| App volta sozinho para o Login | Token expirou (24 h) ou o usuário foi removido | Entrar de novo |
| Backend não sobe: `jwt.secret precisa ter pelo menos 32 bytes` | Chave curta ou ausente | Defina `JWT_SECRET` com 32 bytes ou mais |
| Backend não sobe: erro de conexão com o banco | PostgreSQL parado, banco inexistente ou senha errada | Inicie o PostgreSQL, rode `CREATE DATABASE comodeu;` e confira `DB_*` |
| `Port 8080 already in use` | Outra instância rodando | Feche a outra instância ou use `$env:PORT = "8081"` |
| Flutter Web: erro de CORS no navegador | Origem não liberada | Em dev, use `localhost`. Em prod, defina `CORS_ALLOWED_ORIGINS` |
| Classificação: nenhum item sugerido | A nota não tem as palavras-chave exatas | Escolha o item na lista "Todos os Itens COMO D'EU" |

---

## 13. Limitações conhecidas

- **Classificação exige conexão:** offline é possível registrar avaliações e evidências, mas não classificá-las.
- **Offline só fora do navegador:** no Flutter Web não há modo offline.
- **Sair apaga pendências:** o app avisa antes, mas itens não enviados são perdidos se o usuário confirmar.
- **Fotos em disco local:** a pasta de fotos precisa estar num disco persistente e no backup. Para vários servidores, o ideal seria um storage compartilhado (ex.: S3).
- **Marcação na foto:** `markX`/`markY` são coordenadas na tela de captura (área de 300 px de altura) e não são exibidas nas outras telas.
- **Avaliações não podem ser apagadas pelo app:** só pela API (`DELETE /evaluations/{id}`).
- **Sem testes automatizados** no backend e no frontend.
