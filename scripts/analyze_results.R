#!/usr/bin/env Rscript
# Analysis script for Trust-Aware BRPL experiments
# Generates publication-quality figures

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(scales)
  library(gridExtra)
})

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  cat("Usage: Rscript analyze_results.R <results_directory>\n")
  quit(status = 1)
}

results_dir <- args[1]
output_dir <- "docs/report"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat("============================================\n")
cat("Trust-Aware BRPL Results Analysis\n")
cat("============================================\n")
cat("Results directory:", results_dir, "\n")
cat("Output directory:", output_dir, "\n\n")

# Read summary data
summary_file <- file.path(results_dir, "experiment_summary.csv")
if (!file.exists(summary_file)) {
  cat("ERROR: Summary file not found:", summary_file, "\n")
  quit(status = 1)
}

data <- read_csv(summary_file, show_col_types = FALSE)

cat("Loaded", nrow(data), "experiment results\n")
cat("Scenarios:", unique(data$scenario), "\n\n")

# Clean and prepare data
data <- data %>%
  mutate(
    routing_label = ifelse(routing == "BRPL", "BRPL", "MRHOF"),
    trust_label = ifelse(trust == 1, "Trust ON", "Trust OFF"),
    attack_label = ifelse(attack_rate == 0, "No Attack", paste0("Attack ", attack_rate, "%")),
    scenario_label = paste(routing_label, trust_label, sep = " + ")
  )

# Summary statistics
summary_stats <- data %>%
  group_by(scenario, routing, attack_rate, trust) %>%
  summarise(
    pdr_mean = mean(pdr, na.rm = TRUE),
    pdr_sd = sd(pdr, na.rm = TRUE),
    delay_mean = mean(avg_delay_ms, na.rm = TRUE),
    delay_sd = sd(avg_delay_ms, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

cat("\n=== Summary Statistics ===\n")
print(summary_stats, n = 50)

# Theme for publication-quality plots
theme_pub <- theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold")
  )

# Color palette
colors <- c("MRHOF" = "#E74C3C", "BRPL" = "#3498DB", 
            "Trust OFF" = "#95A5A6", "Trust ON" = "#27AE60")

# ============================================
# Figure 1: Normal Performance Comparison (No Attack)
# ============================================
cat("\nGenerating Figure 1: Normal Performance...\n")

normal_data <- data %>%
  filter(attack_rate == 0)

fig1a <- ggplot(normal_data, aes(x = routing_label, y = pdr, fill = routing_label)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.1, alpha = 0.3, size = 2) +
  scale_fill_manual(values = colors) +
  labs(
    title = "PDR: Normal Conditions (No Attack)",
    x = "Routing Protocol",
    y = "Packet Delivery Ratio (%)",
    fill = "Protocol"
  ) +
  theme_pub +
  ylim(0, 100)

fig1b <- ggplot(normal_data, aes(x = routing_label, y = avg_delay_ms, fill = routing_label)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.1, alpha = 0.3, size = 2) +
  scale_fill_manual(values = colors) +
  labs(
    title = "Delay: Normal Conditions (No Attack)",
    x = "Routing Protocol",
    y = "Average E2E Delay (ms)",
    fill = "Protocol"
  ) +
  theme_pub

fig1 <- grid.arrange(fig1a, fig1b, ncol = 2)
ggsave(file.path(output_dir, "figure1_normal_performance.png"), fig1, 
       width = 12, height = 5, dpi = 300)

# ============================================
# Figure 2: Attack Impact (Trust OFF)
# ============================================
cat("Generating Figure 2: Attack Impact...\n")

attack_notrust <- data %>%
  filter(trust == 0, attack_rate > 0)

fig2 <- ggplot(attack_notrust, aes(x = attack_rate, y = pdr, color = routing_label, group = routing_label)) +
  stat_summary(fun = mean, geom = "line", size = 1.2) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 2, size = 0.8) +
  scale_color_manual(values = colors) +
  labs(
    title = "Attack Impact: PDR vs Attack Rate (Trust OFF)",
    x = "Attack Rate (Drop %)",
    y = "Packet Delivery Ratio (%)",
    color = "Routing Protocol"
  ) +
  theme_pub +
  ylim(0, 100)

ggsave(file.path(output_dir, "figure2_attack_impact.png"), fig2, 
       width = 10, height = 6, dpi = 300)

# ============================================
# Figure 3: Defense Effect (Trust ON vs OFF)
# ============================================
cat("Generating Figure 3: Defense Effect...\n")

defense_data <- data %>%
  filter(attack_rate > 0)

fig3 <- ggplot(defense_data, aes(x = attack_rate, y = pdr, 
                                  color = routing_label, 
                                  linetype = trust_label,
                                  group = interaction(routing_label, trust_label))) +
  stat_summary(fun = mean, geom = "line", size = 1.2) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 2, size = 0.8) +
  scale_color_manual(values = colors) +
  scale_linetype_manual(values = c("Trust OFF" = "dashed", "Trust ON" = "solid")) +
  labs(
    title = "Defense Effectiveness: Trust ON vs OFF",
    subtitle = "PDR Recovery with Trust-Based Defense",
    x = "Attack Rate (Drop %)",
    y = "Packet Delivery Ratio (%)",
    color = "Routing Protocol",
    linetype = "Defense"
  ) +
  theme_pub +
  ylim(0, 100)

ggsave(file.path(output_dir, "figure3_defense_effect.png"), fig3, 
       width = 10, height = 6, dpi = 300)

# ============================================
# Figure 4: BRPL Focus (Core Result)
# ============================================
cat("Generating Figure 4: BRPL Focus...\n")

brpl_data <- data %>%
  filter(routing == "BRPL", attack_rate > 0)

fig4 <- ggplot(brpl_data, aes(x = attack_rate, y = pdr, 
                               color = trust_label, 
                               group = trust_label)) +
  stat_summary(fun = mean, geom = "line", size = 1.5) +
  stat_summary(fun = mean, geom = "point", size = 4) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 2, size = 1) +
  scale_color_manual(values = colors) +
  labs(
    title = "BRPL: Trust-Based Defense Effectiveness",
    subtitle = "Core Result - Trust Mechanism Recovery",
    x = "Attack Rate (Drop %)",
    y = "Packet Delivery Ratio (%)",
    color = "Defense Status"
  ) +
  theme_pub +
  ylim(0, 100) +
  annotate("text", x = 50, y = 90, 
           label = "Trust mechanism\nrecovers PDR", 
           hjust = 0.5, size = 4, fontface = "italic")

ggsave(file.path(output_dir, "figure4_brpl_focus.png"), fig4, 
       width = 10, height = 6, dpi = 300)

# ============================================
# Figure 5: Delay Comparison
# ============================================
cat("Generating Figure 5: Delay Analysis...\n")

fig5 <- ggplot(defense_data, aes(x = attack_rate, y = avg_delay_ms, 
                                  color = routing_label, 
                                  linetype = trust_label,
                                  group = interaction(routing_label, trust_label))) +
  stat_summary(fun = mean, geom = "line", size = 1.2) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 2) +
  scale_color_manual(values = colors) +
  scale_linetype_manual(values = c("Trust OFF" = "dashed", "Trust ON" = "solid")) +
  labs(
    title = "End-to-End Delay Comparison",
    x = "Attack Rate (Drop %)",
    y = "Average E2E Delay (ms)",
    color = "Routing Protocol",
    linetype = "Defense"
  ) +
  theme_pub

ggsave(file.path(output_dir, "figure5_delay_comparison.png"), fig5, 
       width = 10, height = 6, dpi = 300)

# ============================================
# Table 1: Overhead Analysis
# ============================================
cat("Generating Table 1: Overhead Analysis...\n")

overhead_data <- data %>%
  group_by(routing, trust) %>%
  summarise(
    pdr_mean = mean(pdr, na.rm = TRUE),
    pdr_sd = sd(pdr, na.rm = TRUE),
    delay_mean = mean(avg_delay_ms, na.rm = TRUE),
    delay_sd = sd(avg_delay_ms, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    pdr_str = sprintf("%.2f±%.2f", pdr_mean, pdr_sd),
    delay_str = sprintf("%.2f±%.2f", delay_mean, delay_sd)
  )

write_csv(overhead_data, file.path(output_dir, "table1_overhead.csv"))

# ============================================
# Statistical Tests
# ============================================
cat("\n=== Statistical Analysis ===\n")

# T-test: BRPL Trust ON vs OFF under attack
brpl_attack_trust_on <- data %>% 
  filter(routing == "BRPL", attack_rate == 50, trust == 1) %>% 
  pull(pdr)

brpl_attack_trust_off <- data %>% 
  filter(routing == "BRPL", attack_rate == 50, trust == 0) %>% 
  pull(pdr)

if (length(brpl_attack_trust_on) > 0 && length(brpl_attack_trust_off) > 0) {
  t_result <- t.test(brpl_attack_trust_on, brpl_attack_trust_off)
  cat("\nBRPL @ 50% Attack: Trust ON vs OFF\n")
  cat("Mean PDR (Trust ON):", mean(brpl_attack_trust_on, na.rm = TRUE), "%\n")
  cat("Mean PDR (Trust OFF):", mean(brpl_attack_trust_off, na.rm = TRUE), "%\n")
  cat("T-test p-value:", t_result$p.value, "\n")
  cat("Significant:", ifelse(t_result$p.value < 0.05, "YES ***", "NO"), "\n")
}

# ============================================
# Summary Report
# ============================================
report <- paste0(
  "============================================\n",
  "Trust-Aware BRPL Experiment Results\n",
  "============================================\n\n",
  "Total Experiments: ", nrow(data), "\n",
  "Seeds: ", length(unique(data$seed)), "\n",
  "Scenarios: ", length(unique(data$scenario)), "\n\n",
  "=== Key Findings ===\n\n",
  "1. Normal Performance (Attack Rate = 0%):\n",
  "   MRHOF: ", sprintf("%.2f%%", mean(data$pdr[data$routing == "MRHOF" & data$attack_rate == 0], na.rm = TRUE)), " PDR\n",
  "   BRPL:  ", sprintf("%.2f%%", mean(data$pdr[data$routing == "BRPL" & data$attack_rate == 0], na.rm = TRUE)), " PDR\n\n",
  "2. Under Attack (50% Drop Rate, Trust OFF):\n",
  "   MRHOF: ", sprintf("%.2f%%", mean(data$pdr[data$routing == "MRHOF" & data$attack_rate == 50 & data$trust == 0], na.rm = TRUE)), " PDR\n",
  "   BRPL:  ", sprintf("%.2f%%", mean(data$pdr[data$routing == "BRPL" & data$attack_rate == 50 & data$trust == 0], na.rm = TRUE)), " PDR\n\n",
  "3. With Defense (50% Drop Rate, Trust ON):\n",
  "   MRHOF: ", sprintf("%.2f%%", mean(data$pdr[data$routing == "MRHOF" & data$attack_rate == 50 & data$trust == 1], na.rm = TRUE)), " PDR\n",
  "   BRPL:  ", sprintf("%.2f%%", mean(data$pdr[data$routing == "BRPL" & data$attack_rate == 50 & data$trust == 1], na.rm = TRUE)), " PDR\n\n",
  "Figures saved to: ", output_dir, "/\n",
  "============================================\n"
)

cat("\n", report)
writeLines(report, file.path(output_dir, "summary_report.txt"))

cat("\n✓ Analysis complete!\n")
cat("Check", output_dir, "for all figures and tables.\n\n")
