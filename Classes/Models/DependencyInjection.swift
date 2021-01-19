//
//  DependencyInjection.swift
//  iSub
//
//  Created by Benjamin Baron on 1/6/21.
//  Copyright © 2021 Ben Baron. All rights reserved.
//

import Foundation
import Resolver

struct DependencyInjection {
    private static let resolver = Resolver()
    
    static func setupRegistrations() {
        let main = Resolver.main
        
        // Singletons
        main.register(factory: { Store() as Store }).scope(Resolver.application)
        main.register(factory: { Settings.shared() as Settings }).scope(Resolver.application)
        main.register(factory: { ViewObjects.shared() as ViewObjects }).scope(Resolver.application)
        main.register(factory: { AudioEngine.shared() as AudioEngine }).scope(Resolver.application)
        main.register(factory: { Music.shared() as Music }).scope(Resolver.application)
        main.register(factory: { PlayQueue() as PlayQueue }).scope(Resolver.application)
        main.register(factory: { Cache.shared() as Cache }).scope(Resolver.application)
        main.register(factory: { CacheQueue.shared() as CacheQueue }).scope(Resolver.application)
        main.register(factory: { StreamManager.shared() as StreamManager }).scope(Resolver.application)
        main.register(factory: { Jukebox.shared() as Jukebox }).scope(Resolver.application)
    }
}
