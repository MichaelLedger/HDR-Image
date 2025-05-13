//
//  GainMap.swift
//  HDRDemo23
//
//  Created by Gavin Xiang on 5/13/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import UIKit
import MobileCoreServices.UTCoreTypes
import UniformTypeIdentifiers
import Photos
import CoreGraphics

public class GainMapTool: NSObject {
    
    static func fetchGainMap() {
        if #available(iOS 14.1, *) {
            // "IMG_3661" "IMG_8775"
            // "IMG_3659" => CGColorSpace.itur_2100_PQ
            // "IMG_3660" => CGColorSpace.itur_2100_HLG
            let imageName: String = "IMG_3659"
            print("imageName:\(imageName)")
            guard let input = Bundle.main.url(forResource: imageName, withExtension: "heic") else {return}
            
//            guard let imageData = NSData(contentsOf: input) else {return}
//            let hassGainMapHDR = hasGainMapHDR(data: imageData as Data)
//            print("hassGainMapHDR:\(hassGainMapHDR)")
//            guard let image = UIImage(contentsOfFile: input.path) else {return}
            guard let image = loadHDRImage(from: input) else {return}
            let isHDR = isImageHDR(image: image)
            print("isHDR:\(isHDR)")
            let isHDRV2 = isImageHDRV2(image: image)
            print("isHDRV2:\(isHDRV2)")
//            guard let imageData = NSData(contentsOf: input) else {return}
//            let hassGainMapHDR = hasGainMapHDR(data: imageData as Data)
            let hassGainMapHDR = hasGainMapHDR(url: input)
            print("hassGainMapHDR:\(hassGainMapHDR)")
            
            let colorDepth = getImageColorDepth(from: image)
            print("colorDepth:\(colorDepth ?? 0)")
            
            let output = FileManager().temporaryDirectory.appendingPathComponent("\(imageName).GAIN_MAP.BMP")
            guard let source = CGImageSourceCreateWithURL(input as CFURL, nil) else {return}
            
            // urn:com:apple:photo:2020:aux:hdrgainmap
            let auxiliaryDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeHDRGainMap)
            guard let dataInfo = auxiliaryDataInfo as? Dictionary<CFString, Any> else {return}
            guard let data = dataInfo[kCGImageAuxiliaryDataInfoData] as? Data else {return}
            
            guard let description = dataInfo[kCGImageAuxiliaryDataInfoDataDescription] as? [String: Int] else {return}
            guard let width = description["Width"], let height = description["Height"] else {return}
            let size = CGSize(width: width, height: height)
            guard let bytesPerRow = description["BytesPerRow"] else {return}
            let ciImage = CIImage(bitmapData: data, bytesPerRow: bytesPerRow, size: size, format: .L8, colorSpace: nil)
            guard let cgImage = CIContext().createCGImage(ciImage, from: CGRect(origin: CGPoint(x: 0, y: 0), size: size)) else {return}
            
            guard let destRef = CGImageDestinationCreateWithURL(output as CFURL, UTType.bmp as! CFString, 1, nil) else {
                print("Failed to create CGImageDestination.")
                return
            }
            CGImageDestinationAddImage(destRef, cgImage, [:] as CFDictionary)
            CGImageDestinationFinalize(destRef)
            
            print(output)
        }
    }
    
    static func fetchGainMapVersion(_ imageData: NSData?) {
//        let imageName: String = "IMG_3661"
//        guard let input = Bundle.main.url(forResource: imageName, withExtension: "heic") else {return}
//        guard let imageData = NSData(contentsOf: input) else {return}
        guard let imageData = imageData else {return}
        if let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) {
            if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                if let auxiliaryData = properties["AuxiliaryData"] as? [String: Any] {
                    if let version = auxiliaryData["HDRGainMapVersion"] as? String, !version.isEmpty {
                        print("GainMap Version is \(version)")
                    }
                }
            }
        }
    }

    static func saveToAlbum(_ image: UIImage) {
        // Request permission to access the photo library
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("[IPS] Photo library access denied")
                return
            }
            // Save image to photo album
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                if success {
                    print("[IPS] Image saved successfully")
                } else if let error = error {
                    print("[IPS] Error saving image: \(error.localizedDescription)")
                }
            })
        }
    }
    
    // Function to determine an image's color depth
    static func getImageColorDepth(from image: UIImage) -> Int? {
        // Ensure we have a CGImage
        guard let cgImage = image.cgImage else { return nil }
        
        // Get the bits per component
        let bitsPerComponent = cgImage.bitsPerComponent
        // Get color space information
        let colorSpace = cgImage.colorSpace
//        let isHDR = false
        
        // Check if image has HDR color space
        if let colorSpace = colorSpace {
            // For iOS 17+ devices, you can check if color space uses ITU-R 2100 transfer functions
            if #available(iOS 17.0, *) {
                if CGColorSpaceUsesITUR_2100TF(colorSpace) {
                    // This is an ISO HDR image
                    return bitsPerComponent
                }
            }
            
            // Check for Extended color spaces indicating potential HDR
            let colorSpaceName = colorSpace.name
            if colorSpaceName == CGColorSpace.extendedLinearSRGB ||
               colorSpaceName == CGColorSpace.extendedLinearDisplayP3 ||
               colorSpaceName == CGColorSpace.extendedLinearITUR_2020 ||
               colorSpaceName == CGColorSpace.itur_2100_PQ ||
               colorSpaceName == CGColorSpace.itur_2100_HLG {
                return bitsPerComponent
            }
        }
        
        // Get alphaInfo, bitmapInfo for more details if needed
        let alphaInfo = cgImage.alphaInfo
        let bitmapInfo = cgImage.bitmapInfo
        
        return bitsPerComponent
    }
    
    // For iOS 17+, check if an image is HDR
    @available(iOS 17.0, *)
    static func isImageHDR(image: UIImage) -> Bool {
        return image.isHighDynamicRange
    }
    
    // For iOS 17+ devices, you can check if color space uses ITU-R 2100 transfer functions
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
    
    // Function to check if an image has Gain Map HDR
    static func hasGainMapHDR(url: URL) -> Bool {
        // Create an image source from data
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return false
        }
        
        // Check for Gain Map HDR by examining metadata
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return false
        }
        
        // Look for Apple's Gain Map indicators in EXIF data
//        if let exifDict = properties["{Exif}"] as? [String: Any],
//           let headroomValue = exifDict["Headroom"] {
//            return true
//        }
        
        print("properties:\(properties)")
        
        // check profile name in property
        if let profileName = properties["ProfileName"] as? String {
            if profileName == "Rec. ITU-R BT.2100 PQ" {//CGColorSpace.itur_2100_PQ
                return true
            }
        }
        
        // check headroom in property
        if let headroomValue = properties["Headroom"] as? Int {
            if headroomValue == 1 {
                return true
            }
        }
        
        return false
    }
    
    // For iOS 17+, use the modern way to read HDR images
    @available(iOS 17.0, *)
    static func loadHDRImage(from url: URL) -> UIImage? {
        // Create a UIImageReader configuration
        var config = UIImageReader.Configuration()
        config.prefersHighDynamicRange = true
        
        // Read the image
        let reader = UIImageReader(configuration: config)
        return reader.image(contentsOf: url)
    }
}
