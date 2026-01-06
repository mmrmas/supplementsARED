# supplementsARED
scripts used for analysis of colorimetric data from our ARED study

IJMacro_Supplement:
The main script is SUP_20210302_IJMacro_RecordingStation.ijm that runs as a macro witinh the ImageJ environment.
We follow the RGB colors over time of a set of ROIs that are within a camera stream.
It requires modifications based on the set-up of the assay, such as ROIs and directory names.
The result is a file with RGB values (Blue, Green, Red) and a set of commands that are used for the downstream R-script (IJMacroResutToPdf.R)
The last line can be copy-pasted and run in the terminal to activate the IJMacroResutToPdf.R
This script requires the IJ webcam plugin (https://imagej.nih.gov/ij/plugins/webcam-capture/index.html)

IJMacroResutToPdf.R:
This version of the script takes the output of the aforementioned ImageJ macro and produces a pdf file containing graphs of the resuzurin
color development, Euclidian Distances and basic summary of the replicates.

Experimental design:
The scripts were designed for one imaging staion with 2 96-well plates.
The first 2 plate columns contained control samples, the second 2 columns contained samples with antibiotics (exposed group)
The first well of the first column (A1 and A3) conatined wild-type cells.
The last well of the last column (H2 and H4) did not contain cells and served as negative controls.
This setup was repeated 2 times to fill the whole 96 well plate.

Welcome to contact me if you would like to aim for implementation and questions arise.
