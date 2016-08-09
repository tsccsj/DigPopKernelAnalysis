#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "dpbKDE.cuh"
#include "rasterStat.cuh"

//DigPopKernelAnalysis csvForMapsFromRealizations
int main(int argc, char ** argv)
{
	if(argc != 2)
	{
		printf("Incorrect number of input arguments.\n");
		printf("./DigPopKernelAnalysis csvForMapsFromRealizations\n");
		exit(1);
	}

	FILE * parameterFile;
	if(NULL == (parameterFile = fopen(argv[1], "r")))
	{
		printf("Can't open csvForMapsFromRealizations File: %s\n", argv[1]);
		exit(1);
	}

	FILE * metaFile;

	char line[1000];
	char cleanLine[1000];

	bool hhOnly;
	char * inputFileName;
	char * outputFileName;
	char outputMetaFileName[4000];
	int minRzn;
	int numRzn;
	float xMin;
	float xMax;
	float yMin;
	float yMax;
	int projCode = 32646;
	float cellSize;
	float bandwidth;
	char * mapLogic;
	char logic[100];
	char * mapSubPop;
	char subPop[100];

	char * personColName;

	char command[1000];

	char * outputFileNamesList;
	int outputFileCount = 0;

	char inputPopulation[200];
	char inputHousehold[200];
	char kdeOutFile[200];
	char outputPCcount[200];

//To alucate current time
	struct tm * tm;
	time_t t;
	time(&t);
	tm = localtime(&t);

    fgets(line, 1000, parameterFile);

	while(NULL != fgets(line, 1000, parameterFile))
	{
		outputFileCount ++;
	}

	outputFileNamesList = (char *) malloc (sizeof(char) * 200 * outputFileCount);
	
	rewind(parameterFile);
	fgets(line, 1000, parameterFile);


	for(int i = 0; NULL != fgets(line, 1000, parameterFile); i++)
	{
		//Delete ' ' and '\t' and '"'
		int k = 0;
		for(int j = 0; j < strlen(line) + 1; j++)
		{
			if(line[j] != '\t' && line[j] != ' ' && line[j] != '\n' && line[j] != '\r' && line[j] != '\"')
			{
				cleanLine[k] = line[j];
				k ++;
			}
		}

		strcpy(line, cleanLine);

		//Handle lines begin with '#'
		if(line[0] == '#')
		{
			strcpy(outputFileNamesList + 200 * i, "");
			continue;
		}

		//Handle the commenting at the end of lines
		strtok(line, "#");

		//Handle empty lines V2
		if(k < 2)
		{
			strcpy(outputFileNamesList + 200 * i, "");
			continue;
		}

		//Delete lines with all ","
		bool allComma = true;
		for(int j = 0; j < strlen(line); j ++)
		{
			if(line[j] != ',')
			{
				allComma = false;
				break;
			}
		}
		if(allComma)
		{
			strcpy(outputFileNamesList + 200 * i, "");
			continue;
		}
		

		outputFileName = strtok(line, ",");
		inputFileName = strtok(NULL, ",");
		minRzn = atoi(strtok(NULL, ","));
		numRzn = atoi(strtok(NULL, ","));
		projCode = atoi(strtok(NULL, ","));
		yMax = atof(strtok(NULL, ","));
		xMax = atof(strtok(NULL, ","));
		yMin = atof(strtok(NULL, ","));
		xMin = atof(strtok(NULL, ","));
		cellSize = atof(strtok(NULL, ","));
		bandwidth = atof(strtok(NULL, ","));

		strcpy(outputFileNamesList + 200 * i, outputFileName);

		if(strcmp("H",strtok(NULL, ",")) == 0)
		{
			hhOnly = true;
		}
		else
		{
			hhOnly = false;
		}
		mapSubPop = strtok(NULL, ",");
		mapLogic = strtok(NULL, ",");
		personColName = strtok(NULL, ",");

		printf("Processing %s\n", outputFileName);
		sprintf(outputPCcount, "%s_PCcount", outputFileName);


		for(int j = 0; j < numRzn; j++)
		{
			sprintf(inputHousehold, "%s%03d-households.csv", inputFileName, (minRzn + j));
			sprintf(kdeOutFile, "%s_rzn%03d", outputFileName, (minRzn + j));

			strcpy(subPop, mapSubPop);
			strcpy(logic, mapLogic);

			if(hhOnly)
			{
				sprintf(inputPopulation, "-HHO");
			}
			else
			{
				sprintf(inputPopulation, "%s%03d-population.csv", inputFileName, (minRzn + j));
			}

			//printf("Input HH name: %s\n", inputHousehold);
			//printf("xMin: %f\t xMax:%f\nyMin: %f\tyMax: %f\n", xMin, xMax, yMin, yMax);
			//printf("cellsize: %f\t bandwidth:%f\n", cellSize, bandwidth);
			dpbKDE(inputPopulation, inputHousehold, kdeOutFile, outputPCcount, xMin, yMin, xMax, yMax, cellSize, bandwidth, subPop, logic, personColName, projCode);
		}

		rasterStat(outputFileName, minRzn, numRzn, outputPCcount, xMin, yMin, xMax, yMax, cellSize, outputFileName, projCode);

		sprintf(command, "rm %s", outputPCcount);
		system(command);
		for(int j = 0; j < numRzn; j++)
		{
			sprintf(command, "rm %s_rzn%03d %s_rzn%03d_P", outputFileName, (minRzn + j), outputFileName, (minRzn + j));
			system(command);
		}

//gdal commands to reproject to get the latlong files for the generation of KMZs
/* 
		sprintf(command, "gdalwarp -of GTiff -s_srs EPSG:%d -t_srs EPSG:4326 -srcnodata -1 -dstnodata -1 -r cubic %s_mean.asc %s_temp.tif", projCode, outputFileName, outputFileName);
		system(command);

		sprintf(command, "gdal_translate -of AAIGrid %s_temp.tif %s_mean_LatLong.asc", outputFileName, outputFileName);
		system(command);
		
		sprintf(command, "rm %s_temp.tif %s_mean_LatLong.asc.aux.xml %s_mean_LatLong.prj", outputFileName, outputFileName, outputFileName);
		system(command);

		sprintf(command, "gdalwarp -of GTiff -s_srs EPSG:%d -t_srs EPSG:4326 -srcnodata -1 -dstnodata -1 -r cubic %s_iqr.asc %s_temp.tif", projCode, outputFileName, outputFileName);
		system(command);

		sprintf(command, "gdal_translate -of AAIGrid %s_temp.tif %s_iqr_LatLong.asc", outputFileName, outputFileName);
		system(command);
		
		sprintf(command, "rm %s_temp.tif %s_iqr_LatLong.asc.aux.xml %s_iqr_LatLong.prj", outputFileName, outputFileName, outputFileName);
		system(command);
*/
		printf("Done for %s\n", outputFileName);

//Write the meta file
		sprintf(outputMetaFileName, "%s_metadata.txt", outputFileName);
		if(NULL == (metaFile = fopen(outputMetaFileName, "w")))
		{
			printf("Can't open output metaData File: %s\n", outputMetaFileName);
			exit(1);
		}

		fprintf(metaFile, "Date time of Analysis:\t%s", asctime(tm));
		fprintf(metaFile, "Input files used:\t%s\n", inputFileName); 
		fprintf(metaFile, "Minimum realization number:\t%d\n", minRzn); 
		fprintf(metaFile, "Maximum realization number:\t%d\n", (minRzn + numRzn - 1));
		fprintf(metaFile, "Projection system EPSG code:\t%d\n", projCode);
		fprintf(metaFile, "Output grid northing:\t%f\n", yMax);
		fprintf(metaFile, "Output grid eastint:\t%f\n", xMax);
		fprintf(metaFile, "Output grid southint:\t%f\n", yMin); 
		fprintf(metaFile, "Output grid westint:\t%f\n", xMin);
		fprintf(metaFile, "Output grid cell size:\t%f\n", cellSize);
		fprintf(metaFile, "Kernel radius:\t%f\n", bandwidth);
		fprintf(metaFile, "Persons per houshold field:\t%f\n", personColName);
		fprintf(metaFile, "Map Logic:\tpercentage of %s\n", hhOnly?"Households":"Persons");
		fprintf(metaFile, "\t\tthat satisfy %s\n", logic);
		fprintf(metaFile, "\t\tamong the %s that satisfy %s\n", hhOnly?"Households":"Persons", subPop);

		fclose(metaFile);

	}

	fclose(parameterFile);

//Generate KMZs
/*
	strcpy(command, "java -jar AscToKml.jar");
	int j = 0;
	for(int i = 0; i < outputFileCount; i++)
	{
		if(strcmp(outputFileNamesList + i * 200, "") == 0)
			continue;
		sprintf(command, "%s %s", command, outputFileNamesList + i * 200);
		j ++;
		if(j >= 8)
		{
			printf("Java command:\t%s\n", command);
			system(command);
			j = 0;
			strcpy(command, "java -jar AscToKml.jar");
		}
	}
	if(j > 0)
	{
		printf("Java command:\t%s\n", command);
		system(command);
	}


	for(int i = 0; i < outputFileCount; i++)
	{
		if(strcmp(outputFileNamesList + i * 200, "") == 0)
			continue;
		sprintf(command, "rm %s_mean_LatLong.asc %s_iqr_LatLong.asc", outputFileNamesList + i * 200, outputFileNamesList + i * 200);
		system(command);
	}
*/
	free(outputFileNamesList);
	return 0;
}

