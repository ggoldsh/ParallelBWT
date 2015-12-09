export MTF_decode_serial, MTF_decode_parallel

#Composes two permutations
function decode_contractor(x,y)
	[x[y[i]] for i in 1:length(x)]
end

#Moves character in position a to front and returns character
function moveToFront(L,a::Int)
	c = L[a]
	for i in a:-1:2
		L[i] = L[i-1]
	end
	L[1] = c
	c
end

#Serial MTF decode algorithm
function MTF_decode_serial(encoded)
	L = copy(alphabet)
	n = length(encoded)
	result = Array(Char, n)
	for i in 1:n
		result[i] = moveToFront(L, encoded[i]+1) #+1 because 0 index
	end
	result
end

#Decoder for local portion of array
function MTF_decode_localF(S)
	L = copy(identity)
	for i in myMinIndex(S):myMaxIndex(S)
		moveToFront(L, S[i]+1)  #+1 because 0 index
	end
	L
end

#Accumulator for results of all processor computations
#Uses contractor
function MTF_decode_accum(A)
	results = []
	push!(results, copy(identity))
	for i in 1:length(A)-1
		push!(results, decode_contractor(results[i], A[i]))
	end
	results
end

#Takes in starting permutation from MTF_accum, calculates final encoding over local portion
function MTF_decode_localAccum(S, P, T)
	L = [alphabet[P[j]] for j in 1:length(alphabet)]
	for i in myMinIndex(S):myMaxIndex(S)
		T[i] = moveToFront(L, S[i]+1)  #+1 because 0 index
	end
end

#Full MTF decoding algorithm
function MTF_decode_parallel(S)
	T = initializeParallel(length(S),Char,()->'A')
	star(MTF_decode_localF, MTF_decode_accum, MTF_decode_localAccum, S, T)
	T
end