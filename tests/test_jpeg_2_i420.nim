import turbojpeg


# TEST
var
  width, height: int
  i420_img_size: uint # = width * height * 3 div 2  # 12 bits per pixel
  pictureData: ptr UncheckedArray[uint8]

echo jpegFile2i420("examples/example.jpg", pictureData, i420_img_size, width, height)

