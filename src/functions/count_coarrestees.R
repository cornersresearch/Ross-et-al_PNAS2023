count_coarrestees <- function(units,
                              interval_width = 1,
                              intervals = c("[-3,-2)", "[-2,-1)", "[-1,0)"),
                              by = NULL){
  #' Count coarrestees during arbitrary intervals before treatment. You can also
  #' specify an optional group_by, e.g. by = "type.x" if you want coarrestee
  #' counts by arrest type for unit x (by = "type.y" for unit y).

  arrest |>
    inner_join(units, by = "link_key") |>
    drop_na(rd_no) |>
    left_join(arrest, by = c("rd_no")) |>
    filter(link_key.x != link_key.y) |>
    mutate(i = cut_width(x        = interval(start, date.x) / years(1),
                         width    = interval_width,
                         boundary = 0,
                         closed   = "left")) |>
    filter(i %in% intervals) |>
    group_by(link_key = link_key.x, i, !!!syms(by)) |>
    dplyr::summarize(n = n_distinct(link_key.y, na.rm = TRUE),
              .groups = "drop_last") |>
    ungroup() |>
    pivot_wider(names_from   = c(i, !!!syms(by)),
                values_from  = n,
                names_prefix = "co_",
                names_repair = make_clean_names)
}