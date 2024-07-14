process translate {
	tag "Translate Amino Acid Sequences"

	publishDir "${params.outdir}/translate", mode: 'copy'

	input:
	path(tree_refined)
	path(reference_annotation)
	path(node_data_ancestral)

	output:
	path("node_data_translate.json")

	"""
	augur translate \
		--tree ${tree_refined} \
		--ancestral-sequences ${node_data_ancestral} \
		--reference-sequence ${reference_annotation} \
		--output-node-data node_data_translate.json \
		"""
}