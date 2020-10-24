### Turbo-Jpeg

Port of libturbojpeg. 
The compiled static object is automatically linked in your build.

#### Currently supported:
- Linux
- Windows

#### High level API
There is also a high level api for compression, decompression of formats:
```nim
# convert i420 planes to rgb format
proc i4202rgb(
  i420_planes: array[3, ptr UncheckedArray[uint8]], strides: array[3, cint], width, height: int,
  rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, flags = 0
): bool 

# convert yuv to rgb format
proc yuv2rgb(
  yuv_buffer: pointer, yuv_size: uint, width, height: int, subsample: TJSAMP, 
  rgb_buffer: var ptr UncheckedArray[uint8], rgb_size: var uint, flags = 0
): bool

# convert rgb to yuv format
proc rgb2yuv(
  rgb_buffer: pointer, width, height: int, 
  yuv_buffer: var ptr UncheckedArray[uint8], yuv_size: var uint, 
  subsample: TJSAMP, flags = 0
): bool 

# convert yuv to jpeg format
proc yuv2jpeg(
  yuv_buffer: pointer | ptr UncheckedArray[uint8], width, height: int, subsample: TJSAMP,
  jpeg_buffer: var ptr UncheckedArray[uint8], jpeg_size: var uint, 
  quality: TJQuality, flags = 0
): bool

# convert jpeg to yuv
proc jpeg2yuv(
  jpeg_buffer: string, yuv_buffer: var ptr UncheckedArray[uint8], 
  yuv_size: var uint, yuv_sample: var TJSAMP, flags = 0
): bool

# convert planar yuv to jpeg
proc i4202jpeg(
  i420_buffer: array[3, ptr UncheckedArray[uint8]], width, height: int, 
  jpegBuf: var ptr UncheckedArray[uint8], jpegSize: var uint, jpegQual: TJQuality = 80, 
  strides: array[3, cint], flags = 0
): bool

...
```


### Examples
For low level examples see in examples/...
