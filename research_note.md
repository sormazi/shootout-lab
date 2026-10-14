# When does a goal handicap improve shootout balance?

Working research note • October 14, 2026 • Computational replication and candidate extensions

## Main result and interpretation

For independent constant kick probabilities p=.75 and q in [.60,.75], the round-completed (5,4) rule has smaller absolute win bias than a standard five-attempt shootout below q≈.6720991429, and larger bias above it. At q=.60, A wins with probability .5008192349 under (5,4), compared with .7282416667 under the standard rule. At p=q=.75, (5,4) instead gives A only .238752, while standard is .5. These are computed model outcomes, not observed results or established novel findings.

The contribution worth developing is a defensible uncertainty set and a constrained rule-selection method, supported by boundary calculations, behavior sensitivity, and a separate assessment of skill preservation. Equal winning chances are an appropriate benchmark for equally skilled teams. They are not a universal objective for unequal teams. A base p≠q alone does not identify an order effect.

## Source and rules

The replication target is the full February 2023 [Brams–Ismail–Kilgour MPRA manuscript](https://mpra.ub.uni-muenchen.de/116352/1/MPRA_paper_116352.pdf). The later [2024 published article](https://doi.org/10.1080/0025570X.2024.2378681) is a separate version; this audit does not claim to verify every change in that version. The source PDF was read in full. Source hashes and version identity are recorded in sources.json. The referenced ChatGPT history supplied the project brief but did not return a separate detailed build prompt; implementation scope was reconstructed from that brief and the manuscript.

Standard ABAB follows the mathematical stopping structure in [IFAB Law 10](https://www.theifab.com/laws/latest/determining-the-outcome-of-a-match/): up to five attempts each, early termination after any kick when catching up becomes impossible, then paired sudden death. Administrative matters such as retakes, player eligibility and disciplinary sanctions are outside this probability model.

Round-completed (m,n) requires goals, not a fixed number of attempts. At (4,2), the (5,4) contest continues. At the end of a pair, (5,3) is an A win, (4,4) a B win, and (5,4) starts sudden death next pair. If A reaches 5 on its kick, B still gets its kick in that pair. Sequential (m,n) ends immediately when a target is reached; B's final kick may be omitted. We report rounds started, total kicks, and kicks/2 separately.

ABBA and Catch-Up are explicitly experimental comparators applied to the standard five-attempt format, not the target rule. ABBA alternates the first team each pair, continuing into sudden death. Catch-Up sends the sole unsuccessful team first in the next pair; ties reverse the previous order. This matches the ordinary alternating-on-ties convention analyzed in the [shootout design literature](https://arxiv.org/abs/1806.01114). The name does not imply inclusion of every delayed or adjusted Catch-Up variant.

## Mathematical reconstruction

Let d=p(1−q)+(1−p)q. Sudden death repeats a tied pair with probability 1−d, so P(A wins | SD)=p(1−q)/d and E[SD pairs]=1/d. The ten-state (2,1) chain consists of five transient ordinary kick states, three transient sudden-death states, and two absorbing winners. It is exported as Figure 1.

Self-loop elimination gives the small-model probability p²(1−q)²/[d(p+q−pq)] and expected rounds (2p+q−3pq)/[d(p+q−pq)]. The exact solver reproduces both at multiple parameter values.

For general targets, write f_A(r)=C(r−1,m−1)p^m(1−p)^(r−m), the probability of A's mth success on kick r, and define f_B similarly for n. The three mutually exclusive events are: A reaches first, B reaches first, and both reach in round r. Their probabilities are f_A(r)Pr[Bin(r,q)<n], f_B(r)Pr[Bin(r,p)<m], and f_A(r)f_B(r). Sum the A-first event plus tied events multiplied by its SD win probability. Expected duration sums r times each first-hit event and (r+1/d) times the tie event. Corollary 1's early B hits and later B hits correctly partition its outcomes.

The Python implementation calculates the model by finite-state recurrence, independently checks the negative-binomial event sums, and validates a second browser implementation against Python propagation. Exact here means solving the finite equations to floating-point precision; it does not mean symbolic or arbitrary-precision arithmetic. Infinite event sums are truncated at 300 for cross-checks in the tested interior domain, not asserted as globally exact near 0 or 1.

Under the fixed-order iid assumptions, deliberately missing cannot improve a team's chance of attaining its target before the opponent. The manuscript's strategyproofness argument relies on those assumptions. No claim of strategyproofness is extended to arbitrary score-dependent psychological responses or adaptive kicking orders.

## Replication and source discrepancies

Table 4 reproduces at p=.75,q=.60: (5,4) 6.061068; (4,3) 4.710791; (3,2) 3.333333; (2,1) 1.851852 rounds. Each rounds to the printed entry. Table 3's computed balancing q values are .6004569470, .5617204053, .4943770289, and .3447656822 respectively. The manuscript's .50 for (3,2) is not the nearest two-decimal rounding (.49). It may be a graphical approximation.

The printed Proposition 2, manuscript pp.18–19, uses max{r,m−1} as B-first event's binomial upper bound. Counting A's fewer-than-m successes requires min{r,m−1}, treating coefficients beyond r as zero. Implementing the printed bound gives 10.405892 rounds for (5,4,.75,.60), instead of 6.061068. The corrected event count agrees with the independent recurrence and the table. This is an apparent manuscript typographical error, to discuss with the authors before treating it as a publication correction.

A narrative remark on p.20 says q=.60 equalizes (2,1) win chances. Its actual balance is .344766; at q=.60 the A win probability is .197531. The claimed 1.85 duration at q=.60 is nevertheless correct. These discrepancies are preserved, not silently overwritten. Corollary 1 was checked against the rendered formula and is valid.

Figures 2–6 are reconstructed from numerical curves. The sequential duration convention is not formally specified in the manuscript; Figure 6 reports both rounds started and kicks/2. Table 1's three stopping examples and Table 2's notation are documented above; their checkmark layout is not copied as a new figure.

## Candidate extension 1: uncertainty changes the preferred target

A finite exact minimax search compares standard ABAB with all goal-target rules 1≤n≤m≤8, subject to worst expected duration ≤8 rounds. On the nine scenarios p∈{.72,.75,.78},q∈{.57,.60,.63}, (5,4) leads: worst absolute bias .098737 and worst expected duration 6.235455. This is a finite-scenario result, not a continuous-rectangle certificate.

When the nine scenarios instead use p∈{.70,.75,.80} and q∈{p−.15,p−.075,p}, (1,1) leads with worst bias .182927 and worst duration 3.125. This does not justify replacing shootouts with a short race. It exposes a missing competition-depth constraint: minimizing imbalance alone can prefer a contest with less information about skill. The interface therefore offers a minimum B target, and the package includes a separate skill audit.

For skill probabilities .80 versus .70 with no slot effect, the stronger team wins .673113 under standard regardless of role. Under (5,4), it wins .394859 as A and .878720 as B, with a role-averaged .636789. Role bias is large and the average stronger-team win probability declines. A publishable objective should measure both order fairness and discrimination between unequal skill levels, along with duration and tails.

The equal-skill null is a diagnostic necessity: at p=q=.75, (5,4) incurs .261248 absolute bias, whereas standard and equal-target round-completed rules are exactly balanced. A robust set containing that null forces any proposed handicap to account for this failure case. This observation follows from the existing model; novelty is not claimed.

## Candidate extension 2: changing probabilities and Monte Carlo selection

The behavioral model sets logit conversion to team base logit + first/second slot effect − penalty per actual goal behind − fatigue per completed round, capped at round 10 + cyclic kicker offset. Synthetic lineup profiles represent 11 eligible kickers and repeat. All these coefficients are hypothetical sensitivity parameters, not estimates fitted to causal psychological mechanisms. Pressure uses actual score deficits during the target phase and resets to a neutral scoreboard at sudden death; the paired sudden-death outcome is judged within that pair. It does not use distance to the unequal targets; this choice must be challenged in subsequent work.

Forward probability propagation handles score- and round-dependent independent outcomes, preserving all reachable states through a declared horizon. It reports A-win lower and upper bounds differing by unresolved probability mass, exact survival probabilities at the chosen round, and restricted expected rounds/kicks. A small residual mass bounds win uncertainty; by itself it does not bound an infinite-horizon expected duration.

Monte Carlo additionally allows persistent, independent Gaussian logit shocks for team skill within each shootout. This introduces within-team outcome dependence through latent ability. It does not represent all possible correlation structures. Seeded simulations preserve censoring instead of assigning censored contests a winner. Wilson intervals are marginal Bernoulli intervals for A wins by the horizon; unresolved mass is reported separately.

The precomputed robust stress test uses equal base .75, slot effect {0,.1,.2}, trailing coefficient .1, latent σ=.15, and five candidates: standard ABAB, ABBA, Catch-Up, (5,4), and (4,4). It runs 6,000 contests per candidate/scenario, horizon 40. A union-bound Hoeffding margin supplies simultaneous 95% probability bounds across all 15 estimates. Conservative capped-duration bounds are displayed separately; probability and duration families each use 95%, so their joint guarantee is at least 90%, not 95%. Reusing seeds across candidates correlates estimates but does not invalidate the union bound. Python random and browser seeded generators differ; browser runs reproduce within the browser, not bit-for-bit against Python.

Catch-Up leads in this simulated finite set, with observed worst bias .010500 and simultaneous upper bias .033588. This ranking is not a proof that it dominates ABBA. An independent 30,000-contest holdout at slot effect .2 yields A wins .517200, Wilson interval [.511544,.522852], with zero observed censoring. The holdout evaluates one stress scenario; it does not confirm the full uncertainty set. Duration constraints in this MC search apply to E[min(R,40)], not infinite-horizon ER. A broader study needs joint uncertainty sets, out-of-sample stress cases, and convergence checks before recommending a rule.

## Empirical replication and sensitivity

The public [Vollmer–Schoch–Brandes (2024) study](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0315017) and [OSF material](https://osf.io/t6qj7/) provide independent observational evidence. The lab reproduces D1=60,287, D2=51,007, D3=45,402; 18,903 D2 kicks form 1,759 legally terminated alternating shootouts. First teams win 859/1,759=.48834565. The shootout bootstrap 95% interval is [.465591,.511654], using 2,000 replicates, seed 20261014. Big-5 national cups reproduce 241/513=.46978558. Each match passes sequence, goal count and terminal-score invariants. The upstream filtering flags are used; their original scraping and every cleaning decision have not been independently recreated.

Pooled kick conversion is .74638946. At equal team bases of this value, the iid standard gives .5 and (5,4) gives .240306. Assigning observed position conversions to each team's first five kickers, then the pooled value thereafter, gives standard .490612 and target .233003. Using all marginal lower/upper bootstrap endpoints produces target .242132/.222628 and standard .492234/.488624. These are transport sensitivity scenarios, not confidence bounds on counterfactual match outcomes. Later kicks are selected by surviving earlier kicks; no missing attempts are imputed as observations.

These results motivate uncertainty sets including zero and negative order effects. Observed score-state associations cannot be used directly as causal pressure coefficients: skill, goalie ability, kicker choice, tournament mix, stopping and coin-toss selection confound them. Shootout bootstrap preserves within-match dependence but assumes shootouts independent; repeated teams and competitions may call for coarser clustering. Historical standard-rule matches do not identify behavioral responses to handicapped rules. External validity is limited to the source's European men's competition coverage.

## Research next steps and novelty status

The boundary, finite-scenario robust outcomes, model audit, skill discrimination trade-off, and empirical transport scenarios are candidate starting points for discussion with Professor Brams. No claim of a first study or publishable novelty is made. Related work includes [Csató's design comparison](https://arxiv.org/abs/1806.01114), [Brams et al.'s Catch-Up analysis](https://arxiv.org/abs/1808.06922), and a [2025 European football preprint](https://arxiv.org/abs/2510.17641) reporting no evidence of kicking-order effects. This is a scoped source review, not an exhaustive citation search.

A credible next study should predefine a minimum contest depth and skill-discrimination floor; build an empirical uncertainty set with team/player controls and joint bootstrap draws; test out-of-sample tournaments; compare score deficits with target-distance pressure; study sudden-death changes and correlated kicks; and derive continuous-domain or certified numerical bounds. A randomized behavioral experiment under the new stopping rules would address transportability that historical data cannot settle. Discuss the manuscript discrepancies with the authors before presenting them as corrections to the later publication.
