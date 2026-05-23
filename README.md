# MesclaInvest – Projeto Integrador III

## 👥 Integrantes

* Alice Da Silva Beserra
* Antonio Airton Rodrigues Junior
* Beatriz Costa Leme
* Nathalia Alves Dias Alecio

---

## 📌 Descrição

Repositório destinado ao desenvolvimento do **Projeto Integrador III** da disciplina de Engenharia de Software da **PUC Campinas**.

O projeto consiste no desenvolvimento do **MesclaInvest**, uma plataforma mobile que simula investimento em startups por meio da negociação de tokens.

---

## 📊 Base de Dados Simulada

Foi criada uma planilha contendo **5 startups fictícias**, utilizadas no catálogo do aplicativo.

Arquivo:

```
/data/startups_simuladas.xlsx
```

---

## 🧠 Mapa Mental do Sistema

O mapa mental foi elaborado para organizar os módulos principais do sistema e o fluxo do usuário.

Arquivo:

```
/docs/mapa_mental_mesclainvest.png
```

---

## 🛠 Organização do Projeto

* Versionamento do código com **Git**
* Repositório hospedado no **GitHub**
* Gerenciamento de tarefas utilizando **GitHub Projects**
* Organização das atividades através de **Issues**

---

## ✏️ Protótipo do Projeto
```
https://www.figma.com/make/4V1c4zootORBRlYjwKvvAf/Investment-App-Design?p=f&t=J78XCA0yhjMj7pRS-0&fullscreen=1
```


## wireframe visual

<img width="1485" height="852" alt="image" src="https://github.com/user-attachments/assets/4c2f1cea-36f2-441f-a89f-2ca5bd501c96" />

---

## ✅ Evidencias de Organizacao Tecnica

- Repositorio versionado com Git e hospedado no GitHub.
- Branches e commits registrados durante o desenvolvimento.
- Acompanhamento de tarefas via GitHub Projects e Issues.
- Documentacao atualizada neste README.

---

## ▶️ Como Executar o Projeto

1) Instale o Flutter e configure o ambiente.
2) No diretório do projeto, instale dependencias:

```
flutter pub get
```

3) Rode o app:

```
flutter run
```

Opcional: sobrescreva a URL das Functions (Cloud Run v2) com `--dart-define`:

```
flutter run -d chrome --dart-define=FUNCTIONS_BASE_URL=https://api-hsr6pxtqoq-uc.a.run.app
```

---

## 🧪 Como Executar os Testes

O projeto conta com uma suíte de testes de integração no backend para validar as regras de negócio de compra, venda e saldo da carteira (TDD).

**Pré-requisitos:**
* Ter o Node.js instalado.
* Ter o Java (JRE) instalado.
* Instalar o Firebase CLI globalmente:
  ```bash
  npm install -g firebase-tools
  ```

Para rodar os testes localmente, necessita de dois terminais:

**Terminal 1:**
1) Na raiz do projeto, inicie o emulador do Firestore:
   ```bash
   firebase emulators:start --only firestore
   ```

**Terminal 2:**
1) Acesse o diretório das Cloud Functions:
   ```bash
   cd functions
   ```
2) Instale as dependências do Node (caso não tenha):
   ```bash
   npm install
   ```
3) Execute a suíte de testes:
   ```bash
   npm test
   ```

---

## 🔥 Firebase

O projeto utiliza Firebase para autenticacao e dados das startups.
Certifique-se de configurar o arquivo `google-services.json` (Android)
ou `GoogleService-Info.plist` (iOS), alem do `firebase_options.dart`.

