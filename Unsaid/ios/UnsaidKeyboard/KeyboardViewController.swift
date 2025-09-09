//
//  KeyboardViewController.swift
//  UnsaidKeyboard
//
//  Created by John  Gray on 8/22/25.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    
    private var keyboardController: KeyboardController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the custom keyboard controller
        keyboardController = KeyboardController(frame: view.bounds, inputViewStyle: .default)
        keyboardController?.configure(with: self)
        
        // Set up the keyboard view
        if let keyboardView = keyboardController {
            view.addSubview(keyboardView)
            keyboardView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
                keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        // KeyboardController handles its own constraints
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        keyboardController?.frame = view.bounds
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        // KeyboardController will get the textDocumentProxy changes automatically
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        // KeyboardController will get the textDocumentProxy changes automatically
    }
}
