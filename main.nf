#!/usr/bin/env nextflow

/*
== V0.1  ==
*/

import java.time.LocalDateTime

nextflow.enable.dsl = 2

include { make_multifasta; get_background_sequences; make_msa; make_dates_file; make_tree; extract_sample_genes} from './modules/phylo.nf'
include { build_tree  } from './workflows/phylogenetics.nf'

println "HELLO. STARTING NOROVIRUS PHYLOGENETICS PIPELINE."
println "${LocalDateTime.now()}"

// prints to the screen and to the log
log.info """Norovirus Phylogenetics Pipeline
===================================
projectDir        : ${projectDir}
launchDir         : ${launchDir}
fastaInputDir     : ${params.fasta_input}
outdir            : ${params.outdir}
git repo          : $workflow.repository
git version       : $workflow.revision [$workflow.commitId]
user              : $workflow.userName
""".stripIndent()

// database          : ${params.db}
// Git repository    : $workflow.repository
// git commit id     : $workflow.commitId
// branch            : $workflow.revision
// pipeline run      : ${params.pipeline_short_name}
// pipeline version  : ${params.pipeline_minor_version}


workflow {
	ch_start_time = Channel.of(LocalDateTime.now())
	ch_pipeline_name = Channel.of(workflow.manifest.name)
	ch_pipeline_version = Channel.of(workflow.manifest.version)

	ch_human_ref = Channel.from(params.human_ref)
	ch_centrifuge_db = Channel.from(params.centrifuge_db)
	ch_blastdb_gtype_fasta = Channel.from(params.gtype_database)
	ch_blastdb_ptype_fasta = Channel.from(params.ptype_database)
	ch_fastq_input = Channel.fromFilePairs( params.fastq_search_path, flat: true ).map{ it -> [it[0].split('_')[0], it[1], it[2]] }.unique{ it -> it[0] }

	main:

		// GENE-SPECIFIC PHYLOGENETIC TREES
		create_gtree(make_consensus.out, ch_gene_db_vp1, ch_blastdb_gtype_fasta)
		create_ptree(make_consensus.out, ch_gene_db_rdrp, ch_blastdb_ptype_fasta)

		// Create multifasta of full-length sequences for final seqence analysis 
		make_multifasta(make_consensus.out.map{it -> it[1]}.collect()).set{ch_sequences}

		// Add background sequences if others are detected in the specified path
		if (params.results_path){
			get_background_sequences(ch_sequences, Channel.fromPath(params.results_path))
			ch_sequences = ch_sequences.mix(get_background_sequences.out).collect()
		} 

		// Make a multiple sequence alignment of full-length sequences
		make_msa(ch_sequences)

		// Make a phylogenetic tree using full-length sequences
		make_tree(make_msa.out)