import os

template getBinPath(): TaintedString =
  let info = splitFile(instantiationInfo(fullPaths = true).filename).dir
  echo info&"/turbojpeg/bin/win32/libturbojpeg.dll.a"
  info

when defined(Windows):
  when defined(m64):
    {.passL:getBinPath()&"/turbojpeg/bin/win64/libturbojpeg.a".}
  else:
    {.
      passL:getBinPath()&"\\turbojpeg\\bin\\win32\\libturbojpeg.dll.a",
      passL:getBinPath()&"\\turbojpeg\\bin\\win32\\libturbojpeg.a"
    .}
elif defined(Linux):
  {.passL:getBinPath()&"/turbojpeg/bin/linux/libturbojpeg.a".}

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