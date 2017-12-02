#!/bin/bash
#Example script to choose a subset of people based on logical conditions of household and population
#Yizhao Gao (yizhaotsccsj@gmail.com)
# java - cp Subset.jar subset.AttributePopulationSubset [inputRealizetionFileBeforeRznID] [outputChosenRealizetionFileBeforeRznID] [outputUnchosenRealizetionFileBeforeRznID] [popFieldName] [startingRznID] [numberOfRzns] [logicCondition] [popChosenField]
para="/home/ygao29/data/digpop/rzn ./result/chosenRzn ./result/unchosenRzn PERSONS 1 1 AGE:0:12|AGE:13:99&LIT:1:1 PopChosen"
echo "parameters: $para"
java -cp Subset.jar subset.AttributePopulationSubset $para
