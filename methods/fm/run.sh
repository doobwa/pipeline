# valid.training.txt 4763362
# valid.test.txt 80075
# test.sp.txt 93100

./methods/fm/bin/libFM --train data/valid.training.sp.txt --test data/valid.test.sp.txt --dim "1,1,20" --learn_rate 0.00001 --iter 5 --regular "0,1,10" --task c --out working.data/fm/valid.test/sgd.20.1.txt --verbosity 1 --method sgd

./methods/fm/bin/libFM --train data/training.sp.txt --test data/test.sp.txt --dim "1,1,20" --learn_rate 0.0001 --iter 10 --regular "0,.5,3" --task c --out working.data/fm/test/sgd.20.1.txt --verbosity 1 --method sgd

./methods/fm/bin/libFM --train data/valid.training.sp.txt --test data/valid.test.sp.txt --dim "1,1,20" --iter 10 --regular "0,1,5" --task r --out working.data/fm/valid.test/als.20.1.txt --verbosity 1 --method als

./methods/fm/bin/libFM --train data/training.sp.txt --test data/test.sp.txt --dim "1,1,20" --iter 5 --regular "0,1,5" --task r --out working.data/fm/test/als.20.1.txt --verbosity 1 --method als

./methods/fm/bin/libFM --train data/training.sp.txt --test data/training.sp.txt --dim "1,1,20" --iter 5 --regular "0,1,5" --task r --out working.data/fm/training/als.20.1.txt --verbosity 1 --method als

./methods/fm/bin/libFM --train data/training.sp.txt --test data/test.sp.txt --dim "1,1,20" --iter 5 --regular "0,1,10" --task r --out working.data/fm/valid.test/als.20.1.txt --verbosity 1 --method als


# RUN WITH LARGE K

./methods/fm/bin/libFM --train data/valid.training.sp.txt --test data/valid.test.sp.txt --dim "1,1,50" --iter 5 --regular "0,1,10" --task r --out working.data/fm/valid.test/als.50.1.10.txt --verbosity 1 --method als

./methods/fm/bin/libFM --train data/training.sp.txt --test data/test.sp.txt --dim "1,1,50" --iter 5 --regular "0,1,10" --task r --out working.data/fm/test/als.50.10.txt --verbosity 1 --method als

# K=50, mu=15
./methods/fm/bin/libFM --train data/valid.training.sp.txt --test data/valid.test.sp.txt --dim "1,1,50" --iter 5 --regular "0,1,15" --task r --out working.data/fm/valid.test/als.50.1.15.txt --verbosity 1 --method als

./methods/fm/bin/libFM --train data/training.sp.txt --test data/test.sp.txt --dim "1,1,50" --iter 5 --regular "0,1,15" --task r --out working.data/fm/test/als.50.15.txt --verbosity 1 --method als

# K=100, mu=10
./methods/fm/bin/libFM --train data/valid.training.sp.txt --test data/valid.test.sp.txt --dim "1,1,100" --iter 5 --regular "0,1,10" --task r --out working.data/fm/valid.test/als.100.1.10.txt --verbosity 1 --method als

./methods/fm/bin/libFM --train data/training.sp.txt --test data/test.sp.txt --dim "1,1,100" --iter 5 --regular "0,1,10" --task r --out working.data/fm/test/als.100.1.txt --verbosity 1 --method als

