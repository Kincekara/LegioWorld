version 1.0

task sketch_fasta {
  input {
    String samplename
    File fasta    
    Int kmer = 21
    Int sketch_size = 10000
    String docker = "kincekara/mash:2.3"
    Int cpu = 4
    Int memory = 8    
  }

  command <<<
    # version
    mash --version > VERSION
    # sketch
    mash sketch -p ~{cpu} -k ~{kmer} -s {sketch_size} -o ~{samplename} ~{fasta}
  >>>

  output {    
    File sketch = "~{samplename}.msh"
  }

  runtime {
  docker: "~{docker}"
  memory: "~{memory} GB"
  cpu: cpu
  disks: "local-disk 100 SSD"
  preemptible: 0
  }
}


task sketch_fastq {
  input {
    String samplename
    File read1
    File? read2    
    Int kmer = 21
    Int sketch_size = 10000
    String docker = "kincekara/mash:2.3"
    Int cpu = 4
    Int memory = 8    
  }  
  command <<<
    # version
    mash --version > VERSION

    if [ -f ~{read2} ]
    then
      # merge reads
      cat ~{read1} ~{read2} > ~{samplename}.merged.fastq.gz
      # sketch
      mash sketch -p ~{cpu} -k ~{kmer} -s {sketch_size} -o ~{samplename} ~{samplename}.merged.fastq.gz
    else
      mash sketch -p ~{cpu} -k ~{kmer} -s {sketch_size} -o ~{samplename} ~{read1}
  >>>

  output {    
    File sketch = "~{samplename}.msh"
  }

  runtime {
  docker: "~{docker}"
  memory: "~{memory} GB"
  cpu: cpu
  disks: "local-disk 100 SSD"
  preemptible: 0
  }
}

task screen {
  input {
    File assembly   
    File reference
    String samplename
    String docker = "kincekara/mash:2.3"
    Int? memory = 8
    Int? cpu = 4
  }

  command <<<
    # version
    mash --version > VERSION
    # screen assembly
    mash screen -p ~{cpu} ~{reference} ~{assembly} > ~{samplename}.mash.tsv
    # parse results
    sort -gr ~{samplename}.mash.tsv > ~{samplename}.mash.sorted.tsv
    taxon=$(awk -F "\t" 'NR==1 {print $6}' ~{samplename}.mash.sorted.tsv | sed 's/[^ ]* seqs] //' | sed 's/ \[.*//')
    echo $taxon > TAXON
    ratio=$(awk -F "\t" 'NR==1 {printf "%.2f\n",$1*100}' ~{samplename}.mash.sorted.tsv)
    echo $ratio > RATIO
    printf "$taxon\t$ratio\n" > ~{samplename}.top_taxon.tsv
  >>>

  output {
    String version = read_string("VERSION")
    File screen = "~{samplename}.mash.sorted.tsv"
    File top_taxon = "~{samplename}.top_taxon.tsv"
    String taxon = read_string("TAXON")
    Float ratio = read_float("RATIO")
    String mash_docker = docker
  }

  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk 100 SSD"
    preemptible: 0
  } 
}

task generate_db {
  input {   
  String name = "reference"
  File fastas  
  Int kmer = 21
  Int sketch_size = 10000
  String docker = "kincekara/mash:2.3"
  Int cpu = 16
  Int memory = 32    
  }

  command <<<
    # version
    mash --version > VERSION
    # generate db
    tar -xvf ~{fastas}
    list=$(ls | grep ".fna")
    for i in $list
      do
      #taxon=$(head -n1 $i | cut -d " " -f2,3)
      id=$(echo $i | grep -Eo "GCF_[0-9]+.[0-9]")
      mash sketch -p ~{cpu} -k ~{kmer} -s ~{sketch_size} -I $id $i 
      done
    mash sketch -o ~{name} *.msh
    # clean up
    rm *.fna *fna.msh 
  >>>

  output {
    String version = read_string("VERSION")
    File db = "~{name}.msh"
  }

  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk 100 SSD"
    preemptible: 0
  } 
}