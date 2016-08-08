# DigPopKernelAnalysis

Software instruction at
http://digitalpopulations.pbworks.com/w/page/88807286/KernelAnalysis

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

To run the code, run DPIndictor <inputFile>

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

To run the code, run DPIndictor <inputFile>

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
