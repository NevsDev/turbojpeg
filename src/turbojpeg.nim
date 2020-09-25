import os

template getBinPath(): TaintedString =
  let info = splitFile(instantiationInfo(fullPaths = true).filename).dir
  info

when defined(Windows):
  when defined(m64):
    {.passL:getBinPath()&"/bin/win64/libturbojpeg.a",
      passL:getBinPath()&"/bin/win64/libturbojpeg.dll.a".}
  else:
    {.passL:getBinPath()&"/bin/win32/libturbojpeg.a",
      passL:getBinPath()&"/bin/win32/libturbojpeg.dll.a".}
elif defined(Linux):
  {.passL:getBinPath()&"/bin/linux/libturbojpeg.a".}

elif defined(MacOsX):
  {.error: "MacOsX is not supported now".}

elif defined(android):
  {.error: "Android is not supported now".}
else:
  {.error: "Yout System is not supported now".}

include headers/turbojpeg_header
