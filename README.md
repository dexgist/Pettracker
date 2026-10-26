# PetTrack

PetTrack is a local pet relocation management system for journeys within the Philippines. This repository keeps the existing Angular 22 client and adds a PHP 8.2+ JSON API with a MySQL/MariaDB schema. PHP and MySQL are required for authentication and persistent workflows; the Angular development server alone does not provide backend functionality.

## Requirements

- Node.js 20.19+ and npm (use the versions supported by the installed Angular CLI)
- PHP 8.2+ with `pdo_mysql`, `fileinfo`, and sessions enabled
- MySQL 8+ or MariaDB 10.6+
- XAMPP is suitable for local development

## Setup

1. Start MySQL in XAMPP and import `database/schema.sql` with phpMyAdmin or the MySQL command line.
2. Copy `.env.example` to `.env` in the project root and set the database connection values. Never commit `.env`.
3. Ensure PHP can read `.env` and write to `server/storage/documents`. Keep document storage outside the public web root in production.
4. Create the first administrator once from a terminal. Supply its password through a process environment variable, not as a command argument:

   ```powershell
   $secure = Read-Host "Initial administrator password" -AsSecureString
   $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
   try { $env:PETTRACK_INITIAL_ADMIN_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr); php scripts/create-first-admin.php "System Administrator" admin@example.test }
   finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr); Remove-Item Env:PETTRACK_INITIAL_ADMIN_PASSWORD -ErrorAction SilentlyContinue }
   ```

   Use at least 14 characters. The script refuses to create an administrator if one already exists. Additional accounts must be created by a signed-in administrator. Remove the initializer from production after setup.

For an existing installation created from an earlier schema, take a database backup and apply `database/migrations/20261026_pettrack_workflows.sql` once before starting the updated app. Fresh installations should import the current `database/schema.sql` only.
5. Start the PHP API from the repository root:

   ```powershell
   php -S 127.0.0.1:8080 -t server/public
   ```

6. In another terminal run `npm install` and `npm start`; open `http://localhost:4200`. The Angular development proxy forwards `/api` calls to PHP. XAMPP Apache can also serve `server/public`, but configure the app origin and database environment accordingly. Do not put the API on a different origin without configuring secure CORS and cookies.

### Database environment

`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, and `DB_PASSWORD` are read by `server/src/Database.php` from process variables, with the root `.env` file used as a local fallback. Set `APP_TIMEZONE=Asia/Manila` for the intended local deployment.

## Workflows included

- Session login/logout, CSRF token checks, role checks, login throttling, and secure password hashing.
- Administrator-only account creation, editing, role changes, deactivation, and temporary password resets; CLI-only one-time initial administrator creation.
- Owner pet profile creation and editing, protected photo upload, vaccination history, and ownership-scoped access.
- Relocation request creation with transport type and emergency contact, human-readable references, route and transport-specific checklist snapshots, and staff/admin status transitions with history.
- Private PDF/JPG/PNG document storage and authorization-checked downloads; staff reviews and correction feedback.
- Document expiration dates and configurable validity periods with scheduled in-app reminders; document review history remains visible on each request.
- Database-backed notifications, pickup schedule validation and change history, idempotent pickup/expiration reminders, audit activity, filtered administrator CSV exports, printable request/report summaries, and Chart.js analytics.
- Administrator-only system health and backup/recovery guidance; the health view does not expose environment secrets.
- Responsive owner, staff, and administrator workspace views.

Public account registration is not implemented. Route document checklists are administrative references and must be configured from verified guidance. PetTrack milestones are entered by authorized users; the app does not provide GPS tracking, transport, veterinary certification, or automatic legal validation.

## Run checks

```powershell
npm run build
npm test -- --watch=false
```

The repository also needs PHP checks in an environment with PHP installed:

```powershell
Get-ChildItem server\src\*.php,server\public\*.php,scripts\*.php | ForEach-Object { php -l $_.FullName }
```

Then import the schema, create a test administrator, and verify login, role restrictions, owner isolation, uploads, review feedback, status history, schedule visibility, reminder deduplication, notifications, charts, and report export against a disposable database. No test or PHP syntax result should be inferred from the Angular build.

## Backup and recovery

Back up the `pettrack` MySQL database and `server/storage/documents` together using access-controlled storage. A SQL dump alone does not contain uploaded files, and the file store alone has no relational metadata. Before restore, stop writes, restore the database and matching document directory from the same backup point, then verify file ownership and permissions. Restrict backups to authorized operators and encrypt them at rest.

## Security and deployment notes

- Serve the site over HTTPS in production. The PHP session cookie is HttpOnly and SameSite=Lax; it is marked Secure when PHP detects HTTPS.
- Keep `server/storage` non-public, set conservative directory permissions, and configure PHP upload limits to at least the app's 10 MB per-file limit if that matches policy.
- Use a least-privilege database account rather than MySQL root outside a local XAMPP setup.
- Configure PHP error logging to a protected destination. The API returns generic server errors and logs technical details server-side.
- Configure Apache to serve only `server/public`; never expose the repository root, `.env`, SQL dumps, or uploaded documents.
- Scheduled pickup reminders are supported by `scripts/send-pickup-reminders.php`; configure it with Task Scheduler or cron as described below. Email and SMS providers are not configured.

## Acceptance checklist

- [ ] Start MySQL/PHP and import `database/schema.sql`.
- [ ] Create the first administrator through the CLI script and confirm a second initial setup is refused.
- [ ] Confirm a guest cannot access protected API routes and no public sign-up route exists.
- [ ] Create owner and staff accounts as admin; confirm owner/staff cannot create accounts.
- [ ] Add an owner pet and submit a Philippine local relocation request.
- [ ] Verify request reference and route checklist snapshot are saved.
- [ ] Submit a permitted document and confirm it remains pending until a staff review.
- [ ] Verify correction feedback and status updates appear in the owner's records.
- [ ] Confirm a user cannot view another owner's request, notification, or file.
- [ ] Verify schedule, audit activity, and CSV export using actual database data.
- [ ] Confirm schedules cannot be created before required documents are verified; schedule edits appear in the request history.
- [ ] Confirm route checklist rules match transport type and stored request snapshots survive later requirement edits.
- [ ] Set a document validity date, run the reminder command, and confirm an in-app expiration notification is created only once.
- [ ] Print a request summary and a filtered administrator report.
# 4. Create the first administrator once, from a terminal in the project directory. Set the password in the process environment instead of placing it in the command arguments:

   ```powershell
   $env:PETTRACK_INITIAL_ADMIN_PASSWORD = Read-Host "Initial administrator password"
   php scripts/create-first-admin.php "System Administrator" admin@example.test
   Remove-Item Env:PETTRACK_INITIAL_ADMIN_PASSWORD
   ```

   Use a unique password of at least 14 characters. Avoid shared terminals. The script refuses to create an administrator if one already exists. Additional accounts must be created while signed in as an administrator. Remove the initializer script from a production deployment after setup.

5. For a local Angular and PHP development setup, run the PHP API from the repository root in one terminal:

   ```powershell
   php -S 127.0.0.1:8080 -t server/public
   ```

   In another terminal run `npm install` and `npm start`; open `http://localhost:4200`. The Angular development proxy forwards `/api` calls to the PHP server. Alternatively, use XAMPP Apache with `server/public` as its document root and configure the matching API origin. Do not put the PHP API on a different origin without configuring secure CORS and cookie settings.
- Configure pickup reminders with Windows Task Scheduler or cron to run once daily:

  ```powershell
  php scripts/send-pickup-reminders.php
  ```

  The command creates one in-app reminder for each scheduled pickup within the next 24 hours and records that it sent the reminder to avoid duplicates. Configure the MySQL session offset (`DB_TIMEZONE_OFFSET`, default `+08:00`) to match the PHP `APP_TIMEZONE` used by the deployment. Email and SMS are not configured.
