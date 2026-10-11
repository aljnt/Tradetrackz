# 🚀 Tradetackz (TradeVision)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.2.3-6DB33F?logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-17-ED8B00?logo=openjdk&logoColor=white)](https://www.oracle.com/java/)
[![Security](https://img.shields.io/badge/JWT-Spring_Security-red?logo=jsonwebtokens&logoColor=white)](https://jwt.io/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Tradetackz** est une application moderne et performante de trading multi-actifs et d'analyse financière en temps réel. Elle combine un frontend multiplateforme développé en **Flutter** avec un backend sécurisé en **Spring Boot 3**.

---

## 📑 Sommaire

- [Aperçu de l'Application](#-aperçu-de-lapplication)
- [Fonctionnalités Principales](#-fonctionnalités-principales)
- [Architecture & Conception](#-architecture--conception)
  - [Architecture Globale](#architecture-globale)
  - [Architecture Frontend (Flutter & BLoC)](#architecture-frontend-flutter--bloc)
  - [Architecture Backend (Spring Boot 3)](#architecture-backend-spring-boot-3)
  - [Gestion des Flux et Optimisation API](#gestion-des-flux-et-optimisation-api)
- [Structure du Projet](#-structure-du-projet)
- [Stack Technique](#-stack-technique)
- [Installation & Démarrage](#-installation--démarrage)
  - [Prérequis](#prérequis)
  - [1. Configuration & Lancement du Backend](#1-configuration--lancement-du-backend)
  - [2. Configuration & Lancement du Frontend](#2-configuration--lancement-du-frontend)
- [Endpoints API (Backend)](#-endpoints-api-backend)
- [Variables d'Environnement](#-variables-denvironnement)
- [Contribuer](#-contribuer)
- [Auteur](#-auteur)

---

## 🌟 Aperçu de l'Application

Tradetackz a été conçu pour offrir aux traders et investisseurs une expérience fluide, réactive et intuitive avec des outils d'analyse technique professionnels :

- **Visualisation dynamique** : Graphiques en chandeliers japonais (candlesticks) interactifs avec timeframes et outils de tracé technique intégrés.
- **Trading simulé avec levier** : Gestion de marge, positions Long/Short, calcul de Stop-Loss et Take-Profit en direct.
- **Portefeuille en direct** : Suivi de la balance, de l'equity, de la marge utilisée et des performances non réalisées.
- **Données multi-marchés** : Suivi des marchés Forex, Matières Premières (Gold/XAUUSD), Indices, Actions et Crypto-monnaies.

---

## ✨ Fonctionnalités Principales

### 📈 Analyse Graphique & Marchés
- **Chandeliers japonais interactifs** avec calcul dynamique des échelles de prix et de temps.
- **Timeframes multiples** : `1m`, `5m`, `15m`, `1H`, `4H`, `1D`, `1W`.
- **Périodes d'analyse** : `1D`, `5D`, `1M`, `3M`, `6M`, `YTD`, `1Y`, `5Y`, `ALL`.
- **Outils de tracé technique** : Ajout de lignes de tendance, niveaux de supports/résistances sur les graphiques.
- **Curseur Crosshair & Inspection** : Visualisation précise des données OHLC (Open, High, Low, Close) et volume par bougie.

### 💼 Trading & Gestion du Portefeuille
- **Prise de position** : Ordres d'achat (**Long**) et de vente (**Short**).
- **Effet de levier paramétrable** : Ajustement dynamique du levier pour simuler des scénarios à marge.
- **Protection du capital** : Définition des niveaux de **Stop-Loss (SL)** et de **Take-Profit (TP)**.
- **Calcul du P&L en direct** : Suivi temps réel des gains/pertes latents et des pourcentages de rendement.
- **Wallet interactif** : Opérations de dépôt et retrait simulées.

### 🔐 Sécurité & Authentification
- Système d'inscription et de connexion complet.
- Mots de passe chiffrés par **BCrypt**.
- Authentification stateless par **Tokens JWT (JSON Web Tokens)**.
- Persistance sécurisée de la session sur l'appareil.

---

## 🏗 Architecture & Conception

Le projet repose sur les principes de la **Clean Architecture** afin de garantir une séparation stricte des responsabilités, une testabilité accrue et une grande évolutivité.

### Architecture Globale

```
+-----------------------------------------------------------+
|                     TRADETACKZ                            |
+-----------------------------+-----------------------------+
                              |
       +----------------------+----------------------+
       |                                             |
+------v---------------------+                +------v---------------------+
|      FLUTTER FRONTEND      |                |    SPRING BOOT BACKEND     |
| (BLoC / UI / Data Sources) |                | (REST API / JWT / JPA)     |
+--------------+-------------+                +--------------+-------------+
               |                                             |
   HTTP / Data Sources (TwelveData,             Spring Security / Filter
        Finnhub, Alpha Vantage)                              |
               |                                  H2 / PostgreSQL DB
               v                                             v
  [Flux de Marché Temps Réel]                     [Utilisateurs & Sécurité]
```

### Architecture Frontend (Flutter & BLoC)

Le frontend suit le pattern **BLoC (Business Logic Component)** pour découpler l'interface graphique de la logique métier :

1. **Presentation Layer** :
   - Écrans (`LoginScreen`, `RegisterScreen`, `DashboardScreen`, `TradePage`, `DepositPage`, etc.).
   - Widgets réutilisables et CustomPainters pour le rendu graphique des chandeliers.
   - Thème dark moderne (`AppTheme`) avec charte graphique premium.
2. **BLoC Layer** :
   - `AuthBloc` : Gestion des états de connexion, d'inscription et de vérification de session.
   - `MarketDataBloc` : Orchestration des flux de cotations, calculs de positions ouvertes et gestion des historiques.
3. **Data Layer** :
   - `Datasources` : Appels HTTP REST vers le backend d'authentification et vers les APIs de données financières.
   - `Repositories` : Abstraction et gestion des sources de données locales (`SharedPreferences`) et distantes.
   - `Models` : Objets typés (`AssetItem`, `Candle`, `Quote`, `TradePosition`, `UserModel`).

### Architecture Backend (Spring Boot 3)

Le backend est architecturé en couches indépendantes :

- **Controller** : Endpoints REST (`/api/v1/auth/**`) gérant la validation des requêtes entrantes.
- **Security & JWT** :
  - `SecurityConfig` : Configuration de la chaîne de filtres Spring Security 6 (CORS, CSRF, gestion stateless).
  - `JwtFilter` : Intercepteur de requêtes extrayant et validant le token Bearer.
  - `JwtUtil` : Génération et vérification cryptographique des signatures JWT.
- **Service** : Logique métier d'authentification, de gestion de compte et d'encodage de mot de passe.
- **Repository** : Couche d'accès aux données avec Spring Data JPA.
- **Model** : Entité `User` persistée en base de données relationnelle.

### Gestion des Flux et Optimisation API

Afin d'éviter le dépassement des quotas des fournisseurs de données financières (rate limits) :
- **Système de Cache Mémoire** : Mise en cache locale des bougies et cotations avec expiration paramétrée.
- **Polling & StreamController Broadcast** : Diffusion unifiée des prix en temps réel vers tous les composants abonnés sans requêtes redondantes.
- **Multi-Providers Fallback** : Support de **TwelveData**, **Finnhub** et **Alpha Vantage** avec bascule intelligente.

---

## 📁 Structure du Projet

```text
Tradetackz/
├── .gitignore                      # Fichier d'exclusion Git global (Java, Flutter, IDEs, etc.)
├── README.md                       # Documentation du projet
│
├── backend/                        # Backend Spring Boot 3 (Java 17)
│   ├── pom.xml                     # Dépendances Maven (Spring Data JPA, Security, JWT, Lombok)
│   └── src/
│       ├── main/
│       │   ├── java/com/tradingapp/
│       │   │   ├── config/         # Configuration Spring Security
│       │   │   ├── controller/     # Contrôleurs REST (Auth)
│       │   │   ├── dto/            # Data Transfer Objects (Login, Register, Tokens)
│       │   │   ├── exception/      # Gestionnaire d'erreurs global
│       │   │   ├── model/          # Entités JPA (User)
│       │   │   ├── repository/     # Repositories JPA
│       │   │   ├── security/       # JWT Filter & JWT Utility
│       │   │   ├── service/        # Services métier (AuthService, UserDetails)
│       │   │   └── TradingAppApplication.java
│       │   └── resources/
│       │       └── application.yml # Configuration H2 / PostgreSQL / JWT
│       └── test/                   # Tests unitaires et d'intégration
│
└── frontend/                       # Application Flutter (Multiplateforme)
    ├── pubspec.yaml                # Dépendances Flutter (flutter_bloc, fl_chart, etc.)
    ├── .env.example                # Exemple de configuration des clés API financières
    └── lib/
        ├── main.dart               # Point d'entrée de l'application
        ├── core/
        │   ├── constants/          # Constantes & URLs d'API
        │   └── theme/              # Thème UI sombre et styles graphiques
        ├── data/
        │   ├── datasources/        # Services distants (MarketDataService, AuthRemote)
        │   ├── models/             # Modèles de données (Candle, Quote, TradePosition...)
        │   └── repositories/       # Implémentation des repositories
        ├── presentation/
        │   ├── blocs/              # BLoCs (AuthBloc, MarketDataBloc)
        │   └── screens/            # Vues (Login, Register, Dashboard, TradePage, Wallet)
        └── settings/               # Écran de configuration des clés API
```

---

## 💻 Stack Technique

### Frontend
- **Framework** : [Flutter](https://flutter.dev/) (SDK ^3.12.x)
- **Langage** : [Dart](https://dart.dev/)
- **State Management** : `flutter_bloc` & `equatable`
- **Rendu Graphique** : Custom Canvas Painters & `fl_chart`
- **Réseau & WebSocket** : `http`, `web_socket_channel`
- **Stockage Local** : `shared_preferences`
- **Design & Typographie** : `google_fonts`, `cupertino_icons`

### Backend
- **Framework** : [Spring Boot 3.2.3](https://spring.io/)
- **Langage** : [Java 17](https://www.oracle.com/java/)
- **Sécurité** : Spring Security 6 & JJWT (io.jsonwebtoken 0.12.5)
- **Persistance** : Spring Data JPA, Hibernate
- **Bases de données** : H2 Database (environnement de dev) / PostgreSQL (production)
- **Productivité** : Project Lombok

---

## 🛠 Installation & Démarrage

### Prérequis

Assurez-vous d'avoir installé sur votre machine :
- [Git](https://git-scm.com/)
- [Java JDK 17+](https://adoptium.net/)
- [Maven](https://maven.apache.org/) (ou utiliser le wrapper Maven)
- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install)

---

### 1. Configuration & Lancement du Backend

1. **Naviguer dans le dossier backend** :
   ```bash
   cd backend
   ```

2. **Compiler et exécuter l'application** :
   ```bash
   mvn spring-boot:run
   ```

3. Le serveur démarre sur :
   - API : `http://localhost:8080`
   - Console H2 : `http://localhost:8080/h2-console` *(identifiant: `sa`, mot de passe vide)*

---

### 2. Configuration & Lancement du Frontend

1. **Naviguer dans le dossier frontend** :
   ```bash
   cd ../frontend
   ```

2. **Installer les dépendances Flutter** :
   ```bash
   flutter pub get
   ```

3. **(Optionnel) Configurer les clés d'API financières** :
   Dupliquez le fichier `.env.example` en `.env` et ajoutez vos clés gratuites :
   ```bash
   cp .env.example .env
   ```
   *(Vous pouvez également saisir vos clés directement dans l'application via la page des Paramètres API).*

4. **Lancer l'application** :
   ```bash
   # Sur Chrome (Web)
   flutter run -d chrome

   # Sur Windows (Desktop)
   flutter run -d windows

   # Sur un émulateur ou appareil connecté
   flutter run
   ```

---

## 📡 Endpoints API (Backend)

| Méthode | Route | Description | Authentification requise |
| :--- | :--- | :--- | :---: |
| `POST` | `/api/v1/auth/register` | Inscription d'un nouvel utilisateur | Non |
| `POST` | `/api/v1/auth/login` | Authentification & délivrance du Token JWT | Non |

### Exemple de requête de connexion :
```json
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!"
}
```

### Réponse attendue :
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "trader01"
  }
}
```

---

## 🔑 Variables d'Environnement

Pour exploiter les données de marché en temps réel :

| Fournisseur | Clé | Usage | Inscription |
| :--- | :--- | :--- | :--- |
| **TwelveData** | `TWELVEDATA_API_KEY` | Forex, Gold (XAUUSD), Indices, Crypto | [twelvedata.com](https://twelvedata.com) |
| **Finnhub** | `FINNHUB_API_KEY` | Indices US (SPX, NDX, DJI), Actions | [finnhub.io](https://finnhub.io) |
| **Alpha Vantage** | `ALPHAVANTAGE_API_KEY` | Données Forex & Historique | [alphavantage.co](https://www.alphavantage.co) |

---

## 🤝 Contribuer

Les contributions, suggestions et signalements de bugs sont les bienvenus !
1. Forkez le projet.
2. Créez votre branche de fonctionnalité (`git checkout -b feature/AmazingFeature`).
3. Committez vos modifications (`git commit -m 'feat: Add AmazingFeature'`).
4. Poussez sur votre branche (`git push origin feature/AmazingFeature`).
5. Ouvrez une Pull Request.

---

## 👤 Auteur

- Projet conçu et développé par **alaej**
- Dépôt officiel : [Tradetackz](https://github.com/)
