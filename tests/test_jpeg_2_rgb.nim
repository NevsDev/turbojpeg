import turbojpeg


# TEST
var
  width, height: int
  rgb_img_size: uint # = width * height * 3 div 2  # 12 bits per pixel
  pictureData: ptr UncheckedArray[uint8]

echo jpegFile2rgb("examples/example.jpg", pictureData, rgb_img_size, width, height)
echo rgb2jpegFile(pictureData, width, height, "trgb2jpegFile.jpeg")

