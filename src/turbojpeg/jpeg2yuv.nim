import headers/turbojpeg_header
import shared_handler

proc jpeg2yuv*(jpeg_buffer: pointer, jpeg_size: uint, yuv_buffer: var ptr UncheckedArray[uint8], yuv_size: var uint, yuv_sample: var TJSAMP, flags = 0): bool =
  # yuv_buffer will be assigned and resized automaticly: yuv_buffer <-> yuv_size
  var 
    width, height: int
    subsample: TJSAMP
    colorspace: TJCS
    padding = 1               # 1 or 4 can be, but is not 0

  if decompressor == nil: decompressor = tjInitDecompress()

  if not tjDecompressHeader3(decompressor, jpeg_buffer, jpeg_size, width, height, subsample, colorspace):
    echo tjGetErrorStr2(decompressor)
    return false

  yuv_sample = subsample;
  # Note: After testing, the designated sampling yuv YUV format only affects the buffer size, in fact or by itself JPEG YUV format conversion
  var buffSize = tjBufSizeYUV2(width, padding, height, subsample);
  if yuv_size != buffSize:
    yuv_size = buffSize
    if yuv_buffer == nil:
      yuv_buffer = cast[ptr UncheckedArray[uint8]](alloc(yuv_size))
    else:
      yuv_buffer = cast[ptr UncheckedArray[uint8]](realloc(yuv_buffer, yuv_size))
    if yuv_buffer == nil:
      echo("alloc buffer failed.\n")
      return false

  if tjDecompressToYUV2(decompressor, jpeg_buffer, jpeg_size, yuv_buffer, width, padding, height, flags) != 0:
    echo tjGetErrorStr2(decompressor)
    return false
  return true

proc jpeg2yuv*(jpeg_buffer: string, yuv_buffer: var ptr UncheckedArray[uint8], yuv_size: var uint, yuv_sample: var TJSAMP, flags = 0): bool {.inline.} =
  # yuv_buffer will be assigned and resized automaticly: yuv_buffer <-> yuv_size
  result = jpeg2yuv(jpeg_buffer[0].unsafeAddr, jpeg_buffer.len.uint, yuv_buffer, yuv_size, yuv_sample, flags)
 

proc yuv2jpeg*(yuv_buffer: pointer | ptr UncheckedArray[uint8], width, height: int, subsample: TJSAMP, 
                jpeg_buffer: var ptr UncheckedArray[uint8], jpeg_size: var uint, quality: TJQuality, flags = 0): bool =
  var 
    padding = 1 # 1 or 4 can be, but is not 0
 
  if compressor == nil: compressor = tjInitCompress()


  var maxJSize = tjBufSize()
  if maxJSize != jpeg_size:
    if jpeg_buffer == nil:
      jpeg_buffer = cast[ptr UncheckedArray[uint8]](alloc(jpeg_size))
    elif jpeg_size < maxJSize:
      jpeg_buffer = cast[ptr UncheckedArray[uint8]](realloc(jpeg_buffer, jpeg_size))
    jpeg_size = maxJSize

  if tjCompressFromYUV(compressor, yuv_buffer, width, padding, height, subsample, jpeg_buffer, jpeg_size, quality, flags) != 0:
    echo tjGetErrorStr2(compressor)
    return false
  return true

proc yuv2jpegFile*(yuv_buffer: pointer | ptr UncheckedArray[uint8], width, height: int, subsample: TJSAMP, filename: string, jpegQual: TJQuality = 80, flags = 0): bool =
  var 
    jpegBuf: ptr UncheckedArray[uint8]
    jpegSize: uint
  if yuv2jpeg(yuv_buffer, width, height, subsample, jpegBuf, jpegSize, jpegQual, flags):
    var file = open(filename, fmWrite)
    if file != nil:
      discard file.writeBuffer(jpegBuf, jpegSize.int)
      file.close()
      return false
    else:
      return false

