#include <stdio.h>
#include <string.h>
#include "io.cuh"
#include <gdal.h>
#include <ogr_srs_api.h>
#include <ogr_api.h>
#include <cpl_conv.h>

struct Condition
{
	bool hhAtt;
	bool withinRange;
	int colID;
	char * conditionString;
	char * colName;
	int upper;
	int lower;
};



int getHHNum(FILE * file)
{
	int hhCount = 0;

	rewind(file);
	char line[4000];
	fgets(line, 4000, file);

	while(NULL != fgets(line, 4000, file))
	{
		hhCount ++;
	}

	return hhCount;
}

bool readPointsP(FILE * hhFile, FILE * popFile, int nHH, int &popCount, int &pNCase, float * xCol, float * yCol, float * pCount, float * cCount, char * mapLogic, char * personColName)
{
	char * hhAtt[1000];
	char * popAtt[1000];

	int numHHAtt;
	
	char hhLine[4000];
	char popLine[4000];

	popCount = 0;
	pNCase = 0;
	int hhID = 0;
	int persons;
	int personColID = -1;

	int popLineCount = 2;


	//Process the person-per-household
	rewind(hhFile);
    if(NULL == (fgets(hhLine, 4000, hhFile)))
	{
		printf("ERROR: Corrupted household file at line 1.\n");
		return false;
	}

	while((int)(hhLine[strlen(hhLine)-1]) < 47)
	{
		hhLine[strlen(hhLine)-1] = (char)0;
	}
	
	char * cName = strtok(hhLine, ",");
	for(int i = 1;; i++)
    {
        cName = strtok(NULL, ",");
        if(cName == NULL)
        {
            break;
        }

        //Person-per-household check
        if(strcmp(personColName, cName) == 0)
        {
            personColID = i;
        }
	}
	
	if(personColID < 0)
    {
        printf("ERROR: incorrect population-per-houshold column name: %s.\n", personColName);
		return false;
    }


	int numCondition = 0; //**************
	int numSingCond;
	struct Condition * conditions; 
	char mapLogicCopy[500];
	char ** logicConditions; //*************
	char * temp;
	char * singleLogic;
	strcpy(mapLogicCopy, mapLogic);

	temp = strtok(mapLogicCopy, "|");
	while(temp != NULL)
	{
		numCondition ++;
		temp = strtok(NULL, "|");
	}

	//printf("Number of Conditions: %d\n", numCondition);

	logicConditions = (char **) malloc (numCondition * sizeof (char *));
	logicConditions[0] = strtok(mapLogic, "|");
	for(int i = 1; i < numCondition; i++)
	{
		logicConditions[i] = strtok(NULL, "|");
	}


	for(int j = 0; j < numCondition; j++)
	{

		strcpy(mapLogicCopy, logicConditions[j]);

	//	printf(" condition %d: \t %s\n", j, logicConditions[j]);

		numSingCond = 0;
		singleLogic = strtok(mapLogicCopy, "&");
		while(singleLogic != NULL)
		{
			numSingCond ++;
			singleLogic = strtok(NULL, "&");
		}

		if(NULL == (conditions = (struct Condition *) malloc (sizeof(struct Condition) * numSingCond)))
		{
			printf("ERROR: Out of memory in line %d!\n", __LINE__);
			return false;
		}

		strcpy(mapLogicCopy, logicConditions[j]);
		conditions[0].conditionString = strtok(mapLogicCopy, "&");
		for(int i = 1; i < numSingCond; i++)
		{
			conditions[i].conditionString = strtok(NULL, "&");
		}	
		for(int i = 0; i < numSingCond; i++)
		{
			conditions[i].colName = strtok(conditions[i].conditionString, ":");
			if(conditions[i].colName[0] == '!') //if it is a not condition
			{
				conditions[i].colName ++;
				conditions[i].withinRange = false;
			}
			else
			{
				conditions[i].withinRange = true;
			}
			conditions[i].lower = atoi(strtok(NULL, ":"));
			conditions[i].upper = atoi(strtok(NULL, ":"));
		}

		rewind(hhFile);
		rewind(popFile);
		if(NULL == (fgets(hhLine, 4000, hhFile)))
		{
			printf("ERROR: Corrupted household file at line 1.\n");
			return false;
		}
		if(NULL == (fgets(popLine, 4000, popFile)))
		{
			printf("ERROR: Corrupted population file at line 1.\n");
			return false;
		}

		while((int)(hhLine[strlen(hhLine)-1]) < 47)
		{
			hhLine[strlen(hhLine)-1] = (char)0;
		}
	
		while((int)(popLine[strlen(popLine)-1]) < 47)
		{
			popLine[strlen(popLine)-1] = (char)0;
		}
	

		//printf("Here\n");

		int nCondition = 0;
		cName = strtok(hhLine, ",");

		for(int i = 1;; i++)
		{
			cName = strtok(NULL, ",");
			if(cName == NULL)
			{
				break;
			}

			for(int j = 0; j < numSingCond; j++)
			{
				if(strcmp(conditions[j].colName, cName) == 0)
				{
					conditions[j].hhAtt = true;
					conditions[j].colID = i;
					nCondition ++;
					break;
				}
			}

			numHHAtt = i + 1;

			if(nCondition == numSingCond)
				break;
		}

		if(numHHAtt > 1000)
		{
			printf("ERROR: To many colums in Household File.\n");
			return false;
		}

		cName = strtok(popLine, ",");

		for(int i = 1;; i++)
		{
			cName = strtok(NULL, ",");
			if(cName == NULL)
			{
				break;
			}

			for(int j = 0; j < numSingCond; j++)
			{
				if(strcmp(conditions[j].colName, cName) == 0)
				{
					conditions[j].hhAtt = false;
					conditions[j].colID = i;
					nCondition ++;
					break;
				}
			}

			if(nCondition == numSingCond)
				break;
		}

		if(nCondition != numSingCond)
		{
			printf("ERROR: incorrect column name.\n nCondition = %d \t numSingCond = %d \n", nCondition, numSingCond);
			return false;
		}

		for(hhID = 0; hhID < nHH; hhID ++)
		{
			if(NULL == (fgets(hhLine, 4000, hhFile)))
			{
				printf("ERROR: Corrupted household file at line %d\n", hhID + 2);
				return false;
			}
			hhAtt[0] = strtok(hhLine, ",");
			for(int i = 1; i < numHHAtt; i ++)
			{
				hhAtt[i] = strtok(NULL, ",");
				if(hhAtt[i] == NULL)
				{
					printf("ERROR: Corrupted household file at line %d\n", hhID + 2);
					return false;
				}
			}

			xCol[hhID] = atof(hhAtt[0]);
			yCol[hhID] = atof(hhAtt[1]);

			//Here needs to change, may not alwasy be the same
			persons = atoi(hhAtt[personColID]);

			pCount[hhID] = persons;

			if(j == 0)
				cCount[hhID] = 0;

			int value;

			bool isHHCase = true;
			bool isPopCase;

			for(int i = 0; i < numSingCond; i++)
			{
				if(conditions[i].hhAtt)
				{
					value = atoi(hhAtt[conditions[i].colID]);
					if(conditions[i].withinRange == true)
					{
						if(value < conditions[i].lower || value > conditions[i].upper)
						{
							isHHCase = false;
							break;
						}
					}
					else
					{
						if(value >= conditions[i].lower && value <= conditions[i].upper)
                        {
                            isHHCase = false;
                            break;
                        }
					}
				}
			}

			if(isHHCase)
			{
				for(int i = 0; i < persons; i++)
				{
					if(NULL == (fgets(popLine, 4000, popFile)))
					{
						printf("ERROR: Corrupted population file at line %d\n", popLineCount);
						return false;
					}

					popLineCount ++;

					popAtt[0] = strtok(popLine, ",");
					for(int i = 1; i < 1000; i ++)
					{
						popAtt[i] = strtok(NULL, ",");
					}

					isPopCase = true;


					for(int i = 0; i < numSingCond; i++)
					{
						if(!conditions[i].hhAtt)
						{
							value = atoi(popAtt[conditions[i].colID]);
							if(conditions[i].withinRange == true)
							{
								if(value < conditions[i].lower || value > conditions[i].upper)
								{
									isPopCase = false;
									break;
								}
							}
							else
							{
								if(value >= conditions[i].lower && value <= conditions[i].upper)
								{
									isPopCase = false;
									break;
								}
							}
						}
					}

					if(isPopCase)
					{
						cCount[hhID] += 1;
						pNCase ++;
					}
				}
			}
			else
			{
				for(int i = 0; i < persons; i++)
				{
					if(NULL == (fgets(popLine, 4000, popFile)))
					{
						printf("ERROR: Corrupted input population file at line %d.\n", popLineCount);
						return false;
					}
					popLineCount ++;	
				}
			}

		}

		free(conditions);

	}

//	printf("Done input!\n");
	free(logicConditions);

	return true;	
}

bool readPointsH(FILE * file, int nHH, int &positiveCount, float * xCol, float * yCol, float * pCount, float * cCount, char * mapLogic)
{
	char * att[1000];

	int numHHAtt;

	positiveCount = 0;
	int hhID = -1;

	int numCondition = 0; //**************
	int numSingCond;
	struct Condition * conditions; 
	char mapLogicCopy[500];
	char ** logicConditions; //*************
	char * temp;
	char * singleLogic;
	strcpy(mapLogicCopy, mapLogic);

	temp = strtok(mapLogicCopy, "|");
	while(temp != NULL)
	{
		numCondition ++;
		temp = strtok(NULL, "|");
	}

	logicConditions = (char **) malloc (numCondition * sizeof (char *));
	logicConditions[0] = strtok(mapLogic, "|");
	for(int i = 1; i < numCondition; i++)
	{
		logicConditions[i] = strtok(NULL, "|");
	}

	for(int j = 0; j < numCondition; j++)
	{

		strcpy(mapLogicCopy, logicConditions[j]);

		numSingCond = 0;
		singleLogic = strtok(mapLogicCopy, "&");
		while(singleLogic != NULL)
		{
			numSingCond ++;
			singleLogic = strtok(NULL, "&");
		}

		if(NULL == (conditions = (struct Condition *) malloc (sizeof(struct Condition) * numSingCond)))
		{
			printf("ERROR: Out of memory in line %d!\n", __LINE__);
			return false;
		}

		strcpy(mapLogicCopy, logicConditions[j]);
		conditions[0].conditionString = strtok(mapLogicCopy, "&");
		for(int i = 1; i < numSingCond; i++)
		{
			conditions[i].conditionString = strtok(NULL, "&");
		}	
		for(int i = 0; i < numSingCond; i++)
		{
			conditions[i].colName = strtok(conditions[i].conditionString, ":");
			if(conditions[i].colName[0] == '!') //if it is a not condition
			{
				conditions[i].colName ++;
				conditions[i].withinRange = false;
			}
			else
			{
				conditions[i].withinRange = true;
			}
			conditions[i].lower = atoi(strtok(NULL, ":"));
			conditions[i].upper = atoi(strtok(NULL, ":"));
		}

		rewind(file);
		char line[4000];
		if(NULL == (fgets(line, 4000, file)))
		{
			printf("ERROR: Corrupted household file at line 0\n");
			return false;
		}

		while((int)(line[strlen(line)-1]) < 47)
		{
			line[strlen(line)-1] = (char)0;
		}
	
		char * cName = strtok(line, ",");

		for(int i = 1, nCondition = 0;; i++)
		{
			cName = strtok(NULL, ",");
			if(cName == NULL)
			{
				printf("ERROR: incorrect column name.\n");
				return false;
			}

			for(int j = 0; j < numSingCond; j++)
			{
				if(strcmp(conditions[j].colName, cName) == 0)
				{
					conditions[j].hhAtt = true;
					conditions[j].colID = i;
					nCondition ++;
					break;
				}
			}

			numHHAtt = i + 1;

			if(nCondition == numSingCond)
				break;
		}

		if(numHHAtt > 1000)
		{
			printf("ERROR: To many colums in Household file.\n");
			return false;
		}

		hhID = -1;
		while(NULL != fgets(line, 4000, file))
		{
			att[0] = strtok(line, ",");
			for(int i = 1; i < numHHAtt; i ++)
			{
				att[i] = strtok(NULL, ",");
				if(att[i] == NULL)
				{
					printf("ERROR: Corrupted household file\n");
					return false;
				}
			}

			hhID ++;

			if(hhID >= nHH)
			{
				printf("ERROR: household ID out of bound\n");
				return false;
			}
			xCol[hhID] = atof(att[0]);
			yCol[hhID] = atof(att[1]);
			pCount[hhID] = 1;

			if(j == 0)
				cCount[hhID] = 0;

			int value;


			bool isCase = true;

			for(int i = 0; i < numSingCond; i++)
			{
				value = atoi(att[conditions[i].colID]);
				if(conditions[i].withinRange == true)
				{
					if(value < conditions[i].lower || value > conditions[i].upper)
					{
						isCase = false;
						break;
					}
				}
				else
				{
					if(value >= conditions[i].lower && value <= conditions[i].upper)
					{
						isCase = false;
						break;
					}
				}
			}

			if(isCase)
			{
				cCount[hhID] += 1;
				positiveCount ++;
			}
		}

		free(conditions);

	}

	free(logicConditions);
	return true;
}


bool readPointsPInSubPop(FILE * hhFile, FILE * popFile, int nHH, int &popCount, int &pNCase, float * xCol, float * yCol, float * pCount, float * cCount, char * subPop, char * mapLogic, char * personColName)
{
	char * hhAtt[1000];
	char * popAtt[1000];

	int numHHAtt;

	popCount = 0;
	pNCase = 0;
	int hhID = 0;
	int persons;
	int personColID = -1;

	int numCondition = 0;
	int numSingCond;
	struct Condition * conditions; 
	char mapLogicCopy[500];
	int numSubPopCond = 0;					//!!!
	struct Condition * subPopConditions;	//!!!
	char subPopCopy[500];					//!!!
	char ** logicConditions;
	char * temp;
	char * singleLogic;

	int popLineCount = 2;

	//Process sub-population conditions and person-per-household field
	strcpy(subPopCopy, subPop);
	temp = strtok(subPopCopy, "&");
	while(temp != NULL)
	{
		numSubPopCond ++;
		temp = strtok(NULL, "&");
	}

	if(NULL == (subPopConditions = (struct Condition *) malloc (sizeof(struct Condition) * numSubPopCond)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return false;
	}

	subPopConditions[0].conditionString = strtok(subPop, "&");
	for(int i = 1; i < numSubPopCond; i++)
	{
		subPopConditions[i].conditionString = strtok(NULL, "&");
	}	
	for(int i = 0; i < numSubPopCond; i++)
	{
		subPopConditions[i].colName = strtok(subPopConditions[i].conditionString, ":");
		if(subPopConditions[i].colName[0] == '!') //if it is a not condition
		{
			subPopConditions[i].colName ++;
			subPopConditions[i].withinRange = false;
		}
		else
		{
			subPopConditions[i].withinRange = true;
		}
		subPopConditions[i].lower = atoi(strtok(NULL, ":"));
		subPopConditions[i].upper = atoi(strtok(NULL, ":"));
//		printf("SubPop %s: %d - %d\n", subPopConditions[i].colName, subPopConditions[i].lower, subPopConditions[i].upper);
	}

	rewind(hhFile);
	rewind(popFile);
	char hhLine[4000];
	char popLine[4000];
	if(NULL == (fgets(hhLine, 4000, hhFile)))
	{
		printf("ERROR: Corrupted household file at line 1.\n");
		return false;
	}
	if(NULL == (fgets(popLine, 4000, popFile)))
	{
		printf("ERROR: Corrupted population file at line 1.\n");
		return false;
	}

	while((int)(hhLine[strlen(hhLine)-1]) < 47)
	{
		hhLine[strlen(hhLine)-1] = (char)0;
	}
	
	while((int)(popLine[strlen(popLine)-1]) < 47)
	{
		popLine[strlen(popLine)-1] = (char)0;
	}
	
	int nCondition = 0;
	char * cName = strtok(hhLine, ",");

	for(int i = 1;; i++)
	{
		cName = strtok(NULL, ",");
		if(cName == NULL)
		{
			break;
		}
		
		//Person-per-household check
		if(strcmp(personColName, cName) == 0)
		{
			personColID = i;
		}

		for(int j = 0; j < numSubPopCond; j++)
		{
			if(strcmp(subPopConditions[j].colName, cName) == 0)
			{
				subPopConditions[j].hhAtt = true;
				subPopConditions[j].colID = i;
				nCondition ++;
				break;
			}
		}

		if(cName != NULL)
		{
			numHHAtt = i + 1;
		}
	}

	if(personColID < 0)
	{
		printf("ERROR: incorrect population-per-houshold column name: %s.\n", personColName);
		return false;
	}

	cName = strtok(popLine, ",");

	for(int i = 1;; i++)
	{
		cName = strtok(NULL, ",");
		if(cName == NULL)
		{
			break;
		}

		for(int j = 0; j < numSubPopCond; j++)
		{
			if(strcmp(subPopConditions[j].colName, cName) == 0)
			{
				subPopConditions[j].hhAtt = false;
				subPopConditions[j].colID = i;
				nCondition ++;
				break;
			}
		}
	}

	if(nCondition != numSubPopCond)
	{
		printf("ERROR: incorrect column name.\n nCondition = %d \t numSubPopCond = %d \n", nCondition, numSubPopCond);
		return false;
	}

	//process map logic conditions
	strcpy(mapLogicCopy, mapLogic);
	temp = strtok(mapLogicCopy, "|");
	while(temp != NULL)
	{
		numCondition ++;
		temp = strtok(NULL, "|");
	}

//	printf("Number of Conditions: %d\n", numCondition);

	logicConditions = (char **) malloc (numCondition * sizeof (char *));
	logicConditions[0] = strtok(mapLogic, "|");
	for(int i = 1; i < numCondition; i++)
	{
		logicConditions[i] = strtok(NULL, "|");
	}


	for(int j = 0; j < numCondition; j++)
	{
		popLineCount = 2;

		strcpy(mapLogicCopy, logicConditions[j]);

//		printf(" condition %d: \t %s\n", j, logicConditions[j]);

		numSingCond = 0;
		singleLogic = strtok(mapLogicCopy, "&");
		while(singleLogic != NULL)
		{
			numSingCond ++;
			singleLogic = strtok(NULL, "&");
		}

		if(NULL == (conditions = (struct Condition *) malloc (sizeof(struct Condition) * numSingCond)))
		{
			printf("ERROR: Out of memory in line %d!\n", __LINE__);
			return false;
		}

		strcpy(mapLogicCopy, logicConditions[j]);
		conditions[0].conditionString = strtok(mapLogicCopy, "&");
		for(int i = 1; i < numSingCond; i++)
		{
			conditions[i].conditionString = strtok(NULL, "&");
		}	
		for(int i = 0; i < numSingCond; i++)
		{
			conditions[i].colName = strtok(conditions[i].conditionString, ":");
			if(conditions[i].colName[0] == '!') //if it is a not condition
			{
				conditions[i].colName ++;
				conditions[i].withinRange = false;
			}
			else
			{
				conditions[i].withinRange = true;
			}
			conditions[i].lower = atoi(strtok(NULL, ":"));
			conditions[i].upper = atoi(strtok(NULL, ":"));
		}

		rewind(hhFile);
		rewind(popFile);
		if(NULL == (fgets(hhLine, 4000, hhFile)))
		{
			printf("ERROR: Corrupted household file at line 1.\n");
			return false;
		} 
		if(NULL == (fgets(popLine, 4000, popFile)))
		{
			printf("ERROR: Corrupted population file at line 1.\n");
			return false;
		} 

		while((int)(hhLine[strlen(hhLine)-1]) < 47)
		{
			hhLine[strlen(hhLine)-1] = (char)0;
		}
	
		while((int)(popLine[strlen(popLine)-1]) < 47)
		{
			popLine[strlen(popLine)-1] = (char)0;
		}
	

		//printf("Here\n");

		nCondition = 0;
		cName = strtok(hhLine, ",");

		for(int i = 1;; i++)
		{
			cName = strtok(NULL, ",");
			if(cName == NULL)
			{
				break;
			}

			for(int k = 0; k < numSingCond; k++)
			{
				if(strcmp(conditions[k].colName, cName) == 0)
				{
					conditions[k].hhAtt = true;
					conditions[k].colID = i;
					nCondition ++;
					break;
				}
			}

			if(nCondition == numSingCond)
				break;
		}

		cName = strtok(popLine, ",");

		for(int i = 1;; i++)
		{
			cName = strtok(NULL, ",");
			if(cName == NULL)
			{
				break;
			}

			for(int k = 0; k < numSingCond; k++)
			{
				if(strcmp(conditions[k].colName, cName) == 0)
				{
					conditions[k].hhAtt = false;
					conditions[k].colID = i;
					nCondition ++;
					break;
				}
			}

			if(nCondition == numSingCond)
				break;
		}

		if(nCondition != numSingCond)
		{
			printf("ERROR: incorrect column name.\n nCondition = %d \t numSingCond = %d \n", nCondition, numSingCond);
			return false;
		}

		for(hhID = 0; hhID < nHH; hhID ++)
		{
			if(NULL == (fgets(hhLine, 4000, hhFile)))
			{
				printf("ERROR: Corrupted household file at line %d\n", hhID + 2);
				return false;
			}
			hhAtt[0] = strtok(hhLine, ",");
			for(int i = 1; i < numHHAtt; i ++)
			{
				hhAtt[i] = strtok(NULL, ",");
				if(hhAtt[i] == NULL)
				{
					printf("ERROR: Corrupted household file at line %d\n", hhID + 2);
					return false;
				}
			}

			xCol[hhID] = atof(hhAtt[0]);
			yCol[hhID] = atof(hhAtt[1]);

			//Here needs to change, may not alwasy be the same
			persons = atoi(hhAtt[personColID]);

			pCount[hhID] = 0;

			if(j == 0)
				cCount[hhID] = 0;

			int value;

			bool isHHCase = true;
			bool isPopCase;

			bool isHHBP = true; //!!!
			bool isPopBP;		//!!!


//**********Logic**************
//*********isHHBP**************
//******No*******Yes***********
//***Nothing***isPopBP*********
//************Yes****No********
//********isPopCase**Nothing***
//********isHHCase*************
//******Yes*****No*************
//****AddBoth***AddCase********
			for(int i = 0; i < numSubPopCond; i++)
			{
				if(subPopConditions[i].hhAtt)
				{
					value = atoi(hhAtt[subPopConditions[i].colID]);
					if(subPopConditions[i].withinRange == true)
					{
						if(value < subPopConditions[i].lower || value > subPopConditions[i].upper)
						{
							isHHBP = false;
							break;
						}
					}
					else
					{
						if(value >= subPopConditions[i].lower && value <= subPopConditions[i].upper)
						{
							isHHBP = false;
							break;
						}
					}
				}
			}

			if(isHHBP)
			{

				for(int i = 0; i < numSingCond; i++)
				{
					if(conditions[i].hhAtt)
					{
						value = atoi(hhAtt[conditions[i].colID]);
						if(conditions[i].withinRange == true)
						{
							if(value < conditions[i].lower || value > conditions[i].upper)
							{
								isHHCase = false;
								break;
							}
						}
						else
						{
							if(value >= conditions[i].lower && value <= conditions[i].upper)
							{
								isHHCase = false;
								break;
							}
						}
					}
				}

				for(int i = 0; i < persons; i++)
				{
					if(NULL == (fgets(popLine, 4000, popFile)))
					{
						printf("ERROR: Corrupted population file at line %d.\n", popLineCount);
						return false;
					}

					popLineCount ++;

					popAtt[0] = strtok(popLine, ",");
					for(int i = 1; i < 1000; i ++)
					{
						popAtt[i] = strtok(NULL, ",");
					}

					isPopBP = true;
					isPopCase = true;

					for(int k = 0; k < numSubPopCond; k++)
					{
						if(!subPopConditions[k].hhAtt)
						{
							value = atoi(popAtt[subPopConditions[k].colID]);
							if(subPopConditions[k].withinRange == true)
							{
								if(value < subPopConditions[k].lower || value > subPopConditions[k].upper)
								{
									isPopBP = false;
									break;
								}
							}
							else
							{
								if(value >= subPopConditions[k].lower && value <= subPopConditions[k].upper)
								{
									isPopBP = false;
									break;
								}
							}
						}
					}

					if(isPopBP)
					{
						for(int k = 0; k < numSingCond; k++)
						{
							if(!conditions[k].hhAtt)
							{
								value = atoi(popAtt[conditions[k].colID]);
								if(conditions[k].withinRange == true)
								{
									if(value < conditions[k].lower || value > conditions[k].upper)
									{
										isPopCase = false;
										break;
									}
								}
								else
								{
									if(value >= conditions[k].lower && value <= conditions[k].upper)
									{
										isPopCase = false;
										break;
									}
								}
							}
						}

						if(isPopCase && isHHCase)
						{
							cCount[hhID] += 1;
							pCount[hhID] += 1;
							pNCase ++;
						}
						else
						{
							pCount[hhID] += 1;
						}
					}
				}
			}
			else
			{
				for(int i = 0; i < persons; i++)
				{
					if(NULL == (fgets(popLine, 4000, popFile)))
					{
						printf("ERROR: Corrupted population file at line %d.\n", popLineCount);
						return false;
					}
					popLineCount ++;
				}
			}

		}

		free(conditions);

	}

//	printf("Done input!\n");
	free(logicConditions);
	free(subPopConditions);	
	return true;
}

bool readPointsHInSubPop(FILE * file, int nHH, int &positiveCount, float * xCol, float * yCol, float * pCount, float * cCount, char * subPop, char * mapLogic)
{
	char * att[1000];

	int numHHAtt;

	positiveCount = 0;
	int hhID = -1;

	int numCondition = 0;
	int numSingCond;
	struct Condition * conditions; 
	char mapLogicCopy[500];
	int numSubPopCond = 0;					//!!!
	struct Condition * subPopConditions;	//!!!
	char subPopCopy[500];					//!!!
	char ** logicConditions;
	char * temp;
	char * singleLogic;


	//Process sub-population conditions
	strcpy(subPopCopy, subPop);
	temp = strtok(subPopCopy, "&");
	while(temp != NULL)
	{
		numSubPopCond ++;
		temp = strtok(NULL, "&");
	}

	if(NULL == (subPopConditions = (struct Condition *) malloc (sizeof(struct Condition) * numSubPopCond)))
	{
		printf("ERROR: Out of memory in line %d!\n", __LINE__);
		return false;
	}

	subPopConditions[0].conditionString = strtok(subPop, "&");
	for(int i = 1; i < numSubPopCond; i++)
	{
		subPopConditions[i].conditionString = strtok(NULL, "&");
	}	
	for(int i = 0; i < numSubPopCond; i++)
	{
		subPopConditions[i].colName = strtok(subPopConditions[i].conditionString, ":");
		if(subPopConditions[i].colName[0] == '!') //if it is a not condition
		{
			subPopConditions[i].colName ++;
			subPopConditions[i].withinRange = false;
		}
		else
		{
			subPopConditions[i].withinRange = true;
		}
		subPopConditions[i].lower = atoi(strtok(NULL, ":"));
		subPopConditions[i].upper = atoi(strtok(NULL, ":"));
//		printf("SubPop %s: %d - %d\n", subPopConditions[i].colName, subPopConditions[i].lower, subPopConditions[i].upper);
	}

	rewind(file);
	char line[4000];
	if(NULL == (fgets(line, 4000, file)))
	{
		printf("ERROR: Corrupted household file at line 1.\n");
		return false;
	}
	char * cName = strtok(line, ",");

	for(int i = 1, nCondition = 0;; i++)
	{
		cName = strtok(NULL, ",");
		if(cName == NULL)
		{
			printf("ERROR: incorrect column name.\n");
			return false;
		}

		for(int k = 0; k < numSubPopCond; k++)
		{
			if(strcmp(subPopConditions[k].colName, cName) == 0)
			{
				subPopConditions[k].hhAtt = true;
				subPopConditions[k].colID = i;
				nCondition ++;
				break;
			}
		}

		numHHAtt = i + 1;

		if(nCondition == numSubPopCond)
			break;
	}

	if(numHHAtt > 1000)
	{
		printf("ERROR: To many colums in household file.\n");
		return false;
	}

	//Process map logic
	strcpy(mapLogicCopy, mapLogic);

	temp = strtok(mapLogicCopy, "|");
	while(temp != NULL)
	{
		numCondition ++;
		temp = strtok(NULL, "|");
	}

	logicConditions = (char **) malloc (numCondition * sizeof (char *));
	logicConditions[0] = strtok(mapLogic, "|");
	for(int i = 1; i < numCondition; i++)
	{
		logicConditions[i] = strtok(NULL, "|");
	}

	for(int j = 0; j < numCondition; j++)
	{

		strcpy(mapLogicCopy, logicConditions[j]);

		numSingCond = 0;
		singleLogic = strtok(mapLogicCopy, "&");
		while(singleLogic != NULL)
		{
			numSingCond ++;
			singleLogic = strtok(NULL, "&");
		}

		if(NULL == (conditions = (struct Condition *) malloc (sizeof(struct Condition) * numSingCond)))
		{
			printf("ERROR: Out of memory in line %d!\n", __LINE__);
			return false;
		}

		strcpy(mapLogicCopy, logicConditions[j]);
		conditions[0].conditionString = strtok(mapLogicCopy, "&");
		for(int i = 1; i < numSingCond; i++)
		{
			conditions[i].conditionString = strtok(NULL, "&");
		}	
		for(int i = 0; i < numSingCond; i++)
		{
			conditions[i].colName = strtok(conditions[i].conditionString, ":");
			if(conditions[i].colName[0] == '!') //if it is a not condition
			{
				conditions[i].colName ++;
				conditions[i].withinRange = false;
			}
			else
			{
				conditions[i].withinRange = true;
			}
			conditions[i].lower = atoi(strtok(NULL, ":"));
			conditions[i].upper = atoi(strtok(NULL, ":"));
		}

		rewind(file);
		if(NULL == (fgets(line, 4000, file)))
		{
			printf("ERROR: Corrupted household file at line 1.\n");
			return false;
		}
		cName = strtok(line, ",");

		for(int i = 1, nCondition = 0;; i++)
		{
			cName = strtok(NULL, ",");
			if(cName == NULL)
			{
				printf("ERROR: incorrect column name.\n");
				return false;
			}

			for(int j = 0; j < numSingCond; j++)
			{
				if(strcmp(conditions[j].colName, cName) == 0)
				{
					conditions[j].hhAtt = true;
					conditions[j].colID = i;
					nCondition ++;
					break;
				}
			}

			if(numHHAtt < i + 1)
				numHHAtt = i + 1;

			if(nCondition == numSingCond)
				break;
		}

		if(numHHAtt > 1000)
		{
			printf("ERROR: To many colums in household file.\n");
			return false;
		}

		hhID = -1;
		while(NULL != fgets(line, 4000, file))
		{
			att[0] = strtok(line, ",");
			for(int i = 1; i < numHHAtt; i ++)
			{
				att[i] = strtok(NULL, ",");
				if(att[i] == NULL)
				{
					printf("ERROR: Corrupted household file.\n");
					return false;
				}
			}
			hhID ++;

			if(hhID >= nHH)
			{
				printf("ERROR: household ID out of bound\n");
				return false;
			}
			xCol[hhID] = atof(att[0]);
			yCol[hhID] = atof(att[1]);
			//pCount[hhID] = 1;

			if(j == 0)
				cCount[hhID] = 0;

			int value;


			bool isCase = true;
			bool isPop = true;

			for(int i = 0; i < numSubPopCond; i++)
			{
				value = atoi(att[subPopConditions[i].colID]);
				if(subPopConditions[i].withinRange == true)
				{
					if(value < subPopConditions[i].lower || value > subPopConditions[i].upper)
					{
						isPop = false;
						break;
					}
				}
				else
				{
					if(value >= subPopConditions[i].lower && value <= subPopConditions[i].upper)
					{
						isPop = false;
						break;
					}
				}
			}
			if(isPop)
			{
				for(int i = 0; i < numSingCond; i++)
				{
					value = atoi(att[conditions[i].colID]);
					if(conditions[i].withinRange == true)
					{
						if(value < conditions[i].lower || value > conditions[i].upper)
						{
							isCase = false;
							break;
						}
					}
					else
					{
						if(value >= conditions[i].lower && value <= conditions[i].upper)
						{
							isCase = false;
							break;
						}
					}
				}

				if(isCase)
				{
					cCount[hhID] += 1;
					positiveCount ++;
				}
				pCount[hhID] = 1;
			}
		}

		free(conditions);

	}

	free(logicConditions);
	free(subPopConditions);
	return true;
}

void writeGridRatio(FILE * output, float * caseDen, float * popDen, int nRow, int nCol, float xMin, float yMax, float cellSize)
{
	fprintf(output, "ncols\t%d\n", nCol);
	fprintf(output, "nrows\t%d\n", nRow);
	fprintf(output, "xllcorner\t%f\n", xMin);
	fprintf(output, "yllcorner\t%f\n", yMax);
	fprintf(output, "cellsize\t%f\n", cellSize);
	fprintf(output, "NODATA_value\t-1.00000\n");
	for(int i = 0; i < nRow; i++)
	{
		if(popDen[i * nCol] > 0)
			fprintf(output, "%.5f", caseDen[i * nCol] / popDen[i * nCol]);
		else
			fprintf(output, "-1.00000");
		
		for(int j = 1; j < nCol; j++)
		{
			if(popDen[i * nCol + j] > 0)
				fprintf(output, " %.5f", caseDen[i * nCol + j] / popDen[i * nCol + j]);
			else
				fprintf(output, " -1.00000");
		}
		fprintf(output, "\n");
	}
}

void writeGeoTiffRatio(char * fileName, float * caseDen, float * popDen, int nRow, int nCol, float xMin, float yMax, float cellSize)
{
	//Calculate Ratio
	float * grid;
	grid = (float *) malloc (nRow * nCol * sizeof(float));
	for(int i = 0; i < nRow; i++)
	{
		for(int j = 0; j < nCol; j++)
		{
			if(popDen[i * nCol + j] > 0)
			{
				grid[i * nCol + j] = caseDen[i * nCol + j] / popDen[i * nCol + j];
			}
			else
			{
				grid[i * nCol + j] = -1;
			}
		}
	}


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
	GDALRasterIO(hBand, GF_Write, 0, 0, nCol, nRow, grid, nCol, nRow, GDT_Float32, 0, 0 );
	
	GDALClose(hDstDS);

	free(grid);
	return;
}

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

void writeGridF(FILE * output, float * result, int nRow, int nCol, float xMin, float yMax, float cellSize, float noData)
{
	fprintf(output, "ncols\t%d\n", nCol);
	fprintf(output, "nrows\t%d\n", nRow);
	fprintf(output, "xllcorner\t%f\n", xMin);
	fprintf(output, "yllcorner\t%f\n", yMax);
	fprintf(output, "cellsize\t%f\n", cellSize);
	fprintf(output, "NODATA_value\t%f\n", noData);
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


void writeGeoTiffF(char * fileName, float * result, int nRow, int nCol, float xMin, float yMax, float cellSize, int epsgCode)
{
	
	GDALAllRegister();
	OGRRegisterAll();

	GDALDatasetH hDstDS;
	GDALDriverH hDriver;
	GDALRasterBandH hBand;
	OGRSpatialReferenceH hSRS;
	char *pszSRS_WKT = NULL;
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

	hSRS=OSRNewSpatialReference(NULL);
	OSRImportFromEPSG(hSRS,epsgCode);
	OSRExportToWkt(hSRS,&pszSRS_WKT);
	GDALSetProjection(hDstDS,pszSRS_WKT);
	OSRDestroySpatialReference(hSRS);
	CPLFree(pszSRS_WKT);

	hBand=GDALGetRasterBand(hDstDS,1);
	GDALSetRasterNoDataValue(hBand,-1);
	GDALRasterIO(hBand, GF_Write, 0, 0, nCol, nRow, result, nCol, nRow, GDT_Float32, 0, 0 );
	
	GDALClose(hDstDS);

	return;
}

void writeGeoTiffI(char * fileName, int * result, int nRow, int nCol, float xMin, float yMax, float cellSize, int epsgCode)
{
	
	GDALAllRegister();
	OGRRegisterAll();

	GDALDatasetH hDstDS;
	GDALDriverH hDriver;
	GDALRasterBandH hBand;
	OGRSpatialReferenceH hSRS;
	char *pszSRS_WKT = NULL;
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

	hSRS=OSRNewSpatialReference(NULL);
	OSRImportFromEPSG(hSRS,epsgCode);
	OSRExportToWkt(hSRS,&pszSRS_WKT);
	GDALSetProjection(hDstDS,pszSRS_WKT);
	OSRDestroySpatialReference(hSRS);
	CPLFree(pszSRS_WKT);

	hBand=GDALGetRasterBand(hDstDS,1);
	GDALSetRasterNoDataValue(hBand,-1);
	GDALRasterIO(hBand, GF_Write, 0, 0, nCol, nRow, result, nCol, nRow, GDT_Int32, 0, 0 );
	
	GDALClose(hDstDS);

	return;
}

void writeGeoTiffRatio(char * fileName, float * caseDen, float * popDen, int nRow, int nCol, float xMin, float yMax, float cellSize, int epsgCode)
{
	//Calculate Ratio
	float * grid;
	grid = (float *) malloc (nRow * nCol * sizeof(float));
	for(int i = 0; i < nRow; i++)
	{
		for(int j = 0; j < nCol; j++)
		{
			if(popDen[i * nCol + j] > 0)
			{
				grid[i * nCol + j] = caseDen[i * nCol + j] / popDen[i * nCol + j];
			}
			else
			{
				grid[i * nCol + j] = -1;
			}
		}
	}


	GDALAllRegister();
	OGRRegisterAll();

	GDALDatasetH hDstDS;
	GDALDriverH hDriver;
	GDALRasterBandH hBand;
	OGRSpatialReferenceH hSRS;
	char *pszSRS_WKT = NULL;
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

	hSRS=OSRNewSpatialReference(NULL);
	OSRImportFromEPSG(hSRS,epsgCode);
	OSRExportToWkt(hSRS,&pszSRS_WKT);
	GDALSetProjection(hDstDS,pszSRS_WKT);
	OSRDestroySpatialReference(hSRS);
	CPLFree(pszSRS_WKT);

	hBand=GDALGetRasterBand(hDstDS,1);
	GDALSetRasterNoDataValue(hBand,-1);
	GDALRasterIO(hBand, GF_Write, 0, 0, nCol, nRow, grid, nCol, nRow, GDT_Float32, 0, 0 );
	
	GDALClose(hDstDS);

	free(grid);
	return;
}

