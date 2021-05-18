# Library
library(jsonlite)
library(MALDIquant)
library(XML)

# APIs
# Reading spectrum data .csv
tqdm_r = function(i, total_len){
  percents = c(0.2,0.4,0.6,0.8,1)
  if (is.element(i/total_len, percents)){
    print(paste0("processing... ",round(i/total_len,1)*100, "%"))
  }
}


read_csv_time_data = function(path){
  csv_list = list.files(path = path, pattern = '.csv')
  getwd_b = getwd()
  setwd(path)
  ini_spectra = list()
  for(i in 1:length(csv_list)){
    tqdm_r(i, length(csv_list))
    csv = read.csv(csv_list[i], stringsAsFactors = F)
    mass = as.numeric(csv[,1])
    intensity = as.numeric(csv$Intensity)
    metaData = list(filename=csv_list[i])
    try({
      s = createMassSpectrum(mass=mass, intensity=intensity,
                             metaData = metaData)
      ini_spectra = append(ini_spectra, s)
    }, silent = T)
  }
  setwd(getwd_b)
  return(ini_spectra)
}


post_processing_spectrum = function(spectra, config){
  spectra = transformIntensity(spectra, method = config$transformIntensity)
  smoothing_iteration = as.numeric(config$smoothing_iteration)
  for(r in 1:smoothing_iteration){
    spectra = smoothIntensity(spectra, method = config$smoothIntensity, halfWindowSize = 10)
  }
  spectra = removeBaseline(spectra, method = config$removeBaseline, iteration = 100)
  spectra = calibrateIntensity(spectra, method = config$calibrateIntensity)
  alignment = ifelse(config$alignBoolean == 1, T, F)
  if(alignment == T){
    spectra = alignSpectra(spectra, halfWindowSize = 20, SNR = 5, tolerance = config$alignTolerance, warpingMethod = config$alignSpectra)
  }
  return(spectra)
}

peak_picking = function(spectra_processed, config){
  peaks = detectPeaks(spectra_processed, method = config$detectPeaks, halfWindowSize = 20, SNR=config$alignment_snr_threshold)
  return(peaks)
}

massy_db_snr_cut = function(massy_db, snr_cut, len_cut, mass_range){
  
  for(i in 1:length(massy_db)){
    snr = massy_db[[i]]@snr
    mz = massy_db[[i]]@mass
    intensity = massy_db[[i]]@intensity
    
    snr_1 = snr[mz >= mass_range[1] & mz < mass_range[2] & snr >= snr_cut]
    mz_1 = mz[mz >= mass_range[1] & mz < mass_range[2] & snr >= snr_cut]
    intensity_1 = intensity[mz >= mass_range[1] & mz < mass_range[2] & snr >= snr_cut]
    no_redun_intensity_snr_1 = intensity_1 + snr_1 * 0.01
    
    if(length(mz_1) < len_cut){
      len_cut_ex = length(mz_1)
    } else {
      len_cut_ex = len_cut
    }
    
    cut_criteria = no_redun_intensity_snr_1[rev(order(no_redun_intensity_snr_1))][len_cut_ex]
    select = ifelse(no_redun_intensity_snr_1 >= cut_criteria, 1, 0)
    intensity_2 = intensity_1[select %in% 1]
    intensity_2 = intensity_2 / max(intensity_2)
    massy_db[[i]]@snr = snr_1[select %in% 1]
    massy_db[[i]]@mass = mz_1[select %in% 1]
    massy_db[[i]]@intensity = intensity_2
    
    if(length(names(massy_db[[i]]@metaData)[names(massy_db[[i]]@metaData) %in% 'weight']) > 0){
      w = massy_db[[i]]@metaData$weight
      w_1 = w[mz >= mass_range[1] & mz < mass_range[2] & snr >= snr_cut]
      massy_db[[i]]@metaData$weight = w_1[select %in% 1]
    }
  }
  
  return(massy_db)
}


exporting_massy_to_xml = function(xml_db, export_directory){
  getwd_b = getwd()
  if(class(xml_db) != "list"){
    xml_db = list(xml_db)
  }
  setwd(export_directory)
  for(i in 1:length(xml_db)){
    mz_peaked = xml_db[[i]]@mass
    intensity_peaked = xml_db[[i]]@intensity
    snr_peaked = xml_db[[i]]@snr
    filename = gsub(".csv", "", xml_db[[i]]@metaData$filename)
    
    df = data.frame(mz=round(mz_peaked,2), intensity=round(intensity_peaked,6), snr=round(snr_peaked,2), stringsAsFactors = F)
    
    prefix='<?xml version="1.0" encoding="euc-kr"?>'
    data_name = gsub(".xml", "", filename)
    
    listToXML <- function(df, name) {
      xml <- xmlTree("document", attrs=c(name=name))
      for (i in 1:nrow(df)) {
        xml$addTag("PeakInfo", attrs=c(No=i, mz=df$mz[i], Intensity=df$intensity[i], SNR=df$snr[i]))
      }
      xml$closeTag()
      return(xml)
    }
    ret <- listToXML(df, data_name)
    out <- saveXML(ret, prefix=prefix)
    write(out, file=paste0(data_name, ".xml"))
  }
  setwd(getwd_b)
}


