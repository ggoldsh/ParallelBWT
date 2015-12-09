export MTF_encode_serial, MTF_encode_parallel

# to run the encoding, use ParallelOps and call star(MTF_encode_localF, MTF_encode_accum, MTF_encode_localAccum, S, T)

#finds character c, moves it to front
#returns position of character in array
function moveToFront(L, c::Char)
	a = findfirst(L,c)
	for i in a:-1:2
		L[i] = L[i-1]
	end
	L[1] = c
	a
end

#MTF serial encoder
function MTF_encode_serial(input)
	L = copy(alphabet)
	n = length(input)
	result = Array(Int, n)
	for i = 1:n
		result[i] = moveToFront(L, input[i])-1 #-1 to 0 index
	end	
	result
end

#Gets a function which returns true for elements not in b
function getFilter(b)
	f(x) = !(x in b)
end

#Next four functions contract any combination of char arrays and single chars
function encode_contractor(x::Char,y::Array)
	x = [x]
	[y; filter(getFilter(y), x)]
end

function encode_contractor(x::Array,y::Char)
	y = [y]
	[y; filter(getFilter(y), x)]
end

function encode_contractor(x::Char,y::Char)
	x,y = [x],[y]
	[y; filter(getFilter(y), x)]
end

function encode_contractor(x::Array,y::Array)
	[y; filter(getFilter(y), x)]
end

#Run on a local portion of array- calculates final L_i vector starting from identity
#Identity is empty string
function MTF_encode_localF(S)
	n = length(S)
	result = [S[myMinIndex(S)]]
	for i in myMinIndex(S)+1:myMaxIndex(S)
		if (S[i] in result) #don't allocate new memory if I don't have to
			moveToFront(result, S[i])
		else
			result = encode_contractor(result, S[i])
		end
	end
	result
end

#Accumulates results of all MTF local encoding using contractor
function MTF_encode_accum(A)
	results = []
	push!(results, copy(alphabet))
	for i in 1:length(A)-1
		push!(results, encode_contractor(results[i], A[i]))
	end
	results
end

#Used for fanout stage of encoding
#Takes in value from MTF_encode_accum, calculates final encoding everywhere
function MTF_encode_localOut(S, L, T)
	for i in myMinIndex(S):myMaxIndex(S)
		T[i] = moveToFront(L, S[i])-1
	end
end

function MTF_encode_parallel(S)
  	T = initializeParallel(length(S),Int, ()->0)
	star(MTF_encode_localF, MTF_encode_accum, MTF_encode_localOut, S, T)
	T
end 