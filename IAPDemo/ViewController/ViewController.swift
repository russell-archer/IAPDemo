//
//  ViewController.swift
//  IAPTestingDemo
//
//  Created by Russell Archer on 23/06/2020.
//

import UIKit
import IAPHelper

class ViewController: UIViewController {
    
    private var tableView = UITableView(frame: .zero)
    private let iap = IAPHelper.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        configureProducts()
        
        iap.receiveNotifications { notification in
            // Respond to general notifications
        }
    }
    
    func configureTableView() {
        view.addSubview(tableView)
       
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
       
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)  // Removes empty cells
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.reuseId)
        tableView.register(RestoreCell.self, forCellReuseIdentifier: RestoreCell.reuseId)
    }
    
    func configureProducts() {
        iap.requestProductsFromAppStore { notification in
            
            if notification == IAPNotification.requestProductsSuccess {
                
                self.iap.processReceipt()
                self.tableView.reloadData()
            }
        }
    }
}

// MARK:- UITableViewDelegate, UITableViewDataSource

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    internal func numberOfSections(in tableView: UITableView) -> Int { 2 }

    internal func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 { return RestoreCell.cellHeight }
        
        var purchased = false
        if let p = iap.products?[indexPath.row], iap.isProductPurchased(id: p.productIdentifier) { purchased = true }
        
        return purchased ? ProductCell.cellHeightPurchased : ProductCell.cellHeightUnPurchased
    }
        
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return iap.products == nil ? 0 : iap.products!.count }
        else { return 1 }
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 { return configureProductCell(for: indexPath) }
        return configureRestoreCell()
    }
    
    private func configureProductCell(for indexPath: IndexPath) -> ProductCell {
        guard let products = iap.products else { return ProductCell() }
        
        let product = products[indexPath.row]
        var price =  IAPHelper.getLocalizedPriceFor(product: product)
        if price == nil { price = "Price unknown" }
        
        let productInfo = IAPProductInfo(id: product.productIdentifier,
                                         imageName: product.productIdentifier,
                                         localizedTitle: product.localizedTitle,
                                         localizedDescription: product.localizedDescription,
                                         localizedPrice: price!,
                                         purchased: iap.isProductPurchased(id: product.productIdentifier))
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.reuseId) as! ProductCell
        cell.delegate = self
        cell.productInfo = productInfo
        
        return cell
    }
    
    private func configureRestoreCell() -> RestoreCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RestoreCell.reuseId) as! RestoreCell
        cell.delegate = self
        return cell
    }
}

// MARK:- ProductCellDelegate

extension ViewController: ProductCellDelegate {
    
    internal func requestBuyProduct(productId: ProductId) {
        guard let product = iap.getStoreProductFrom(id: productId) else { return }
        
        iap.buyProduct(product) { notification in
            switch notification {
            case .purchaseAbortPurchaseInProgress: IAPLog.event("Purchase aborted because another purchase is being processed")
            case .purchaseCancelled(productId: let pid): IAPLog.event("Purchase cancelled for product \(pid)")
            case .purchaseFailure(productId: let pid): IAPLog.event("Purchase failure for product \(pid)")
            case .purchaseSuccess(productId: let pid):
                
                IAPLog.event("Purchase success for product \(pid)")
                self.iap.processReceipt()
            
            default: break
            }
            
            self.tableView.reloadData()  // Reload data for a success, cancel or failure to clear the spinner
        }
    }
}

// MARK:- RestoreCellDelegate

extension ViewController: RestoreCellDelegate {
    
    internal func requestRestore() {
        iap.restorePurchases() { notification in
            
            switch notification {
            case .purchaseRestoreSuccess(productId:): fallthrough
            case .purchaseRestoreFailure(productId:):
                
                self.iap.processReceipt()
                self.tableView.reloadData()  // Reload data for a success or failure
            
            default: break
            }
        }
    }
}


