# 📍 Aplicação COMO D'EU
Solução tecnológica para avaliação de espaços culturais usando o instrumento COMO D'EU.

📘 **Documentação completa (app, API e configurações):** [docs/DOCUMENTACAO.md](docs/DOCUMENTACAO.md)

---

## O que o app faz

O avaliador visita um espaço cultural (museu, galeria, teatro, biblioteca) e:

1. **Durante a visita:** fotografa um ponto do espaço, marca o elemento na foto com um toque e escreve uma nota rápida (ex.: "letra pequena").
2. **Depois da visita:** abre cada evidência e a classifica em um ou mais dos **17 itens COMO D'EU**, escrevendo uma análise pessoal. O app sugere itens a partir das palavras da nota, mas todos os 17 ficam disponíveis para escolha.

O acesso exige conta (cadastro e login com e-mail e senha), e cada usuário vê apenas as próprias avaliações. No Android, o registro funciona **sem internet**: avaliações e evidências ficam guardadas no aparelho e são enviadas quando a conexão voltar.

## Tecnologias

| Parte | Tecnologia |
|---|---|
| `backend/` | API REST em Spring Boot 3.5 (Java 25, Gradle), Spring Security + JWT, Swagger |
| `frontend/` | App Flutter/Dart (Android e Web) |
| Banco | PostgreSQL (tabelas criadas automaticamente) |

## Estrutura do Projeto

```
como-deu-app/
├── backend/                 # API Spring Boot
│   ├── build.gradle
│   ├── init-db.sql          # opcional: cria banco e tabelas manualmente
│   └── src/main/
│       ├── java/com/comodeu/
│       │   ├── config/      # segurança, CORS, Swagger, admin de dev
│       │   ├── controller/  # endpoints REST
│       │   ├── dto/         # objetos de entrada/saída
│       │   ├── entity/      # entidades JPA
│       │   ├── repository/  # acesso a dados
│       │   ├── security/    # JWT
│       │   └── service/     # regras de negócio e sugestão de itens
│       └── resources/       # application.yml, -dev.yml, -prod.yml
├── frontend/                # App Flutter
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── models/          # Evaluation, Evidence, ComoItem
│       ├── screens/         # telas
│       └── services/        # api_service.dart (HTTP + sessão)
└── docs/
    └── DOCUMENTACAO.md      # documentação completa
```

---

## 🚀 Como rodar (desenvolvimento)

### Pré-requisitos
- Java 25 (o Gradle Wrapper já está no projeto)
- PostgreSQL 12+ em `localhost:5432` (usuário/senha padrão: `postgres`/`postgres`)
- Flutter 3 e Android Studio com um emulador

### 1. Criar o banco (só na primeira vez)
```sql
CREATE DATABASE comodeu;
```
As tabelas e os 17 itens COMO D'EU são criados automaticamente quando o backend sobe.

### 2. Backend
```powershell
cd backend
./gradlew bootRun
```
- API: <http://localhost:8080/api>
- Swagger: <http://localhost:8080/api/swagger-ui.html>
- Usuário de teste criado automaticamente: `admin@comodeu.dev` / `admin123`

Se o seu PostgreSQL usar outro usuário ou senha, defina `$env:DB_USERNAME` e `$env:DB_PASSWORD` antes de rodar.

### 3. App
No **Android Studio**: abra a pasta `frontend`, selecione o emulador e clique em **Run ▶**.

Ou pelo terminal:
```powershell
cd frontend
flutter pub get
flutter run
```

A URL da API é escolhida automaticamente: `10.0.2.2:8080` no emulador Android e `localhost:8080` no Chrome. Em um **celular físico**, informe o IP do PC:
```powershell
flutter run --dart-define=API_BASE_URL=http://<IP-do-PC>:8080/api
```

> 💡 Depois de alterar o código do app, use **Hot Restart** (⟳ / `R`). O Hot Reload (⚡ / `r`) às vezes mantém a versão antiga das telas.

---

## ⚙️ Perfis de configuração

| Perfil | Como ativar | Observações |
|---|---|---|
| `dev` | padrão | PostgreSQL local, Swagger liberado, admin de teste criado |
| `prod` | `$env:SPRING_PROFILES_ACTIVE = "prod"` | Exige `DB_PASSWORD` e `JWT_SECRET`. Swagger desligado |

Em produção, defina as variáveis de ambiente antes de subir:
```powershell
$env:SPRING_PROFILES_ACTIVE = "prod"
$env:DB_PASSWORD = "sua-senha-do-postgres"
$env:JWT_SECRET  = "<segredo base64 com 32+ bytes>"
$env:PHOTOS_DIR  = "D:\comodeu\fotos"   # pasta persistente para as fotos (incluir no backup)
# opcionais: DB_URL (padrão jdbc:postgresql://localhost:5432/comodeu),
#            DB_USERNAME (padrão postgres), CORS_ALLOWED_ORIGINS, SWAGGER_ENABLED, PORT
```
Sem `DB_PASSWORD` ou `JWT_SECRET`, a aplicação não sobe. A lista completa de propriedades e variáveis está na [documentação](docs/DOCUMENTACAO.md#8-configuração-do-backend).

---

## 🔌 Endpoints principais

Todos sob `http://localhost:8080/api`. Exceto cadastro e login, todos exigem `Authorization: Bearer <token>`.

| Recurso | Endpoints |
|---|---|
| Autenticação | `POST /auth/register`, `POST /auth/login`, `GET /auth/me` |
| Avaliações | `POST/GET /evaluations`, `GET /evaluations/{id}`, `PUT /evaluations/{id}/complete` |
| Evidências | `POST /evidences` (multipart, com o arquivo `photo`), `GET /evidences/evaluation/{evaluationId}`, `GET /evidences/{id}/photo`, `DELETE /evidences/{id}` |
| Classificações | `GET/PUT /evidences/{id}/classifications` (salvar substitui a anterior, sem duplicar) |
| Itens COMO D'EU | `GET /como-items`, `POST /como-items/suggest` |

As fotos ficam em arquivos na pasta `PHOTOS_DIR` (padrão `backend/uploads/photos`), não no banco.

Lista completa: [documentação, seção 7](docs/DOCUMENTACAO.md#7-api-rest) ou o Swagger.

---

## 📊 Os 17 itens COMO D'EU

| Categoria | Itens |
|---|---|
| Acessibilidade & Conforto | 1. Acessibilidade Física · 2. Conforto Térmico · 3. Conforto Acústico · 4. Qualidade da Iluminação · 5. Mobiliário Apropriado |
| Informação & Comunicação | 6. Sinalização Clara · 7. Informações Legíveis · 8. Acesso à Informação · 9. Comodidades Gerais |
| Experiência & Engajamento | 10. Clareza Expositiva · 11. Engajamento do Visitante · 12. Diversidade de Conteúdo |
| Segurança & Recursos | 13. Segurança e Privacidade · 14. Gestão do Tempo · 15. Qualidade do Atendimento · 16. Recursos Educacionais · 17. Impressão Geral / Satisfação |

---

## 🐛 Problemas comuns

| Sintoma | Solução |
|---|---|
| Mudança no app não aparece | Stop ■ → Run ▶ no Android Studio (ou `flutter clean` e rodar de novo) |
| App não conecta à API | Confirme que o backend está em `:8080`. Em celular físico, use `--dart-define=API_BASE_URL` |
| Backend não conecta ao banco | Verifique se o PostgreSQL está rodando, se o banco `comodeu` existe e as variáveis `DB_*` |
| App volta para o login | O token expirou (24 h): entre novamente |

Mais casos na [documentação](docs/DOCUMENTACAO.md#12-solução-de-problemas).

---

## 📝 Próximos Passos

1. Classificar evidências também sem conexão
2. Testes automatizados (backend e app)
3. Relatórios e exportação em PDF
4. Publicar na Play Store

---

## 👨‍💻 Desenvolvido por
Vinícius Vieira Carneiro
Extensão V - UECE

---

## 📜 Licença
MIT License
