FQ1gz="/disks/dacelo/data/raw_data/tree_EM1/Project_SN7001117R_0083_CKulheim_LBronham_Melaleuca/Sample_M1a_index2/M1a_index2_CGATGTAT_L003_R1_001.fastq.gz"
FQ2gz="/disks/dacelo/data/raw_data/tree_EM1/Project_SN7001117R_0083_CKulheim_LBronham_Melaleuca/Sample_M1a_index2/M1a_index2_CGATGTAT_L003_R2_001.fastq.gz"
outputf="/disks/dacelo/data/novoplasty"

test_fraction=0.25 #proportion of data to reserve as test data


# 1. Split data into training and test sets
FQ1=${FQ1gz%.*}
FQ2=${FQ2gz%.*}

# unzip fq's for convenience
zcat $FQ1gz > $FQ1
zcat $FQ2gz > $FQ2

# first check that you have the same number of lines in both files
l1=$(wc -l $FQ1)
l2=$(wc -l $FQ2)
export l1
export l2
n1=$(perl -e 'print $ENV{"l1"} / 4') # number of F reads
n2=$(perl -e 'print $ENV{"l2"} / 4') # number of R reads
export n1
export n2
echo "You have "$n1" forward reads"
echo "You have "$n2" reverse reads"
echo "Only continue if these are the same"

# get the number of reads that correspond to the test_fraction 
export test_fraction
test=$(perl -e 'print int($ENV{"n1"} * $ENV{"test_fraction"})')
export test
train=$(perl -e 'print $ENV{"n1"} - $ENV{"test"}')
echo "Making test file from "$test" reads"
echo "Making training file from "$train" reads"

# merge and randomise the reads
# see aaron quinlan's answer here https://www.biostars.org/p/6544/
export FQ1
export FQ2

# The names of the test/train subsets you wish to create
export FQ1test=test1.fq
export FQ2test=test2.fq
export FQ1train=train1.fq
export FQ2train=train2.fq

# paste the two FASTQ such that the 
# header, seqs, seps, and quals occur "next" to one another
  paste $FQ1 $FQ2 | \
# "linearize" the two mates into a single record.  Add a random number to the front of each line
  awk 'BEGIN{srand()}; {OFS="\t"; \
                        getline seqs; getline sep; getline quals; \
                        print rand(),$0,seqs,sep,quals}' | \
# sort by the random number
  sort -k1,1 > pasted.txt

# split the merged reads
head -n $test pasted.txt > testdata.pasted.txt
tail -n $train pasted.txt > traindata.pasted.txt

# unmerge the reads
# see aaron quinlan's answer here https://www.biostars.org/p/6544/
awk '{OFS="\n"; \
        print $2,$4,$6,$8 >> ENVIRON["FQ1test"]; \
        print $3,$5,$7,$9 >> ENVIRON["FQ2test"]}' \
        testdata.pasted.txt

awk '{OFS="\n"; \
        print $2,$4,$6,$8 >> ENVIRON["FQ1train"]; \
        print $3,$5,$7,$9 >> ENVIRON["FQ2train"]}' \
        traindata.pasted.txt


# I think the last line(s) might be better like this
 awk '{OFS="\n"; \
        print $2" "$3,$6,$8,$10 >> ENVIRON["FQ1test"]; \
        print $4" "$5,$7,$9,$11 >> ENVIRON["FQ2test"]}'         testdata.pasted.txt