import UIKit

class SearchViewController: SpotzerViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate {
    
    //var searchBar = UISearchBar()
    var items = [String]()
    var filteredItems = Array<ArtObject>()
    var arraysWithDataFtomSQL = Array<Array<ArtObject>>()
    var savedData = Array<ArtObject>()
    var db: SpotzerDatabase! = SpotzerDatabase.sharedInstance
    var ifDeleteArray = false
    var height = CGFloat()
    var lastText = ""
    var tours = [CuratorGroup]()
    var filteredTours = [CuratorGroup]()
    var filteredObjects = Array<AnyObject>()
    var makeEmpty = false
    
    @IBOutlet weak var searchResultsTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var sgmControl: UISegmentedControl!
    @IBOutlet weak var cnsSettingsContainerHeight: NSLayoutConstraint!
    
    
    @IBAction func valueChangeSgmControl(sender: AnyObject) {

        searchBar(searchBar, textDidChange: searchBar.text)
    }
    
    var searchQueue : dispatch_queue_t = {
        let q = dispatch_queue_create("searchQueue", DISPATCH_QUEUE_SERIAL)
        return q
        }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.screenName = "search"

        
        tours = db.getTours()
        if searchResultsTableView.respondsToSelector(Selector("layoutMargins")) {
            self.searchResultsTableView.layoutMargins = UIEdgeInsetsZero
        }
        if searchResultsTableView.respondsToSelector(Selector("separatorInset")){
            self.searchResultsTableView.separatorInset = UIEdgeInsetsZero
        }
        sgmControl.hidden = true
        
        sgmControl.selectedSegmentIndex = 0
     
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasHiden:", name: UIKeyboardDidHideNotification , object: nil)
        
        searchBar.backgroundColor = SpotzerConfiguration.backgroundColor
        searchBar.tintColor = SpotzerConfiguration.themeColor
        //        searchBar.barTintColor = SpotzerConfiguration.backgroundColor
        searchBar.becomeFirstResponder()
        searchBar.layer.shadowOffset = CGSizeZero
        searchBar.layer.shadowColor = UIColor.grayColor().CGColor
        searchBar.layer.shadowRadius = 5.0
        searchBar.layer.shadowOpacity = 0.7
        searchBar.placeholder = "Enter text in field to start your search."
        
        
        sgmControl.tintColor = SpotzerConfiguration.themeColor
        sgmControl.backgroundColor = UIColor.whiteColor()
        sgmControl.layer.cornerRadius = 5
        sgmControl.setTitleTextAttributes([NSFontAttributeName: SpotzerConfiguration.Fonts.regular(10), NSForegroundColorAttributeName: SpotzerConfiguration.themeColor], forState: .Normal)
        sgmControl.setTitleTextAttributes([NSFontAttributeName: SpotzerConfiguration.Fonts.regular(10), NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Selected)
        
        let searchBarAttributes: NSDictionary = [NSFontAttributeName: SpotzerConfiguration.Fonts.regular(16), NSForegroundColorAttributeName: "COLOR_WHITE"]
        
        for var i = 0; i < searchBar.subviews.count; i++ {
            if searchBar.subviews[i].isKindOfClass(UITextField) {
                searchBar.subviews[i].setTitleTextAttributes(searchBarAttributes, forState: UIControlState.Normal)
            }
           
        }
            // TODO: Change searchBar font
        searchResultsTableView.backgroundColor = SpotzerConfiguration.backgroundColor
        searchResultsTableView.tintColor = SpotzerConfiguration.themeColor
        
        searchResultsTableView.backgroundColor = SpotzerConfiguration.backgroundColor
        searchResultsTableView.tableFooterView = UIView()
        
        
       
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let acNav = self.navigationController as? ACContainerViewController {
            acNav.navTitle = "Search"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == searchResultsTableView {
            if self.filteredObjects.isEmpty {
                return 0
            }
            return self.filteredObjects.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
       
        if filteredObjects.count < indexPath.row {
            return UITableViewCell()
        }
        
    /// MARK: Customize tour cell
        
        if (filteredObjects.count) > indexPath.row {
            
            if let curator = filteredObjects[indexPath.row] as? CuratorGroup {
                
                if curator.isExhibition == true {
                    var optCell: ExhibitionCell? = tableView.dequeueReusableCellWithIdentifier("exhibitionCell", forIndexPath: indexPath) as? ExhibitionCell
                    var cell: ExhibitionCell
                    if optCell == nil {
                        cell = ExhibitionCell(style: UITableViewCellStyle.Default, reuseIdentifier: "exhibitionCell")
                    } else {
                        cell = optCell!
                    }
                    if filteredObjects.count > indexPath.row {
                    cell = prepareExhibitionCell(curator, indexPath: indexPath,cell: cell)
                    }
                    return cell
                }
    /// MARK: Customize exh cell
                
                }
        
            
            if filteredObjects.count > indexPath.row {
                if let curator = filteredObjects[indexPath.row] as? CuratorGroup {
                    if curator.isExhibition == false {
                        var optCell: TourCell? = tableView.dequeueReusableCellWithIdentifier("tourCell", forIndexPath: indexPath) as? TourCell
                        var cell: TourCell
                        if optCell == nil {
                            cell = TourCell(style: UITableViewCellStyle.Default, reuseIdentifier: "tourCell")
                        } else {
                            cell = optCell!
                        }
                        if filteredObjects.count > indexPath.row {
                        
                            let tour = filteredObjects[indexPath.row] as CuratorGroup
                            cell = prepareTourCell(tour, indexPath: indexPath, cell: cell)
                            
                            return cell
                        }
                    }
                }
            }
            
        
    /// MARK: Customize Art cell
            
        
            if filteredObjects.count > indexPath.row {
                if let art = filteredObjects[indexPath.row] as? ArtObject {
               
                    var optCell: SearchArtCell? = tableView.dequeueReusableCellWithIdentifier("searchArtCell", forIndexPath: indexPath) as? SearchArtCell
                    var cell: SearchArtCell
                    if optCell == nil {
                        cell = SearchArtCell(style: UITableViewCellStyle.Default, reuseIdentifier: "searchArtCell")
                    } else {
                        cell = optCell!
                    }
                        if filteredObjects.count > indexPath.row {
                            let art = filteredObjects[indexPath.row] as ArtObject
                        
                            cell = prepareArtObjectCell(art, indexPath: indexPath, cell: cell)
                            return cell
                        }
                }
            }
      
            if filteredObjects.count > indexPath.row {
                if let artist = filteredObjects[indexPath.row] as? Artist {
                    var optCell: ArtistCell? = tableView.dequeueReusableCellWithIdentifier("artistCell", forIndexPath: indexPath) as? ArtistCell
                    var cell: ArtistCell
                    if optCell == nil {
                        cell = ArtistCell(style: UITableViewCellStyle.Default, reuseIdentifier: "artistCell")
                    } else {
                        cell = optCell!
                    }
                    if (filteredObjects.count) > indexPath.row {
                    
                        cell = prepareArtistCell(artist, indexPath: indexPath, cell: cell)
                        return cell
                    }
                }
            }
        }
        
        
        
        
        
        return UITableViewCell()
        
    }
    
    func filterContentForSearchText(searchText: String, arraysWithDataSQL: Array<Array<ArtObject>>) ->  Array<ArtObject>{
        var filtered = Array<ArtObject>()
        var filteredArtFromArtist = Array<ArtObject>()
        if let objects = db.getSearchItem(searchText) as Array<ArtObject>? {
            self.arraysWithDataFtomSQL.append(objects)
            return objects
        }
        return filtered
    }
    func filterToursForSearchText(searchText: String) -> [CuratorGroup] {
        var filtered = Array<CuratorGroup>()
        if let objects = db.getSearchTour(searchText) as Array<CuratorGroup>? {
            
            return objects
        }
        return filtered
    }
    func filterArtistsForSearchText(searchText: String) -> [Artist] {
        var filtered = Array<Artist>()
        if let objects = db.getSearchArtist(searchText) as Array<Artist>? {
            return objects
        }
        return filtered
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil);
        if let art = filteredObjects[indexPath.row] as? ArtObject {
            let vc = storyboard.instantiateViewControllerWithIdentifier("spotzerArtViewController") as SpotzerArtViewController
            vc.art = art
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if let tour = self.filteredObjects[indexPath.row] as? CuratorGroup {
            let vc = ArtObjectListController.createAsTour(tour)
            //let vc = storyboard.instantiateViewControllerWithIdentifier("artObjectListController") as Art
            //vc.tour = tour
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if let artist = self.filteredObjects[indexPath.row] as? Artist {
            let vc = storyboard.instantiateViewControllerWithIdentifier("spotzerArtistViewController") as SpotzerArtistViewController
            vc.artist = artist
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func searchBar(searchBar: UISearchBar!, textDidChange searchText: String!) {
        if searchText == "" {
            if sgmControl.hidden == false {
                sgmControl.hidden = true
                
            }
        } else {
            if sgmControl.hidden == true {
                sgmControl.hidden = false
                
            }
        }
        
        var backgroundTaskIdentifier : UIBackgroundTaskIdentifier = 0
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(backgroundTaskIdentifier)
        })
        if backgroundTaskIdentifier == UIBackgroundTaskInvalid {
            return
        }
        
        dispatch_async(self.searchQueue) {
            self.filteredObjects = Array<AnyObject>()
            if searchText == "" {
                self.arraysWithDataFtomSQL = Array<Array<ArtObject>>()
                self.filteredItems = Array<ArtObject>()
                self.filteredTours = Array<CuratorGroup>()
                self.filteredObjects = Array<AnyObject>()
            }
            else {
                self.filteredItems = Array<ArtObject>()
                self.filteredTours = Array<CuratorGroup>()
                self.filteredObjects = Array<AnyObject>()
                
                switch self.sgmControl.selectedSegmentIndex {
                    
                case 4:
                    if let artArray = self.filterContentForSearchText(searchText, arraysWithDataSQL: self.arraysWithDataFtomSQL) as Array<ArtObject>? {
                        self.filteredItems = artArray
                        
                        for item in self.filteredItems {
                            
                            self.filteredObjects.append(item)
                        }
                    }
                    else {
                        self.filteredItems = Array<ArtObject>()
                        
                    }
                case 3:
                    if let artistArray = self.filterArtistsForSearchText(searchText) as Array<Artist>? {
                        for item in artistArray {
                            self.filteredObjects.append(item)
                        }
                    } else {
                        
                    }
                case 2:
                    if let toursArray = self.filterToursForSearchText(searchText) as Array<CuratorGroup>? {
                        self.filteredTours = toursArray
                        for item in self.filteredTours {
                            if item.isExhibition == false {
                                self.filteredObjects.append(item)
                            }
                        }
                    } else {
                        self.filteredTours = []
                        
                    }
                case 1:
                    if let exhArray = self.filterToursForSearchText(searchText) as Array<CuratorGroup>? {
                        self.filteredTours = exhArray
                        for item in self.filteredTours {
                            if item.isExhibition == true {
                                self.filteredObjects.append(item)
                            }
                        }
                    } else {
                        self.filteredTours = []
                    
                    }
               
                case 0:   /// all objects
                    if let artArray = self.filterContentForSearchText(searchText, arraysWithDataSQL: self.arraysWithDataFtomSQL) as Array<ArtObject>? {
                        self.filteredItems = artArray
                        
                        for item in self.filteredItems {
                            
                            self.filteredObjects.append(item)
                        }
                    }
                    if let toursArray = self.filterToursForSearchText(searchText) as Array<CuratorGroup>? {
                        self.filteredTours = toursArray
                        for item in self.filteredTours {
                            if item.isExhibition == false {
                                self.filteredObjects.append(item)
                            }
                        }
                    }
                    if let exhArray = self.filterToursForSearchText(searchText) as Array<CuratorGroup>? {
                        self.filteredTours = exhArray
                        for item in self.filteredTours {
                            if item.isExhibition == true {
                                self.filteredObjects.append(item)
                            }
                        }
                    }

                    if let artistArray = self.filterArtistsForSearchText(searchText) as Array<Artist>? {
                        for item in artistArray {
                            self.filteredObjects.append(item)
                        }
                    }

                default:
                    println("default")
                }
                self.sortArray()
            }
            dispatch_sync(dispatch_get_main_queue()) {
                self.lastText = searchText
                self.searchResultsTableView.reloadData()
//                self.sortArray()
                UIApplication.sharedApplication().endBackgroundTask(backgroundTaskIdentifier)
            }
        }
        
    }
    
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar!) {
        searchBar.resignFirstResponder()
    }
    
    func keyboardWasShown (aNotification: NSNotification){
        var info: NSDictionary = aNotification.userInfo!
        var kbSize: CGSize = info.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue().size
        
        var contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0)
        
        var aRect: CGRect = self.view.frame
        aRect.size.height -= kbSize.height
        height = kbSize.height * 5/4
        //view.backgroundColor = SpotzerConfiguration.themeColor
        //self.searchResultsTableView.frame = CGRectMake(0, searchBar.frame.height, view.frame.width, view.frame.height - kbSize.height - searchBar.frame.height)
        //CGRectMake(0, searchBar.frame.height, view.frame.width, view.frame.height - searchBar.frame.height - 40)
        //button.frame = CGRectMake(0, textField.frame.origin.y + textField.frame.height, view.frame.width,  kbSize.height/4)
        //        label.frame = CGRectMake(0, textField.frame.origin.y + textField.frame.height - kbSize.height/4, view.frame.width,  kbSize.height/4)
        
        searchResultsTableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0)
        //searchResultsTableView.setContentOffset(CGPointMake(0.0, -kbSize.height), animated: true)
    }
    
    func keyboardWasHiden (aNotification: NSNotification){
        //self.searchResultsTableView.frame = CGRectMake(0, searchBar.frame.height, view.frame.width, view.frame.height - searchBar.frame.height )
        //CGRectMake(0, searchBar.frame.height, view.frame.width, view.frame.height - searchBar.frame.height - 40)
        //button.frame = CGRectMake(0, textField.frame.origin.y + textField.frame.height, view.frame.width,  kbSize.height/4)
        //        label.frame = CGRectMake(0, textField.frame.origin.y + textField.frame.height - kbSize.height/4, view.frame.width,  kbSize.height/4)
        
        //searchResultsTableView.setContentOffset(CGPointMake(0.0, 0.0), animated: true);
        searchResultsTableView.contentInset = UIEdgeInsetsZero;
    }
    
    override func viewWillBeCovered(animated: Bool) {
        searchBar.resignFirstResponder()
    }
    
    override func viewWillBeUncovered(animated: Bool) {
        searchBar.becomeFirstResponder()
    }
    
    
    func sortArray(){
        
        filteredObjects.sort{
            var previous: String!
            var next: String!
            if let tour = $1 as? CuratorGroup {
                next = tour.title
            }
            if let art = $1 as? ArtObject {
                next = art.title
            }
            if let tour = $0 as? CuratorGroup {
                previous = tour.title
            }
            if let art = $0 as? ArtObject {
                previous = art.title
            }
            if let artist = $1 as? Artist {
                next = artist.name
            }
            if let artist = $0 as? Artist {
                previous = artist.name
            }
            return (previous < next)
        }
    
    }
    
/// MARK: Prepare Cells for tableView
    
    func prepareTourCell(curator: CuratorGroup, indexPath: NSIndexPath, cell: TourCell) -> TourCell {
        
        
            let tour = curator
                
            cell.selectionStyle = UITableViewCellSelectionStyle.Gray
            cell.imgArt.image = UIImage()
            cell.lblArtist.text = ""
            
            cell.lblArtist.font = SpotzerConfiguration.Fonts.regular(13)
            cell.lblArt.font = SpotzerConfiguration.Fonts.bold(15)
            cell.lblTime.font = SpotzerConfiguration.Fonts.regular(12)
            cell.lblTime.hidden = true
            cell.imgTime.hidden = true
            
            if let title = tour.title as String? {
                cell.lblArt.text = title
            }
            if let artist = tour.curator as String? {
                cell.lblArtist.text = artist
            }
            if let time = tour.duration as String? {
                cell.lblTime.text = time
                cell.lblTime.hidden = false
                cell.imgTime.hidden = false
            }
            if let thumbUrl: String = tour.thumbUrl {
                cell.imgArt.getImageWithURL(thumbUrl)
            }
            
            
            cell.selectionStyle = UITableViewCellSelectionStyle.Gray
            
            if cell.respondsToSelector(Selector("layoutMargins")) {
                
                cell.layoutMargins = UIEdgeInsetsZero
            }
            
            return cell
                
        
        }
        
    func prepareExhibitionCell(curator: CuratorGroup, indexPath: NSIndexPath, cell: ExhibitionCell) -> ExhibitionCell {
        
        
        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
        cell.imgArt.image = UIImage()
        cell.lblArtist.text = ""
        
        cell.lblArtist.font = SpotzerConfiguration.Fonts.regular(13)
        cell.lblArt.font = SpotzerConfiguration.Fonts.bold(15)
        cell.lblLocation.font = SpotzerConfiguration.Fonts.regular(12)
        cell.lblLocation.hidden = true
        cell.imgLocation.hidden = true
        
        if let title = curator.title as String? {
            cell.lblArt.text = title
        }
        if let artist = curator.curator as String? {
            cell.lblArtist.text = artist
        }
        
        if let thumbUrl: String = curator.thumbUrl {
            cell.imgArt.getImageWithURL(thumbUrl)
        }
        
        if let location = curator.location as String? {
            cell.lblLocation.hidden = false
            cell.lblLocation.text = location
            cell.imgLocation.hidden = false
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
        
        if cell.respondsToSelector(Selector("layoutMargins")) {
            
            cell.layoutMargins = UIEdgeInsetsZero
        }
        
        return cell as ExhibitionCell
        
        
    }
    
    func prepareArtObjectCell(art: ArtObject, indexPath: NSIndexPath, cell: SearchArtCell) -> SearchArtCell {
        
        cell.imgArt.image = UIImage()
        cell.lblArtist.text = ""
        cell.lblArt.text = art.title
        cell.lblArt.font = SpotzerConfiguration.Fonts.bold(15)
        cell.lblArtist.font = SpotzerConfiguration.Fonts.regular(13)
        cell.lblLocation.hidden = true
        
        if let location = art.location {
            println("Location: \(location)")
            cell.lblLocation.hidden = false
            cell.lblLocation.font = SpotzerConfiguration.Fonts.regular(13)
            cell.imgLocation.hidden = false
            cell.lblLocation.text = location
        } else {
            cell.lblLocation.hidden = true
            cell.imgLocation.hidden = true
        }
        
        if let artist = db.getArtist(art.artistId)?.name as String? {
            cell.lblArtist.text = artist
        }
         
        if let thumbUrl: String = art.thumbUrl {
            cell.imgArt.getImageWithURL(thumbUrl)
        }

    
        
        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
        
        if cell.respondsToSelector(Selector("layoutMargins")) {
        
            cell.layoutMargins = UIEdgeInsetsZero
        }
        
        return cell
    }
    
    func prepareArtistCell(artist: Artist, indexPath: NSIndexPath, cell: ArtistCell) -> ArtistCell {
        
        
        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
        cell.imgArtist.image = UIImage()
        cell.lblArtist.text = ""
        
        cell.lblArtist.font = SpotzerConfiguration.Fonts.bold(15)
        
        
       
        if let name = artist.name as String? {
            cell.lblArtist.text = name
        }
        
        if let thumbUrl: String = artist.thumbUrl {
            cell.imgArtist.getImageWithURL(thumbUrl)
        } else {
            var arts = self.db.getArtObjects(artistId: artist.id)
            for var i = 0; i < arts.count ; i++  {
                if arts[i].thumbUrl != nil {
                    cell.imgArtist.getImageWithURL(arts[i].thumbUrl!)
                    break
                }
            }
            if arts.count == 0 {
                cell.imgArtist.image = UIImage(named: "no avatar")
            }
        }

        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
        
        if cell.respondsToSelector(Selector("layoutMargins")) {
            
            cell.layoutMargins = UIEdgeInsetsZero
        }
        
        return cell

        
    }
    
}
