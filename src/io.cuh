#ifndef IOH
#define IOH

int getHHNum(FILE * file);
bool readPointsP(FILE * hhFile, FILE * popFile, int nHH, int &popCount, int &pNCase, float * xCol, float * yCol, float * pCount, float * cCount, char * mapLogic, char * personColName);
bool readPointsH(FILE * file, int nHH, int &positiveCount, float * xCol, float * yCol, float * pCount, float * cCount, char * mapLogic);
bool readPointsPInSubPop(FILE * hhFile, FILE * popFile, int nHH, int &popCount, int &pNCase, float * xCol, float * yCol, float * pCount, float * cCount, char * subPop, char * mapLogic, char * personColName);
bool readPointsHInSubPop(FILE * file, int nHH, int &positiveCount, float * xCol, float * yCol, float * pCount, float * cCount, char * subPop, char * mapLogic);
void writeGridRatio(FILE * output, float * caseDen, float * popDen, int nRow, int nCol, float xMin, float yMax, float cellSize);
void writeGeoTiffRatio(char * fileName, float * caseDen, float * popDen, int nRow, int nCol, float xMin, float yMax, float cellSize);
void writeGeoTiffRatio(char * fileName, float * caseDen, float * popDen, int nRow, int nCol, float xMin, float yMax, float cellSize, int epsgCode);
void writeGridF(FILE * output, float * result, int nRow, int nCol, float xMin, float yMax, float cellSize);
void writeGridF(FILE * output, float * result, int nRow, int nCol, float xMin, float yMax, float cellSize, float noData);
void writeGridI(FILE * output, int * result, int nRow, int nCol, float xMin, float yMax, float cellSize);
void writeGeoTiffF(char * fileName, float * result, int nRow, int nCol, float xMin, float yMax, float cellSize);
void writeGeoTiffI(char * fileName, int * result, int nRow, int nCol, float xMin, float yMax, float cellSize);
void writeGeoTiffF(char * fileName, float * result, int nRow, int nCol, float xMin, float yMax, float cellSize, int epsgCode);
void writeGeoTiffI(char * fileName, int * result, int nRow, int nCol, float xMin, float yMax, float cellSize, int epsgCode);
#endif

