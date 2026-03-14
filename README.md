# ☁️ Azure – Architecture Web Haute Disponibilité (HA) + Load Balancer + Supervision + Budget
Déploiement complet d’une architecture Web haute disponibilité sur Azure (Load Balancer, Availability Set, VMs, supervision, alertes et budget) via un script PowerShell automatisé, reproductible et documenté. Région : France Central.  

![Azure](https://img.shields.io/badge/Azure-0089D6?logo=microsoft-azure&logoColor=white)
![High Availability](https://img.shields.io/badge/High%20Availability-HA-blue)
![Load Balancer](https://img.shields.io/badge/Azure%20Load%20Balancer-4C8BF5?logo=microsoft-azure&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?logo=powershell&logoColor=white)
![Azure Monitor](https://img.shields.io/badge/Azure%20Monitor-5C2D91?logo=microsoft-azure&logoColor=white)

Ce projet automatise la création d’un environnement complet incluant :

- Load Balancer Public
- Availability Set
- 2 Machines Virtuelles Ubuntu (Nginx)
- NSG + VNet + Subnet existants
- Alertes (CPU + PowerState)
- Action Group (email)
- Budget Cost Management
- Cloud‑init pour configuration automatique
- Région : France Central

---

## 📦 Prérequis

Avant d’exécuter le script :

```powershell
Install-Module Az -Scope CurrentUser
Connect-AzAccount
# Renseigner l'adresse mail de service => VARIABLES ALERTES / BUDGET
# L’ID de subscription si nécessaire
```

---

## 📁 Structure du projet

```
.
├── deploy-ha-web.ps1
└── README.md
```

---

## 🚀 Déploiement

Exécuter simplement :

```powershell
.\scripts\deploy-ha-web.ps1
```

Le script réalise automatiquement :

1. Récupération des ressources existantes (VNet, Subnet, NSG, Load Balancer)
2. Création de l’Availability Set
3. Création des NICs et rattachement au Backend Pool
4. Déploiement des 2 VMs Ubuntu avec cloud‑init (Nginx)
5. Configuration des alertes (CPU + PowerState)
6. Création du Budget mensuel avec alerte à 80%

---

## 🏗️ Architecture déployée

```
                Internet
                    │
            ┌────────────────┐
            │ Load Balancer  │
            └────────────────┘
              │            │
        ┌─────────┐   ┌─────────┐
        │  VM1    │   │  VM2    │
        │ Nginx   │   │ Nginx   │
        └─────────┘   └─────────┘
              \        /
           Availability Set
```

---

## 📡 Supervision & Alertes

Le script configure automatiquement :

- Alerte CPU > 80% (VM1)
- Alerte PowerState (VM arrêtée)
- Action Group avec envoi email
- Budget mensuel (10 €) avec alerte à 80%

---

## 🧹 Nettoyage

Pour supprimer l’environnement :

```powershell
Remove-AzResourceGroup -Name rg-tp-loadbalancer -Force -AsJob
```
