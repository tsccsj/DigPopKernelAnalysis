#!/bin/bash
#Example script to choose a subset of people based on logical conditions of household
#Yizhao Gao (yizhaotsccsj@gmail.com)
# java - cp Subset.jar subset.AttributeHouseholdSubset [inputRealizetionFileBeforeRznID] [outputChosenRealizetionFileBeforeRznID] [outputUnchosenRealizetionFileBeforeRznID] [popFieldName] [startingRznID] [numberOfRzns] [logicCondition]
para="/home/ygao29/data/digpop/rzn ./result/chosenRzn ./result/unchosenRzn PERSONS 1 1 BD11A_TOILET:2:2&ELECTRC:2:2&BD11A_WATSRC:3:3|BD11A_TOILET:3:3&ELECTRC:2:2&BD11A_WATSRC:1:2"
echo "parameters: $para"
java -cp Subset.jar subset.AttributeHouseholdSubset $para
