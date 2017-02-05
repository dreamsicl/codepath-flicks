//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Vanna Phong on 2/2/17.
//  Copyright © 2017 Vanna Phong. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var movies: [NSDictionary]?
    var filteredMovies: [NSDictionary]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set tableView parameters to self
        tableView.dataSource = self
        tableView.delegate = self
        
        
        // Initialize a UIRefreshControl for pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
        
        // Call the API to have data on first load
        update()
        
        // Initialize search bar delegate
        searchBar.delegate = self
    }
    
    // Makes a network request to get updated data
    // Updates the tableView with the new data
    // Hides the RefreshControl
    func refreshControlAction(_ refreshControl: UIRefreshControl) {
        update();
        // Tell the refreshControl to stop spinning
        refreshControl.endRefreshing()
    }
    
    // Makes call to API for movie data
    // Sets loading state while data is being fetched
    // Reloads table data if request is successful
    func update() {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    print(dataDictionary)
                    
                    self.movies = (dataDictionary["results"] as! [NSDictionary])
                    self.tableView.reloadData()
                    
                }
            }
        }
        task.resume()
        
    }
    
    
    /*
    // MARK: - Table View
    */
    
    // Sets the number of rows in the table to be the number of movies returned from API call
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("movies.count = \(movies?.count)")
        if let movies = movies {
            return movies.count
        }
        else {
            return 0
        }
    }

    // Populates table cell with individual movie data returned from API call
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        let movie = movies![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        // image handling
        let posterPath = movie["poster_path"] as! String
        let baseUrl = "https://image.tmdb.org/t/p/w500/"
        let imageUrl = NSURL(string: baseUrl + posterPath)
        let imageRequest = NSURLRequest(url: imageUrl as! URL)
        
        
        
        cell.posterView.setImageWith(
            imageRequest as URLRequest,
            placeholderImage: nil,
            success: { (imageRequest, imageResponse, image) -> Void in
                
                // imageResponse will be nil if the image is cached
                if imageResponse != nil {
                    print("Image was NOT cached, fade in image")
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = image
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        cell.posterView.alpha = 1.0
                    })
                } else {
                    print("Image was cached so just update the image")
                    cell.posterView.image = image
                }
        },
            failure: { (imageRequest, imageResponse, error) -> Void in
                // do something for the failure condition
                print("Image failed to load")
        })
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Search
    */
    // Returns movies by searched movie title
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        
        
        // filter movies based on title
        filteredMovies = searchText.isEmpty ? movies : movies?.filter ({ movie in
            
            // bool for whether or not the movie title matches searchText
            let foundTitle = (movie["title"] as? String)?.range(of: searchText, options: .caseInsensitive) != nil
            
            return foundTitle
        })
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
