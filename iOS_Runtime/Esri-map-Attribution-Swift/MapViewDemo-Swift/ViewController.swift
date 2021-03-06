//
// Copyright 2016 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

import UIKit
import ArcGIS

class ViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var attributionLabel: UILabel!
    @IBOutlet weak var mapView: AGSMapView!
    
    private var useServiceBaseMap: Bool = false
    private var useVectorBaseMap: Bool = true
    private var tiledLayer: AGSArcGISTiledLayer!
    var map:AGSMap!
    var currentViewPoint: AGSViewpoint!
    var currentLOD: AGSViewpoint!
    var ymin: Double!
    var xmin: Double!
    var ymax: Double!
    var xmax: Double!
    var scale: Double!
    
    func createBasemapTiledLayer(URL: NSURL) -> AGSArcGISTiledLayer {
        //create an instance of a map with requested basemap
        let tiledLayer:AGSArcGISTiledLayer = AGSArcGISTiledLayer(URL: URL);
        return tiledLayer;
    }
    
    func createBasemapVectorTiledLayer(URL: NSURL) -> AGSArcGISVectorTiledLayer {
        //create an instance of a map with requested basemap
        let tiledLayer:AGSArcGISVectorTiledLayer = AGSArcGISVectorTiledLayer(URL: URL);
        return tiledLayer;
    }
    
    func createBasemap() -> AGSBasemap {
        var basemap:AGSBasemap
        if (useServiceBaseMap) {
            basemap = AGSBasemap.streetsBasemap();
        } else if (useVectorBaseMap) {
            basemap = AGSBasemap(baseLayer: self.createBasemapVectorTiledLayer(NSURL(string: "http://basemaps.arcgis.com/b2/arcgis/rest/services/World_Basemap/VectorTileServer")!));
        } else {
            basemap = AGSBasemap(baseLayer: self.createBasemapTiledLayer(NSURL(string: "http://services.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer")!));
        }
        return basemap;
    }
    
    func getBasemapAttribution() -> String {
        guard let baseLayer:AGSArcGISTiledLayer = self.map.basemap.baseLayers[0] as? AGSArcGISTiledLayer else {
            return "No attribution"
        }
        return baseLayer.mapServiceInfo!.attribution;
    }
    
    func configAttributionLabel() {
        self.attributionLabel.numberOfLines = 1
        self.attributionLabel.lineBreakMode = .ByTruncatingTail
        self.attributionLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        self.attributionLabel.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.65)
        self.attributionLabel.textAlignment = NSTextAlignment.Left
    }
    
    func updateAttribution() {
        //set map attribution to show once map load up
        let attributeFont = UIFont(name: "Helvetica Neue", size: 8)
        let mapAttributes = [
            NSFontAttributeName: attributeFont!
        ]
        let mapAttributionString = NSMutableAttributedString(string: self.getBasemapAttribution(), attributes: mapAttributes)
        self.attributionLabel.attributedText = mapAttributionString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.map = AGSMap(basemap: self.createBasemap())
        
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -13045884, y: 4036331, spatialReference: AGSSpatialReference.webMercator()), scale: 1e6)

        self.mapView.map = self.map
        self.configAttributionLabel();
        
        //Setup a completion handler until the map loaded then show the attribution label
        self.map.loadWithCompletion { (error) -> Void in
            if let error = error {
                print(error)
            } else {
                self.updateAttribution();
            }
        }
        
        //this may not fit for performance since we may call it too often and we can't return anything back
        self.mapView.viewpointChangedHandler = {
            () -> Void in
            
           
            self.currentViewPoint = self.mapView.currentViewpointWithType(AGSViewpointType.BoundingGeometry)
            self.currentLOD = self.mapView.currentViewpointWithType(AGSViewpointType.CenterAndScale)
            do {
                let jsonBbox = try self.currentViewPoint.toJSON()
                let jsonScale = try self.currentLOD.toJSON()
                
                //print(jsonScale)
                //print(jsonBbox)
                
              //check the current bound
             if let targetGeometry = jsonBbox["targetGeometry"] as? [String: AnyObject]{
                if let ymax = targetGeometry["ymax"] as? Double {
                    print("Ymax: \(ymax)")
                    self.ymax = ymax
                }
                if let xmin = targetGeometry["xmin"] as? Double {
                    print("Xmin: \(xmin)")
                    self.xmin = xmin
                }
                if let ymin = targetGeometry["ymin"] as? Double {
                    print("Ymin: \(ymin)")
                    self.ymin = ymin
                }
                if let xmax = targetGeometry["xmax"] as? Double {
                    print("Xmax: \(xmax)")
                    self.xmax = xmax
                }
            }
               //check the current scale
                if let currentScale = jsonScale["scale"] as? Double {
                    print("Current Scale: \(currentScale)")
                    self.scale = currentScale
                    print("--------------------")
                }
                
            } catch let error as NSError {
                print ("JSON Error: \(error.localizedDescription)")
                
            }
        }
    }
}

