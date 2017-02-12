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
import FontAwesome_swift

class MoviesViewController: UIViewController,/* UITableViewDataSource, UITableViewDelegate,*/ UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate, UIScrollViewDelegate {

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var collectionView: UICollectionView!
        
    @IBOutlet weak var errorLabel: UILabel!
    
    lazy var searchBar = UISearchBar();
    
    var movies: [NSDictionary]?
    var filteredMovies: [NSDictionary]?
    var endpoint = ""

    var page: Int = 1
    var nextPage: Int = 2
    var isMoreDataLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide errorLabel until needed
        errorLabel.isHidden = true

        // Set collectionView parameters to self
        collectionView.dataSource = self
        collectionView.delegate = self
        
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 10)
        
        searchBar.sizeToFit()
        
        searchBar.delegate = self
        searchBar.placeholder = "Search for a movie..."
        searchBar.searchBarStyle = .prominent
        
        navigationItem.titleView = searchBar
        
        // Initialize a UIRefreshControl for pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        collectionView.insertSubview(refreshControl, at: 0)
        
        // Call the API to have data on first load
        update(currentPage: 1)
        
        // Initialize search bar delegate
        searchBar.delegate = self
    }
    
    // Makes a network request to get updated data
    // Updates the tableView with the new data
    // Hides the RefreshControl
    func refreshControlAction(_ refreshControl: UIRefreshControl) {
        // make sure progress HUD doesn't show during refresh
        MBProgressHUD.hide(for: self.view, animated: true)
        update(currentPage: 1);
        // Tell the refreshControl to stop spinning
        refreshControl.endRefreshing()
    }
    
    // Makes call to API for movie data
    // Sets loading state while data is being fetched
    // Reloads table data if request is successful
    func update(currentPage: Int) {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        
        print("loading page \(currentPage) on endpoint \(endpoint)")
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)&page=\(currentPage)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        if (currentPage != 1) {
            MBProgressHUD.showAdded(to: self.view, animated: true)
        }
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if (currentPage != 1) {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.isMoreDataLoading = false
                self.nextPage += 1
            }
            
            // error handling
            if (error != nil) {
                
                // set error message
                
                let errorMessage = String.fontAwesomeIcon(code: "fa-exclamation-triangle")! + "\n\n" + (error?.localizedDescription)!
                
                // format error for display
                let attributedString = NSMutableAttributedString(string: errorMessage)
                let symbolRange = NSMakeRange(0, 1)
                attributedString.setAttributes([NSFontAttributeName: UIFont.fontAwesome(ofSize: 60)], range: symbolRange)

                // set background of collectionView to error message
                self.errorLabel.isHidden = false
                self.errorLabel.attributedText = attributedString
                self.collectionView.backgroundView = self.errorLabel
                
                // empty data so that the error is viewable
                self.movies = []
                self.filteredMovies = []
                self.collectionView.reloadData()
                
                
                
            } else {
                // successfully loaded data, so reload table
                self.errorLabel.isHidden = true
                if let data = data {
                    if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                        //print(dataDictionary)
                        
                        if (currentPage != 1) {
                            for result in (dataDictionary["results"] as! [NSDictionary]) {
                                self.movies?.append(result)
                            }
                            self.filteredMovies = self.movies
                        } else {
                            self.movies = (dataDictionary["results"] as! [NSDictionary])
                            self.filteredMovies = self.movies
                        }
                        self.collectionView.reloadData()
                        
                    }
                }
            }
            
            //
        }
        task.resume()
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Search
    */
    
    // Filters movies by searched movie title
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        guard let movies = self.movies
            else {
                return
        }
        
        // show cancel button with animation if text is input
        self.searchBar.setShowsCancelButton(searchText != "", animated: true)
        
        // filter movies based on title
        filteredMovies = searchText.isEmpty ? movies : movies.filter ({ movie in
            
            // bool for whether or not the movie title matches searchText
            let foundTitle = (movie["title"] as? String)?.range(of: searchText, options: .caseInsensitive) != nil
            return foundTitle
        })
        
        self.collectionView.reloadData()
        
        
    }
    
    // Handles pressing the cancel button
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
        // make sure view displays all movies
        filteredMovies = movies
        self.collectionView.reloadData()
    }
    
    // MARK: - Collection View Data Source
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let filteredMovies = self.filteredMovies {
            return filteredMovies.count
        } else {
            
            return 0
        }
    }
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCollectionCell

        let movie = filteredMovies![indexPath.row]
        
        // image handling
        if let posterPath = movie["poster_path"] as? String {
            
            let smallImageUrl = NSURL(string: "https://image.tmdb.org/t/p/w185/" + posterPath)
            let largeImageUrl = NSURL(string: "https://image.tmdb.org/t/p/w500/" + posterPath)
            
            let smallImageRequest = NSURLRequest(url: smallImageUrl as! URL)
            let largeImageRequest = NSURLRequest(url: largeImageUrl as! URL)
            
            cell.posterView.layer.cornerRadius = 2.0;
            cell.posterView.clipsToBounds = true;
            
            cell.posterView.setImageWith(
                smallImageRequest as URLRequest,
                placeholderImage: nil,
                success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if smallImageResponse != nil {
                        //print("Image was NOT cached, fade in image")
                        cell.posterView.alpha = 0.0
                        cell.posterView.image = smallImage
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.posterView.alpha = 1.0
                        })
                        
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.posterView.alpha = 0.90
                            
                        }, completion: { (sucess) -> Void in
                            
                            // The AFNetworking ImageView Category only allows one request to be sent at a time
                            // per ImageView. This code must be in the completion block.
                            cell.posterView.setImageWith(
                                largeImageRequest as URLRequest,
                                placeholderImage: smallImage,
                                success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                    
                                    cell.posterView.image = largeImage;
                                    
                            },
                                failure: { (request, response, error) -> Void in
                                    // do something for the failure condition of the large image request
                                    // possibly setting the ImageView's image to a default image
                            })
                        })
                        
                    } else {
                        //print("Image was cached so just update the image")
                        cell.posterView.image = smallImage
                    }
            },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // do something for the failure condition
                    //print("Image failed to load")
            })
        }
        
        let cellBackground = UIView()
        cellBackground.backgroundColor = navigationController?.navigationBar.barTintColor
        cell.selectedBackgroundView = cellBackground
        
        return cell

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // deselect the cell when we're done
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let cell = sender as! UICollectionViewCell
        let indexPath = collectionView.indexPath(for: cell)
        let movie = filteredMovies?[(indexPath?.row)!]
        
        let detailViewController = segue.destination as! DetailViewController
        detailViewController.movie = movie
        
        
    }
    
    // MARK: - Infinite Scroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!isMoreDataLoading) {        // Calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = collectionView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - collectionView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && collectionView.isDragging) {
                isMoreDataLoading = true
                self.page = self.nextPage
                // load more results
                update(currentPage: self.page)
                
            }
        }
    }
}
