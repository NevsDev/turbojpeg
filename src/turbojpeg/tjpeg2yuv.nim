import strformat
import headers/turbojpeg_header

var decompressor {.threadvar.}: tjhandle
var compressor {.threadvar.}: tjhandle

proc tjpeg2yuv*(jpeg_buffer: pointer, jpeg_size: uint, yuv_buffer: ptr ptr UncheckedArray[uint8], yuv_size: var uint, yuv_sample: var TJSAMP): bool =
  # yuv_buffer will be assigned and resized automaticly: yuv_buffer <-> yuv_size
  var 
    width, height: int
    subsample: TJSAMP
    colorspace: TJCS
    flags = TJFLAG_FORCESSE3
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
    if yuv_buffer[] == nil:
      yuv_buffer[] = cast[ptr UncheckedArray[uint8]](alloc(yuv_size))
    else:
      yuv_buffer[] = cast[ptr UncheckedArray[uint8]](realloc(yuv_buffer[], yuv_size))
    if yuv_buffer[] == nil:
      echo("alloc buffer failed.\n")
      return false

  if tjDecompressToYUV2(decompressor, jpeg_buffer, jpeg_size, yuv_buffer, width, padding, height, flags) != 0:
    echo tjGetErrorStr2(decompressor)
    return false
  return true

proc tjpeg2yuv*(jpeg_buffer: string, yuv_buffer: ptr ptr UncheckedArray[uint8], yuv_size: var uint, yuv_sample: var TJSAMP): bool {.inline.} =
  # yuv_buffer will be assigned and resized automaticly: yuv_buffer <-> yuv_size
  result = tjpeg2yuv(jpeg_buffer[0].unsafeAddr, jpeg_buffer.len.uint, yuv_buffer, yuv_size, yuv_sample)
 

proc tyuv2jpeg*(yuv_buffer: pointer | ptr UncheckedArray[uint8], yuv_size: uint, width, height: int, subsample: TJSAMP, 
                jpeg_buffer: ptr ptr UncheckedArray[uint8], jpeg_size: var uint, quality: TJQuality): bool =
  var 
    flags = 0
    padding = 1 # 1 or 4 can be, but is not 0
 
  if compressor == nil: compressor = tjInitCompress()

  var need_size = tjBufSizeYUV2(width, padding, height, subsample);
  if need_size != yuv_size:
    echo &"we detect yuv size: {need_size}, but you give: {yuv_size}, check again."
    return false
 
  if tjCompressFromYUV(compressor, yuv_buffer, width, padding, height, subsample, jpeg_buffer, jpeg_size, quality, flags) != 0:
    echo tjGetErrorStr2(compressor)
    return false
  return true