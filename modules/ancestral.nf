process ancestral {

    tag "Reconstructing Ancestral States "

    publishDir "${params.outdir}/ancestral/", mode: 'copy'

    input:
    path(tree_refined)
	path(alignment)

    output:
    path("node_data_ancestral.json"), emit: node_data

    """
    augur ancestral \
        --tree ${tree_refined} \
        --alignment ${alignment} \
        --output-node-data node_data_ancestral.json \
        --keep-overhangs \
        --keep-ambiguous
    """
}