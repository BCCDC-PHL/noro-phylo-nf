#!/usr/bin/env nextflow

/*
== V0.1  ==
*/

import java.time.LocalDateTime

nextflow.enable.dsl = 2

include { make_multifasta; get_background_sequences; make_msa; make_dates_file; make_tree; extract_sample_genes} from '../modules/phylo.nf'

workflow build_tree {
	take:
		ch_consensus_fasta
		ch_sample_db_pos
		ch_gene_db
		ch_gene_bool
	main:
		
		if (ch_gene_bool == True){ 
			extract_sample_genes(ch_consensus_fasta.join(ch_sample_db_pos))
			ch_sequences = extract_sample_genes.out.map{it -> it[1]}.mix(ch_gene_db).collect()
		}else{
			ch_sequences = ch_consensus_fasta.out.map{it -> it[1]}.collect()
		}
		
		
		make_multifasta(ch_sequences).set{ch_multifasta}

		if (params.background_path){
			get_background_sequences(ch_multifasta, Channel.fromPath(params.results_path))
			ch_multifasta = ch_multifasta.mix(get_background_sequences.out).collect()
		} 

		make_dates_file(ch_multifasta)
		make_msa(ch_multifasta)
		make_tree(make_msa.out.combine(make_dates_file.out))

	emit:
		align = make_msa.out
		tree = make_tree.out.tree

}

// workflow create_full_tree {
// 	take:
// 		ch_consensus_fasta
// 		ch_sample_db_pos
// 		ch_gene_db

// 	main:

// 		// Create multifasta of full-length sequences for final seqence analysis 
// 		make_multifasta(ch_consensus_fasta.out.map{it -> it[1]}.collect()).set{ch_sequences}

// 		// Add background sequences if others are detected in the specified path
// 		if (params.results_path){
// 			get_background_sequences(ch_sequences, Channel.fromPath(params.results_path))
// 			ch_sequences = ch_sequences.mix(get_background_sequences.out).collect()
// 		} 

// 		// Make a multiple sequence alignment of full-length sequences
// 		make_msa(ch_sequences)

// 		// Make a phylogenetic tree using full-length sequences
// 		make_tree(make_msa.out)
// }