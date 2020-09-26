import os

template getBinPath(): TaintedString =
  let info = splitFile(instantiationInfo(fullPaths = true).filename).dir
  info

when defined(Windows):
  when defined(m64):
    {.passL:getBinPath()&"turbojpeg/bin/win64/libturbojpeg.a",
      passL:getBinPath()&"turbojpeg/bin/win64/libturbojpeg.dll.a".}
  else:
    {.passL:getBinPath()&"turbojpeg/bin/win32/libturbojpeg.a",
      passL:getBinPath()&"turbojpeg/bin/win32/libturbojpeg.dll.a".}
elif defined(Linux):
  {.passL:getBinPath()&"turbojpeg/bin/linux/libturbojpeg.a".}

elif defined(MacOsX):
  {.error: "MacOsX is not supported now".}

elif defined(android):
  {.error: "Android is not supported now".}
else:
  {.error: "Yout System is not supported now".}

include turbojpeg/headers/turbojpeg_header


import turbojpeg/[tjpeg2i420, tjpeg2yuv, trgb2yuv, tyuv2pixel]

export tjpeg2i420, tjpeg2yuv, trgb2yuv, tyuv2pixel