//
//  DetailViewController.swift
//  MovieViewer
//
//  Created by Vanna Phong on 2/6/17.
//  Copyright © 2017 Vanna Phong. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var posterimageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var overviewTextView: UITextView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var infoView: UIView!
    
    var movie: NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("\(movie)")

        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.size.height)
        
        
        let title = movie["title"] as? String
        titleLabel.text = title
        navigationItem.title = title
        
        let overview = movie["overview"] as? String
        overviewTextView.text = overview
        
        
        
            // image handling
        if let posterPath = movie["poster_path"] as? String {
            
            let baseUrl = "https://image.tmdb.org/t/p/w500/"
            let imageUrl = NSURL(string: baseUrl + posterPath)
            let imageRequest = NSURLRequest(url: imageUrl as! URL)
            
            
            
            posterimageView.setImageWith(
                imageRequest as URLRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        //print("Image was NOT cached, fade in image")
                        self.posterimageView.alpha = 0.0
                        self.posterimageView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            self.posterimageView.alpha = 1.0
                        })
                    } else {
                        //print("Image was cached so just update the image")
                        self.posterimageView.image = image
                    }
            },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // do something for the failure condition
                    //print("Image failed to load")
            })
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
