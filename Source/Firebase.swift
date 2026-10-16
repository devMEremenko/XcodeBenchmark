//
// Firebase.swift
// XcodeBenchmark
//
// Created on 18.08.2020.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseAnalytics
import FirebaseRemoteConfig
import FirebaseStorage
import FirebaseMessaging
import FirebaseABTesting
import FirebaseInstallations

public enum Factory {
    public static func printAll() {
        print(Storage.self)
        print(Firestore.self)
        print(Messaging.self)
        print(RemoteConfig.self)
        print(Firestore.self)
        print(Analytics.self)
        print(RemoteConfig.self)
    }
}
