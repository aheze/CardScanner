# CardScanner

## Example repo for [Bounding Box from VNDetectRectangleRequest is not correct size when used as child VC](https://stackoverflow.com/q/64759383/14351818)

First let's look at `boundingBox`, which is a "normalized" rectangle. Apple says 

> The coordinates are normalized to the dimensions of the processed image, with the origin at the image's lower-left corner.

This means that:
- The `origin` is at the bottom-left, not the top-left
- The `origin.x` and `width` are in terms of a fraction of the entire image's width
- The `origin.y` and `height` are in terms of a fraction of the entire image's height

Hopefully this diagram makes it clearer:


What you are used to | What Vision returns
--- | ---
![](https://i.stack.imgur.com/nDvgI.png) | ![](https://i.stack.imgur.com/owpMn.png)


Your function above converts `boundingBox` to the coordinates of `finalFrame`, which I assume is the entire view's frame. That is much larger than your small `CameraCaptureVC`.

Also, your `CameraCaptureVC`'s preview layer probably has a `aspectFill` video gravity. You will also need to account for the overflowing parts of the displayed image.

Try this converting function instead.

```swift
func getConvertedRect(boundingBox: CGRect, inImage imageSize: CGSize, containedIn containerSize: CGSize) -> CGRect {
    
    let rectOfImage: CGRect
    
    let imageAspect = imageSize.width / imageSize.height
    let containerAspect = containerSize.width / containerSize.height
    
    if imageAspect > containerAspect { /// image extends left and right
        let newImageWidth = containerSize.height * imageAspect /// the width of the overflowing image
        let newX = -(newImageWidth - containerSize.width) / 2
        rectOfImage = CGRect(x: newX, y: 0, width: newImageWidth, height: containerSize.height)
        
    } else { /// image extends top and bottom
        let newImageHeight = containerSize.width * (1 / imageAspect) /// the width of the overflowing image
        let newY = -(newImageHeight - containerSize.height) / 2
        rectOfImage = CGRect(x: 0, y: newY, width: containerSize.width, height: newImageHeight)
    }
    
    let newOriginBoundingBox = CGRect(
    x: boundingBox.origin.x,
    y: 1 - boundingBox.origin.y - boundingBox.height,
    width: boundingBox.width,
    height: boundingBox.height
    )
    
    var convertedRect = VNImageRectForNormalizedRect(newOriginBoundingBox, Int(rectOfImage.width), Int(rectOfImage.height))
    
    /// add the margins
    convertedRect.origin.x += rectOfImage.origin.x
    convertedRect.origin.y += rectOfImage.origin.y
    
    return convertedRect
}
```

This takes into account the frame of the image view and also `aspect fill` content mode.

Example (I'm using a static image instead of a live camera feed for simplicity):

```swift
/// inside your Vision request completion handler...
guard let image = self.imageView.image else { return }

let convertedRect = self.getConvertedRect(
    boundingBox: observation.boundingBox,
    inImage: image.size,
    containedIn: self.imageView.bounds.size
)
self.drawBoundingBox(rect: convertedRect)

func drawBoundingBox(rect: CGRect) {
    let uiView = UIView(frame: rect)
    imageView.addSubview(uiView)
        
    uiView.backgroundColor = UIColor.clear
    uiView.layer.borderColor = UIColor.orange.cgColor
    uiView.layer.borderWidth = 3
}
```

<kbd>[![Image taller than image view, orange bounding box drawn on detected rectangle][1]][1]</kbd>

<kbd>[![Image wider than image view, orange bounding box drawn on detected rectangle][2]][2]</kbd>


  [1]: https://i.stack.imgur.com/7iPMM.png
  [2]: https://i.stack.imgur.com/kUU3z.png
