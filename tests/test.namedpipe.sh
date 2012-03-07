rm temp.pipe
mkfifo temp.pipe
seq 1 10 > temp.pipe &

./pipeline/tests/namedpipe.r --infile temp.pipe
rm temp.pipe