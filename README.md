# ☁️ Azure – Architecture Web Haute Disponibilité (HA) + Load Balancer + Supervision + Budget
Déploiement complet d’une architecture Web haute disponibilité sur Azure (Load Balancer, Availability Set, VMs, supervision, alertes et budget) via un script PowerShell automatisé, reproductible et documenté. Région : France Central.  

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
