export randomChar, randomInt, getAlphabet, setAlphabet

include("ParallelOps.jl")
function getAlphabet()
	alphabet
end 

function setAlphabet(a)
	global alphabet = a
	global invAlph = Dict()
	for i in 1:length(alphabet)
		invAlph[alphabet[i]] = i
	end
end

setAlphabet(['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R', 'S','T', 'U','V','W','X','Y','Z'])

const identity = [i for i in 1:length(alphabet)]

function randomChar()
  alphabet[(Int)(ceil(rand() * length(alphabet)))]
end

function randomInt()
	return (Int)(floor(rand() * length(alphabet)))
end 