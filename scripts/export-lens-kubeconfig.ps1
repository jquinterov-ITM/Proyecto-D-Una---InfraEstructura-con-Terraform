param(
  [string]$TargetInstanceId,
  [string]$OutputPath = "$HOME/.kube/k3s-duna-lens.yaml",
  [int]$LocalPort = 6443,
  [string]$Profile,
  [string]$Region,
  [int]$TimeoutSeconds = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-CommandExists {
  param([Parameter(Mandatory = $true)][string]$Name)
  return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Invoke-AwsCli {
  param([Parameter(Mandatory = $true)][string[]]$Args)

  $finalArgs = @()
  $finalArgs += $Args

  if (-not [string]::IsNullOrWhiteSpace($Profile)) {
    $finalArgs += @("--profile", $Profile)
  }

  if (-not [string]::IsNullOrWhiteSpace($Region)) {
    $finalArgs += @("--region", $Region)
  }

  return (& aws @finalArgs)
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
    throw "No fue posible leer master_primary_instance_id desde Terraform. Ejecuta terraform apply o usa -TargetInstanceId."
  }
}

if ([string]::IsNullOrWhiteSpace($TargetInstanceId)) {
  throw "TargetInstanceId vacio. Usa -TargetInstanceId o verifica el output master_primary_instance_id."
}

$commandsParam = @{ commands = @("sudo cat /etc/rancher/k3s/k3s.yaml") } | ConvertTo-Json -Compress

$sendArgs = @(
  "ssm", "send-command",
  "--instance-ids", $TargetInstanceId,
  "--document-name", "AWS-RunShellScript",
  "--comment", "Export K3s kubeconfig for Lens",
  "--parameters", $commandsParam,
  "--query", "Command.CommandId",
  "--output", "text"
)

$commandId = (Invoke-AwsCli -Args $sendArgs).Trim()
if ([string]::IsNullOrWhiteSpace($commandId)) {
  throw "No se obtuvo CommandId de SSM send-command."
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$status = "Pending"

while ((Get-Date) -lt $deadline) {
  $statusArgs = @(
    "ssm", "get-command-invocation",
    "--command-id", $commandId,
    "--instance-id", $TargetInstanceId,
    "--query", "Status",
    "--output", "text"
  )

  try {
    $status = (Invoke-AwsCli -Args $statusArgs).Trim()
  }
  catch {
    $status = "Pending"
  }

  if ($status -in @("Success", "Cancelled", "TimedOut", "Failed", "Cancelling")) {
    break
  }

  Start-Sleep -Seconds 2
}

if ($status -ne "Success") {
  throw "SSM no completo con exito. Estado final: $status"
}

$outputArgs = @(
  "ssm", "get-command-invocation",
  "--command-id", $commandId,
  "--instance-id", $TargetInstanceId,
  "--query", "StandardOutputContent",
  "--output", "text"
)

$kubeConfig = Invoke-AwsCli -Args $outputArgs
if ([string]::IsNullOrWhiteSpace($kubeConfig)) {
  throw "El contenido del kubeconfig llego vacio."
}

$patchedConfig = [regex]::Replace(
  $kubeConfig,
  "(?m)^\s*server:\s*https://.*$",
  "    server: https://127.0.0.1:$LocalPort"
)

$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
  New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Set-Content -Path $OutputPath -Value $patchedConfig -Encoding utf8

Write-Host "Kubeconfig exportado para Lens." -ForegroundColor Green
Write-Host "Archivo: $OutputPath" -ForegroundColor Green
Write-Host "Server configurado: https://127.0.0.1:$LocalPort" -ForegroundColor Green
Write-Host "" 
Write-Host "Siguiente paso:" -ForegroundColor Cyan
Write-Host ".\\scripts\\start-lens-ssm-tunnel.ps1 -TargetInstanceId $TargetInstanceId -LocalPort $LocalPort" -ForegroundColor Cyan
