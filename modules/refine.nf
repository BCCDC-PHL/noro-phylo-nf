process refine {
    tag "Refine Tree"

    publishDir "${params.outdir}/tree/", mode: 'copy'

    input:
    path(tree)
    path(alignment)
    path(metadata)

    output:
    path("tree_refine.nwk"), emit: tree
    path("node_data_refine.json"), emit: node_data

    script:
    time_tree = params.time_tree ? "--timetree" : ""
    root_value = params.root_name ? "--root ${params.root_name}" : "--keep-root" 
    metadata = metadata.name == 'NO_FILE' ? "" : "--metadata ${metadata}"
    """
    augur refine \
        --tree ${tree} \
        --alignment ${alignment} \
        ${metadata} \
        ${time_tree} \
        ${root_value} \
        --divergence-units ${params.divergence_units} \
        --output-tree tree_refine.nwk \
        --output-node-data node_data_refine.json
    """
}