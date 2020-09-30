import turbojpeg
import streams

# TEST
var
  width, height: int
  rgb_img_size: uint # = width * height * 3 div 2  # 12 bits per pixel
  pictureData: ptr UncheckedArray[uint8]

echo jpegFile2rgb("examples/example.jpg", pictureData, rgb_img_size, width, height)
echo rgb2jpegFile(pictureData, width, height, "trgb2jpegFile.jpeg")

# test with flags = TJFLAG_FASTUPSAMPLE or TJFLAG_NOREALLOC or TJFLAG_FASTDCT
var 
  jpegSize: uint
  jpegData = cast[ptr UncheckedArray[uint8]](alloc(maxJpegSize(width, height)))
echo rgb2jpeg(pictureData, width, height, jpegData, jpegSize, quality = 80, flags = TJFLAG_FASTUPSAMPLE or TJFLAG_NOREALLOC or TJFLAG_FASTDCT)
var file = open("cache_mem.jpeg", fmWrite)
if file != nil:
  discard file.writeBuffer(jpegData, jpegSize.int)
  file.close()
dealloc(pictureData)