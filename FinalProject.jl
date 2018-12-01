using Pkg, DataFrames, CSV, Printf,DataStructures
Pkg.add("DataStructures")

function findNeediestStates(S,threshold)
size = size(S)
neediestStateInds = Int64[]
needyqueue = PriorityQueue{Tuple{::Int64}, Float64}(Base.Order.Reverse)
for (lat = 1 : size[1])
    for (long = 1:size[2])
        if (S[lat,long] < threshold)
            needyqueue.enqueue!(tuple(lat,long),S[lat,long])
        end
    end
end
return needyqueue

function findHighestSurplusStates(S,num)
neediestStateInds = Int64[]
S0 = deepcopy(S)
for (i = 1 : num)
    [max1, maxind] = max(S0);
    neediestStateInds[i] = maxind
    S0[maxind] = -Inf;
end
return neediestStateInds

function findClosestSurplusStates(S,num,needystate)
# numGrids = size[1]*size[2]
# neediestStateInds = Int64[]
# numfound = 0
# distance = 1
# while (numfound < num)
#     findnextclosest(needystate,distance)
#     distance += 1
return neediestStateInds

function dist(s, s0)
size = size(S)
[x, y] = ind2sub(size, s)
[x0, y0] = ind2sub(size, s0)
return abs(x-x0)+abs(y-y0)

function reward(S, action::Action)
# computes reward for a given grid state and action
s = action.stateToMoveFrom
s0 = action.stateToMoveTo
weight = 1
reward −= dist(s, s0)*action.numPoliceOfficersToMove
S0 = deepcopy(S)
applyAction(S0, action)
reward += weight*sum(S0 < 0)
return reward


function applyAction!(S, action::Action)
s = action.stateToMoveFrom
s0 = action.stateToMoveTo
S[s] = S[s] − action.numPoliceOfficersToMove
S[s0] = S[s0] + action.numPoliceOfficersToMove
end


struct Action
    stateToMoveFrom::Int64
    stateToMoveTo::Int64
    numPoliceOfficersToMove::Float64
end


function pickOptimalAction(S,needystate,highestqueue,closestqueue)
totallist = append!(highestqueue,closestqueue)
possibleactions = Vector{::Action}
rewards = Vector{::Float64}
for i = 1:length(totallist)
    cell = totallist[i]
    numPoliceOfficersToMove = min(S[needystate],S[cell])
    action = Action{cell,needystate,numPoliceOfficersToMove}
    rewards[i] = reward(S, action)
    possibleactions[i] = action
end
optimalactionind = argmax(rewards)
optimalaction = possibleactions[optimalactionind]
return optimalaction


function main(hour)
S = P[:,:,hour]-C[:,:,hour];
num = 5
threshold = -0.02
needyqueue = findNeediestStates(S,threshold);
actionlist = Vector{::Action}
while !isempty(needyqueue)
    needystate = needyqueue.peek;
    highestqueue = findHighestSurplusStates(S,num)
    closestqueue = findClosestSurplusStates(S,num)
    bestaction = pickOptimalAction(S,needystate,highestqueue,closestqueue)
    actionlist.append!(bestaction)
    applyAction!(S,bestaction)
    needyqueue = findNeediestStates(S,threshold);
end
return actionlist

function findHourlyPolicy()
    policylist = Vector{Vector{::Action}}
    for hour = 1:24
        actionlist = main(hour)
        policylist.append!(actionlist)
        # visualization
    end

end
