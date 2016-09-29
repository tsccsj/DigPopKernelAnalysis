# DigPopKernelAnalysis
KernelAnalysis is software developed to create indicator maps from Digital Populations realizations based on the attributes of household attributes and person attributes. It aims to answer questions of this kind: give all or a subset of population (or households), what is the ratio of the population (or households) that meets certain standards. What does it do?

#Software instruction
http://digitalpopulations.pbworks.com/w/page/88807286/KernelAnalysis

#What does it do?
For each of the Digital Populations realizations, it performs the following steps:
 1. Find the persons (or households) that belongs to the targeting sub-population by reading through the household and population files of this Digital Populations realization
 2. Find the persons (or households) within the sub-population that meet user-specific conditions (referred as cases)
 3. Perform kernel density estimation to estimate density distribution of results from both step 1 (sub-population) and step 2 (cases)
 4. Calculate the ratio map of the case density to the  sub-population density
For each map cell, summarize the mean, median and etc from all the ratio maps, and output the summarized maps in the form of GeoTIFF.

#Prerequisites
 CUDA
 GDAL

#To run the code, run the executable with only one arguments (the input parameter file)
DigPopKernelAnalysis inputParameterFile

Input parameter file
The input parameter files let users to specify the input and output of the code, the questions to be answered, and the parameters of the kernel density estimation. The input parameter file is a CSV file, with the first line as the file header and each question per line.
The meaning of each column is described below: 
 1. OutputFileName: the name and directory of output files. It is assumed that output maps will be named as OutputFile_mean.tif, outputFileName_max.tif and etc.
 2. InputDigPopNamePreNumber: the name and directory of input Digital Populations realizations files.
  i. It is assumed that input household files will be named 'InputFile''realizationNumber'-households.csv
  ii. and population files will be named 'InputFile''realizationNumber'-population.csv
 3. MinRzn: the index of the first realization to be analyzed
 4. NumRzn: the number of realizations to be analyzed
  i. Realization number is assumed to have three digit in file names
 5. ProjectionCode:  the EPSG code indicating the projection information of input coordiates
 6. NorthBounds: the north bound (Max of Y) of study area
 7. EastBounds: the east bound (Max of X) of study area
 8. SouthBounds: the north bound (Min of Y) of study area
 9. WestBounds: the north bound (Min of X) of study area
 10. LatticeSize: the cell size of output raster maps
 11. KernelBandwidth: the bandwidth used by the kernel density estimation
  i. If a zero(0) bandwidth is used, the code simply count the number of persons (households) in each cell and calculate the ratio
 12. HouseholdOrPopulationMap: the indicator of whether the analysis is based on household or population
  i. H for household. Thus it will calculate the % of households
  ii. P for population. Thus it will calculate the % of persons that
 13. SubPopulation: the conditions of target sub-population. It will be treated as the denominator when calculating the ratio
  i. If your SubPopulation is All, just put a "\*" here, or leave this field empty. In this case, you are calculating the ratio to all the population or households
  ii. Only support "and" and "or" operator 
 14. MapLogic: additional conditions that specify the standards to calculate the ratio for. It will be treated as the numerator when calculating the ratio
 15. PersonsPerHousehold:  the column name in the household file which represents the the number of people in each household

Logic condition used in MapLogic and SubPopulation
The logic conditions used in column SubPoplulation and MapLogic of the input parameter file follow the following rules.
 1. Basic condition: attributeName:startValue:endValue. For example, AGE:0:17 means 0<=AGE<=17
  i. NOT operator: "!" before the attributeName. For example, !AGE:12:17 means NOT 12<=AGE<=17
  ii. If H is specified in  HhOrPop, only household attributes can be used in SubPoplulation and MapLogic
  iii. If P is specified in  HhOrPop, both household attributes and population attributes can be used in SubPoplulation and MapLogic
 2. "And"  connecting basic conditions: BasicCondition1andBasicCondition2
  i. AND operator: "and" between basic conditions (no parenthesis is needed and allowed)
  ii. For example:  AGE:60:999andRELIG:5:5
 3. "Or" connecting "and" clause: AndClause1orAndClause1
  i. OR operator: "or" between AND clasue (no parenthesis is needed and allowed)
  ii. For example:  AGE:0:12orAGE:13:99andLIT:1:1 means people who are kids ( under 13) or literate order people
  iii. Can only be applicable to MapLogic but not MapLogic


#Output
 1. 'outputFileName'_rzn'rznNumber'.tif: The ratio maps for each realization.
 2. 'outputFileName_mean.tif: The mean value of the ratio maps from all input Digital Populations realizations
 3. 'outputFileName'max.tif: The maximum value of the ratio maps from all input Digital Populations realizations
 4. 'outputFileName'_min.tif: The minimum value of the ratio maps from all input Digital Populations realizations
 5. 'outputFileName'_1q.tif: The 1st quantile value of the ratio maps from all input Digital Populations realizations
 6. 'outputFileName'_3q.tif: The 3st quantile value of the ratio maps from all input Digital Populations realizations
 7. 'outputFileName'_median.tif: The median value of the ratio maps from all input Digital Populations realizations
 8. 'outputFileName'_nNA.tif: The number of times this map cell has value (not NA) among all the ratio maps from all input Digital Populations realizations
 10. 'outputFileName'_meanPop.tif: The median value of the sub population maps from all input Digital Populations realizations
 11. 'outputFileName'_range.tif: The range (max - min) of the ratio maps from all input Digital Populations realizations
 12. 'outputFileName'_iqr.tif: The inter quantile range (1st quantile - 3rd quantile) of the ratio maps from all input Digital Populations realizations
 13. 'outputFileName'_metadata.txt: The metadata of the analysis

#Change logs
--------------------------------------------------------------------------------------------------
DigPopKernelAnalysisV7

Minor bug fixes

Change the output data format from ASCII Grid to GeoTIFF

--------------------------------------------------------------------------------------------------
DigPopKernelAnalysisV6

Change the way how some parameters are passed among software components.

Make the software more robust to incorrect input files.

Provide more meaningful error messages.

For the subset selection tool:
 - Change the increased field in the Houshold file from "Persons chosen in each household" to "The original number of persons in eahc household"
 - Correspondingly, the original "persons per household field" is kept, with the content replaced by the actual number of persons chosen in that household.

Merged the Summary statistics generation tool into the Raster calculation script, so that the user doesn't need a seperate line in the script to generate summary statistics.

--------------------------------------------------------------------------------------------------
DigPopKernelAnalysisV5

Add some supplementary tool sets, and script to the software

The supplemetary tools include:
 - Subset selection tools for DigPop realizations
      Select subset of households / populations based on proportion map or user specified standard
 - Raster calculation script
      Use GDAL commands to perform raster calculation
 - Summary statistics generation
      Generate summary statistis for raster calculation results

Add a new parameter to DigPopKernelAnalysis: the projection EPSG code, which indicates the projection information of the input and thus output data

--------------------------------------------------------------------------------------------------
DigPopKernelAnalysisV4

Include a "standard deviation" map to the final output summary

Output the raw ratio map of each of the realizations in ascii format

In include the raster calcuate part, subset selection part and stand-along raster summary

--------------------------------------------------------------------------------------------------
DigPopKernelAnalysisV3

The software now is more robust to corrupted input files.

Handle the problems when the number of questions is too large.

Add a new output file "metadata.txt" for each question.

--------------------------------------------------------------------------------------------------
DigPopKernelAnalysisV2

Add a new field to the input parameter file "PersonsPerHousehold"
 - Represent the column name of PersonsPerHousehold

A much faster KDE implementation

--------------------------------------------------------------------------------------------------
DigPopKernelAnalysis

New name for the software!

--------------------------------------------------------------------------------------------------
DPIndicatorV5:

To run the code, run DPIndictor inputFile

Support the NOT operator
 - For both the subpopualtion and maplogic
 - The syntax is "!" at the very front of each logic element
 - Now can only be used for each element of the logic

Suppot commenting the imput parameter file

Change the excecutable file name to "DigPopKernelAnalysis"

Input formate:
 - OutputFileName,InputDigPopNamePreNumber,MinRzn,NumberRzn,NorthBounds,EastBounds,SoutBounds,WestBounds,LatticeSize,KernelDiameter,HouseholdOrPopulationMap,SubPopulation,MapLogic

Example:
 - ../result/Relig_Buddhist_Young,~/data/digpop/rzn,1,3,2816700,322900,2526600,122500,1000,1000,P,!RELIG:2:2,!AGE:0:17
--------------------------------------------------------------------------------------------------
DPIndicatorV4:

To run the code, run DPIndictor inputFile

Support subpopulaion
 - The ratio will be calcuated based on the subpopulation
 - A new column of the imput file: SubPopulation is added
 - The subpopulation only support and operator

Input formate:
 - OutputFileName,InputDigPopNamePreNumber,MinRzn,NumberRzn,NorthBounds,EastBounds,SoutBounds,WestBounds,LatticeSize,KernelDiameter,HouseholdOrPopulationMap,SubPopulation,MapLogic

Example:
 - ../result/Relig_Buddhist_Young,~/data/digpop/rzn,1,3,2816700,322900,2526600,122500,1000,1000,P,RELIG:2:2,AGE:0:17

--------------------------------------------------------------------------------------------------
DPIndicatorV3:

Both the 'and' and 'or' operators are supported in map conditions
 - The syntax of the 'and' operator is "&"
 - The syntax of the 'or' operator is "|"
 - It only support one order: the "and" clauses connected by "or"

When generating ratio maps based on population, both population conditions and household conditions can be supported
 - No distinction needs to be made for these two kinds of conditions
 - Suppose that no attributes of Population and Household have the same name except for the X and Y

Input formate:
 - OutputFileName,InputDigPopNamePreNumber,MinRzn,NumberRzn,NorthBounds,EastBounds,SoutBounds,WestBounds,LatticeSize,KernelDiameter,HouseholdOrPopulationMap,MapLogic

Example:
 - ../result/UtilAccess5_Kernel1600,~/data/digpop/rzn,1,5,2816700,322900,2526600,122500,200,1600,H,BD11A_TOILET:2:2&ELECTRC:2:2&BD11A_WATSRC:3:3|BD11A_TOILET:3:3&ELECTRC:2:2&BD11A_WATSRC:1:2
--------------------------------------------------------------------------------------------------
DPIndicatorV2:

Have only one C programs and a JAR file: AscToKml.jar
 - dpbKDE and rasterStat are covereted into classes
 - system calls are still used for calling the AscToKml.jar, and delete intermediate files

--------------------------------------------------------------------------------------------------
DPIndicator V1:

Have three seperate programs not including the AscToKml.jar.

 - dpIndicator: read in the input parameters and call the other two programs, delete intermediate outputs through system calls
 - dpbKDE: do the kernel density estimation and generate the output ratio files
 - rasterStat: summarize the rasters and generates ASCii grid outputs

"and" operator is supported in the map condition, and the syntax is "and" seperating mutiple simple conditions

Input formate:
 - OutputFileName,InputDigPopNamePreNumber,MinRzn,NumberRzn,NorthBounds,EastBounds,SoutBounds,WestBounds,LatticeSize,KernelDiameter,HouseholdOrPopulationMap,MapLogic

Example:
 -	../result/UtilAccess1,~/data/digpop/rzn,1,5,2816700,322900,2526600,122500,400,1000,H,BD11A_TOILET:1:1andELECTRC:1:1andBD11A_WATSRC:1:2
