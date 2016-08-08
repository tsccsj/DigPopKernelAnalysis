#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "io.cuh"


//rasterStat inputFileName inputCount inputPCcount xMin yMin xMax yMax cellSize outputFileName
int rasterStat(char * inputFileName, int minRzn, int numRzn, char * inputPCName, float xMin, float yMin, float xMax, float yMax, float cellSize, char * outputFileName, int epsgCode)
{
	FILE ** inputFilesC;
	FILE ** inputFilesP;
	FILE * inputPCcountFile;

//	FILE * outputFile;
	
	int nRow, nCol;

	int * nPop, * nCase;

	char tempFileName[500];


	float * rowCase;
	float * rowPop;

	float * cellCase;
	float * cellPop;
//	float * cellLike;

	int nNA;
	float * mean;
	float * max;
	float * min;
	float * median;
	float * q1;
	float * q3;
	float * meanPop;
	float * range;
	float * iqr;
	int * notNA;
	float * sd;
/*
	float * meanL;
	float * maxL;
	float * minL;
	float * medianL;
	float * q1L;
	float * q3L;
*/	

	if(numRzn < 0 || numRzn > 10000)
	{
		printf("invalid numOfMaps, should be more than 0 and less than 10000\n");
		exit(1);
	}

	if(NULL == (inputFilesC = (FILE **) malloc(sizeof(FILE *) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (inputFilesP = (FILE **) malloc(sizeof(FILE *) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}

	for(int i = 0; i < numRzn; i++)
	{
		sprintf(tempFileName, "%s_rzn%03d", inputFileName, (minRzn + i));
		if(NULL == (inputFilesC[i] = fopen(tempFileName, "rb")))
		{
			printf("ERROR: Can't open input case file: %s.\n", tempFileName);
			exit(1);
		}
		sprintf(tempFileName, "%s_rzn%03d_P", inputFileName, (minRzn + i));
		if(NULL == (inputFilesP[i] = fopen(tempFileName, "rb")))
		{
			printf("ERROR: Can't open input population file: %s.\n", tempFileName);
			exit(1);
		}
	}
	
	if(NULL == (inputPCcountFile = fopen(inputPCName, "r")))
	{
		printf("ERROR: Can't open input population-and-case-count file: %s.\n", tempFileName);
		exit(1);
	}

	if(NULL == (nPop = (int *)malloc(sizeof(int) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (nCase = (int *)malloc(sizeof(int) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}

	for(int i = 0; i < numRzn; i++)
	{
		fscanf(inputPCcountFile, "%s %d %d\n", tempFileName, nPop + i, nCase + i);
	}

	fclose(inputPCcountFile);

	nCol = ceil((xMax - xMin)/cellSize);
	nRow = ceil((yMax - yMin)/cellSize);

	xMax = xMin + cellSize * nCol;
	yMax = yMin + cellSize * nRow;

//	printf("####################\n");
//	printf("nRow: %d\tnCol: %d\n", nRow, nCol);
//	printf("xMax: %f\txMin: %f\nyMax: %f\tyMin: %f\n",xMax,xMin,yMax,yMin);
//	printf("####################\n");


	if(NULL == (rowCase = (float *) malloc (sizeof(float) * numRzn * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (rowPop = (float *) malloc (sizeof(float) * numRzn * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}

	if(NULL == (cellCase = (float *) malloc (sizeof(int) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (cellPop = (float *) malloc (sizeof(int) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
/*
	if(NULL == (cellLike = (float *) malloc (sizeof(int) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
*/
	if(NULL == (notNA = (int *) malloc (sizeof(int) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (mean = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (max = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (min = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (median = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (q1 = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (q3 = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (meanPop = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (range = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (iqr = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (sd = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
/*
	if(NULL == (meanL = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (maxL = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (minL = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (medianL = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (q1L = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (q3L = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		exit(1);
	}
*/	

	float tempF;
	float tempFS;
	for(int i = 0; i < nRow; i++)
	{
		for(int k = 0; k < numRzn; k++)
		{
			if(nCol != fread(rowCase + k * nCol, sizeof(float), nCol, inputFilesC[k]))
			{
				printf("Wrong input file size or nRow, nCol!\n");
				exit(1);
			}
			if(nCol != fread(rowPop + k * nCol, sizeof(float), nCol, inputFilesP[k]))
			{
				printf("Wrong input file size or nRow, nCol!\n");
				exit(1);
			}
		}

		for(int j = 0; j < nCol; j++)
		{
			nNA = 0;
			for(int k = 0; k < numRzn; k++)
			{
				if(rowPop[k * nCol + j] > 0)
				{
					cellCase[nNA] = rowCase[k * nCol + j];
					cellPop[nNA] = rowPop[k * nCol + j];
					//cellLike[nNA] = pow(cellCase[nNA]/cellPop[nNA], cellCase[nNA]) * pow((cellPop[nNA] - cellCase[nNA])/cellPop[nNA], (cellPop[nNA] - cellCase[nNA])) * pow((nCase[k] - cellCase[nNA])/(nPop[k] - cellPop[nNA]), (nCase[k] - cellCase[nNA])) * pow((nPop[k] - cellPop[nNA] - nCase[k] + cellCase[nNA])/(nPop[k] - cellPop[nNA]), (nPop[k] - cellPop[nNA] - nCase[k] + cellCase[nNA]));
					//cellLike[nNA] = cellCase[nNA] * log(cellCase[nNA]/cellPop[nNA]) + (cellPop[nNA] - cellCase[nNA]) * log((cellPop[nNA] - cellCase[nNA])/cellPop[nNA]) + (nCase[k] - cellCase[nNA]) * log((nCase[k] - cellCase[nNA])/(nPop[k] - cellPop[nNA])) + (nPop[k] - cellPop[nNA] - nCase[k] + cellCase[nNA]) * log((nPop[k] - cellPop[nNA] - nCase[k] + cellCase[nNA])/(nPop[k] - cellPop[nNA]));  
					cellCase[nNA] = cellCase[nNA] / cellPop[nNA];

					nNA ++;
				}
			}


			if(0 == nNA)
			{
				mean[i * nCol + j] = -1;
				max[i * nCol + j] = -1;
				min[i * nCol + j] = -1;
				median[i * nCol + j] = -1;
				q1[i * nCol + j] = -1;
				q3[i * nCol + j] = -1;
				meanPop[i * nCol + j] = -1;
				range[i * nCol + j] = -1;
				iqr[i * nCol + j] = -1;
				sd[i * nCol + j] = -1;

/*				meanL[i * nCol + j] = 1;
				maxL[i * nCol + j] = 1;
				minL[i * nCol + j] = 1;
				medianL[i * nCol + j] = 1;
				q1L[i * nCol + j] = 1;
				q3L[i * nCol + j] = 1;
*/
			}
			else
			{
				//Sort Porprotion
				for(int k = 0; k < nNA - 1; k++)
				{
					int maxID = k;
					for(int l = k + 1; l < nNA; l++)
					{
						if(cellCase[maxID] < cellCase[l])
						{
							maxID = l;
						}
					}
					if(maxID != k)
					{
						tempF = cellCase[k];
						cellCase[k] = cellCase[maxID];
						cellCase[maxID] = tempF;
					}
				}

				//Calcualte statistics
				max[i * nCol + j] = cellCase[0];
				min[i * nCol + j] = cellCase[nNA-1];
				if(0==nNA%2)
				{
					median[i * nCol + j] = (cellCase[nNA/2] + cellCase[nNA/2-1]) / 2;
				}
				else
				{
					median[i * nCol + j] = cellCase[nNA/2];
				}	
				q3[i * nCol + j] = cellCase[(int)((float)nNA/4-0.5)];
				q1[i * nCol + j] = cellCase[(int)((float)nNA/4*3-0.5)];
				tempF = 0.0;
				tempFS = 0.0;
				for(int k = 0; k < nNA; k++)
				{
					tempF += cellCase[k];
					tempFS += cellCase[k] * cellCase[k];
				}
				mean[i * nCol + j] = tempF / nNA;
				sd[i * nCol + j] = sqrt(tempFS / nNA - (tempF / nNA) * (tempF / nNA));
				
				tempF = 0.0;
				for(int k = 0; k < nNA; k++)
				{
					tempF += cellPop[k];
				}
				meanPop[i * nCol + j] = tempF / numRzn;
				range[i * nCol + j] = max[i * nCol + j] - min[i * nCol + j];
				iqr[i * nCol + j] = q3[i * nCol + j] - q1[i * nCol + j];
				
/*
				//Sort Likelihood
				for(int k = 0; k < nNA - 1; k++)
				{
					int maxID = k;
					for(int l = k + 1; l < nNA; l++)
					{
						if(cellLike[maxID] < cellLike[l])
						{
							maxID = l;
						}
					}
					if(maxID != k)
					{
						tempF = cellLike[k];
						cellLike[k] = cellLike[maxID];
						cellLike[maxID] = tempF;
					}
				}
				maxL[i * nCol + j] = cellLike[0];
				minL[i * nCol + j] = cellLike[nNA-1];
				if(0==nNA%2)
				{
					medianL[i * nCol + j] = (cellLike[nNA/2] + cellLike[nNA/2-1]) / 2;
				}
				else
				{
					medianL[i * nCol + j] = cellLike[nNA/2];
				}	
				q3L[i * nCol + j] = cellLike[(int)((float)nNA/4-0.5)];
				q1L[i * nCol + j] = cellLike[(int)((float)nNA/4*3-0.5)];
				tempF = 0;
				for(int k = 0; k < nNA; k++)
				{
					tempF += cellLike[k];
				}
				meanL[i * nCol + j] = tempF / nNA;
*/
			}
			notNA[i * nCol + j] = nNA;
		}
	}


	for(int i = 0; i < numRzn; i++)
	{
		fclose(inputFilesC[i]);
		fclose(inputFilesP[i]);
	}


	
	//Write output files
	sprintf(tempFileName, "%s_mean.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridF(outputFile, mean, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, mean, nRow, nCol, xMin, yMax, cellSize, epsgCode);

	sprintf(tempFileName, "%s_max.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridF(outputFile, max, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, max, nRow, nCol, xMin, yMax, cellSize, epsgCode);

	sprintf(tempFileName, "%s_min.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridF(outputFile, min, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, min, nRow, nCol, xMin, yMax, cellSize, epsgCode);

	sprintf(tempFileName, "%s_1q.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridF(outputFile, q1, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, q1, nRow, nCol, xMin, yMax, cellSize, epsgCode);

	sprintf(tempFileName, "%s_3q.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridF(outputFile, q3, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, q3, nRow, nCol, xMin, yMax, cellSize, epsgCode);
	
	sprintf(tempFileName, "%s_median.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridF(outputFile, median, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, median, nRow, nCol, xMin, yMax, cellSize, epsgCode);

	sprintf(tempFileName, "%s_nNA.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridI(outputFile, notNA, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffI(tempFileName, notNA, nRow, nCol, xMin, yMax, cellSize, epsgCode);

	sprintf(tempFileName, "%s_meanPop.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridF(outputFile, meanPop, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, meanPop, nRow, nCol, xMin, yMax, cellSize, epsgCode);

	sprintf(tempFileName, "%s_range.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridF(outputFile, range, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, range, nRow, nCol, xMin, yMax, cellSize, epsgCode);

	sprintf(tempFileName, "%s_iqr.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridF(outputFile, iqr, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, iqr, nRow, nCol, xMin, yMax, cellSize, epsgCode);

	sprintf(tempFileName, "%s_sd.tif", outputFileName);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file%s.\n", tempFileName);
//		exit(1);
//	}
//	writeGridF(outputFile, sd, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, sd, nRow, nCol, xMin, yMax, cellSize, epsgCode);
/*
	sprintf(tempFileName, "%s_meanLikelihood.asc", outputFileName);
	if(NULL == (outputFile = fopen(tempFileName, "w")))
	{
		printf("ERROR: Can't open output file%s.\n", tempFileName);
		exit(1);
	}
	writeGridF(outputFile, meanL, nRow, nCol, xMin, yMin, cellSize, 1);
	fclose(outputFile);

	sprintf(tempFileName, "%s_maxLikelihood.asc", outputFileName);
	if(NULL == (outputFile = fopen(tempFileName, "w")))
	{
		printf("ERROR: Can't open output file%s.\n", tempFileName);
		exit(1);
	}
	writeGridF(outputFile, maxL, nRow, nCol, xMin, yMin, cellSize, 1);
	fclose(outputFile);

	sprintf(tempFileName, "%s_minLikelihood.asc", outputFileName);
	if(NULL == (outputFile = fopen(tempFileName, "w")))
	{
		printf("ERROR: Can't open output file%s.\n", tempFileName);
		exit(1);
	}
	writeGridF(outputFile, minL, nRow, nCol, xMin, yMin, cellSize, 1);
	fclose(outputFile);

	sprintf(tempFileName, "%s_1qLikelihood.asc", outputFileName);
	if(NULL == (outputFile = fopen(tempFileName, "w")))
	{
		printf("ERROR: Can't open output file%s.\n", tempFileName);
		exit(1);
	}
	writeGridF(outputFile, q1L, nRow, nCol, xMin, yMin, cellSize, 1);
	fclose(outputFile);

	sprintf(tempFileName, "%s_3qLikelihood.asc", outputFileName);
	if(NULL == (outputFile = fopen(tempFileName, "w")))
	{
		printf("ERROR: Can't open output file%s.\n", tempFileName);
		exit(1);
	}
	writeGridF(outputFile, q3L, nRow, nCol, xMin, yMin, cellSize, 1);
	fclose(outputFile);
	
	sprintf(tempFileName, "%s_medianLikelihood.asc", outputFileName);
	if(NULL == (outputFile = fopen(tempFileName, "w")))
	{
		printf("ERROR: Can't open output file%s.\n", tempFileName);
		exit(1);
	}
	writeGridF(outputFile, medianL, nRow, nCol, xMin, yMin, cellSize, 1);
	fclose(outputFile);
*/
	//Clean up resourses
	free(inputFilesC);
	free(inputFilesP);


	free(rowCase);
	free(rowPop);

	free(cellCase);
	free(cellPop);
//	free(cellLike);

	free(notNA);
	free(mean);
	free(max);
	free(min);
	free(median);
	free(q1);
	free(q3);
	free(meanPop);
	free(range);
	free(iqr);
	free(sd);
/*
	free(meanL);
	free(maxL);
	free(minL);
	free(medianL);
	free(q1L);
	free(q3L);
*/
	free(nPop);
	free(nCase);

	//printf("Finished!\n");
	return 0;
}
