count_treated_peers <- function(units){
  #' Compute proportions of first and second-order co-arrestees who are
  #' receiving the treatment.
  #' For control-group subjects, there should be zero first-order
  #' co-arrestees in the treatment group. (This is because first-order
  #' co-arrestees of treatment-group participants were excluded from the pool
  #' of potential evaluation units.)

  # Other organizations offering treatment.
  orgs <- c("")
  
  # Find treatment group's arrests in the last three years.
  eval_arrests <- 
    units %>% 
      left_join(arrest, by = "link_key") %>% 
      filter(start - date <= years(3)) %>% 
      transmute(ego = link_key, rd_no, start) %>% 
      distinct() %>% 
      drop_na()
  
  # Find the first- & second-order arrest peers for all treatment participants.
  peers_all <- 
    eval_arrests %>% 
      left_join(arrest %>% filter(rd_no %in% eval_arrests$rd_no),
                by = "rd_no") %>% 
      filter(ego != link_key, start - date <= years(3)) %>% 
      transmute(ego, start, link_key) %>% 
      left_join(arrest, by = "link_key") %>% 
      filter(start - date <= years(3)) %>% 
      transmute(ego, start, peer1 = link_key, rd_no) %>% 
      drop_na() %>% 
      left_join(arrest, by = "rd_no") %>% 
      filter(start - date <= years(3),
             ego != link_key,
             peer1 != link_key) %>% 
      transmute(ego, peer1, peer2 = link_key)
  
  # Pull out first-order peers.
  peers_1o <-
    peers_all %>% 
      transmute(ego, peer1) %>% 
      distinct()
  
  # Pull out second-order peers.
  peers_2o <- 
    peers_all %>% 
      transmute(ego, peer2) %>% 
      distinct()
  
  # Get first- and second-order peers who are treated by the specified orgs.
  peer_tx_status <- 
    treated %>% 
      filter(link_key %in% (c(peers_1o$peer1, peers_2o$peer2)),
             organization %in% orgs) %>% # Only treated peers in specified orgs
      transmute(peer = link_key, tx)
  
  
  # Get all first- and second-order peers; set treatment (tx) to zero for those
  # not receiving services from the specified organizations.
  peers_all_degree <- 
    peers_all %>% 
      pivot_longer(c(peer1, peer2),
                   names_to = "degree", values_to = "peer") %>% 
      mutate(degree = degree %>% str_remove("peer") %>% as.integer()) %>% 
      left_join(peer_tx_status, by = "peer") %>% 
      mutate(tx = tx %>% replace_na(0) %>% as.integer())
  
 
  # Find counts of peers in treatment (or not) by peer_degree.
  peers_counts <- 
    peers_all_degree %>% 
    arrange(ego, degree) %>% 
    group_by(ego, degree, tx) %>% 
    summarize(num_peers_by_tx_type = n_distinct(peer), .groups = "drop")
  
  # Compute total number of peers for each ego by order.
  peers_total <- 
    peers_counts %>% 
    group_by(ego, degree) %>% 
    summarize(total_peers = sum(num_peers_by_tx_type), .groups = "drop")
  
  # Compute proportions of first- and second-order peers receiving treatment.
  prop_treated_peers <- 
    peers_counts %>% 
    filter(tx == 1) %>% # Keep only the rows with treated peers
    left_join(peers_total, by = c("ego", "degree")) %>% 
    mutate(prop_peers = num_peers_by_tx_type / total_peers) %>% 
    pivot_wider(ego,
                names_from = c(degree, tx),
                values_from = prop_peers,
                names_glue = "prop.deg{degree}_tx{tx}",
                values_fill = 0) %>% 
    rename(link_key = ego) %>% 
    right_join(units %>% transmute(link_key), by = "link_key") %>% 
    mutate(across(where(is.numeric), ~ replace_na(., 0))) %>% 
    select(link_key, any_of(c("prop.deg1_tx1", "prop.deg2_tx1")))
}