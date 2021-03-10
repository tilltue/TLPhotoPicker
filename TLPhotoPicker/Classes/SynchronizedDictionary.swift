//
//  SynchronizedDictionary.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 30/03/2019.
//

import Foundation
import Combine

public class SynchronizedDictionary<K:Hashable,V> {
    private var dictionary: [K:V] = [:]
    private let accessQueue = DispatchQueue(label: "SynchronizedDictionaryAccess",
                                            attributes: .concurrent)
    
    deinit {
        //print("deinit SynchronizedDictionary")
    }
    
    public func removeAll() {
        self.accessQueue.async(flags:.barrier) {
            self.dictionary.removeAll()
        }
    }
    
    public func removeValue(forKey: K) {
        self.accessQueue.async(flags:.barrier) {
            self.dictionary.removeValue(forKey: forKey)
        }
    }
    
    public func forEach(_ closure: @escaping ((K,V) -> Void)) {
        self.accessQueue.async {
            self.dictionary.forEach{ arg in
                let (key, value) = arg
                closure(key,value)
            }
        }
    }
    
    public enum Error: Swift.Error {
        case couldNotSetKey
        case couldNotGetValue
    }
    
    @available(iOS 13.0, *)
    public func set(key: K, value: V) -> Future<Void, Error> {
        return .init { [weak self] promise in
            guard let self = self else { return promise(.failure(Error.couldNotSetKey)) }
            self.accessQueue.async(flags:.barrier) {
                self.dictionary[key] = value
                promise(.success(()))
            }
        }
    }
    
    @available(iOS 13.0, *)
    public func get(key: K) -> Future<V, Error> {
        return .init { [weak self] promise in
            guard let self = self else { return promise(.failure(Error.couldNotGetValue)) }
            var element: V?
            self.accessQueue.async {
                element = self.dictionary[key]
                if let element = element {
                    promise(.success(element))
                } else {
                    promise(.failure(Error.couldNotGetValue))
                }
            }
        }
    }
    
    public subscript(key: K) -> V? {
        set {
            self.accessQueue.async(flags:.barrier) {
                self.dictionary[key] = newValue
            }
        }
        get {
            var element: V?
            self.accessQueue.sync {
                element = self.dictionary[key]
            }
            return element
        }
    }
}
