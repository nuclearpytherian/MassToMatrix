# MALDIquant
Making feature matrix of mass spectra for ML.


## Usage

### (1) Post-processing
> Converting raw spectrum data into dizitized values.

	home/Post_processing> $ Rscript post_processing.R config.json


### (2) Make mass bin
> Making feature matrix for machine learning.

	home/make_massbin> $ python binpeak.py --tolerance 0.02 --bintype intensity

"mass_features.csv" will be exported.