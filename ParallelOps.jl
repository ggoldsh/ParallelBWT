
export star, fanin, fanout, initializeParallel, myMinIndex, myMaxIndex

#Initializes array with values outputted by f()
function initializeParallel(n, Type, f)
  S = SharedArray(Type, (n), init = S -> S[myIndices(S)] = f())
end

#These are used for splitting array into local portions
function myMinIndex(S::SharedArray)
  (Int64)(floor((indexpids(S)-1)*length(S)/length(procs(S))) + 1)
end

function myMinIndex(S::Array)
  1
end

function myMaxIndex(S::Array)
  length(S)
end

function myMaxIndex(S::SharedArray)
  (Int64)(floor(indexpids(S)*length(S)/length(procs(S))))
end

function myIndices(S::SharedArray)
  #println("Calling shared array version of myindices")
   return myMinIndex(S):myMaxIndex(S)
end

# f1 takes S, and seed, and is run locally on each processor to 
#     produce single output.  May also mutate S
# S is input array
function fanin(seed, f1, S)
  @sync begin
    results = Array(Any,length(procs(S)))
    for p in eachindex(procs(S))
      @async begin
        results[p] = remotecall_fetch(procs(S)[p],f1, seed[p], S)
      end
    end
  end

  results
end 

 
# f1 takes S, is run locally on each processor to 
#     produce single output.  May also mutate S
# S is input array
function fanin(f1, S)
  @sync begin
    results = Array(Any,length(procs(S)))
    for p in eachindex(procs(S))
      @async begin
        results[p] = remotecall_fetch(procs(S)[p],f1,S)
      end
    end
  end

  results
end 

# Seed is array with one seed per processor
# f1 takes the seed and runs on the local portion of the array
# S input array
# T output array 
# Can supply same array to get "in place" operation
function fanout(seed, f1, S, T)
  @sync begin 
    for p in 1:length(procs(S))
      @async begin
        remotecall_fetch(procs(S)[p],f1, S, seed[p], T)
      end
    end
  end
end 

# Inputs: 
# f1 takes (S), is run on each processor to produce single output.  May also mutate array
# f2 takes (array) of outputs from f1, produces another array
# f3 takes (S,val,T) is run on S from each processor with val from f2, puts results in T
# S input array
# T output array- needs to be different because might need different type 
# Can supply same array if distinction not needed
function star(f1, f2, f3, S,T)
  fanout(f2(fanin(f1, S)), f3, S, T)
end







