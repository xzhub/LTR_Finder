# LTR_Finder

NOTE: This repository is not maintained anymore. I can only try to resolve/answer easy issues/questions. I may not have the time to do extensive debugging. If there is any issue or bug you found and fixed, please submit a pull request, I'll try my best to review then add it into the code base. Thanks!

## Introduction
LTR_Finder is an efficient program for finding full-length LTR retrotranspsons in genome sequences.

The Program first constructs all exact match pairs by a suffix-array based algorithm and extends them to long highly similar pairs. Then Smith-Waterman algorithm is used to adjust the ends of LTR pair candidates to get alignment boundaries. These boundaries are subject to re-adjustment using supporting information of TG..CA box and TSRs and reliable LTRs are selected. Next, LTR\_FINDER tries to identify PBS, PPT and RT inside LTR pairs by build-in aligning and counting modules. RT identification includes a dynamic programming to process frame shift. For other protein domains, LTR\_FINDER calls ps_scan (from PROSITE, http://www.expasy.org/prosite/) to locate cores of important enzymes if they occur. Then possible ORFs are constructed based on that. At last, the program reports possible LTR retrotransposon models in different confidence levels according to how many signals and domains they hit.

## Installation
1. ```cd source```
2. ```make```
3. Add the current path to $PATH: 
   ```echo "export PATH=\$PATH:$PWD" >> ~/.bashrc```

## Usage
1. Read help.pdf
2. Example of figure output:
```
cd source
./ltr_finder test/3ds_72.fa -P 3ds_72 -w2 -f /dev/stderr 2>&1 > test/3ds_72_result.txt | perl genome_plot.pl test/  
``` 

## Reference
Xu, Zhao, and Hao Wang. “LTR_FINDER: an efficient tool for the prediction of full-length LTR retrotransposons.” Nucleic Acids Research 35, suppl. 2 (2007): W265-W268. 

## License
This software is free for non-commercial use. For commercial use, a software agreement is required.
