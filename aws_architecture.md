# GojoCalories — AWS Architecture & Account Migration Guide

> **Purpose**: This document describes every AWS service used by the GojoCalories backend, where each service is configured in the codebase, and exactly what to change when migrating to a new AWS account.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [AWS Services Inventory](#2-aws-services-inventory)
3. [Current Account-Specific Values](#3-current-account-specific-values)
4. [Configuration Files Map](#4-configuration-files-map)
5. [Step-by-Step Migration Guide](#5-step-by-step-migration-guide)
6. [Post-Migration Checklist](#6-post-migration-checklist)

---

## 1. Architecture Overview

```
  Flutter App (iOS/Android)
        │
        │ HTTPS → api.gojocalories.com (DNS → Route 53 / Cloudflare)
        ▼
  ┌─────────────────────────────────────────────────────────────┐
  │                  AWS Account: 353284254035                   │
  │                  Region: us-east-1                           │
  │                                                             │
  │  ┌──────────────────────────────────────────────────────┐  │
  │  │            VPC (auto-created by Copilot)             │  │
  │  │                                                      │  │
  │  │   ┌──────────────────────────────────────────────┐  │  │
  │  │   │  Application Load Balancer (ALB)             │  │  │
  │  │   │  DNS: gojoca-Publi-2bRSRsFxYTTs-             │  │  │
  │  │   │       1943547672.us-east-1.elb.amazonaws.com │  │  │
  │  │   └────────────────────┬─────────────────────────┘  │  │
  │  │                        │                             │  │
  │  │   ┌────────────────────▼─────────────────────────┐  │  │
  │  │   │  ECS Cluster (Fargate)                       │  │  │
  │  │   │  App: gojocalories / Service: api            │  │  │
  │  │   │  Env: prod                                   │  │  │
  │  │   │                                              │  │  │
  │  │   │  FastAPI Container (port 5000)               │  │  │
  │  │   │    CPU: 256 units  Memory: 512 MiB           │  │  │
  │  │   │    Count: 1 task                             │  │  │
  │  │   └──────┬──────────────────────────────┬────────┘  │  │
  │  │          │                              │            │  │
  │  └──────────┼──────────────────────────────┼────────────┘  │
  │             │                              │               │
  │  ┌──────────▼──────────┐   ┌──────────────▼─────────────┐ │
  │  │   Amazon ECR         │   │  AWS SSM Parameter Store   │ │
  │  │   (Container Repo)   │   │  /copilot/gojocalories/    │ │
  │  │   gojocalories/api   │   │  prod/secrets/*            │ │
  │  └─────────────────────┘   └────────────────────────────┘ │
  │                                                             │
  │  ┌──────────────────────┐   ┌────────────────────────────┐ │
  │  │   Amazon S3           │   │  AWS SES                   │ │
  │  │   Bucket:             │   │  Sender: noreply@          │ │
  │  │   gojo-media-uploads  │   │  gojocalories.com          │ │
  │  │   (private, presigned)│   │  Region: us-east-1         │ │
  │  └──────────────────────┘   └────────────────────────────┘ │
  │                                                             │
  └─────────────────────────────────────────────────────────────┘
```

**External dependencies** (not AWS, no migration required):
- **Stripe** — Payments & subscriptions (webhook endpoint on the ECS service)
- **Google Gemini AI** — Food vision analysis
- **PostgreSQL** — Hosted externally (DATABASE_URL stored in SSM)
- **Redis** — Hosted externally (REDIS_URL env var)
- **Cloudflare** — DNS proxy for `api.gojocalories.com` and `pay.gojocalories.com`

---

## 2. AWS Services Inventory

### 2.1 Amazon ECS on Fargate (via AWS Copilot)

| Property | Value |
|---|---|
| **Copilot Application** | `gojocalories` |
| **Service Name** | `api` |
| **Service Type** | Load Balanced Web Service |
| **Environment** | `prod` |
| **Container Port** | `5000` |
| **CPU** | 256 units |
| **Memory** | 512 MiB |
| **Task Count** | 1 |
| **Orchestration Tool** | AWS Copilot CLI |
| **Config file** | [`copilot/api/manifest.yml`](file:///home/zelghourfi/Documents/gojocalories/copilot/api/manifest.yml) |

The ECS service runs the FastAPI backend containerized via Docker. The container image is built from [`backend/Dockerfile`](file:///home/zelghourfi/Documents/gojocalories/backend/Dockerfile) (Python 3.10-slim, uvicorn on port 5000).

### 2.2 Amazon ECR (Elastic Container Registry)

Copilot automatically creates and manages an ECR repository named `gojocalories/api` in the account. Each `copilot deploy` builds the Docker image, pushes it to ECR, and updates the ECS task definition.

### 2.3 Application Load Balancer (ALB)

| Property | Value |
|---|---|
| **Auto-generated DNS** | `gojoca-Publi-2bRSRsFxYTTs-1943547672.us-east-1.elb.amazonaws.com` |
| **Custom Domain** | `api.gojocalories.com` (points to ALB via Cloudflare/Route 53) |
| **Health check path** | `/` (default) |
| **Listener** | Port 80 (HTTP), forwarded to ECS tasks on port 5000 |

Used in: [`backend/test_aws_endpoints.py`](file:///home/zelghourfi/Documents/gojocalories/backend/test_aws_endpoints.py) (line 5)

### 2.4 AWS SSM Parameter Store

All production secrets are stored as SecureString parameters under the Copilot-managed path:

```
/copilot/gojocalories/prod/secrets/<SECRET_NAME>
```

| SSM Parameter Path | Secret / Variable |
|---|---|
| `/copilot/gojocalories/prod/secrets/GEMINI_API_KEY` | Google Gemini AI key |
| `/copilot/gojocalories/prod/secrets/SECRET_KEY` | JWT signing secret |
| `/copilot/gojocalories/prod/secrets/ALLOWED_ORIGINS` | CORS origins list |
| `/copilot/gojocalories/prod/secrets/AWS_BUCKET_NAME` | S3 bucket name |
| `/copilot/gojocalories/prod/secrets/DATABASE_URL` | PostgreSQL connection string |
| `/copilot/gojocalories/prod/secrets/STRIPE_SECRET_KEY` | Stripe secret key |
| `/copilot/gojocalories/prod/secrets/STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret |
| `/copilot/gojocalories/prod/secrets/STRIPE_PUBLISHABLE_KEY` | Stripe publishable key |
| `/copilot/gojocalories/prod/secrets/FOODDATA_CENTRAL_API_KEY` | USDA FoodData API key |

The ECS task role is granted access via the IAM policy in [`backend/ssm_policy.json`](file:///home/zelghourfi/Documents/gojocalories/backend/ssm_policy.json):

```json
"Resource": [
    "arn:aws:ssm:us-east-1:353284254035:parameter/copilot/gojocalories/prod/secrets/*"
]
```

> [!WARNING]
> This ARN contains the **hardcoded account ID `353284254035`** and **region `us-east-1`**. This is the primary file to update when changing accounts.

### 2.5 Amazon S3

| Property | Value |
|---|---|
| **Bucket Name** | `gojo-media-uploads` |
| **Access** | Private (no public access) |
| **Upload pattern** | `food_logs_<uuid>.jpg` |
| **URL generation** | Pre-signed URLs (7-day expiry) |
| **Fallback** | Local filesystem `/uploads/` if bucket not configured |

**IAM Actions granted to ECS Task Role:**
- `s3:PutObject`
- `s3:PutObjectAcl`
- `s3:GetObject`
- `s3:ListBucket`

Used in: [`backend/s3_utils.py`](file:///home/zelghourfi/Documents/gojocalories/backend/s3_utils.py)
Configured in: [`copilot/api/manifest.yml`](file:///home/zelghourfi/Documents/gojocalories/copilot/api/manifest.yml) lines 56–65

### 2.6 AWS SES (Simple Email Service)

| Property | Value |
|---|---|
| **Sender Email** | `noreply@gojocalories.com` (env var `SES_SENDER_EMAIL`) |
| **Region** | `us-east-1` (env var `AWS_REGION`) |
| **Auth** | `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars |

Used in: [`backend/services/email_service.py`](file:///home/zelghourfi/Documents/gojocalories/backend/services/email_service.py)  
Purpose: Email verification codes sent to users during registration.

### 2.7 IAM (Identity & Access Management)

Copilot auto-creates two IAM roles per service:
1. **ECS Task Role** — has policies to access S3 and SSM Parameter Store (defined in `copilot/api/manifest.yml` under `iam_policy_statements`)
2. **ECS Task Execution Role** — allows Fargate to pull images from ECR and write CloudWatch logs

### 2.8 Amazon VPC & Networking

Copilot automatically creates a full VPC with public and private subnets in `us-east-1` for the `prod` environment. Configuration is in [`copilot/environments/prod/manifest.yml`](file:///home/zelghourfi/Documents/gojocalories/copilot/environments/prod/manifest.yml).

### 2.9 Amazon CloudWatch

Container Insights is disabled (`container_insights: false` in the prod environment manifest). Basic CloudWatch Logs are still created automatically by Copilot for ECS task logs.

---

## 3. Current Account-Specific Values

These are the values **hardcoded or bound to the current AWS account** that must be updated during migration:

| # | Value | Where Used | File |
|---|---|---|---|
| 1 | Account ID: `353284254035` | SSM IAM policy ARN | `backend/ssm_policy.json` |
| 2 | Region: `us-east-1` | SSM ARN, S3 client default, SES client default | `ssm_policy.json`, `s3_utils.py`, `email_service.py` |
| 3 | S3 Bucket: `gojo-media-uploads` | IAM policy ARN | `copilot/api/manifest.yml` |
| 4 | ALB DNS: `gojoca-Publi-2bRSRsFxYTTs-1943547672.us-east-1.elb.amazonaws.com` | Test script base URL | `backend/test_aws_endpoints.py` |
| 5 | Copilot SSM secret paths: `/copilot/gojocalories/prod/secrets/*` | All secrets injection | `copilot/api/manifest.yml` |
| 6 | ECR Repo: `353284254035.dkr.ecr.us-east-1.amazonaws.com/gojocalories/api` | Auto-managed by Copilot | (internal, no manual file) |

---

## 4. Configuration Files Map

A complete map of every file and the AWS-related config it contains:

### `copilot/api/manifest.yml`
**Most critical file.** Controls the entire ECS service definition.
- `secrets:` block — SSM parameter paths (will be re-created automatically by Copilot in new account)
- `iam_policy_statements:` block — S3 bucket ARN (`arn:aws:s3:::gojo-media-uploads` and `/*`)

### `copilot/environments/prod/manifest.yml`
- Environment name `prod`
- `container_insights: false`
- VPC config (currently auto-generated, no hardcoded IDs)

### `copilot/.workspace`
- `application: gojocalories` — Copilot app name

### `backend/ssm_policy.json`
> [!CAUTION]
> Contains hardcoded ARN with account ID and region:
> `arn:aws:ssm:us-east-1:353284254035:parameter/copilot/gojocalories/prod/secrets/*`

### `backend/s3_utils.py`
- Reads `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` from environment
- Reads `AWS_BUCKET_NAME` from environment
- No hardcoded account IDs (all env-driven)

### `backend/services/email_service.py`
- Reads `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` from environment
- Reads `SES_SENDER_EMAIL` from environment
- No hardcoded account IDs (all env-driven)

### `backend/test_aws_endpoints.py`
- Hardcoded ALB DNS URL (line 5) — update after migration to new ALB DNS

### `backend/.env.example`
- Template for local development env vars (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET_NAME`)
- Not deployed; developer reference only

### `lib/core/network/api_client.dart` (Flutter)
- Reads `API_URL` from `.env` file (flutter_dotenv)
- Fallback: `https://api.gojocalories.com/api/`
- **No AWS account dependency** — only needs DNS to resolve correctly

---

## 5. Step-by-Step Migration Guide

Follow these steps **in order** to migrate GojoCalories to a new AWS account.

### Phase 1: Prepare the New Account

**Step 1 — Configure AWS CLI with the new account credentials**
```bash
aws configure --profile new-account
# Enter: New Access Key ID, Secret Access Key, region (e.g. us-east-1), json
```

**Step 2 — Install AWS Copilot CLI (if not already installed)**
```bash
# The deploy.sh script does this automatically, or do it manually:
curl -Lo /usr/local/bin/copilot https://github.com/aws/copilot-cli/releases/latest/download/copilot-linux
chmod +x /usr/local/bin/copilot
```

---

### Phase 2: Create the S3 Bucket

**Step 3 — Create the S3 bucket in the new account**
```bash
# If keeping the same bucket name (must be globally unique on S3):
aws s3api create-bucket \
  --bucket gojo-media-uploads \
  --region us-east-1 \
  --profile new-account

# Block all public access (keep private):
aws s3api put-public-access-block \
  --bucket gojo-media-uploads \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile new-account
```

> [!IMPORTANT]
> If you use a **different bucket name**, update `copilot/api/manifest.yml` lines 64–65 with the new bucket ARN before deploying.

---

### Phase 3: Verify SES Sender Email

**Step 4 — Verify the sender email in SES**
```bash
aws ses verify-email-identity \
  --email-address noreply@gojocalories.com \
  --region us-east-1 \
  --profile new-account
```
Check your inbox for the verification email and click the link.

> [!NOTE]
> If you're still in SES sandbox mode in the new account, you must also verify every **recipient** email or request production access from AWS Support.

---

### Phase 4: Deploy via AWS Copilot

**Step 5 — Initialize the Copilot application in the new account**
```bash
cd /home/zelghourfi/Documents/gojocalories

# Point Copilot at the new account profile
copilot app init gojocalories --profile new-account
```

**Step 6 — Initialize the production environment**
```bash
copilot env init \
  --name prod \
  --profile new-account \
  --default-config
```
This creates the VPC, ECS cluster, and ALB in the new account.

**Step 7 — Push all secrets into the new account's SSM Parameter Store**

Run the following for **each** secret. Replace `<VALUE>` with the actual secret.

```bash
# Helper function
put_secret() {
  aws ssm put-parameter \
    --name "/copilot/gojocalories/prod/secrets/$1" \
    --value "$2" \
    --type "SecureString" \
    --region us-east-1 \
    --profile new-account \
    --overwrite
}

put_secret "GEMINI_API_KEY"          "<your-gemini-api-key>"
put_secret "SECRET_KEY"              "<your-jwt-secret-key>"
put_secret "ALLOWED_ORIGINS"         "https://api.gojocalories.com"
put_secret "AWS_BUCKET_NAME"         "gojo-media-uploads"
put_secret "DATABASE_URL"            "postgresql://user:pass@host:5432/gojocalories"
put_secret "STRIPE_SECRET_KEY"       "sk_live_..."
put_secret "STRIPE_WEBHOOK_SECRET"   "whsec_..."
put_secret "STRIPE_PUBLISHABLE_KEY"  "pk_live_..."
put_secret "FOODDATA_CENTRAL_API_KEY" "<usda-api-key>"
```

**Step 8 — Deploy the environment and service**
```bash
# Deploy VPC, ALB, ECS cluster
copilot env deploy --name prod

# Build Docker image → push to new ECR → deploy ECS service
copilot deploy --name api --env prod
```

Copilot will output the **new ALB DNS** at the end of this step. Save it.

---

### Phase 5: Update Hardcoded Values in the Codebase

**Step 9 — Update `backend/ssm_policy.json`**

Replace the old account ID and region with the new ones:

```diff
- "arn:aws:ssm:us-east-1:353284254035:parameter/copilot/gojocalories/prod/secrets/*"
+ "arn:aws:ssm:<NEW_REGION>:<NEW_ACCOUNT_ID>:parameter/copilot/gojocalories/prod/secrets/*"
```

File: [`backend/ssm_policy.json`](file:///home/zelghourfi/Documents/gojocalories/backend/ssm_policy.json)

**Step 10 — Update `backend/test_aws_endpoints.py`**

Replace the ALB DNS with the new one from Step 8:

```diff
- BASE_URL = "http://gojoca-Publi-2bRSRsFxYTTs-1943547672.us-east-1.elb.amazonaws.com/api"
+ BASE_URL = "http://<NEW_ALB_DNS>/api"
```

File: [`backend/test_aws_endpoints.py`](file:///home/zelghourfi/Documents/gojocalories/backend/test_aws_endpoints.py)

---

### Phase 6: Update DNS

**Step 11 — Update DNS to point to the new ALB**

In Cloudflare (or Route 53), update the CNAME/A record for `api.gojocalories.com`:
- Old target: `gojoca-Publi-2bRSRsFxYTTs-1943547672.us-east-1.elb.amazonaws.com`
- New target: `<NEW_ALB_DNS>` (from Step 8)

> [!IMPORTANT]
> Propagation can take up to 48 hours but is usually instant with Cloudflare proxy mode. Keep the old ECS service running until DNS is fully propagated and validated.

---

### Phase 7: Update Stripe Webhook

**Step 12 — Update the Stripe Webhook endpoint**

Go to [Stripe Dashboard → Developers → Webhooks](https://dashboard.stripe.com/webhooks):
- If the webhook URL has changed (e.g., new custom domain), update it
- If you're keeping `api.gojocalories.com`, no change needed
- Re-reveal the **Signing Secret** and re-add it to SSM if regenerated

---

### Phase 8: Migrate S3 Data (if needed)

**Step 13 — Migrate existing food images from old S3 bucket to new bucket**

```bash
# Sync all objects from old account bucket to new account bucket
aws s3 sync \
  s3://gojo-media-uploads \
  s3://gojo-media-uploads \
  --source-region us-east-1 \
  --region us-east-1 \
  --profile old-account \
  # Note: cross-account sync requires proper IAM permissions on both sides
```

For cross-account migration, the recommended approach is:
1. Grant the new account's IAM role read access to the old bucket
2. Run `aws s3 sync` from the new account
3. Or download locally and re-upload

---

## 6. Post-Migration Checklist

Use this checklist to verify the migration is complete and working:

```
Infrastructure
☐ New AWS account is configured in AWS CLI (--profile)
☐ Copilot application initialized in new account
☐ S3 bucket created and public access blocked
☐ SES sender email verified
☐ All 9 SSM secrets populated in new account
☐ Copilot env deployed (VPC, ECS cluster, ALB created)
☐ Copilot service deployed (ECR image pushed, ECS running)

Code Updates
☐ backend/ssm_policy.json updated with new Account ID and region
☐ backend/test_aws_endpoints.py updated with new ALB DNS

DNS & Routing
☐ api.gojocalories.com CNAME/A updated to new ALB DNS
☐ DNS propagation verified (curl https://api.gojocalories.com/ returns { "status": "..." })

Stripe
☐ Stripe webhook endpoint verified/updated
☐ Stripe webhook signing secret re-added to SSM if changed

Testing
☐ Run backend/test_aws_endpoints.py against new URL — all tests pass
☐ Register a new user → login → scan food → verify image in new S3 bucket
☐ Trigger a Stripe test webhook → verify has_paid flag updates
☐ Verify email verification flow works (SES)

Cleanup (after validation)
☐ Old ECS service scaled down / deleted
☐ Old ECR images cleaned up
☐ Old SSM parameters deleted
☐ Old S3 bucket emptied and deleted (after confirming all data is migrated)
☐ Old IAM roles and policies reviewed and removed
```

---

## Summary of Files to Change

| File | Change Needed | Priority |
|---|---|---|
| `backend/ssm_policy.json` | New account ID + region in ARN | 🔴 Critical |
| `copilot/api/manifest.yml` | S3 bucket ARN (if bucket name changes) | 🟡 Conditional |
| `backend/test_aws_endpoints.py` | New ALB DNS URL | 🟢 Dev/Test only |
| DNS (Cloudflare) | Update `api.gojocalories.com` CNAME | 🔴 Critical |
| SSM Parameters | Re-create all 9 secrets in new account | 🔴 Critical |
| Stripe Webhook | Update if webhook endpoint URL changes | 🟡 Conditional |
| `backend/.env.example` | Update region/bucket if different | 🟢 Dev reference |

> [!TIP]
> The application code (`s3_utils.py`, `email_service.py`, `database.py`) reads **all AWS config from environment variables**. These files require **zero changes** — only the SSM parameters and the one hardcoded ARN in `ssm_policy.json` need updating.
