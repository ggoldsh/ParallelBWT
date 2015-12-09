@everywhere using BWT

#Generate random string of length n, and fully encode and decode it in serial
function full_serial_demo(n)
  println("Full serial demo, ", n, " character input, ", length(getAlphabet()), " character alphabet.")

  tic()

  @time input = [randomChar() for i in 1:n]
  println("Init complete") 

  @time ME = MTF_encode_serial(input)
  println("MTF encode complete")
  input = 0
  gc()

  @time codes, HE = Huffman_encode_serial(ME)
  println("Huffman encode complete. Encoding is ", length(HE), " bits.")
  ME = 0
  gc()

  @time HD = Huffman_decode_serial(codes, HE)
  println("Huffman decode complete.")
  HE = 0
  gc()

  @time MD = MTF_decode_serial(HD)
  println("MTF decode complete.")
  HD = 0
  MD = 0
  gc()
  
  time = toc()
  println("Completed serial demo for size ", n , "  on ", length(workers()), " processors.")
end 

#Generate random string of length n, and fully encode and decode it in parallel
function full_parallel_demo(n)
  println("Full parallel demo, ", n, " character input, ", length(getAlphabet()), " character alphabet.")
  println("Using ", length(workers()), " processors. ")

  tic()
    @time begin
      S = initializeParallel(n,Char,randomChar)
    end 
    println("Init complete")

    @time ME = MTF_encode_parallel(S)
    println("MTF encode complete.")
    S = 0
    gc()

    @time codes, HE = Huffman_encode_parallel(ME)
    println("Huffman encode complete. Encoding is ", length(HE), " bits.")
    ME = 0
    gc()

    @time HD = Huffman_decode_parallel(codes, HE)
    println("Huffman decode complete")
    HE = 0
    gc()

    @time MD = MTF_decode_parallel(HD)
    println("MTF decode complete.")
    HD = 0
    MD = 0
    gc()

    time = toc()
    println("Completed parallel demo for size ", n , "  on ", length(workers()), " processors.")
end 

#Run demos of algorithm in parallel and serial:
sizeInput = parse(Int,ARGS[1])
full_parallel_demo(sizeInput)
full_serial_demo(sizeInput)
