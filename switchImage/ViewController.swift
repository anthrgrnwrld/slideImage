//
//  ViewController.swift
//  switchImage
//
//  Created by Masaki Horimoto on 2015/05/24.
//  Copyright (c) 2015年 Masaki Horimoto. All rights reserved.
//

import UIKit

//自分がいるlocation#を記憶できるクラス (UIImageViewを継承)
class LocationImageView: UIImageView {
    var location: Int! = 0
    var lpName: String! = ""
    var isSlide: Bool! = false
}

//二つのCGPointを持つクラス (イメージ移動の座標管理)
class TwoCGPoint {
    var imagePoint: CGPoint!    //イメージの座標保存用
    var touchPoint: CGPoint!    //タッチ位置の座標保存用
}

//タッチスタート時と移動後の座標情報を持つクラス (イメージ移動の座標管理)
class ControlImageClass {
    var start: TwoCGPoint = TwoCGPoint()            //スタート時の画像座標とタッチ座標
    var destination: TwoCGPoint = TwoCGPoint()      //移動後(または移動途中の)画像座標とタッチ座標
    var draggingView: UIView?                       //どの画像を移動しているかを保存
    
    //startとdestinationからタッチ中の移動量を計算
    var delta: CGPoint {
        get {
            let deltaX: CGFloat = destination.touchPoint.x - start.touchPoint.x
            let deltaY: CGFloat = destination.touchPoint.y - start.touchPoint.y
            return CGPointMake(deltaX, deltaY)
        }
    }
    
    //移動後(または移動中の)画像の座標取得用のメソッド
    func setMovedImagePoint() -> CGPoint {
        let imagePointX: CGFloat = start.imagePoint.x + delta.x
        let imagePointY: CGFloat = start.imagePoint.y + delta.y
        destination.imagePoint = CGPointMake(imagePointX, imagePointY)
        return destination.imagePoint
    }
}

class ViewController: UIViewController {

    @IBOutlet var imageLPArray: [LocationImageView]!
    @IBOutlet weak var outputLabel: UILabel!
    
    let initialLPArray: [String] = ["DefinitelyMaybe", "MorningGlory", "BeHereNow"]     //初期LP画像名
    var pointImage: ControlImageClass! = ControlImageClass()                            //移動画像管理用変数
    @IBOutlet var destinationViewArray: [UIView]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //表示したいLP画像名を設定する (実際の表示はviewDidLayoutSubviewsで行う)
        for (index, val) in enumerate(initialLPArray) {
            imageLPArray[index].lpName = initialLPArray[index]
            imageLPArray[index].userInteractionEnabled = true
            imageLPArray[index].location = index
            outputLabel.text = "location of \(imageLPArray[index].lpName) is \(imageLPArray[index].location)"
        }

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        println("\(__FUNCTION__) is called")
        
        for (index, val) in enumerate(initialLPArray) {
            imageLPArray[index].image = UIImage(named: "\(imageLPArray[index].lpName).jpg")
            
            let location = imageLPArray[index].location!
            let isSlide = imageLPArray[index].isSlide!
            var point: CGPoint?
            if isSlide {
                point = CGPointMake(destinationViewArray[location].center.x, destinationViewArray[location].center.y - 80)
            } else {
                point = destinationViewArray[location].center
                
            }
            imageLPArray[index].center = point!
            
        }
        
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        
        if touch.view is LocationImageView {
            pointImage.start.imagePoint = touch.view.center
            pointImage.start.touchPoint = touch.locationInView(self.view)
            pointImage.draggingView = touch.view
            touch.view.layer.opacity = 0.5
            touch.view.layer.shadowOpacity = 0.8
            self.view.bringSubviewToFront(touch.view)
        } else {
            //Do nothing
        }
        
    }
    
    
    //各locationとの距離を管理するクラス
    class distanceClass {
        var distanceArray: [CGFloat] = []
        var minIndex: Int!
    }
    
    //各locationとの距離とその最小値のIndexを保存するメソッド
    func getDistanceWithImage(imageView :UIView) -> distanceClass {
        let distance: distanceClass = distanceClass()
        
        distance.distanceArray = destinationViewArray.map({self.getDistanceWithPoint1(imageView.center, point2: $0.center)})
        let (index, val) = reduce(enumerate(distance.distanceArray), (-1, CGFloat(FLT_MAX))) {
            $0.1 < $1.1 ? $0 : $1
        }
        distance.minIndex = index
        
        return distance
    }
    
    //2点の座標間の距離を取得するメソッド
    func getDistanceWithPoint1(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let distanceX = point1.x - point2.x
        let distanceY = point1.y - point2.y
        let distance = sqrt(distanceX * distanceX + distanceY * distanceY)
        return distance
    }
    
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        
        if touch.view == pointImage.draggingView {
            pointImage.destination.touchPoint = touch.locationInView(self.view)
            touch.view.center = pointImage.setMovedImagePoint()     //移動後の座標を取得するメソッドを使って画像の表示位置を変更
            
            let tmpImageView = touch.view as! LocationImageView
            var distance: distanceClass = distanceClass()   //locationとの距離を管理する変数
            distance = getDistanceWithImage(touch.view)     //各locationの距離と最小値のindexを保存
            
            let minIndex = distance.minIndex
            
            for (index, val) in enumerate(imageLPArray) {
                
                slideWithDistance(distance, touchView: tmpImageView, locationImageView: imageLPArray[index], index: minIndex)
                
            }
            
        } else {
            //Do nothing
        }
    }
    
    func slideWithDistance(distance: distanceClass, touchView: LocationImageView, locationImageView: LocationImageView, index: Int) {
        
        let destinationIndex = locationImageView.location
        
        if distance.distanceArray[distance.minIndex] < 40 * sqrt(2.000) && index == locationImageView.location && touchView != locationImageView {
            
            if locationImageView.isSlide == false {
                locationImageView.isSlide = true
                var point = CGPointMake(locationImageView.center.x, destinationViewArray[destinationIndex].center.y - 80)
                animationWithImageView(locationImageView, point: point, duration: 0.2)
                locationImageView.layer.shadowOpacity = 0.6
            } else {
                //Do nothing
            }
            
        } else {
            if locationImageView.isSlide == true && touchView != locationImageView {
                locationImageView.isSlide = false
                animationWithImageView(locationImageView, point: destinationViewArray[destinationIndex].center, duration: 0.2)
                locationImageView.layer.shadowOpacity = 0.0
            } else if locationImageView.isSlide == true && touchView == locationImageView {
                locationImageView.isSlide = false
            }
            else {
                //Do nothing
            }
            
        }
        
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        
        if touch.view == pointImage.draggingView {
            let tmpImageView = touch.view as! LocationImageView
            var distance: distanceClass = distanceClass()   //locationとの距離を管理する変数
            distance = getDistanceWithImage(touch.view)     //各locationの距離と最小値のindexを保存
            
            moveImageWithDistance(distance, imageView: tmpImageView)
            
        } else {
            //Do nothing
        }
        
        
    }
    
    //最も近いdestinationに移動 && 透明度を0%にして元の位置へ  or  透明度を0%にして元の位置へ
    func moveImageWithDistance(distance: distanceClass, imageView: LocationImageView) {
        let point: CGPoint!
        
        if distance.distanceArray[distance.minIndex] < 40 * sqrt(2.000) {
            imageView.layer.opacity = 1.0
            imageView.layer.shadowOpacity = 0.0
            imageView.location = distance.minIndex
            
            animationWithImageView(imageView, point: destinationViewArray[distance.minIndex].center, duration: 0.2)
            outputLabel.text = "location of \(imageView.lpName) is \(imageView.location)"
            
        } else {
            let point = pointImage.start.imagePoint
            imageView.layer.opacity = 1.0
            imageView.layer.shadowOpacity = 0.0
            
            animationWithImageView(imageView, point: point, duration: 0.2)
            outputLabel.text = "location of \(imageView.lpName) is \(imageView.location)"
            
            for (index, val) in enumerate(imageLPArray) {
                if imageView != imageLPArray[index] && imageView.location == imageLPArray[index].location {
                    let point = CGPointMake(destinationViewArray[index].center.x, destinationViewArray[index].center.y - 80)
                    animationWithImageView(imageLPArray[index], point: point, duration: 0.2)
                    imageLPArray[index].layer.shadowOpacity = 0.6
                    
                }
                
            }
            
        }
        
    }
    
    //引数1のUIImageViewを引数2の座標へアニメーションするメソッド
    func animationWithImageView(ImageView: UIImageView, point: CGPoint, duration: Double) {
            UIView.animateWithDuration(duration, animations: { () -> Void in
                ImageView.center = point
                ImageView.layer.opacity = 1.0
            })
            
    }
    
    


}

