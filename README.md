# Brother Cond. — Madinaty Branch — Spare Parts System

A bilingual (Arabic/English) spare parts inventory, sales (POS), customers, and
finance system, backed by Supabase and hosted free on GitHub Pages.

## What's in this folder
- `index.html` — the whole app (no build step needed)
- `config.js` — where you paste your Supabase project keys
- `schema.sql` — run this once inside Supabase to create all the tables

## 1. Set up Supabase (5 min)

1. Open your Supabase project → left sidebar → **SQL Editor** → **New query**.
2. Open `schema.sql` from this folder, copy all of it, paste it into the query editor, and click **Run**.
   This creates all the tables (parts, suppliers, customers, purchases, sales, expenses, profiles)
   and the security rules that only let logged-in staff see the data.
3. Go to **Authentication → Providers** and make sure **Email** is enabled (it is by default).
4. Go to **Authentication → Users → Add user** and create your own account:
   - Email: your email (e.g. `you@example.com`)
   - Password: pick one
   - Leave "Auto confirm user" checked
   The **very first account you create automatically becomes Admin**. Every account
   after that starts as "Staff" — you can promote them to Admin later from inside the app
   (Staff section).
5. Go to **Project Settings → API**. Copy:
   - **Project URL**
   - **anon public** key

## 2. Add your keys

Open `config.js` and replace the two placeholder values:

```js
const SUPABASE_URL = "https://xxxxxxxx.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOi....";
```

This key is safe to publish in a public GitHub repo — it only allows what your
Row Level Security rules (from `schema.sql`) permit, which is "logged-in staff only."

## 3. Put it on GitHub

1. Create a new repository on GitHub (e.g. `spareparts-madinaty`). Keep it either
   Public or Private — both work with GitHub Pages (Private Pages needs GitHub Pro/Team;
   if you're on a free personal account, use **Public**).
2. Upload all 3 files (`index.html`, `config.js`, `schema.sql`) to the repo — either
   drag-and-drop them on the GitHub website ("Add file → Upload files"), or via git:

```bash
git init
git add index.html config.js schema.sql README.md
git commit -m "Spare parts system"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/spareparts-madinaty.git
git push -u origin main
```

## 4. Turn on GitHub Pages

1. In your repo, go to **Settings → Pages**.
2. Under "Build and deployment" → **Source**, choose **Deploy from a branch**.
3. Branch: `main`, folder: `/ (root)` → **Save**.
4. Wait ~1 minute, then refresh the page — GitHub will show you the live URL,
   something like: `https://YOUR-USERNAME.github.io/spareparts-madinaty/`

That's your permanent system URL — bookmark it, or add it to your phone's home screen.

## 5. Adding more staff later

You (as Admin) can't create logins from inside the app itself — Supabase keeps
that locked down for security. Instead:
1. Supabase Dashboard → **Authentication → Users → Add user** → give them an email + password.
2. Log into the app → **Staff** section → their name will already be listed
   (as "Staff" by default) → click **Edit** if you want to promote them to Admin
   or fix their display name.

## Notes
- Everyone who logs in sees the same shared inventory, sales, and customer data —
  this is a shared branch system, not per-person storage.
- Admin-only sections: **Finance** and **Staff**. Regular staff can use
  Inventory, Suppliers, Purchases, Sales (POS), and Customers.
- The receipt printing uses your browser's print dialog — works with any
  receipt printer connected to the computer/tablet you're using.
- If you ever want to reset all data, you can truncate the tables from the
  Supabase SQL Editor, e.g.: `truncate table sale_items, sales, purchase_items, purchases, parts, suppliers, customers, expenses restart identity cascade;`
