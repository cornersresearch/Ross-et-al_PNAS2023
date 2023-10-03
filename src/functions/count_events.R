count_events <- function(response,
                         units,
                         interval_width = 1,
                         intervals = c("[-3,-2)", "[-2,-1)", "[-1,0)"),
                         by = NULL){
  #' Count events (e.g. victimizations) during arbitrary intervals before
  #' treatment. You can also specify an optional group_by, e.g. if you want
  #' counts by arrest type.
  
  #' response: data you want to count, e.g. arrests
  #' units: units for which you want counts
  #' interval_width: width of the time interval in years
  #' intervals: time intervals to keep
  #' by: optional grouping
  
  response |>
    inner_join(units, by = "link_key") |>
    mutate(i = cut_width(x        = interval(start, date) / years(1),
                         width    = interval_width,
                         boundary = 0,
                         closed   = "left")) |>
    filter(i %in% intervals) |>
    count(link_key, i, !!!syms(by)) |>
    pivot_wider(names_from   = c(i, !!!syms(by)),
                values_from  = n,
                names_prefix = deparse(substitute(response)),
                names_repair = make_clean_names)
}