export Huffman_encode_serial, Huffman_encode_parallel

function encode_helper(sequence, seqStart, seqEnd,  result, resultStart, codes)
	pos = resultStart
	for i in seqStart:seqEnd
		codeIndex = sequence[i]+1
		len = length(codes[codeIndex])
		for j in 1:len
			result[pos+j-1] = codes[codeIndex][j]
		end 
		pos+= len
	end 
end 

function serial_encode(sequence, codes)
	totalLength = sum([length(codes[i+1]) for i in sequence])
	result = Array(Bool, totalLength)

	encode_helper(sequence, 1, length(sequence), result, 1, codes)

	result
end

function local_encode(S, seed, T)
	startPos, codes = seed
	encode_helper(S, myMinIndex(S), myMaxIndex(S), T, startPos, codes)
end 

function getCounts(sequence, startPoint , endPoint)
	counts = [0 for i in alphabet]
	for i in startPoint:endPoint
		counts[sequence[i]+1] += 1
	end
	counts
end 

function local_getCounts(S)
	getCounts(S, myMinIndex(S), myMaxIndex(S))
end 

function getCounts(sequence)
	getCounts(sequence, 1, length(sequence))
end 

function getCodes(counts)
	codes = [[] for i in alphabet]
	sets = [[i-1] for i in 1:length(alphabet)]
	heap = Collections.PriorityQueue(Array, Int)
	for i in sets
		Collections.enqueue!(heap,i,counts[i[1]+1])
	end

	while length(heap) > 1
		a = Collections.dequeue!(heap)
		b = Collections.dequeue!(heap)
		for i in a
			prepend!(codes[i+1], [false])
		end 
		for i in b
			prepend!(codes[i+1], [true])
		end
		c = [a;b]
		Collections.enqueue!(heap, c, length(c))
	end 

	codes
end 

function Huffman_encode_serial(s)
	counts = getCounts(s)

	codes = getCodes(counts)
	
	codes, serial_encode(s, codes)
end

#adds counts1 to counts 2
function addCounts(counts1, counts2)
	for i in eachindex(counts1)
		counts2[i] += counts1[i]
	end
end

function cumCounts(countLists)
	for i in 2:length(countLists)
		addCounts(countLists[i-1], countLists[i])
	end 
	countLists
end 

function get_encoding_length(codes, previousCounts)
	result = 0
	for i in 1:length(alphabet)
		result += length(codes[i]) * previousCounts[i]
	end 
	result
end 

function Huffman_encode_parallel(S)
	seedCounts = cumCounts(fanin(local_getCounts,S))
	
	totalCounts = seedCounts[length(seedCounts)]
	codes = getCodes(totalCounts)

    T = initializeParallel(get_encoding_length(codes, totalCounts), Bool, ()->false)
	
	for i in length(seedCounts):-1:2
		seedCounts[i] = seedCounts[i-1]
	end 
	seedCounts[1] = [0 for i in alphabet]

	seedPositions = [get_encoding_length(codes, seedCounts[i])+1 for i in 1:length(seedCounts)] 

	seed = [(seedPositions[i], codes) for i in 1:length(seedCounts)]
	
	fanout(seed, local_encode, S, T)

	codes, T
end 