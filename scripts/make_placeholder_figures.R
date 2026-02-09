# Figures generator (grid) — improved layout stability + reviewer-safe wording
# Output: figures/architecture.pdf, figures/trust_update_flow.pdf, figures/experiment_workflow.pdf

suppressPackageStartupMessages({
  library(grid)
})

out_dir <- "figures"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# -------------------- Style --------------------
ST <- list(
  font = "Helvetica",
  title_gp = gpar(fontfamily = "Helvetica", fontsize = 15, fontface = "bold", col = "#111111"),
  subtitle_gp = gpar(fontfamily = "Helvetica", fontsize = 11, col = "#444444"),
  text_gp = gpar(fontfamily = "Helvetica", fontsize = 11.5, col = "#111111"),
  small_gp = gpar(fontfamily = "Helvetica", fontsize = 9.6, col = "#444444", fontface = "italic"),
  box_border = "#2F2F2F",
  box_lwd = 0.9,
  arrow_col = "#1E1E1E",
  accent_fill = "#E7F0FF",
  accent_border = "#2459A6",
  warn_col = "#B00020",
  lane_fill = "#FBFBFB",
  lane_border = "#CFCFCF",
  bg = "#FFFFFF"
)

# -------------------- Page scaffold --------------------
new_page <- function(title, subtitle = NULL) {
  grid.newpage()
  grid.rect(gp = gpar(fill = ST$bg, col = NA))
  grid.text(title, x = unit(0.04, "npc"), y = unit(0.96, "npc"),
            just = c("left", "top"), gp = ST$title_gp)
  if (!is.null(subtitle)) {
    grid.text(subtitle, x = unit(0.04, "npc"), y = unit(0.905, "npc"),
              just = c("left", "top"), gp = ST$subtitle_gp)
  }
}

# -------------------- Geometry helpers --------------------
count_lines <- function(s) {
  if (is.null(s) || length(s) == 0) return(0L)
  length(strsplit(as.character(s), "\n", fixed = TRUE)[[1]])
}
max_line_chars <- function(s) {
  if (is.null(s) || length(s) == 0) return(0L)
  lines <- strsplit(as.character(s), "\n", fixed = TRUE)[[1]]
  max(nchar(lines, type = "chars"))
}

# -------------------- Stable rounded box (FIXED SIZE, text autoshrink) --------------------
rr_box <- function(x, y, w, h, label, sub = NULL,
                   fill = "#FAFAFA", border = ST$box_border, lwd = ST$box_lwd,
                   label_gp = gpar(fontfamily = ST$font, fontsize = 11.2, fontface = "bold", col = "#111111"),
                   sub_gp   = gpar(fontfamily = ST$font, fontsize = 9.6, col = "#444444"),
                   r = 0.10,
                   pad_x = 0.03, pad_y = 0.02,
                   line_height = 1.15,
                   char_width_em = 0.55,
                   min_size = 8.0,
                   clip_text = TRUE) {

  # fixed inner size in points (deterministic within a device)
  inner_w_pt <- convertWidth(unit(w - 2*pad_x, "npc"), "points", valueOnly = TRUE)
  inner_h_pt <- convertHeight(unit(h - 2*pad_y, "npc"), "points", valueOnly = TRUE)

  # draw fixed box first
  grid.roundrect(unit(x, "npc"), unit(y, "npc"),
                 width = unit(w, "npc"), height = unit(h, "npc"),
                 r = unit(r, "snpc"),
                 gp = gpar(fill = fill, col = border, lwd = lwd))

  # viewport to ensure text never escapes box area
  vp <- viewport(
    x = unit(x, "npc"), y = unit(y, "npc"),
    width = unit(w - 2*pad_x, "npc"),
    height = unit(h - 2*pad_y, "npc"),
    clip = if (clip_text) "on" else "off"
  )
  pushViewport(vp)

  if (is.null(sub)) {
    nL <- max(1L, count_lines(label))
    cL <- max(1L, max_line_chars(label))

    fs_h <- inner_h_pt / (nL * line_height)
    fs_w <- inner_w_pt / (cL * char_width_em)
    fs <- max(min_size, min(label_gp$fontsize, fs_h, fs_w))

    gp2 <- label_gp; gp2$fontsize <- fs
    grid.text(label, x = unit(0.5, "npc"), y = unit(0.5, "npc"), gp = gp2, just = "center")
    popViewport()
    return(invisible(NULL))
  }

  # allocate height: label 40%, sub 60%
  label_h_pt <- inner_h_pt * 0.40
  sub_h_pt   <- inner_h_pt * 0.60

  nLab <- max(1L, count_lines(label))
  cLab <- max(1L, max_line_chars(label))
  nSub <- max(1L, count_lines(sub))
  cSub <- max(1L, max_line_chars(sub))

  fsLab_h <- label_h_pt / (nLab * line_height)
  fsLab_w <- inner_w_pt / (cLab * char_width_em)
  fsLab   <- max(min_size, min(label_gp$fontsize, fsLab_h, fsLab_w))

  fsSub_h <- sub_h_pt / (nSub * line_height)
  fsSub_w <- inner_w_pt / (cSub * char_width_em)
  fsSub   <- max(min_size, min(sub_gp$fontsize, fsSub_h, fsSub_w))

  gpL <- label_gp; gpL$fontsize <- fsLab
  gpS <- sub_gp;   gpS$fontsize <- fsSub

  grid.text(label, x = unit(0.5, "npc"), y = unit(0.70, "npc"), gp = gpL, just = "center")
  grid.text(sub,   x = unit(0.5, "npc"), y = unit(0.30, "npc"), gp = gpS, just = "center")

  popViewport()
}

lane <- function(x, y, w, h, title) {
  grid.roundrect(unit(x, "npc"), unit(y, "npc"),
                 width = unit(w, "npc"), height = unit(h, "npc"),
                 r = unit(0.02, "snpc"),
                 gp = gpar(fill = ST$lane_fill, col = ST$lane_border, lwd = 0.9))
  grid.text(title, unit(x - w/2 + 0.02, "npc"), unit(y + h/2 - 0.02, "npc"),
            just = c("left", "top"),
            gp = gpar(fontfamily = ST$font, fontsize = 10.2, fontface = "bold", col = "#333333"))
}

draw_arrow <- function(x0, y0, x1, y1, dashed = FALSE, col = ST$arrow_col, closed = TRUE) {
  grid.lines(unit(c(x0, x1), "npc"), unit(c(y0, y1), "npc"),
             gp = gpar(col = col, lwd = 0.9, lty = if (dashed) 2 else 1),
             arrow = grid::arrow(
               type = if (closed) "closed" else "open",
               angle = 25, length = unit(2.4, "mm"), ends = "last"
             ))
}

callout <- function(x, y, w, h, text, col = "#123A7A", fill = "#F2F6FF") {
  grid.roundrect(unit(x, "npc"), unit(y, "npc"),
                 width = unit(w, "npc"), height = unit(h, "npc"),
                 r = unit(0.08, "snpc"),
                 gp = gpar(fill = fill, col = col, lwd = 0.9))
  grid.text(text, unit(x, "npc"), unit(y, "npc"),
            gp = gpar(fontfamily = ST$font, fontsize = 9.4, col = col, fontface = "bold"))
}

# -------------------- Device helper --------------------
open_pdf <- function(path, width, height) {
  # base pdf() is fine; if you prefer more stable font metrics, replace with grDevices::cairo_pdf
  pdf(path, width = width, height = height, useDingbats = FALSE, family = ST$font)
}

# -------------------- Fig 1: Architecture --------------------
open_pdf(file.path(out_dir, "architecture.pdf"), width = 8.8, height = 5.9)
new_page("Software Architecture", "Trust-aware BRPL integration (where trust affects routing decisions)")

lane(0.34, 0.50, 0.56, 0.70, "Contiki-NG Protocol Stack")

rr_box(0.34, 0.73, 0.48, 0.13, "Application",
       "Periodic sensor-to-root traffic")
draw_arrow(0.34, 0.73 - 0.13/2 - 0.015, 0.34, 0.56 + 0.13/2 + 0.015)

rr_box(0.34, 0.56, 0.48, 0.13, "RPL / BRPL Core",
       "DODAG formation • parent selection\nbackpressure-based routing metric")
draw_arrow(0.34, 0.56 - 0.13/2 - 0.015, 0.34, 0.38 + 0.16/2 + 0.015)

rr_box(0.34, 0.38, 0.48, 0.16,
       "Trust Module",
       "computes trust score T and\npenalty term ϕ(T) online",
       fill = ST$accent_fill, border = ST$accent_border, lwd = 1.1,
       label_gp = gpar(fontfamily = ST$font, fontsize = 11.0, fontface = "bold", col = "#123A7A"),
       sub_gp   = gpar(fontfamily = ST$font, fontsize = 9.0, col = "#123A7A"))

draw_arrow(0.34, 0.38 - 0.16/2 - 0.015, 0.34, 0.20 + 0.13/2 + 0.015)

rr_box(0.34, 0.20, 0.48, 0.13, "MAC / Radio",
       "IEEE 802.15.4 / CSMA • UDGM (Cooja)")

lane(0.82, 0.50, 0.36, 0.70, "Trust Signals (examples)")

rr_box(0.82, 0.66, 0.30, 0.16, "Data-plane signal",
       "observed forwarding outcomes\n(e.g., Beta + EWMA)", fill = "#FFFFFF")
rr_box(0.82, 0.46, 0.30, 0.16, "Control-plane signal",
       "routing consistency/stability\n(e.g., rank changes)", fill = "#FFFFFF")
rr_box(0.82, 0.27, 0.30, 0.16, "Aggregation",
       "combine components into\nT_total (weighted)", fill = "#FFFFFF")

draw_arrow(0.65, 0.66, 0.58, 0.42, col = "#2459A6", closed = TRUE)
draw_arrow(0.65, 0.46, 0.58, 0.40, col = "#2459A6", closed = TRUE)
draw_arrow(0.65, 0.27, 0.58, 0.38, col = "#2459A6", closed = TRUE)

# Reviewer-safe wording:
# Avoid absolute claims like "no additional control packets required" unless you can prove it.
callout(
  0.50, 0.06, 0.90, 0.085,
  "Routing uses ϕ(T) online inside the BRPL metric. If the implementation relies only on locally available signals,\nno extra protocol messages are introduced beyond baseline RPL/BRPL control traffic."
)

dev.off()

# -------------------- Fig 2: Trust update flow (swimlanes) --------------------
open_pdf(file.path(out_dir, "trust_update_flow.pdf"), width = 9.2, height = 7.4)
new_page(
  "Online Trust Update Flow",
  "Swimlane view: data-plane and control-plane signals merged into a routing penalty"
)

# safe vertical region (leave title and footer margins)
y_top <- 0.86
y_bot <- 0.10

lane_h1 <- 0.42
lane_h2 <- 0.34
lane_y1 <- y_bot + lane_h2 + 0.06 + lane_h1/2
lane_y2 <- y_bot + lane_h2/2

lane(0.50, lane_y1, 0.92, lane_h1, "Runtime observations (ONLINE)")
lane(0.50, lane_y2, 0.92, lane_h2, "Routing decision (ONLINE)")

box_w <- 0.38
box_h <- 0.11

xL <- 0.27
xR <- 0.73

rows <- seq(lane_y1 + 0.12, lane_y1 - 0.12, length.out = 3)

# Left: data-plane
rr_box(xL, rows[1], box_w, box_h,
       "Data-plane evidence", "forwarding outcomes\n(success / failure)")
draw_arrow(xL, rows[2] + box_h/2 + 0.015, xL, rows[1] - box_h/2 - 0.015)

rr_box(xL, rows[2], box_w, box_h,
       "Beta update", "posterior mean\n(estimate)")
draw_arrow(xL, rows[3] + box_h/2 + 0.015, xL, rows[2] - box_h/2 - 0.015)

rr_box(xL, rows[3], box_w, box_h,
       "EWMA smoothing", "reduce short-term\nnoise")

# Right: control-plane
rr_box(xR, rows[1], box_w, box_h,
       "Control-plane evidence", "RPL control traffic\n(DIO/DAO etc.)")
draw_arrow(xR, rows[2] + box_h/2 + 0.015, xR, rows[1] - box_h/2 - 0.015)

rr_box(xR, rows[2], box_w, box_h,
       "Anomaly / deviation score", "rank/metric deviation\n(implementation-defined)")
draw_arrow(xR, rows[3] + box_h/2 + 0.015, xR, rows[2] - box_h/2 - 0.015)

rr_box(xR, rows[3], box_w, box_h,
       "Stability signal", "parent/rank changes\n(window W)")

# Merge
merge_y <- lane_y2 + 0.09
rr_box(0.50, merge_y, 0.50, 0.11,
       "Trust aggregation", "produce T_total from available signals")

draw_arrow(xL, rows[3] - box_h/2 - 0.02, 0.43, merge_y + 0.05, col = "#2459A6")
draw_arrow(xR, rows[3] - box_h/2 - 0.02, 0.57, merge_y + 0.05, col = "#2459A6")

# Final decision
final_y <- lane_y2 - 0.09
rr_box(0.50, final_y, 0.74, 0.14,
       "Penalty & parent selection",
       "apply ϕ(T_total) to the BRPL metric\n→ preferred parent / forwarding choice",
       fill = ST$accent_fill, border = ST$accent_border, lwd = 1.1,
       label_gp = gpar(fontfamily = ST$font, fontsize = 10.6, fontface = "bold", col = "#123A7A"),
       sub_gp   = gpar(fontfamily = ST$font, fontsize = 9.0, col = "#123A7A"))

draw_arrow(0.50, merge_y - 0.11/2 - 0.02, 0.50, final_y + 0.14/2 + 0.02)

# Reviewer-safe footer:
# Don't claim "no offline feedback" if your system later adds any adaptive logic from logs.
callout(
  0.50, 0.055, 0.92, 0.075,
  "Offline log parsing (if used) is for evaluation/diagnostics only and is not part of the online routing loop.",
  col = "#8A1F1F", fill = "#FFF3F3"
)

dev.off()

# -------------------- Fig 3: Experiment workflow --------------------
open_pdf(file.path(out_dir, "experiment_workflow.pdf"), width = 10.4, height = 5.8)
new_page("Experiment Workflow", "Pipeline separating online behavior from offline evaluation")

lane(0.50, 0.66, 0.92, 0.40, "ONLINE (affects routing behavior)")
lane(0.50, 0.22, 0.92, 0.36, "OFFLINE (metrics/evaluation)")

# Online flow boxes
rr_box(0.16, 0.70, 0.16, 0.18, ".csc\nTopology", "node positions / params")
rr_box(0.36, 0.70, 0.18, 0.18, "Cooja\nSimulation", "Contiki-NG stack")
rr_box(0.58, 0.70, 0.22, 0.18, "Online Trust\n+ Routing", "runtime decisions",
       fill = ST$accent_fill, border = ST$accent_border, lwd = 1.1,
       label_gp = gpar(fontfamily = ST$font, fontsize = 10.0, fontface = "bold", col = "#123A7A"),
       sub_gp = gpar(fontfamily = ST$font, fontsize = 8.6, col = "#123A7A"))
rr_box(0.82, 0.70, 0.18, 0.18, "COOJA.testlog", "runtime traces")

draw_arrow(0.16 + 0.16/2 + 0.02, 0.70, 0.36 - 0.18/2 - 0.02, 0.70)
draw_arrow(0.36 + 0.18/2 + 0.02, 0.70, 0.58 - 0.22/2 - 0.02, 0.70)
draw_arrow(0.58 + 0.22/2 + 0.02, 0.70, 0.82 - 0.18/2 - 0.02, 0.70)

# Offline flow
rr_box(0.62, 0.26, 0.24, 0.18, "Offline Log Analyzer", "metrics only\n(no online feedback)")
rr_box(0.84, 0.26, 0.16, 0.18, "Metrics", "PDR / Delay\nOverhead / Churn")

# log -> offline
draw_arrow(0.82, 0.70 - 0.18/2 - 0.03, 0.62, 0.26 + 0.18/2 + 0.03)
# offline -> metrics
draw_arrow(0.62 + 0.24/2 + 0.02, 0.26, 0.84 - 0.16/2 - 0.02, 0.26)

# No-feedback barrier (dashed red line)
bar_y <- 0.41
grid.lines(unit(c(0.05, 0.95), "npc"), unit(c(bar_y, bar_y), "npc"),
           gp = gpar(col = ST$warn_col, lwd = 1.0, lty = 2))
grid.text("NO ONLINE FEEDBACK from OFFLINE stage", unit(0.50, "npc"), unit(bar_y + 0.02, "npc"),
          gp = gpar(fontfamily = ST$font, fontsize = 9, col = ST$warn_col, fontface = "bold"))

grid.text(
  "Offline processing is separated for evaluation/diagnostics; online routing decisions are made during simulation runtime.",
  x = unit(0.06, "npc"), y = unit(0.06, "npc"),
  just = c("left", "bottom"), gp = ST$small_gp
)

dev.off()
