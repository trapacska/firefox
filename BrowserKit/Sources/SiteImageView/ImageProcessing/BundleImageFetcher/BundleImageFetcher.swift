// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

protocol BundleImageFetcher {
    /// Fetches from the bundle
    /// - Parameter domain: The domain to fetch the image with from the bundle
    /// - Returns: The image or throw an error if it fails
    func getImageFromBundle(domain: ImageDomain?) throws -> UIImage
}

class DefaultBundleImageFetcher: BundleImageFetcher {
    private struct BundledImage: Codable {
        var title: String
        var url: String?
        var image_url: String
        var background_color: String
        var domain: String
    }

    private struct FormattedBundledImage {
        var backgroundColor: UIColor
        var filePath: String
        var title: String
    }

    private let bundleDataProvider: BundleDataProvider
    private static var staticBundledImages = [String: FormattedBundledImage]()
    private var bundledImages: [String: FormattedBundledImage] {
        DefaultBundleImageFetcher.staticBundledImages
    }
    private var logger: Logger

    init(bundleDataProvider: BundleDataProvider = DefaultBundleDataProvider(),
         logger: Logger = DefaultLogger.shared) {
        self.bundleDataProvider = bundleDataProvider
        self.logger = logger
        // This is a heavy lift so we only want to fetch once, so we store in a static var
        if bundledImages.isEmpty {
            DefaultBundleImageFetcher.staticBundledImages = retrieveBundledImages()
        }
    }

    func getImageFromBundle(domain: ImageDomain?) throws -> UIImage {
        guard let domain = domain,
              let bundleDomain = getBundleDomain(domain: domain)
        else {
            throw SiteImageError.noImageInBundle
        }

        guard let bundledImage = bundledImages[bundleDomain],
              let image = bundleDataProvider.getBundleImage(from: bundledImage.filePath)
        else {
            throw SiteImageError.noImageInBundle
        }

        let color = bundledImage.backgroundColor.cgColor.alpha < 0.01 ? UIColor.white : bundledImage.backgroundColor
        return withBackgroundAndPadding(image: image, color: color)
    }

    // MARK: - Private

    private func getBundleDomain(domain: ImageDomain) -> String? {
        return domain.bundleDomains.first(where: { bundledImages[$0] != nil })
    }

    private func retrieveBundledImages() -> [String: FormattedBundledImage] {
        do {
            let data = try bundleDataProvider.getBundleData()
            return decode(from: data)
        } catch {
            return [:]
        }
    }

    private func decode(from data: Data) -> [String: FormattedBundledImage] {
        let decoder = JSONDecoder()
        var icons = [String: FormattedBundledImage]()

        do {
            let decodedImages = try decoder.decode([BundledImage].self, from: data)
            for decodedImage in decodedImages {
                guard let image = format(image: decodedImage) else {
                    continue
                }

                icons[image.title] = image
            }

            return icons
        } catch {
            return icons
        }
    }

    private func format(image: BundledImage) -> FormattedBundledImage? {
        let path = image.image_url.replacingOccurrences(of: ".png", with: "")
        let title = image.title
        let color = image.background_color
        let filePath = bundleDataProvider.getPath(from: path)
        guard let filePath = filePath else {
            return nil
        }

        var backgroundColor: UIColor
        if color == "#fff" || color == "#FFF" {
            backgroundColor = UIColor.clear
        } else {
            backgroundColor = UIColor(colorString: color.replacingOccurrences(of: "#", with: ""))
        }

        return FormattedBundledImage(backgroundColor: backgroundColor,
                                     filePath: filePath,
                                     title: title)
    }

    private func withBackgroundAndPadding(image: UIImage, color: UIColor, opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, opaque, image.scale)

        guard let ctx = UIGraphicsGetCurrentContext(), let cgImage = image.cgImage else { return image }
        defer { UIGraphicsEndImageContext() }

        // Pad the image in a bit to make the favicons look better
        let newSize = CGSize(width: image.size.width - 20, height: image.size.height - 20)
        let rect = CGRect(origin: .zero, size: image.size)
        let imageRect = CGRect(origin: CGPoint(x: 10, y: 10), size: newSize)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: image.size.height))
        ctx.draw(cgImage, in: imageRect)

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}
