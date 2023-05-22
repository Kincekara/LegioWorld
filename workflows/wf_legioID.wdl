version 1.0

import "../tasks/task_version.wdl" as version
import "../tasks/task_fastp.wdl" as fastp
import "../tasks/task_bbtools.wdl" as bbtools
import "../tasks/task_mash.wdl" as mash

workflow legioID {

  meta {
  description: "Legionella Identification and Genome Assembly"
  }

  input {
  File read1
  File read2
  String samplename
  Int minimum_total_reads = 30000
  File mash_reference
  }
 
  call version.version_capture {
    input:
  }

  call fastp.fastp_pe as fastp_trim {
    input:
      read1 = read1,
      read2 = read2,
      samplename = samplename 
  }

  if ( fastp_trim.total_reads > minimum_total_reads) {
    
    call bbtools.bbduk {
      input:
        read1_trimmed = fastp_trim.read1_trimmed,
        read2_trimmed = fastp_trim.read2_trimmed,
        samplename = samplename
    }

    call mash.screen_reads {
        input:
        read1 = bbduk.read1_clean,
        read2 = bbduk.read2_clean,
        samplename = samplename,
        reference = mash_reference
    }
  }

  output {
    # Version 
    String legioID_version = version_capture.version
    String legioID_analysis_date = version_capture.date    
    # FastP
    String fastp_version = fastp_trim.fastp_version
    String fastp_docker = fastp_trim.fastp_docker
    File fastp_report = fastp_trim.fastp_report
    Int total_reads = fastp_trim.total_reads
    Int total_reads_trim = fastp_trim.total_reads_trim
    Int r1_reads =  fastp_trim.r1_reads
    Int r2_reads = fastp_trim.r2_reads
    Float? r1_q30_raw = fastp_trim.r1_q30_raw
    Float? r2_q30_raw = fastp_trim.r2_q30_raw
    Float? r1_q30_trim = fastp_trim.r1_q30_trim
    Float? r2_q30_trim = fastp_trim.r2_q30_trim
    # BBtools
    File? phiX_stats = bbduk.phiX_stats
    String? bbtools_docker = bbduk.bbtools_docker
    String? bbtools_version = bbduk.bbmap_version
    String? phiX_ratio = bbduk.phix_ratio
    # Mash    
    String? taxon_reads = screen_reads.taxon
    Float? taxon_reads_percent = screen_reads.ratio
    File? reads_screen_result = screen_reads.screen   
  }
}