//
// Firebase.swift
// XcodeBenchmark
//
// Created on 18.08.2020.
//

import Foundation
import Firebase
import FirebaseStorage
import FirebaseDatabase
import FirebaseABTesting
import FirebaseMessaging
import FirebaseFirestore
import FirebaseInstanceID
import FirebaseCoreDiagnostics
import FirebaseInstallations
import FirebaseCrashlytics
import FirebaseFirestoreSwift
import FirebaseRemoteConfig

public enum Factory {
    
    public static func printAll() {
        print(Storage.self)
        print(Database.self)
        print(Messaging.self)
        print(RemoteConfig.self)
        print(Firestore.self)
        print(InstanceID.self)
        print(Crashlytics.self)
        print(Analytics.self)
        print(RemoteConfig.self)
    }
}
