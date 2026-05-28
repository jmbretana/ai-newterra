# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository structure

This is a thin monorepo shell — it holds two git submodules:

| Submodule | Path | Remote |
|-----------|------|--------|
| Frontend (new-terra) | `src/frontend/` | https://github.com/jmbretana/new-terra |
| Backend (new-terra-api) | `src/backend/` | https://github.com/jmbretana/new-terra-api |

Each submodule has its own `.git`, dependencies, CI, and `CLAUDE.md`. Work on a submodule as if you were inside its own repo.

## Submodule-specific guidance

- **Frontend:** see [src/frontend/CLAUDE.md](src/frontend/CLAUDE.md) — React + TypeScript, Redux Toolkit, MUI v6, rsbuild.
- **Backend:** see [src/backend/CLAUDE.md](src/backend/CLAUDE.md) — Node.js, Express 4, MongoDB/Mongoose, Netlify serverless.

## Working with submodules

```bash
# Clone and initialize all submodules
git clone --recurse-submodules <repo-url>

# If already cloned without submodules
git submodule update --init --recursive

# Pull latest on both submodules
git submodule update --remote --merge

# Check submodule status (shows commit hash each points to)
git submodule status
```

Commits in this repo only record which submodule commit is checked out. To update the pinned commit after working in a submodule:

```bash
cd src/frontend   # or src/backend
git add . && git commit && git push
cd ../..
git add src/frontend   # stage the new submodule pointer
git commit -m "chore: bump frontend submodule"
```

## Overall architecture

```
Browser
  └─ src/frontend  (React SPA, served by Netlify CDN)
         │ HTTP (Axios)  /api/*
         ▼
  src/backend  (Express REST API, Netlify serverless functions)
         │ Mongoose
         ▼
       MongoDB Atlas
```

The frontend and backend are deployed independently on Netlify. CORS in the backend allows `https://newterra.netlify.app` and localhost dev origins.
