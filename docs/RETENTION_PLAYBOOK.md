# Retention Playbook
### Data-backed recommendations for the founding team — August 2026

This document translates the analysis in `python/`, `sql/`, and `dashboard/`
into two decisions the brand can act on this quarter. Every recommendation
names the segment, the trigger behavior, a rollout timeline, and the metric
to track — "reduce discounts" is not a plan, so it doesn't appear here as one.

---

## 1. Promotional Sunset Plan

### The evidence
`sql/06_promotional_sunset_candidates.sql` splits every (value tier ×
category role) cell into its organic and discount-driven customers and
compares their average order value head-to-head. The logic: a segment is
only safe to wean off discounting if its **organic** customers already spend
as much as, or more than, its discount-driven ones — proof the discount
isn't the thing making them valuable.

| Tier | Category role | Organic avg order | Discount-driven avg order | Verdict |
|---|---|---|---|---|
| **Platinum** | Entry-point | $76.87 | $72.16 | **Sunset candidate** |
| **Platinum** | Retention | $75.42 | $74.71 | **Sunset candidate** |
| **Gold** | Retention | $65.02 | $64.02 | **Sunset candidate** |
| Gold | Entry-point | $65.24 | $65.66 | Keep promoting |
| Silver / Bronze | both | organic ≤ discount-driven | — | Keep promoting |

Two segments clear the bar cleanly: **all of Platinum** (187 customers, the
top ~4.8% of the base by composite value score) and **Gold customers buying
in Retention Categories** (Accessories; 433 customers). Together they
represent roughly **620 customers and 42.8% of the base's annualized
spend value is currently flowing through promo-dependent customers**
system-wide — this plan targets the slice of that spend the data says the
brand doesn't need to be discounting to keep.

### The recommendation

**Segment:** Platinum tier (all categories) + Gold tier within Accessories
(the brand's one Retention Category).

**Trigger behavior:** A customer enters the sunset track when they hit
Platinum status (composite value score ≥ 80, roughly top-quartile spend and
tenure) *or* when a Gold-tier customer's third Accessories purchase posts
without a discount code — both are observable in the data the brand already
collects, no new instrumentation required.

**What to do, concretely:**
1. **Weeks 1–2:** Stop auto-applying sitewide promo banners to logged-in
   Platinum accounts; leave promo codes redeemable if a customer actively
   seeks one out, but stop pushing them.
2. **Weeks 3–6:** A/B test replacing the discount incentive with a
   non-price loyalty perk for this segment (early access, free express
   shipping, priority restock alerts) on half the cohort; hold the other
   half on the current promo cadence as control.
3. **Weeks 7–12:** If the test cohort's repeat-purchase rate and average
   order value hold within 5% of control, roll the non-price perk out to
   the full sunset segment and formally retire promo eligibility for it.

**What this risks — stated plainly:** if the brand is wrong about *why*
these customers are loyal (e.g., their tenure predates the current promo
program and isn't causally about anything the brand controls), removing the
discount could shave off the ~40–42% of this segment that *is* currently
promo-dependent even though their spend levels don't require it. The 12-week
phased rollout with a live control group exists specifically to catch this
before it hits the full segment.

**Metric to track:** Segment-level average order value and 90-day repeat
purchase rate, compared test-vs-control weekly. A drop of more than 5% in
either metric in the test cohort is the stop condition — revert that
sub-segment to standard promo cadence.

**Estimated margin impact:** Removing blanket discount eligibility from
these ~620 customers, at even a conservative 15% average discount rate
observed in the promo-applied population, implies roughly **$45,000–$60,000
in annualized margin recovered** if spend behavior holds — the 12-week test
is designed to confirm that assumption before it's booked.

---

## 2. Ideal Customer Profile

### The evidence
`sql/05_ideal_customer_profile.sql` isolates the Platinum tier (187
customers) and benchmarks it against the full base on every dimension
marketing can target against.

| Dimension | Platinum | All customers | Gap |
|---|---|---|---|
| Avg. order value | $75.01 | $59.76 | **+25%** |
| Avg. tenure (previous orders) | 43.0 | 25.4 | **+69%** |
| Avg. satisfaction (review rating) | 4.35 / 5 | 3.75 / 5 | **+0.60 pts** |
| Promo-dependent | 42.2% | 43.0% | roughly equal — *not* discount-driven relative to the base |
| Subscribed | 28.9% | 27.0% | roughly equal |
| Avg. age | 45.0 | 44.1 | roughly equal |

Top attributes by share of the Platinum cohort:
- **Age:** 55+ (32%) and a fairly even spread from 25–54 — this is not a
  narrow youth-skewed segment.
- **Category:** Clothing (40%) and Accessories (33%) dominate; Footwear and
  Outerwear are minority categories for this group.
- **Payment method:** Credit Card (21%) and a close, even split across
  PayPal, Cash, and Debit Card — no single payment rail defines them.
- **Shipping:** Free Shipping (20%) and Store Pickup (18%) lead — this
  cohort is patient on delivery speed, unlike what a "VIP = wants it fast"
  assumption would predict.

### The profile

**The brand's ideal customer is not defined by how much they spend on any
single order — it's defined by how long they've kept coming back.** The
Platinum cohort's order values are only 25% above average, but their order
count is 69% above average, and their satisfaction is nearly a full point
higher. Value here is compounding tenure, not one big purchase.

**Actionable description for a marketing team:**
> A repeat shopper, most commonly 45+ but present across every adult age
> band, who buys Clothing or Accessories, is comfortable waiting on Free
> Shipping or Store Pickup rather than paying for speed, and who is just as
> likely to have arrived via a promo code as any other customer — meaning
> the brand did not have to buy this loyalty, it earned it through product
> and experience.

### How to acquire more of them

1. **Stop targeting acquisition spend by discount-responsiveness.** Since
   promo usage doesn't distinguish Platinum from the base, using
   "responded to a discount" as a lookalike-audience signal will not find
   more Platinum customers — it will mostly find Silver/Bronze bargain
   shoppers. Build lookalike audiences instead from *tenure and repeat
   Accessories/Clothing purchases* in the first 90 days.
2. **Lead acquisition creative with product and service quality, not
   price.** Free Shipping and Store Pickup adoption in this cohort suggests
   they value reliability and convenience over speed — a "we'll get it
   right" message will out-perform a "biggest sale of the season" message
   for this specific audience.
3. **Instrument a 90-day early-loyalty signal.** Because tenure is the
   dominant driver, the brand should flag any new customer who reaches 3+
   orders in Clothing/Accessories within 90 days as a Platinum-track
   candidate and route them into the non-price loyalty perk track from
   Section 1 immediately, rather than waiting for the full value score to
   accumulate.

---

## Known limitations (stated for transparency)

- The dataset is a customer-level snapshot, not a transaction log — spend
  and tenure metrics are proxies (see `python/feature_engineering.py`
  docstrings for exact derivation), not measured longitudinal behavior.
  Real order-level timestamps would sharpen every recommendation above.
- Margin estimates use an assumed average discount rate; the brand's actual
  gross margin by category should replace this before the number is used
  in a board deck.
- "Retention Category" vs. "Entry-Point Category" is determined by average
  tenure at the category level across the whole base — it does not yet
  account for cross-category purchase sequences (e.g., does a customer buy
  Clothing first and Accessories later, or the reverse?). That sequencing
  would need order-level data to establish causally.
