param(
  [string]$TargetInstanceId,
  [int]$LocalPort = 6443,
  [int]$RemotePort = 6443,
  [string]$Profile,
  [string]$Region
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-CommandExists {
  param([Parameter(Mandatory = $true)][string]$Name)

  return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

if (-not (Test-CommandExists -Name "aws")) {
  throw "AWS CLI no esta instalado o no esta en PATH."
}

if ([string]::IsNullOrWhiteSpace($TargetInstanceId)) {
  if (-not (Test-CommandExists -Name "terraform")) {
    throw "No se recibio TargetInstanceId y Terraform no esta disponible para leer outputs."
  }

  try {
    $TargetInstanceId = (terraform output -raw master_primary_instance_id 2>$null).Trim()
  }
  catch {
    throw "No fue posible leer master_primary_instance_id desde Terraform. Ejecuta terraform apply o pasa -TargetInstanceId."
  }
}

if ([string]::IsNullOrWhiteSpace($TargetInstanceId)) {
  throw "TargetInstanceId vacio. Pasa -TargetInstanceId o verifica el output master_primary_instance_id."
}

$ssmParameters = @{
  portNumber      = @("$RemotePort")
  localPortNumber = @("$LocalPort")
} | ConvertTo-Json -Compress

Write-Host "Iniciando tunel SSM..." -ForegroundColor Cyan
Write-Host "Instancia: $TargetInstanceId" -ForegroundColor Cyan
Write-Host "Localhost:$LocalPort -> Remoto:$RemotePort" -ForegroundColor Cyan

$awsArgs = @(
  "ssm", "start-session",
  "--target", $TargetInstanceId,
  "--document-name", "AWS-StartPortForwardingSession",
  "--parameters", $ssmParameters
)

if (-not [string]::IsNullOrWhiteSpace($Profile)) {
  $awsArgs += @("--profile", $Profile)
}

if (-not [string]::IsNullOrWhiteSpace($Region)) {
  $awsArgs += @("--region", $Region)
}

& aws @awsArgs
