version 1.0

import "../tasks/task_mash.wdl" as mash
import "../tasks/task_datasets.wdl" as datasets

workflow mashDB {

  meta {
  description: "Generate MASH reference database"
  }

  input {
  String accessions 
  String? db_name = "reference"  
  Int? kmer = 25
  Int? sketch_size = 100000
  }
  
  call datasets.download {
    input:
      accession = accessions         
  }  

  call mash.generate_db {
    input:
      name = db_name,
      fastas = download.reference,
      kmer = kmer,
      sketch_size = sketch_size
  }
 
 output {
    File mash_reference = generate_db.db
  }
}