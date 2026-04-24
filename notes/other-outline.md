# Open Source North 2026 Talk Outline

## Working Title
Building Real-World Grafana Dashboards: From Data Source to Design

## Talk Goals
- Share practical experiences from shipping three production Grafana dashboards.
- Highlight the data onboarding steps for each dashboard and how to keep them reliable.
- Extract lessons learned that attendees can apply to their own dashboards.
- Close with a concise checklist of dashboard construction tips.

## Structure

### 1. Introduction (5 minutes)
- Quick personal context: Grafana usage, projects that drove the dashboards.
- Set expectations: three stories + actionable wrap-up.

#### Dashboard A: "Home Overview"
- First dashboard is a one showing the climate and air quality in my house.
- lessons learned:
  - Ask yourself "Why do I want this dashboard?"
  - Don't build what you can already use

#### Dashboard B: Mortgage Burndown
- Data sources: mortgage servicer CSV exports with payment history, amortization schedule calculator, household budget spreadsheet.
- Ingestion: Scheduled Python script normalizes CSV → pushes into Google Sheets; Grafana connects via Google Sheets data source plus static JSON for amortization projections.
- Lessons learned:
  - Mirror the language your bank uses so the dashboard aligns with monthly statements.
  - Visualize "payments made vs payments remaining" together to keep motivation visible.
  - Surface extra-payment scenarios with toggles so you can answer "what if we add $X more per month?" live.

#### Dashboard C: Classic Video Game Marathon Tracker
- Audience: marathon organizers, speedrunners, and livestream viewers.
- Data sources: OBS stats (bitrate/drop frames), runner split submissions via Google Form, donation tracker API, Twitch chat sentiment sample.
- Ingestion: Alloy instance scrapes OBS exporter; Google Form responses land in Sheets and are mirrored via Grafana data source; donation API polled through simple HTTP JSON data source; chat sentiment summarized with lightweight Python worker pushing to Prometheus remote_write.
- Lessons learned:
  - Build a "run card" panel per game with fields for estimate, actual, and delta so commentators can react instantly.
  - Cache donation totals during API hiccups to keep on-stage confidence high.
  - Create a calm/night mode theme; marathon venues often dim lights and bright panels cause fatigue.

### 3. Wrap-Up: Dashboard Construction Tips (5 minutes)
- Reusable checklist:
  1. Start with audience questions; panels are answers.
  2. Validate data freshness and reliability before design polish.
  3. Apply consistent naming/labeling conventions across sources.
  4. Reserve space for annotations and incident context.
  5. Iterate with stakeholders using staging folders before production.
- Call to action: share your own dashboard war stories, link to repo/resources.

### 4. Q&A (5 minutes)
- Invite questions about data onboarding, panel choices, or Grafana plugin ecosystem.
- Have backup demo queries ready (e.g., Loki logs drilldown, BigQuery explorer).
