Repo for Gil Goldshlager's Final Project in MIT 6.338, Parallel Computing with Julia

Contains code to run a Move-to-front encoder and decoder, and a Huffman encoder and decoder.  

The original goal was to create a full Burrows-Wheeler type compression and decompression algorithm, but the BWT itself turned out to be too much for a course project.

Type julia -p k -L BWT.jl Demos.jl N to run a demo of all of the algorithms on k processors and a randomly generated string of length N. 
