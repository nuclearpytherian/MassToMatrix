# MassToMatrix
Making feature matrix of mass spectra for ML.


## Usage

### (1) Post-processing
> Converting raw spectrum data into dizitized values.

	root/Post_processing> Rscript post_processing.R config.json

Then, dizitized peak data will be generated in "xml_export" folder. The data format is xml. 


### (2) Make mass bin
> Making feature matrix for machine learning.

	root/make_massbin> python binpeak.py --tolerance 0.002 --bintype intensity

"mass_features.csv" will be exported.

	root/make_massbin> python binpeak.py --help

For more arguments..


## Citation
User is needed to cite as below;

	{MassToMatrix, author = Yong Ha In, title = {MassToMatrix, Making feature matrix for machine learning using mass spectrum data}, published = {\url{https://github.com/nuclearpytherian/MassToMatrix}}, year = {2021} }


## License
> Copyright 2021 "nuclearpyterian". All Rights Reserved.
