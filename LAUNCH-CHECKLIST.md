# Rank Matrix Launch Checklist

## What's Built & Ready
- [x] Full SaaS with signup, login, password reset
- [x] Project and keyword management with plan limits
- [x] Daily automated rank checking (Celery + Beat scheduler)
- [x] Free SERP scraper fallback (works without ValueSERP API key)
- [x] Stripe billing: checkout, webhooks, subscription management, dunning
- [x] Email service: welcome email, ranking alerts, password reset
- [x] Dashboard with stats, top movers, biggest drops
- [x] Settings page: profile, password, subscription, account deletion
- [x] CSV export (paid plans)
- [x] Chart.js ranking history charts
- [x] Alembic database migrations (auto-run on deploy)
- [x] SEO: sitemap.xml, robots.txt, OpenGraph meta tags
- [x] Landing page with hero, features, pricing, FAQ
- [x] Health check endpoint for monitoring
- [x] Fly.io deploy config ready
- [x] Secure cookies, proper auth redirects
- [x] Pain Miner service for discovering SEO opportunities

## You Need To Do (30-45 min total)

### Local One-Click Run
1. Run `mm.bat doctor`
2. If doctor reports Docker/service/engine issues, run `mm.bat repair`
3. Run `mm.bat start`
4. If first run, setup is automatic.
5. App opens at `http://localhost:8000` and dashboard at `http://localhost:8100/dashboard`

### Startup Failure Map
1. Docker CLI missing
   - Action: install Docker Desktop, then `mm.bat doctor`
2. Docker service denied/stopped
   - Action: run `mm.bat repair` and approve UAC prompt
3. Docker engine not ready
   - Action: run `mm.bat repair`
4. Compose startup timeout
   - Action: run `mm.bat doctor`, then `mm.bat repair`
5. API health check failure on `8000` or `8100`
   - Action: run `mm.bat logs`

### 1. Stripe Setup (~10 min)
1. Create account at https://dashboard.stripe.com
2. Create 3 subscription products with monthly prices
3. Copy price IDs + secret key + webhook secret
4. Update `seo-rank-tracker/.env`

### 2. Domain (~5 min)
1. Buy a domain (e.g. rankmatrixseo.com)
2. Update `APP_URL` in .env

### 3. Deploy (~15 min)
**Fly.io (recommended - starts ~$5/mo):**
```bash
cd seo-rank-tracker
fly launch
fly postgres create
fly redis create
fly secrets set SECRET_KEY=... STRIPE_SECRET_KEY=... DATABASE_URL=... REDIS_URL=...
fly deploy
```

### 4. Optional (improve later)
- [ ] Resend API key for emails (free tier = 100/day)
- [ ] ValueSERP API key for more accurate rank data
- [ ] Reddit API for Pain Miner
- [ ] Custom domain SSL via Fly.io

### 5. Get Users
- Post on Reddit: r/SEO, r/smallbusiness, r/Entrepreneur, r/SideProject
- Post on Indie Hackers, Hacker News (Show HN)
- Tweet about it
- Add to Product Hunt

## Revenue Potential
| Plan | Price | 10 users | 50 users | 100 users |
|------|-------|----------|----------|-----------|
| Starter | $19/mo | $190/mo | $950/mo | $1,900/mo |
| Pro | $79/mo | $790/mo | $3,950/mo | $7,900/mo |
| Agency | $199/mo | $1,990/mo | $9,950/mo | $19,900/mo |
