import headers/turbojpeg_header

var compressor: tjhandle


proc trgb2yuv*(rgb_buffer: pointer, width, height: int, yuv_buffer: ptr ptr UncheckedArray[uint8], yuv_size: var uint, subsample: TJSAMP): bool =
  # Warning: single threaded converter 
  # yuv_buffer will be assigned and or resized automaticly: yuv_buffer <-> yuv_size
  var
    flags = 0
    padding = 1 # 1 or 4 can be, but is not 0
    pixelfmt = TJPF_RGB
 
  if compressor == nil: compressor = tjInitCompress()
   
  var buffSize = tjBufSizeYUV2(width, padding, height, subsample)

  if yuv_size != buffSize:
    yuv_size = buffSize
    if yuv_buffer[] == nil:
      yuv_buffer[] = cast[ptr UncheckedArray[uint8]](alloc(yuv_size))
    else:
      yuv_buffer[] = cast[ptr UncheckedArray[uint8]](realloc(yuv_buffer[], yuv_size))
    if yuv_buffer[] == nil:
      echo("alloc buffer failed.\n")
      return false

  result = tjEncodeYUV3(compressor, rgb_buffer, width, 0, height, pixelfmt, yuv_buffer, padding, subsample, flags) == 0

