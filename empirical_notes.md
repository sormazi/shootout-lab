# Empirical sensitivity and replication

The laboratory includes actual public replication data, not invented observations. The source is Vollmer, Schoch and Brandes (2024), [Penalty shoot-outs are tough, but the alternating order is fair](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0315017), DOI 10.1371/journal.pone.0315017, with [OSF replication material](https://osf.io/t6qj7/). This is a separate empirical study from the Brams–Ismail–Kilgour theoretical manuscript. Its sample does not validate counterfactual (m,n) rules.

## What is reproduced from individual records

Running `python3 empirical.py --bootstrap 2000 --seed 20261014` uses only the Python standard library and produces `data/empirical_results.json`. Data flags reproduce D1=60,287, D2=51,007, D3=45,402. D2 contains 18,903 shootout kicks across 1,759 complete shootouts. The first team wins 859 (48.8346%), agreeing with the published rounded 48.83%. National cups in England, Spain, Germany, Italy and France reproduce 241 wins in 513 shootouts (46.9786%), agreeing with 46.98%. Mean shootout conversion is 74.6389%; 30.1308% continue beyond ten kicks.

For the overall first-team share, the 95% Wilson interval is [46.5037%,51.1705%]. The seeded whole-shootout percentile bootstrap interval is [46.5591%,51.1654%]. The sampling unit is the entire shootout, preserving dependence among its kicks and their stopping pattern. These intervals assume shootouts are independent; repeated teams, players and competitions may require coarser or multiway clustering. Neither interval proves perfect fairness, and neither identifies a causal order effect. A 60% first-team winning probability lies well outside these intervals for this selected population, conditional on the sampling assumptions.

Every D2 shootout is independently validated for unique contiguous kick order, alternating teams, binary outcome labels, legal early termination, unequal terminal scores, and consistency between reconstructed goals and the source terminal scoreboard. A failed invariant raises an error. `data/d2_shootout_kicks.csv` is the transparent normalized subset; `data/provenance.json` records download URLs and SHA-256 hashes. The original published R script is retained for audit, but the laboratory's analysis does not execute it.

## Position and score-state sensitivity

The output includes conversion estimates and shootout-bootstrap intervals for all observed kick positions, and for each team's behind/level/ahead score state before its kick. The first six positions all have 1,759 observed attempts. A1 converts 77.2030%, B1 76.2933%, A2 72.5412%, B2 75.8954%, A3 75.0426%, B3 74.0193%. B5 is observed in only 998 shootouts and converts 75.8517% among those selected survivors. These descriptive estimates are useful alternative scenarios for a simulation, with sample sizes shown alongside every estimate.

Later kicks are observed only in shootouts that survive to them. Kicker ranking, goalkeeper quality, team composition, tournament mix, score history and strategic selection all confound conversion differences. In particular, a lower success rate when trailing must not be assigned directly to psychological pressure. The selected survivors at B5 are not a randomized sample of all B5 kickers; the 761 unobserved B5 attempts have no observed outcomes. No missing potential kicks are imputed as observed data.

## What can and cannot be calibrated

Use empirical rates as descriptive anchors and report sensitivity across their uncertainty ranges. Observed 74.64% conversion supports scenarios near 0.75 in this sample. Preserve the theoretical manuscript's assumptions separately. Replaying these per-position rates under a different order assumes rates transport to the new rule; that assumption is untested. The dataset contains ordinary alternating shootouts and excludes inconsistent/nonalternating orders, so it supplies no direct empirical outcomes for handicapped (m,n) or alternative sequencing rules.

To estimate a causal pressure parameter, a subsequent study would need a defensible identification design and adequate player/team skill controls, coin-toss choice information, out-of-sample evaluation, and uncertainty propagated into rule choice. A match bootstrap quantifies sampling uncertainty; it does not solve confounding, stopping selection, cleaning selection, or model misspecification. The imported flags follow the source authors' filtering; this laboratory does not claim independently to have recreated their original scraping and all cleaning decisions. Raw-data filtering changes and repeated-team dependence should be examined before a publication claim.

The article's European men's competition coverage and historical window constrain external validity. A robust rule that includes a zero or reversed order-effect scenario is more empirically defensible than optimizing only a large positive first-mover advantage. This is a methodological motivation for model sensitivity, not a finding that a particular new rule improves actual matches.

## Attribution and distribution

Source files were downloaded from the OSF GitHub provider on October 14, 2026. The upstream README identifies the replication material and points to `R_analysis.R`. The PLOS article is CC BY; a separate dataset/code license was not located in the inspected OSF metadata or README. Retain attribution and verify source redistribution terms before publishing the raw data on a public website.
