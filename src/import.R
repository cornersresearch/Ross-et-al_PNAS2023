#' This script imports and tidies outreach participant and Administrative data.


#' victimization
#' 1/ bind the fatal and non-fatal victimization data
#' 2/ filter to data >= 2010-01-01
#' 3/ for each link_key, remove any victimizations occurring after fatal
#' 4/ for each link_key, remove non-fatal that occur on same date as fatal
message("----Loading victimization data\n")
victim <-
  bind_rows(
    bq_project_query(
      "database",
      "SELECT rd_no, victim_ir_no, injury_date
      FROM `table`"
    ) |>
      bq_table_download() |>
      transmute(link_key = victim_ir_no, rd_no, date = injury_date,
                type = "fatal"),
    bq_project_query(
      "database",
      "SELECT rd_no, ir_no, date
      FROM `table`"
    ) |>
      bq_table_download() |>
      transmute(link_key = ir_no, rd_no, date = as_date(date),
                type = "non_fatal")
  ) |>
  filter(!is.na(link_key), date >= ymd("2010-01-01")) |> #2
  group_by(link_key) |>
  filter(date <= min(date[type == "fatal"])) |> #3
  group_by(link_key, date) |>
  slice_max(fct_relevel(type, "non_fatal"), with_ties = FALSE) |> #4
  ungroup()

#' arrests
#' 1/ filter to data >= 2010-01-01
#' 2/ join arrest types
message("\n----Loading arrest data")
arrest <-
  bq_project_query(
    "database",
    "SELECT rd_no, ir_no AS link_key, arrest_date AS date,
            fbi_code, race, age, sex, arr_district
     FROM `table`
     WHERE ir_no IS NOT NULL
        AND arrest_date >= '2010-01-01'
        AND age != 0"
  ) |>
  bq_table_download(page_size = 50000) |>
  left_join(augment_arrest(), by = "fbi_code") |>
  # in general, transmute is more robust than select as it has fewer conflicts
  # with other packages
  transmute(link_key, rd_no, date, type, severity,
            violent, race, age, sex, arr_district) |> 
  replace_na(list(type = "other", severity = 10, violent = "non_violent")) |>
  distinct()

# gang
message("----Loading gang data")
gang <-
  bq_project_query(
    "database",
    "SELECT * FROM `table`"
  ) |>
  bq_table_download() |>
  transmute(link_key = ir_no, gang = 1) |>
  filter(!is.na(link_key)) |>
  distinct()

#' treatment
#' 1/ bind the participation data (from org of interest and any other orgs)
#' 2/ remove rows without start date or link_key
#' 3/ for each link_key, take earliest start date
#' 4/ exclude participants who joined very recently (within 6 months of most
#'    recent date in Arrests dataset)
message("----Loading participant data\n\n")

treated <-
  bind_rows(
    glue("org_participant_data.csv") |> # Extended client-level dataset filename
      read_csv(progress = F, show_col_types = F) |> # Suppress loading details
      transmute(link_key, start = ymd(participant_enrolled_assistance_start),
                organization = "organization_name", # Organization name
                tx = 1,
                participant_status_program_phase,
                community_where_active, previous_status_value),
    other_demographics |> 
      transmute(link_key, start = ymd(first_day),
                organization, tx = 1)
  ) |>
  filter(!is.na(link_key), !is.na(start)) |> #2
  group_by(link_key) |>
  slice_min(start, with_ties = FALSE) |> #3
  ungroup() %>%
  # Exclude those who joined in the last 6 months before the most recent arrest.
  filter(start < max(arrest$date) %m-% months(6)) #4