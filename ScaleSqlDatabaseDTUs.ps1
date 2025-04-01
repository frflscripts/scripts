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
    200 { "S4" }
    10 { "S0" }
    default { throw "Unsupported DTU value: $targetDTUs. Supported values are 10 and 200." }
}

Write-Output "Scaling database '$databaseName' in server '$serverName' to service objective '$serviceObjective'..."

az sql db update `
    --resource-group $resourceGroup `
    --server $serverName `
    --name $databaseName `
    --edition Standard `
    --service-objective $serviceObjective | Out-Null

Write-Output "Scaling operation completed successfully."
