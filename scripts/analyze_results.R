#!/usr/bin/env Rscript
# Analysis script for Trust-Aware BRPL experiments
# Generates 4 Figures + 1 Table as specified

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

# Read summary data
summary_file <- file.path(results_dir, "experiment_summary.csv")
if (!file.exists(summary_file)) {
  cat("ERROR: Summary file not found:", summary_file, "\n")
  quit(status = 1)
}

data <- read_csv(summary_file, show_col_types = FALSE)
cat("Loaded", nrow(data), "experiment results\n\n")

# Theme
theme_pub <- theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5),
    panel.border = element_rect(color = "gray80", fill = NA)
  )

colors <- c("MRHOF" = "#E74C3C", "BRPL" = "#3498DB")
trust_colors <- c("Trust OFF" = "#E67E22", "Trust ON" = "#27AE60")

# ============================================
# FIGURE 1: Normal Operation (1 vs 2)
# ============================================
cat("=== Figure 1: Normal Operation ===\n")

fig1_data <- data %>%
  filter(scenario %in% c("1_mrhof_normal_notrust", "2_brpl_normal_notrust")) %>%
  mutate(Routing = ifelse(routing == "MRHOF", "MRHOF", "BRPL"))

fig1_stats <- fig1_data %>%
  group_by(Routing) %>%
  summarise(
    pdr_mean = mean(pdr),
    pdr_se = sd(pdr) / sqrt(n()),
    delay_mean = mean(avg_delay_ms),
    delay_se = sd(avg_delay_ms) / sqrt(n())
  )

p1a <- ggplot(fig1_stats, aes(x = Routing, y = pdr_mean, fill = Routing)) +
  geom_col(width = 0.6, color = "black") +
  geom_errorbar(aes(ymin = pdr_mean - pdr_se, ymax = pdr_mean + pdr_se), width = 0.2) +
  scale_fill_manual(values = colors) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "PDR", x = NULL, y = "PDR (%)") +
  theme_pub + theme(legend.position = "none")

p1b <- ggplot(fig1_stats, aes(x = Routing, y = delay_mean, fill = Routing)) +
  geom_col(width = 0.6, color = "black") +
  geom_errorbar(aes(ymin = delay_mean - delay_se, ymax = delay_mean + delay_se), width = 0.2) +
  scale_fill_manual(values = colors) +
  labs(title = "Delay", x = NULL, y = "Delay (ms)") +
  theme_pub + theme(legend.position = "none")

fig1 <- grid.arrange(p1a, p1b, ncol = 2,
                     top = textGrob("Figure 1: Normal Operation (MRHOF vs BRPL)",
                                   gp = gpar(fontface = "bold", fontsize = 16)))

ggsave(file.path(output_dir, "figure1_normal.png"), fig1, width = 10, height = 5, dpi = 300)
cat("✓ Saved: figure1_normal.png\n\n")

# ============================================
# FIGURE 2: Attack Impact (3 vs 4)
# ============================================
cat("=== Figure 2: Attack Impact ===\n")

fig2_data <- data %>%
  filter(scenario %in% c("3_mrhof_attack_notrust", "4_brpl_attack_notrust")) %>%
  mutate(Routing = ifelse(routing == "MRHOF", "MRHOF", "BRPL"))

fig2_stats <- fig2_data %>%
  group_by(Routing, attack_rate) %>%
  summarise(pdr_mean = mean(pdr), pdr_se = sd(pdr) / sqrt(n()), .groups = "drop")

fig2 <- ggplot(fig2_stats, aes(x = factor(attack_rate), y = pdr_mean, fill = Routing, group = Routing)) +
  geom_line(aes(color = Routing), size = 1.2, position = position_dodge(0.2)) +
  geom_point(size = 3, shape = 21, color = "black", position = position_dodge(0.2)) +
  geom_errorbar(aes(ymin = pdr_mean - pdr_se, ymax = pdr_mean + pdr_se, color = Routing),
                width = 0.2, position = position_dodge(0.2)) +
  scale_fill_manual(values = colors) +
  scale_color_manual(values = colors) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "Figure 2: PDR Degradation Under Attack (Trust OFF)",
       x = "Attack Drop Rate (%)", y = "PDR (%)") +
  theme_pub

ggsave(file.path(output_dir, "figure2_attack.png"), fig2, width = 10, height = 6, dpi = 300)
cat("✓ Saved: figure2_attack.png\n\n")

# ============================================
# FIGURE 3: Defense (4 vs 6) - BRPL Only
# ============================================
cat("=== Figure 3: Defense Effectiveness ===\n")

fig3_data <- data %>%
  filter(scenario %in% c("4_brpl_attack_notrust", "6_brpl_attack_trust")) %>%
  mutate(Trust = ifelse(trust == 1, "Trust ON", "Trust OFF"))

fig3_stats <- fig3_data %>%
  group_by(Trust, attack_rate) %>%
  summarise(pdr_mean = mean(pdr), pdr_se = sd(pdr) / sqrt(n()), .groups = "drop")

fig3 <- ggplot(fig3_stats, aes(x = factor(attack_rate), y = pdr_mean, fill = Trust, group = Trust)) +
  geom_line(aes(color = Trust), size = 1.2, position = position_dodge(0.2)) +
  geom_point(size = 3, shape = 21, color = "black", position = position_dodge(0.2)) +
  geom_errorbar(aes(ymin = pdr_mean - pdr_se, ymax = pdr_mean + pdr_se, color = Trust),
                width = 0.2, position = position_dodge(0.2)) +
  scale_fill_manual(values = trust_colors) +
  scale_color_manual(values = trust_colors) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "Figure 3: Trust-Based Defense (BRPL)",
       x = "Attack Drop Rate (%)", y = "PDR (%)") +
  theme_pub

ggsave(file.path(output_dir, "figure3_defense.png"), fig3, width = 10, height = 6, dpi = 300)
cat("✓ Saved: figure3_defense.png\n\n")

# ============================================
# FIGURE 4: Trust Evolution
# ============================================
cat("=== Figure 4: Trust Evolution ===\n")

trust_file <- list.files(results_dir, pattern = "trust_metrics.csv", 
                        recursive = TRUE, full.names = TRUE)[1]

if (!is.null(trust_file) && file.exists(trust_file)) {
  trust_data <- read_csv(trust_file, show_col_types = FALSE)
  
  trust_summary <- trust_data %>%
    group_by(node_id) %>%
    summarise(avg_trust = mean(trust_value, na.rm = TRUE))
  
  attacker_id <- trust_summary %>% 
    filter(avg_trust == min(avg_trust)) %>% 
    pull(node_id) %>% first()
  
  plot_data <- trust_data %>%
    mutate(
      time_sec = timestamp / 1000,
      node_type = ifelse(node_id == attacker_id, "Attacker", "Normal")
    ) %>%
    filter(time_sec <= 300)
  
  fig4 <- ggplot(plot_data, aes(x = time_sec, y = trust_value, color = node_type, group = node_id)) +
    geom_line(alpha = 0.7, size = 0.8) +
    scale_color_manual(values = c("Attacker" = "#E74C3C", "Normal" = "#27AE60")) +
    scale_y_continuous(limits = c(0, 1)) +
    labs(title = "Figure 4: Trust Value Evolution",
         x = "Time (s)", y = "Trust Value", color = "Node Type") +
    theme_pub
  
  ggsave(file.path(output_dir, "figure4_trust.png"), fig4, width = 10, height = 6, dpi = 300)
  cat("✓ Saved: figure4_trust.png\n\n")
} else {
  cat("⚠ No trust_metrics.csv found\n\n")
}

# ============================================
# TABLE 1: Overhead
# ============================================
cat("=== Table 1: Overhead Analysis ===\n")

overhead_data <- data %>%
  filter(attack_rate > 0) %>%
  group_by(routing, trust, attack_rate) %>%
  summarise(avg_tx = mean(tx), avg_pdr = mean(pdr), .groups = "drop")

table1 <- overhead_data %>%
  pivot_wider(
    id_cols = c(routing, attack_rate),
    names_from = trust,
    values_from = c(avg_tx, avg_pdr)
  ) %>%
  mutate(
    tx_overhead = avg_tx_1 - avg_tx_0,
    pdr_improvement = avg_pdr_1 - avg_pdr_0
  ) %>%
  select(Routing = routing, Attack = attack_rate, 
         `TX Overhead` = tx_overhead, `PDR Improvement` = pdr_improvement)

write_csv(table1, file.path(output_dir, "table1_overhead.csv"))
cat("✓ Saved: table1_overhead.csv\n\n")

print(table1)

cat("\n============================================\n")
cat("Analysis Complete! Check docs/report/\n")
cat("============================================\n")
