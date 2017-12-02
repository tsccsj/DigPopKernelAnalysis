#!/bin/bash
#Example script to choose a subset of household based on ESRI ASCII grid of probability
#Yizhao Gao (yizhaotsccsj@gmail.com)
# java - cp Subset.jar subset.AreaHouseholdSubSet [inputProbabilityGrid] [inputRealizetionFileBeforeRznID] [outputChosenRealizetionFileBeforeRznID] [outputUnchosenRealizetionFileBeforeRznID] [popFieldName] [startingRznID] [numberOfRzns] [randomSeed(optional)]
para="test.asc /home/ygao29/data/digpop/rzn ./result/chosenRzn ./result/unchosenRzn PERSONS 1 1"
echo "parameters: $para"
java -cp Subset.jar subset.AreaHouseholdSubset $para
