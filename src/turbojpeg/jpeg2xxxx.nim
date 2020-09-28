import streams
import headers/turbojpeg_header
import shared_handler



proc jpeg2xxxx*(jpeg_buffer: pointer | ptr uint8 | ptr char, jpeg_size: uint, format: TJPF, dst_buffer: var ptr UncheckedArray[uint8], dst_size: var uint, width, height: var int): bool =
  # yuv_buffer will be assigned and resized automaticly: yuv_buffer <-> yuv_size
  var 
    subsample: TJSAMP
    colorspace: TJCS
    flags = 0

  if decompressor == nil: decompressor = tjInitDecompress()

  if not tjDecompressHeader3(decompressor, jpeg_buffer, jpeg_size, width, height, subsample, colorspace):
    echo tjGetErrorStr2(decompressor)
    return false
 
  var buffSize = if format == TJPF_RGB or format == TJPF_BGR or format == TJPF_CMYK: (width * height * 3).uint
                elif format == TJPF_GRAY: (width * height).uint
                else: (width * height * 4).uint

  if dst_size != buffSize:
    dst_size = buffSize

    if dst_buffer == nil:
      dst_buffer = cast[ptr UncheckedArray[uint8]](alloc(dst_size))
    else:
      dst_buffer = cast[ptr UncheckedArray[uint8]](realloc(dst_buffer, dst_size))
    if dst_buffer == nil:
      echo("alloc buffer failed.\n")
      return false


  if not tjDecompress2(decompressor, jpeg_buffer, jpeg_size, dst_buffer, width, height, TJPF_RGB, flags, 0):
    echo tjGetErrorStr2(decompressor)
    return false
  return true

proc xxxx2jpegFile*(format: TJPF, buffer: pointer | ptr uint8 | string, width, height: int, filename: string, quality: TJQuality = 80): bool  =
  var
    jpeg_buffer: ptr UncheckedArray[byte]
    buffer_size: uint

  if compressor == nil: compressor = tjInitCompress()

  if tjCompress2(compressor, buffer, width, height, pixelFormat = format, jpeg_buffer, buffer_size, jpegSubsamp = TJSAMP_444, quality, flags = 0):
    var file = open(filename, fmWrite)
    if file != nil:
      discard file.writeBuffer(jpeg_buffer, buffer_size.int)
      file.close()
      result = true
    else:
      result = false
    tjFree(jpeg_buffer)
  else:
    echo tjGetErrorStr2(compressor)


proc xxxx2jpegFile*(format: TJPF, buffer: ptr UncheckedArray[uint8], width, height: int, filename: string, quality: TJQuality = 80): bool  {.inline.} =
  xxxx2jpegFile(format, cast[pointer](buffer), width, height, filename, quality)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc rgb2jpegFile*(rgb_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, filename: string, quality: TJQuality = 80): bool {.inline.} =
  xxxx2jpegFile(TJPF_RGB, rgb_buffer, width, height, filename, quality)

proc rgb2jpeg*(rgb_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, quality: TJQuality, jpeg_buffer: ptr ptr UncheckedArray[byte] | ptr pointer, buffer_size: var uint): bool {.inline.} =
  result = tjCompress2(compressor, rgb_buffer, width, height, pixelFormat = TJPF_RGB, jpeg_buffer, buffer_size, jpegSubsamp = TJSAMP_444, quality, flags = 0)

proc jpeg2rgb*(jpeg_buffer: pointer, buffer_size: uint|int, rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, width, height: var int): bool {.inline.} =
  jpeg2xxxx(jpeg_buffer, buffer_size.uint, TJPF_RGB, rgb_buffer, rgb_size, width, height)

proc jpeg2rgb*(jpeg_buffer: string, rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, width, height: var int): bool {.inline.} =
  jpeg2rgb(jpeg_buffer[0].unsafeAddr, jpeg_buffer.len, rgb_buffer, rgb_size, width, height)

proc jpegFile2rgb*(filename: string, rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, width, height: var int): bool {.inline.} =
  jpeg2rgb(readFile(filename), rgb_buffer, rgb_size, width, height)



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc rgba2jpegFile*(rgba_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, filename: string, quality: TJQuality = 80): bool {.inline.} =
  xxxx2jpegFile(TJPF_RGBA, rgba_buffer, width, height, filename, quality)

proc jpeg2rgba*(jpeg_buffer: pointer, buffer_size: uint|int, rgba_buffer: var ptr UncheckedArray[uint8], rgba_size: var uint, width, height: var int): bool {.inline.} =
  jpeg2xxxx(jpeg_buffer, buffer_size.uint, TJPF_RGBA, rgba_buffer, rgba_size, width, height)

proc jpeg2rgba*(jpeg_buffer: string, rgba_buffer: var ptr UncheckedArray[uint8], rgba_size: var uint, width, height: var int): bool {.inline.} =
  jpeg2rgba(jpeg_buffer[0].unsafeAddr, jpeg_buffer.len.uint, rgba_buffer, rgba_size, width, height)

proc jpegFile2rgba*(filename: string, rgba_buffer: var ptr UncheckedArray[uint8], rgba_size: var uint, width, height: var int): bool {.inline.} =
  jpeg2rgba(readFile(filename), rgba_buffer, rgba_size, width, height)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc gray2jpegFile*(gray_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, filename: string, quality: TJQuality = 80): bool {.inline.} =
  xxxx2jpegFile(TJPF_GRAY, gray_buffer, width, height, filename, quality)

proc jpeg2gray*(jpeg_buffer: pointer, buffer_size: uint|int, gray_buffer: var ptr UncheckedArray[uint8], gray_size: var uint, width, height: var int): bool {.inline.} =
  jpeg2xxxx(jpeg_buffer, buffer_size.uint, TJPF_GRAY, gray_buffer, gray_size, width, height)

proc jpeg2gray*(jpeg_buffer: string, gray_buffer: var ptr UncheckedArray[uint8], gray_size: var uint, width, height: var int): bool {.inline.} =
  jpeg2gray(jpeg_buffer[0].unsafeAddr, jpeg_buffer.len.uint, gray_buffer, gray_size, width, height)

proc jpegFile2gray*(filename: string, gray_buffer: var ptr UncheckedArray[uint8], gray_size: var uint, width, height: var int): bool {.inline.} =
  jpeg2gray(readFile(filename), gray_buffer, gray_size, width, height)