library(rjson)

x <- list(feature=list(words  = "sparse",
                       topics = "dense",
                       length = "dense",
                       num_self_words = "dense"),
          dataset=list(basic  = c("topics","length")),
          model  =list(slda   = list(data = c("topics"),
                                     args = c("--K 10", "--K 30")),
                       logreg = list(data = c("length","num_self_words"),
                                     args = c("")))
          )
write(toJSON(x),file="config.json")