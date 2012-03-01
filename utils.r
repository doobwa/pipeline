
#' Create cv splits in director data/1/train.txt and data/2/train.txt.  
#' Each file has the row number to use.  Uses 0-based indexing.
#' 
#' @M number of observations
#' @K number of splits
create.cvsplits <- function(M,K=5) {
  cvsplit <- as.numeric(cut(1:M,K))
  dir.create("split")
  for (i in K:1) {
    cat(".")
    dir.create(paste("split/",i,sep=""))
    train.ix <- which(cvsplit != i)
    test.ix  <- which(cvsplit == i)
    write(paste(train.ix - 1,collapse="\n"),
          file=paste("split/",i,"/train.txt",sep=""))
    write(paste(test.ix - 1,collapse="\n"),
          file=paste("split/",i,"/test.txt",sep=""),sep="\n")
  }
  write(paste(0:(M-1),collapse="\n"),
        file=paste("split/0/train.txt",sep=""))
}

train.single <- function(Y,X,X.test,metric,model,predict,folder=NULL,method.name=NULL) {
  f <- model(X,Y)
  yhat.train <- predict(f,X)
  yhat.test  <- predict(f,X.test)
  if (!is.null(folder) & !is.null(method.name)) {
    outfile <- paste(folder,"/final/train/",method.name,".txt",sep="")
    write.csv(yhat.train,file=outfile,row.names=F)
    outfile <- paste(folder,"/final/test/",method.name,".txt",sep="")
    write.csv(yhat.test,file=outfile,row.names=F)
  }
  list(f=f,yhat.test=yhat.test,yhat.train=yhat.train, perf.train=metric(Y,yhat.train))
}

train.kfold <- function(Y,X,cvsplit,metric,model,predict,folder=NULL,method.name=NULL) {
  K <- max(cvsplit)
  lapply(1:K,function(k) {
    train.ix <- which(cvsplit != k)
    test.ix  <- which(cvsplit == k)
    f <- model(X[train.ix,],Y[train.ix])
    yhat.test  <- predict(f,X[test.ix,])
    yhat.train <- predict(f,X[train.ix,])
    y.test  <- Y[test.ix]
    y.train <- Y[train.ix]
    if (!is.null(folder) & !is.null(method.name)) {
      outfile <- paste(folder,"/valid",k,"/train/",method.name,".txt",sep="")
      write.csv(yhat.train,file=outfile,row.names=F)
      outfile <- paste(folder,"/valid",k,"/test/",method.name,".txt",sep="")
      write.csv(yhat.test,file=outfile,row.names=F)
    }
    list(f=f,yhat.test=yhat.test,yhat.train=yhat.train, perf.test=metric(y.test,yhat.test), perf.train=metric(y.train,yhat.train))
  })
}


# Compare performance
auc <- function(outcome, proba){
  N = length(proba)
  N_pos = sum(outcome)
  df = data.frame(out = outcome, prob = proba)
  df = df[order(-df$prob),]
  df$above = (1:N) - cumsum(df$out)
  return( 1- sum( df$above * df$out ) / (N_pos * (N-N_pos) ) )
}


compare.performance <- function(prediction.folder,train,cvsplit) {
  s <- expand.grid(k = 1:5,version = c("train","test"))
  res <- list()
  v <- 0
  cur <- getwd()
  for (i in 1:nrow(s)) {
    k <- s$k[i]
    dataset.name <- paste("valid",k,sep="")
    version <- s$version[i]
    folder <- paste(cur,"/",prediction.folder,"/",dataset.name,"/",version,sep="")
    setwd(folder)
    for (file in list.files()) {
      if (version=="train") {
        ix <- which(cvsplit!=k)
      } else {
        ix <- which(cvsplit==k)
      }
      y <- train$y[ix]
      yhat <- unlist(read.csv(file))
      res[[v <- v+1]] <- data.frame(dataset.name,version,file,auc=auc(y,yhat))
      print(res[[v]])
    }
    setwd(cur)
  }
  res <- do.call(rbind,res)
  return(res)
}
# Make a matrix X of the predictions for hold out folds (k.tilda) from each of the models.
# Make a vector of the true values y corresponding to these predictions.
# These structures are used to train the ensemble.
combine.for.ensemble <- function(prediction.folder,train,cvsplit,fs=NULL,K=5) {
  require(reshape)
  dataset.names <- paste("valid",1:K,sep="")
  ys <- lapply(1:K, function(k) {
    y.t <- train$y[which(cvsplit==k)]
    data.frame(i=1:length(y.t),dataset.name=dataset.names[k],y=y.t)
  })
  ys <- do.call(rbind,ys)
  
  s <- expand.grid(dataset.name = paste("valid",1:5,sep=""))
  yhats <- list()
  k <- 0
  cur <- getwd()
  for (i in 1:nrow(s)) {
    dataset.name <- s$dataset.name[i]
    version <- s$version[i]
    folder <- paste(cur,"/",prediction.folder,"/",dataset.name,"/","test",sep="")
    setwd(folder)
    if (is.null(fs)) fs <- list.files()
    for (file in fs) {
      yhat <- unlist(read.csv(file))
      yhats[[k <- k+1]] <- data.frame(i=1:length(yhat),dataset.name,file,yhat)
    }
    setwd(cur)
  }
  yhats <- do.call(rbind,yhats)
  yhats <- cast(yhats,dataset.name + i ~ file)
  res <- list(ys=ys,yhats=yhats)
  return(res)
}

ensemble.load <- function(files) {
  yhats <- lapply(files,function(f) scan(f,skip=1))
  names(yhats) <- 1:length(yhats)
  data.frame(yhats)
}



convertrow2libsvm <- function(y,x,dims) {
  right <- x + b
  ans <- paste(paste(right,1,sep=":"),collapse=" ")
  return(paste(y,ans,sep=" "))
}

convertmat2fm <- function(d,outfile,dims,single.cat=TRUE) {
  options(scipen=7)  # don't allow scientific notation when converting to characters
  D <- length(dims)
  b <- c(0,cumsum(dims[-D]))
  cat("creating matrix\n")
  if (single.cat) {
    b <- matrix(b,nr=nrow(d$x),nc=D,byrow=TRUE)
  } else {
    b <- 0
  }
  b <- d$x + b
#   for (j in 1:D) {
#     cat(".")
#     b[,j]  <- paste(b[,j],1,sep=":")
#   }
  cat("pasting each row\n")
  b <- mclapply(1:D,function(j)  paste(b[,j],1,sep=":"))
  b <- do.call(cbind,b)
  a <- cbind(y=d$y,b)
  cat("pasting each column\n")
  #g <- sapply(1:nrow(a),function(i)  paste(a[i,],collapse=" "))
  g <- unlist(mclapply(1:nrow(a),function(i)  paste(a[i,],collapse=" ")))
  cat("collapsing\n")
  gall <- paste(g,collapse="\n")
  cat("writing to file\n")
  write(gall,outfile)
}

# test_that("convert to libsvm format",{
#   # first row of trianing set
#   y <- 0
#   x <- c(85818,5560,5,14)
#   dims <- c(179104,6045,8,15) + 1  # num unique values=max value + 1
#   right <- c(85818,dims[1]+5560,dims[1]+dims[2]+5,dims[1]+dims[2]+dims[3]+14)
#   ans <- "0 85818:1 184665:1 185156:1 185174:1"
#   expect_that(convertrow2libsvm(y,x,dims),equals(ans))
# })

convertmat2libsvm <- function(d,outfile,dims) {
  options(scipen=7)  # don't allow scientific notation when converting to characters
  D <- length(dims)
  cat("pasting each row\n")
  b <- mclapply(1:D,function(j)  paste(j,b[,j],sep=":"))
  b <- do.call(cbind,b)
  a <- cbind(y=d$y,b)
  cat("pasting each column\n")
  g <- unlist(mclapply(1:nrow(a),function(i)  paste(a[i,],collapse=" ")))
  cat("collapsing\n")
  gall <- paste(g,collapse="\n")
  cat("writing to file\n")
  write(gall,outfile)
}

convert2libsvm <- function(d,outfile,dims) {
  write(convertrow2libsvm(d$y[1],d$x[1,],dims),outfile)
  pb <- txtProgressBar(min=0,max=nrow(d$x),style=3)
  for (i in 2:nrow(d$x)) {
    setTxtProgressBar(pb,i)
    write(convertrow2libsvm(d$y[i],d$x[i,],dims),outfile,append=TRUE)
  }
  close(pb)
}

# 
# require(Rcpp)
# require(inline)
# require(testthat)
# 
# fx <- cxxfunction( ,"",includes=
#   '
# // Arguments and returned values use 0-based indexing
# std::vector< std::vector<int> > which(Rcpp::IntegerVector x, int M) {
#   std::vector< std::vector<int> > xx;
#   for (int i = 0; i < M; i++) {
#     std::vector<int> tmp(0);
#     xx.push_back(tmp);
#   }
#   for (int i = 0; i < x.size(); i++) {
#     xx[x[i]].push_back(i);  // x uses 1-based indexing
#   }
#   return xx;
# }
# RCPP_MODULE(foo){
#   function( "which", &which ) ;
# }
# ', plugin="Rcpp")
# 
# super <- Module("foo",getDynLib(fx))

require(Rcpp)
require(inline)

superwhich <- cxxfunction(signature(xr="integer",mr="integer"),
'
std::vector< std::vector<int> > xx;
int m = as<int>(mr);
Rcpp::IntegerVector x(xr);
for (int i = 0; i < m; i++) {
  std::vector<int> tmp(0);
  xx.push_back(tmp);
}
for (int i = 0; i < x.size(); i++) {
  xx[x[i]].push_back(i);  
}
return wrap(xx);
', plugin="Rcpp")


#' From http://www.kaggle.com/c/PhotoQualityPrediction/forums/t/1013/r-function-for-binomial-deviance
CappedBinomialDeviance <- function(a, p) {
  if (length(a) !=  length(p)) stop("Actual and Predicted need to be equal lengths!")
  p_capped <- pmin(0.99, p)
  p_capped <- pmax(0.01, p_capped)
  -sum(a * log(p_capped, base=10) + (1 - a) * log(1 - p_capped, base=10)) / length(a)
}

collect.results <- function(ys,metric){
  yhats <- list()
  folders <- paste("predictions/",1:5,"/test",sep="")
  for (folder in folders) {
    for (f in list.files(folder)) {
      yhats[[folder]][[f]] <- scan(paste(folder,"/",f,sep=""))
    }
  }
  res <- list()
  for (i in 1:5) {
    res[[i]] <- list()
    for (j in names(yhats[[i]])) {
      res[[i]][[j]] <- metric(ys[[i]],yhats[[i]][[j]])
    }
  }
  return(melt(res))
}