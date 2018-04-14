//
//  WhiskyService.swift
//  WhiskyClub
//
//  Created by Martin Mitrevski on 13.04.18.
//  Copyright © 2018 Mitrevski. All rights reserved.
//

import Foundation

class WhiskyService {
    static let shared = WhiskyService()
    let whiskyInfo: Array<[String: Any]>
    
    private init() {
        whiskyInfo = loadWhiskies()
    }
    
    func whiskyInfo(forLabel label: String) -> [String: Any] {
        for whisky in whiskyInfo {
            if let whiskyLabel = whisky["label"] as? String {
                if whiskyLabel == label {
                    return whisky
                }
            }
        }
        return [String: Any]()
    }
    
}

func loadWhiskies() -> Array<[String: Any]> {
    var whiskyArray = Array<[String: Any]>()
    let whiskiesUrl = Bundle.main.url(forResource: "whiskies", withExtension: "json")!
    do {
        let whiskyData = try Data.init(contentsOf: whiskiesUrl)
        let whiskyMeta = try JSONSerialization.jsonObject(with: whiskyData,
                                                      options: .allowFragments) as! [String: Any]
        whiskyArray = whiskyMeta["whiskies"] as! Array<[String: Any]>
    } catch {
        print("error loading whiskies info")
    }
    return whiskyArray
}
