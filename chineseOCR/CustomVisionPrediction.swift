//
//  CustomVisionPrediction.swift
//  chineseOCR
//
//  Created by Tarun Kaushik on 22/06/18.
//  Copyright © 2018 Tarun Kaushik. All rights reserved.
//

import Foundation
import UIKit
struct CustomVisionPrediction {
    let TagId: String?
    let Tag: String?
    let Probability: Float?
    
    public init(json: [String: Any]) {
        let tagId = json["tagId"] as? String
        let tag = json["tagName"] as? String
        let probability = json["probability"] as? Double
        
        self.TagId = tagId
        self.Tag = tag
        self.Probability = Float(probability!)
    }
}

struct CustomVisionResult {
    let Id: String?
    let Project: String?
    let Iteration: String?
    let Created: String?
    let Predictions: [CustomVisionPrediction]
    
    public init(json: [String: Any]) throws {
        print(json)
        let id = json["id"] as? String
        let project = json["project"] as? String
        let iteration = json["iteration"] as? String
        let created = json["created"] as? String
        
        let predictionsJson = json["predictions"] as? [[String: Any]]
     
        
        var predictions = [CustomVisionPrediction]()
        for predictionJson in predictionsJson! {
            do
            {
                let cvp = CustomVisionPrediction(json: predictionJson)
                predictions.append(cvp)
            }
        }
        
        self.Id = id
        self.Project = project
        self.Iteration = iteration
        self.Created = created
        self.Predictions = predictions
    }
}

class CustomVisionService {
    var preductionUrl = "https://southcentralus.api.cognitive.microsoft.com/customvision/v2.0/Prediction/6b5fd38d-a29b-4738-aaa8-a6434869a84a/image?iterationId=6f7e5ded-b154-436d-abc9-d765858a4fb5"
    var predictionKey = "833b88bf74854e3dbcf041bea04cb3f7"
    var contentType = "application/octet-stream"
    
    var defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    func predict(image: Data, completion: @escaping (CustomVisionResult?, Error?) -> Void) {
        
        // Create URL Request
        var urlRequest = URLRequest(url: URL(string: preductionUrl)!)
        urlRequest.addValue(predictionKey, forHTTPHeaderField: "Prediction-Key")
        urlRequest.addValue(contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        
        // Cancel existing dataTask if active
        dataTask?.cancel()
        
        // Create new dataTask to upload image
        dataTask = defaultSession.uploadTask(with: urlRequest, from: image) { data, response, error in
            defer { self.dataTask = nil }
            
            if let error = error {
                completion(nil, error)
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                print(data)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let result = try? CustomVisionResult(json: json!) {
                    print(json,result)
                    completion(result, nil)
                }
            }
        }
        
        // Start the new dataTask
        dataTask?.resume()
}
    
}

