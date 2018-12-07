using Pkg, DataFrames, CSV, Printf,DataStructures#, Plots

struct Action2
    stateToMoveFrom::Tuple{Int64, Int64}
    stateToMoveTo::Tuple{Int64, Int64}
    numPoliceOfficersToMove::Float64
end

function findNeediestStates(S,threshold)
sizeS = size(S)
neediestStateInds = Int64[]
needyqueue = PriorityQueue{Tuple{Int64,Int64}, Float64}(Base.Order.Reverse)
for lat in 1 : sizeS[1]
    for long in 1: sizeS[2]
        if (S[lat,long] < threshold)
            enqueue!(needyqueue, tuple(lat,long),S[lat,long])
        end
    end
end
return needyqueue
end

function findHighestSurplusStates(S,num)
highestSurplusList = Array{Tuple{Int64, Int64}}(undef, num)
S0 = deepcopy(S)
for i in 1 : num
    (max1, maxind) = findmax(S0);
    highestSurplusList[i] = maxind
    S0[maxind] = -Inf;
end
return highestSurplusList
end

function findClosestSurplusStates(S,num,needystateIdx)
lat0=needystateIdx[1];
long0=needystateIdx[2];
closestSurplusList=Array{Tuple{Int64, Int64}}(undef, num);
numFound=0;
currentMaxDist=0;
(maxLat,maxLong)=size(S);
while (numFound<num || currentMaxDist>=maxLat+maxLong)
    currentMaxDist = currentMaxDist + 1;
    for deltaLat in -currentMaxDist : 1 : currentMaxDist
        # Stop searching if we've already found the required number of states
        if numFound >= num
            break;
        end
        deltaLong = currentMaxDist - abs(deltaLat);
        latNew = lat0 + deltaLat;
        longNew1= long0 + deltaLong;
        longNew2= long0 - deltaLong;
        if (isRealGridCell(latNew,longNew1,S) && S[latNew,longNew1] > 0)
            numFound = numFound + 1;
            closestSurplusList[numFound]=tuple(latNew, longNew1);
        end
        # If there is a second longNew and if we haven't already reached our limit
        if (deltaLong != 0 && numFound < num)
            if (isRealGridCell(latNew,longNew2,S) && S[latNew,longNew2] > 0)
                numFound = numFound + 1;
                closestSurplusList[numFound]=tuple(latNew, longNew2);
            end
        end
    end
end
return closestSurplusList
end

function isRealGridCell(lat,long,S)
    maxLat = size(S,1);
    maxLong = size(S,2);
    if (lat>=1 && lat <= maxLat && long>=1 && long<= maxLong)
        return true;
    else
        return false;
    end
end

function dist(s, s0)
return abs(s[1]-s0[1])+abs(s[2]-s0[2])
end

function findReward(S, action::Action2)
# computes reward for a given grid state and action
s = action.stateToMoveFrom
s0 = action.stateToMoveTo
reward = 0;
# The reward is just the cost of moving these police officers a certain dist
reward -= dist(s, s0)*action.numPoliceOfficersToMove
Snew=applyAction(S, action)
return reward
end

function applyAction(S, action::Action2)
Snew = deepcopy(S)
s = action.stateToMoveFrom
s0 = action.stateToMoveTo
Snew[s...] = S[s...] - action.numPoliceOfficersToMove
Snew[s0...] = S[s0...] + action.numPoliceOfficersToMove
return Snew
end


function pickOptimalAction(S,needystateIdx,highestSurplusList,closestSurplusList)
totallist = [highestSurplusList;closestSurplusList];
numActions=length(totallist);
possibleactions = Vector{Action2}(undef,numActions)
rewards = Vector{Float64}(undef,numActions)
for i in 1:numActions
    cell = totallist[i]
    numPoliceOfficersToMove = min(abs(S[needystateIdx...]),S[cell...])
    action = Action2(cell,needystateIdx,numPoliceOfficersToMove)
    rewards[i] = findReward(S, action)
    possibleactions[i] = action
end
optimalactionind = argmax(rewards)
optimalaction = possibleactions[optimalactionind]
return optimalaction
end


function main(hour,P,C,threshold)
S = P-C;
num = 5
needyqueue = findNeediestStates(S,threshold);
actionlist = Vector{Action2}(undef,0)
while !isempty(needyqueue)
    needystate = peek(needyqueue);
    highestSurplusList = findHighestSurplusStates(S,num)
    needystateIdx = needystate.first;
    closestSurplusList = findClosestSurplusStates(S,num,needystateIdx)
    bestaction = pickOptimalAction(S,needystateIdx,highestSurplusList,closestSurplusList)
    push!(actionlist,bestaction)
    Snew=applyAction(S,bestaction)
    show(bestaction.stateToMoveFrom)
    S=Snew
    needyqueue = findNeediestStates(S,threshold);
end
Pnew=C+S
return actionlist,Pnew
end

function findHourlyPolicy(PInit,CAllHours,threshold)
    policylist = Vector{Vector{Action2}}(undef,0)
    Plist=Vector{Array{Float64,2}}(undef,0);
    P=PInit
    push!(Plist,P)
    for hour in 1:24
        C=CAllHours[:,:,hour];
        (actionlist, Pnew) = main(hour,P,C,threshold)
        push!(policylist,actionlist)
        push!(Plist,Pnew)
        P=Pnew
    end
    return policylist,Plist
end

function evaluatePolicy(policylist::Vector{Vector{Action2}},sizeOfGrid,Plist,CAllHours)
    intermediateRewards=Vector{Tuple{Float64,Float64}}(undef,0)
    for hour in 1:24
        C=CAllHours[:,:,hour]
        P=Plist[hour]
        Sinit=P-C
        policyForThisHour=policylist[hour]
        policyWithDurations=Vector{Tuple{Action2,Float64}}(undef,length(policyForThisHour))
        for i=1:length(policyForThisHour)
            action=policyForThisHour[i];
            timeForAction=findTimeForAction(action,sizeOfGrid);
            policyWithDurations[i]=(action,timeForAction)
        end
        sort!(policyWithDurations, by = x -> x[2])
        sortedDurations=[x[2] for x in policyWithDurations]
        idxTimesteps=findlast.(isequal.(unique(sortedDurations)), [sortedDurations])
        actionsApplied=0;
        S=Sinit
        for t in idxTimesteps
            timestepT=(hour-1)+sortedDurations[t]
            for act = actionsApplied+1:t
                actionToApply=policyWithDurations[act][1]
                Snew=applyAction(S, actionToApply)
                S=Snew
            end
            policyRewardAtTimestep = sum(S[S.<0])
            push!(intermediateRewards,tuple(timestepT,policyRewardAtTimestep))
            actionsApplied=t
        end
    end
    return intermediateRewards
end

function findTimeForAction(action::Action2, sizeOfGrid::Int64)
    factor= dist((1,1),(sizeOfGrid,sizeOfGrid))
    return (dist(action.stateToMoveFrom,action.stateToMoveTo)/factor)
end

function getC(crime_data::Matrix,grid_size) ### GETS CRIME MATRIX
    matrix4=crime_data
    n,m = size(matrix4)
    C = zeros(grid_size,grid_size,24)
    for i = 1:n
        lat = matrix4[i,3]
        long = matrix4[i,4]
        hour = matrix4[i,1]+1
        C[lat,long,hour] += 1
    end
    total_hourly_crime = zeros(24)
    for h = 1:24
        total_hourly_crime[h] = sum(C[:,:,h])
    end
    for latitude = 1:grid_size
        for longitude = 1:grid_size
            for h = 1:24
                if C[latitude,longitude,h] != 0
                    C[latitude,longitude,h] = C[latitude,longitude,h]/total_hourly_crime[h]
                end
            end
        end
    end
    return C
end

function getCWeighted(crime_data::Matrix,grid_size) ### GETS CRIME MATRIX
    matrix4=crime_data;
    n,m = size(matrix4)
    C = zeros(grid_size,grid_size,24)
    for i = 1:n
        lat = matrix4[i,3]
        long = matrix4[i,4]
        hour = matrix4[i,1]+1
        C[lat,long,hour] += matrix4[i,5]
    end
    total_hourly_crime = zeros(24)
    for h = 1:24
        total_hourly_crime[h] = sum(C[:,:,h])
    end
    for latitude = 1:grid_size
        for longitude = 1:grid_size
            for h = 1:24
                if C[latitude,longitude,h] != 0
                    C[latitude,longitude,h] = C[latitude,longitude,h]/total_hourly_crime[h]
                end
            end
        end
    end
    return C
end

function write_policy_eval(policyEvals::Vector{Tuple{Float64,Float64}}, filename)
    open(filename, "w") do io
        for i=1:length(policyEvals)
            @printf(io, "%f, %f\n", policyEvals[i][1], policyEvals[i][2])
        end
    end
end

### Unweighted crime data
# data=CSV.File("2018_Crime_Datafloortimelatlong_40x40.csv") |> DataFrame;
# crime_data=convert(Array,data)
# sizeOfGrid=40;
# CAllHours=getC(crime_data,sizeOfGrid)
# (lat,long,hr)=size(CAllHours)
# PInit=zeros(lat,long)
# fill!(PInit,1/(lat*long))
# hour=1;
# threshold = -0.001
# wtParam = 1
# (policylist,Plist)=main(hour,PInit,CAllHours[:,:,hour],threshold, wtParam)
# (policylist,Plist)=findHourlyPolicy(PInit,CAllHours,threshold, wtParam)
# for h=1:24
#     hourlyP=Plist[h];
#     name=string("PMatrixHour",h,".csv");
#     CSV.write(name,DataFrame(hourlyP))
# end

data_wt=CSV.File("2018_Crime_Data(floortime,lat,long_40x40)_weighted.csv") |> DataFrame;
crime_data_wt=convert(Array,data_wt)
sizeOfGrid=40;
CAllHoursWeighted=getCWeighted(crime_data_wt,sizeOfGrid)
(lat,long,hr)=size(CAllHoursWeighted)
PInit=zeros(lat,long)
fill!(PInit,1/(lat*long))
hour=1;

threshold = -0.001
(policylist,Plist)=findHourlyPolicy(PInit,CAllHoursWeighted,threshold)
### Required to publish P matrices
for h=1:24
    hourlyP=Plist[h];
    name=string("PMatrixWeighted0.001Hour",h,".csv");
    CSV.write(name,DataFrame(hourlyP))
end
intermediateRewards= evaluatePolicy(policylist,sizeOfGrid,Plist,CAllHoursWeighted)
write_policy_eval(intermediateRewards,"policyEvaluationForWeightedCrime0.001.txt")


threshold = -0.01
(policylist,Plist)=findHourlyPolicy(PInit,CAllHoursWeighted,threshold)
### Required to publish P matrices
for h=1:24
    hourlyP=Plist[h];
    name=string("PMatrixWeighted0.01Hour",h,".csv");
    CSV.write(name,DataFrame(hourlyP))
end
intermediateRewards= evaluatePolicy(policylist,sizeOfGrid,Plist,CAllHoursWeighted)
write_policy_eval(intermediateRewards,"policyEvaluationForWeightedCrime0.01.txt")


threshold = -0.1
(policylist,Plist)=findHourlyPolicy(PInit,CAllHoursWeighted,threshold)
### Required to publish P matrices
for h=1:24
    hourlyP=Plist[h];
    name=string("PMatrixWeighted0.1Hour",h,".csv");
    CSV.write(name,DataFrame(hourlyP))
end
intermediateRewards= evaluatePolicy(policylist,sizeOfGrid,Plist,CAllHoursWeighted)
write_policy_eval(intermediateRewards,"policyEvaluationForWeightedCrime0.1.txt")

threshold = -0.005
(policylist,Plist)=findHourlyPolicy(PInit,CAllHoursWeighted,threshold)
### Required to publish P matrices
for h=1:24
    hourlyP=Plist[h];
    name=string("PMatrixWeighted0.005Hour",h,".csv");
    CSV.write(name,DataFrame(hourlyP))
end
intermediateRewards= evaluatePolicy(policylist,sizeOfGrid,Plist,CAllHoursWeighted)
write_policy_eval(intermediateRewards,"policyEvaluationForWeightedCrime0.005.txt")

### Attempting to plot but not successfully
# gr()
# timesteps=[ir[1] for ir in intermediateRewards]
# rwds=[ir[2] for ir in intermediateRewards]
# plot([1],[1])
# for hr=1:24
#     idxs=(timesteps.<hr) .& (timesteps.>=hr-1)
#     gr()
#     plot!(timesteps[idxs], rwds[idxs])
# end
# yvalues=collect(-0.680:0.01:-0.575)
# xvalues=ones(length(yvalues),1)
# plot!(xvalues,yvalues)
