#!/bin/bash

#############################################################
#dir  in fastq.gz format (the end of file must be ".fastq.gz", if not, change the for loop)
R1gz=$1
outputR1_train_fastq=$2
outputR1_test_fastq=$3
test_percentage=${4:-10}
#############################################################
#if this script has every error, exit
set -e


#output some stat data
function stat()
{
    R1File=$1
    percentage=$2

    l1=$(wc -l < $R1File)
    n1=$[$l1 / 4] # number of F reads
    echo "You have "$n1" forward reads"

    # get the number of reads that correspond to the test_percentage 
    nTest=$[$n1 * $percentage / 100]
    nTrain=$[$n1 - $nTest]
    echo "Making test file from "$nTest" reads"
    echo "Making training file from "$nTrain" reads"
}




function split()
{
    FQ1=$1
    # The names of the test/train subsets you wish to create
    FQ1train=$2
    FQ1test=$3
    nTrain=$4
    nTest=$5

    # "linearize" the two mates into a single record.  Add a random number to the front of each line
    awk 'BEGIN{srand()}; {OFS="\t"; \
           getline seqs; getline sep; getline quals; \
           print rand(),$0,seqs,sep,quals}' $FQ1 | \
    # sort by the random number
           sort -k1,1 > pasted.txt

    # split the merged reads
    head -n $nTest pasted.txt > testData.pasted.txt
    tail -n $nTrain pasted.txt > trainData.pasted.txt

    # unmerge the reads
    awk -v FQ1test="$FQ1test" \
        '{OFS="\n"; \
        print $2,$3,$4,$5 >> FQ1test}' \
        testData.pasted.txt

    awk -v FQ1train="$FQ1train" \
        '{OFS="\n"; \
        print $2,$3,$4,$5 >> FQ1train}' \
        trainData.pasted.txt

    #clean
    rm testData.pasted.txt trainData.pasted.txt pasted.txt
}

#help info
if [ $# -lt 1 ]
then
  echo "Usage: ./splitReads_single.sh inputFile outputTrainFile outputTestFile  integer (1-99, default 10)" 
  exit 1
elif [ $1 == --help -o $1 == -h ]
then
  echo "Usage: ./splitReads_single.sh inputFile outputTrainFile outputTestFile  integer (1-99, default 10)" 
  exit 1
fi


#check argument
if [[ $R1gz != *.fastq.gz && $R1gz != *.fq.gz ]]
then
    echo "[ERROR] The file "$R1gz" is neither in fastq.gz or fq.gz format"
    exit 1
fi

if ! [[ $test_percentage =~ ^[0-9]+$ ]]
then
    echo "[ERROR] Percentage should be 1-99 (integer)"
    echo "Usage: ./splitReads_single.sh inputFile outputTrainFile outputTestFile  integer (1-99, default 10)" 
    exit 1
elif [ $test_percentage -ge 100 -o $test_percentage -le 0 ]
then
    echo "[ERROR] Percentage should be 1-99 (integer)"
    echo "Usage: ./splitReads_single.sh inputFile outputTrainFile outputTestFile  integer (1-99, default 10)" 
    exit 1
fi




#begin
outputR1=outputR1
#unzip fq for convenience
zcat $R1gz > $outputR1

stat $outputR1 $test_percentage

split $outputR1 $outputR1_train_fastq $outputR1_test_fastq $nTrain $nTest

gzip $outputR1_train_fastq
gzip $outputR1_test_fastq

rm $outputR1 
