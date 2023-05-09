version 1.0

task fetch_reference {
  input {
    String taxon
    String docker = "kincekara/ncbi_datasets:v14.27.0"
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
      mv $(find ncbi_dataset/data -name "*_genomic.fna") ~{taxon}_ref.fa
    fi
  >>>

  output {
    String version = read_string("VERSION")
    File? reference = "~{taxon}_ref.fa"
  }

  runtime {
      docker: "~{docker}"
      memory: "4 GB"
      cpu: 1
      disks: "local-disk 100 SSD"
      preemptible:  0
  }
}


task download {
  input {
    String accession
    String prefix = "reference"  
    String docker = "kincekara/ncbi_datasets:v14.27.0"
  }

  command <<<
    # version
    datasets version | cut -d " " -f3 > VERSION
    # download seqs
    datasets download genome accession ~{accession}
    unzip ncbi_dataset.zip
    cd ncbi_dataset
    find . -name "*genomic.fna" -exec mv {} . \;
    tar -czvf "../~{prefix}.tar.gz" *genomic.fna
    # clean up
    cd ..
    rm -rf ncbi_dataset
    rm ncbi_dataset.zip
  >>>

  output{
    String version = read_string("VERSION")
    File reference = "~{prefix}.tar.gz"
  }

  runtime {
    docker: "~{docker}"
    memory: "16 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}

task download_list {
  input {
    File dataset
    String prefix = "fastas" 
    String docker = "kincekara/ncbi_datasets:v14.27.0"
  }

  command <<<
    # version
    datasets version | cut -d " " -f3 > VERSION
    # download seqs
    awk -F "\t" 'NR>1 {print $1}' ~{dataset} > inputfile.txt
    datasets download genome accession --inputfile inputfile.txt
    unzip ncbi_dataset.zip
    cd ncbi_dataset
    find . -name "*genomic.fna" -exec mv {} . \;
    tar -I pigz -cvf "../~{prefix}.tar.gz" *genomic.fna
    # clean up
    cd ..
    rm -rf ncbi_dataset
    rm ncbi_dataset.zip
  >>>

  output{
    String version = read_string("VERSION")
    File reference = "~{prefix}.tar.gz"
  }

  runtime {
    docker: "~{docker}"
    memory: "32 GB"
    cpu: 16
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}

