//
//  ProductCell.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 09/07/2020.
//

import UIKit

/// Implement this delegate method to receive requests to purchase a product.
protocol ProductCellDelegate: class {
    func requestBuyProduct(productId: ProductId)
}

/// ProductCell provides information on a product and a "Buy" button.
/// An image for each product is stored in the Assets catalog.
/// The image name is the product id (e.g. com.rarcher.flowers-large).
/// All images are copyright free from Pixabay.com.
class ProductCell: UITableViewCell {
    
    public static let reuseId = "ProductCell"
    public static let cellHeightPurchased = CGFloat(100)
    public static let cellHeightUnPurchased = CGFloat(135)
    
    /// Set this delegate to be informed when the user requests a purchase to be made.
    public weak var delegate: ProductCellDelegate?
    
    private var id: ProductId?
    private var imgView = UIImageView()
    private var localizedTitleLabel = UILabel()
    private var localizedDescriptionLabel = UILabel()
    private var localizedPriceLabel = UILabel()
    private var purchasedLabel = UILabel()
    private var activityIndicator = UIActivityIndicatorView()
    private var buyButton = UIButton()
    
    /// Set this property to provide the cell with required product information.
    public var productInfo: IAPProductInfo? {
        didSet {
            guard let pInfo = productInfo else { return }
            
            imgView.image = UIImage(named: pInfo.imageName)
            localizedTitleLabel.text = pInfo.localizedTitle
            localizedDescriptionLabel.text = pInfo.localizedDescription
            localizedPriceLabel.text = String(pInfo.localizedPrice)
            purchasedLabel.text = pInfo.purchased ? "(purchased)" : "(available to purchase)"

            if pInfo.purchased { buyButton.isHidden = true }
            else {
                buyButton.isEnabled = true
                buyButton.addTarget(self, action: #selector(buyButtonTapped), for: .touchUpInside)
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) { fatalError("Storyboard not supported") }
    
    private func configureCell() {
        // You must add subviews to the *contentView*
        contentView.addSubview(imgView)
        contentView.addSubview(localizedTitleLabel)
        contentView.addSubview(localizedDescriptionLabel)
        contentView.addSubview(localizedPriceLabel)
        contentView.addSubview(purchasedLabel)
        contentView.addSubview(activityIndicator)
        contentView.addSubview(buyButton)
        
        localizedTitleLabel.font = UIFont.preferredFont(forTextStyle: .title1)  // Use text styles to support dynamic type
        localizedTitleLabel.adjustsFontForContentSizeCategory = true  // Dynamic type on
        localizedTitleLabel.adjustsFontSizeToFitWidth = true  // Shrink text if necessary to fit the given width
        
        localizedDescriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        localizedDescriptionLabel.adjustsFontForContentSizeCategory = true
        localizedDescriptionLabel.adjustsFontSizeToFitWidth = true
        
        localizedPriceLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        localizedPriceLabel.adjustsFontForContentSizeCategory = true
        localizedPriceLabel.adjustsFontSizeToFitWidth = true
        
        purchasedLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        purchasedLabel.adjustsFontForContentSizeCategory = true
        purchasedLabel.adjustsFontSizeToFitWidth = true
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        
        buyButton.backgroundColor = .systemGreen
        buyButton.setTitle("Buy", for: .normal)
        buyButton.layer.cornerRadius = 10
        buyButton.setTitleColor(.white, for: .normal)
        buyButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        
        translatesAutoresizingMaskIntoConstraints = false
        imgView.translatesAutoresizingMaskIntoConstraints = false
        localizedTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        localizedDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        localizedPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        purchasedLabel.translatesAutoresizingMaskIntoConstraints = false
        buyButton.translatesAutoresizingMaskIntoConstraints = false

        // The layout of the cell is as follows:
        //
        // +-----------------------------------------+
        // | +---------+ [Title                    ] |
        // | |  image  | [Description              ] |
        // | +---------+ [Price       ] [Purchased?] |
        // |           [ * ] [   Buy   ]             |
        // +-----------------------------------------+
        
        let padding: CGFloat = 5
        NSLayoutConstraint.activate([
            imgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2 * padding),
            imgView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            imgView.heightAnchor.constraint(equalToConstant: 75),
            imgView.widthAnchor.constraint(equalToConstant: 75),
            
            localizedTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            localizedTitleLabel.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: 2 * padding),
            localizedTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            localizedPriceLabel.heightAnchor.constraint(equalToConstant: 20),
            
            localizedDescriptionLabel.topAnchor.constraint(equalTo: localizedTitleLabel.bottomAnchor, constant: padding),
            localizedDescriptionLabel.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: 2 * padding),
            localizedDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            localizedDescriptionLabel.heightAnchor.constraint(equalToConstant: 20),
            
            localizedPriceLabel.topAnchor.constraint(equalTo: localizedDescriptionLabel.bottomAnchor, constant: padding),
            localizedPriceLabel.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: 2 * padding),
            localizedPriceLabel.heightAnchor.constraint(equalToConstant: 20),
            localizedPriceLabel.widthAnchor.constraint(equalToConstant: 40),
            
            purchasedLabel.topAnchor.constraint(equalTo: localizedDescriptionLabel.bottomAnchor, constant: padding),
            purchasedLabel.leadingAnchor.constraint(equalTo: localizedPriceLabel.trailingAnchor, constant: 2 * padding),
            purchasedLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            purchasedLabel.heightAnchor.constraint(equalToConstant: 20),
            
            buyButton.topAnchor.constraint(equalTo: localizedPriceLabel.bottomAnchor, constant: 2 * padding),
            buyButton.heightAnchor.constraint(equalToConstant: 28),
            buyButton.widthAnchor.constraint(equalToConstant: 170),
            buyButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            activityIndicator.topAnchor.constraint(equalTo: localizedPriceLabel.bottomAnchor, constant: padding),
            activityIndicator.leadingAnchor.constraint(equalTo: buyButton.leadingAnchor, constant: -50),
            activityIndicator.heightAnchor.constraint(equalToConstant: 40),
            activityIndicator.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc internal func buyButtonTapped() {
        activityIndicator.startAnimating()
        buyButton.isEnabled = false
        delegate?.requestBuyProduct(productId: productInfo!.id)
    }
}

