process export {
	tag "Export Auspice JSON File"
	publishDir "${params.outdir}/auspice", mode: 'copy'

	input:
	path(tree_refine)
	path(metadata)
	path(node_data)
	tuple path(config_auspice), path(config_colors), path(config_lat_long)

	output:
	path("${params.run_name}.json")

	script:
	metadata = metadata.name == 'NO_FILE' ? "" : "--metadata ${metadata}"

	"""
	export AUGUR_RECURSION_LIMIT=${params.recursion_limit}

	augur export v2 \
		--tree ${tree_refine} \
		${metadata} \
		--node-data ${node_data} \
		--colors ${config_colors} \
		--lat-longs ${config_lat_long} \
		--minify-json \
		--auspice-config ${config_auspice} \
		--output ${params.run_name}.json
	"""
}