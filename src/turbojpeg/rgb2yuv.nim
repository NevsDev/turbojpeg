import headers/turbojpeg_header
import shared_handler


proc rgb2yuv*(rgb_buffer: pointer, width, height: int, yuv_buffer: var ptr UncheckedArray[uint8], yuv_size: var uint, subsample: TJSAMP, flags = 0): bool =
  # yuv_buffer will be assigned and or resized automaticly: yuv_buffer <-> yuv_size
  var
    padding = 1 # 1 or 4 can be, but is not 0
    pixelfmt = TJPF_RGB
 
  if compressor == nil: compressor = tjInitCompress()
   
  var buffSize = tjBufSizeYUV2(width, padding, height, subsample)

  if ((flags and TJFLAG_NOREALLOC) != TJFLAG_NOREALLOC) and yuv_size != buffSize:
    yuv_buffer = cast[ptr UncheckedArray[uint8]](realloc(yuv_buffer, buffSize))
    if yuv_buffer == nil:
      echo("alloc buffer failed.\n")
      return false
  yuv_size = buffSize

  if tjEncodeYUV3(compressor, rgb_buffer, width, 0, height, pixelfmt, yuv_buffer, padding, subsample, flags) != 0:
    echo tjGetErrorStr2(compressor)
    return false
  return true
