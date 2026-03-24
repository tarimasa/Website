<#
.SYNOPSIS
    Microsoft Graph API + Azure ARM API を使用して
    Static Web Apps の Managed Identity に RBAC ロールを割り当てる

.DESCRIPTION
    1. Azure にログイン
    2. Microsoft Graph API で Managed Identity の Service Principal を取得
    3. Azure ARM API で Storage Blob Data Reader ロールを割り当て
    4. Blob Storage ネットワーク設定を更新

.NOTES
    前提条件:
    - Az PowerShell モジュール: Install-Module Az
    - Phase 1 で Blob Storage 作成済み
    - Phase 3 で Static Web Apps 作成済み（Managed Identity 有効）
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$StaticWebAppName,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory = $false)]
    [string]$StorageResourceGroupName = $ResourceGroupName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Phase 4: RBAC セットアップ（Graph API + ARM API）" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# -------------------------------------------------------
# 1. Azure ログイン確認
# -------------------------------------------------------
Write-Host "`n[1/5] Azure ログイン確認..." -ForegroundColor Yellow

try {
    $context = Get-AzContext
    if (-not $context) { throw "ログインが必要です" }
    Write-Host "  サブスクリプション : $($context.Subscription.Name)" -ForegroundColor Green
    Write-Host "  テナント ID        : $($context.Tenant.Id)" -ForegroundColor Green
}
catch {
    Write-Host "  Azure にログインします..." -ForegroundColor Yellow
    Connect-AzAccount
    $context = Get-AzContext
}

$subscriptionId = $context.Subscription.Id

# -------------------------------------------------------
# 2. Microsoft Graph API: Managed Identity の Service Principal を取得
# -------------------------------------------------------
Write-Host "`n[2/5] Microsoft Graph API で Managed Identity を検索..." -ForegroundColor Yellow

# Graph API 用アクセストークン取得
$graphToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token

$graphHeaders = @{
    "Authorization" = "Bearer $graphToken"
    "Content-Type"  = "application/json"
}

# Static Web Apps の Managed Identity (Service Principal) を名前で検索
$encodedName = [System.Uri]::EscapeDataString($StaticWebAppName)
$graphUri = "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=displayName eq '$encodedName'&`$select=id,displayName,servicePrincipalType"

Write-Host "  Graph API エンドポイント: $graphUri" -ForegroundColor Gray

$response = Invoke-RestMethod -Uri $graphUri -Headers $graphHeaders -Method GET
$servicePrincipals = $response.value | Where-Object { $_.servicePrincipalType -eq "ManagedIdentity" }

if ($servicePrincipals.Count -eq 0) {
    # Azure Resource から Managed Identity の Principal ID を直接取得（フォールバック）
    Write-Host "  Graph API でSPが見つかりません。Azure ARM から直接取得します..." -ForegroundColor Yellow
    $staticWebApp = Get-AzStaticWebApp -ResourceGroupName $ResourceGroupName -Name $StaticWebAppName
    $managedIdentityPrincipalId = $staticWebApp.IdentityPrincipalId

    if (-not $managedIdentityPrincipalId) {
        Write-Error "Static Web Apps '$StaticWebAppName' に Managed Identity が設定されていません。"
        exit 1
    }
    Write-Host "  ARM API から取得した Principal ID: $managedIdentityPrincipalId" -ForegroundColor Green
}
else {
    $managedIdentityPrincipalId = $servicePrincipals[0].id
    Write-Host "  Graph API で SP を発見:" -ForegroundColor Green
    Write-Host "    表示名    : $($servicePrincipals[0].displayName)" -ForegroundColor Green
    Write-Host "    Object ID : $managedIdentityPrincipalId" -ForegroundColor Green
}

# -------------------------------------------------------
# 3. Graph API: Service Principal の詳細情報を確認
# -------------------------------------------------------
Write-Host "`n[3/5] Graph API で Service Principal の詳細を確認..." -ForegroundColor Yellow

$spDetailUri = "https://graph.microsoft.com/v1.0/servicePrincipals/$managedIdentityPrincipalId"
$spDetail = Invoke-RestMethod -Uri $spDetailUri -Headers $graphHeaders -Method GET

Write-Host "  SP 詳細:" -ForegroundColor Green
Write-Host "    ID                  : $($spDetail.id)" -ForegroundColor Green
Write-Host "    displayName         : $($spDetail.displayName)" -ForegroundColor Green
Write-Host "    servicePrincipalType: $($spDetail.servicePrincipalType)" -ForegroundColor Green

# -------------------------------------------------------
# 4. Azure ARM API: Storage Blob Data Reader ロール割り当て
# -------------------------------------------------------
Write-Host "`n[4/5] Azure ARM API で Storage Blob Data Reader ロールを割り当て..." -ForegroundColor Yellow

# Storage Blob Data Reader ロール定義 ID（組み込みロール）
$storageBlobDataReaderRoleId = "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"

# Blob Storage のリソース ID を取得
$storageAccount = Get-AzStorageAccount -ResourceGroupName $StorageResourceGroupName -Name $StorageAccountName
$storageAccountId = $storageAccount.Id

Write-Host "  Blob Storage ID: $storageAccountId" -ForegroundColor Gray

# 既存のロール割り当てを確認
$existingRoleAssignment = Get-AzRoleAssignment `
    -ObjectId $managedIdentityPrincipalId `
    -RoleDefinitionId $storageBlobDataReaderRoleId `
    -Scope $storageAccountId `
    -ErrorAction SilentlyContinue

if ($existingRoleAssignment) {
    Write-Host "  ロール割り当ては既に存在します（スキップ）" -ForegroundColor Yellow
}
else {
    # ARM REST API でロール割り当て（Graph API との組み合わせデモ）
    $armToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token
    $armHeaders = @{
        "Authorization" = "Bearer $armToken"
        "Content-Type"  = "application/json"
    }

    $roleAssignmentId = [System.Guid]::NewGuid().ToString()
    $roleAssignmentUri = "https://management.azure.com${storageAccountId}/providers/Microsoft.Authorization/roleAssignments/${roleAssignmentId}?api-version=2022-04-01"

    $roleAssignmentBody = @{
        properties = @{
            roleDefinitionId = "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/$storageBlobDataReaderRoleId"
            principalId      = $managedIdentityPrincipalId
            principalType    = "ServicePrincipal"
            description      = "Portfolio: Static Web Apps MI -> Storage Blob Data Reader"
        }
    } | ConvertTo-Json

    Write-Host "  ARM API エンドポイント: $roleAssignmentUri" -ForegroundColor Gray
    $result = Invoke-RestMethod -Uri $roleAssignmentUri -Headers $armHeaders -Method PUT -Body $roleAssignmentBody
    Write-Host "  ロール割り当て完了: $($result.id)" -ForegroundColor Green
}

# -------------------------------------------------------
# 5. Blob Storage ネットワーク設定の確認
# -------------------------------------------------------
Write-Host "`n[5/5] Blob Storage ネットワーク設定を確認..." -ForegroundColor Yellow

$storageNetworkRules = $storageAccount.NetworkRuleSet
Write-Host "  デフォルトアクション : $($storageNetworkRules.DefaultAction)" -ForegroundColor Green
Write-Host "  バイパス設定         : $($storageNetworkRules.Bypass)" -ForegroundColor Green

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host " Phase 4 完了！" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "設定されたRBAC:"
Write-Host "  Principal: $managedIdentityPrincipalId (Managed Identity)"
Write-Host "  Role     : Storage Blob Data Reader"
Write-Host "  Scope    : $storageAccountId"
Write-Host ""
Write-Host "次のステップ:"
Write-Host "  1. カスタムドメインを Cloudflare DNS で設定"
Write-Host "  2. ブログ記事 (MDX) を src/posts/ に追加"
Write-Host "  3. GitHub に push してデプロイ確認"
