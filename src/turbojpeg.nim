import os, strutils

template getBinPath(): TaintedString =
  let info = splitFile(instantiationInfo(fullPaths = true).filename).dir
  info

const 
  path = getBinPath()


when defined(Windows):
  {.passL: "-static -lpthread -dynamic".}
  when sizeof(int) == 8:
    {.passL: path.joinPath(normalizedPath("turbojpeg/bin/win64/libturbojpeg.a")).escape.}
  else:
    {.passL: path.joinPath(normalizedPath("turbojpeg/bin/win32/libturbojpeg.a")).escape.}
elif defined(Linux):
  {.passL: path.joinPath(normalizedPath("turbojpeg/bin/linux/libturbojpeg.a")).escape.}

elif defined(MacOsX):
  {.error: "MacOsX is not supported now".}

elif defined(android):
  {.error: "Android is not supported now".}
else:
  {.error: "Yout System is not supported now".}

import turbojpeg/headers/turbojpeg_header
const FAST_FLAGS* = TJFLAG_NOREALLOC or TJFLAG_FASTUPSAMPLE or TJFLAG_FASTDCT

import turbojpeg/[jpeg2i420, jpeg2yuv, rgb2yuv, yuv2pixel, jpeg2xxxx, i4202pixel]

export turbojpeg_header, jpeg2i420, jpeg2yuv, rgb2yuv, yuv2pixel, jpeg2xxxx, i4202pixel