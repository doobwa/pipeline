# Create synthetic data.  Should be run from example/data folder.

n <- 2000
x <- cbind(rnorm(n),rnorm(n))
y <- x[,1] + 2*x[,2]
d <- data.frame(response=y,feature1=x[,1],feature2=x[,2])
train <- d[1:1000,]
test  <- d[1001:2000,]
write.csv(train,file="train.csv",row.names=FALSE)
write.csv(test,file="test.csv",row.names=FALSE)
