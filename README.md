# New Terra

Business operations platform for managing clients, budgets, accounts, providers, stock, and PDF reports.

## Structure

This repo is a monorepo shell containing two git submodules:

| | Repo | Path |
|---|---|---|
| **Frontend** | [jmbretana/new-terra](https://github.com/jmbretana/new-terra) | `src/frontend/` |
| **Backend** | [jmbretana/new-terra-api](https://github.com/jmbretana/new-terra-api) | `src/backend/` |

Both are deployed independently on **Netlify**.

## Stack

| Layer | Tech |
|---|---|
| Frontend | React + TypeScript, Redux Toolkit, Material-UI v6, Rsbuild |
| Backend | Node.js, Express 4, MongoDB (Mongoose), JWT, Netlify serverless |

## Getting started

```bash
# Clone with submodules
git clone --recurse-submodules <repo-url>

# Or init after a plain clone
git submodule update --init --recursive
```

### Frontend

```bash
cd src/frontend
npm install
npm run dev        # dev server with hot-reload
npm run build      # production build
npm run lint
```

### Backend

```bash
cd src/backend
npm install
npm run demon      # nodemon dev (port 3001)
npm test
npm run lint
```

Required environment variables for the backend: `JWT_SECRET`, `MONGODB_URI`. Copy from `.env` (not committed).

## Architecture

```
Browser
  └─ src/frontend  (React SPA — Netlify CDN)
         │  Axios /api/*
         ▼
  src/backend  (Express REST API — Netlify Functions)
         │  Mongoose
         ▼
     MongoDB Atlas
```

All API routes are prefixed `/api`. CORS allows `https://newterra.netlify.app` and localhost dev origins.
