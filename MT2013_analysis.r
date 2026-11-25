# MT2013 - Multiple-Testing Analysis of Textual Indicators
# in the Internet Advertisements Dataset
# Class CC04 - Project Group 5
# Run: Rscript MT2013_analysis.R (from the directory containing add.csv)

# Section 3 - Data Preprocessing ----
# Lead: Nguyễn Lâm Vĩnh Khang; data auditing support: Nguyễn Anh Minh Tuệ

# 3.1 Data Loading and Initial Inspection ----
load_data <- function() {
  file_path <- "add.csv"

  if (!file.exists(file_path)) {
    stop("File not found at: ", file_path)
  }

  df <- read.csv(
    file_path,
    na.strings = c("?", "NA", "", " ?"),
    strip.white = TRUE,
    stringsAsFactors = FALSE
  )

  return(df)
}

df <- load_data()

# Verify dataset dimensions
n_rows <- nrow(df)
n_cols <- ncol(df)
n_features <- n_cols - 2 # Exclude index and label columns

if (n_rows != 3279 || n_cols != 1560) {
  stop(
    "Unexpected dimensions: ",
    n_rows, " rows, ", n_cols, " columns. ",
    "Expected: 3279 rows, 1560 columns."
  )
}

# Inspect sample records and data types
cat("Number of observations:", n_rows, "\n")
cat("Number of columns:", n_cols, "\n")
cat("Number of features:", n_features, "\n\n")

cat("First 5 rows (first 10 columns):\n")
print(head(df[, 1:min(10, n_cols)], 5))
cat("\nDatatype distribution:\n")
print(table(sapply(df, class)))

# Examine Class distribution
cat("AD/NON-AD count:\n")
label_col_name <- names(df)[ncol(df)]
label_counts <- table(df[[label_col_name]], useNA = "ifany")
print(label_counts)

# 3.2 Variable Selection and Mapping ----

feature_cols <- paste0("X", 4:1557)
analysis_df <- df[, paste0("X", 0:1558)] # Exclude the index column
names(analysis_df)[1:4] <- c("Height", "Width", "Aratio", "Local")
names(analysis_df)[1559] <- "Class"

# 3.3 Data Validation ----

# Check binary feature values
cat("Anomaly check:...\n")
binary_cols <- names(df)[5:(ncol(df) - 1)]
anomalous_cols <- list()

for (col in binary_cols) {
  unique_vals <- unique(df[[col]])

  # Identify values outside 0, 1, and NA
  invalid <- unique_vals[!is.na(unique_vals) & !(unique_vals %in% c(0, 1, "0", "1"))]

  if (length(invalid) > 0) {
    anomalous_cols[[col]] <- invalid
  }
}

if (length(anomalous_cols) == 0) {
  cat("No anomalies found. Only 1, 0 and NA.\n")
} else {
  cat("Anomalies found in column(s)\n")
  print(anomalous_cols)
}

# Check analysis requirements
for (col in c("Height", "Width", "Aratio", "Local", feature_cols)) {
  x <- analysis_df[[col]]
  if (!all(is.na(x)) && !is.numeric(x)) {
    stop("Expected numeric data in column: ", col)
  }
  if (any(!is.na(x) & !is.finite(x))) {
    stop("Non-finite value in column: ", col)
  }
}

valid_classes <- c("ad.", "nonad.")
if (any(!is.na(analysis_df$Class) &
        !(analysis_df$Class %in% valid_classes))) {
  stop("Class must contain ad., nonad., or NA.")
}
if (!all(valid_classes %in% analysis_df$Class)) {
  stop("Both ad. and nonad. classes are required.")
}

for (col in c("Height", "Width", "Aratio")) {
  if (any(analysis_df[[col]] <= 0, na.rm = TRUE)) {
    stop("Inspect non-positive values in column: ", col)
  }
}

for (col in c("Local", feature_cols)) {
  x <- analysis_df[[col]]
  if (any(!is.na(x) & !(x %in% c(0, 1)))) {
    stop("Column must contain only 0, 1, or NA: ", col)
  }
}

# 3.4 Missing Values and Duplicate Records ----

# Retain repeated profiles in the primary analysis.
missing_counts <- colSums(is.na(analysis_df))
n_incomplete <- sum(!complete.cases(analysis_df))
missing_summary <- data.frame(
  variable = names(analysis_df),
  n_missing = as.vector(missing_counts),
  missing_percent = round(100 * as.vector(missing_counts) / nrow(analysis_df), 2)
)
duplicate_rows <- duplicated(analysis_df)
n_duplicates <- sum(duplicate_rows)

# Report preprocessing results
cat("\n=== Section 3 - Data Preprocessing ===\n")
cat("Input rows:", nrow(analysis_df), "\n")
cat("Rows with at least one missing value:", n_incomplete, "\n")
cat("Rows with missing Class:", sum(is.na(analysis_df$Class)), "\n")
cat("Textual indicators:", length(feature_cols), "\n")
cat("Missing textual values:", sum(missing_counts[feature_cols]), "\n")
cat("Duplicate rows after the first occurrence (retained):", n_duplicates, "\n")
cat("\nVariables with missing values:\n")
print(missing_summary[missing_summary$n_missing > 0, ], row.names = FALSE)

# 3.5 Preparation of Analysis Data ----

write.csv(analysis_df, "MT2013_cleaned.csv", row.names = FALSE, na = "NA")

# Section 4 - Descriptive Statistics ----
# Lead: Lê Quốc Bảo

y <- analysis_df$Class

figure_dir <- "figures"
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# 4.1 Class Distribution ----
class_n <- table(factor(y, levels = c("ad.", "nonad.")))
print(data.frame(Class = c("Ad", "Non-ad"), N = as.integer(class_n),
                 Percent = round(100 * as.integer(class_n) / length(y), 2)))

# 4.2 Image Geometry and the Local Indicator ----

table1 <- data.frame()
for (g in c("ad.", "nonad.")) {
  for (v in c("Height", "Width", "Aratio")) {
    x <- analysis_df[[v]][y == g]
    z <- x[!is.na(x)]
    table1 <- rbind(table1, data.frame(
      Variable = v, Class = if (g == "ad.") "Ad" else "Non-ad",
      Valid_n = length(z), Missing_pct = round(100 * mean(is.na(x)), 2),
      Mean = round(mean(z), 2), SD = round(sd(z), 2),
      Median = round(median(z), 2), IQR = round(IQR(z), 2)
    ))
  }
}
cat("\nTable 4.1 - Geometry summary by class\n")
print(table1, row.names = FALSE)

# Figure 4.1 (original PNG filename retained).
# Width by Class: descriptive only, omitting missing Width.
width_df <- analysis_df[!is.na(analysis_df$Width), c("Width", "Class")]
width_df$Class <- factor(width_df$Class, levels = c("ad.", "nonad."),
                         labels = c("Ad", "Non-ad"))
png(file.path(figure_dir, "Figure3_width_boxplot.png"),
    width = 1600, height = 1100, res = 220)
par(mar = c(5, 5, 2, 1.5))
boxplot(Width ~ Class, data = width_df, col = c("#85B8C8", "#D2DEE5"),
        border = "#50616A", xlab = "Advertisement class",
        ylab = "Image width (pixels)")
dev.off()

# Local completeness by class.
cat("\nLocal by Class (0 / 1 / NA):\n")
print(table(y, analysis_df$Local, useNA = "ifany"))

# 4.3 Distribution of Textual Feature Support ----

# Support: number of observed 1s in each indicator.
X <- as.matrix(analysis_df[, feature_cols, drop = FALSE])
k_j <- colSums(X == 1)
cat("\nFeature support summary:\n")
print(summary(k_j))
cat("SD:", round(sd(k_j), 2), "\n")

support_groups <- cut(k_j, breaks = c(-1, 0, 5, 20, 100, Inf),
                      labels = c("0", "1-5", "6-20", "21-100", ">100"))
support_counts <- table(support_groups)
print(support_counts)

# Figure 4.2
png(file.path(figure_dir, "Figure1_support_feature.png"),
    width = 1800, height = 1000, res = 220)
par(mar = c(5, 5, 2, 1.5))
bp <- barplot(support_counts, col = "#016783", border = NA,
              xlab = "Feature support (observations per indicator)",
              ylab = "Number of textual indicators",
              ylim = c(0, max(support_counts) * 1.15))
text(bp, support_counts, labels = support_counts, pos = 3)
dev.off()

# 4.4 Differences in Occurrence Rates Between Classes ----

# Rate differences are descriptive, not p-values.
ad_rate <- colMeans(X[y == "ad.", , drop = FALSE])
nonad_rate <- colMeans(X[y == "nonad.", , drop = FALSE])
rate_df <- data.frame(feature = feature_cols, support = k_j,
                      ad_rate = ad_rate, nonad_rate = nonad_rate,
                      difference = ad_rate - nonad_rate, row.names = NULL)
cat("\nFeatures more common in Ad / Non-ad:",
    sum(rate_df$difference > 0), "/", sum(rate_df$difference < 0), "\n")
cat("Both occurrence rates < 5%:",
    sum(ad_rate < 0.05 & nonad_rate < 0.05), "\n")

# Figure 4.3: omit zero support from the logarithmic x-axis.
show <- rate_df$support > 0
png(file.path(figure_dir, "Figure2_occurence_rates.png"),
    width = 1800, height = 1200, res = 220)
par(mar = c(5, 5, 2, 1.5))
plot(rate_df$support[show], rate_df$difference[show],
     log = "x", pch = 16, cex = 0.65,
     col = rgb(0.12, 0.35, 0.65, 0.45),
     xlab = "Textual feature support (log scale)",
     ylab = "Ad rate - Non-ad rate")
abline(h = 0, col = "#B45143", lty = 2, lwd = 2)
dev.off()

cat("\nSection 4 complete: 3 PNG figures saved to", figure_dir, "\n")

# Section 5 - Statistical Inference ----
# Lead: Nguyễn Kim Bảo

# 5.1 Feature-wise Fisher's Exact Tests ----

alpha <- 0.05

# Two-sided Fisher tests; retain rare/constant features and duplicate rows.
class_group <- factor(analysis_df$Class, levels = c("ad.", "nonad."))
results <- data.frame(
  Feature = feature_cols,
  Support = integer(length(feature_cols)),
  Ad_rate = numeric(length(feature_cols)),
  Non_ad_rate = numeric(length(feature_cols)),
  Difference = numeric(length(feature_cols)),
  Raw_p = numeric(length(feature_cols))
)

for (j in seq_along(feature_cols)) {
  # Explicit levels preserve a 2x2 table; table() excludes incomplete pairs.
  tab <- table(class_group,
               factor(analysis_df[[feature_cols[j]]], levels = c(0, 1)))
  n <- rowSums(tab)
  if (any(n == 0)) {
    stop("No observed feature values in one class for ", feature_cols[j])
  }
  rates <- tab[, "1"] / n
  test_result <- fisher.test(tab)
  raw_p <- test_result$p.value
  results[j, 2:6] <- c(
    sum(tab[, "1"]),
    rates[1],
    rates[2],
    rates[1] - rates[2],
    raw_p
  )
}

# 5.2 Multiple-Testing Correction and Comparison ----

# Adjust the same complete family of raw p-values.
results$BY_p <- p.adjust(results$Raw_p, method = "BY")
results$BH_p <- p.adjust(results$Raw_p, method = "BH")
results$Bonferroni_p <- p.adjust(results$Raw_p, method = "bonferroni")
results$BY_discovery <- results$BY_p <= alpha
results$BH_discovery <- results$BH_p <= alpha
results$Bonferroni_discovery <- results$Bonferroni_p <= alpha

# Compare the three discovery sets.
comparison <- data.frame(
  Procedure = c("BY", "BH", "Bonferroni"),
  Error_control = c("FDR", "FDR", "FWER"),
  Discoveries = c(sum(results$BY_discovery), sum(results$BH_discovery),
                  sum(results$Bonferroni_discovery))
)

cat("\nTable 5.1 - Multiple-Testing Comparison (level = 0.05)\n")
print(comparison, row.names = FALSE)
cat("\nCommon to all three:", sum(results$BY_discovery & results$BH_discovery &
                                  results$Bonferroni_discovery),
    "\nBH but not BY:", sum(results$BH_discovery & !results$BY_discovery),
    "\nBY but not Bonferroni:",
    sum(results$BY_discovery & !results$Bonferroni_discovery),
    "\nBonferroni but not BY:",
    sum(results$Bonferroni_discovery & !results$BY_discovery), "\n")

# Additional comparisons reported in Section 5.2.
bh_only <- results[results$BH_discovery & !results$BY_discovery, ]
cat("\nBH-only discoveries more common in Non-ad:",
    sum(bh_only$Difference < 0), "\n")
cat("Median absolute rate difference (percentage points):\n")
print(round(100 * c(
  BH_only = median(abs(bh_only$Difference)),
  BY = median(abs(results$Difference[results$BY_discovery]))
), 2))

# origurl*valley (X602): example reported in Section 5.2.
print(results[results$Feature == "X602",
              c("Feature", "Ad_rate", "Non_ad_rate", "Difference", "BH_p", "BY_p")],
      row.names = FALSE, digits = 5)

# 5.3 Interpretation of Selected BY Discoveries ----

by_results <- results[results$BY_discovery, ]
# Ties: smaller BY-adjusted p, then original feature-column order.
by_results <- by_results[
  order(
    -abs(by_results$Difference),
    by_results$BY_p,
    match(by_results$Feature, feature_cols)
  ),
]
selected_by <- head(by_results[, c("Feature", "Support", "Ad_rate",
                                  "Non_ad_rate", "Difference", "BY_p")], 10)

cat("\nTable 5.2 - Selected BY Discoveries (rates on the 0-1 scale)\n")
print(selected_by, row.names = FALSE, digits = 5)
cat("\nBY discoveries more common in Ad / Non-ad:",
    sum(by_results$Difference > 0), "/",
    sum(by_results$Difference < 0), "\n")

# Overlap of alt*click+here (X1455) with its component words.
phrase <- analysis_df$X1455 == 1
cat("Phrase support / also containing both words:",
    sum(phrase), "/",
    sum(phrase & analysis_df$X1483 == 1 & analysis_df$X1435 == 1), "\n")

# Export all features without rounding the stored results.
# Retain the existing filename for compatibility.
output_file <- "outputs/T07_inference_results.csv"
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
write.csv(results, output_file, row.names = FALSE)
cat("\nFull results saved to:", output_file, "\n")

# 5.4 Sensitivity Analysis for Repeated Profiles ----

# Retain one copy of each distinct profile.
profiles <- analysis_df[!duplicated(analysis_df), , drop = FALSE]

is_ad <- profiles$Class == "ad."
n_ad_profile <- sum(is_ad)
n_nonad_profile <- sum(!is_ad)

x_profile <- as.matrix(profiles[, feature_cols, drop = FALSE])
ad_present <- colSums(x_profile[is_ad, , drop = FALSE])
nonad_present <- colSums(x_profile[!is_ad, , drop = FALSE])

# Recompute Fisher p-values using the reduced class margins.
profile_p <- vapply(seq_along(feature_cols), function(j) {
  tab <- matrix(
    c(ad_present[j], n_ad_profile - ad_present[j],
      nonad_present[j], n_nonad_profile - nonad_present[j]),
    nrow = 2, byrow = TRUE
  )
  fisher.test(tab)$p.value
}, numeric(1))

# Apply BY to the same family of 1,554 indicators.
profile_by <- p.adjust(profile_p, method = "BY") <= alpha

primary_ids <- results$Feature[results$BY_discovery]
profile_ids <- feature_cols[profile_by]

cat("\nTable 5.3 - Sensitivity Analysis for Repeated Profiles\n")
print(c(
  Original_records  = nrow(analysis_df),
  Distinct_profiles = nrow(profiles),
  Ad_profiles       = n_ad_profile,
  Nonad_profiles    = n_nonad_profile,
  Primary_BY        = length(primary_ids),
  Profile_BY        = length(profile_ids),
  Retained          = length(intersect(primary_ids, profile_ids)),
  Left              = length(setdiff(primary_ids, profile_ids)),
  Entered           = length(setdiff(profile_ids, primary_ids)),
  Top10_retained    = sum(selected_by$Feature %in% profile_ids)
))

# Compare the rate difference of ancurl*com (X1243).
profile_difference <- ad_present / n_ad_profile -
                      nonad_present / n_nonad_profile

print(round(100 * c(
  Primary_gap_pp = results$Difference[match("X1243", results$Feature)],
  Profile_gap_pp = unname(profile_difference["X1243"])
), 2))

# BY allows dependence among tests only when individual p-values are valid.
# It does not repair dependent observations; discoveries are marginal associations.

# Section 6 - Discussion and Extensions ----
# Report lead: Nguyễn Anh Minh Tuệ

# 6.2 Limitations: Feature Redundancy ----

# Compare occurrence vectors across all original image records.
x_all <- as.matrix(analysis_df[, feature_cols, drop = FALSE])
x_selected <- x_all[, primary_ids, drop = FALSE]

# Count distinct occurrence vectors.
n_unique_all <- sum(!duplicated(t(x_all)))
n_unique_selected <- sum(!duplicated(t(x_selected)))

redundancy <- data.frame(
  Indicator_set = c("All indicators", "BY discoveries"),
  Indicators = c(ncol(x_all), ncol(x_selected)),
  Distinct_vectors = c(n_unique_all, n_unique_selected),
  Additional_identical_vectors = c(
    ncol(x_all) - n_unique_all,
    ncol(x_selected) - n_unique_selected
  )
)

cat("\nSection 6.2 - Feature Redundancy\n")
print(redundancy, row.names = FALSE)