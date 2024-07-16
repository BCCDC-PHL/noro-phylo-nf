process concat_sequences {

	tag "Concatenating Sequences"

	publishDir "${params.outdir}/align/", mode: 'copy'

	input:
	path(fasta_files)

	output:
	path("concatenated.fasta")

	"""
	cat ${fasta_files} > concatenated.fasta
	"""
}

process align {

	label "heavy"

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