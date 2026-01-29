#!/usr/bin/env Rscript
# Analysis script for Trust-Aware BRPL experiments
# Generates 4 Figures + 1 Table as specified

# Set library path
.libPaths(c("~/R/library", .libPaths()))

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(scales)
  library(gridExtra)
  library(grid)
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

# Theme (cinematic + clean)
theme_cinematic <- theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    axis.title = element_text(face = "bold", color = "#0f172a"),
    axis.text = element_text(color = "#111827"),
    plot.title = element_text(face = "bold", hjust = 0.5, color = "#0f172a"),
    plot.subtitle = element_text(hjust = 0.5, color = "#334155"),
    plot.background = element_rect(fill = "#f8fafc", color = NA),
    panel.background = element_rect(fill = "#f1f5f9", color = NA),
    panel.grid.major = element_line(color = "#e2e8f0"),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "#cbd5e1", fill = NA, linewidth = 0.6)
  )

colors <- c("MRHOF" = "#ef4444", "BRPL" = "#3b82f6")
trust_colors <- c("Trust OFF" = "#f97316", "Trust ON" = "#22c55e")

bar_shadow <- function(data, x_var, y_var) {
  geom_col(
    data = data,
    aes(x = .data[[x_var]], y = .data[[y_var]]),
    width = 0.6,
    fill = "#0f172a",
    alpha = 0.12,
    position = position_nudge(x = 0.06, y = -1)
  )
}

line_glow <- function(color_var) {
  list(
    geom_line(aes(color = .data[[color_var]]), linewidth = 6, alpha = 0.12, lineend = "round"),
    geom_line(aes(color = .data[[color_var]]), linewidth = 2.2, alpha = 0.95, lineend = "round")
  )
}

heatmap_theme <- theme_cinematic +
  theme(
    axis.text.x = element_text(angle = 30, hjust = 1),
    legend.position = "right"
  )

figure_header <- function(title) {
  textGrob(title, gp = gpar(fontface = "bold", fontsize = 16, col = "#0f172a"))
}

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
  bar_shadow(fig1_stats, "Routing", "pdr_mean") +
  geom_col(width = 0.6, color = "#0f172a", linewidth = 0.6) +
  geom_errorbar(aes(ymin = pdr_mean - pdr_se, ymax = pdr_mean + pdr_se), width = 0.2) +
  scale_fill_manual(values = colors) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "PDR", subtitle = "Normal traffic (no attack, no trust)", x = NULL, y = "PDR (%)") +
  theme_cinematic + theme(legend.position = "none")

p1b <- ggplot(fig1_stats, aes(x = Routing, y = delay_mean, fill = Routing)) +
  bar_shadow(fig1_stats, "Routing", "delay_mean") +
  geom_col(width = 0.6, color = "#0f172a", linewidth = 0.6) +
  geom_errorbar(aes(ymin = delay_mean - delay_se, ymax = delay_mean + delay_se), width = 0.2) +
  scale_fill_manual(values = colors) +
  labs(title = "Delay", subtitle = "Normal traffic (no attack, no trust)", x = NULL, y = "Delay (ms)") +
  theme_cinematic + theme(legend.position = "none")

fig1 <- grid.arrange(p1a, p1b, ncol = 2,
                     top = figure_header("Figure 1: Normal Operation (MRHOF vs BRPL)"))

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

fig2 <- ggplot(fig2_stats, aes(x = factor(attack_rate), y = pdr_mean, group = Routing)) +
  line_glow("Routing") +
  geom_point(aes(fill = Routing), size = 3.6, shape = 21, color = "#0f172a") +
  geom_errorbar(aes(ymin = pdr_mean - pdr_se, ymax = pdr_mean + pdr_se, color = Routing),
                width = 0.2) +
  scale_fill_manual(values = colors) +
  scale_color_manual(values = colors) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "Figure 2: PDR Degradation Under Attack (Trust OFF)",
       subtitle = "Selective forwarding impact by routing",
       x = "Attack Drop Rate (%)", y = "PDR (%)") +
  theme_cinematic

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

fig3 <- ggplot(fig3_stats, aes(x = factor(attack_rate), y = pdr_mean, group = Trust)) +
  line_glow("Trust") +
  geom_point(aes(fill = Trust), size = 3.6, shape = 21, color = "#0f172a") +
  geom_errorbar(aes(ymin = pdr_mean - pdr_se, ymax = pdr_mean + pdr_se, color = Trust),
                width = 0.2) +
  scale_fill_manual(values = trust_colors) +
  scale_color_manual(values = trust_colors) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "Figure 3: Trust-Based Defense (BRPL)",
       subtitle = "Trust ON vs OFF under attack",
       x = "Attack Drop Rate (%)", y = "PDR (%)") +
  theme_cinematic

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
  trust_value_col <- NULL
  if ("trust_value" %in% names(trust_data)) {
    trust_value_col <- "trust_value"
  } else if ("beta" %in% names(trust_data)) {
    trust_value_col <- "beta"
  } else if ("bayes" %in% names(trust_data)) {
    trust_value_col <- "bayes"
  } else if ("ewma" %in% names(trust_data)) {
    trust_value_col <- "ewma"
  }
  
  if (is.null(trust_value_col)) {
    cat("⚠ trust_metrics.csv found but no trust column detected (trust_value/beta/bayes/ewma)\n\n")
  } else {
  trust_data <- trust_data %>% mutate(trust_value = .data[[trust_value_col]])

    trust_summary <- trust_data %>%
      group_by(node_id) %>%
      summarise(avg_trust = mean(trust_value, na.rm = TRUE))
  
  attacker_id <- trust_summary %>% 
    filter(avg_trust == min(avg_trust)) %>% 
    pull(node_id) %>% first()
  
    plot_data <- trust_data %>%
      mutate(
        time_sec = if ("timestamp" %in% names(trust_data)) timestamp / 1000 else seq / 1.0,
        node_type = ifelse(node_id == attacker_id, "Attacker", "Normal")
      ) %>%
      filter(time_sec <= 300)

    normal_summary <- plot_data %>%
      filter(node_type == "Normal") %>%
      group_by(time_sec) %>%
      summarise(
        trust_mean = mean(trust_value, na.rm = TRUE),
        trust_sd = sd(trust_value, na.rm = TRUE),
        .groups = "drop"
      )
  
    fig4 <- ggplot() +
      geom_ribbon(data = normal_summary,
                  aes(x = time_sec, ymin = trust_mean - trust_sd, ymax = trust_mean + trust_sd),
                  fill = "#22c55e", alpha = 0.20) +
      geom_line(data = normal_summary,
                aes(x = time_sec, y = trust_mean),
                color = "#16a34a", linewidth = 2.2, lineend = "round") +
      geom_line(data = plot_data %>% filter(node_type == "Attacker"),
                aes(x = time_sec, y = trust_value, group = node_id),
                color = "#ef4444", linewidth = 2.6, lineend = "round") +
      scale_y_continuous(limits = c(0, 1)) +
      labs(title = "Figure 4: Trust Value Evolution",
           subtitle = paste0("Attacker vs Normal (mean ± SD), source: ", trust_value_col),
           x = "Time (s)", y = "Trust Value") +
      theme_cinematic
    
    ggsave(file.path(output_dir, "figure4_trust.png"), fig4, width = 10, height = 6, dpi = 300)
    cat("✓ Saved: figure4_trust.png\n\n")
  }
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

cat("=== Additional Figures ===\n")

# FIGURE 5: All scenarios PDR vs attack rate (facet)
fig5_stats <- data %>%
  mutate(Scenario = scenario) %>%
  group_by(Scenario, routing, trust, attack_rate) %>%
  summarise(pdr_mean = mean(pdr), pdr_se = sd(pdr) / sqrt(n()), .groups = "drop") %>%
  mutate(Trust = ifelse(trust == 1, "Trust ON", "Trust OFF"))

fig5 <- ggplot(fig5_stats, aes(x = factor(attack_rate), y = pdr_mean, group = interaction(routing, Trust))) +
  line_glow("routing") +
  geom_point(aes(fill = routing), size = 3.2, shape = 21, color = "#0f172a") +
  geom_errorbar(aes(ymin = pdr_mean - pdr_se, ymax = pdr_mean + pdr_se, color = routing), width = 0.2) +
  facet_wrap(~ Trust, ncol = 2) +
  scale_fill_manual(values = colors) +
  scale_color_manual(values = colors) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "Figure 5: PDR Across All Scenarios",
       subtitle = "Routing comparison with trust facets",
       x = "Attack Drop Rate (%)", y = "PDR (%)") +
  theme_cinematic

ggsave(file.path(output_dir, "figure5_pdr_all.png"), fig5, width = 12, height = 6, dpi = 300)
cat("✓ Saved: figure5_pdr_all.png\n\n")

# FIGURE 6: Delay vs attack rate
fig6_stats <- data %>%
  group_by(routing, trust, attack_rate) %>%
  summarise(delay_mean = mean(avg_delay_ms), delay_se = sd(avg_delay_ms) / sqrt(n()), .groups = "drop") %>%
  mutate(Trust = ifelse(trust == 1, "Trust ON", "Trust OFF"))

fig6 <- ggplot(fig6_stats, aes(x = factor(attack_rate), y = delay_mean, group = routing)) +
  line_glow("routing") +
  geom_point(aes(fill = routing), size = 3.2, shape = 21, color = "#0f172a") +
  geom_errorbar(aes(ymin = delay_mean - delay_se, ymax = delay_mean + delay_se, color = routing), width = 0.2) +
  facet_wrap(~ Trust) +
  scale_fill_manual(values = colors) +
  scale_color_manual(values = colors) +
  labs(title = "Figure 6: Delay Under Attack",
       subtitle = "Delay trends across routing and trust",
       x = "Attack Drop Rate (%)", y = "Delay (ms)") +
  theme_cinematic

ggsave(file.path(output_dir, "figure6_delay.png"), fig6, width = 12, height = 6, dpi = 300)
cat("✓ Saved: figure6_delay.png\n\n")

# FIGURE 7: PDR vs Delay scatter (expert-style)
fig7 <- ggplot(data, aes(x = avg_delay_ms, y = pdr, color = routing, shape = factor(trust))) +
  geom_point(size = 3, alpha = 0.85) +
  scale_color_manual(values = colors) +
  scale_shape_manual(values = c("0" = 16, "1" = 17), labels = c("Trust OFF", "Trust ON")) +
  labs(title = "Figure 7: PDR vs Delay",
       subtitle = "Trade-off landscape",
       x = "Delay (ms)", y = "PDR (%)", shape = "Trust") +
  theme_cinematic

ggsave(file.path(output_dir, "figure7_pdr_delay.png"), fig7, width = 10, height = 6, dpi = 300)
cat("✓ Saved: figure7_pdr_delay.png\n\n")

# FIGURE 8: Heatmap (PDR by scenario and attack rate)
heat_data <- data %>%
  group_by(scenario, attack_rate) %>%
  summarise(pdr_mean = mean(pdr), .groups = "drop") %>%
  mutate(attack_rate = factor(attack_rate))

fig8 <- ggplot(heat_data, aes(x = attack_rate, y = scenario, fill = pdr_mean)) +
  geom_tile(color = "#0f172a", linewidth = 0.4) +
  scale_fill_gradient(low = "#0ea5e9", high = "#ef4444") +
  labs(title = "Figure 8: PDR Heatmap",
       subtitle = "Scenario vs Attack Drop Rate",
       x = "Attack Drop Rate (%)", y = "Scenario", fill = "PDR") +
  heatmap_theme

ggsave(file.path(output_dir, "figure8_heatmap.png"), fig8, width = 10, height = 7, dpi = 300)
cat("✓ Saved: figure8_heatmap.png\n\n")

# FIGURE 9: TX/RX volume by routing & trust (pseudo-3D bars)
vol_stats <- data %>%
  group_by(routing, trust) %>%
  summarise(tx_mean = mean(tx), rx_mean = mean(rx), .groups = "drop") %>%
  mutate(Trust = ifelse(trust == 1, "Trust ON", "Trust OFF"))

vol_long <- vol_stats %>%
  pivot_longer(cols = c(tx_mean, rx_mean), names_to = "Metric", values_to = "Value") %>%
  mutate(Metric = recode(Metric, tx_mean = "TX", rx_mean = "RX"))

fig9 <- ggplot(vol_long, aes(x = routing, y = Value, fill = Metric)) +
  bar_shadow(vol_long, "routing", "Value") +
  geom_col(width = 0.6, color = "#0f172a", linewidth = 0.6, position = position_dodge(width = 0.7)) +
  facet_wrap(~ Trust) +
  scale_fill_manual(values = c("TX" = "#38bdf8", "RX" = "#f472b6")) +
  labs(title = "Figure 9: Transmission Volume",
       subtitle = "TX/RX volume by routing and trust",
       x = NULL, y = "Packets") +
  theme_cinematic

ggsave(file.path(output_dir, "figure9_volume.png"), fig9, width = 11, height = 6, dpi = 300)
cat("✓ Saved: figure9_volume.png\n\n")

cat("\n============================================\n")
cat("Analysis Complete! Check docs/report/\n")
cat("============================================\n")
