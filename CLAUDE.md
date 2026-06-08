# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- `npm run dev` — Start Vite dev server
- `npm run build` — Production build
- `npm run lint` — ESLint (flat config, JS/JSX only)
- `npm run preview` — Preview production build

No test runner is configured (no vitest/jest, no test files). `lint` is the only automated check.

## Architecture

React 19 SPA using Vite 7.1, Tailwind CSS 4 (via `@tailwindcss/vite`), and React Router 7.8. No TypeScript — plain JSX throughout. `"type": "module"` (ESM).

### State Management

Two React Context directories with confusingly similar names — mind the singular/plural:

- **`src/context/`** (singular) — Core contexts: `AuthContext` (auth + dummy users + localStorage persistence; exposes `isEmployer` / `isJobSeeker` / `isAdmin` helpers), `JobContext` (applications, saved jobs, employer job CRUD), `ThemeContext`
- **`src/contexts/`** (plural) — Data-fetching contexts: `JobsDataContext` (cached job list with 5-min TTL), `CompaniesContext`

Provider nesting order (in `App.jsx`): AuthProvider → JobsDataProvider → JobProvider → CompaniesProvider → ThemeProvider → Router.

### Data Layer

Currently uses **mock data** with localStorage persistence — no real backend. Data originates from `src/data/mockData.js`.

Services in `src/services/` simulate async API calls: each returns a Promise, wraps `delay()` from `src/utils/delay.js`, and reads/writes localStorage. Files: `companyService`, `contactService`, `jobApplicationService`, `profileService`, `savedJobService`. Mutations in these services must stay in sync with the `*_{userId}` localStorage keys below.

Key localStorage keys: `jobPortalUser`, `authToken`, `registeredUsers`, `globalPostedJobs`, `jobApplications_{userId}`, `savedJobs_{userId}`, `postedJobs_{userId}`.

### Test Credentials

Dummy logins defined in `src/context/AuthContext.jsx`. The app is auth-gated, so use these to reach protected routes:

| Email | Password | Role |
|-------|----------|------|
| `employer@company.com` | `employer123` | ROLE_EMPLOYER |
| `hr@startup.com` | `hr123` | ROLE_EMPLOYER |
| `jobseeker@email.com` | `jobseeker123` | ROLE_JOB_SEEKER |
| `candidate@email.com` | `candidate123` | ROLE_JOB_SEEKER |
| `admin@portal.com` | `admin123` | ROLE_ADMIN |

Registration creates additional `ROLE_JOB_SEEKER` users persisted to localStorage (`registeredUsers`).

### Routing & Roles

All routes are nested under `<Layout />` in `src/App.jsx`. Roles are bare string literals (no enum/constants file) compared against the `allowedRoles` array in `src/components/ProtectedRoute.jsx` — unauthenticated → redirect to `/login`, wrong role → redirect to `/`.

| Path | Component | Required role |
|------|-----------|---------------|
| `/` | Home | public |
| `jobs` | Jobs | public |
| `jobs/:id` | JobDetail | public |
| `companies` | Companies | public |
| `companies/:id` | CompanyDetail | public |
| `login` | Login | public |
| `register` | Register | public |
| `contact` | Contact | public |
| `profile` | Profile | ROLE_JOB_SEEKER |
| `applied-jobs` | AppliedJobs | ROLE_JOB_SEEKER |
| `saved-jobs` | SavedJobs | ROLE_JOB_SEEKER |
| `post-job` | PostJob | ROLE_EMPLOYER |
| `employer/jobs` | MyJobs | ROLE_EMPLOYER |
| `job-applicants/:jobId` | JobApplicants | ROLE_EMPLOYER |
| `admin` | Dashboard | ROLE_ADMIN |
| `admin/companies` | CompanyManagement | ROLE_ADMIN |
| `admin/employers` | EmployerManagement | ROLE_ADMIN |
| `admin/contact-messages` | ContactMessages | ROLE_ADMIN |

Admin pages live in `src/pages/admin/`.

### Key Libraries

- Font Awesome 6.7 + Lucide React 0.539 for icons
- react-toastify 11 for notifications

### Conventions

- ESM only (`"type": "module"`).
- Tailwind 4 is wired through the Vite plugin — there is **no** `tailwind.config.js` or PostCSS config.
- `vite.config.js` is minimal: `react()` + `tailwindcss()` plugins, no path aliases or proxy. Use relative imports.
- ESLint flat config (`eslint.config.js`, ESLint 9). The `no-unused-vars` rule ignores variables starting with uppercase or underscore (`varsIgnorePattern: '^[A-Z_]'`).
