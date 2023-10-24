//
//  NetworkCheck.swift
//  mNativeUpdater
//
//  Created by Yinwei Z on 10/24/23.
//

import Network

class NetworkCheck {
    private var monitor: NWPathMonitor
    private var queue: DispatchQueue
    
    init() {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "NetworkCheck")
    }
    
    func startMonitoring(completion: @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                completion(true)
            } else {
                completion(false)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}
