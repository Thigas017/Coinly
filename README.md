# Coinly

![Kotlin](https://img.shields.io/badge/Kotlin-0095D5?style=for-the-badge&logo=kotlin&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-F2F4F9?style=for-the-badge&logo=spring-boot)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![C++](https://img.shields.io/badge/C++-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)

**Coinly** is an offline-first, AI-powered mobile application designed for numismatists to manage their coin collections. 

## Goal
Built to showcase a complete software engineering lifecycle, featuring **Edge AI TensorFlow Lite**, a custom **C++ dynamic grading algorithm** via Dart FFI, and a robust **Kotlin Spring Boot backend** with automated CI/CD pipelines.

## Key Features
- **AI Coin Recognition:** Identifies the coin offline (Country, Year, Motif).
- **Dynamic Grading (C++):** Analyzes coin luster via video frames to estimate its grade (e.g., UNC, XF).
- **Anomaly Detection:** Spots known minting errors automatically.
- **Offline-First Vault:** Works seamlessly without internet, syncing in the background when online.
- **Portfolio Tracker:** Tracks market value evolution using automated backend web scraping cron jobs.