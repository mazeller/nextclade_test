#! /usr/bin/env bash
set -euv

INFILE="sequences.fasta"
REF="reference.fasta"
REF_GFF="genome_annotation.gff"

[[ -d "results" ]] || mkdir results

echo "strain|clade_membership|year" | tr '|' '\t' > metadata.tsv
grep ">" ${INFILE} \
  | sed 's/>//g' \
  | awk -F'|' '{print $0"\t"$1"\t"$2}' >> metadata.tsv

augur align \
  --sequences ${INFILE} \
  --reference-sequence ${REF} \
  --output results/prrsv_aln.fasta \
  --fill-gaps \
  --nthreads 1

augur tree \
  --alignment results/prrsv_aln.fasta \
  --output results/tree.nwk \
  --nthreads 1

augur refine \
  --tree results/tree.nwk \
  --alignment results/prrsv_aln.fasta \
  --metadata metadata.tsv \
  --output-tree results/refined_tree.nwk \
  --output-node-data results/branch_labels.json

augur ancestral \
  --tree results/refined_tree.nwk \
  --alignment results/prrsv_aln.fasta \
  --output-node-data results/nt-muts.json \
  --inference joint

augur translate \
  --tree results/refined_tree.nwk \
  --ancestral-sequences results/nt-muts.json \
  --reference-sequence ${REF_GFF} \
  --output results/aa-muts.json

augur traits \
  --tree results/refined_tree.nwk \
  --metadata metadata.tsv \
  --output results/clade_membership.json \
  --columns year clade_membership

augur export v2 \
  --tree results/refined_tree.nwk \
  --auspice-config auspice_config.json \
  --colors colors.tsv \
  --node-data \
    results/branch_labels.json \
    results/clade_membership.json \
    results/nt-muts.json \
  --output results/tree.json
	#results/aa-muts.json \
	
#augur export v2 \
#  --tree results/refined_tree.nwk \
#  --node-data \
#    results/branch_labels.json \
#    results/clade_membership.json \
#    results/nt-muts.json \
    #results/aa-muts.json \
#  --output results/tree.json
  
echo "Done! look at results/tree.json"

# Copy in the meta entries or maybe use something like
# https://github.com/nextstrain/dengue/blob/main/config/auspice_config_all.json
#
# zip into PRRSV.zip
# nextclade run -D PRRSV.zip -j 4 \
#   --output-fasta output_alignment.fasta \
#   --output-translations translations_{gene}.zip \
#   --output-insertions insertions.csv \
#   sequences.fasta