generate_eligible_untreated <- function(arrest, treated, services,
                                        order = 1,
                                        arrest_since = ymd("2015-01-01"),
                                        geo_restrict = FALSE){
  # This function generates a pool of untreated arrestees from which to select
  # the control group.
  # The geo_restrict parameter indicates whether we are selecting a control
  # groupfrom arrestees with arrests in any of the geographic areas (police
  # district where the arrest took place) intersecting where the treatment group
  # receives treatment.
  # Enter the integer values for the arrest district on ***line 33***.

  # Generate tibble of eligible untreated units
  # 1/ Generate co-arrest graph and identify neighbors of treated.
  treated_neighbors <-
    arrest |>
    generate_graph() |>
    {
      function(x)
        ego(x, order = order,
            nodes = which(V(x)$name %in% c(treated$link_key,
                                           services$link_key)))
    }() |>
    sapply(names) |>
    unlist() |>
    enframe(value = "link_key")

  # 2/ Remove treated units and their neighbors; generate treatment indicator.
  # 3/ If geo_restrict is TRUE, keep only observations with an arrest in the
  #    police district(s) intersecting the boundaries of the treatment area.
  arrest |>
    { function(x)
      if(geo_restrict){
        x |> filter(arr_district %in% c()) # Enter geographic unit(s) here
      }
      else{
        x
      }}() |>
    anti_join(treated, by = "link_key") |>
    anti_join(services, by = "link_key") |>
    anti_join(treated_neighbors, by = "link_key") |>
    filter(date >= arrest_since) |>
    distinct(link_key) |>
    mutate(tx = 0)
}