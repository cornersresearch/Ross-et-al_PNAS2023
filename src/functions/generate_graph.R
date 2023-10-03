generate_graph <- function(arrest){
  # Generate co-arrest graph.
  graph <- graph.data.frame(drop_na(arrest), directed = FALSE)
  V(graph)$type <- FALSE
  V(graph)$type[V(graph)$name %in% arrest$"link_key"] <- TRUE
  bipartite_projection(graph, which = "true", multiplicity = TRUE)
}