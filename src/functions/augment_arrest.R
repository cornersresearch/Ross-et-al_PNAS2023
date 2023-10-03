augment_arrest <-
  function() {
    #' Augment arrest_type with severity (authors' approximation based on FBI
    #' codes). 3, 4, & 5 are a toss-up; We decided NFS (non-fatal shooting) was
    #' more serious than rape, though not all aggravated battery charges are
    #' NFS, of course, and that robbery was less serious than both (if someone
    #' is injured or dies, the charge is escalated, so in theory, these
    #' should be less serious than both sexual assault and aggravated battery).

    tibble(
      fbi_code = c("01A", "01B", "02",
                   "03", "04A", "04B",
                   "08A", "08B", "15"),
      type     = c("homicide", "manslaughter", "criminal_sexual_assault",
                   "robbery", "aggravated_assault", "aggravated_battery",
                   "simple_assault", "simple_battery", "weapons_violation"),
      severity = c(1, 2, 4,
                   5, 6, 3,
                   8, 7, 9),
      violent  = c(rep("violent", 8), "non_violent")
    )
}