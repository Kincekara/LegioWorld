version 1.0

import "../tasks/task_version.wdl" as version
import "../tasks/task_mash.wdl" as mash
import "../tasks/task_datasets.wdl" as datasets


workflow mashDB {

  meta {
  description: "Generate MASH reference database"
  }

  input {
  File dataset
  String? db_name = "reference"  
  Int? kmer = 25
  Int? sketch_size = 100000
  }

  call version.version_capture {
    input:    
  }
  
  call datasets.download_list {
    input:
      dataset = dataset      
  }  

  call mash.generate_db {
    input:
      name = db_name,
      fastas = download_list.reference,
      kmer = kmer,
      sketch_size = sketch_size
  }
 
 output {
    String mashdb_version = version_capture.version
    File reference_fastas = download_list.reference
    File mash_reference = generate_db.db
  }
}