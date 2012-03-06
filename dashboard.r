x <- read.csv("results.csv")
colnames(x) <- c("split_type","split_number","model_method","model_id","metric","value")

library(ggplot2)

df <- data.frame(x)
df$model <- paste(df$model_method,df$model_id)
qplot(value,model,data=df)