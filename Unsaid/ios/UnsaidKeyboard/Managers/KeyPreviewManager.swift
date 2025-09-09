//
//  KeyPreviewManager.swift
//  UnsaidKeyboard
//
//  Manages key preview balloons that appear above keys when pressed
//

import Foundation
import UIKit

final class KeyPreviewManager {
    private let keyPreviewTable = NSMapTable<UIButton, KeyPreview>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var keyPreviewAutoDismissTimers = [UIButton: Timer]()
    
    init() {}
    
    deinit {
        dismissAllKeyPreviews()
    }
    
    // MARK: - Public Interface
    
    func showKeyPreview(for button: UIButton) {
        guard let title = button.title(for: .normal),
              !title.isEmpty,
              title.count == 1 else { return }
        
        // Remove existing preview for this button
        hideKeyPreview(for: button)
        
        // Create new preview
        let preview = KeyPreview(text: title)
        keyPreviewTable.setObject(preview, forKey: button)
        
        // Position preview above button
        guard let superview = button.superview else { return }
        superview.addSubview(preview)
        
        NSLayoutConstraint.activate([
            preview.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            preview.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -8)
        ])
        
        // Animate in
        preview.alpha = 0
        preview.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut]) {
            preview.alpha = 1
            preview.transform = .identity
        }
        
        // Auto-dismiss timer
        let timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
            self?.hideKeyPreview(for: button)
        }
        keyPreviewAutoDismissTimers[button] = timer
    }
    
    func hideKeyPreview(for button: UIButton) {
        // Cancel auto-dismiss timer
        keyPreviewAutoDismissTimers[button]?.invalidate()
        keyPreviewAutoDismissTimers.removeValue(forKey: button)
        
        // Remove preview with animation
        guard let preview = keyPreviewTable.object(forKey: button) else { return }
        
        UIView.animate(withDuration: 0.08, animations: {
            preview.alpha = 0
            preview.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            preview.removeFromSuperview()
        }
        
        keyPreviewTable.removeObject(forKey: button)
    }
    
    func dismissAllKeyPreviews() {
        // Cancel all timers
        keyPreviewAutoDismissTimers.values.forEach { $0.invalidate() }
        keyPreviewAutoDismissTimers.removeAll()
        
        // Remove all previews
        let enumerator = keyPreviewTable.objectEnumerator()
        while let preview = enumerator?.nextObject() as? KeyPreview {
            preview.removeFromSuperview()
        }
        keyPreviewTable.removeAllObjects()
    }
}

// MARK: - Key Preview Balloon
final class KeyPreview: UIView {
    private let label = UILabel()
    
    init(text: String) {
        super.init(frame: .zero)
        setupUI(text: text)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(text: String) {
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 6
        layer.shadowOffset = .init(width: 0, height: 2)
        
        label.text = text
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthAnchor.constraint(equalToConstant: 52),
            heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}
