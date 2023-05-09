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
    Int kmer
    Int sketch_size
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
      mash sketch -m 2 -p ~{cpu} -k ~{kmer} -s ~{sketch_size} -I ~{samplename} -o ~{samplename}.reads ~{samplename}.merged.fastq.gz
    else
      mash sketch -m 2 -p ~{cpu} -k ~{kmer} -s ~{sketch_size} -I ~{samplename} -o ~{samplename}.reads ~{read1}
    fi
  >>>

  output {    
    File sketch = "~{samplename}.reads.msh"
  }

  runtime {
  docker: "~{docker}"
  memory: "~{memory} GB"
  cpu: cpu
  disks: "local-disk 100 SSD"
  preemptible: 0
  }
}

task screen_reads {
  input {
    File read1
    File? read2   
    File reference
    String samplename
    String docker = "kincekara/mash:2.3"
    Int? memory = 8
    Int? cpu = 4
  }

  command <<<
    # version
    mash --version > VERSION
    if [ -f ~{read2} ]
    then
      cat ~{read1} ~{read2} > ~{samplename}.merged.fastq.gz
      mash screen -p ~{cpu} ~{reference} ~{samplename}.merged.fastq.gz > ~{samplename}.screen.tsv
    else
      mash screen -p ~{cpu} ~{reference} ~{read1} > ~{samplename}.screen.tsv
    fi

    # parse results
    sort -gr ~{samplename}.screen.tsv > ~{samplename}.mash.sorted.tsv
    taxon=$(awk -F "\t" 'NR==1 {print $6}' ~{samplename}.mash.sorted.tsv | cut -d " " -f4,5)
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
    tar -I pigz -xvf ~{fastas}
    mash sketch -p ~{cpu} -k ~{kmer} -s ~{sketch_size} -o ~{name} *.fna
    # clean up
    rm *.fna
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