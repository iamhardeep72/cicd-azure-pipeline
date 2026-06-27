#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  Azure Infrastructure Setup Script
#  Run this ONCE to create all Azure resources the pipeline needs
#  Run in: Azure Cloud Shell → https://shell.azure.com
# ═══════════════════════════════════════════════════════════════════

set -e

# ── CONFIGURATION (change these) ────────────────────────────────
RESOURCE_GROUP="cicd-demo-rg"
LOCATION="eastus"
ACR_NAME="securecorpacr"                    # must be globally unique, no dashes
CONTAINER_APP_ENV="cicd-demo-env"
CONTAINER_APP_NAME="cicd-demo-app"
# ────────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   CI/CD Demo — Azure Infrastructure Setup           ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── STEP 1: Resource Group ───────────────────────────────────────
echo "▶ [1/6] Creating Resource Group..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table

# ── STEP 2: Azure Container Registry (ACR) ──────────────────────
echo ""
echo "▶ [2/6] Creating Azure Container Registry: $ACR_NAME..."
az acr create \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --sku Basic \
  --admin-enabled true \
  --output table

# ── STEP 3: Get ACR credentials (for GitHub Secrets) ────────────
echo ""
echo "▶ [3/6] Getting ACR credentials..."
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" -o tsv)
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query "loginServer" -o tsv)

echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│  Add these to GitHub → Settings → Secrets           │"
echo "├─────────────────────────────────────────────────────┤"
echo "│  ACR_USERNAME  = $ACR_USERNAME"
echo "│  ACR_PASSWORD  = $ACR_PASSWORD"
echo "│  (AZURE_CREDENTIALS — generated in step 5)"
echo "└─────────────────────────────────────────────────────┘"

# ── STEP 4: Container Apps Environment ──────────────────────────
echo ""
echo "▶ [4/6] Creating Container Apps Environment..."
az containerapp env create \
  --name "$CONTAINER_APP_ENV" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table

# ── STEP 5: Container App (first deploy — placeholder image) ────
echo ""
echo "▶ [5/6] Creating Container App: $CONTAINER_APP_NAME..."
az containerapp create \
  --name "$CONTAINER_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$CONTAINER_APP_ENV" \
  --image "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
  --target-port 80 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 3 \
  --cpu 0.25 \
  --memory 0.5Gi \
  --output table

# ── STEP 6: Service Principal for GitHub Actions ─────────────────
echo ""
echo "▶ [6/6] Creating Service Principal for GitHub Actions..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

SP_JSON=$(az ad sp create-for-rbac \
  --name "cicd-demo-github-actions" \
  --role contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --sdk-auth)

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅  SETUP COMPLETE — Add these to GitHub Secrets        ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo ""
echo "  Secret name: AZURE_CREDENTIALS"
echo "  Secret value (copy the entire JSON below):"
echo ""
echo "$SP_JSON"
echo ""
echo "  Secret name: ACR_USERNAME"
echo "  Secret value: $ACR_USERNAME"
echo ""
echo "  Secret name: ACR_PASSWORD"
echo "  Secret value: $ACR_PASSWORD"
echo ""
echo "╠══════════════════════════════════════════════════════════╣"
echo ""

# Print the app URL
APP_URL=$(az containerapp show \
  --name "$CONTAINER_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv)

echo "  Your app URL: https://$APP_URL"
echo "  (will show your site after first GitHub Actions run)"
echo ""
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Next: Push code to GitHub → pipeline runs automatically!"
