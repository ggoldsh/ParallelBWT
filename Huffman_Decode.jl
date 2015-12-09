export Huffman_decode_serial, Huffman_decode_parallel

#Decode array used for quickly mapping bit strings to decoding characters
#Bit strings are interpretted as binary numbers with an added leading 1, 
#and decodings are stored at the corresponding index of the decoding array
function get_decode_array(codes)
	intCodes = [1 for i in codes]
	for i in eachindex(codes)
		for a in codes[i]
			intCodes[i] = 2*intCodes[i]
			if a
				intCodes[i] += 1
			end 
		end
	end 
	 
	maxCode, _= findmax(intCodes)

	decodeArray = [-1  for i in 1:maxCode+1]

	for i in eachindex(codes)
		decodeArray[intCodes[i]+1] = i-1
	end 

	decodeArray
end

#Traverse array to decode
function Huffman_decode_serial(codes, H)
	decodeArray = get_decode_array(codes)

	result = []

	code = 1
	for pos in 1:length(H)
		code = 2*code
		if H[pos]
			code += 1
		end 
		if decodeArray[code+1] != -1
			push!(result, decodeArray[code+1])
			code = 1
		end 
	end 

	result
end

#Return length of maximum code from codes table
function getMaxCodeLength(codes)
	maxLength = 0
	for i in codes
		maxLength = max(maxLength, length(i))
	end 
	maxLength
end 

#Runs locally to get the minimal decoding pointer that starts at startPoint
#and ends at or after endPoint
function getPointerResult(S, startPoint, endPoint, decodeArray)
	codeLength = 0

	code = 1
	pos = startPoint
	while pos <= length(S)
		code = 2*code
		if S[pos]
			code += 1
		end 
		if decodeArray[code+1] != -1
			codeLength += 1
			code = 1
			if pos >= endPoint
				break
			end 
		end 
		pos += 1
	end 

	(startPoint, pos+1, codeLength)
end 

#Gets the next partition bin endpoint given current starts and jumpDist
#Need to be careful not to make it slightly before the end of the bucket,
#so that the pointers found don't point out of the bucket unless this is the last
#iteration.
function getNextEndpoint(startPoints, jumpDist, S)
	endPoint = min(myMaxIndex(S), startPoints[1] + jumpDist)
	if endPoint > myMaxIndex(S) - jumpDist
		endPoint = myMaxIndex(S)
	end 
	endPoint
end 

#Function for fanin stage
#Seeded with decodeArray and max code length
#Calculates all pointers from local portion to next local portion
#Avoids multiplicative maxLen factor of work by binning the local region and removing
#repeat pointers at the end of each bin
function getLocalPointers(seed, S)
	maxLen, decodeArray = seed[1],seed[2]

	originalStarts = [i for i in myMinIndex(S):myMinIndex(S)+maxLen-1]
	startPoints = copy(originalStarts)

	jumpDist = max(10000, (Int)(floor((myMaxIndex(S)-myMinIndex(S))/100))) #change to large number

	endPoint = getNextEndpoint(startPoints, jumpDist, S)
	pointersList = []
	printed = false
	while startPoints[1] < endPoint
		pointers = [getPointerResult(S, i, endPoint, decodeArray) for i in startPoints]
		pointerDict = [pointers[i][1] => (pointers[i][2], pointers[i][3]) for i in eachindex(startPoints)]

		push!(pointersList, pointerDict)

		startPoints = union([pointers[i][2] for i in 1:length(pointers)])

		endPoint = getNextEndpoint(startPoints, jumpDist, S)
	end

	pointerResults = [(originalStarts[i], originalStarts[i], 0) for i in eachindex(originalStarts)]
	for pointerDict in pointersList
		for j in eachindex(pointerResults)
			pointerResults[j] = (pointerResults[j][1],pointerDict[pointerResults[j][2]][1],pointerResults[j][3]+pointerDict[pointerResults[j][2]][2])
		end 
	end 

	pointerResults
end 

#Function for combining results from fanin into seed 
function getStarts(results)
	minPositions = [results[i][1][1] for i in eachindex(results)]

	starts = Array(Any, length(results)+1)
	starts[1] = (1,1)

	for i in 2:length(results)+1
		resultsIndex = starts[i-1][1]- minPositions[i-1] + 1
		nextStart = results[i-1][resultsIndex][2]
		nextLength = starts[i-1][2] + results[i-1][resultsIndex][3]
		starts[i] = (nextStart, nextLength)
	end 

	starts
end 

#Local decoder for fanout
#Takes seed in, decodes on specified portion using decodeArray
function local_decoder(S, seed, T)
	decodeArray = seed[1]
	startPoint = seed[2]
	endPoint = seed[3]
	outStart = seed[4]

	code = 1
	outPos = outStart
	for inPos in startPoint:endPoint-1
		code = 2*code
		if S[inPos]
			code += 1
		end 
		if decodeArray[code+1] != -1
			T[outPos] =  decodeArray[code+1]
			outPos += 1
			code = 1
		end 
	end 
end 

#Full decoding algorithm
function Huffman_decode_parallel(codes, S)
	decodeArray = get_decode_array(codes)

	maxLen = getMaxCodeLength(codes)

	f1 = getLocalPointers
	seed = [(maxLen, decodeArray) for i in procs(S)]
	results = fanin(seed, f1, S)

	starts= getStarts(results)

	resultLength = starts[length(starts)][2]-1

	T = initializeParallel(resultLength,Int, ()->-1)

	seed = [(decodeArray, starts[i][1], starts[i+1][1], starts[i][2]) for i in 1:length(starts)-1]

	fanout(seed, local_decoder, S, T)
	T
end 
