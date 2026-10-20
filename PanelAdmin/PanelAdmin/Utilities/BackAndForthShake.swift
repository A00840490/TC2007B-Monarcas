//
//  BackAndForthShake.swift
//  PanelAdmin
//

import SwiftUI
import UIKit
import Combine
import CoreMotion

class BackAndForthShakeDetector
{
    let motionManager = CMMotionManager()
    
    let minimumForce = 0.9
    let maximumGap = 0.45
    let peaksNeeded = 3
    
    var peaks = 0
    var lastDirection = 0.0
    var lastPeakTime = 0.0
    var lastShakeTime = 0.0
    
    var isAvailable: Bool
    {
        motionManager.isDeviceMotionAvailable
    }
    
    func start(onShake: @escaping () -> Void)
    {
        if !isAvailable || motionManager.isDeviceMotionActive { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main)
        { [weak self] motion, _ in
            guard let self, let motion else { return }
            
            if self.isShake(motion.userAcceleration, time: motion.timestamp)
            {
                onShake()
            }
        }
    }
    
    func stop()
    {
        motionManager.stopDeviceMotionUpdates()
        peaks = 0
    }
    
    func isShake(_ acceleration: CMAcceleration, time: Double) -> Bool
    {
        let z = acceleration.z
        let sideways = max(abs(acceleration.x), abs(acceleration.y))
        
        if time - lastPeakTime > maximumGap
        {
            peaks = 0
            lastDirection = 0
        }
        
        if time - lastShakeTime < 1.5 { return false }
        if abs(z) < minimumForce { return false }
        if abs(z) < sideways * 1.5 { return false }
        
        let direction = z > 0 ? 1.0 : -1.0
        lastPeakTime = time
        
        if direction == lastDirection { return false }
        
        lastDirection = direction
        peaks += 1
        
        if peaks < peaksNeeded { return false }
        
        peaks = 0
        lastDirection = 0
        lastShakeTime = time
        return true
    }
}

extension Notification.Name
{
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow
{
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
    {
        super.motionEnded(motion, with: event)
        
        if motion == .motionShake
        {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}

struct BackAndForthShakeModifier: ViewModifier
{
    let action: () -> Void
    
    @State private var detector = BackAndForthShakeDetector()
    @Environment(\.scenePhase) private var scenePhase
    
    func body(content: Content) -> some View
    {
        content
            .onAppear
            {
                detector.start(onShake: action)
            }
            .onDisappear
            {
                detector.stop()
            }
            .onChange(of: scenePhase)
            {
                if scenePhase == .active
                {
                    detector.start(onShake: action)
                }
                else
                {
                    detector.stop()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake))
            { _ in
                if !detector.isAvailable
                {
                    action()
                }
            }
    }
}

extension View
{
    func onBackAndForthShake(perform action: @escaping () -> Void) -> some View
    {
        modifier(BackAndForthShakeModifier(action: action))
    }
}
