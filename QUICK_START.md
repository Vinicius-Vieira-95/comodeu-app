# 🚀 Quick Start - COMO D'EU App

## 1️⃣ Preparar Backend (Java + PostgreSQL)

### Pré-requisitos
```bash
# Verificar Java 25
java -version

# Verificar PostgreSQL
psql --version

# Se não tiver Gradle, ele será baixado automaticamente
```

### Iniciar Backend (5 minutos)

```bash
cd backend

# 1. Criar banco de dados
createdb como_deu

# 2. (Opcional) Executar script SQL
psql -U postgres -d como_deu -f init-db.sql

# 3. Rodar aplicação
./gradlew bootRun
```

✅ **Backend rodando em:** http://localhost:8080/api

---

## 2️⃣ Preparar Frontend (Flutter + Dart)

### Pré-requisitos
```bash
# Verificar Flutter
flutter --version

# Verificar Dart
dart --version

# Listar emuladores disponíveis
flutter emulators
```

### Iniciar Frontend (5 minutos)

```bash
cd frontend

# 1. Baixar dependências
flutter pub get

# 2. Rodar aplicação
flutter run

# Ou, se tiver múltiplos emuladores:
flutter run -d emulator-5554
```

✅ **App rodando no emulador**

---

## 3️⃣ Testar Fluxo Completo

### No App
1. **Home** → Clique em "Nova Avaliação"
2. **Formulário** → Preencha:
   - Seu Nome: "João Silva"
   - Espaço: "Museu de Arte Moderna"
   - Tipo: "Museu"
3. **Captura** → 
   - Clique na câmera
   - Marque um ponto na foto
   - Digite: "letra pequena"
   - Clique "Registrar"
4. **Galeria** → 
   - Veja a thumbnail
   - Clique para detalhe
5. **Classificação** →
   - App sugere itens automaticamente
   - Escreva análise: "Fonte menor que 16pt viola WCAG AA"
   - Clique "Salvar"

✅ **Dado salvo no Backend!**

---

## 🔍 Verificar Dados no Backend

### Ver evidências no BD
```bash
# Conectar ao PostgreSQL
psql -U postgres -d como_deu

# Ver avaliações
SELECT * FROM evaluations;

# Ver evidências
SELECT id, evaluation_id, quick_note FROM evidences;

# Ver classificações
SELECT COUNT(*) FROM classifications;
```

### Ver via API (Postman/curl)
```bash
# Listar todas avaliações
curl http://localhost:8080/api/evaluations

# Listar itens COMO D'EU
curl http://localhost:8080/api/como-items

# Sugerir itens por nota
curl -X POST http://localhost:8080/api/como-items/suggest \
  -H "Content-Type: application/json" \
  -d '{"quickNote":"letra pequena"}'
```

---

## ❌ Problemas Comuns

### Backend
```
Error: could not connect to database
→ createdb como_deu
→ psql -U postgres -d como_deu -f init-db.sql

Error: Port 8080 already in use
→ kill -9 $(lsof -t -i:8080)
```

### Frontend
```
Error: Failed to connect to localhost:8080
→ Verifique se Backend está rodando
→ flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8080/api

Error: Camera permission denied
→ Settings > Permissions > Camera > Allow
```

---

## 📁 Estrutura do Projeto

```
├── README.md                  ← Documentação completa
├── QUICK_START.md            ← Este arquivo
├── backend/
│   ├── build.gradle          ← Dependências Java
│   ├── init-db.sql           ← Script SQL inicial
│   └── src/main/java/...     ← Código Java
├── frontend/
│   ├── pubspec.yaml          ← Dependências Dart
│   ├── lib/main.dart         ← Entrada do app
│   └── lib/screens/...       ← Telas Flutter
```

---

## 📊 Próximas Melhorias

- [ ] Adicionar login de usuários
- [ ] Sincronizar dados offline
- [ ] Dashboard com gráficos
- [ ] Exportar relatório em PDF
- [ ] Publicar na App Store
- [ ] Publicar na Play Store

---

## 💡 Tips

- **Desenvolvimento rápido**: Use `flutter run -v` para debug
- **Hot reload**: Pressione `r` para recarregar app
- **Hot restart**: Pressione `R` para restart completo
- **DevTools**: Execute `flutter pub global activate devtools` + `devtools`

---

## ❓ Dúvidas?

Veja `README.md` para documentação completa ou abra uma issue.

**Bom desenvolvimento! 🚀**
