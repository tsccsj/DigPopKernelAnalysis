#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <gdal.h>
#include <ogr_srs_api.h>
#include <ogr_api.h>
#include <cpl_conv.h>

void writeGridF(FILE * output, float * result, int nRow, int nCol, float xMin, float yMax, float cellSize)
{
	fprintf(output, "ncols\t%d\n", nCol);
	fprintf(output, "nrows\t%d\n", nRow);
	fprintf(output, "xllcorner\t%f\n", xMin);
	fprintf(output, "yllcorner\t%f\n", yMax);
	fprintf(output, "cellsize\t%f\n", cellSize);
	fprintf(output, "NODATA_value\t-1.00000\n");
	for(int i = 0; i < nRow; i++)
	{
		fprintf(output, "%.5f", result[i * nCol]);
		for(int j = 1; j < nCol; j++)
		{
			fprintf(output, " %.5f", result[i * nCol + j]);
		}
		fprintf(output, "\n");
	}
}

void writeGridI(FILE * output, int * result, int nRow, int nCol, float xMin, float yMax, float cellSize)
{
	fprintf(output, "ncols\t%d\n", nCol);
	fprintf(output, "nrows\t%d\n", nRow);
	fprintf(output, "xllcorner\t%f\n", xMin);
	fprintf(output, "yllcorner\t%f\n", yMax);
	fprintf(output, "cellsize\t%f\n", cellSize);
	fprintf(output, "NODATA_value\t-1\n");
	for(int i = 0; i < nRow; i++)
	{
		fprintf(output, "%d", result[i * nCol]);
		for(int j = 1; j < nCol; j++)
		{
			fprintf(output, " %d", result[i * nCol + j]);
		}
		fprintf(output, "\n");
	}
}

void writeGeoTiffF(char * fileName, float * result, int nRow, int nCol, float xMin, float yMax, float cellSize)
{
	
	GDALAllRegister();
	OGRRegisterAll();

	GDALDatasetH hDstDS;
	GDALDriverH hDriver;
	GDALRasterBandH hBand;
	double adfGeoTransform[6];

	char *papszOptions[] = {"COMPRESS=LZW",NULL};
	const char *pszFormat="GTiff";

	if(NULL == (hDriver = GDALGetDriverByName(pszFormat)))
	{
		printf("ERROR: hDriver is null cannot output using GDAL\n");
		exit(1);
	}
	
	hDstDS = GDALCreate(hDriver, fileName, nCol, nRow, 1, GDT_Float32, papszOptions);

	adfGeoTransform[0] = xMin;
	adfGeoTransform[1] = cellSize;
	adfGeoTransform[2] = 0;
	adfGeoTransform[3] = yMax;
	adfGeoTransform[4] = 0;
	adfGeoTransform[5] = -cellSize;

	GDALSetGeoTransform(hDstDS,adfGeoTransform);

	hBand=GDALGetRasterBand(hDstDS,1);
	GDALSetRasterNoDataValue(hBand,-1);
	GDALRasterIO(hBand, GF_Write, 0, 0, nCol, nRow, result, nCol, nRow, GDT_Float32, 0, 0 );
	
	GDALClose(hDstDS);

	return;
}

void writeGeoTiffI(char * fileName, int * result, int nRow, int nCol, float xMin, float yMax, float cellSize)
{
	
	GDALAllRegister();
	OGRRegisterAll();

	GDALDatasetH hDstDS;
	GDALDriverH hDriver;
	GDALRasterBandH hBand;
	double adfGeoTransform[6];

	char *papszOptions[] = {"COMPRESS=LZW",NULL};
	const char *pszFormat="GTiff";

	if(NULL == (hDriver = GDALGetDriverByName(pszFormat)))
	{
		printf("ERROR: hDriver is null cannot output using GDAL\n");
		exit(1);
	}
	
	hDstDS = GDALCreate(hDriver, fileName, nCol, nRow, 1, GDT_Int32, papszOptions);

	adfGeoTransform[0] = xMin;
	adfGeoTransform[1] = cellSize;
	adfGeoTransform[2] = 0;
	adfGeoTransform[3] = yMax;
	adfGeoTransform[4] = 0;
	adfGeoTransform[5] = -cellSize;

	GDALSetGeoTransform(hDstDS,adfGeoTransform);

	hBand=GDALGetRasterBand(hDstDS,1);
	GDALSetRasterNoDataValue(hBand,-1);
	GDALRasterIO(hBand, GF_Write, 0, 0, nCol, nRow, result, nCol, nRow, GDT_Int32, 0, 0 );
	
	GDALClose(hDstDS);

	return;
}

int main(int argc, char ** argv)
{

	if(argc != 5)
	{
		printf("Incorrect number of input arguments: \n");
		printf("\tSARasterStat <InputFile> <startRzn> <numRzn> <OutputFile>\n");
		return 1;
	}

	int minRzn = atoi(argv[2]);
	int numRzn = atoi(argv[3]); 

//	FILE ** inputFiles;
//	FILE * outputFile;

	GDALAllRegister();
	GDALDatasetH * dataSets;
	GDALRasterBandH * bands;
	double adfGeoTransform[6];


	int nRow, nCol;
	float xMin, yMin, yMax, cellSize, nonData;
	
	char tempFileName[500];

	float * rowValue;
	float * cellValue;

	int nNA;
	float * mean;
	float * max;
	float * min;
	float * median;
	float * q1;
	float * q3;
	float * range;
	float * iqr;
	int * notNA;
	float * sd;
	
	if(numRzn < 0 || numRzn > 10000)
	{
		printf("invalid numOfMaps, the number should be more than 0 and less than 10000\n");
		return 1;
	}
/*
	if(NULL == (inputFiles = (FILE **) malloc(sizeof(FILE *) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
*/
	if(NULL == (dataSets = (GDALDatasetH *) malloc (sizeof(GDALDatasetH) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (bands = (GDALRasterBandH *) malloc (sizeof(GDALRasterBandH) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	
//	for(int i = 0; i < numRzn; i++)
//	{
//		sprintf(tempFileName, "%s_rzn%03d.asc", argv[1], (minRzn + i));
//		if(NULL == (inputFiles[i] = fopen(tempFileName, "r")))
//		{
//			printf("ERROR: Can't open input file%s.\n", tempFileName);
//			return 1;
//		}

		
//		fscanf(inputFiles[i], "ncols %d\n", &nCol);
//		fscanf(inputFiles[i], "nrows %d\n", &nRow);
//		fscanf(inputFiles[i], "xllcorner %f\n", &xMin);
//		fscanf(inputFiles[i], "yllcorner %f\n", &yMin);
//		fscanf(inputFiles[i], "cellsize %f\n", &cellSize);
//		fscanf(inputFiles[i], "NODATA_value %f\n", &nonData);
//		yMax = yMin + nRow * cellSize;

//	}


	for(int i = 0; i < numRzn; i++)
	{
		sprintf(tempFileName, "%s_rzn%03d.tif", argv[1], (minRzn + i));
		if(NULL == (dataSets[i] = GDALOpen(tempFileName, GA_ReadOnly)))
		{
			printf("ERROR: Can't open input file%s.\n", tempFileName);
			return 1;		
		}

		
		bands[i] = GDALGetRasterBand(dataSets[i], 1 );
		
	}

	
	GDALGetGeoTransform(dataSets[0], adfGeoTransform);

	xMin = adfGeoTransform[0];
	yMax = adfGeoTransform[3];
	cellSize = adfGeoTransform[1];
		
	nCol = GDALGetRasterXSize(dataSets[0]);
	nRow = GDALGetRasterYSize(dataSets[0]);
	
	yMin = yMax + nRow * cellSize;


	if(NULL == (rowValue = (float *) malloc (sizeof(float) * numRzn * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (cellValue = (float *) malloc (sizeof(float) * numRzn)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	
	
	if(NULL == (notNA = (int *) malloc (sizeof(int) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (mean = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (max = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (min = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (median = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (q1 = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (q3 = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (range = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (iqr = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}
	if(NULL == (sd = (float *) malloc (sizeof(float) * nRow * nCol)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return 1;
	}

	float tempF;
	float tempFS;

	for(int i = 0; i < nRow; i++)
	{
		for(int k = 0; k < numRzn; k++)
		{
//			for(int j = 0; j < nCol; j++)
//			{
//				fscanf(inputFiles[k], "%f\n", rowValue + k * nCol + j);
//			}

			
			GDALRasterIO(bands[k], GF_Read, 0, i, nCol, 1, rowValue + k * nCol, nCol, 1, GDT_Float32, 0, 0);
		}

		for(int j = 0; j < nCol; j++)
		{
			nNA = 0;
			for(int k = 0; k < numRzn; k++)
			{
				if(rowValue[k * nCol + j] >= 0)
				{
					cellValue[nNA] = rowValue[k * nCol + j];
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
				range[i * nCol + j] = -1;
				iqr[i * nCol + j] = -1;
				sd[i * nCol + j] = -1;
			}
			else
			{
				for(int k = 0; k < nNA - 1; k++)
				{
					int maxID = k;
					for(int l = k + 1; l < nNA; l++)
					{
						if(cellValue[maxID] < cellValue[l])
						{
							maxID = l;
						}
					}
					if(maxID != k)
					{
						tempF = cellValue[k];
						cellValue[k] = cellValue[maxID];
						cellValue[maxID] = tempF;
					}
				}

				max[i * nCol + j] = cellValue[0];
				min[i * nCol + j] = cellValue[nNA-1];
				if(0==nNA%2)
				{
					median[i * nCol + j] = (cellValue[nNA/2] + cellValue[nNA/2-1]) / 2;
				}
				else
				{
					median[i * nCol + j] = cellValue[nNA/2];
				}	
				q3[i * nCol + j] = cellValue[(int)((float)nNA/4-0.5)];
				q1[i * nCol + j] = cellValue[(int)((float)nNA/4*3-0.5)];
				tempF = 0.0;
				tempFS = 0.0;
				for(int k = 0; k < nNA; k++)
				{
					tempF += cellValue[k];
					tempFS += cellValue[k] * cellValue[k];
				}
				mean[i * nCol + j] = tempF / nNA;
				sd[i * nCol + j] = sqrt(tempFS / nNA - (tempF / nNA) * (tempF / nNA));
				
				range[i * nCol + j] = max[i * nCol + j] - min[i * nCol + j];
				iqr[i * nCol + j] = q3[i * nCol + j] - q1[i * nCol + j];
			}
			notNA[i * nCol + j] = nNA;
		}
	}

	for(int i = 0; i < numRzn; i++)
	{
//		fclose(inputFiles[i]);
		GDALClose(dataSets[i]);
	}

	free(cellValue);
	free(rowValue);

	free(dataSets);
	free(bands);

	sprintf(tempFileName, "%s_mean.tif", argv[4]);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file: %s.\n", tempFileName);
//		return 1;
//	}
//	writeGridF(outputFile, mean, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, mean, nRow, nCol, xMin, yMax, cellSize);

	sprintf(tempFileName, "%s_max.tif", argv[4]);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file: %s.\n", tempFileName);
//		return 1;
//	}
//	writeGridF(outputFile, max, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, max, nRow, nCol, xMin, yMax, cellSize);

	sprintf(tempFileName, "%s_min.tif", argv[4]);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file: %s.\n", tempFileName);
//		return 1;
//	}
//	writeGridF(outputFile, min, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, min, nRow, nCol, xMin, yMax, cellSize);

	sprintf(tempFileName, "%s_1q.tif", argv[4]);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file: %s.\n", tempFileName);
//		return 1;
//	}
//	writeGridF(outputFile, q1, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, q1, nRow, nCol, xMin, yMax, cellSize);

	sprintf(tempFileName, "%s_3q.tif", argv[4]);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file: %s.\n", tempFileName);
//		return 1;
//	}
//	writeGridF(outputFile, q3, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, q3, nRow, nCol, xMin, yMax, cellSize);
	
	sprintf(tempFileName, "%s_median.tif", argv[4]);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file: %s.\n", tempFileName);
//		return 1;
//	}
//	writeGridF(outputFile, median, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, median, nRow, nCol, xMin, yMax, cellSize);

	sprintf(tempFileName, "%s_nNA.tif", argv[4]);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file: %s.\n", tempFileName);
//		return 1;
//	}
//	writeGridI(outputFile, notNA, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffI(tempFileName, notNA, nRow, nCol, xMin, yMax, cellSize);

	sprintf(tempFileName, "%s_range.tif", argv[4]);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file: %s.\n", tempFileName);
//		return 1;
//	}
//	writeGridF(outputFile, range, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, range, nRow, nCol, xMin, yMax, cellSize);

	sprintf(tempFileName, "%s_iqr.tif", argv[4]);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file: %s.\n", tempFileName);
//		return 1;
//	}
//	writeGridF(outputFile, iqr, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, iqr, nRow, nCol, xMin, yMax, cellSize);

	sprintf(tempFileName, "%s_sd.tif", argv[4]);
//	if(NULL == (outputFile = fopen(tempFileName, "w")))
//	{
//		printf("ERROR: Can't open output file: %s.\n", tempFileName);
//		return 1;
//	}
//	writeGridF(outputFile, sd, nRow, nCol, xMin, yMin, cellSize);
//	fclose(outputFile);
	writeGeoTiffF(tempFileName, sd, nRow, nCol, xMin, yMax, cellSize);


	free(mean);
	free(max);
	free(min);
	free(median);
	free(q1);
	free(q3);
	free(range);
	free(iqr);
	free(notNA);
	free(sd);
	return 0;
}
