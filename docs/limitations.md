# Limitations, Assumptions, and Next Steps

This project is designed to be a clean, explainable Databricks SQL lakehouse demo.
The NFL context is the attention hook; the core deliverable is a reproducible Bronze → Silver → Gold pipeline.

That said, sports outcomes are chaotic. This section is intentionally honest so readers trust the work.

---

## What This Model Uses (Today)
The current Gold model is built from:
- Team-level point differential (baseline strength)
- Recent form (last-N games)
- Home-field advantage (fixed constant)
- Observed scoring volatility (sigma from completed games)
- Optional: market odds features are stored and joinable

The model produces:
- team spread ratings (neutral/home/away vs league average)
- matchup win probability

---

## What This Model Does NOT Include (Yet)

### 1) Injuries / availability (biggest missing piece)
Examples:
- QB status changes probability dramatically
- OL/DL injuries can flip a matchup
- defensive secondary availability affects passing efficiency

**Why it matters:** your predicted win probability can be directionally right but off by a lot.

### 2) Snap counts / depth chart changes
Not all “active” players are equally involved.
Snap counts show who actually played and how much.

### 3) Play-by-play efficiency metrics (EPA)
Point differential is coarse.
EPA (Expected Points Added) can describe team strength more accurately.

### 4) Coaching changes and scheme matchups
Some teams are built to exploit specific weaknesses.
This model doesn’t encode matchup-specific style.

### 5) Market timing / last-second odds movement
If odds were collected earlier in the week, they may not reflect late injuries or public information.

### 6) Weather uncertainty for future games
Future games can have missing `temp_f` and `wind_mph`.
The Gold weather features fill these values with safe defaults and a `weather_known` flag.

---

## Modeling Assumptions (Important)
- **Home field advantage** is treated as a constant (example: +1.5 points).
- **Recent form weighting** is a fixed factor (example: 0.7).
- **Win probability mapping** uses observed margin volatility (sigma) from completed games.
- **Team strength scale** is derived from the dataset; it may not match Vegas spread scale without calibration.

---

## Why These Limitations Don’t “Kill” the Project
Recruiters should care about:
- pipeline design
- data modeling choices
- validation checks
- reproducibility
- communication

Even a simple model is valuable if it’s:
- cleanly engineered
- auditable
- explainable
- easy to extend

---

## Next Steps (If Expanding the Project)
1) Add injury + availability features (Bronze → Silver → Gold)
2) Add snap counts and QB starters
3) Add play-by-play EPA and pace metrics
4) Calibrate “spread rating” vs market spreads (regression)
5) Add automated refresh + dashboard publish schedule
6) Package into a weekly “NFL Lakehouse Update” workflow
