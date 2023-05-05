version 1.0

task fetch_reference {
  input {
    String taxon
    String docker = "kincekara/ncbi_datasets:v14.26.0"
  }

  command <<<
    # version
    datasets version | cut -d " " -f3 > VERSION
    # fetch reference   
    datasets summary genome taxon "~{taxon}" --reference > ref.json
    acc_id=$(jq -r '.reports[0].accession' ref.json)
    if [ ! -z "$acc_id" ]
    then
      datasets download genome accession $acc_id
      unzip ncbi_dataset.zip
      mv $(find ncbi_dataset/data -name "$acc_id*_genomic.fna") ~{taxon}_ref.fa
    fi
  >>>

  output {
    String version = read_string("VERSION")
    File? reference = "~{taxon}_ref.fa"
  }

  runtime {
      docker: "~{docker}"
      memory: "256 MB"
      cpu: 1
      disks: "local-disk 100 SSD"
      preemptible:  0
  }
}


task download {
  input {
    String accession  
    String docker = "kincekara/ncbi_datasets:v14.26.0"
  }

  command <<<
    # version
    datasets version | cut -d " " -f3 > VERSION
    # download seqs
    datasets download genome accession ~{accession}
    unzip ncbi_dataset.zip && rm ncbi_dataset.zip
    cd ncbi_dataset
    find . -name "*genomic.fna" -exec mv {} . \;
    rm -rf data
    tar -czvf reference.tar.gz *
    # clean up
    rm *genomic.fna
  >>>

  output{
    String version = read_string("VERSION")
    File reference = "ncbi_dataset/reference.tar.gz"
  }

  runtime {
    docker: "~{docker}"
    memory: "256 MB"
    cpu: 1
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}