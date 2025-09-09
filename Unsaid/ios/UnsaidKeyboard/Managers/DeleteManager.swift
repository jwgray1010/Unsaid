//
//  DeleteManager.swift
//  UnsaidKeyboard
//
//  Handles delete repeat functionality and delete-related logic
//

import Foundation
import UIKit

protocol DeleteManagerDelegate: AnyObject {
    func performDelete()
    func performDeleteTick()
}

final class DeleteManager {
    weak var delegate: DeleteManagerDelegate?
    
    // Delete repeat
    private var deleteTimer: Timer?
    private var deleteInterval: TimeInterval = 0.12
    private var deletePressBeganAt: CFTimeInterval = 0
    private var deleteDidRepeat = false
    private var deleteInitialTimer: Timer?
    
    init() {}
    
    deinit {
        stopDeleteRepeat()
    }
    
    // MARK: - Public Interface
    
    func beginDeleteRepeat() {
        deletePressBeganAt = CACurrentMediaTime()
        deleteDidRepeat = false
        
        // Initial delete happens immediately
        delegate?.performDelete()
        
        // Start timer for repeat behavior
        deleteInitialTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.startDeleteRepeat()
        }
    }
    
    func endDeleteRepeat() {
        stopDeleteRepeat()
    }
    
    // MARK: - Private Implementation
    
    private func startDeleteRepeat() {
        deleteTimer?.invalidate()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: deleteInterval, repeats: true) { [weak self] _ in
            self?.handleDeleteRepeat()
        }
        RunLoop.current.add(deleteTimer!, forMode: .common)
    }
    
    @objc private func handleDeleteRepeat() {
        deleteDidRepeat = true
        delegate?.performDeleteTick()
        
        // Accelerate delete speed over time
        if deleteInterval > 0.04 {
            deleteInterval *= 0.92
            deleteTimer?.invalidate()
            startDeleteRepeat()
        }
    }
    
    private func stopDeleteRepeat() {
        deleteInitialTimer?.invalidate()
        deleteTimer?.invalidate()
        deleteInitialTimer = nil
        deleteTimer = nil
        deleteInterval = 0.12 // Reset to default
    }
}
