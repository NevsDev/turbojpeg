# import strformat
import headers/turbojpeg_header
import shared_handler

proc i4202pixel*(i420_planes: array[3, ptr UncheckedArray[uint8]], strides: array[3, cint], width, height: int, rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, pixelfmt: TJPF, flags = 0): bool =
  if decompressor == nil: decompressor = tjInitDecompress()
 
  var rgbSize = width * height * tjPixelSize[pixelfmt.int]
  if ((flags and TJFLAG_NOREALLOC) != TJFLAG_NOREALLOC) and rgb_size != rgbSize:
    rgb_buffer = cast[ptr UncheckedArray[uint8]](realloc(rgb_buffer, rgbSize))
    if rgb_buffer == nil:
      echo("alloc buffer failed.")
      return false
  rgb_size = rgbSize

  if tjDecodeYUVPlanes(decompressor, i420_planes, strides, TJSAMP_420.cint, rgb_buffer[0].addr, width.cint, 0, height.cint, pixelfmt.cint, (flags or TJFLAG_NOREALLOC).cint) != 0:
    echo tjGetErrorStr2(decompressor)
    return false
  return true


proc i4202rgb*(i420_planes: array[3, ptr UncheckedArray[uint8]], strides: array[3, cint], width, height: int, rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, flags = 0): bool {.inline.} =
  result = i4202pixel(i420_planes, strides, width, height, rgb_buffer, rgb_size, TJPF_RGB, flags)

proc i4202rgba*(i420_planes: array[3, ptr UncheckedArray[uint8]], strides: array[3, cint], width, height: int, rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, flags = 0): bool {.inline.} =
  result = i4202pixel(i420_planes, strides, width, height, rgb_buffer, rgb_size, TJPF_RGBA, flags)
