import AppKit

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
let text = "👀"
let font = NSFont.systemFont(ofSize: 800)

image.lockFocus()
let attributedString = NSAttributedString(string: text, attributes: [.font: font])
let stringSize = attributedString.size()
let point = CGPoint(x: (size.width - stringSize.width) / 2, y: (size.height - stringSize.height) / 2)
attributedString.draw(at: point)
image.unlockFocus()

if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try? pngData.write(to: URL(fileURLWithPath: "icon.png"))
    print("Generated icon.png")
}
