library(rjson)

x <- list(feature=list(words  = "sparse",
                       topics = "dense",
                       length = "dense",
                       num_self_words = "dense"),
          dataset=list(basic  = list(features = c("topics","length"),
                                     splits   = c("5fold"))),
          method =list(slda   = list(data = c("basics"),
                                     args = c("--K 10", "--K 30")),
                       logreg = list(data = c("basic"),
                                     args = c("")))
          )
write(toJSON(x),file="config.json")
