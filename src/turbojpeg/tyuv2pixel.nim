import strformat
import headers/turbojpeg_header

var decompressor {.threadvar.}: tjhandle


proc tyuv2pixel*(yuv_buffer: pointer, yuv_size: uint, width, height: int, subsample: TJSAMP, rgb_buffer: ptr ptr UncheckedArray[uint8], rgb_size: var uint, pixelfmt: TJPF): bool =
  # rgb_buffer will be assigned and or resized automaticly: rgb_buffer <-> rgb_size
  var
    flags = 0
    padding = 1  # 1 or 4 can be, but is not 0
 
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

  if tjDecodeYUV(decompressor, yuv_buffer, padding, subsample, rgb_buffer, width, 0, height, pixelfmt, flags) != 0:
    echo tjGetErrorStr2(decompressor)
    return false
  return true


proc tyuv2rgb*(yuv_buffer: pointer, yuv_size: uint, width, height: int, subsample: TJSAMP, rgb_buffer: ptr ptr UncheckedArray[uint8], rgb_size: var uint): bool {.inline.} =
  # Warning: single threaded converter 
  # rgb_buffer will be assigned and or resized automaticly: rgb_buffer <-> rgb_size
  result = tyuv2pixel(yuv_buffer, yuv_size, width, height, subsample, rgb_buffer, rgb_size, TJPF_RGB)

proc tyuv2rgbx*(yuv_buffer: pointer, yuv_size: uint, width, height: int, subsample: TJSAMP, rgb_buffer: ptr ptr UncheckedArray[uint8], rgb_size: var uint): bool {.inline.} =
  # Warning: single threaded converter 
  # rgb_buffer will be assigned and or resized automaticly: rgb_buffer <-> rgb_size
  result = tyuv2pixel(yuv_buffer, yuv_size, width, height, subsample, rgb_buffer, rgb_size, TJPF_RGBX)
