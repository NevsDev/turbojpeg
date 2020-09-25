##
##  Copyright (C)2009-2015, 2017, 2020 D. R. Commander.  All Rights Reserved.
##
##  Redistribution and use in source and binary forms, with or without
##  modification, are permitted provided that the following conditions are met:
##
##  - Redistributions of source code must retain the above copyright notice,
##    this list of conditions and the following disclaimer.
##  - Redistributions in binary form must reproduce the above copyright notice,
##    this list of conditions and the following disclaimer in the documentation
##    and/or other materials provided with the distribution.
##  - Neither the name of the libjpeg-turbo Project nor the names of its
##    contributors may be used to endorse or promote products derived from this
##    software without specific prior written permission.
##
##  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS",
##  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
##  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
##  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
##  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
##  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
##  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
##  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
##  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
##  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
##  POSSIBILITY OF SUCH DAMAGE.
##

## *
##  @addtogroup TurboJPEG
##  TurboJPEG API.  This API provides an interface for generating, decoding, and
##  transforming planar YUV and JPEG images in memory.
##
##  @anchor YUVnotes
##  YUV Image Format Notes
##  ----------------------
##  Technically, the JPEG format uses the YCbCr colorspace (which is technically
##  not a colorspace but a color transform), but per the convention of the
##  digital video community, the TurboJPEG API uses "YUV" to refer to an image
##  format consisting of Y, Cb, and Cr image planes.
##
##  Each plane is simply a 2D array of bytes, each byte representing the value
##  of one of the components (Y, Cb, or Cr) at a particular location in the
##  image.  The width and height of each plane are determined by the image
##  width, height, and level of chrominance subsampling.   The luminance plane
##  width is the image width padded to the nearest multiple of the horizontal
##  subsampling factor (2 in the case of 4:2:0 and 4:2:2, 4 in the case of
##  4:1:1, 1 in the case of 4:4:4 or grayscale.)  Similarly, the luminance plane
##  height is the image height padded to the nearest multiple of the vertical
##  subsampling factor (2 in the case of 4:2:0 or 4:4:0, 1 in the case of 4:4:4
##  or grayscale.)  This is irrespective of any additional padding that may be
##  specified as an argument to the various YUV functions.  The chrominance
##  plane width is equal to the luminance plane width divided by the horizontal
##  subsampling factor, and the chrominance plane height is equal to the
##  luminance plane height divided by the vertical subsampling factor.
##
##  For example, if the source image is 35 x 35 pixels and 4:2:2 subsampling is
##  used, then the luminance plane would be 36 x 35 bytes, and each of the
##  chrominance planes would be 18 x 35 bytes.  If you specify a line padding of
##  4 bytes on top of this, then the luminance plane would be 36 x 35 bytes, and
##  each of the chrominance planes would be 20 x 35 bytes.
##
##  @{
##
## *
##  The number of chrominance subsampling options
##

const
  TJ_NUMSAMP* = 6

## *
##  Chrominance subsampling options.
##  When pixels are converted from RGB to YCbCr (see #TJCS_YCbCr) or from CMYK
##  to YCCK (see #TJCS_YCCK) as part of the JPEG compression process, some of
##  the Cb and Cr (chrominance) components can be discarded or averaged together
##  to produce a smaller image with little perceptible loss of image clarity
##  (the human eye is more sensitive to small changes in brightness than to
##  small changes in color.)  This is called "chrominance subsampling".
##

type
  TJSAMP* {.size: sizeof(cint).} = enum ## *
    ##  4:4:4 chrominance subsampling (no chrominance subsampling).  The JPEG or
    ##  YUV image will contain one chrominance component for every pixel in the
    ##  source image.
    TJSAMP_444 = 0,
    ##  4:2:2 chrominance subsampling.  The JPEG or YUV image will contain one
    ##  chrominance component for every 2x1 block of pixels in the source image.
    TJSAMP_422, 
    ##  4:2:0 chrominance subsampling.  The JPEG or YUV image will contain one
    ##  chrominance component for every 2x2 block of pixels in the source image.
    TJSAMP_420,
    ##  Grayscale.  The JPEG or YUV image will contain no chrominance components.
    TJSAMP_GRAY,
    ##  4:4:0 chrominance subsampling.  The JPEG or YUV image will contain one
    ##  chrominance component for every 1x2 block of pixels in the source image.
    ##
    ##  @note 4:4:0 subsampling is not fully accelerated in libjpeg-turbo.
    TJSAMP_440,
    ##  4:1:1 chrominance subsampling.  The JPEG or YUV image will contain one
    ##  chrominance component for every 4x1 block of pixels in the source image.
    ##  JPEG images compressed with 4:1:1 subsampling will be almost exactly the
    ##  same size as those compressed with 4:2:0 subsampling, and in the
    ##  aggregate, both subsampling methods produce approximately the same
    ##  perceptual quality.  However, 4:1:1 is better able to reproduce sharp
    ##  horizontal features.
    ##
    ##  @note 4:1:1 subsampling is not fully accelerated in libjpeg-turbo.
    TJSAMP_411


## *
##  MCU block width (in pixels) for a given level of chrominance subsampling.
##  MCU block sizes:
##  - 8x8 for no subsampling or grayscale
##  - 16x8 for 4:2:2
##  - 8x16 for 4:4:0
##  - 16x16 for 4:2:0
##  - 32x8 for 4:1:1
var tjMCUWidth* {.importc: "tjMCUWidth".}: array[TJ_NUMSAMP, cint]

## *
##  MCU block height (in pixels) for a given level of chrominance subsampling.
##  MCU block sizes:
##  - 8x8 for no subsampling or grayscale
##  - 16x8 for 4:2:2
##  - 8x16 for 4:4:0
##  - 16x16 for 4:2:0
##  - 32x8 for 4:1:1
var tjMCUHeight* {.importc: "tjMCUHeight".}: array[TJ_NUMSAMP, cint]

## *
##  The number of pixel formats
##

const
  TJ_NUMPF* = 12

##  Pixel formats
type
  TJPF* {.size: sizeof(cint).} = enum
    ##  RGB pixel format.  The red, green, and blue components in the image are
    ##  stored in 3-byte pixels in the order R, G, B from lowest to highest byte
    ##  address within each pixel.
    TJPF_UNKNOWN = -1, TJPF_RGB = 0, 

    ##  BGR pixel format.  The red, green, and blue components in the image are
    ##  stored in 3-byte pixels in the order B, G, R from lowest to highest byte
    ##  address within each pixel.
    TJPF_BGR,

    ##  RGBX pixel format.  The red, green, and blue components in the image are
    ##  stored in 4-byte pixels in the order R, G, B from lowest to highest byte
    ##  address within each pixel.  The X component is ignored when compressing
    ##  and undefined when decompressing.
    TJPF_RGBX,

    ##  BGRX pixel format.  The red, green, and blue components in the image are
    ##  stored in 4-byte pixels in the order B, G, R from lowest to highest byte
    ##  address within each pixel.  The X component is ignored when compressing
    ##  and undefined when decompressing.
    TJPF_BGRX,

    ##  XBGR pixel format.  The red, green, and blue components in the image are
    ##  stored in 4-byte pixels in the order R, G, B from highest to lowest byte
    ##  address within each pixel.  The X component is ignored when compressing
    ##  and undefined when decompressing.
    TJPF_XBGR,

    ##  XRGB pixel format.  The red, green, and blue components in the image are
    ##  stored in 4-byte pixels in the order B, G, R from highest to lowest byte
    ##  address within each pixel.  The X component is ignored when compressing
    ##  and undefined when decompressing.
    TJPF_XRGB,

    ##  Grayscale pixel format.  Each 1-byte pixel represents a luminance
    ##  (brightness) level from 0 to 255.
    TJPF_GRAY,

    ##  RGBA pixel format.  This is the same as @ref TJPF_RGBX, except that when
    ##  decompressing, the X component is guaranteed to be 0xFF, which can be
    ##  interpreted as an opaque alpha channel.
    TJPF_RGBA,

    ##  BGRA pixel format.  This is the same as @ref TJPF_BGRX, except that when
    ##  decompressing, the X component is guaranteed to be 0xFF, which can be
    ##  interpreted as an opaque alpha channel.
    TJPF_BGRA,

    ##  ABGR pixel format.  This is the same as @ref TJPF_XBGR, except that when
    ##  decompressing, the X component is guaranteed to be 0xFF, which can be
    ##  interpreted as an opaque alpha channel.
    TJPF_ABGR,

    ##  ARGB pixel format.  This is the same as @ref TJPF_XRGB, except that when
    ##  decompressing, the X component is guaranteed to be 0xFF, which can be
    ##  interpreted as an opaque alpha channel.
    TJPF_ARGB,

    ##  CMYK pixel format.  Unlike RGB, which is an additive color model used
    ##  primarily for display, CMYK (Cyan/Magenta/Yellow/Key) is a subtractive
    ##  color model used primarily for printing.  In the CMYK color model, the
    ##  value of each color component typically corresponds to an amount of cyan,
    ##  magenta, yellow, or black ink that is applied to a white background.  In
    ##  order to convert between CMYK and RGB, it is necessary to use a color
    ##  management system (CMS.)  A CMS will attempt to map colors within the
    ##  printer's gamut to perceptually similar colors in the display's gamut and
    ##  vice versa, but the mapping is typically not 1:1 or reversible, nor can it
    ##  be defined with a simple formula.  Thus, such a conversion is out of scope
    ##  for a codec library.  However, the TurboJPEG API allows for compressing
    ##  CMYK pixels into a YCCK JPEG image (see #TJCS_YCCK) and decompressing YCCK
    ##  JPEG images into CMYK pixels.
    TJPF_CMYK
    ##  Unknown pixel format.  Currently this is only used by #tjLoadImage().


##  Red offset (in bytes) for a given pixel format.  This specifies the number
##  of bytes that the red component is offset from the start of the pixel.  For
##  instance, if a pixel of format TJ_BGRX is stored in <tt>char pixel[]</tt>,
##  then the red component will be <tt>pixel[tjRedOffset[TJ_BGRX]]</tt>.  This
##  will be -1 if the pixel format does not have a red component.
var tjRedOffset* {.importc: "tjRedOffset".}: array[TJ_NUMPF, cint]

##  Green offset (in bytes) for a given pixel format.  This specifies the number
##  of bytes that the green component is offset from the start of the pixel.
##  For instance, if a pixel of format TJ_BGRX is stored in
##  <tt>char pixel[]</tt>, then the green component will be
##  <tt>pixel[tjGreenOffset[TJ_BGRX]]</tt>.  This will be -1 if the pixel format
##  does not have a green component.
var tjGreenOffset* {.importc: "tjGreenOffset".}: array[TJ_NUMPF, cint]

##  Blue offset (in bytes) for a given pixel format.  This specifies the number
##  of bytes that the Blue component is offset from the start of the pixel.  For
##  instance, if a pixel of format TJ_BGRX is stored in <tt>char pixel[]</tt>,
##  then the blue component will be <tt>pixel[tjBlueOffset[TJ_BGRX]]</tt>.  This
##  will be -1 if the pixel format does not have a blue component.
var tjBlueOffset* {.importc: "tjBlueOffset".}: array[TJ_NUMPF, cint]

##  Alpha offset (in bytes) for a given pixel format.  This specifies the number
##  of bytes that the Alpha component is offset from the start of the pixel.
##  For instance, if a pixel of format TJ_BGRA is stored in
##  <tt>char pixel[]</tt>, then the alpha component will be
##  <tt>pixel[tjAlphaOffset[TJ_BGRA]]</tt>.  This will be -1 if the pixel format
##  does not have an alpha component.
var tjAlphaOffset* {.importc: "tjAlphaOffset".}: array[TJ_NUMPF, cint]

##  Pixel size (in bytes) for a given pixel format
var tjPixelSize* {.importc: "tjPixelSize".}: array[TJ_NUMPF, cint]

##  The number of JPEG colorspaces
const TJ_NUMCS* = 5

##  JPEG colorspaces
type
  TJCS* {.size: sizeof(cint).} = enum 
    ##  RGB colorspace.  When compressing the JPEG image, the R, G, and B
    ##  components in the source image are reordered into image planes, but no
    ##  colorspace conversion or subsampling is performed.  RGB JPEG images can be
    ##  decompressed to any of the extended RGB pixel formats or grayscale, but
    ##  they cannot be decompressed to YUV images.
    TJCS_RGB = 0, 

    ##  YCbCr colorspace.  YCbCr is not an absolute colorspace but rather a
    ##  mathematical transformation of RGB designed solely for storage and
    ##  transmission.  YCbCr images must be converted to RGB before they can
    ##  actually be displayed.  In the YCbCr colorspace, the Y (luminance)
    ##  component represents the black & white portion of the original image, and
    ##  the Cb and Cr (chrominance) components represent the color portion of the
    ##  original image.  Originally, the analog equivalent of this transformation
    ##  allowed the same signal to drive both black & white and color televisions,
    ##  but JPEG images use YCbCr primarily because it allows the color data to be
    ##  optionally subsampled for the purposes of reducing bandwidth or disk
    ##  space.  YCbCr is the most common JPEG colorspace, and YCbCr JPEG images
    ##  can be compressed from and decompressed to any of the extended RGB pixel
    ##  formats or grayscale, or they can be decompressed to YUV planar images.
    TJCS_YCbCr,

    ##  Grayscale colorspace.  The JPEG image retains only the luminance data (Y
    ##  component), and any color data from the source image is discarded.
    ##  Grayscale JPEG images can be compressed from and decompressed to any of
    ##  the extended RGB pixel formats or grayscale, or they can be decompressed
    ##  to YUV planar images.
    TJCS_GRAY,

    ##  CMYK colorspace.  When compressing the JPEG image, the C, M, Y, and K
    ##  components in the source image are reordered into image planes, but no
    ##  colorspace conversion or subsampling is performed.  CMYK JPEG images can
    ##  only be decompressed to CMYK pixels.
    TJCS_CMYK,

    ##  YCCK colorspace.  YCCK (AKA "YCbCrK") is not an absolute colorspace but
    ##  rather a mathematical transformation of CMYK designed solely for storage
    ##  and transmission.  It is to CMYK as YCbCr is to RGB.  CMYK pixels can be
    ##  reversibly transformed into YCCK, and as with YCbCr, the chrominance
    ##  components in the YCCK pixels can be subsampled without incurring major
    ##  perceptual loss.  YCCK JPEG images can only be compressed from and
    ##  decompressed to CMYK pixels.
    TJCS_YCCK


##  The uncompressed source/destination image is stored in bottom-up (Windows,
##  OpenGL) order, not top-down (X11) order.
const TJFLAG_BOTTOMUP* = 2

##  When decompressing an image that was compressed using chrominance
##  subsampling, use the fastest chrominance upsampling algorithm available in
##  the underlying codec.  The default is to use smooth upsampling, which
##  creates a smooth transition between neighboring chrominance components in
##  order to reduce upsampling artifacts in the decompressed image.
const TJFLAG_FASTUPSAMPLE* = 256

##  Disable buffer (re)allocation.  If passed to one of the JPEG compression or
##  transform functions, this flag will cause those functions to generate an
##  error if the JPEG image buffer is invalid or too small rather than
##  attempting to allocate or reallocate that buffer.  This reproduces the
##  behavior of earlier versions of TurboJPEG.
const TJFLAG_NOREALLOC* = 1024

##  Use the fastest DCT/IDCT algorithm available in the underlying codec.  The
##  default if this flag is not specified is implementation-specific.  For
##  example, the implementation of TurboJPEG for libjpeg[-turbo] uses the fast
##  algorithm by default when compressing, because this has been shown to have
##  only a very slight effect on accuracy, but it uses the accurate algorithm
##  when decompressing, because this has been shown to have a larger effect.
const TJFLAG_FASTDCT* = 2048

##  Use the most accurate DCT/IDCT algorithm available in the underlying codec.
##  The default if this flag is not specified is implementation-specific.  For
##  example, the implementation of TurboJPEG for libjpeg[-turbo] uses the fast
##  algorithm by default when compressing, because this has been shown to have
##  only a very slight effect on accuracy, but it uses the accurate algorithm
##  when decompressing, because this has been shown to have a larger effect.
const TJFLAG_ACCURATEDCT* = 4096

##  Immediately discontinue the current compression/decompression/transform
##  operation if the underlying codec throws a warning (non-fatal error).  The
##  default behavior is to allow the operation to complete unless a fatal error
##  is encountered.
const TJFLAG_STOPONWARNING* = 8192

##  Use progressive entropy coding in JPEG images generated by the compression
##  and transform functions.  Progressive entropy coding will generally improve
##  compression relative to baseline entropy coding (the default), but it will
##  reduce compression and decompression performance considerably.
const TJFLAG_PROGRESSIVE* = 16384

##  The number of error codes
const TJ_NUMERR* = 2

##  Error codes
type
  TJERR* {.size: sizeof(cint).} = enum
    ##  The error was non-fatal and recoverable, but the image may still be
    ##  corrupt.
    TJERR_WARNING = 0,
    ##  The error was fatal and non-recoverable.
    TJERR_FATAL


##  The number of transform operations
const
  TJ_NUMXOP* = 8

##  Transform operations for #tjTransform()
type
  TJXOP* {.size: sizeof(cint).} = enum ## *
    ##  Do not transform the position of the image pixels
    TJXOP_NONE = 0,

    ##  Flip (mirror) image horizontally.  This transform is imperfect if there
    ##  are any partial MCU blocks on the right edge (see #TJXOPT_PERFECT.)
    TJXOP_HFLIP,

    ##  Flip (mirror) image vertically.  This transform is imperfect if there are
    ##  any partial MCU blocks on the bottom edge (see #TJXOPT_PERFECT.)
    TJXOP_VFLIP,

    ##  Transpose image (flip/mirror along upper left to lower right axis.)  This
    ##  transform is always perfect.
    TJXOP_TRANSPOSE,
    
    ##  Transverse transpose image (flip/mirror along upper right to lower left
    ##  axis.)  This transform is imperfect if there are any partial MCU blocks in
    ##  the image (see #TJXOPT_PERFECT.)
    TJXOP_TRANSVERSE,

    ##  Rotate image clockwise by 90 degrees.  This transform is imperfect if
    ##  there are any partial MCU blocks on the bottom edge (see
    ##  #TJXOPT_PERFECT.)
    TJXOP_ROT90,

    ##  Rotate image 180 degrees.  This transform is imperfect if there are any
    ##  partial MCU blocks in the image (see #TJXOPT_PERFECT.)
    TJXOP_ROT180,

    ##  Rotate image counter-clockwise by 90 degrees.  This transform is imperfect
    ##  if there are any partial MCU blocks on the right edge (see
    ##  #TJXOPT_PERFECT.)
    TJXOP_ROT270


##  This option will cause #tjTransform() to return an error if the transform is
##  not perfect.  Lossless transforms operate on MCU blocks, whose size depends
##  on the level of chrominance subsampling used (see #tjMCUWidth
##  and #tjMCUHeight.)  If the image's width or height is not evenly divisible
##  by the MCU block size, then there will be partial MCU blocks on the right
##  and/or bottom edges.  It is not possible to move these partial MCU blocks to
##  the top or left of the image, so any transform that would require that is
##  "imperfect."  If this option is not specified, then any partial MCU blocks
##  that cannot be transformed will be left in place, which will create
##  odd-looking strips on the right or bottom edge of the image.
const
  TJXOPT_PERFECT* = 1

##  This option will cause #tjTransform() to discard any partial MCU blocks that
##  cannot be transformed.
const
  TJXOPT_TRIM* = 2

##  This option will enable lossless cropping.  See #tjTransform() for more
##  information.
const
  TJXOPT_CROP* = 4

##  This option will discard the color data in the input image and produce
##  a grayscale output image.
const
  TJXOPT_GRAY* = 8

##  This option will prevent #tjTransform() from outputting a JPEG image for
##  this particular transform (this can be used in conjunction with a custom
##  filter to capture the transformed DCT coefficients without transcoding
##  them.)
const
  TJXOPT_NOOUTPUT* = 16

##  This option will enable progressive entropy coding in the output image
##  generated by this particular transform.  Progressive entropy coding will
##  generally improve compression relative to baseline entropy coding (the
##  default), but it will reduce compression and decompression performance
##  considerably.
const
  TJXOPT_PROGRESSIVE* = 32

##  This option will prevent #tjTransform() from copying any extra markers
##  (including EXIF and ICC profile data) from the source image to the output
##  image.
const
  TJXOPT_COPYNONE* = 64

##  Scaling factor
type
  tjscalingfactor* {.importc: "tjscalingfactor", bycopy.} = object
    num* {.importc: "num".}: cint
    denom* {.importc: "denom".}: cint


##  Cropping region
type
  tjregion* {.importc: "tjregion", bycopy.} = object
    x* {.importc: "x".}: cint 
    ##  The left boundary of the cropping region.  This must be evenly divisible
    ##  by the MCU block width (see #tjMCUWidth.)
    ##  The upper boundary of the cropping region.  This must be evenly divisible
    ##  by the MCU block height (see #tjMCUHeight.)
    y* {.importc: "y".}: cint
    ##  The width of the cropping region. Setting this to 0 is the equivalent of
    ##  setting it to the width of the source JPEG image - x.
    w* {.importc: "w".}: cint
    ##  The height of the cropping region. Setting this to 0 is the equivalent of
    ##  setting it to the height of the source JPEG image - y.
    h* {.importc: "h".}: cint


##  Lossless transform
type
  tjtransform* {.importc: "tjtransform", bycopy.} = object
    r* {.importc: "r".}: tjregion 
    op* {.importc: "op".}: cint ##  The bitwise OR of one of more of the @ref TJXOPT_CROP "transform options"
    options* {.importc: "options".}: cint ##  Arbitrary data that can be accessed within the body of the callback function
    data* {.importc: "data".}: pointer
    ##  A callback function that can be used to modify the DCT coefficients
    ##  after they are losslessly transformed but before they are transcoded to a
    ##  new JPEG image.  This allows for custom filters or other transformations
    ##  to be applied in the frequency domain.
    ##
    ##  @param coeffs pointer to an array of transformed DCT coefficients.  (NOTE:
    ##  this pointer is not guaranteed to be valid once the callback returns, so
    ##  applications wishing to hand off the DCT coefficients to another function
    ##  or library should make a copy of them within the body of the callback.)
    ##
    ##  @param arrayRegion #tjregion structure containing the width and height of
    ##  the array pointed to by <tt>coeffs</tt> as well as its offset relative to
    ##  the component plane.  TurboJPEG implementations may choose to split each
    ##  component plane into multiple DCT coefficient arrays and call the callback
    ##  function once for each array.
    ##
    ##  @param planeRegion #tjregion structure containing the width and height of
    ##  the component plane to which <tt>coeffs</tt> belongs
    ##
    ##  @param componentID ID number of the component plane to which
    ##  <tt>coeffs</tt> belongs (Y, Cb, and Cr have, respectively, ID's of 0, 1,
    ##  and 2 in typical JPEG images.)
    ##
    ##  @param transformID ID number of the transformed image to which
    ##  <tt>coeffs</tt> belongs.  This is the same as the index of the transform
    ##  in the <tt>transforms</tt> array that was passed to #tjTransform().
    ##
    ##  @param transform a pointer to a #tjtransform structure that specifies the
    ##  parameters and/or cropping region for this transform
    ##
    ##  @return 0 if the callback was successful, or -1 if an error occurred.
    customFilter* {.importc: "customFilter".}: proc (coeffs: ptr cshort; 
        arrayRegion: tjregion; planeRegion: tjregion; componentIndex: cint;
        transformIndex: cint; transform: ptr tjtransform): cint


##  TurboJPEG instance handle
type
  tjhandle* = pointer

##  Pad the given width to the nearest 32-bit boundary
template TJPAD*(width: untyped): untyped =
  (((width) + 3) and (not 3))

##  Compute the scaled value of <tt>dimension</tt> using the given scaling
##  factor.  This macro performs the integer equivalent of <tt>ceil(dimension *
##  scalingFactor)</tt>.
template TJSCALED*(dimension, scalingFactor: untyped): untyped =
  ((dimension * scalingFactor.num + scalingFactor.denom - 1) div scalingFactor.denom)

##  Create a TurboJPEG compressor instance.
##
##  @return a handle to the newly-created instance, or NULL if an error
##  occurred (see #tjGetErrorStr2().)
proc tjInitCompress*(): tjhandle {.importc: "tjInitCompress".}

##  Compress an RGB, grayscale, or CMYK image into a JPEG image.
##
##  @param handle a handle to a TurboJPEG compressor or transformer instance
##
##  @param srcBuf pointer to an image buffer containing RGB, grayscale, or
##  CMYK pixels to be compressed
##
##  @param width width (in pixels) of the source image
##
##  @param pitch bytes per line in the source image.  Normally, this should be
##  <tt>width * #tjPixelSize[pixelFormat]</tt> if the image is unpadded, or
##  <tt>#TJPAD(width * #tjPixelSize[pixelFormat])</tt> if each line of the image
##  is padded to the nearest 32-bit boundary, as is the case for Windows
##  bitmaps.  You can also be clever and use this parameter to skip lines, etc.
##  Setting this parameter to 0 is the equivalent of setting it to
##  <tt>width * #tjPixelSize[pixelFormat]</tt>.
##
##  @param height height (in pixels) of the source image
##
##  @param pixelFormat pixel format of the source image (see @ref TJPF
##  "Pixel formats".)
##
##  @param jpegBuf address of a pointer to an image buffer that will receive the
##  JPEG image.  TurboJPEG has the ability to reallocate the JPEG buffer
##  to accommodate the size of the JPEG image.  Thus, you can choose to:
##  -# pre-allocate the JPEG buffer with an arbitrary size using #tjAlloc() and
##  let TurboJPEG grow the buffer as needed,
##  -# set <tt>*jpegBuf</tt> to NULL to tell TurboJPEG to allocate the buffer
##  for you, or
##  -# pre-allocate the buffer to a "worst case" size determined by calling
##  #tjBufSize().  This should ensure that the buffer never has to be
##  re-allocated (setting #TJFLAG_NOREALLOC guarantees that it won't be.)
##  .
##  If you choose option 1, <tt>*jpegSize</tt> should be set to the size of your
##  pre-allocated buffer.  In any case, unless you have set #TJFLAG_NOREALLOC,
##  you should always check <tt>*jpegBuf</tt> upon return from this function, as
##  it may have changed.
##
##  @param jpegSize pointer to an unsigned long variable that holds the size of
##  the JPEG image buffer.  If <tt>*jpegBuf</tt> points to a pre-allocated
##  buffer, then <tt>*jpegSize</tt> should be set to the size of the buffer.
##  Upon return, <tt>*jpegSize</tt> will contain the size of the JPEG image (in
##  bytes.)  If <tt>*jpegBuf</tt> points to a JPEG image buffer that is being
##  reused from a previous call to one of the JPEG compression functions, then
##  <tt>*jpegSize</tt> is ignored.
##
##  @param jpegSubsamp the level of chrominance subsampling to be used when
##  generating the JPEG image (see @ref TJSAMP
##  "Chrominance subsampling options".)
##
##  @param jpegQual the image quality of the generated JPEG image (1 = worst,
##  100 = best)
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjCompress2_Impl(handle: tjhandle; srcBuf: pointer; width, pitch, height: cint, pixelFormat: TJPF, 
                 jpegBuf: ptr ptr UncheckedArray[byte], jpegSize: ptr culong, jpegSubsamp: TJSAMP, jpegQual: cint; flags: cint): cint 
                 {.importc: "tjCompress2".}
                 
type TJQuality* = range[1..100]
proc tjCompress2*(handle: tjhandle, srcBuf: pointer|string|seq[byte|char], width, height: SomeInteger, pixelFormat: TJPF, 
                 jpegBuf: ptr ptr UncheckedArray[byte], jpegSize: var uint, jpegSubsamp: TJSAMP = TJSAMP_444, jpegQual: TJQuality = 80, flags: int = 0, pitch: uint = 0): bool {.discardable, inline.} =
  var srcAddr = when srcBuf is pointer: srcBuf
  elif srcBuf is string: srcBuf[0].unsafeAddr
  else: srcBuf[0].addr
  result = tjCompress2_Impl(handle, srcAddr, width.cint, pitch.cint, height.cint, pixelFormat, jpegBuf, jpegSize.culong.addr, jpegSubsamp, jpegQual.cint, flags.cint) == 0
  
proc tjCompress2*(handle: tjhandle, srcBuf: pointer|string|seq[byte|char], width, height: SomeInteger, pixelFormat: TJPF, 
                 jpegSubsamp: TJSAMP = TJSAMP_444, jpegQual: TJQuality = 80, flags: int32 = 0, pitch: uint = 0): string {.inline.} =
  var
    outputJPGbuffer: ptr UncheckedArray[byte]
    jpegSize: culong
  if tjCompress2(handle, srcBuf, width, height, pixelFormat, outputJPGbuffer.addr, jpegSize, jpegSubsamp, jpegQual, flags.cint, pitch):
    result.setLen(jpegSize)
    copyMem(result[0].addr, outputJPGbuffer[0].addr, jpegSize)

##  Compress a YUV planar image into a JPEG image.
##
##  @param handle a handle to a TurboJPEG compressor or transformer instance
##
##  @param srcBuf pointer to an image buffer containing a YUV planar image to be
##  compressed.  The size of this buffer should match the value returned by
##  #tjBufSizeYUV2() for the given image width, height, padding, and level of
##  chrominance subsampling.  The Y, U (Cb), and V (Cr) image planes should be
##  stored sequentially in the source buffer (refer to @ref YUVnotes
##  "YUV Image Format Notes".)
##
##  @param width width (in pixels) of the source image.  If the width is not an
##  even multiple of the MCU block width (see #tjMCUWidth), then an intermediate
##  buffer copy will be performed within TurboJPEG.
##
##  @param pad the line padding used in the source image.  For instance, if each
##  line in each plane of the YUV image is padded to the nearest multiple of 4
##  bytes, then <tt>pad</tt> should be set to 4.
##
##  @param height height (in pixels) of the source image.  If the height is not
##  an even multiple of the MCU block height (see #tjMCUHeight), then an
##  intermediate buffer copy will be performed within TurboJPEG.
##
##  @param subsamp the level of chrominance subsampling used in the source
##  image (see @ref TJSAMP "Chrominance subsampling options".)
##
##  @param jpegBuf address of a pointer to an image buffer that will receive the
##  JPEG image.  TurboJPEG has the ability to reallocate the JPEG buffer to
##  accommodate the size of the JPEG image.  Thus, you can choose to:
##  -# pre-allocate the JPEG buffer with an arbitrary size using #tjAlloc() and
##  let TurboJPEG grow the buffer as needed,
##  -# set <tt>*jpegBuf</tt> to NULL to tell TurboJPEG to allocate the buffer
##  for you, or
##  -# pre-allocate the buffer to a "worst case" size determined by calling
##  #tjBufSize().  This should ensure that the buffer never has to be
##  re-allocated (setting #TJFLAG_NOREALLOC guarantees that it won't be.)
##  .
##  If you choose option 1, <tt>*jpegSize</tt> should be set to the size of your
##  pre-allocated buffer.  In any case, unless you have set #TJFLAG_NOREALLOC,
##  you should always check <tt>*jpegBuf</tt> upon return from this function, as
##  it may have changed.
##
##  @param jpegSize pointer to an unsigned long variable that holds the size of
##  the JPEG image buffer.  If <tt>*jpegBuf</tt> points to a pre-allocated
##  buffer, then <tt>*jpegSize</tt> should be set to the size of the buffer.
##  Upon return, <tt>*jpegSize</tt> will contain the size of the JPEG image (in
##  bytes.)  If <tt>*jpegBuf</tt> points to a JPEG image buffer that is being
##  reused from a previous call to one of the JPEG compression functions, then
##  <tt>*jpegSize</tt> is ignored.
##
##  @param jpegQual the image quality of the generated JPEG image (1 = worst,
##  100 = best)
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjCompressFromYUV*(handle: tjhandle; srcBuf: ptr cuchar; width: cint; pad: cint;
                       height: cint; subsamp: cint; jpegBuf: ptr ptr cuchar;
                       jpegSize: ptr culong; jpegQual: cint; flags: cint): cint 
                       {.importc: "tjCompressFromYUV".}

##  Compress a set of Y, U (Cb), and V (Cr) image planes into a JPEG image.
##
##  @param handle a handle to a TurboJPEG compressor or transformer instance
##
##  @param srcPlanes an array of pointers to Y, U (Cb), and V (Cr) image planes
##  (or just a Y plane, if compressing a grayscale image) that contain a YUV
##  image to be compressed.  These planes can be contiguous or non-contiguous in
##  memory.  The size of each plane should match the value returned by
##  #tjPlaneSizeYUV() for the given image width, height, strides, and level of
##  chrominance subsampling.  Refer to @ref YUVnotes "YUV Image Format Notes"
##  for more details.
##
##  @param width width (in pixels) of the source image.  If the width is not an
##  even multiple of the MCU block width (see #tjMCUWidth), then an intermediate
##  buffer copy will be performed within TurboJPEG.
##
##  @param strides an array of integers, each specifying the number of bytes per
##  line in the corresponding plane of the YUV source image.  Setting the stride
##  for any plane to 0 is the same as setting it to the plane width (see
##  @ref YUVnotes "YUV Image Format Notes".)  If <tt>strides</tt> is NULL, then
##  the strides for all planes will be set to their respective plane widths.
##  You can adjust the strides in order to specify an arbitrary amount of line
##  padding in each plane or to create a JPEG image from a subregion of a larger
##  YUV planar image.
##
##  @param height height (in pixels) of the source image.  If the height is not
##  an even multiple of the MCU block height (see #tjMCUHeight), then an
##  intermediate buffer copy will be performed within TurboJPEG.
##
##  @param subsamp the level of chrominance subsampling used in the source
##  image (see @ref TJSAMP "Chrominance subsampling options".)
##
##  @param jpegBuf address of a pointer to an image buffer that will receive the
##  JPEG image.  TurboJPEG has the ability to reallocate the JPEG buffer to
##  accommodate the size of the JPEG image.  Thus, you can choose to:
##  -# pre-allocate the JPEG buffer with an arbitrary size using #tjAlloc() and
##  let TurboJPEG grow the buffer as needed,
##  -# set <tt>*jpegBuf</tt> to NULL to tell TurboJPEG to allocate the buffer
##  for you, or
##  -# pre-allocate the buffer to a "worst case" size determined by calling
##  #tjBufSize().  This should ensure that the buffer never has to be
##  re-allocated (setting #TJFLAG_NOREALLOC guarantees that it won't be.)
##  .
##  If you choose option 1, <tt>*jpegSize</tt> should be set to the size of your
##  pre-allocated buffer.  In any case, unless you have set #TJFLAG_NOREALLOC,
##  you should always check <tt>*jpegBuf</tt> upon return from this function, as
##  it may have changed.
##
##  @param jpegSize pointer to an unsigned long variable that holds the size of
##  the JPEG image buffer.  If <tt>*jpegBuf</tt> points to a pre-allocated
##  buffer, then <tt>*jpegSize</tt> should be set to the size of the buffer.
##  Upon return, <tt>*jpegSize</tt> will contain the size of the JPEG image (in
##  bytes.)  If <tt>*jpegBuf</tt> points to a JPEG image buffer that is being
##  reused from a previous call to one of the JPEG compression functions, then
##  <tt>*jpegSize</tt> is ignored.
##
##  @param jpegQual the image quality of the generated JPEG image (1 = worst,
##  100 = best)
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjCompressFromYUVPlanes*(handle: tjhandle; srcPlanes: ptr ptr cuchar; width: cint;
                             strides: ptr cint; height: cint; subsamp: cint;
                             jpegBuf: ptr ptr cuchar; jpegSize: ptr culong;
                             jpegQual: cint; flags: cint): cint 
                             {.importc: "tjCompressFromYUVPlanes".}

##  The maximum size of the buffer (in bytes) required to hold a JPEG image with
##  the given parameters.  The number of bytes returned by this function is
##  larger than the size of the uncompressed source image.  The reason for this
##  is that the JPEG format uses 16-bit coefficients, and it is thus possible
##  for a very high-quality JPEG image with very high-frequency content to
##  expand rather than compress when converted to the JPEG format.  Such images
##  represent a very rare corner case, but since there is no way to predict the
##  size of a JPEG image prior to compression, the corner case has to be
##  handled.
##
##  @param width width (in pixels) of the image
##
##  @param height height (in pixels) of the image
##
##  @param jpegSubsamp the level of chrominance subsampling to be used when
##  generating the JPEG image (see @ref TJSAMP
##  "Chrominance subsampling options".)
##
##  @return the maximum size of the buffer (in bytes) required to hold the
##  image, or -1 if the arguments are out of bounds.
proc tjBufSize*(width: cint; height: cint; jpegSubsamp: cint): culong {.importc: "tjBufSize".}

##  The size of the buffer (in bytes) required to hold a YUV planar image with
##  the given parameters.
##
##  @param width width (in pixels) of the image
##
##  @param pad the width of each line in each plane of the image is padded to
##  the nearest multiple of this number of bytes (must be a power of 2.)
##
##  @param height height (in pixels) of the image
##
##  @param subsamp level of chrominance subsampling in the image (see
##  @ref TJSAMP "Chrominance subsampling options".)
##
##  @return the size of the buffer (in bytes) required to hold the image, or
##  -1 if the arguments are out of bounds.
proc tjBufSizeYUV2*(width: cint; pad: cint; height: cint; subsamp: cint): culong {.importc: "tjBufSizeYUV2".}

##  The size of the buffer (in bytes) required to hold a YUV image plane with
##  the given parameters.
##
##  @param componentID ID number of the image plane (0 = Y, 1 = U/Cb, 2 = V/Cr)
##
##  @param width width (in pixels) of the YUV image.  NOTE: this is the width of
##  the whole image, not the plane width.
##
##  @param stride bytes per line in the image plane.  Setting this to 0 is the
##  equivalent of setting it to the plane width.
##
##  @param height height (in pixels) of the YUV image.  NOTE: this is the height
##  of the whole image, not the plane height.
##
##  @param subsamp level of chrominance subsampling in the image (see
##  @ref TJSAMP "Chrominance subsampling options".)
##
##  @return the size of the buffer (in bytes) required to hold the YUV image
##  plane, or -1 if the arguments are out of bounds.
proc tjPlaneSizeYUV*(componentID: cint; width: cint; stride: cint; height: cint; subsamp: cint): culong {.importc: "tjPlaneSizeYUV".}

##  The plane width of a YUV image plane with the given parameters.  Refer to
##  @ref YUVnotes "YUV Image Format Notes" for a description of plane width.
##
##  @param componentID ID number of the image plane (0 = Y, 1 = U/Cb, 2 = V/Cr)
##
##  @param width width (in pixels) of the YUV image
##
##  @param subsamp level of chrominance subsampling in the image (see
##  @ref TJSAMP "Chrominance subsampling options".)
##
##  @return the plane width of a YUV image plane with the given parameters, or
##  -1 if the arguments are out of bounds.
proc tjPlaneWidth*(componentID: cint; width: cint; subsamp: cint): cint {.importc: "tjPlaneWidth".}

##  The plane height of a YUV image plane with the given parameters.  Refer to
##  @ref YUVnotes "YUV Image Format Notes" for a description of plane height.
##
##  @param componentID ID number of the image plane (0 = Y, 1 = U/Cb, 2 = V/Cr)
##
##  @param height height (in pixels) of the YUV image
##
##  @param subsamp level of chrominance subsampling in the image (see
##  @ref TJSAMP "Chrominance subsampling options".)
##
##  @return the plane height of a YUV image plane with the given parameters, or
##  -1 if the arguments are out of bounds.
proc tjPlaneHeight*(componentID: cint; height: cint; subsamp: cint): cint {.importc: "tjPlaneHeight".}

##  Encode an RGB or grayscale image into a YUV planar image.  This function
##  uses the accelerated color conversion routines in the underlying
##  codec but does not execute any of the other steps in the JPEG compression
##  process.
##
##  @param handle a handle to a TurboJPEG compressor or transformer instance
##
##  @param srcBuf pointer to an image buffer containing RGB or grayscale pixels
##  to be encoded
##
##  @param width width (in pixels) of the source image
##
##  @param pitch bytes per line in the source image.  Normally, this should be
##  <tt>width * #tjPixelSize[pixelFormat]</tt> if the image is unpadded, or
##  <tt>#TJPAD(width * #tjPixelSize[pixelFormat])</tt> if each line of the image
##  is padded to the nearest 32-bit boundary, as is the case for Windows
##  bitmaps.  You can also be clever and use this parameter to skip lines, etc.
##  Setting this parameter to 0 is the equivalent of setting it to
##  <tt>width * #tjPixelSize[pixelFormat]</tt>.
##
##  @param height height (in pixels) of the source image
##
##  @param pixelFormat pixel format of the source image (see @ref TJPF
##  "Pixel formats".)
##
##  @param dstBuf pointer to an image buffer that will receive the YUV image.
##  Use #tjBufSizeYUV2() to determine the appropriate size for this buffer based
##  on the image width, height, padding, and level of chrominance subsampling.
##  The Y, U (Cb), and V (Cr) image planes will be stored sequentially in the
##  buffer (refer to @ref YUVnotes "YUV Image Format Notes".)
##
##  @param pad the width of each line in each plane of the YUV image will be
##  padded to the nearest multiple of this number of bytes (must be a power of
##  2.)  To generate images suitable for X Video, <tt>pad</tt> should be set to
##  4.
##
##  @param subsamp the level of chrominance subsampling to be used when
##  generating the YUV image (see @ref TJSAMP
##  "Chrominance subsampling options".)  To generate images suitable for X
##  Video, <tt>subsamp</tt> should be set to @ref TJSAMP_420.  This produces an
##  image compatible with the I420 (AKA "YUV420P") format.
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjEncodeYUV3_Impl(handle: tjhandle; srcBuf: pointer; width: cint; pitch: cint;
                  height: cint; pixelFormat: TJPF; dstBuf: pointer; pad: cint;
                  subsamp: cint; flags: cint): cint {.importc: "tjEncodeYUV3".}
                  
proc tjEncodeYUV3*(handle: tjhandle, srcBuf: pointer, width, pitch, height: SomeInteger, pixelFormat: TJPF; dstBuf: pointer, pad, subsamp, flags: SomeInteger): int {.inline.} =
  result = tjEncodeYUV3_Impl(handle, srcBuf, width.cint, pitch.cint, height.cint, pixelFormat, dstBuf, pad.cint, subsamp.cint, flags.cint).int


##  Encode an RGB or grayscale image into separate Y, U (Cb), and V (Cr) image
##  planes.  This function uses the accelerated color conversion routines in the
##  underlying codec but does not execute any of the other steps in the JPEG
##  compression process.
##
##  @param handle a handle to a TurboJPEG compressor or transformer instance
##
##  @param srcBuf pointer to an image buffer containing RGB or grayscale pixels
##  to be encoded
##
##  @param width width (in pixels) of the source image
##
##  @param pitch bytes per line in the source image.  Normally, this should be
##  <tt>width * #tjPixelSize[pixelFormat]</tt> if the image is unpadded, or
##  <tt>#TJPAD(width * #tjPixelSize[pixelFormat])</tt> if each line of the image
##  is padded to the nearest 32-bit boundary, as is the case for Windows
##  bitmaps.  You can also be clever and use this parameter to skip lines, etc.
##  Setting this parameter to 0 is the equivalent of setting it to
##  <tt>width * #tjPixelSize[pixelFormat]</tt>.
##
##  @param height height (in pixels) of the source image
##
##  @param pixelFormat pixel format of the source image (see @ref TJPF
##  "Pixel formats".)
##
##  @param dstPlanes an array of pointers to Y, U (Cb), and V (Cr) image planes
##  (or just a Y plane, if generating a grayscale image) that will receive the
##  encoded image.  These planes can be contiguous or non-contiguous in memory.
##  Use #tjPlaneSizeYUV() to determine the appropriate size for each plane based
##  on the image width, height, strides, and level of chrominance subsampling.
##  Refer to @ref YUVnotes "YUV Image Format Notes" for more details.
##
##  @param strides an array of integers, each specifying the number of bytes per
##  line in the corresponding plane of the output image.  Setting the stride for
##  any plane to 0 is the same as setting it to the plane width (see
##  @ref YUVnotes "YUV Image Format Notes".)  If <tt>strides</tt> is NULL, then
##  the strides for all planes will be set to their respective plane widths.
##  You can adjust the strides in order to add an arbitrary amount of line
##  padding to each plane or to encode an RGB or grayscale image into a
##  subregion of a larger YUV planar image.
##
##  @param subsamp the level of chrominance subsampling to be used when
##  generating the YUV image (see @ref TJSAMP
##  "Chrominance subsampling options".)  To generate images suitable for X
##  Video, <tt>subsamp</tt> should be set to @ref TJSAMP_420.  This produces an
##  image compatible with the I420 (AKA "YUV420P") format.
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjEncodeYUVPlanes_Impl(handle: tjhandle; srcBuf: pointer; width: cint; pitch: cint;
                       height: cint; pixelFormat: TJPF; dstPlanes: ptr pointer;
                       strides: ptr cint; subsamp: cint; flags: cint): cint 
                       {.importc: "tjEncodeYUVPlanes".}

proc tjEncodeYUVPlanes*(handle: tjhandle; srcBuf: pointer; width, pitch, height: int, pixelFormat: TJPF, dstPlanes: ptr pointer,
                       strides: var int, subsamp, flags: int): int {.inline.} =
  var strd: cint
  result = tjEncodeYUVPlanes_Impl(handle, srcBuf, width.cint, pitch.cint, height.cint, pixelFormat, dstPlanes, strd.addr, subsamp.cint, flags.cint).int
  strides = strd.int

##  Create a TurboJPEG decompressor instance.
##
##  @return a handle to the newly-created instance, or NULL if an error
##  occurred (see #tjGetErrorStr2().)
proc tjInitDecompress*(): tjhandle {.importc: "tjInitDecompress".}

##  Retrieve information about a JPEG image without decompressing it.
##
##  @param handle a handle to a TurboJPEG decompressor or transformer instance
##
##  @param jpegBuf pointer to a buffer containing a JPEG image
##
##  @param jpegSize size of the JPEG image (in bytes)
##
##  @param width pointer to an integer variable that will receive the width (in
##  pixels) of the JPEG image
##
##  @param height pointer to an integer variable that will receive the height
##  (in pixels) of the JPEG image
##
##  @param jpegSubsamp pointer to an integer variable that will receive the
##  level of chrominance subsampling used when the JPEG image was compressed
##  (see @ref TJSAMP "Chrominance subsampling options".)
##
##  @param jpegColorspace pointer to an integer variable that will receive one
##  of the JPEG colorspace constants, indicating the colorspace of the JPEG
##  image (see @ref TJCS "JPEG colorspaces".)
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjDecompressHeader3_Impl(handle: tjhandle; jpegBuf: pointer; jpegSize: culong;
                         width: ptr cint; height: ptr cint; jpegSubsamp: ptr cint;
                         jpegColorspace: ptr cint): cint 
                         {.importc: "tjDecompressHeader3".}

proc tjDecompressHeader3*(handle: tjhandle, jpegBuf: pointer, jpegSize: SomeInteger,
                         width, height: var int32, jpegSubsamp: var TJSAMP, jpegColorspace: var TJCS): bool {.inline, discardable.} =
  var colSp, samp: int32
  result = tjDecompressHeader3_Impl(handle, jpegBuf, jpegSize.culong, width.addr, height.addr, samp.addr, colSp.addr) == 0
  jpegColorspace = colSp.TJCS
  jpegSubsamp = samp.TJSAMP
proc tjDecompressHeader3*(handle: tjhandle, jpegBuf: seq[char|uint8] | string,
                         width, height: var int32, jpegSubsamp: var TJSAMP, jpegColorspace: var TJCS): bool {.inline, discardable.} =
  var colSp, samp: int32
  when jpegBuf is string:
    var buffAddr = jpegBuf[0].unsafeAddr
  else:
    var buffAddr = jpegBuf[0].addr
  result = tjDecompressHeader3_Impl(handle, buffAddr, jpegBuf.len.culong, width.addr, height.addr, samp.addr, colSp.addr) == 0
  jpegColorspace = colSp.TJCS
  jpegSubsamp = samp.TJSAMP

##  Returns a list of fractional scaling factors that the JPEG decompressor in
##  this implementation of TurboJPEG supports.
##
##  @param numscalingfactors pointer to an integer variable that will receive
##  the number of elements in the list
##
##  @return a pointer to a list of fractional scaling factors, or NULL if an
##  error is encountered (see #tjGetErrorStr2().)
proc tjGetScalingFactors*(numscalingfactors: ptr cint): ptr tjscalingfactor {.importc: "tjGetScalingFactors".}

##  Decompress a JPEG image to an RGB, grayscale, or CMYK image.
##
##  @param handle a handle to a TurboJPEG decompressor or transformer instance
##
##  @param jpegBuf pointer to a buffer containing the JPEG image to decompress
##
##  @param jpegSize size of the JPEG image (in bytes)
##
##  @param dstBuf pointer to an image buffer that will receive the decompressed
##  image.  This buffer should normally be <tt>pitch * scaledHeight</tt> bytes
##  in size, where <tt>scaledHeight</tt> can be determined by calling
##  #TJSCALED() with the JPEG image height and one of the scaling factors
##  returned by #tjGetScalingFactors().  The <tt>dstBuf</tt> pointer may also be
##  used to decompress into a specific region of a larger buffer.
##
##  @param width desired width (in pixels) of the destination image.  If this is
##  different than the width of the JPEG image being decompressed, then
##  TurboJPEG will use scaling in the JPEG decompressor to generate the largest
##  possible image that will fit within the desired width.  If <tt>width</tt> is
##  set to 0, then only the height will be considered when determining the
##  scaled image size.
##
##  @param pitch bytes per line in the destination image.  Normally, this is
##  <tt>scaledWidth * #tjPixelSize[pixelFormat]</tt> if the decompressed image
##  is unpadded, else <tt>#TJPAD(scaledWidth * #tjPixelSize[pixelFormat])</tt>
##  if each line of the decompressed image is padded to the nearest 32-bit
##  boundary, as is the case for Windows bitmaps.  (NOTE: <tt>scaledWidth</tt>
##  can be determined by calling #TJSCALED() with the JPEG image width and one
##  of the scaling factors returned by #tjGetScalingFactors().)  You can also be
##  clever and use the pitch parameter to skip lines, etc.  Setting this
##  parameter to 0 is the equivalent of setting it to
##  <tt>scaledWidth * #tjPixelSize[pixelFormat]</tt>.
##
##  @param height desired height (in pixels) of the destination image.  If this
##  is different than the height of the JPEG image being decompressed, then
##  TurboJPEG will use scaling in the JPEG decompressor to generate the largest
##  possible image that will fit within the desired height.  If <tt>height</tt>
##  is set to 0, then only the width will be considered when determining the
##  scaled image size.
##
##  @param pixelFormat pixel format of the destination image (see @ref
##  TJPF "Pixel formats".)
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjDecompress2_Impl(handle: tjhandle; jpegBuf: pointer; jpegSize: culong;
                   dstBuf: pointer; width: cint; pitch: cint; height: cint; pixelFormat: TJPF; flags: cint): cint 
                   {.importc: "tjDecompress2".}

proc tjDecompress2*(handle: tjhandle, jpegBuf: pointer, jpegSize: SomeInteger,
                   dstBuf: pointer, width, height: SomeInteger, pixelFormat: TJPF = TJPF_RGB, flags: int32 = 0, pitch: int32 = 0): bool {.discardable, inline.} =
  # FLAGS:
  #   TJFLAG_BOTTOMUP* = 2, TJFLAG_FASTUPSAMPLE* = 256, TJFLAG_NOREALLOC* = 1024, TJFLAG_FASTDCT* = 2048
  #   TJFLAG_ACCURATEDCT* = 4096, TJFLAG_STOPONWARNING* = 8192, TJFLAG_PROGRESSIVE
  result = tjDecompress2_Impl(handle, jpegBuf, jpegSize.culong, dstBuf, width.cint, pitch.cint, height.cint, pixelFormat, flags) == 0
proc tjDecompress2*(handle: tjhandle, jpegBuf: seq[char|uint8|byte] | string,
                   dstBuf: seq[byte|char]|string|pointer, width, height: SomeInteger, pixelFormat: TJPF = TJPF_RGB, flags: int32 = 0, pitch: int32 = 0): bool {.discardable, inline.} =
  # FLAGS:
  #   TJFLAG_BOTTOMUP* = 2, TJFLAG_FASTUPSAMPLE* = 256, TJFLAG_NOREALLOC* = 1024, TJFLAG_FASTDCT* = 2048
  #   TJFLAG_ACCURATEDCT* = 4096, TJFLAG_STOPONWARNING* = 8192, TJFLAG_PROGRESSIVE
  var srcAddr = when jpegBuf is string: jpegBuf[0].unsafeAddr
  else: jpegBuf[0].addr

  var dstAddr = when dstBuf is pointer: dstBuf
  elif dstBuf is string: dstBuf[0].unsafeAddr
  else: dstBuf[0].unsafeAddr
  result = tjDecompress2_Impl(handle, srcAddr, jpegBuf.len.culong, dstAddr, width.cint, pitch.cint, height.cint, pixelFormat, flags) == 0



##  Decompress a JPEG image to a YUV planar image.  This function performs JPEG
##  decompression but leaves out the color conversion step, so a planar YUV
##  image is generated instead of an RGB image.
##
##  @param handle a handle to a TurboJPEG decompressor or transformer instance
##
##  @param jpegBuf pointer to a buffer containing the JPEG image to decompress
##
##  @param jpegSize size of the JPEG image (in bytes)
##
##  @param dstBuf pointer to an image buffer that will receive the YUV image.
##  Use #tjBufSizeYUV2() to determine the appropriate size for this buffer based
##  on the image width, height, padding, and level of subsampling.  The Y,
##  U (Cb), and V (Cr) image planes will be stored sequentially in the buffer
##  (refer to @ref YUVnotes "YUV Image Format Notes".)
##
##  @param width desired width (in pixels) of the YUV image.  If this is
##  different than the width of the JPEG image being decompressed, then
##  TurboJPEG will use scaling in the JPEG decompressor to generate the largest
##  possible image that will fit within the desired width.  If <tt>width</tt> is
##  set to 0, then only the height will be considered when determining the
##  scaled image size.  If the scaled width is not an even multiple of the MCU
##  block width (see #tjMCUWidth), then an intermediate buffer copy will be
##  performed within TurboJPEG.
##
##  @param pad the width of each line in each plane of the YUV image will be
##  padded to the nearest multiple of this number of bytes (must be a power of
##  2.)  To generate images suitable for X Video, <tt>pad</tt> should be set to
##  4.
##
##  @param height desired height (in pixels) of the YUV image.  If this is
##  different than the height of the JPEG image being decompressed, then
##  TurboJPEG will use scaling in the JPEG decompressor to generate the largest
##  possible image that will fit within the desired height.  If <tt>height</tt>
##  is set to 0, then only the width will be considered when determining the
##  scaled image size.  If the scaled height is not an even multiple of the MCU
##  block height (see #tjMCUHeight), then an intermediate buffer copy will be
##  performed within TurboJPEG.
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjDecompressToYUV2*(handle: tjhandle; jpegBuf: ptr cuchar; jpegSize: culong;
                        dstBuf: ptr cuchar; width: cint; pad: cint; height: cint;
                        flags: cint): cint 
                        {.importc: "tjDecompressToYUV2".}

##  Decompress a JPEG image into separate Y, U (Cb), and V (Cr) image
##  planes.  This function performs JPEG decompression but leaves out the color
##  conversion step, so a planar YUV image is generated instead of an RGB image.
##
##  @param handle a handle to a TurboJPEG decompressor or transformer instance
##
##  @param jpegBuf pointer to a buffer containing the JPEG image to decompress
##
##  @param jpegSize size of the JPEG image (in bytes)
##
##  @param dstPlanes an array of pointers to Y, U (Cb), and V (Cr) image planes
##  (or just a Y plane, if decompressing a grayscale image) that will receive
##  the YUV image.  These planes can be contiguous or non-contiguous in memory.
##  Use #tjPlaneSizeYUV() to determine the appropriate size for each plane based
##  on the scaled image width, scaled image height, strides, and level of
##  chrominance subsampling.  Refer to @ref YUVnotes "YUV Image Format Notes"
##  for more details.
##
##  @param width desired width (in pixels) of the YUV image.  If this is
##  different than the width of the JPEG image being decompressed, then
##  TurboJPEG will use scaling in the JPEG decompressor to generate the largest
##  possible image that will fit within the desired width.  If <tt>width</tt> is
##  set to 0, then only the height will be considered when determining the
##  scaled image size.  If the scaled width is not an even multiple of the MCU
##  block width (see #tjMCUWidth), then an intermediate buffer copy will be
##  performed within TurboJPEG.
##
##  @param strides an array of integers, each specifying the number of bytes per
##  line in the corresponding plane of the output image.  Setting the stride for
##  any plane to 0 is the same as setting it to the scaled plane width (see
##  @ref YUVnotes "YUV Image Format Notes".)  If <tt>strides</tt> is NULL, then
##  the strides for all planes will be set to their respective scaled plane
##  widths.  You can adjust the strides in order to add an arbitrary amount of
##  line padding to each plane or to decompress the JPEG image into a subregion
##  of a larger YUV planar image.
##
##  @param height desired height (in pixels) of the YUV image.  If this is
##  different than the height of the JPEG image being decompressed, then
##  TurboJPEG will use scaling in the JPEG decompressor to generate the largest
##  possible image that will fit within the desired height.  If <tt>height</tt>
##  is set to 0, then only the width will be considered when determining the
##  scaled image size.  If the scaled height is not an even multiple of the MCU
##  block height (see #tjMCUHeight), then an intermediate buffer copy will be
##  performed within TurboJPEG.
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjDecompressToYUVPlanes*(handle: tjhandle; jpegBuf: ptr cuchar; jpegSize: culong;
                             dstPlanes: ptr ptr cuchar; width: cint;
                             strides: ptr cint; height: cint; flags: cint): cint 
                             {.importc: "tjDecompressToYUVPlanes".}

##  Decode a YUV planar image into an RGB or grayscale image.  This function
##  uses the accelerated color conversion routines in the underlying
##  codec but does not execute any of the other steps in the JPEG decompression
##  process.
##
##  @param handle a handle to a TurboJPEG decompressor or transformer instance
##
##  @param srcBuf pointer to an image buffer containing a YUV planar image to be
##  decoded.  The size of this buffer should match the value returned by
##  #tjBufSizeYUV2() for the given image width, height, padding, and level of
##  chrominance subsampling.  The Y, U (Cb), and V (Cr) image planes should be
##  stored sequentially in the source buffer (refer to @ref YUVnotes
##  "YUV Image Format Notes".)
##
##  @param pad Use this parameter to specify that the width of each line in each
##  plane of the YUV source image is padded to the nearest multiple of this
##  number of bytes (must be a power of 2.)
##
##  @param subsamp the level of chrominance subsampling used in the YUV source
##  image (see @ref TJSAMP "Chrominance subsampling options".)
##
##  @param dstBuf pointer to an image buffer that will receive the decoded
##  image.  This buffer should normally be <tt>pitch * height</tt> bytes in
##  size, but the <tt>dstBuf</tt> pointer can also be used to decode into a
##  specific region of a larger buffer.
##
##  @param width width (in pixels) of the source and destination images
##
##  @param pitch bytes per line in the destination image.  Normally, this should
##  be <tt>width * #tjPixelSize[pixelFormat]</tt> if the destination image is
##  unpadded, or <tt>#TJPAD(width * #tjPixelSize[pixelFormat])</tt> if each line
##  of the destination image should be padded to the nearest 32-bit boundary, as
##  is the case for Windows bitmaps.  You can also be clever and use the pitch
##  parameter to skip lines, etc.  Setting this parameter to 0 is the equivalent
##  of setting it to <tt>width * #tjPixelSize[pixelFormat]</tt>.
##
##  @param height height (in pixels) of the source and destination images
##
##  @param pixelFormat pixel format of the destination image (see @ref TJPF
##  "Pixel formats".)
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjDecodeYUV*(handle: tjhandle; srcBuf: ptr cuchar; pad: cint; subsamp: cint;
                 dstBuf: ptr cuchar; width: cint; pitch: cint; height: cint;
                 pixelFormat: cint; flags: cint): cint 
                 {.importc: "tjDecodeYUV".}

##  Decode a set of Y, U (Cb), and V (Cr) image planes into an RGB or grayscale
##  image.  This function uses the accelerated color conversion routines in the
##  underlying codec but does not execute any of the other steps in the JPEG
##  decompression process.
##
##  @param handle a handle to a TurboJPEG decompressor or transformer instance
##
##  @param srcPlanes an array of pointers to Y, U (Cb), and V (Cr) image planes
##  (or just a Y plane, if decoding a grayscale image) that contain a YUV image
##  to be decoded.  These planes can be contiguous or non-contiguous in memory.
##  The size of each plane should match the value returned by #tjPlaneSizeYUV()
##  for the given image width, height, strides, and level of chrominance
##  subsampling.  Refer to @ref YUVnotes "YUV Image Format Notes" for more
##  details.
##
##  @param strides an array of integers, each specifying the number of bytes per
##  line in the corresponding plane of the YUV source image.  Setting the stride
##  for any plane to 0 is the same as setting it to the plane width (see
##  @ref YUVnotes "YUV Image Format Notes".)  If <tt>strides</tt> is NULL, then
##  the strides for all planes will be set to their respective plane widths.
##  You can adjust the strides in order to specify an arbitrary amount of line
##  padding in each plane or to decode a subregion of a larger YUV planar image.
##
##  @param subsamp the level of chrominance subsampling used in the YUV source
##  image (see @ref TJSAMP "Chrominance subsampling options".)
##
##  @param dstBuf pointer to an image buffer that will receive the decoded
##  image.  This buffer should normally be <tt>pitch * height</tt> bytes in
##  size, but the <tt>dstBuf</tt> pointer can also be used to decode into a
##  specific region of a larger buffer.
##
##  @param width width (in pixels) of the source and destination images
##
##  @param pitch bytes per line in the destination image.  Normally, this should
##  be <tt>width * #tjPixelSize[pixelFormat]</tt> if the destination image is
##  unpadded, or <tt>#TJPAD(width * #tjPixelSize[pixelFormat])</tt> if each line
##  of the destination image should be padded to the nearest 32-bit boundary, as
##  is the case for Windows bitmaps.  You can also be clever and use the pitch
##  parameter to skip lines, etc.  Setting this parameter to 0 is the equivalent
##  of setting it to <tt>width * #tjPixelSize[pixelFormat]</tt>.
##
##  @param height height (in pixels) of the source and destination images
##
##  @param pixelFormat pixel format of the destination image (see @ref TJPF
##  "Pixel formats".)
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjDecodeYUVPlanes*(handle: tjhandle; srcPlanes: ptr ptr cuchar; strides: ptr cint;
                       subsamp: cint; dstBuf: ptr cuchar; width: cint; pitch: cint;
                       height: cint; pixelFormat: cint; flags: cint): cint 
                       {.importc: "tjDecodeYUVPlanes".}

##  Create a new TurboJPEG transformer instance.
##
##  @return a handle to the newly-created instance, or NULL if an error
##  occurred (see #tjGetErrorStr2().)
proc tjInitTransform*(): tjhandle {.importc: "tjInitTransform".}

##  Losslessly transform a JPEG image into another JPEG image.  Lossless
##  transforms work by moving the raw DCT coefficients from one JPEG image
##  structure to another without altering the values of the coefficients.  While
##  this is typically faster than decompressing the image, transforming it, and
##  re-compressing it, lossless transforms are not free.  Each lossless
##  transform requires reading and performing Huffman decoding on all of the
##  coefficients in the source image, regardless of the size of the destination
##  image.  Thus, this function provides a means of generating multiple
##  transformed images from the same source or  applying multiple
##  transformations simultaneously, in order to eliminate the need to read the
##  source coefficients multiple times.
##
##  @param handle a handle to a TurboJPEG transformer instance
##
##  @param jpegBuf pointer to a buffer containing the JPEG source image to
##  transform
##
##  @param jpegSize size of the JPEG source image (in bytes)
##
##  @param n the number of transformed JPEG images to generate
##
##  @param dstBufs pointer to an array of n image buffers.  <tt>dstBufs[i]</tt>
##  will receive a JPEG image that has been transformed using the parameters in
##  <tt>transforms[i]</tt>.  TurboJPEG has the ability to reallocate the JPEG
##  buffer to accommodate the size of the JPEG image.  Thus, you can choose to:
##  -# pre-allocate the JPEG buffer with an arbitrary size using #tjAlloc() and
##  let TurboJPEG grow the buffer as needed,
##  -# set <tt>dstBufs[i]</tt> to NULL to tell TurboJPEG to allocate the buffer
##  for you, or
##  -# pre-allocate the buffer to a "worst case" size determined by calling
##  #tjBufSize() with the transformed or cropped width and height.  Under normal
##  circumstances, this should ensure that the buffer never has to be
##  re-allocated (setting #TJFLAG_NOREALLOC guarantees that it won't be.)  Note,
##  however, that there are some rare cases (such as transforming images with a
##  large amount of embedded EXIF or ICC profile data) in which the output image
##  will be larger than the worst-case size, and #TJFLAG_NOREALLOC cannot be
##  used in those cases.
##  .
##  If you choose option 1, <tt>dstSizes[i]</tt> should be set to the size of
##  your pre-allocated buffer.  In any case, unless you have set
##  #TJFLAG_NOREALLOC, you should always check <tt>dstBufs[i]</tt> upon return
##  from this function, as it may have changed.
##
##  @param dstSizes pointer to an array of n unsigned long variables that will
##  receive the actual sizes (in bytes) of each transformed JPEG image.  If
##  <tt>dstBufs[i]</tt> points to a pre-allocated buffer, then
##  <tt>dstSizes[i]</tt> should be set to the size of the buffer.  Upon return,
##  <tt>dstSizes[i]</tt> will contain the size of the JPEG image (in bytes.)
##
##  @param transforms pointer to an array of n #tjtransform structures, each of
##  which specifies the transform parameters and/or cropping region for the
##  corresponding transformed output image.
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_ACCURATEDCT
##  "flags"
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2()
##  and #tjGetErrorCode().)
proc tjTransformProc*(handle: tjhandle; jpegBuf: ptr cuchar; jpegSize: culong; n: cint;
                 dstBufs: ptr ptr cuchar; dstSizes: ptr culong;
                 transforms: ptr tjtransform; flags: cint): cint {.importc: "tjTransform".}

##  Destroy a TurboJPEG compressor, decompressor, or transformer instance.
##
##  @param handle a handle to a TurboJPEG compressor, decompressor or
##  transformer instance
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2().)
proc tjDestroy*(handle: tjhandle): cint {.importc: "tjDestroy",discardable.}

##  Allocate an image buffer for use with TurboJPEG.  You should always use
##  this function to allocate the JPEG destination buffer(s) for the compression
##  and transform functions unless you are disabling automatic buffer
##  (re)allocation (by setting #TJFLAG_NOREALLOC.)
##
##  @param bytes the number of bytes to allocate
##
##  @return a pointer to a newly-allocated buffer with the specified number of
##  bytes.
##
##  @sa tjFree()
proc tjAlloc*(bytes: cint): ptr cuchar {.importc: "tjAlloc".}

##  Load an uncompressed image from disk into memory.
##
##  @param filename name of a file containing an uncompressed image in Windows
##  BMP or PBMPLUS (PPM/PGM) format
##
##  @param width pointer to an integer variable that will receive the width (in
##  pixels) of the uncompressed image
##
##  @param align row alignment of the image buffer to be returned (must be a
##  power of 2.)  For instance, setting this parameter to 4 will cause all rows
##  in the image buffer to be padded to the nearest 32-bit boundary, and setting
##  this parameter to 1 will cause all rows in the image buffer to be unpadded.
##
##  @param height pointer to an integer variable that will receive the height
##  (in pixels) of the uncompressed image
##
##  @param pixelFormat pointer to an integer variable that specifies or will
##  receive the pixel format of the uncompressed image buffer.  The behavior of
##  #tjLoadImage() will vary depending on the value of <tt>*pixelFormat</tt>
##  passed to the function:
##  - @ref TJPF_UNKNOWN : The uncompressed image buffer returned by the function
##  will use the most optimal pixel format for the file type, and
##  <tt>*pixelFormat</tt> will contain the ID of this pixel format upon
##  successful return from the function.
##  - @ref TJPF_GRAY : Only PGM files and 8-bit BMP files with a grayscale
##  colormap can be loaded.
##  - @ref TJPF_CMYK : The RGB or grayscale pixels stored in the file will be
##  converted using a quick & dirty algorithm that is suitable only for testing
##  purposes (proper conversion between CMYK and other formats requires a color
##  management system.)
##  - Other @ref TJPF "pixel formats" : The uncompressed image buffer will use
##  the specified pixel format, and pixel format conversion will be performed if
##  necessary.
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_BOTTOMUP
##  "flags".
##
##  @return a pointer to a newly-allocated buffer containing the uncompressed
##  image, converted to the chosen pixel format and with the chosen row
##  alignment, or NULL if an error occurred (see #tjGetErrorStr2().)  This
##  buffer should be freed using #tjFree().
proc tjLoadImage*(filename: cstring; width: ptr cint; align: cint; height: ptr cint;
                 pixelFormat: ptr cint; flags: cint): ptr cuchar {.importc: "tjLoadImage".}

##  Save an uncompressed image from memory to disk.
##
##  @param filename name of a file to which to save the uncompressed image.
##  The image will be stored in Windows BMP or PBMPLUS (PPM/PGM) format,
##  depending on the file extension.
##
##  @param buffer pointer to an image buffer containing RGB, grayscale, or
##  CMYK pixels to be saved
##
##  @param width width (in pixels) of the uncompressed image
##
##  @param pitch bytes per line in the image buffer.  Setting this parameter to
##  0 is the equivalent of setting it to
##  <tt>width * #tjPixelSize[pixelFormat]</tt>.
##
##  @param height height (in pixels) of the uncompressed image
##
##  @param pixelFormat pixel format of the image buffer (see @ref TJPF
##  "Pixel formats".)  If this parameter is set to @ref TJPF_GRAY, then the
##  image will be stored in PGM or 8-bit (indexed color) BMP format.  Otherwise,
##  the image will be stored in PPM or 24-bit BMP format.  If this parameter
##  is set to @ref TJPF_CMYK, then the CMYK pixels will be converted to RGB
##  using a quick & dirty algorithm that is suitable only for testing (proper
##  conversion between CMYK and other formats requires a color management
##  system.)
##
##  @param flags the bitwise OR of one or more of the @ref TJFLAG_BOTTOMUP
##  "flags".
##
##  @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr2().)
proc tjSaveImage*(filename: cstring; buffer: ptr cuchar; width: cint; pitch: cint;
                 height: cint; pixelFormat: cint; flags: cint): cint 
                 {.importc: "tjSaveImage".}

##  Free an image buffer previously allocated by TurboJPEG.  You should always
##  use this function to free JPEG destination buffer(s) that were automatically
##  (re)allocated by the compression and transform functions or that were
##  manually allocated using #tjAlloc().
##
##  @param buffer address of the buffer to free.  If the address is NULL, then
##  this function has no effect.
##
##  @sa tjAlloc()
proc tjFree*(buffer: ptr cuchar) {.importc: "tjFree".}

##  Returns a descriptive error message explaining why the last command failed.
##
##  @param handle a handle to a TurboJPEG compressor, decompressor, or
##  transformer instance, or NULL if the error was generated by a global
##  function (but note that retrieving the error message for a global function
##  is thread-safe only on platforms that support thread-local storage.)
##
##  @return a descriptive error message explaining why the last command failed.
proc tjGetErrorStr2*(handle: tjhandle): cstring 
  {.importc: "tjGetErrorStr2".}

##  Returns a code indicating the severity of the last error.  See
##  @ref TJERR "Error codes".
##
##  @param handle a handle to a TurboJPEG compressor, decompressor or
##  transformer instance
##
##  @return a code indicating the severity of the last error.  See
##  @ref TJERR "Error codes".
proc tjGetErrorCode*(handle: tjhandle): cint 
  {.importc: "tjGetErrorCode".}

##  Deprecated functions and macros
const
  TJFLAG_FORCEMMX* = 8
  TJFLAG_FORCESSE* = 16
  TJFLAG_FORCESSE2* = 32
  TJFLAG_FORCESSE3* = 128


##  Backward compatibility functions and macros (nothing to see here)
const
  NUMSUBOPT* = TJ_NUMSAMP
  TJ_444* = TJSAMP_444
  TJ_422* = TJSAMP_422
  TJ_420* = TJSAMP_420
  TJ_411* = TJSAMP_420
  TJ_GRAYSCALE* = TJSAMP_GRAY
  TJ_BGR* = 1
  TJ_BOTTOMUP* = TJFLAG_BOTTOMUP
  TJ_FORCEMMX* = TJFLAG_FORCEMMX
  TJ_FORCESSE* = TJFLAG_FORCESSE
  TJ_FORCESSE2* = TJFLAG_FORCESSE2
  TJ_ALPHAFIRST* = 64
  TJ_FORCESSE3* = TJFLAG_FORCESSE3
  TJ_FASTUPSAMPLE* = TJFLAG_FASTUPSAMPLE
  TJ_YUV* = 512

proc TJBUFSIZE*(width: cint; height: cint): culong {.importc: "TJBUFSIZE".}
proc TJBUFSIZEYUV*(width: cint; height: cint; jpegSubsamp: cint): culong {. importc: "TJBUFSIZEYUV".}
proc tjBufSizeYUV*(width: cint; height: cint; subsamp: cint): culong {.importc: "tjBufSizeYUV".}

proc tjCompress*(handle: tjhandle; srcBuf: ptr cuchar; width: cint; pitch: cint; 
                height: cint; pixelSize: cint; dstBuf: ptr cuchar;
                compressedSize: ptr culong; jpegSubsamp: cint; jpegQual: cint; flags: cint): cint 
                {.importc: "tjCompress".}
proc tjEncodeYUV*(handle: tjhandle; srcBuf: ptr cuchar; width: cint; pitch: cint;
                 height: cint; pixelSize: cint; dstBuf: ptr cuchar; subsamp: cint;
                 flags: cint): cint {.importc: "tjEncodeYUV".}
proc tjEncodeYUV2*(handle: tjhandle; srcBuf: ptr cuchar; width: cint; pitch: cint;
                  height: cint; pixelFormat: cint; dstBuf: ptr cuchar; subsamp: cint;
                  flags: cint): cint {.importc: "tjEncodeYUV2".}

proc tjDecompressHeader*(handle: tjhandle; jpegBuf: ptr cuchar; jpegSize: culong;
                        width: ptr cint; height: ptr cint): cint 
                        {.importc: "tjDecompressHeader".}
proc tjDecompressHeader2*(handle: tjhandle; jpegBuf: ptr cuchar; jpegSize: culong;
                         width: ptr cint; height: ptr cint; jpegSubsamp: ptr cint): cint 
                         {.importc: "tjDecompressHeader2".}

proc tjDecompress*(handle: tjhandle; jpegBuf: ptr cuchar; jpegSize: culong; dstBuf: ptr cuchar; width: cint; 
                  pitch: cint; height: cint; pixelSize: cint; flags: cint): cint 
                  {.importc: "tjDecompress".}
proc tjDecompressToYUV*(handle: tjhandle; jpegBuf: ptr cuchar; jpegSize: culong;
                       dstBuf: ptr cuchar; flags: cint): cint 
                       {.importc: "tjDecompressToYUV".}
proc tjGetErrorStr*(): cstring {.importc: "tjGetErrorStr".}




