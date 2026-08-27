# 🚀 Free Deployment Guide for Render

This project is configured for **100% Free / Trial Tier Deployment** on [Render](https://render.com) using Docker.

---

## 📦 What Was Built for Docker & Render

1. **[`Dockerfile`](file:///usr/local/google/home/mhumza/humza/Dockerfile):** Multi-stage production build that installs dependencies, precompiles assets, and runs as a secure non-root user.
2. **[`docker-compose.yml`](file:///usr/local/google/home/mhumza/humza/docker-compose.yml):** Local containerized testing with PostgreSQL and Rails.
3. **[`bin/docker-entrypoint`](file:///usr/local/google/home/mhumza/humza/bin/docker-entrypoint):** Automatically prepares the database (`bin/rails db:prepare`) and runs migrations on start.
4. **[`render.yaml`](file:///usr/local/google/home/mhumza/humza/render.yaml):** Render Blueprint infrastructure configuration using Render's **Free Tier**.

---

## 🛠️ Step-by-Step Deployment Instructions

### Option 1: Automatic 1-Click Deployment (Recommended)

1. **Push your code to GitHub / GitLab:**
   ```bash
   git push origin feature/splitwise-expenses
   ```
2. **Log into [Render.com](https://dashboard.render.com)** (create a free account if you haven't yet).
3. Click **"Blueprints"** in the top navigation bar.
4. Click **"New Blueprint Instance"**.
5. Connect your GitHub repository and select your branch (`feature/splitwise-expenses`).
6. Render will automatically read [`render.yaml`](file:///usr/local/google/home/mhumza/humza/render.yaml) and provision:
   * **Free Web Service:** `splitwise-clone` (Docker runtime)
   * **Free PostgreSQL Database:** `splitwise-db`
7. Click **"Apply"** — Render will build the Docker container and deploy the app!

---

### Option 2: Manual Deployment via Render Dashboard

If you prefer to configure manually via the Render UI:

#### Step 1: Create Free PostgreSQL Database
1. Go to **Dashboard** -> **New +** -> **PostgreSQL**.
2. Name: `splitwise-db`
3. Database: `splitwise_production`
4. User: `splitwise_user`
5. Plan: **Free**
6. Click **Create Database**.
7. Copy the **Internal Database URL** (e.g. `postgresql://...`).

#### Step 2: Create Free Web Service (Docker)
1. Go to **Dashboard** -> **New +** -> **Web Service**.
2. Connect your Git repository.
3. Name: `splitwise-clone`
4. Runtime: **Docker**
5. Plan: **Free**
6. Add the following **Environment Variables**:
   * `RAILS_ENV` = `production`
   * `RAILS_SERVE_STATIC_FILES` = `true`
   * `RAILS_LOG_TO_STDOUT` = `true`
   * `SECRET_KEY_BASE` = *(Click "Generate" or enter a random 64-character string)*
   * `DATABASE_URL` = *(Paste the Internal Database URL from Step 1)*
7. Click **Create Web Service**.

---

## 🐳 Local Testing with Docker Compose

To test the containerized app locally before pushing:

```bash
# 1. Build and start both PostgreSQL and Rails containers
docker-compose up --build

# 2. Open in your browser
http://localhost:3000
```
