count_coarrestee_victimizations <- function(units,
                                            interval_width = 1,
                                            intervals = c("[-3,-2)",
                                                          "[-2,-1)",
                                                          "[-1,0)"),
                                            by = NULL){
  #' Count victimizations among coarrestees during user-defined intervals
  #' before treatment. Optional group_by.

  arrest |>
    inner_join(units, by = "link_key") |>
    drop_na(rd_no) |>
    left_join(arrest, by = c("rd_no")) |>
    filter(link_key.x != link_key.y) |>
    inner_join(victim, by = c("link_key.y" = "link_key")) |>
    mutate(i = cut_width(x        = interval(start, date) / years(1),
                         width    = interval_width,
                         boundary = 0,
                         closed   = "left")) |>
    filter(i %in% intervals) |>
    group_by(link_key = link_key.x, i, !!!syms(by)) |>
    dplyr::summarize(n = n_distinct(rd_no.y, na.rm = TRUE),
              .groups = "drop_last") |>
    ungroup() |>
    pivot_wider(names_from   = c(i, !!!syms(by)),
                values_from  = n,
                names_prefix = "pv_",
                names_repair = make_clean_names)
}