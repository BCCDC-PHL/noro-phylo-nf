#!/usr/bin/env nextflow

/*
== V0.1  ==
*/

import java.time.LocalDateTime

nextflow.enable.dsl = 2

include { concat_sequences ; align } from './modules/align.nf'
include { tree  				   } from './modules/tree.nf'
include { refine  				   } from './modules/refine.nf'
include { ancestral  		       } from './modules/ancestral.nf'
include { translate  		       } from './modules/translate.nf'
include { export  		       } from './modules/export.nf'

println "${LocalDateTime.now()}"

// prints to the screen and to the log
log.info """Norovirus Phylogenetics Pipeline
===================================
projectDir        : ${projectDir}
launchDir         : ${launchDir}
fastaInputDir     : ${params.fasta_input}
outdir            : ${params.outdir}
reference         : ${params.reference}
git repo          : $workflow.repository
git version       : $workflow.revision [$workflow.commitId]
user              : $workflow.userName
""".stripIndent()


workflow {
    ch_start_time = Channel.of(LocalDateTime.now())
    ch_pipeline_name = Channel.of(workflow.manifest.name)
    ch_pipeline_version = Channel.of(workflow.manifest.version)
    
    ch_reference = Channel.fromPath(params.reference)

    ch_metadata = params.metadata == 'NO_FILE' ? Channel.fromPath('NO_FILE') : Channel.fromPath(params.metadata)


    ch_config = Channel.fromPath([params.config_auspice, params.config_colors, params.config_lat_long]).collect()

    // Catch invalid reference input combinations 
    reference_gb_format = (params.ref =~ /.+\.[Gg]b$/)

    if (!reference_gb_format && params.reference_annotation == 'NO_FILE' ){                         // Cannot have an empty --ref_anno parameter if reference is in non-GenBank format
        error "ERROR: Parameter --reference_annotation (.gff3 or .gb format) must be specified if non-GenBank reference is provided under --reference."
    }
    if (params.reference_annotation != 'NO_FILE' && !(params.reference_annotation =~ /.+\.gff.?|.+\.[Gg]b/ ) ){    
        error "ERROR: Parameter --reference_annotation must be in either .gff or .gb (GenBank) format."
    }
    
    // Load the ref_anno_ch channel appropriately 
    if (reference_gb_format){                                                         // Copy the ref_ch channel if in GenBank format (ref_ch can be reused as ref_anno_ch)
        ch_reference_annotation = ch_reference
    }else{                                                                      // Load new channel from scratch if different reference annotation format specified
        ch_reference_annotation = Channel.fromPath(params.reference_annotation, checkIfExists:true)
    }


    main:  

        if (params.fasta_dir) {
            ch_fasta_files = Channel.fromPath(params.fasta_search_paths)
            ch_multifasta = concat_sequences(ch_fasta_files.collect())
        }else {
            ch_multifasta = Channel.fromPath(params.sequences)
        }


        align(ch_multifasta, ch_reference)
        
        tree(align.out)

        refine(tree.out, align.out, ch_metadata)

        ancestral(refine.out.tree, align.out)

        translate(refine.out.tree, ch_reference_annotation, ancestral.out.node_data)

        ch_node_data = Channel.empty()
        ch_node_data = ch_node_data.mix(refine.out.node_data)
        ch_node_data = ch_node_data.mix(ancestral.out.node_data)
        ch_node_data = ch_node_data.mix(translate.out.node_data)
        ch_node_data = ch_node_data.collect()

        export(
            refine.out.tree, 
            ch_metadata, 
            ch_node_data,
            ch_config
        )
}