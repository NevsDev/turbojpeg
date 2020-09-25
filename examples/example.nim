import turbojpeg

var
  width, height: int32
  jpegSubsamp: TJSAMP
  colorSpace: TJCS
  jpegRaw = readFile("examples/example.jpg")
  success: bool

# ~~~~~~~~~~~~~~~~~~~~~~ DECOMPRESS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
# Init Handler
var handle = tjInitDecompress()

# Decompress Header
# with pointer to raw data and the size of data 
success = tjDecompressHeader3(handle, jpegRaw[0].addr, jpegRaw.len, width, height, jpegSubsamp, colorSpace)    
# or direct with string or seq[char|uint8] data
success = tjDecompressHeader3(handle, jpegRaw, width, height, jpegSubsamp, colorSpace)    

echo "Size: ", width, "x", height, "  Subsample: ", jpegSubsamp, "  ColorSpace: ", colorSpace

# Decompress Data to RGB and Fast
var outBuffer = newString(width * height * 3) # outBuffer can also be pointer or seq[char|uint8]
success = tjDecompress2(handle, jpegRaw, outBuffer, width, height, TJPF_RGB, TJFLAG_FASTDCT, pitch = 0)

# free handle
tjDestroy(handle)

# ~~~~~~~~~~~~~~~~~~~~~~ COMPRESS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
var 
  rawRGBbuffer = outBuffer
  outputJPGbuffer: ptr UncheckedArray[byte]
  jpegSize: uint
# Init Handler
var compHandle = tjInitCompress()

success = tjCompress2(compHandle, rawRGBbuffer, width, height, pixelFormat = TJPF_RGB, 
                outputJPGbuffer.addr, jpegSize, jpegSubsamp = TJSAMP_444, jpegQual = 80, flags = 0, pitch = 0)
# or compress direct to string
var rawImage: string = tjCompress2(compHandle, rawRGBbuffer, width, height, pixelFormat = TJPF_RGB, 
                                    jpegSubsamp = TJSAMP_444, jpegQual = 80, flags = 0, pitch = 0)

# write File to storage
var file = open("compressed_img.jpeg", fmWrite)
assert(file.writeBuffer(outputJPGbuffer[0].addr, jpegSize) == jpegSize.int)
file.close()

writeFile("compress_direct_img.jpeg", rawImage)

# free handle
tjDestroy(compHandle)