import headers/turbojpeg_header
import shared_handler


proc jpeg2i420*(jpeg_buffer: pointer, jpeg_size: uint, i420_buffer: var ptr UncheckedArray[uint8], i420_size: var uint, width, height: var int): bool =
  # yuv_buffer will be assigned and resized automaticly: yuv_buffer <-> yuv_size
  var 
    subsample: TJSAMP
    colorspace: TJCS
    flags = 0
    padding = 1               # 1 or 4 can be, but is not 0

  if decompressor == nil: decompressor = tjInitDecompress()
  if compressor == nil: compressor = tjInitCompress()

  if not tjDecompressHeader3(decompressor, jpeg_buffer, jpeg_size, width, height, subsample, colorspace):
    echo tjGetErrorStr2(decompressor)
    return false
 
  var buffSize = (width * height * 3).uint
  if buffer.buffer_size != buffSize:
    buffer.buffer_size = buffSize
    if buffer.buffer_size_max < buffSize:
      buffer.buffer_size_max = buffSize
      if buffer.buffer == nil:
        buffer.buffer = cast[ptr UncheckedArray[uint8]](alloc(buffer.buffer_size_max))
      else:
        buffer.buffer = cast[ptr UncheckedArray[uint8]](realloc(buffer.buffer, buffer.buffer_size_max))
      if buffer.buffer == nil:
        echo("alloc buffer failed.\n")
        return false

  var std_i420_size = (width * height * 3 div 2).uint
  if i420_size != std_i420_size:  # 12 bits per pixel
    i420_size = std_i420_size
    if i420_buffer == nil:
      i420_buffer = cast[ptr UncheckedArray[uint8]](alloc(i420_size))
    else:
      i420_buffer = cast[ptr UncheckedArray[uint8]](realloc(i420_buffer, i420_size))

  if not tjDecompress2(decompressor, jpeg_buffer, jpeg_size, buffer.buffer, width, height, TJPF_RGB, flags, 0):
    echo tjGetErrorStr2(decompressor)
    return false

  if tjEncodeYUV3(compressor, buffer.buffer, width, pitch = 0, height, TJPF_RGB, i420_buffer, padding, TJSAMP_420, flags) != 0:
    echo tjGetErrorStr2(compressor)
    return false
  return true


proc jpeg2i420*(jpeg_buffer: string, i420_buffer: var ptr UncheckedArray[uint8], i420_size: var uint, width, height: var int): bool =
  result = jpeg2i420(jpeg_buffer[0].unsafeAddr, jpeg_buffer.len.uint, i420_buffer, i420_size, width, height)


proc jpegFile2i420*(filename: string, i420_buffer: var ptr UncheckedArray[uint8], i420_size: var uint, width, height: var int): bool =
  var fileContent = readFile(filename)
  result = jpeg2i420(fileContent[0].unsafeAddr, fileContent.len.uint, i420_buffer, i420_size, width, height)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc i4202jpeg*(i420_buffer: var pointer, width, height: int, jpegBuf: var ptr UncheckedArray[uint8], jpegSize: var uint, jpegQual: TJQuality = 80): bool =
  if compressor == nil: compressor = tjInitCompress()
  result = tjCompressFromYUVPlanes(compressor, i420_buffer, width, strides = nil, height, TJSAMP_420, jpegBuf, jpegSize, jpegQual, 0) 
  if not result:
    echo tjGetErrorStr2(compressor)


proc i4202jpegFile*(i420_buffer: var pointer, width, height: int, filename: string, jpegQual: TJQuality = 80): bool =
  var 
    jpegBuf: ptr UncheckedArray[uint8]
    jpegSize: uint
  if i4202jpeg(i420_buffer, width, height, jpegBuf, jpegSize, jpegQual):
    var file = open(filename, fmWrite)
    if file != nil:
      discard file.writeBuffer(jpegBuf, jpegSize.int)
      file.close()
      return false
    else:
      return false