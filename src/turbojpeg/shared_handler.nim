import headers/turbojpeg_header


type 
  WorkingBuffer* = object
    buffer*: ptr UncheckedArray[uint8]
    buffer_size*: uint
    buffer_size_max*: uint

var
  buffer* {.threadvar.}: WorkingBuffer

var decompressor* {.threadvar.}: tjhandle
var compressor* {.threadvar.}: tjhandle

const FAST_FLAGS* = TJFLAG_NOREALLOC or TJFLAG_FASTUPSAMPLE or TJFLAG_FASTDCT
