import streams
import headers/turbojpeg_header
import shared_handler



proc jpeg2xxxx*(jpeg_buffer: pointer | ptr uint8 | ptr char, jpeg_size: uint, format: TJPF, dst_buffer: var ptr UncheckedArray[uint8], dst_size: var uint, width, height: var int, flags = 0): bool =
  # yuv_buffer will be assigned and resized automaticly: yuv_buffer <-> yuv_size
  var 
    subsample: TJSAMP
    colorspace: TJCS

  if decompressor == nil: decompressor = tjInitDecompress()

  if not tjDecompressHeader3(decompressor, jpeg_buffer, jpeg_size, width, height, subsample, colorspace):
    echo tjGetErrorStr2(decompressor)
    return false
 
  var buffSize = if format == TJPF_RGB or format == TJPF_BGR or format == TJPF_CMYK: (width * height * 3).uint
                elif format == TJPF_GRAY: (width * height).uint
                else: (width * height * 4).uint

  if ((flags and TJFLAG_NOREALLOC) != TJFLAG_NOREALLOC) and dst_size != buffSize:
    dst_size = buffSize
    dst_buffer = cast[ptr UncheckedArray[uint8]](realloc(dst_buffer, dst_size))
    if dst_buffer == nil:
      echo("alloc buffer failed.\n")
      return false


  if not tjDecompress2(decompressor, jpeg_buffer, jpeg_size, dst_buffer, width, height, TJPF_RGB, flags, 0):
    echo tjGetErrorStr2(decompressor)
    return false
  return true


proc maxJpegSize*(width, height: int): int = TJBUFSIZE(width.cint, height.cint).int

proc xxxx2jpeg*(format: TJPF, buffer: pointer | ptr uint8 | ptr UncheckedArray[uint8] | string, width, height: int, jpeg_buffer: var ptr UncheckedArray[byte], buffer_size: var uint, quality: TJQuality = 80, flags = 0): bool  =
  if compressor == nil: compressor = tjInitCompress()

  if tjCompress2(compressor, buffer, width, height, pixelFormat = format, jpeg_buffer, buffer_size, jpegSubsamp = TJSAMP_444, quality, flags):
    result = true
  else:
    echo tjGetErrorStr2(compressor)


proc xxxx2jpegFile*(format: TJPF, buffer: pointer | ptr uint8 |  ptr UncheckedArray[uint8] | string, width, height: int, filename: string, quality: TJQuality = 80, flags = 0): bool  =
  var
    jpeg_buffer: ptr UncheckedArray[byte]
    buffer_size: uint

  if xxxx2jpeg(format, buffer, width, height, jpeg_buffer, buffer_size, quality, flags):
    var file = open(filename, fmWrite)
    if file != nil:
      discard file.writeBuffer(jpeg_buffer, buffer_size.int)
      file.close()
      result = true
    else:
      result = false
    tjFree(jpeg_buffer)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc rgb2jpegFile*(rgb_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, filename: string, quality: TJQuality = 80, flags = 0): bool {.inline.} =
  xxxx2jpegFile(TJPF_RGB, rgb_buffer, width, height, filename, quality, flags)

proc rgb2jpeg*(rgb_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, jpeg_buffer: var ptr UncheckedArray[byte], buffer_size: var uint, quality: TJQuality = 80, flags = 0): bool {.inline.} =
  xxxx2jpeg(TJPF_RGB, rgb_buffer, width, height, jpeg_buffer, buffer_size, quality, flags)

proc rgb2jpeg*(rgb_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, jpeg_buffer: var string, quality: TJQuality = 80, flags = 0): bool {.inline.} =
  var
    j_buffer: ptr UncheckedArray[byte]
    buffer_size: uint
  if xxxx2jpeg(TJPF_RGB, rgb_buffer, width, height, j_buffer, buffer_size, quality, flags):
    jpeg_buffer.setLen(buffer_size)
    copyMem(jpeg_buffer[0].unsafeAddr, j_buffer, buffer_size)
  tjFree(j_buffer)


proc jpeg2rgb*(jpeg_buffer: pointer, buffer_size: uint|int, rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, width, height: var int, flags = 0): bool {.inline.} =
  jpeg2xxxx(jpeg_buffer, buffer_size.uint, TJPF_RGB, rgb_buffer, rgb_size, width, height, flags)

proc jpeg2rgb*(jpeg_buffer: string, rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, width, height: var int, flags = 0): bool {.inline.} =
  jpeg2rgb(jpeg_buffer[0].unsafeAddr, jpeg_buffer.len, rgb_buffer, rgb_size, width, height, flags)

proc jpegFile2rgb*(filename: string, rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, width, height: var int, flags = 0): bool {.inline.} =
  jpeg2rgb(readFile(filename), rgb_buffer, rgb_size, width, height, flags)



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc rgba2jpegFile*(rgba_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, filename: string, quality: TJQuality = 80, flags = 0): bool {.inline.} =
  xxxx2jpegFile(TJPF_RGBA, rgba_buffer, width, height, filename, quality, flags)

proc rgba2jpeg*(rgb_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, jpeg_buffer: var ptr UncheckedArray[byte] | ptr pointer, buffer_size: var uint, quality: TJQuality = 80, flags = 0): bool {.inline.} =
  xxxx2jpeg(TJPF_RGBA, rgb_buffer, width, height, jpeg_buffer, buffer_size, quality, flags)

proc jpeg2rgba*(jpeg_buffer: pointer, buffer_size: uint|int, rgba_buffer: var ptr UncheckedArray[uint8], rgba_size: var uint, width, height: var int, flags = 0): bool {.inline.} =
  jpeg2xxxx(jpeg_buffer, buffer_size.uint, TJPF_RGBA, rgba_buffer, rgba_size, width, height, flags)

proc jpeg2rgba*(jpeg_buffer: string, rgba_buffer: var ptr UncheckedArray[uint8], rgba_size: var uint, width, height: var int, flags = 0): bool {.inline.} =
  jpeg2rgba(jpeg_buffer[0].unsafeAddr, jpeg_buffer.len.uint, rgba_buffer, rgba_size, width, height, flags)

proc jpegFile2rgba*(filename: string, rgba_buffer: var ptr UncheckedArray[uint8], rgba_size: var uint, width, height: var int, flags = 0): bool {.inline.} =
  jpeg2rgba(readFile(filename), rgba_buffer, rgba_size, width, height, flags)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc gray2jpegFile*(gray_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, filename: string, quality: TJQuality = 80, flags = 0): bool {.inline.} =
  xxxx2jpegFile(TJPF_GRAY, gray_buffer, width, height, filename, quality, flags)

proc gray2jpeg*(rgb_buffer: ptr UncheckedArray[uint8] | pointer | ptr uint8 | string, width, height: int, jpeg_buffer: var ptr UncheckedArray[byte] | ptr pointer, buffer_size: var uint, quality: TJQuality = 80, flags = 0): bool {.inline.} =
  xxxx2jpeg(TJPF_GRAY, rgb_buffer, width, height, jpeg_buffer, buffer_size, quality, flags)

proc jpeg2gray*(jpeg_buffer: pointer, buffer_size: uint|int, gray_buffer: var ptr UncheckedArray[uint8], gray_size: var uint, width, height: var int, flags = 0): bool {.inline.} =
  jpeg2xxxx(jpeg_buffer, buffer_size.uint, TJPF_GRAY, gray_buffer, gray_size, width, height, flags)

proc jpeg2gray*(jpeg_buffer: string, gray_buffer: var ptr UncheckedArray[uint8], gray_size: var uint, width, height: var int, flags = 0): bool {.inline.} =
  jpeg2gray(jpeg_buffer[0].unsafeAddr, jpeg_buffer.len.uint, gray_buffer, gray_size, width, height, flags)

proc jpegFile2gray*(filename: string, gray_buffer: var ptr UncheckedArray[uint8], gray_size: var uint, width, height: var int, flags = 0): bool {.inline.} =
  jpeg2gray(readFile(filename), gray_buffer, gray_size, width, height, flags)