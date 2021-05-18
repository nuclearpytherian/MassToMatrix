

cat("Executing Post-processing!")


# Source
work_path = getwd()
setwd("..")
home_path = getwd()
source("Utils/functions.R")

# Args
args = commandArgs(trailingOnly = T)
config = fromJSON(paste0("Post_processing/", args))

# Dataset
spectra = read_csv_time_data(gsub("\\", "/", config$data_path, fixed = T))

# Post-processing
spectra_processed = post_processing_spectrum(spectra, config)

# Peak picking
peaked = peak_picking(spectra_processed, config)
peaked_truncated = massy_db_snr_cut(peaked, snr_cut=config$truncate_SNR_threshold, 
                                    len_cut = config$truncate_len_threshold, 
                                    mass_range = c(config$mass_range_start, config$mass_range_end))

# Exporting
exporting_massy_to_xml(peaked_truncated, "xml_export")


cat("Finished!")