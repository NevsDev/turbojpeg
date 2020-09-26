import strformat
import headers/turbojpeg_header

var decompressor: tjhandle
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


proc tyuv2rgb*(yuv_buffer: pointer, yuv_size: uint, width, height: int, subsample: TJSAMP, rgb_buffer: ptr ptr UncheckedArray[uint8], rgb_size: var uint): bool =
  # Warning: single threaded converter 
  # rgb_buffer will be assigned and or resized automaticly: rgb_buffer <-> rgb_size
  var
    flags = 0
    padding = 1  # 1 or 4 can be, but is not 0
    pixelfmt = TJPF_RGB
 
  if decompressor == nil: decompressor = tjInitDecompress()
 
  var need_size = tjBufSizeYUV2(width, padding, height, subsample)
  if need_size != yuv_size:
    echo &"we detect yuv size: {need_size}, but you give: {yuv_size}, check again."
    return false
  
  var rgbSize = width * height * tjPixelSize[pixelfmt.int]
  if rgb_size != rgbSize:
    rgb_size = rgbSize
    if rgb_buffer[] == nil:
      rgb_buffer[] = cast[ptr UncheckedArray[uint8]](alloc(rgb_size))
    else:
      rgb_buffer[] = cast[ptr UncheckedArray[uint8]](realloc(rgb_buffer[], rgb_size))
    if rgb_buffer[] == nil:
      echo("alloc buffer failed.\n")
      return false

  result = tjDecodeYUV(decompressor, yuv_buffer, padding, subsample, rgb_buffer, width, 0, height, pixelfmt, flags) == 0
#     if (ret < 0)
#     {
#         printf("decode to rgb failed: %s\n", tjGetErrorStr());
#     }
 
 
#     return ret;
