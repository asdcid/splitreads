# splitreads.sh

This is a script to randomly split a set of paired-end reads (splitReads_paired.sh) or single reads (splitReads_single.sh) into two subsets of predefined proportions. Files should be end with 'fastq.gz' or 'fq.gz'.

Usage: ./splitReads_paried.sh inputDir outputDir integer (1-99, default 10)

It's really just a reworking of some answers on biostars here: https://www.biostars.org/p/6544/

NOTE: The script does not work if the header has more than one domain.
e.g >readname 123 aaa  (do not work)
    >readname          (work)
