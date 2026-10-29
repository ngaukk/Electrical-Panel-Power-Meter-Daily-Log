# Electrical Panel Power Meter Daily Log

Daily kWh register log for the six electrical panel power meters at **Lam Soon Edible Oils Sdn. Bhd., Telok Panglima Garang Factory** (Workshop Department).

The log is one web page (`index.html`) hosted on GitHub Pages. Readings are stored in a Supabase database. Only registered staff can sign in, see readings or save them.

**Live log:** `https://<your-github-name>.github.io/power-meter-log/`

## Meters

| Code | Meter |
| --- | --- |
| LV1885 | Transformer 1 |
| LV201357 | Transformer 2 |
| SB-UT | Utility |
| COM | Compressor |
| PUMP | Chiller Pump |
| SB-SM | Soap Main |

## What the log does

- **Dashboard:** today's status for all 6 meters, last register, last daily use, 7-day average and month-to-date kWh, a daily consumption bar chart and a cumulative reading line chart.
- **Daily entry:** one meter at a time from the Entry menu; reading time is stamped automatically when saved; warns if a reading is lower than the previous one.
- **History:** by month, as register readings or daily usage; edit or delete a day; Export CSV, Import CSV, and a monthly report in paper-form layout as PDF.
- **Trends:** per meter or all meters, for 7, 30, 90 days, 12 months or a chosen period, with Create PDF.
- **Contact:** contractor contacts grouped by company.
- Phone and PC layouts (switch with the 📱 / 🖥️ buttons), light and dark mode.

Usage is calculated as `(today's register − previous register) × CT/PT multiplier`. When readings are more than a day apart, the usage is spread over the days between.

## Files

| File | Purpose |
| --- | --- |
| `index.html` | The whole web page: layout, charts, reports and the connection to Supabase |
| `supabase/schema.sql` | Creates the database tables, the six meters, the security rules and live updates |
| `README.md` | This guide |

No readings or staff emails are stored in this repository. They live only in Supabase, behind sign-in.

## Setup

### 1. Supabase database

1. Create a project at [supabase.com](https://supabase.com) (region: Southeast Asia, Singapore).
2. **SQL Editor → New query:** paste all of `supabase/schema.sql` and click **Run**. The last line should show `meters = 6`.
3. **Table Editor → staff:** add one row per person who records readings (`name` as it should appear in "Recorded by", `email` they will sign in with).
4. **Authentication → Users → Add user → Send invitation** for each staff email.
5. **Authentication → Sign In / Providers:** keep Email on; turn off **Allow new users to sign up**.
6. **Authentication → URL Configuration:** set **Site URL** and add a **Redirect URL**, both to the GitHub Pages address of the log.

### 2. Connect the page

In `index.html`, search for `SB_URL` and set your own values from **Project Settings → API Keys**:

```js
const SB_URL = "https://<project-ref>.supabase.co";
const SB_KEY = "sb_publishable_...";
```

Use the **publishable** (anon) key only. Never put the secret / `service_role` key in this page or this repository. The publishable key is safe to publish because the security rules in `schema.sql` decide who can read and write.

### 3. Publish on GitHub Pages

1. Upload `index.html`, `README.md` and the `supabase` folder to this repository.
2. **Settings → Pages:** Source **Deploy from a branch**, branch **main**, folder **/ (root)**, **Save**.
3. After 1 to 2 minutes the log is live at `https://<your-github-name>.github.io/power-meter-log/`.

## Signing in

1. Open the log and tap **Sign in**.
2. Enter your work email and tap **Send sign-in link**.
3. Open the email on the same phone or PC and tap the link. You return to the log, signed in. Your name fills **Recorded by** automatically.

If the email is not in the staff list, the log stays empty. Ask the Admin to add you.

## Looking after the log

| Task | Where |
| --- | --- |
| Add a staff member | Supabase Table Editor → `staff` (add row), then Authentication → Users → invite |
| Remove a staff member | Delete their `staff` row and their user under Authentication → Users |
| Change a CT/PT multiplier | Table Editor → `meters` → `multiplier` |
| Correct or delete a reading | In the log: History → pencil or ✕ |
| Month-end backup | In the log: History → Export CSV, keep the file on the shared drive |
| Update the page | Upload a new `index.html` here; the site updates in about a minute |

The free Supabase plan pauses a project after about a week without use; daily logging keeps it active. If it is paused, open the Supabase dashboard and click **Restore project**.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| Sign-in link opens a blank page or localhost | Set Site URL and Redirect URL (Setup 1, item 6) |
| Sign-in email does not arrive | Check spam; the free plan sends only a few emails per hour, so wait and retry |
| Signed in but no readings show | The email is not in the `staff` table, or is spelled differently |
| GitHub address shows 404 | Wait 2 minutes; the file must be named `index.html` in the repository root |
