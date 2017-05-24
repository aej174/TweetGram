//
//  ViewController.swift
//  TweetGram
//
//  Created by ALLAN E JONES on 5/16/17.
//  Copyright © 2017 ALLAN E JONES. All rights reserved.
//

import Cocoa
import OAuthSwift
import SwiftyJSON
import Kingfisher

class ViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource {
        
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var loginLogoutButton: NSButton!
    
    var imageURLs : [String] = []
    var tweetURLs : [String] = []
    
    // create an instance and retain it
    let oauthswift = OAuth1Swift(
        consumerKey:    "NwU0VGL2cr6usrbQEWVef6hiq",
        consumerSecret: "Vp9ijih6XT6U744xDb0P5FMRmlohqx62eMQrvBgOAmni4naCuP",
        requestTokenUrl: "https://api.twitter.com/oauth/request_token",
        authorizeUrl:    "https://api.twitter.com/oauth/authorize",
        accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 300, height: 300)
        layout.sectionInset = EdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        layout.minimumLineSpacing = 10.0
        layout.minimumInteritemSpacing = 10.0
        collectionView.collectionViewLayout = layout
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        checkLogin()
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        print("We have \(imageURLs.count) pictures")
        return imageURLs.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "TweetGramItem", for: indexPath)
        
        let urlString = imageURLs[indexPath.item]
        let url = URL(string: urlString)
        item.imageView?.kf.setImage(with: url)
        
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        collectionView.deselectAll(nil)
        if let indexPath = indexPaths.first {
            if let url = URL(string: tweetURLs[indexPath.item]) {
                NSWorkspace.shared().open(url)
            }
        }
        
    }
    
    func checkLogin() {
        
        if let oauthToken = UserDefaults.standard.string(forKey: "oauthToken") {
            if let oauthTokenSecret = UserDefaults.standard.string(forKey: "oauthTokenSecret") {
                
                oauthswift.client.credential.oauthToken = oauthToken
                oauthswift.client.credential.oauthTokenSecret = oauthTokenSecret
                getTweets()
                loginLogoutButton.title = "Logout"
            }
        }
    }
    
    @IBAction func loginLogoutClicked(_ sender: Any) {
        
        if loginLogoutButton.title == "Login" {
            logIn()
        } else {
            logOut()
        }
    }
    
    func logOut() {
        
        loginLogoutButton.title = "Login"
        UserDefaults.standard.removeObject(forKey: "oauthToken")
        UserDefaults.standard.removeObject(forKey: "oauthTokenSecret")
        UserDefaults.standard.synchronize()
        imageURLs = []
        tweetURLs = []
        collectionView.reloadData()
    }

    func logIn() {        
        let _ = oauthswift.authorize(
            withCallbackURL: URL(string: "TweetGram://wemadeit")!,
            success: { credential, response, parameters in
                
                UserDefaults.standard.setValue(credential.oauthToken, forKey: "oauthToken")
                UserDefaults.standard.setValue(credential.oauthTokenSecret, forKey: "oauthTokenSecret")
                UserDefaults.standard.synchronize()
                
                self.loginLogoutButton.title = "Logout"
                self.getTweets()
                
        },
            failure: { error in
                print(error.localizedDescription)
        }             
        )
    }
    
    func getTweets() {
        let _ = oauthswift.client.get("https://api.twitter.com/1.1/statuses/home_timeline.json", parameters: ["tweet_mode":"extended","count":100],
            success: { response in
                
                if let dataString = response.string {
                    print(dataString)
                }
                
                let json = JSON(data: response.data)
                
                for (_ ,tweetJson):(String, JSON) in json {
                    
                    var retweeted = false
                    for (_ ,mediaJson):(String, JSON) in tweetJson["retweeted_status"]["entities"]["media"] {
                        retweeted = true

                        if let url = mediaJson["media_url_https"].string {
                            self.imageURLs.append(url)
                        }
                        if let expandedURL = mediaJson["expanded_url"].string {
                            self.tweetURLs.append(expandedURL)
                        }
                    }
                    
                    if retweeted == false {
                        for (_ ,mediaJson):(String, JSON) in tweetJson["entities"]["media"] {
                            if let url = mediaJson["media_url_https"].string {
                                self.imageURLs.append(url)
                            }
                            if let expandedURL = mediaJson["expanded_url"].string {
                                self.tweetURLs.append(expandedURL)
                            }
                        }
                    }
                }
                print(self.imageURLs)
                self.collectionView.reloadData()
                
            },
            failure: { error in
            print(error)
                
        }
        )
    }

}

