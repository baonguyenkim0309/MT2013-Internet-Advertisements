# Multiple-Testing Analysis of Textual Indicators in the Internet Advertisements Dataset

![Course](https://img.shields.io/badge/Course-MT2013%20Probability%20%26%20Statistics-164B77?style=flat-square)
![University](https://img.shields.io/badge/HCMUT-Faculty%20of%20CSE-005BAC?style=flat-square)
![Language](https://img.shields.io/badge/Language-Base%20R-276DC3?style=flat-square&logo=r&logoColor=white)
![Dataset](https://img.shields.io/badge/Dataset-UCI%20%2F%20Kaggle%20%235-20BEFF?style=flat-square)

Major Assignment Repository for **MT2013 – Probability and Statistics** (Class **CC04**, Project Group **5**, Semester 1 – Academic Year 2026–2027) at **Ho Chi Minh City University of Technology (HCMUT)**.

- **Instructor:** Dr. Nguyễn Tiến Dũng (Faculty of Applied Sciences)
- **Student Faculty:** Faculty of Computer Science and Engineering
- **Assigned Dataset:** Internet Advertisements (Dataset #5)

---

## Overview

Web-page images carry both geometric dimensions and textual/HTML metadata (URLs, anchor links, `alt` attributes, and captions). Testing **1,554 binary textual indicators** individually at $\alpha = 0.05$ inflates false discoveries, while overlapping HTML/URL tokens induce dependence across tests and sparse counts invalidate large-sample $\chi^2$ approximations.

This project investigates marginal associations between all 1,554 textual indicators and advertisement status (`ad.` vs. `nonad.`) across **3,279 observations** ($n_1 = 459$ Ad; $n_0 = 2,820$ Non-ad) using:
1. **Feature-wise two-sided Fisher's exact tests** for exact inference on sparse $2 \times 2$ contingency tables.
2. **Benjamini–Yekutieli (BY)** False Discovery Rate (FDR) control at $q = 0.05$ as the primary procedure (valid under arbitrary dependence), benchmarked against **Benjamini–Hochberg (BH)** and **Bonferroni** FWER control.

---

## Key Results

| Procedure | Error Criterion | Nominal Level | Discoveries ($m = 1,554$) | Share of Family |
| :--- | :---: | :---: | :---: | :---: |
| **Benjamini–Yekutieli (BY)** *(Primary)* | FDR | $q = 0.05$ | **447** | **28.76%** |
| **Benjamini–Hochberg (BH)** | FDR | $q = 0.05$ | 489 | 31.47% |
| **Bonferroni** | FWER | $\alpha = 0.05$ | 379 | 24.39% |

- The discovery sets are strictly nested: $\mathcal{D}_{\text{Bonferroni}} \subset \mathcal{D}_{\text{BY}} \subset \mathcal{D}_{\text{BH}}$ ($379 < 447 < 489$).
- Among the **447 BY discoveries**, **365** occur more frequently in advertisements ($\hat{\Delta}_j > 0$) and **82** occur more frequently in non-advertisements ($\hat{\Delta}_j < 0$).
- The largest marginal occurrence-rate difference is observed for `X1243` (`ancurl*com`), present in **41.18%** of Ad images versus **0.64%** of Non-ad images ($\hat{\Delta} = +0.40538$, $p_{\text{BY}} = 1.55 \times 10^{-150}$).

### Visual Highlights

<table>
  <tr>
    <td align="center" width="50%">
      <img src="figures/Figure3_width_boxplot.png" alt="Image width by class" width="100%" /><br />
      <sub><b>Figure 1.</b> Distribution of observed image widths by class (Ad vs. Non-ad).</sub>
    </td>
    <td align="center" width="50%">
      <img src="figures/Figure2_occurence_rates.png" alt="Occurrence rate differences vs support" width="100%" /><br />
      <sub><b>Figure 2.</b> Occurrence-rate difference (Ad minus Non-ad) vs. feature support (log scale).</sub>
    </td>
  </tr>
</table>

---

## Repository Structure

```text
MT2013-Internet-Advertisements/
├── add.csv                         # Raw dataset (3,279 rows × 1,560 columns)
├── ad.names                        # Original UCI attribute schema & token names
├── MT2013_analysis.R               # Complete, self-contained Base R analysis pipeline
├── MT2013_cleaned.csv              # Validated & standardized dataset exported by script
├── figures/                        # Generated PNG plots used in the report
│   ├── Figure1_support_feature.png
│   ├── Figure2_occurence_rates.png
│   └── Figure3_width_boxplot.png
├── outputs/
│   └── T07_inference_results.csv   # Full table of 1,554 Fisher tests & adjusted p-values
├── report/                         # Final PDF report (and LaTeX source, if included)
└── README.md
```

---

## Reproducibility

The entire pipeline uses **Base R** only — no external packages are required.

```bash
# 1. Clone the repository
git clone https://github.com/baonguyenkim0309/MT2013-Internet-Advertisements.git
cd MT2013-Internet-Advertisements

# 2. Run the full analysis pipeline
Rscript MT2013_analysis.R
```

Executing `MT2013_analysis.R` reads `add.csv` from the root directory and reproduces `MT2013_cleaned.csv`, all PNG figures in `figures/`, and `outputs/T07_inference_results.csv`.

---

## Contributors (Class CC04 – Group 5)

| Member | Student ID | Main Responsibilities |
| :--- | :---: | :--- |
| **Nguyễn Anh Minh Tuệ** | `2353281` | Data auditing support; discussion, limitations, and extensions (Section 6) |
| **Lê Quốc Bảo** | `2550264` | Dataset review; descriptive statistics and visualizations (Sections 1 & 4) |
| **Nguyễn Kim Bảo** | `2550265` | Research design; statistical theory, inference, and integration (Sections 2 & 5) |
| **Nguyễn Lâm Vĩnh Khang** | `2550297` | Schema validation; data preprocessing; data and code documentation (Sections 3 & 7) |

<sub>*Note: The complete official class roster (including withdrawn members with 0% contribution) is documented in the submitted PDF report.*</sub>

---

## Data Source & References

- **UCI Machine Learning Repository:** N. Kushmerick (1999), *Internet Advertisements*, DOI: [10.24432/C5V011](https://doi.org/10.24432/C5V011).
- **Kaggle Mirror (`add.csv`):** [UCI ML – Internet Advertisements Data Set](https://www.kaggle.com/datasets/uciml/internet-advertisements-data-set/data).
- **Key Methodological References:**
  - Kushmerick, N. (1999). *Learning to remove internet advertisements*. AGENTS '99, pp. 175–181.
  - Benjamini, Y., & Hochberg, Y. (1995). *Controlling the false discovery rate: A practical and powerful approach to multiple testing*. JRSS-B, 57(1), 289–300.
  - Benjamini, Y., & Yekutieli, D. (2001). *The control of the false discovery rate in multiple testing under dependency*. The Annals of Statistics, 29(4), 1165–1188.