using Pkg, DataFrames, CSV, Printf,DataStructures

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
weight = 1
reward = 0;
reward -= dist(s, s0)*action.numPoliceOfficersToMove
Snew=applyAction(S, action)
reward += weight*sum(Snew[Snew.<0])
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


function main(hour,P,C)
S = P-C;
num = 5
threshold = -0.01
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

function findHourlyPolicy(PAllHours,CAllHours)
    policylist = Vector{Vector{Action2}}(undef,0)
    Plist=Vector{Array{Float64,2}}(undef,0);
    P=PAllHours[:,:,1]
    push!(Plist,P)
    for hour = 1:24
        C=CAllHours[:,:,hour];
        (actionlist, Pnew) = main(hour,P,C)
        push!(policylist,actionlist)
        push!(Plist,Pnew)
        P=Pnew
    end
    return policylist,Plist
end

# hour=1;
# P=rand(5,5,24);
# C=rand(5,5,24);
# main(hour,P,C)

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

data=CSV.File("2018_Crime_Datafloortimelatlong_40x40.csv") |> DataFrame;
crime_data=convert(Array,data)
CAllHours=getC(crime_data,40)
(lat,long,hr)=size(CAllHours)
PAllHours=zeros(lat,long,hr)
fill!(PAllHours,1/(lat*long))
hour=1;
(policylist,Plist)=main(hour,PAllHours[:,:,hour],CAllHours[:,:,hour])
(policylist,Plist)=findHourlyPolicy(PAllHours,CAllHours)
for h=1:24
    hourlyP=Plist[h];
    name=string("PMatrixHour",h,".csv");
    CSV.write(name,DataFrame(hourlyP))
end
