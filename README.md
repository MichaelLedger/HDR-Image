# Supporting High Dynamic Range (HDR) images in your app
​
Load, display, edit, check and save HDR images using SwiftUI and Core Image.
​
## Overview

This sample code project shows how to read, write, edit, and display HDR images using SwiftUI, UIKit, 
AppKit, Core Image, and Core Graphics. It loads a film strip of multiple images from on-disk or 
from the Photos library. Then it allows you to select, edit, and save an image in HDR. The sample uses 
several new APIs in various frameworks to correctly handle HDR images in a complete HDR workflow.
​
- Note: This sample code project is associated with WWDC23 session 10181: [Support HDR images in your app](https://developer.apple.com/wwdc23/10181/).
​
## Configure the sample code project

Before you run this sample code project in Xcode, ensure you're using iOS 17 or later for the iOS target, and macOS 14 or later for the Mac target.

## Check if an image is HDR

`CGColorSpace.itur_2100_PQ` & `CGColorSpace.itur_2100_HLG` are belongs to `CGColorSpaceUsesITUR_2100TF`.

```
// For iOS 17+, check if an image is HDR
@available(iOS 17.0, *)
static func isImageHDR(image: UIImage) -> Bool {
    return image.isHighDynamicRange
}

// For iOS 14+ devices, you can check if color space uses ITU-R 2100 transfer functions
@available(iOS 14.0, *)
static func isImageHDRV2(image: UIImage) -> Bool {
    guard let cgImage = image.cgImage else { return false }
    let colorSpace = cgImage.colorSpace
    if let colorSpace = colorSpace {
        if CGColorSpaceUsesITUR_2100TF(colorSpace) {
            // This is an ISO HDR image
            return true
        }
    }
    return false
}
```
​
## Enable HDR on image views

To turn on HDR in the SwiftUI image view, the sample uses the `allowedDynamicRange` modifier in the film strip to show limited HDR headroom. 

``` swift
FilmStrip(assets: $assets, selectedAsset: $selectedAsset)
    .allowedDynamicRange(.constrainedHigh)
    .frame(height: geometry.size.height / 10.0)
```

​For the UIKit main image view, the sample adds the `preferredImageDynamicRange` property to the `UIImageView`.
​
``` swift
let view = UIImageView()
view.preferredImageDynamicRange = .high
```
​
​For AppKit, the sample adds the property to the `NSImageView`.

``` swift
let view = NSImageView()
view.preferredImageDynamicRange = .high
```
​​
​
## Edit HDR using Core Image

To ensure Core Image reads Gain Map HDR images as HDR, the sample sets the `CIImageOption.expandToHDR` property to `true`. To modify the HDR image data, it uses `CIFilter` filters.

``` swift
let ciOptions: [CIImageOption: Any] = [.applyOrientationProperty: true, .expandToHDR: true]
```
​
​The sample saves the image to disk if it's an on-disk file to begin with. The sample uses a `CIContext` and `CGImageDestination` to render a `CIImage` into a `CGImage` and write it to a 10-bit HEIC image file.

``` swift
let cgImage = context.createCGImage(image,
                                    from: image.extent,
                                    format: .RGB10,
                                    colorSpace: colorspace ?? CGColorSpace(name: CGColorSpace.itur_2100_PQ)!,
                                    deferred: true)
```
​
​The sample writes the edited HDR image data back to the Photos library by writing a 10-bit HEIC image to the `renderedContentURL` of a `PHContentEditingOutput` object. The sample only uses this path when an image comes from the Photos library using the `PhotosPicker`.

``` swift
guard let outputURL = try? output.renderedContentURL(for: .heic) else {
    print("Failed to obtain HEIC output URL.")
    return nil
}
```

## ImageMagick: Can identify color profiles and bit depths
```
% identify -verbose IMG_3659.heic

Image:
  Filename: IMG_3659.heic
  Permissions: rw-r--r--
  Format: HEIC (High Efficiency Image Format)
  Mime type: image/heic
  Class: DirectClass
  Geometry: 1290x2796+0+0
  Units: Undefined
  Colorspace: sRGB
  Type: TrueColor
  Base type: Undefined
  Endianness: Undefined
  Depth: 10/16-bit
  Channels: 3.0
  Channel depth:
    Red: 16-bit
    Green: 16-bit
    Blue: 16-bit
  Channel statistics:
    Pixels: 3606840
    Red:
      min: 0  (0)
      max: 606.416 (0.592782)
      mean: 429.263 (0.419612)
      median: 455.562 (0.445319)
      standard deviation: 106.337 (0.103947)
      kurtosis: 0.00931588
      skewness: -0.810252
      entropy: 0.928415
    Green:
      min: 0  (0)
      max: 603.419 (0.589853)
      mean: 416.034 (0.40668)
      median: 438.578 (0.428717)
      standard deviation: 107.135 (0.104727)
      kurtosis: 0.322292
      skewness: -0.820841
      entropy: 0.93522
    Blue:
      min: 0  (0)
      max: 615.408 (0.601572)
      mean: 390.522 (0.381742)
      median: 425.59 (0.416022)
      standard deviation: 128 (0.125122)
      kurtosis: -0.495058
      skewness: -0.671299
      entropy: 0.954439
  Image statistics:
    Overall:
      min: 0  (0)
      max: 615.408 (0.601572)
      mean: 411.939 (0.402678)
      median: 439.91 (0.43002)
      standard deviation: 113.824 (0.111265)
      kurtosis: -0.0544833
      skewness: -0.767464
      entropy: 0.939358
  Rendering intent: Perceptual
  Gamma: 0.454545
  Chromaticity:
    red primary: (0.64,0.33,0.03)
    green primary: (0.3,0.6,0.1)
    blue primary: (0.15,0.06,0.79)
    white point: (0.3127,0.329,0.3583)
  Matte color: grey74
  Background color: white
  Border color: srgb(223,223,223)
  Transparent color: black
  Interlace: None
  Intensity: Undefined
  Compose: Over
  Page geometry: 1290x2796+0+0
  Dispose: Undefined
  Iterations: 0
  Compression: Undefined
  Orientation: TopLeft
  Properties:
    date:create: 2025-05-13T07:19:28+00:00
    date:modify: 2024-10-25T05:25:02+00:00
    date:timestamp: 2025-05-13T08:11:04+00:00
    signature: 9aeca2755f69050a89e08c134f15d4c219f39db0136d44651522e9ca67f3c54c
  Artifacts:
    verbose: true
  Tainted: False
  Filesize: 1.00927MiB
  Number pixels: 3.60684M
  Pixel cache type: Memory
  Pixels per second: 62.3387MP
  User time: 0.150u
  Elapsed time: 0:01.057
  Version: ImageMagick 7.1.1-45 Q16-HDRI aarch64 22722 https://imagemagick.org
```
