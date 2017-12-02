#!/bin/bash
#Example script to choose a subset of people based on ESRI ASCII grid of probability
#Yizhao Gao (yizhaotsccsj@gmail.com)
# java - cp Subset.jar subset.AreaPopulationSubset [inputProbabilityGrid] [inputRealizetionFileBeforeRznID] [outputChosenRealizetionFileBeforeRznID] [outputUnchosenRealizetionFileBeforeRznID] [popFieldName] [startingRznID] [numberOfRzns] [popChosenFieldName] [randomSeed(optional)]
para="test.asc /home/ygao29/data/digpop/rzn ./result/chosenRzn ./result/unchosenRzn PERSONS 1 1 PChosen"
echo "parameters: $para"
java -cp Subset.jar subset.AreaPopulationSubset $para
