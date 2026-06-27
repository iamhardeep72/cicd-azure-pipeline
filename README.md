# CI/CD Pipeline — Static Site → Docker → Azure Container Apps

## What This Project Does

Every time you push code to the `main` branch, this pipeline automatically:

```
You push code
     ↓
GitHub Actions triggers
     ↓
✅ Validate (check files, lint Dockerfile)
     ↓
🐳 Build Docker image (nginx serving your HTML)
     ↓
📦 Push image to Azure Container Registry (ACR)
     ↓
🚀 Deploy to Azure Container Apps (live URL, auto-scaled)
     ↓
🌐 Your site is live in ~2 minutes
```

---

## Project Structure

```
cicd-project/
├── app/
│   └── index.html                    ← Your website
├── docker/
│   └── nginx.conf                    ← nginx web server config
├── .github/
│   └── workflows/
│       ├── deploy.yml                ← Main CI/CD pipeline
│       └── pr-check.yml              ← PR validation (no deploy)
├── Dockerfile                        ← Container definition
├── setup-azure.sh                    ← One-time Azure setup
└── README.md
```

---

## Step-by-Step Setup

### Step 1 — Create a GitHub Repository

```bash
# On your machine
git init
git add .
git commit -m "initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/cicd-demo.git
git push -u origin main
```

> ⚠️ Don't push yet — set up Azure first (Step 2), then push to trigger the pipeline.

---

### Step 2 — Set Up Azure Resources

Open **Azure Cloud Shell** → https://shell.azure.com

```bash
# Upload setup-azure.sh using the Upload button in Cloud Shell, then:
chmod +x setup-azure.sh
./setup-azure.sh
```

This script creates:
- Resource Group
- Azure Container Registry (ACR)
- Container Apps Environment
- Container App
- Service Principal (for GitHub Actions to authenticate)

It will print out 3 secrets at the end — copy them.

---

### Step 3 — Add GitHub Secrets

Go to your GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**

Add these 3 secrets:

| Secret Name | Where to get it |
|---|---|
| `AZURE_CREDENTIALS` | JSON printed by setup script |
| `ACR_USERNAME` | Printed by setup script |
| `ACR_PASSWORD` | Printed by setup script |

---

### Step 4 — Update Workflow Variables

Edit `.github/workflows/deploy.yml` and update the `env:` section:

```yaml
env:
  ACR_NAME: YOUR_ACR_NAME           # what you set in setup-azure.sh
  ACR_LOGIN_SERVER: YOUR_ACR_NAME.azurecr.io
  RESOURCE_GROUP: cicd-demo-rg
  CONTAINER_APP_NAME: cicd-demo-app
  CONTAINER_APP_ENV: cicd-demo-env
```

---

### Step 5 — Push Code → Pipeline Runs

```bash
git add .
git commit -m "setup CI/CD pipeline"
git push origin main
```

Go to GitHub → **Actions tab** — you'll see the pipeline running live.

---

## Pipeline Jobs Explained

### Job 1: validate
- Checks all required files exist
- Lints the Dockerfile for best practices
- Runs on every push AND pull request

### Job 2: build
- Logs into Azure Container Registry
- Builds the Docker image
- Tags it with the git commit SHA (unique per commit)
- Pushes to ACR
- Skipped on pull requests (just validates, doesn't push)

### Job 3: deploy
- Logs into Azure with the service principal
- Deploys the new image to Azure Container Apps
- Only runs on pushes to `main` (not PRs)
- Prints the live URL

### Job 4: notify
- Always runs (even if other jobs fail)
- Prints a summary: which jobs passed/failed

---

## PR Flow (Safe Testing)

When you open a Pull Request:
1. `pr-check.yml` runs — builds Docker image locally to verify it works
2. Runs a health check on the container
3. Does NOT deploy to Azure
4. You can safely test changes without affecting production

When PR is merged to `main`:
1. `deploy.yml` runs the full pipeline
2. Deploys to production automatically

---

## How to Update Your Site

```bash
# Edit your HTML
nano app/index.html

# Commit and push
git add app/index.html
git commit -m "update homepage"
git push origin main

# GitHub Actions automatically:
# → builds new Docker image
# → pushes to ACR
# → deploys to Azure Container Apps
# → your site is updated in ~2 minutes
```

---

## Costs

| Resource | Tier | Cost |
|---|---|---|
| Azure Container Registry | Basic | ~$5/month |
| Azure Container Apps | Consumption | ~$0 (free 180,000 vCPU-seconds/month) |
| **Total** | | **~$5/month** |

Delete everything when done:
```bash
az group delete --name cicd-demo-rg --yes
```

---

## What to Say in Your Interview

> *"I built a full CI/CD pipeline using GitHub Actions that automatically builds a Docker container from a static website, pushes it to Azure Container Registry, and deploys it to Azure Container Apps on every git push to main. The pipeline has 4 jobs — validate, build, deploy, and notify — with PR checks that test without deploying to production. I used a service principal with contributor scope for GitHub Actions to authenticate to Azure."*

---

## Resume Bullet Points

- Designed and implemented a 4-stage CI/CD pipeline using GitHub Actions (validate → build → deploy → notify)
- Containerized a static web application using Docker and nginx:alpine
- Set up Azure Container Registry (ACR) for storing versioned Docker images tagged by git commit SHA
- Deployed to Azure Container Apps with auto-scaling (1–3 replicas)
- Configured branch protection: PR checks run without deployment; main branch triggers full deploy
- Used Azure Service Principal with scoped RBAC for secure GitHub Actions authentication
