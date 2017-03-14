//
//  Webber.swift
//  Webber
//
//  Created by Seyyed Parsa Neshaei on 3/12/17.
//  Copyright © 2017 Seyyed Parsa Neshaei. All rights reserved.
//

import Foundation
import SystemConfiguration

public class Webber {
    
    /**
     Set this property to be used as server address once.
     */
    public static var server = ""
    
    
    /**
     Checks the connection to the Internet.
     
     - Returns: `true` if a valid connection to the Internet is found, otherwise `false`.
     */
    public static func isInternetAvailable() -> Bool{
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    /**
     Connects to an API using GET.
     
     - Parameters:
        - url: The relative URL to the specified server without slash at the beginning.
        - cache: Specifies where should content be loaded or saved in cache when offline.
     
     - Returns: A string containing the server result which may be `nil` if you are offline and `cache` is `false` or if the cache is cleared.
     */
    public static func getFromAPI(url: String, cache: Bool = true) -> String?{
        let defaults=UserDefaults.standard
        var text:String?
        if isInternetAvailable(){
            do{
                let url=URL(string: "\(server)/\(url)")
                text=try NSString(contentsOf: url!, encoding: String.Encoding.utf8.rawValue) as String
            }catch{
                print("Webber Error: \(error.localizedDescription)")
                return nil
            }
            if cache{
                defaults.set(text, forKey: "__WEBBER_OFFLINE_getFromAPI_\(server)/\(url)")
            }
        }else{
            if cache{
                text=defaults.string(forKey: "__WEBBER_OFFLINE_getFromAPI_\(server)/\(url)")
            }
        }
        return text
    }
    
    /**
     Connects to an API using GET asynchronous.
     
     - Parameters:
        - url: The relative URL to the specified server without slash at the beginning.
        - cache: Specifies where should content be loaded or saved in cache when offline.
        - offline: If `true`, `completion` is called twice, first after loading cache and then after downloading data, else it is called only once after downloading data.
        - completion: Things to do when data is received, for example updating a `UITableView`. The closure receives an optional parameter containing the result.
        - atLast: Things to do at last, for example stopping a `UIActivityIndicatorView`.
     
     */
    public static func asyncGetFromAPI(url: String, cache: Bool = true, offline: Bool = true, completion: @escaping (String?) -> Void, atLast: ((Void) -> Void)? = nil){
        var text:String?
        if offline{
            text=cacheGetFromAPI(url: url)
            completion(text)
        }
        let queue=DispatchQueue(label: "WebberAsyncGetFromAPI")
        queue.async {
            text=getFromAPI(url: url, cache: cache)
            DispatchQueue.main.async {
                if isInternetAvailable(){
                    completion(text)
                }
                if let atLastUnwrapped = atLast{
                    atLastUnwrapped()
                }
            }
        }
    }
    
    /**
     Returns the saved cache for a URL.
     
     - Parameters:
        - url: The relative URL to the specified server without slash at the beginning.
     
     - Returns: A string containing the cached server result which may be `nil` if no cache is saved or if the cache is cleared.
     
     */
    public static func cacheGetFromAPI(url: String) -> String?{
        let defaults=UserDefaults.standard
        return defaults.string(forKey: "__WEBBER_OFFLINE_getFromAPI_\(server)/\(url)")
    }
    
    /**
     Connects to an API using GET and parses the result in JSON.
     
     - Parameters:
     - url: The relative URL to the specified server without slash at the beginning.
     - cache: Specifies where should content be loaded or saved in cache when offline.
     
     - Returns: An array containing the server result parsed to JSON which may be `nil` if you are offline and `cache` is `false` or if the cache is cleared.
     */
    public static func getJSONArrayFromAPI(url: String, cache: Bool = true) -> [Any]?{
        let defaults=UserDefaults.standard
        var text:String?
        var arr:[Any]?
        if isInternetAvailable(){
            do{
                let url=URL(string: "\(server)/\(url)")
                text=try NSString(contentsOf: url!, encoding: String.Encoding.utf8.rawValue) as String
            }catch{
                print("Webber Error: \(error.localizedDescription)")
                return nil
            }
            if cache{
                defaults.set(text, forKey: "__WEBBER_OFFLINE_getJSONArrayFromAPI_\(server)/\(url)")
            }
        }else{
            if cache{
                text=defaults.string(forKey: "__WEBBER_OFFLINE_getJSONArrayFromAPI_\(server)/\(url)")
            }
        }
        do{
            if let t=text{
                let json = try JSONSerialization.jsonObject(with: t.data(using: String.Encoding.utf8)!, options: [])
                if let array=json as? [Any]{
                    arr=array
                }else{
                    return nil
                }
            }else{
                return nil
            }
        }catch{
            print("Webber Error: \(error.localizedDescription)")
            return nil
        }
        return arr
    }
    
    /**
     Returns the saved cache parsed to JSON for a URL.
     
     - Parameters:
     - url: The relative URL to the specified server without slash at the beginning.
     
     - Returns: An array containing the cached server parsed to JSON result which may be `nil` if no cache is saved or if the cache is cleared.
     
     */
    public static func cacheGetJSONArrayFromAPI(url: String) -> [Any]?{
        let defaults=UserDefaults.standard
        let text=defaults.string(forKey: "__WEBBER_OFFLINE_getJSONArrayFromAPI_\(server)/\(url)")
        var arr:[Any]?
        do{
            if let t=text{
                let json = try JSONSerialization.jsonObject(with: t.data(using: String.Encoding.utf8)!, options: [])
                if let array=json as? [Any]{
                    arr=array
                }else{
                    return nil
                }
            }else{
                return nil
            }
        }catch{
            print("Webber Error: \(error.localizedDescription)")
            return nil
        }
        return arr
    }
    
    /**
     Connects to an API using GET asynchronous and parses the result to JSON.
     
     - Parameters:
     - url: The relative URL to the specified server without slash at the beginning.
     - cache: Specifies where should content be loaded or saved in cache when offline.
     - offline: If `true`, `completion` is called twice, first after loading cache and then after downloading data, else it is called only once after downloading data.
     - completion: Things to do when data is received, for example updating a `UITableView`. The closure receives an optional parameter containing the result parsed to JSON.
     - atLast: Things to do at last, for example stopping a `UIActivityIndicatorView`.
     
     */
    public static func asyncGetJSONArrayFromAPI(url: String, cache: Bool = true, offline: Bool = true, completion: @escaping ([Any]?) -> Void, atLast: ((Void) -> Void)? = nil){
        var arr:[Any]?
        if offline{
            arr=cacheGetJSONArrayFromAPI(url: url)
            completion(arr)
        }
        let queue=DispatchQueue(label: "WebberAsyncGetFromAPI")
        queue.async {
            arr=getJSONArrayFromAPI(url: url, cache: cache)
            DispatchQueue.main.async {
                if isInternetAvailable(){
                    completion(arr)
                }
                if let atLastUnwrapped = atLast{
                    atLastUnwrapped()
                }
            }
        }
    }
}
