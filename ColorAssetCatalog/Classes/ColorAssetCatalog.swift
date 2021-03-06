//
//  ColorAssetCatalog.swift
//  ColorAssetCatalog
//
//  Created by Sam Rayner on 12/06/2017.
//

struct ColorAssetCatalog: Decodable {
    var colors: [ColorAsset]
}

struct ColorAsset: Decodable {
    private enum CodingKeys: String, CodingKey {
        case idiomString = "idiom"
        case color
    }

    var idiomString: String
    var idiom: UIUserInterfaceIdiom? {
        switch idiomString {
        case "universal":
            return .unspecified
        case "iphone":
            return .phone
        case "ipad":
            return .pad
        case "tv":
            return .tv
        default:
            return nil
        }
    }

    var color: Color

    var colorComponents: [CGFloat] {
        return [color.components.red, color.components.green, color.components.blue, color.components.alpha]
    }

    var cgColor: CGColor? {
        guard let colorSpace = color.colorSpace else { return nil }
        return CGColor(colorSpace: colorSpace, components: colorComponents)
    }
}

extension UIUserInterfaceIdiom: Decodable {}

extension ColorAsset {
    struct Color: Decodable {
        private enum CodingKeys: String, CodingKey {
            case components
            case colorSpaceString = "color-space"
        }

        var components: Components

        var colorSpaceString: String
        var colorSpace: CGColorSpace? {
            return CGColorSpace(name: colorSpaceName)
        }
        var colorSpaceName: CFString {
            switch colorSpaceString {
            case "srgb":
                return CGColorSpace.sRGB
            case "display-P3":
                if #available(iOS 9.3, *) {
                    return CGColorSpace.displayP3
                } else {
                    return CGColorSpace.sRGB
                }
            case "gray-gamma-22":
                return CGColorSpace.genericGrayGamma2_2
            case "extended-gray":
                if #available(iOS 10.0, *) {
                    return CGColorSpace.extendedGray
                } else {
                    return CGColorSpace.genericGrayGamma2_2
                }
            case "extended-srgb":
                if #available(iOS 10.0, *) {
                    return CGColorSpace.extendedSRGB
                } else {
                    return CGColorSpace.sRGB
                }
            case "extended-linear-srgb":
                if #available(iOS 10.0, *) {
                    return CGColorSpace.extendedLinearSRGB
                } else {
                    return CGColorSpace.genericRGBLinear
                }
            default:
                return CGColorSpace.sRGB
            }
        }

        @available(iOS 10, *)
        var displayGamut: UIDisplayGamut {
            return colorSpaceName == CGColorSpace.displayP3 ? .P3 : .SRGB
        }
    }
}

extension ColorAsset.Color {
    struct Components: Decodable {
        var alpha: CGFloat = 1
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0

        var white: CGFloat? {
            didSet {
                guard let white = white else { return }
                red = white
                green = white
                blue = white
            }
        }

        // Custom decoding required due to Floats
        // being Strings in JSON generated by Xcode 9.2+
        // https://bugs.swift.org/browse/SR-5249

        private enum CodingKeys: String, CodingKey {
            case alpha
            case red
            case green
            case blue
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            alpha   = try decodeCGFloat(for: .alpha, in: values)
            red     = try decodeCGFloat(for: .red, in: values)
            green   = try decodeCGFloat(for: .green, in: values)
            blue    = try decodeCGFloat(for: .blue, in: values)
        }

        private func decodeCGFloat(for key: CodingKeys, in container: KeyedDecodingContainer<CodingKeys>) throws -> CGFloat {
            do {
                return try container.decode(CGFloat.self, forKey: key)
            } catch {
                let string = try container.decode(String.self, forKey: key)
                guard let double = Double(string) else {
                    throw DecodingError.typeMismatch(CGFloat.self, DecodingError.Context(codingPath: [key], debugDescription: string))
                }
                return CGFloat(double)
            }
        }
    }
}
