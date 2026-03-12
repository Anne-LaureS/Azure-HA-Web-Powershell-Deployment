# ============================
# Cloud Azure - Script complet PowerShell
# Région : France Central / VM : B1s / Disque : StandardSSD
# ============================

# Renseigner le mot de passe Admin et le nom de l'utilisateur
# Renseigner l'adresse mail de service => VARIABLES ALERTES / BUDGET 

# ---------- Variables globales ----------
$rgName    = "rg-tp-loadbalancer"
$location  = "francecentral"
$vmSize    = "Standard_B2ats_v2"
$vmName1   = "vm1"
$vmName2   = "vm2"
$avsetName = "avset-web"
$adminUser = "azureuser"   # <-- À RENSEIGNER
$adminPassword = ConvertTo-SecureString "P@ssw0rd1234!" -AsPlainText -Force   # <-- À RENSEIGNER
$cred = New-Object System.Management.Automation.PSCredential($adminUser, $adminPassword)

# Récupération des ressources existantes
$vnet = Get-AzVirtualNetwork -Name "tp-vnet" -ResourceGroupName $rgName
$subnet = Get-AzVirtualNetworkSubnetConfig -Name "subnet-default" -VirtualNetwork $vnet
$nsg = Get-AzNetworkSecurityGroup -Name "tp-nsg" -ResourceGroupName $rgName
$lb  = Get-AzLoadBalancer -Name "tp-loadbalancer" -ResourceGroupName $rgName
$backendPool = $lb.BackendAddressPools[0]

# Availability Set
$avset = New-AzAvailabilitySet -Location $location -Name $avsetName `
    -ResourceGroupName $rgName -Sku aligned -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2

# NICs
$nic1 = New-AzNetworkInterface -Name "nic-$vmName1" -ResourceGroupName $rgName `
    -Location $location -Subnet $subnet -NetworkSecurityGroup $nsg `
    -LoadBalancerBackendAddressPool $backendPool

$nic2 = New-AzNetworkInterface -Name "nic-$vmName2" -ResourceGroupName $rgName `
    -Location $location -Subnet $subnet -NetworkSecurityGroup $nsg `
    -LoadBalancerBackendAddressPool $backendPool

# cloud-init
$cloudInit1 = @"
#cloud-config
package_update: true
packages:
  - nginx
runcmd:
  - echo '<h1>VM Web 01 - TP Load Balancer</h1>' > /var/www/html/index.nginx-debian.html
"@

$cloudInit2 = @"
#cloud-config
package_update: true
packages:
  - nginx
runcmd:
  - echo '<h1>VM Web 02 - TP Load Balancer</h1>' > /var/www/html/index.nginx-debian.html
"@

# VM1
$vm1 = New-AzVMConfig -VMName $vmName1 -VMSize $vmSize -AvailabilitySetId $avset.Id |
    Set-AzVMOperatingSystem -Linux -ComputerName $vmName1 -Credential $cred -DisablePasswordAuthentication:$false |
    Set-AzVMSourceImage -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts" -Version "latest" |
    Add-AzVMNetworkInterface -Id $nic1.Id

$vm1.UserData = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($cloudInit1))

New-AzVM -ResourceGroupName $rgName -Location $location -VM $vm1

# VM2
$vm2 = New-AzVMConfig -VMName $vmName2 -VMSize $vmSize -AvailabilitySetId $avset.Id |
    Set-AzVMOperatingSystem -Linux -ComputerName $vmName2 -Credential $cred -DisablePasswordAuthentication:$false |
    Set-AzVMSourceImage -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts" -Version "latest" |
    Add-AzVMNetworkInterface -Id $nic2.Id

$vm2.UserData = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($cloudInit2))

New-AzVM -ResourceGroupName $rgName -Location $location -VM $vm2

============================================================================================
# ---------- VARIABLES ALERTES / BUDGET ----------
$alertEmail        = "Totovapecher@ocean.fr"   # <-- À RENSEIGNER
$actionGroupName   = "ag-tp-loadbalancer"
$actionGroupShort  = "ag-tp"
$budgetName        = "budget-tp-loadbalancer"
$budgetAmount      = 10                        # 10 € / mois

# ---------- 7. Action Group pour alertes ----------
Write-Host "Création de l'Action Group pour les alertes..." -ForegroundColor Cyan

$actionGroup = Set-AzActionGroup `
    -Name $actionGroupName `
    -ShortName $actionGroupShort `
    -ResourceGroupName $rgName `
    -Location $location `
    -EmailReceiver @(@{ Name = "mail-rec"; EmailAddress = $alertEmail })

Write-Host "Action Group créé : $actionGroupName" -ForegroundColor Green

# ---------- 8. Alertes métriques (CPU + PowerState) ----------
Write-Host "Création des alertes métriques..." -ForegroundColor Cyan

$vm1Id = (Get-AzVM -Name $vmName1 -ResourceGroupName $rgName).Id

# Alerte CPU élevée sur VM1
Add-AzMetricAlertRule `
    -Name "alert-cpu-$vmName1" `
    -Location $location `
    -ResourceGroup $rgName `
    -TargetResourceId $vm1Id `
    -MetricName "Percentage CPU" `
    -Operator GreaterThan `
    -Threshold 80 `
    -WindowSize "00:05:00" `
    -TimeAggregationOperator Average `
    -ActionGroupId $actionGroup.Id | Out-Null

# Alerte arrêt VM1 (PowerState = 0)
Add-AzMetricAlertRule `
    -Name "alert-powerstate-$vmName1" `
    -Location $location `
    -ResourceGroup $rgName `
    -TargetResourceId $vm1Id `
    -MetricName "Power state" `
    -Operator LessThan `
    -Threshold 1 `
    -WindowSize "00:05:00" `
    -TimeAggregationOperator Average `
    -ActionGroupId $actionGroup.Id | Out-Null

Write-Host "Alertes CPU et PowerState créées pour $vmName1." -ForegroundColor Green

# ---------- 9. Budget Cost Management ----------
Write-Host "Création du budget de coût..." -ForegroundColor Cyan

$timeGrain = "Monthly"
$startDate = (Get-Date -Day 1).Date
$endDate   = $startDate.AddYears(1)

$notification = New-Object -TypeName Microsoft.Azure.Commands.Consumption.Models.PSNotification
$notification.Enabled        = $true
$notification.Operator       = "GreaterThan"
$notification.Threshold      = 80
$notification.ContactEmails  = @($alertEmail)

New-AzConsumptionBudget -Name $budgetName `
    -Amount $budgetAmount `
    -Category Cost `
    -TimeGrain $timeGrain `
    -StartDate $startDate `
    -EndDate $endDate `
    -NotificationKey "Alert80" `
    -Notification $notification `
    -Scope "/subscriptions/$subscriptionId" | Out-Null

Write-Host "Budget créé pour $budgetAmount EUR / mois avec alerte à 80%." -ForegroundColor Green
