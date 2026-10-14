# Shootout Fairness Research Laboratory

A reproducible implementation of the February 2023 Brams–Ismail–Kilgour manuscript with separate empirical replication and qualified candidate extensions. Read [the research note](research_note.md) first. The repository includes the complete code, source data, results, and interface.

![Interactive laboratory](docs/laboratory-preview.jpg)

[Download the complete research archive](downloads/shootout-research-laboratory.zip). Open `dist/index.html` directly, or serve `dist/` locally; the interface is buildless and offline with bundled results. It sends no data to external services.

## Run

Python 3.9+; no dependencies for numerical or empirical computation.

```sh
cd shootout-lab
python3 -m unittest discover -s tests -v
python3 run_experiments.py
python3 empirical.py --bootstrap 2000 --seed 20261014
python3 extension_analysis.py
python3 build_artifacts.py
python3 -m http.server 8000 --directory dist
```

Visit http://localhost:8000. `build_artifacts.py` rebuilds the interface fixtures from current results and note. Download buttons export the current scenario and search, and the shipped package supplies authoritative Python Monte Carlo outputs.

Optional research figures:

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements-plots.txt
.venv/bin/python run_experiments.py --plots
.venv/bin/python plot_chain.py
python3 build_artifacts.py
```

`results/` includes the tables, figure curves, crossover boundary sweep, exact finite-scenario minimax searches, MC validation and search, behavioral sensitivities, empirical transport and skill audit. `data/` includes authentic source records, normalized observed kicks, source R analysis and provenance SHA-256 hashes. `sources.json` identifies all sources. `tests/` checks closed forms, event counts, conservation, stopping, symmetry, Monte Carlo and browser/Python parity.

Core model probabilities must be strictly between 0 and 1; singular nonabsorbing endpoints are rejected. The interactive target domain is 1..12. The exact search domain in precomputed experiments is 1≤n≤m≤8. Endpoints q=0,1 are not asserted solved; figures use .01..99.

Exact solver: iid finite-state equations to machine precision. Changing-probability solver: finite-horizon propagation and unresolved mass. MC: seeded capped trajectories, censoring, Wilson intervals, simultaneous Hoeffding bounds for finite robust searches. MC duration feasibility is for capped duration only. Continuous uncertainty domains are not certified. Skill, order and empirical transport assumptions are explicitly distinct in the note.

The browser and Python versions use separate seeded generators and will not produce identical MC samples. Browser analytical values were compared with Python fixtures at 15 iid/behavioral scenarios with maximum discrepancy <1e-10. All tests are research invariants, not snapshots of implementation.

## Reproduction audit

Table 4 reproduces to printed precision. The balancing (3,2) root is .494377, versus manuscript .50. Proposition 2's B-first count needs `min(r,m−1)` instead of printed `max(r,m−1)`. Corollary 1 is valid. The manuscript narrative q=.60 balance for (2,1) is inconsistent with its actual root .344766. Figure 6 sequential duration convention is ambiguous; both rounds started and kicks/2 are supplied.

## Source rights

Original laboratory code and writing: MIT (`LICENSE`). Source authors retain rights to upstream manuscript/data/code. Source data are public replication materials; a separate dataset license was not located. The browser download package distributes code and aggregate analysis and links to the upstream data. This private repository also contains the full downloaded replication inputs. The complete local archive includes the downloaded data for this research task. Check their redistribution terms before making that raw-data archive public.

A complete `downloads/shootout-research-laboratory.zip` is included. The website's download is a smaller code/results package with a source retrieval script, excluding raw data and manuscript. Run `python3 fetch_sources.py` to retrieve the source CSV and verify its expected hash, then empirical.py to regenerate analysis. Raw downloaded sources are never executed.
