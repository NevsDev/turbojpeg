import headers/turbojpeg_header
import os

var decompressor: tjhandle

var 
  rgb_buffer: ptr UncheckedArray[uint8]
  rgb_buffer_size: uint
  rgb_buffer_size_max: uint


proc tjpeg2i420*(jpeg_buffer: pointer, jpeg_size: uint, i420_buffer: ptr ptr UncheckedArray[uint8], i420_size: var uint, width, height: var int): bool =
  # Warning: single threaded converter 
  # yuv_buffer will be assigned and resized automaticly: yuv_buffer <-> yuv_size
  var 
    subsample: TJSAMP
    colorspace: TJCS
    flags = 0
    padding = 1               # 1 or 4 can be, but is not 0

  if decompressor == nil: decompressor = tjInitDecompress()

  tjDecompressHeader3(decompressor, jpeg_buffer, jpeg_size, width, height, subsample, colorspace)
 
  var buffSize = (width * height * 3).uint
  if rgb_buffer_size != buffSize:
    rgb_buffer_size = buffSize
    if rgb_buffer_size_max < buffSize:
      if rgb_buffer == nil:
        rgb_buffer = cast[ptr UncheckedArray[uint8]](alloc(rgb_buffer_size_max))
      else:
        rgb_buffer = cast[ptr UncheckedArray[uint8]](realloc(rgb_buffer, rgb_buffer_size_max))
      if rgb_buffer == nil:
        echo("alloc buffer failed.\n")
        return false

  var std_i420_size = (width * height * 3 div 2).uint
  if i420_size != std_i420_size:  # 12 bits per pixel
    i420_size = std_i420_size
    if i420_buffer[] == nil:
      i420_buffer[] = cast[ptr UncheckedArray[uint8]](alloc(std_i420_size))
    else:
      i420_buffer[] = cast[ptr UncheckedArray[uint8]](realloc(i420_buffer[], std_i420_size))

  if tjDecompress2(decompressor, jpeg_buffer, jpeg_size, rgb_buffer, width, height, TJPF_RGB, TJFLAG_FASTDCT):
    result = tjEncodeYUV3(decompressor, rgb_buffer, width, pitch = 0, height, TJPF_RGB, i420_buffer[], padding, TJSAMP_420, flags) == 0


proc tjpeg2i420*(jpeg_buffer: string, i420_buffer: ptr ptr UncheckedArray[uint8], i420_size: var uint, width, height: var int): bool =
  result = tjpeg2i420(jpeg_buffer[0].unsafeAddr, jpeg_buffer.len.uint, i420_buffer, i420_size, width, height)

proc ti420FromFile*(filename: string, i420_buffer: ptr ptr UncheckedArray[uint8], i420_size: var uint, width, height: var int): bool =
  var fileContent = readFile(filename)
  result = tjpeg2i420(fileContent[0].unsafeAddr, fileContent.len.uint, i420_buffer, i420_size, width, height)