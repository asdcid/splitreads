#!/bin/bash

#############################################################
#dir contains R1 and R2, in fastq.gz format (the end of file must be ".fastq.gz", if not, change the for loop)
inputDir='.'
outputDir='separate'
test_percentage=25 #percentage of data to reserve as test data (must be int!!!)
#############################################################

#if this script has every error, exit
set -e


#check whether the name in R1 and R2 is the same and in the same order, and output some stat data
function check_R1R2_seqName()
{
    R1File=$1
    R2File=$2
    percentage=$3
    awk '{if (NR % 4 == 1) {print $1}}' $R1File > $R1File.checkName
    awk '{if (NR % 4 == 1) {print $1}}' $R2File > $R2File.checkName
    diff -q $R2File.checkName $R2File.checkName 1>/dev/null
    if [ $? == 0 ]
    then
        echo "Finished name checking"
    else
        echo "[ERROR] Names in R1/R2 are not the same"
        exit 1
    fi
    rm $R1File.checkName $R2File.checkName

    # first check that you have the same number of lines in both files
    n1=$(wc -l < $R1File.checkName)
    n2=$(wc -l < $R2File.checkName)
    echo "You have "$n1" forward reads"
    echo "You have "$n2" reverse reads"

    # get the number of reads that correspond to the test_percentage 
    nTest=$[$n1 * $percentage / 100]
    nTrain=$[$n1 - $nTest]
    echo "Making test file from "$nTest" reads"
    echo "Making training file from "$nTrain" reads"
}




function split()
{
    FQ1=$1
    FQ2=$2
    FQ1train=$3
    FQ1test=$4
    FQ2train=$5
    FQ2test=$6
    nTrain=$7
    nTest=$8

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
    head -n $nTest pasted.txt > testData.pasted.txt
    tail -n $nTrain pasted.txt > trainData.pasted.txt

    # unmerge the reads
    awk -v FQ1test="$FQ1test" \
        -v FQ2test="$FQ2test" \
        '{OFS="\n"; \
        print $2" "$3,$6,$8,$10 >> FQ1test; \
        print $4" "$5,$7,$9,$11 >> FQ2test}' \
        testData.pasted.txt

    awk -v FQ1train="$FQ1train" \
        -v FQ2train="$FQ2train" \
        '{OFS="\n"; \
        print $2" "$3,$6,$8,$10 >> FQ1train; \
        print $4" "$5,$7,$9,$11 >> FQ2train}' \
        trainData.pasted.txt

    #clean
    rm testData.pasted.txt trainData.pasted.txt pasted.txt
}



for R1gz in $inputDir/*R1*fastq.gz
do
    echo 'Processing' $R1gz

    R2gz=${R1gz//"R1"/"R2"}
    outputR1=$outputDir/$(basename $R1gz ".fastq.gz")
    outputR2=$outputDir/$(basename $R2gz ".fastq.gz")

    #unzip fq for convenience
    zcat $R1gz > $outputR1
    zcat $R2gz > $outputR2

    check_R1R2_seqName $outputR1 $outputR2 $test_percentage

    split $outputR1 $outputR2 $outputR1.train.fastq $outputR1.test.fastq $outputR2.train.fastq $outputR2.test.fastq $nTrain $nTest

    gzip $outputR1.train.fastq
    gzip $outputR1.test.fastq
    gzip $outputR2.train.fastq
    gzip $outputR2.test.fastq

    rm $outputR1 $outputR2
done
