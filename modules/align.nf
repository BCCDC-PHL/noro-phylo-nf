process concat_sequences {

	tag "Concatenating Sequences"

	publishDir "${params.outdir}/align/", mode: 'copy'

	input:
	path(input_folder)
	val(glob_pattern)

	output:
	path("concatenated.fasta")

	"""
	cat ${input_folder}/${glob_pattern} > concatenated.fasta
	"""
}

process align {

	tag "Aligning Sequences"
	publishDir "${params.outdir}/align/", mode: 'copy'

	input:
	path(multifasta)
	path(reference)

	output:
	path("alignment.fasta")

	"""
	augur align \
	--sequences ${multifasta} \
	--reference-sequence ${reference} \
	--output alignment.fasta \
	--fill-gaps \
	--nthreads ${task.cpus}
	"""
}