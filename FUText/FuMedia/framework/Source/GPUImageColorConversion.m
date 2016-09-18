#import "GPUImageFilter.h"

// Color Conversion Constants (YUV to RGB) including adjustment from 16-235/16-240 (video range)
/*
 YUV色彩模型来源于RGB模型；
 YCbCr模型来源于YUV模型；
 YCbCr是YUV颜色空间的偏移版本；
 H264里面YUV属于YCbCr；
 YUV模型的特点是将亮度和色度分离开，从而适合于图像处理领域；
 YUV格式通常有两大类：打包(packed)格式和平面(planar)格式；
 packed将YUV分量存放在同一个数组中，通常是几个相邻的像素组成一个宏像素(macro-pixel);
 planar使用三个数组分开存放YUV三个分量，就像是一个三维平面。
 */

// BT.601, which is the standard for SDTV.
/*
 YCbCr to RGB color conversion for SDTV:
 | R |    | 1.164   0.000   1.596 |    |  Y - 16  |
 | G | =  | 1.164  -0.392  -0.813 | *  |(Cb - 128)|
 | B |    | 1.164   2.017   0.000 |    |(Cr - 128)|
 Ranges:
     Y[16 ... 235]
 Cb/Cr[16 ... 240]
 R/G/B[0  ... 255]
 */
GLfloat kColorConversion601Default[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
/*
 Full-range YCbCr to RGB color conversion :
 | R |    | 1.000   0.000   14.00 |    |    Y     |
 | G | =  | 1.000  -0.343  -0.711 | *  |(Cb - 128)|
 | B |    | 1.000   1.765   0.000 |    |(Cr - 128)|
 Ranges:
 Y/Cb/Cr[0 ... 255]
   R/G/B[0 ... 255]
 */
GLfloat kColorConversion601FullRangeDefault[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

// BT.709, which is the standard for HDTV.
/*
 YCbCr to RGB color conversion for HDTV:
 | R |    | 1.164   0.000   1.793 |    |  Y - 16  |
 | G | =  | 1.164  -0.213  -0.533 | *  |(Cb - 128)|
 | B |    | 1.164   2.112   0.000 |    |(Cr - 128)|
 Ranges:
     Y[16 ... 235]
 Cb/Cr[16 ... 240]
 R/G/B[0  ... 255]
 */
GLfloat kColorConversion709Default[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};


GLfloat *kColorConversion601 = kColorConversion601Default;
GLfloat *kColorConversion601FullRange = kColorConversion601FullRangeDefault;
GLfloat *kColorConversion709 = kColorConversion709Default;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageYUVVideoRangeConversionForRGFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).rg - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );
#else
NSString *const kGPUImageYUVVideoRangeConversionForRGFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 
 void main()
 {
     vec3 yuv;
     vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).rg - vec2(0.5, 0.5);
     
     // BT.601, which is the standard for SDTV is provided as a reference
     /*
      rgb = mat3(      1,       1,       1,
      0, -.39465, 2.03211,
      1.13983, -.58060,       0) * yuv;
      */
     
     // Using BT.709 which is the standard for HDTV
     rgb = mat3(      1,       1,       1,
                0, -.21482, 2.12798,
                1.28033, -.38059,       0) * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );
#endif

NSString *const kGPUImageYUVFullRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageYUVVideoRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r - (16.0/255.0);
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );
#else
NSString *const kGPUImageYUVVideoRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 
 void main()
 {
     vec3 yuv;
     vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     
     // BT.601, which is the standard for SDTV is provided as a reference
     /*
      rgb = mat3(      1,       1,       1,
      0, -.39465, 2.03211,
      1.13983, -.58060,       0) * yuv;
      */
     
     // Using BT.709 which is the standard for HDTV
     rgb = mat3(      1,       1,       1,
                0, -.21482, 2.12798,
                1.28033, -.38059,       0) * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );
#endif

