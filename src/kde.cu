#include <stdio.h>
#include "kde.cuh"
#include "cudaErrorCheck.cu"

#define BLOCKSIZE 16

__global__ void kdeKernel(float * dPop, float * dCase, int nRow, int nCol, float xMin, float yMax, float cellSize, float * dX, float * dY, float * dP, float * dC, int * dPoints, float bandwidth2, int blockBandwidth)
{
	int i = blockIdx.y * blockDim.y + threadIdx.y;
	int j = blockIdx.x * blockDim.x + threadIdx.x;

	int idInThread = threadIdx.y * blockDim.x + threadIdx.x;
 
	float cellX = xMin + cellSize * (j + 0.5);
	float cellY = yMax - cellSize * (i + 0.5);

	float denPop = 0.0f;
	float denCase = 0.0f;
	float dist2;
	float weight;

	int pointProcessed;
	int pointToProcess;
	int endPoint;

	__shared__ float sX[BLOCKSIZE*BLOCKSIZE];
	__shared__ float sY[BLOCKSIZE*BLOCKSIZE];
	__shared__ float sP[BLOCKSIZE*BLOCKSIZE];
	__shared__ float sC[BLOCKSIZE*BLOCKSIZE];


	for(int k = 0; k < 1 + 2 * blockBandwidth; k ++)
	{
		int dataBID = (blockIdx.y + k) * (gridDim.x + 2 * blockBandwidth)+ blockIdx.x;
		if(dataBID < 1)
		{
			pointProcessed = 0;
		}	
		else
		{
			pointProcessed = dPoints[dataBID - 1];
		}
		endPoint = dPoints[dataBID + 2 * blockBandwidth];

		pointToProcess = BLOCKSIZE * BLOCKSIZE;
	
		for(; pointProcessed < endPoint; pointProcessed += BLOCKSIZE * BLOCKSIZE)
		{
			if(pointProcessed + pointToProcess > endPoint)
			{	
				pointToProcess = endPoint - pointProcessed;
			}

			if(idInThread < pointToProcess)
			{
				sX[idInThread] = dX[pointProcessed + idInThread];
				sY[idInThread] = dY[pointProcessed + idInThread];
				sP[idInThread] = dP[pointProcessed + idInThread];
				sC[idInThread] = dC[pointProcessed + idInThread];
			}
			__syncthreads();
	

			for(int m = 0; m < pointToProcess; m++)
			{
				dist2 = (cellX - sX[m]) * (cellX - sX[m]) + (cellY - sY[m]) * (cellY - sY[m]);
				if(dist2 < bandwidth2)
				{
					weight = (1 - dist2 / bandwidth2);
					denPop += weight * sP[m];
					denCase += weight * sC[m];
				}
			}
				
			__syncthreads();
		}
	}
	
	if(i < nRow && j < nCol && i > -1 && j > -1)
	{
		dPop[i * nCol + j] = denPop;
		dCase[i * nCol + j] = denCase;
	}
}

void kde(float * caseDen, float * popDen, int nRow, int nCol, float cellSize, float xMin, float yMax, float * xCol, float * yCol, float * pCount, float * cCount, int nHH, float bandwidth)
{
	int gridX = ceil((float) nCol / BLOCKSIZE);
	int gridY = ceil((float) nRow / BLOCKSIZE);

	float blockSizeE = BLOCKSIZE * cellSize;

	int blockBandwidth = ceil(bandwidth / blockSizeE);
	printf("block bandwidth: %d\n", blockBandwidth);

	int dataGridX = gridX + 2 * blockBandwidth;
	int dataGridY = gridY + 2 * blockBandwidth;


	float xMinData = xMin - blockSizeE * blockBandwidth;
	float yMaxData = yMax + blockSizeE * blockBandwidth;

	int rowID, colID, gridID;

	int * nPointsB;
	if(NULL == (nPointsB = (int *) malloc(sizeof(int) * dataGridX * dataGridY)))
	{
		printf("ERROR: Out of memory in %d!\n", __LINE__);
		exit(1);
	}
	for(int i = 0; i < dataGridX * dataGridY; i++)
	{
		nPointsB[i] = 0;
	}

	int * dGridID;
	if(NULL == (dGridID = (int *) malloc(sizeof(int) * nHH)))
	{
		printf("ERROR: Out of memory in %d!\n", __LINE__);
		exit(1);
	}

	for(int i = 0; i < nHH; i++)
	{
		colID = (int)((xCol[i] - xMinData) / blockSizeE);
		rowID = (int)((yMaxData - yCol[i]) / blockSizeE);
		gridID = rowID * dataGridX + colID;

		if(colID < 0 || colID >= dataGridX || rowID < 0 || rowID >= dataGridY)
		{
			dGridID[i] = -1; 
		}
		else
		{
			nPointsB[gridID] ++;
			dGridID[i] = gridID; 
		}

	}

	int nPointsIn = 0;
	int * startIDB;
	if(NULL == (startIDB = (int *) malloc(sizeof(int) * dataGridX * dataGridY)))
	{
		printf("ERROR: Out of memory in %d!\n", __LINE__);
		exit(1);
	}

	for(int i = 0; i < dataGridX * dataGridY; i++)
	{
		startIDB[i] = nPointsIn;
		nPointsIn += nPointsB[i];
	}

	float * xColOrd;
	float * yColOrd;
	float * pCOrd;
	float * cCOrd;

	if(NULL == (xColOrd = (float *) malloc(sizeof(float) * nPointsIn)))
	{
		printf("ERROR: Out of memory in %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (yColOrd = (float *) malloc(sizeof(float) * nPointsIn)))
	{
		printf("ERROR: Out of memory in %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (pCOrd = (float *) malloc(sizeof(float) * nPointsIn)))
	{
		printf("ERROR: Out of memory in %d!\n", __LINE__);
		exit(1);
	}
	if(NULL == (cCOrd = (float *) malloc(sizeof(float) * nPointsIn)))
	{
		printf("ERROR: Out of memory in %d!\n", __LINE__);
		exit(1);
	}

	for(int i = 0; i < dataGridX * dataGridY; i++)
	{
		nPointsB[i] = startIDB[i];
	}

	for(int i = 0; i < nHH; i++)
	{
		gridID = dGridID[i];
		if(gridID < 0)
			continue;
		xColOrd[nPointsB[gridID]] = xCol[i];
		yColOrd[nPointsB[gridID]] = yCol[i];
		pCOrd[nPointsB[gridID]] = pCount[i];
		cCOrd[nPointsB[gridID]] = cCount[i];
		nPointsB[gridID] ++;
	}

	float * dX;
	float * dY;
	float * dP;
	float * dC;
	int * dPoints;

	float * dPop;
	float * dCase;

	dim3 dimBlock (BLOCKSIZE, BLOCKSIZE);
	dim3 dimGrid (gridX, gridY);

	CudaSafeCall(cudaMalloc((void **) &dPop, sizeof(float) * nRow * nCol));
	CudaSafeCall(cudaMalloc((void **) &dCase, sizeof(float) * nRow * nCol));

	CudaSafeCall(cudaMalloc((void **) &dX, sizeof(float) * nPointsIn));
	CudaSafeCall(cudaMalloc((void **) &dY, sizeof(float) * nPointsIn));
	CudaSafeCall(cudaMalloc((void **) &dP, sizeof(float) * nPointsIn));
	CudaSafeCall(cudaMalloc((void **) &dC, sizeof(float) * nPointsIn));
	CudaSafeCall(cudaMalloc((void **) &dPoints, sizeof(int) * dataGridX * dataGridY));
	
	CudaSafeCall(cudaMemcpy(dX, xColOrd, sizeof(float) * nPointsIn, cudaMemcpyHostToDevice));
	CudaSafeCall(cudaMemcpy(dY, yColOrd, sizeof(float) * nPointsIn, cudaMemcpyHostToDevice));
	CudaSafeCall(cudaMemcpy(dP, pCOrd, sizeof(float) * nPointsIn, cudaMemcpyHostToDevice));
	CudaSafeCall(cudaMemcpy(dC, cCOrd, sizeof(float) * nPointsIn, cudaMemcpyHostToDevice));
	CudaSafeCall(cudaMemcpy(dPoints, nPointsB, sizeof(int) * dataGridX * dataGridY, cudaMemcpyHostToDevice));

	CudaCheckError();

	//Kernel Goes here
	kdeKernel<<<dimGrid, dimBlock>>>(dPop, dCase, nRow, nCol, xMin, yMax, cellSize, dX, dY, dP, dC, dPoints, bandwidth * bandwidth, blockBandwidth);


	CudaSafeCall(cudaMemcpy(popDen, dPop, sizeof(float) * nRow * nCol, cudaMemcpyDeviceToHost));
	CudaSafeCall(cudaMemcpy(caseDen, dCase, sizeof(float) * nRow * nCol, cudaMemcpyDeviceToHost));
	cudaFree(dPop);
	cudaFree(dCase);
	cudaFree(dX);
	cudaFree(dY);
	cudaFree(dP);
	cudaFree(dC);
	cudaFree(dPoints);

	free(xColOrd);
	free(yColOrd);
	free(pCOrd);
	free(cCOrd);

	free(dGridID);
	free(nPointsB);
	free(startIDB);
}
