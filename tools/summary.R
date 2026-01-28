#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

find_latest_batch <- function() {
  if (!dir.exists("results")) {
    stop("results/ not found")
  }
  dirs <- list.dirs("results", full.names = TRUE, recursive = FALSE)
  dirs <- dirs[grepl("/batch-", dirs)]
  if (length(dirs) == 0) {
    stop("No batch-* directories under results/")
  }
  info <- file.info(dirs)
  dirs[which.max(info$mtime)]
}

batch_dir <- if (length(args) >= 1) args[1] else find_latest_batch()
if (!dir.exists(batch_dir)) {
  stop(paste("Batch dir not found:", batch_dir))
}

out_prefix <- if (length(args) >= 2) args[2] else file.path(batch_dir, "summary")

parse_overall <- function(lines) {
  line <- lines[grep("^Overall:", lines)][1]
  if (is.na(line)) return(c(tx=NA, rx=NA, pdr=NA))
  tx <- as.numeric(sub(".*TX= *([0-9]+).*", "\\1", line))
  rx <- as.numeric(sub(".*RX= *([0-9]+).*", "\\1", line))
  pdr <- as.numeric(sub(".*PDR= *([0-9.]+)%.*", "\\1", line))
  c(tx=tx, rx=rx, pdr=pdr)
}

parse_delay <- function(lines) {
  line <- lines[grep("^Average:", lines)][1]
  if (is.na(line)) return(NA)
  as.numeric(sub("Average: *([0-9.]+).*", "\\1", line))
}

parse_overhead <- function(lines) {
  line <- lines[grep("^Control/Data:", lines)][1]
  if (is.na(line)) return(NA)
  as.numeric(sub("Control/Data: *([0-9.]+)%.*", "\\1", line))
}

files <- list.files(batch_dir, pattern = "parse_results\\.txt$", recursive = TRUE, full.names = TRUE)
if (length(files) == 0) {
  stop("No parse_results.txt found under batch dir")
}

rows <- list()
for (f in files) {
  lines <- readLines(f, warn = FALSE)
  ov <- parse_overall(lines)
  avg_delay <- parse_delay(lines)
  overhead <- parse_overhead(lines)

  m <- regexec("/((brpl|mrhof)_(on|off))/seed([0-9]+)/run/parse_results\\.txt$", f)
  g <- regmatches(f, m)[[1]]
  if (length(g) == 0) {
    next
  }
  mode <- g[3]
  drop <- g[4]
  seed <- as.integer(g[5])

  rows[[length(rows) + 1]] <- data.frame(
    mode = mode,
    attack = drop,
    seed = seed,
    tx = ov["tx"],
    rx = ov["rx"],
    pdr = ov["pdr"],
    avg_delay_ms = avg_delay,
    control_overhead_pct = overhead,
    file = f,
    stringsAsFactors = FALSE
  )
}

if (length(rows) == 0) {
  stop("No matching parse_results.txt files found")
}

df <- do.call(rbind, rows)

write.csv(df, paste0(out_prefix, "_by_run.csv"), row.names = FALSE)

agg_mean <- aggregate(df[, c("pdr", "avg_delay_ms", "control_overhead_pct")],
                      by = list(mode = df$mode, attack = df$attack),
                      FUN = function(x) mean(x, na.rm = TRUE))
agg_sd <- aggregate(df[, c("pdr", "avg_delay_ms", "control_overhead_pct")],
                    by = list(mode = df$mode, attack = df$attack),
                    FUN = function(x) sd(x, na.rm = TRUE))
counts <- aggregate(df$seed, by = list(mode = df$mode, attack = df$attack), FUN = length)
colnames(counts)[3] <- "n"

summary_df <- merge(agg_mean, agg_sd, by = c("mode", "attack"), suffixes = c("_mean", "_sd"))
summary_df <- merge(summary_df, counts, by = c("mode", "attack"))

write.csv(summary_df, paste0(out_prefix, "_summary.csv"), row.names = FALSE)

cat("Batch dir:", batch_dir, "\n")
cat("Per-run CSV:", paste0(out_prefix, "_by_run.csv"), "\n")
cat("Summary CSV:", paste0(out_prefix, "_summary.csv"), "\n")

print(summary_df)
