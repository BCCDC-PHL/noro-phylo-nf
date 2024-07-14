process tree {
	tag "Building IQTREE"
	publishDir "${params.outdir}/tree/", mode: 'copy'

	input:
	path(alignment)

	output:
	path("tree_base.nwk")

	"""
	augur tree \
	--nthreads ${task.cpus} \
	--alignment ${alignment} \
	--method ${params.tree_method} \
	--output tree_base.nwk
	"""
}
