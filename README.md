# 📍 Aplicação COMO D'EU
Solução tecnológica para avaliação de espaços culturais usando o instrumento COMO D'EU.

## Estrutura do Projeto

```
como-deu-app/
├── backend/          # API Spring Boot (Java 25 + Gradle)
│   ├── build.gradle
│   └── src/main/java/com/comodeu/
│       ├── controller/       # REST Controllers
│       ├── entity/           # JPA Entities
│       ├── repository/       # Data Access
│       ├── service/          # Business Logic
│       ├── dto/              # Data Transfer Objects
│       └── ComoDeUApiApplication.java
│
└── frontend/         # App Flutter/Dart
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart
    │   ├── models/          # Data Models
    │   ├── screens/         # UI Screens
    │   ├── services/        # API Service
    │   └── widgets/         # Reusable Components
    └── test/

```

---

## 🚀 Backend - Spring Boot

### Pré-requisitos
- Java 25+
- Gradle 8+
- PostgreSQL 12+

### Instalação

1. **Entrar no diretório backend**
   ```bash
   cd backend
   ```

2. **Configurar banco de dados**
   ```sql
   CREATE DATABASE como_deu;
   ```

3. **Editar `application.yml`**
   - Ajuste as credenciais do PostgreSQL se necessário
   - Mude `spring.jpa.hibernate.ddl-auto` para `create` na primeira execução

4. **Compilar e rodar**
   ```bash
   ./gradlew build
   ./gradlew bootRun
   ```

   Ou com Gradle instalado:
   ```bash
   gradle bootRun
   ```

5. **API estará disponível em:**
   - http://localhost:8080/api
   - Documentação automática: http://localhost:8080/api/como-items/initialize

### Endpoints Principais

#### Evaluations
- `POST /evaluations` - Criar nova avaliação
- `GET /evaluations` - Listar todas
- `GET /evaluations/{id}` - Obter uma específica
- `PUT /evaluations/{id}/complete` - Marcar como completa

#### Evidence
- `POST /evidences` - Registrar evidência
- `GET /evidences/evaluation/{evaluationId}` - Listar por avaliação
- `PUT /evidences/{id}/classify` - Marcar como classificada

#### COMO Items
- `GET /como-items` - Listar todos os 17 itens
- `POST /como-items/suggest` - Sugerir itens por keywords
- `POST /como-items/initialize` - Inicializar dados

#### Classifications
- `POST /classifications` - Criar classificação
- `GET /classifications/evidence/{evidenceId}` - Listar por evidência

---

## 📱 Frontend - Flutter/Dart

### Pré-requisitos
- Flutter 3.0+
- Dart 3.0+
- Android Studio / Xcode (para emulador)
- VS Code ou Android Studio

### Instalação

1. **Entrar no diretório frontend**
   ```bash
   cd frontend
   ```

2. **Instalar dependências**
   ```bash
   flutter pub get
   ```

3. **Verificar dispositivos**
   ```bash
   flutter devices
   ```

4. **Rodar a aplicação**
   ```bash
   flutter run
   ```

   Ou em um emulador específico:
   ```bash
   flutter run -d emulator-5554
   ```

### Estrutura das Screens

1. **HomeScreen** - Lista avaliações e botão para nova
2. **EvaluationFormScreen** - Formulário de dados da visita
3. **CaptureScreen** - Captura foto, marca elemento e registra nota rápida
4. **GalleryScreen** - Grid com miniaturas das evidências
5. **ClassificationScreen** - Classifica evidência com sugestões automáticas

---

## 🔄 Fluxo de Uso

### Durante a Visita (Fase Rápida - ~15 seg por item)
1. Abrir app na tela "Registrar Evidência"
2. Tirar foto do elemento problemático
3. Marcar a localização na foto com um toque
4. Escrever nota rápida (ex: "letra pequena")
5. Clicar "Registrar" e continuar visitando

### Após a Visita (Fase Análise - ~2 min por item)
1. Ir para aba "Galeria"
2. Clicar em uma evidência para detalhe
3. App mostra:
   - Foto com marca
   - Nota original
   - 2-3 itens COMO D'EU sugeridos (selecionados por padrão)
4. Aluno pode:
   - Confirmar seleção ou adicionar/remover itens
   - Escrever análise pessoal detalhada
5. Clicar "Salvar Classificação"

---

## 📊 Dados dos 17 Itens COMO D'EU

### Categoria 1: Acessibilidade & Conforto
1. Acessibilidade Física
2. Conforto Térmico
3. Conforto Acústico
4. Qualidade da Iluminação
5. Mobiliário Apropriado

### Categoria 2: Informação & Comunicação
6. Sinalização Clara
7. Informações Legíveis
8. Acesso à Informação
9. Comodidades Gerais

### Categoria 3: Experiência & Engajamento
10. Clareza Expositiva
11. Engajamento do Visitante
12. Diversidade de Conteúdo

### Categoria 4: Segurança & Recursos
13. Segurança e Privacidade
14. Gestão do Tempo
15. Qualidade do Atendimento
16. Recursos Educacionais
17. Impressão Geral / Satisfação

---

## 🔌 Integração API ↔ App

### Fluxo de Dados

1. **App cria Avaliação** → Backend salva em PostgreSQL
2. **App captura Foto** → Base64 enviado ao Backend
3. **App registra Evidência** → Backend armazena foto + marca + nota
4. **App pede Sugestões** → Backend analisa keywords e retorna top 3
5. **App classifica** → Backend cria registro de classificação

### Persistência
- **Backend**: PostgreSQL (produção)
- **App**: SQLite local + sincronização quando conectado

---

## 🛠️ Customizações

### Alterar URL da API
**Em `frontend/lib/services/api_service.dart`:**
```dart
static const String baseUrl = 'http://192.168.1.100:8080/api';
```

### Adicionar Autenticação
1. Implementar JWT no Backend
2. Armazenar token em SharedPreferences no App
3. Adicionar token aos headers da API

### Suportar Cloud Storage
1. Integrar AWS S3 ou Firebase Storage
2. Armazenar apenas URL no BD (não base64)

---

## 📋 Checklist de Deployment

### Backend
- [ ] Mude `ddl-auto` para `validate` em produção
- [ ] Crie migration scripts com Flyway
- [ ] Configure HTTPS
- [ ] Ajuste JWT secret em produção
- [ ] Defina limites de upload (max-file-size)

### App
- [ ] Change `baseUrl` para produção
- [ ] Configure signing para release
- [ ] Teste em múltiplos devices
- [ ] Configure App Signing no Google Play

---

## 🐛 Troubleshooting

### Backend não conecta ao banco
```
Error: could not connect to database
```
**Solução:** Verifique se PostgreSQL está rodando e credenciais em `application.yml`

### App não conecta à API
```
SocketException: Failed to connect
```
**Solução:** 
- Verifique se Backend está rodando
- Teste URL em postman/curl
- Confirme firewall não bloqueia porta 8080

### Fotos não salva
```
Exception during binary read
```
**Solução:** Verifique permissões de câmera no App

---

## 📝 Próximos Passos

1. Implementar autenticação de usuários
2. Adicionar offline-sync automática
3. Criar dashboard com relatórios
4. Integrar com Google/Facebook login
5. Publicar na App Store e Play Store

---

## 👨‍💻 Desenvolvido por
Vinícius Vieira Carneiro
Extensão V - UECE

---

## 📜 Licença
MIT License
