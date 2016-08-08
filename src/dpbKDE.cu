#include <stdio.h>
#include <math.h>
#include "io.cuh"
#include "kde.cuh"
#include <sys/time.h>


//dpbKDE  inputPopFile inputHHFile outputFileName outputCount xMin yMin xMax yMax cellSize bandwidth mapLogic
int dpbKDE(char * inputPopFileName, char * inputHHFileName, char * outputFileName, char * outputCount, float xMin, float yMin, float xMax, float yMax, float cellSize, float bandwidth, char * subPop, char * mapLogic, char * personColName, int epsgCode)
{
	//Uboyt
	FILE * inputPopData;
	FILE * inputHHData;

	char outputRatioGTiffFile[200];
	char outputPopulationFile[200];

	bool hhOnly;	
	
	float * xCol;
	float * yCol;
	
	float * pCount;
	float * cCount;

	int nRow, nCol, nHH, nPop, nCase = 0;
	float * caseDen;
	float * popDen;

	struct timeval time1;
	gettimeofday(&time1, NULL);

	if(strcmp(inputPopFileName, "-HHO") == 0)
	{
		hhOnly = true;
	}
	else
	{
		hhOnly = false;
		if(NULL == (inputPopData = fopen(inputPopFileName, "r")))
		{
			printf("ERROR: Can't open input population file: %s\n", inputPopFileName);
			exit(1);
		}
	}

	if(NULL == (inputHHData = fopen(inputHHFileName, "r")))
	{
		printf("ERROR: Can't open input household file: %s\n", inputHHFileName);
		exit(1);
	}

	sprintf(outputPopulationFile, "%s_P", outputFileName);
	sprintf(outputRatioGTiffFile, "%s.tif", outputFileName);

//Cells
	nCol = ceil((xMax - xMin)/cellSize);
	nRow = ceil((yMax - yMin)/cellSize);

	xMax = xMin + cellSize * nCol;
	yMax = yMin + cellSize * nRow;

	//printf("####################\n");
	//printf("nRow: %d\tnCol: %d\n", nRow, nCol);
	//printf("xMax: %f\txMin: %f\nyMax: %f\tyMin: %f\n",xMax,xMin,yMax,yMin);
	//printf("####################\n");

//Points

	nHH = getHHNum(inputHHData);
	if(NULL == (xCol = (float *)malloc(sizeof(float) * nHH)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (yCol = (float *)malloc(sizeof(float) * nHH)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (pCount = (float *)malloc(sizeof(float) * nHH)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (cCount = (float *)malloc(sizeof(float) * nHH)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}

	bool succeed;

	if(hhOnly)
	{
		if(strcmp(subPop, "*") == 0)
		{
			succeed = readPointsH(inputHHData, nHH, nCase, xCol, yCol, pCount, cCount, mapLogic);
		}
		else
		{
			succeed = readPointsHInSubPop(inputHHData, nHH, nCase, xCol, yCol, pCount, cCount, subPop, mapLogic);
		}

		if(!succeed)
		{
			printf("File involved: %s\n", inputHHFileName);
			exit(1);
		}
		//printf("num of household: %d\nnum of positive household: %d\n", nHH, nCase);
		//printf("####################\n");
	}
	else
	{
		if(strcmp(subPop, "*") == 0)
		{
			succeed = readPointsP(inputHHData, inputPopData, nHH, nPop, nCase, xCol, yCol, pCount, cCount, mapLogic, personColName);
		}
		else
		{
			succeed = readPointsPInSubPop(inputHHData, inputPopData, nHH, nPop, nCase, xCol, yCol, pCount, cCount, subPop, mapLogic, personColName);
		}
	
		if(!succeed)
		{
			printf("File involved: %s and\\or %s\n", inputHHFileName, inputPopFileName);
			exit(1);
		}
		//printf("num of household: %d\nnum of population: %d\nnum of case: %d\n", nHH, nPop, nCase);
		//printf("####################\n");
	}

	fclose(inputHHData);
	if(!hhOnly)
	{
		fclose(inputPopData);
	}

	struct timeval time2;
	gettimeofday(&time2, NULL);
	//KDE

	if(NULL == (caseDen = (float *) malloc(sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in %d!\n", __LINE__);
		exit(1);
	}
	
	if(NULL == (popDen = (float *) malloc(sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in %d!\n", __LINE__);
		exit(1);
	}

	for(int i = 0; i < nRow * nCol; i++)
	{
		caseDen[i] = 0;
		popDen[i] = 0;
	}

	int x, y;
	if(bandwidth > 1)
	{
		kde(caseDen, popDen, nRow, nCol, cellSize, xMin, yMax, xCol, yCol, pCount, cCount, nHH, bandwidth);

		//filter out non-value areas
		bool * hasValue;
		if(NULL == (hasValue = (bool *) malloc (sizeof(float) * nRow * nCol)))
		{
			printf("ERROR: Out of memory in %d!\n", __LINE__);
			exit(1);
		}
		for(int i = 0; i < nCol * nRow; i++)
		{
			hasValue[i] = false;
		}

		for(int i = 0; i < nHH; i++)
		{
			x = (xCol[i] - xMin) / cellSize;
			y = (yMax - yCol[i]) / cellSize;

			//if(x < 0 || x >= nCol || y < 0 || y >= nRow)
			//{
			//	printf("%d\t%f\t%f\n", i, xCol[i], yCol[i]);
			//}
		
			if(x > -1 && x < nCol && y > -1 && y < nRow && !hasValue[y * nCol + x])
				hasValue[y * nCol + x] = true;		
		}

		for(int i = 0; i < nRow * nCol; i++)
		{
			if(!hasValue[i])
			{
				caseDen[i] = 0;
				popDen[i] = 0;
			}
		}

		free(hasValue);
	}
	else
	{
		for(int i = 0; i < nHH; i++)
		{
			x = (xCol[i] - xMin) / cellSize;
			y = (yMax - yCol[i]) / cellSize;

			if(x >= 0 && x < nCol && y >= 0 && y < nRow)
			{

				caseDen[y * nCol + x] += cCount[i];
				popDen[y * nCol + x] += pCount[i];
			}
		}
	}

	struct timeval time3;
	gettimeofday(&time3, NULL);

	printf("Input time:\t%lfms\n", ((&time2)->tv_sec - (&time1)->tv_sec) * 1000 + (double)((&time2)->tv_usec - (&time1)->tv_usec) / 1000);
	printf("KDE time:\t%lfms\n", ((&time3)->tv_sec - (&time2)->tv_sec) * 1000 + (double)((&time3)->tv_usec - (&time2)->tv_usec) / 1000);

	//Write outputFile
	FILE * outputFile;
	if(NULL == (outputFile = fopen(outputFileName, "wb")))
	{
		printf("ERROR: Can't open output file");
		exit(1);
	}
	fwrite(caseDen, sizeof(float), nRow * nCol, outputFile);
	fclose(outputFile);

//Generate ascii grid
/*
	if(NULL == (outputFile = fopen(outputRatioGTiffFile, "w")))
	{
		printf("ERROR: Can't open output ratio file: %s\n", outputRatioGTiffFile);
		exit(1);
	}
	writeGridRatio(outputFile, caseDen, popDen, nRow, nCol, xMin, yMin, cellSize);
	fclose(outputFile);
*/
//Generate GeoTiff
	writeGeoTiffRatio(outputRatioGTiffFile, caseDen, popDen, nRow, nCol, xMin, yMax, cellSize, epsgCode);

	if(NULL == (outputFile = fopen(outputPopulationFile, "wb")))
	{
		printf("ERROR: Can't open output population file: %s\n", outputPopulationFile);
		exit(1);
	}
	fwrite(popDen, sizeof(float), nRow * nCol, outputFile);
	fclose(outputFile);

// This part is used to be used to calcuate the likelihood, but is no longer used
	if(NULL == (outputFile = fopen(outputCount, "a")))
	{
		printf("ERROR: Can't open output population and count file: %s\n", outputCount);
		exit(1);
	}
	if(hhOnly)
	{
		fprintf(outputFile, "%s %d %d\n", outputFileName, nHH, nCase);
	}
	else
	{
		fprintf(outputFile, "%s %d %d\n", outputFileName, nPop, nCase);
	}
	fclose(outputFile);
	
	//free
	free(xCol);
	free(yCol);
	free(pCount);
	free(cCount);

	free(caseDen);
	free(popDen);

	//printf("Finished!\n");
	return 0;
}



