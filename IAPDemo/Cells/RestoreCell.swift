//
//  RestoreCell.swift
//  IAPDemo
//
//  Created by Russell Archer on 23/11/2020.
//

import UIKit

/// Implement this delegate method to receive requests to purchase a product.
protocol RestoreCellDelegate: class {
    func requestRestore()
}

/// RestoreCell provides a cell with a "Restore Purchases" button and a UIActivityIndicatorView
/// that allows the user to restore previously purchased products.
class RestoreCell: UITableViewCell {

    public static let reuseId = "RestoreCell"
    public static let cellHeight = CGFloat(55)
    
    /// Set this delegate to be informed when the user requests purchases to be restored.
    public weak var delegate: RestoreCellDelegate?
    
    private var activityIndicator = UIActivityIndicatorView()
    private var restoreButton = UIButton()
    private var timer: Timer?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) { fatalError("Storyboard not supported") }
    
    private func configureCell() {
        // You must add subviews to the *contentView*
        contentView.addSubview(restoreButton)
        contentView.addSubview(activityIndicator)
        
        translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        restoreButton.translatesAutoresizingMaskIntoConstraints = false
        restoreButton.backgroundColor = .systemBlue
        restoreButton.setTitle("Restore Purchases", for: .normal)
        restoreButton.layer.cornerRadius = 10
        restoreButton.setTitleColor(.white, for: .normal)
        restoreButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        restoreButton.addTarget(self, action: #selector(restoreButtonTapped), for: .touchUpInside)
        
        // The layout of the cell is as follows:
        //
        // +-----------------------------+
        // | [ * ] [ Restore Purchases ] |
        // +-----------------------------+
        
        let padding: CGFloat = 5
        NSLayoutConstraint.activate([
            restoreButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2 * padding),
            restoreButton.heightAnchor.constraint(equalToConstant: 30),
            restoreButton.widthAnchor.constraint(equalToConstant: 170),
            restoreButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            activityIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            activityIndicator.leadingAnchor.constraint(equalTo: restoreButton.leadingAnchor, constant: -50),
            activityIndicator.heightAnchor.constraint(equalToConstant: 40),
            activityIndicator.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc internal func restoreButtonTapped() {
        // When purchases are restored the ViewController containing the UITableView that shows
        // products will reload the data. This will have the effect of turning off the activity
        // indicator. However, we have no way of knowing if the user has any purchases that can
        // be restored. If there is nothing to be restored then the App Store doesn't provide
        // any kind of feedback. Thus there's no way to know if/when we should turn off the
        // spinner. So, we set a timer for 5 secs. When the timer goes off we turn off the spinner.
        activityIndicator.startAnimating()
        restoreButton.isEnabled = false
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.restoreButton.isEnabled = true
            }
        }
        
        delegate?.requestRestore()
    }
}

