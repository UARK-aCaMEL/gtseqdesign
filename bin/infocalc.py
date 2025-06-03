#!/usr/bin/env python3
"""
infocalc.py  (single ORCA column)
========================================

Python re‑implementation of Rosenberg et al. (2003) **Infocalc** using only
ADMIXTURE outputs:

* **.P**  – L × K allele‑frequency matrix (rows = loci, columns = clusters)
* **.Q**  – N × K ancestry‑coefficient matrix (optional)

If a `.Q` file is supplied the **prior population probabilities** `q_i` are
set to the sample mean of each column of .Q. Otherwise the prior is uniform
(`1/K`).

For every locus the script reports

    locus_idx   In     Ia     ORCA

| column | description | prior used |
|--------|-------------|------------|
| **In**  | informativeness for assignment (eq. 4) | `q_i` (sample‑derived or uniform) |
| **Ia**  | informativeness for ancestry coefficients (eq. 14) | always **uniform** (definition) |
| **ORCA**| diploid optimal assignment accuracy (eq. 12, L = 1) | same `q_i` as **In** |

Usage
-----
```bash
python infocalc_from_PQ.py \
        --pfile  mydata.5.P   \
        --qfile  mydata.5.Q   # optional, choose priors
```
If `--qfile` is omitted the prior is uniform and **In** = **Ia** = log‑likelihood
reductions under that assumption.
"""

import argparse, math, sys
import numpy as np

# ------------------------------------------------ utility functions


def factorial(n: int) -> int:
    return math.prod(range(1, n + 1)) or 1


def unsigned_stirling_first(n: int, k: int) -> int:
    """Unsigned Stirling number of the first kind |s(n,k)| (small n,k)."""
    if k == 0:
        return int(n == 0)
    if k == n:
        return 1
    s = np.zeros((n + 1, k + 1), dtype=object)
    s[0, 0] = 1
    for i in range(1, n + 1):
        for j in range(1, min(i, k) + 1):
            s[i, j] = s[i - 1, j - 1] + (i - 1) * s[i - 1, j]
    return int(s[n, k])


# ------------------------------------------------ In (assignment)


def In_locus(p_vec: np.ndarray, q: np.ndarray) -> float:
    """Rosenberg eq. 4 with arbitrary priors q_i."""
    info = 0.0
    for allele in (p_vec, 1.0 - p_vec):
        p_bar = (q * allele).sum()
        if p_bar in (0.0, 1.0):
            continue
        info -= p_bar * math.log(p_bar)
        info += (q * allele * np.log(allele, where=allele > 0)).sum()
    return info


# ----------------------------------------------- Ia (uniform prior)


def Ia_locus_uniform(p_vec: np.ndarray) -> float:
    """Rosenberg eq. 14. Returns −9999 when denominator → 0."""
    K = p_vec.size
    if K > 24:
        return float("nan")
    S = unsigned_stirling_first(K - 1, 2)
    Kfac = factorial(K)
    Ia = 0.0
    for allele in (p_vec, 1.0 - p_vec):
        pj = allele.mean()
        if pj in (0.0, 1.0):
            continue
        Ia += pj * (1.0 - math.log(pj) - S / Kfac)
        for i, p_ij in enumerate(allele):
            if p_ij == 0.0:
                continue
            denom = K * np.prod([p_ij - allele[r] for r in range(K) if r != i])
            if denom == 0.0:
                return -9999.0
            Ia += (p_ij**K) * math.log(p_ij) / denom
    return Ia


# ------------------------------------------- ORCA diploid (biallelic)


def orca_diploid(p_vec: np.ndarray, q: np.ndarray) -> float:
    """Diploid genotype optimal assignment (eq. 12, L = 1)."""
    P_A = p_vec
    P_B = 1.0 - p_vec
    geno = np.stack([P_A**2, 2 * P_A * P_B, P_B**2])  # AA, AB, BB
    return sum((q * geno[g]).max() for g in range(3))


# ------------------------------------------------------------- main


def main():
    ap = argparse.ArgumentParser(
        description="Compute In, Ia and diploid ORCA from ADMIXTURE .P/.Q"
    )
    ap.add_argument("--pfile", required=True, help=".P file (L × K)")
    ap.add_argument("--qfile", help=".Q file (N × K) – optional")
    ap.add_argument("--outfile", default="infocalc.tsv")
    args = ap.parse_args()

    # ---- read .P
    P = np.loadtxt(args.pfile)
    L, K = P.shape

    # ---- population priors q_i
    if args.qfile:
        Q = np.loadtxt(args.qfile)
        if Q.shape[1] != K:
            sys.exit(".Q columns ≠ K clusters in .P")
        q = Q.mean(axis=0)
        q /= q.sum()
        print("Priors from .Q (mean of rows)")
    else:
        q = np.full(K, 1.0 / K)
        print("Using uniform priors (no .Q provided)")

    q_uniform = np.full(K, 1.0 / K)

    # ---- allocate result arrays
    In_vals = np.empty(L)
    Ia_vals = np.empty(L)
    ORCA_vals = np.empty(L)

    # ---- compute per locus
    for i in range(L):
        p_vec = P[i]
        In_vals[i] = In_locus(p_vec, q)
        Ia_vals[i] = Ia_locus_uniform(p_vec)
        ORCA_vals[i] = orca_diploid(p_vec, q)  # same priors as In

    # ---- write TSV
    with open(args.outfile, "w") as fh:
        fh.write("locus_idx\tIn\tIa\tORCA\n")
        for idx in range(L):
            fh.write(
                f"{idx}\t{In_vals[idx]:.10g}\t{Ia_vals[idx]:.10g}\t{ORCA_vals[idx]:.10g}\n"
            )

    print(f"Done → {args.outfile}   (L={L}, K={K})")
    print("q_i priors:", " ".join(f"{x:.4f}" for x in q))


if __name__ == "__main__":
    main()
