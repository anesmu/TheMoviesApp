//
//  HomeViewController.swift
//  TMA
//
//  Created by Antonio Espino Muñoz on 3/3/22.
//

import UIKit
import RxSwift
import RxCocoa

class HomeViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    private var router = HomeRouter()
    private var viewModel = HomeViewModel()
    private var disposeBag = DisposeBag()
    private var movies = [Movie]()
    private var filteredMovies = [Movie]()

    lazy var searchController: UISearchController = ({
        let controller = UISearchController(searchResultsController: nil)
        controller.hidesNavigationBarDuringPresentation = true
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.sizeToFit()
        controller.searchBar.barStyle = .default
        controller.searchBar.backgroundColor = .clear
        controller.searchBar.placeholder = "Find a movie 🎬"

        return controller
    })()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "The Movies app"
        
        tableView.delegate = self
        tableView.dataSource = self
        configureTableView()
        manageSearchBarController()
        
        viewModel.bind(view: self, router: router)
        
        getData()
    }
    
    private func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "CustomMovieCell", bundle: nil),
                           forCellReuseIdentifier: "CustomMovieCell")
    }
    
    private func manageSearchBarController() {
        let searchBar = searchController.searchBar
        searchController.delegate = self
        tableView.tableHeaderView = searchBar
        tableView.contentOffset = CGPoint(x: 0, y: searchBar.frame.size.height)

        searchBar.rx.text
        .orEmpty
        .distinctUntilChanged()
            .subscribe(onNext: { (result) in
                self.filteredMovies = self.movies.filter({ movie in
                    self.reloadTableView()
                    return movie.title.contains(result)
                })
            })
        .disposed(by: disposeBag)
    }
    
    private func getData() {
        return viewModel.getListMovies()
            .subscribe(on: MainScheduler.instance)
            .subscribe(
                onNext: { movies in
                    self.movies = movies
                    self.reloadTableView()
                }, onError: { error in
                    print("Unknown error: " + error.localizedDescription)
                }, onCompleted: {
                    // not necessary
                }).disposed(by: disposeBag)
    }
    
    private func reloadTableView() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            self.tableView.reloadData()
        }
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive && searchController.searchBar.text != "" ?
            filteredMovies.count : movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
        tableView.dequeueReusableCell(withIdentifier:"CustomMovieCell") as! CustomMovieCell
        
        let movie: Movie = searchController.isActive && searchController.searchBar.text != "" ?
            filteredMovies[indexPath.row] : movies[indexPath.row]

        cell.imageMovie.imageFromServerURL(urlString: Constants.URL.urlImages + movie.image,
                                           placeHolderImage: UIImage(named: "placeholder")!)
        cell.titleMovie.text = movie.title
        cell.descriptionMovie.text = movie.sinopsis
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let movie: Movie = searchController.isActive && searchController.searchBar.text != "" ?
            filteredMovies[indexPath.row] : movies[indexPath.row]

        viewModel.makeDetailsView(movieID: "\(movie.movieID)")
    }
}

extension HomeViewController: UISearchControllerDelegate {
    func searchbarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.isActive = false
        reloadTableView()
    }
}
