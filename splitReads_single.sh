#!/bin/bash

#############################################################
#dir contains single read files in fastq.gz format (the end of file must be ".fastq.gz" or ".fq.gz")
inputDir=$1
outputDir=$2
test_percentage=${3:-10} #percentage of data to reserve as test data (must be integer!!!)
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
        print $2" "$3,$6,$8,$10 >> FQ1test}' \
        testData.pasted.txt

    awk -v FQ1train="$FQ1train" \
        '{OFS="\n"; \
        print $2" "$3,$6,$8,$10 >> FQ1train}' \
        trainData.pasted.txt

    #clean
    rm testData.pasted.txt trainData.pasted.txt pasted.txt
}


#help info
if [ $# -lt 1 ]
then
  echo "Usage: ./splitReads_single.sh inputDir outputDir  integer (1-99, default 10)"
  exit 1
elif [ $1 == --help -o $1 == -h ]
then
  echo "Usage: ./splitReads_single.sh inputDir outputDir  integer (1-99, default 10)"
  exit 1
fi


#check argument
if [ ! -d $inputDir ]
then
    echo "[ERROR]" $inputDir " is not a directory"
    echo "Usage: ./splitReads_single.sh inputDir outputDir integer (1-99, default 10)"
    exit 1
fi

if [ ! -d $outputDir ]
then
    echo "[ERROR]" $outputDir " is not a directory"
    echo "Usage: ./splitReads_single.sh inputDir outputDir integer (1-99, default 10)"
    exit 1
fi

if ! [[ $test_percentage =~ ^[0-9]+$ ]]
then
    echo "[ERROR] Percentage should be 1-99 (integer)"
    echo "Usage: ./splitReads_single.sh inputDir outputDir integer (1-99, default 10)"
    exit 1
elif [ $test_percentage -ge 100 -o $test_percentage -le 0 ]
then
    echo "[ERROR] Percentage should be 1-99 (integer)"
    echo "Usage: ./splitReads_single.sh inputDir outputDir integer (1-99, default 10)"
    exit 1
fi



##begin


for R1gz in $inputDir/*
do
    echo 'Processing' $R1gz
    if [[ $R1gz == *.fastq.gz ]]
    then
        extension=".fastq.gz"
    elif [[ $R1gz == *.fq.gz ]]
    then
        extension=".fq.gz"
    else
        echo "[ERROR] The file is neither in fastq.gz or fq.gz format"
        exit 1
    fi
    
    outputR1=$outputDir/$(basename $R1gz ".fastq.gz")

    #unzip fq for convenience
    zcat $R1gz > $outputR1

    stat $outputR1 $test_percentage

    split $outputR1 $outputR1.train.fastq $outputR1.test.fastq $nTrain $nTest

    gzip $outputR1.train.fastq
    gzip $outputR1.test.fastq

    rm $outputR1 
done
