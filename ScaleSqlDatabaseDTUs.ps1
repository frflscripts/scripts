# This script needs to be placed here for the runbook to access it: https://github.com/frflscripts/scripts/tree/main
# This is workaround until Azure Automation supports bicep modules that can be uploaded with the runbook or accessed via a private storage account.

param (
    [Parameter(Mandatory = $true)]
    [string]$assistEnvironment,

    [Parameter(Mandatory = $true)]
    [int]$targetDTUs,

    [Parameter(Mandatory = $true)]
    [string]$subscriptionId
)



Write-Output "Authenticating with Managed Identity that is built into the Automation Account..."
az login --identity | Out-Null

if ($subscriptionId) {
    Write-Output "Setting Azure subscription context to $subscriptionId..."
    az account set --subscription $subscriptionId
}

# Set variables
$resourceGroup = "rg-frfl-assist-$assistEnvironment"
$serverName = "sql-frfl-assist-$assistEnvironment"
$databaseName = "sqldb-frfl-assist-$assistEnvironment"

# Map DTUs to Service Objective
$serviceObjective = switch ($targetDTUs) {
    5 { "Basic" }
    10 { "S0" }
    20 { "S1" }
    50 { "S2" }
    100 { "S3" }
    200 { "S4" }
    400 { "S6" }
    800 { "S7" }
    1600 { "S9" }
    3000 { "S12" }
    default { throw "Unsupported DTU value: $targetDTUs." }
}

Write-Output "Scaling database '$databaseName' in server '$serverName' to service objective '$serviceObjective'..."

az sql db update `
    --resource-group $resourceGroup `
    --server $serverName `
    --name $databaseName `
    --edition Standard `
    --service-objective $serviceObjective | Out-Null

Write-Output "Scaling operation completed successfully."