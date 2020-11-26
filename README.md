# In-App Purchases with Xcode 12 and iOS 14
Implementing and testing In-App Purchases in Xcode 12 and iOS 14

GitHub: https://github.com/russell-archer/IAPDemo
GitHub2: https://github.com/russell-archer/HelloIAPWorld

**Disclaimer**. The source code presented here is for educational purposes. You may freely reuse and amend this code for use in your own apps. 
However, you do so entirely at your own risk.

See **IAPDemo** on [GitHub](https://github.com/russell-archer/IAPDemo) for source code. 
The **HelloIAPWorld** source is [also available on GitHub](https://github.com/russell-archer/HelloIAPWorld).

References: 
[In-App Purchase Overview](https://developer.apple.com/in-app-purchase/) (Apple)
[Receipt Validation Programming Guide](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW2) (Apple archive but still useful)
[In-App Purchase](https://developer.apple.com/documentation/storekit/in-app_purchase) (Apple)
[Choosing a Receipt Validation Technique](https://developer.apple.com/documentation/storekit/in-app_purchase/choosing_a_receipt_validation_technique) (Apple)
[Validating Receipts with the App Store](https://developer.apple.com/documentation/storekit/in-app_purchase/validating_receipts_with_the_app_store) (Apple)
[In-App Purchases: Receipt Validation Tutorial](https://www.raywenderlich.com/9257-in-app-purchases-receipt-validation-tutorial) (Ray Wenderlich)
[Local Receipt Validation for iOS in Swift From Start to Finish](https://www.andrewcbancroft.com/2017/08/01/local-receipt-validation-swift-start-finish/) (Andrew Bancroft)
[Swifty Local Receipt Validator](https://github.com/andrewcbancroft/SwiftyLocalReceiptValidator) (Andrew Bancroft)
[Receipt Validation – Verifying a Receipt Signature in Swift](https://www.andrewcbancroft.com/2017/07/16/receipt-validation-verifying-a-receipt-signature-in-swift/) (Andrew Bancroft)
[Receipt Validation](https://www.objc.io/issues/17-security/receipt-validation/) (Laurent Etiemble, Objc)

---

# Contents

---

# Overview

The code we write to manage in-app purchases is critically important to the success of our apps. However, if you’ve not tackled it before, implementing and 
testing in-app purchases is daunting, complex and seems *way* more involved than you’d expect!

Anybody wanting to support in-app purchases faces a similar set of challenges:

- How do you define the set of products that can be purchased in your app?
- Defining your in-app purchases in App Store Connect
- Working with **`StoreKit`** to request *localized* product data from the App Store and initiate purchases
- Implementing **`StoreKit`** delegate methods to process async notifications for purchase success, failure, restoring purchases, etc.
- Handling edge-cases, like when a purchase is deferred because it requires parental permissions, or when entitlements for a user have changed and access to the specified IAPs has been revoked
- Should you handle App Store receipt validation on-device or server-side?
- Should you write your own receipt validation code or use a service like [RevenueCat](https://www.revenuecat.com/)?
- Working with **OpenSSL** and the arcane **PKCS #7** and **ASN.1** data structures found in receipts
- Writing code to validate the receipt and read in-app purchase data
- Creating and managing sandbox accounts used for testing

When I first implemented in-app purchases in one of my iOS apps in 2016 the two main pain-points were:

- [Receipt validation]()
- [Sandbox accounts](https://www.notion.so/In-App-Purchases-in-iOS-14-cfef71ffcf56486ea503e4807b0a87ff#24bd23af656749669d90122153a98000)

# Receipt validation options

The App Store issues an encrypted receipt when in-app purchases are made or restored (when an app’s first installed, no receipt is present). This receipt contains a complete list of all in-app purchases made in the app. There are four receipt validation approaches available:

1. Server-side receipt validation
2. On-device receipt validation
3. Third-party receipt validation service
4. No receipt validation

## **Server-side validation**

This is probably the easiest option, but you need an app server to send requests to the App Store server. Apple specifically says you **should not** create direct connections to the App Store server from your app because you can’t guard against man-in-the-middle attacks. 

Despite this clear warning, the web has many examples (including commercial offerings) of using direct app-to-App Store connections. The advantage of using server-side validation is that you can retrieve easily decoded JSON payloads that include all the in-app purchase data you need. We don’t cover server-side validation in this example.

## **On-device validation**

On-device validation is somewhat tricky and requires use of the C-based [OpenSSL](https://www.openssl.org/) library to decrypt and read the receipt data. Note that including the required two OpenSSL libraries adds nearly 50MB to your app.

I first started supporting in-app purchases in 2016. I fully expected **StoreKit** or some other Apple framework to provide ready-to-use abstractions allowing for easy access to the low-level cryptographic data structures in the receipt. However, as I looked deeper into the “where’s the receipt processing framework?” conundrum the more the answer became clear: having a ready-to-use framework creates a security risk because “hackers” wishing to access your in-app purchases for-free know in advance where and how to concentrate their attacks. Apple’s answer was (*and still is*): create your own custom receipt validation solution because a unique solution will be harder to hack.

Clearly a custom solution (if done correctly) will be more secure. But, as all developers know that have attempted it, writing security-critical cryptographic-related code is **hard** and if you get it wrong disasters will happen! In my opinion, surely it would be better for Apple to provide something that enables correct and *reasonably secure* receipt validation for the general app developer?

However, at present (August 2020) you have no choice if you want to validate and read receipt data on-device: you must develop your own OpenSSL-based solution. If you don’t feel confident doing this feel free to adapt (or use as-is) the code presented herein**.**

## Third-party receipt validation service

A number of third parties provide receipt validation services, normally as part of a larger in-app purchase, subscription and analytics service. I've not used any of them in my apps so can't comment on their suitability. However, [RevenueCat](https://www.revenuecat.com/) seems like a good option judging by their documentation and sample code. 

## **No receipt validation**

It’s perfectly possible to do no receipt validation at all, if you think that’s appropriate for your app’s business model. All you need to do is handle transactions from the App Store using the following method:

```swift
paymentQueue(_:updatedTransactions:)
```

When you get a **`.purchased`** or **`.restored`** transaction simply add the product identifier for the product to a list of purchased products that your app maintains. The list should be persisted in a database, or even **`UserDefaults`**. Clearly, this is a far less secure approach than doing receipt validation. However, you may decide that a particular app doesn’t warrant the greater protection and associated complexity provided by receipt validation. See the [HelloIAPWorld]() example below for a discussion of this approach.

# Sandbox accounts

Prior to Xcode 12, in order to test in-app purchases you needed to create multiple sandbox test accounts in App Store Connect. Each sandbox account has to have a unique email address and be validated as an AppleID. In addition, tests must be on a real device, not the simulator.

On the test device you need to sign out of your normal AppleID and sign-in using the sandbox account. This really means you need a spare device to do testing on. To make things more painful, each time you make a purchase using a sandbox account that account becomes “used up” and can’t be used to re-purchase the same product. There’s no way to clear purchases, so you need to use a fresh sandbox account for each set of product purchases.

# Basic Steps

There are a lot of pieces that fit together to enable you to support in-app purchases in your app:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled.png)

The basic steps you need to take to support in-app purchases (IAP hereafter) in your app are as follows:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%201.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%201.png)

## **Create an IAP helper class**

Create a class or struct that will contain all your IAP-related code. For the sake of example we’ll refer to this as the **`IAPHelper`** code.

## **Define your ProductIds**

Define a set of Strings that hold **ProductIds** for the products you want to sell. ProductIds are generally in reverse domain form (“com.your-company.your-product”). 

For example, **`com.rarcher.flowers-large`**. These ids will match the product ids you define in App Store Connect.

## **Add your `IAPHelper` to the Payment Queue**

To receive notifications from the App Store (when payments are successful, fail, are restored, etc.) add your IAPHelper to the StoreKit payment queue. This should be done as soon as possible in the app’s lifecycle. 

For example in **`application(_:didFinishLaunchingWithOptions:)`**, so that notifications from the App Store are not missed:

```swift
SKPaymentQueue.default().add(iapHelper)
```

## **Request localized product information from the App Store**

The **`SKProductsRequestDelegate`** method **`productsRequest(_:didReceive:)`** will be called asynchronously with a list of **`SKProduct`** objects. Note that you can’t simply use predefined product data because you need to display prices, etc. that are *localized* for each user.

## **Present the localized product list to the user and handle purchases**

When the user taps on “buy product” you should wrap the selected **`SKProduct`** in an **`SKPayment`** object, then add it to the **`SKPaymentQueue`**. The App Store will then send notifications to the **`SKPaymentTransactionObserver`** method **`paymentQueue(_:updatedTransactions)`** as the purchase progresses. Note that the App Store presents the user with all the required purchase prompts and confirmations.

## **Process the App Store Receipt**

The App Store will create a new **receipt** when a purchase has been made or restored. The receipt is available when the **`paymentQueue(_:updatedTransactions)`** method is called. This receipt, which is cryptographically signed and encrypted, contains a complete record of all the IAPs made by the user of your app.

The code discussed in the [HelloIAPWorld]() example below provides a practical example of the above points (receipt validation is covered later).

## Xcode 12 Improvements

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/wwdc-2020-100835422-large.jpg](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/wwdc-2020-100835422-large.jpg)

Immediately before Apple’s WWDC 2020 keynote event I tweeted that I was hoping for something “magical and unexpected”. I followed this up with “How about an update to StoreKit that makes it really easy to do on-device validation of App Store receipts”. 

Well, I didn’t get my wish with regard to receipt validation, but I certainly got something magical and unexpected related to StoreKit and in-app purchases!

Starting with Xcode 12, there’s a new local **`StoreKit`** test environment that allows you to do early testing of IAPs in the simulator and without having to set anything up in App Store Connect. You can define your products locally in a **`StoreKit` Configuration file**. Furthermore, you can view and delete transactions, issue refunds, and a whole lot more. There’s also a new **`StoreKitTest`** framework that enables you to do automated testing of IAPs. The [HelloIAPWorld]() project below includes details on how to create and use a StoreKit configuration file.

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap2.jpg](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap2.jpg)

These new features are a huge leap forward in terms of making testing substantially easier, quicker to setup, more flexible and less frustrating!

# HelloIAPWorld Example

The following example shows how to create a **very minimal IAP example** (the IAP equivalent of “Hello World”) that makes use of the new StoreKit testing features in Xcode 12.

Note that StoreKit testing requires **Xcode 12** and **iOS 14**.

Although this is a bare-bones example, the project does demonstrate most of the essential requirements for handling in-app purchases in an iOS app.

You can find the code for **HelloIAPWorld** [on GitHub](https://github.com/russell-archer/HelloIAPWorld).

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%202.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%202.png)

Note that this example project is missing some features a real-world app would be expected to support:

- The App Store receipt is not validated, nor is IAP data read from the receipt
- Purchases are not persisted. So, if the app’s closed and restarted no purchases are remembered
- There’s no way to restore previous purchases
- Deferred purchases aren’t supported
- Edge cases are not supported (refunds, entitlements being revoked, store front changes, purchasing IAPs directly from the app store, etc.)

For this example we’ll assume you’re going to create a demo app from scratch using iOS 14 and Xcode 12. Here are the steps we'll go through:

- [Add the StoreKit Framework](https://www.notion.so/In-App-Purchases-in-iOS-14-cfef71ffcf56486ea503e4807b0a87ff#5c728648fd224ea098b657c1087a7f03)
- [Create the StoreKit configuration file](https://www.notion.so/In-App-Purchases-in-iOS-14-cfef71ffcf56486ea503e4807b0a87ff#d1c4808df18742df8fa580ca60b9295f)
- [Add the in-app purchase capability](https://www.notion.so/In-App-Purchases-in-iOS-14-cfef71ffcf56486ea503e4807b0a87ff#62208eaca1454148a1e0e79bd9f0b0e2)
- [Enable StoreKit Testing via the Project Scheme](https://www.notion.so/In-App-Purchases-in-iOS-14-cfef71ffcf56486ea503e4807b0a87ff#8ee632b97e7d4f1c92443c14281bd954)
- [Add the StoreKit public certificate](https://www.notion.so/In-App-Purchases-in-iOS-14-cfef71ffcf56486ea503e4807b0a87ff#388149cfafd54664b650d7280d61ec2f)
- [Minimal IAPHelper Code](https://www.notion.so/In-App-Purchases-in-iOS-14-cfef71ffcf56486ea503e4807b0a87ff#d1310a17487f4b3988b6caebd3249be6)

## Create the App

Create a new iOS app in Xcode named "HelloIAPWorld":

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%203.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%203.png)

As we'll be creating the UI programmatically we need to remove the Storyboard.

Remove the name (“Main”) of the storyboard in **Targets > General > Deployment Info**:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%204.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%204.png)

Delete **Main.storyboard** and move it to the trash:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%205.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%205.png)

Open **Info.plist**, search for **Main** and then remove the **Storyboard Name** entry entirely:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%206.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%206.png)

Open **SceneDelegate.swift** and modify the **`scene(_:willConnectTo:options:)`** method as follows:

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.

        guard let windowScene = (scene as? UIWindowScene) else { return }  // Get the window scene
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)  // Create a window
       
        if let w = window {
            w.windowScene = windowScene  // Assign the window scene to the window's window scene
            w.rootViewController = ViewController()  // Set the root view controller (to the default view controller)
            w.makeKeyAndVisible()  // Make the window visible
        }
    }
        :
}
```

## Add the StoreKit Framework

The first thing you need to do after creating your new app is to add the **StoreKit** framework. Select your app **Target** and the **General** tab, then add the **`StoreKit`** framework:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%207.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%207.png)

## Create the StoreKit configuration file

Now create a StoreKit configuration file. Select **File > New > File** and choose the **StoreKit Configuration File** template:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap4.jpg](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap4.jpg)

Choose a location in your project to save the file.

Open the StoreKit configuration file and click **+** to add an in-app purchase. For this example select the **Add Non-Consumable in-App Purchase** option:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap5.jpg](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap5.jpg)

You can now define your products in the StoreKit configuration file:

In this example I set the following fields:

- **Reference Name** 
A descriptive name for the product
- **Product ID** 
This the unique code used to identify an IAP product. This same ID will be used in App Store Connect when setting up in-app purchases for production. Note that Product ID is a string that, by convention, uses the format “com.developer.product”, although it can be anything you like
- **Price** 
A hard-coded price for the product. In production your app will request localized price (and other) information from the App Store

By default, the first localization is for the US store. However, you can add as many localizations as required:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%208.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%208.png)

Note that none of the data defined in the .storekit file is ever uploaded to App Store Connect. It’s only used when testing in-app purchases locally in Xcode.

## Add the in-app purchase capability

It’s easy to forget to do this! And you can successfully test in-app purchases *without* adding the IAP capability. However, you will receive the following error when attempting to archive a project in preparation for uploading it to the App Store:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap10.jpg](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap10.jpg)

Add the in-app purchase capability by selecting the app target and **Signing & Capabilities**, then click **+** **Capability** to add a capability:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%209.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%209.png)

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap11.jpg](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap11.jpg)

## Enable StoreKit Testing via the Project Scheme

You now need to enable StoreKit testing in Xcode (it’s disabled by default).

Select **Product > Scheme > Edit Scheme**. Now select **Run** and the **Options** tab. You can now select your configuration file from the **StoreKit Configuration** list:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap7.jpg](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/iap7.jpg)

Should you wish to disable StoreKit testing then repeat the above steps and remove the StoreKit configuration file from the **StoreKit Configuration** list.

## Add the StoreKit public certificate

You need to add the StoreKit public test certificate to your project. This isn’t strictly necessary if you’re not going to be doing any receipt validation. However, we’ll include the details here for completeness.

StoreKit testing in Xcode generates *locally signed* receipts that your app must validate locally against the StoreKit test certificate. In production your app will include the **Apple Root Certificate** and use that when validating the App Store receipt.

In Xcode project navigator, select the StoreKit configuration file. Now select **Editor > Save Public Certificate**.

Choose a location in your project to save the file.

You now need to ensure your app uses the correct certificate in all environments. The easiest way to do this is to create a simple helper which returns the correct certificate name for the runtime environment:

```swift
/// Constants used in support of IAP operations.
public struct IAPConstants {

    /// The appropriate certificate to use for DEBUG and RELEASE builds.
    /// - Returns: Returns the appropriate certificate to use for 
        /// DEBUG and RELEASE builds.
    public static func Certificate() -> String {
        #if DEBUG
                // This is issued by StoreKit for local testing
        return "StoreKitTestCertificate"  
        #else
                // For release with the real App Store
        return "AppleIncRootCertificate"  
        #endif
    }
}
```

## Minimal IAPHelper Code

In this example we’ll put all IAP related code into a single **`IAPHelper`** class. We set this up as a singleton, ensuring there’s only ever a single instance of the class:

```swift
public class IAPHelper: NSObject  {
    
    /// Singleton access. Use IAPHelper.shared to access all IAPHelper 
        /// properties and methods.
    public static let shared: IAPHelper = IAPHelper()
   
    /// Private initializer prevents more than a single instance of this class 
        /// being created. See the public static 'shared' property. This helper 
        /// must be initialized as soon as possible in the app's lifecycle. 
        /// See application(_:didFinishLaunchingWithOptions:).
    private override init() {
        super.init()
        
        // Add ourselves to the payment queue so we get App Store 
                // notifications        
        SKPaymentQueue.default().add(self)  
    }
    :
    :
}
```

In **`AppDelegate`** we initialize **`IAPHelper`**:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    public var iapHelper: IAPHelper?
    
    func application(_
                application: UIApplication, 
                didFinishLaunchingWithOptions launchOptions: 
                [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Make sure the IAPHelper is initialized early in the app's lifecycle 
        // to ensure we don't miss any App Store notifications
        iapHelper = IAPHelper.shared
        return true
    }
```

Then in the initial **`ViewController`** we request a list of localized product information:

```swift
class ViewController: UIViewController {

    private let iap = IAPHelper.shared
    
    override func viewDidLoad() {
        :
        configureProducts()
    }
    
        private func configureProducts() {
        // Ask the App Store for a list of localized products
        iap.requestProductsFromAppStore { notification in
            
            if notification == .requestProductsDidFinish { 
                                self.tableView.reloadData() 
                        }
        }
    }
}
```

When the user wants to purchase a product we call **`IAPHelper.buyProduct(_:completion:)`** and handle the result in a closure:

```swift
extension ViewController: ProductCellDelegate {
    
    internal func requestBuyProduct(productId: ProductId) {
        guard let product = iap.getStoreProductFrom(id: productId) else { 
                        return 
                }
        
        // Start the process to purchase the product
        iap.buyProduct(product) { notification in
            switch notification {
            
                        case .purchaseAbortPurchaseInProgress: 
                                print("Purchase aborted (another purchase being processed)")

            case .purchaseCompleted(productId: let pid): 
                                print("Purchase completed for product \(pid)")

            case .purchaseCancelled(productId: let pid): 
                                print("Purchase cancelled for product \(pid)")

            case .purchaseFailed(productId: let pid): 
                                print("Purchase failed for product \(pid)")

            default: break
            }
            
                        // Reload data for a success, cancel or failure
            self.tableView.reloadData()  
        }
    }
}
```

## Running the app

If you run the app you'll be able to tap on "buy" button and step through the purchase procedure:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/demo.gif](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/demo.gif)

While the app's running, click on the **Manage StoreKit Transactions** button in Xcode's console toolbar:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%2010.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%2010.png)

You'll see transactions for purchases you've made:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%2011.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%2011.png)

From the **Manage StoreKit Transaction** view you can select a transaction and then:

- **Approve** a transaction (if it's pending parental approval)
- **Decline** a transaction (if it's pending parental approval)
- Issue a **refund**
- **Resolve** transaction issues
- **Delete** a transaction

The ability to **delete** transactions is a huge boast to productivity! Previously, when working with App Store Connect sandbox accounts you could test purchase a product once. If you wanted to test purchasing the same product again you'd have to create a new sandbox account, complete with Apple ID, email, etc.

---

# How to Validate Receipts Locally

## What actually is a Receipt?

The receipt issued to an app by the App Store contains a complete record of a user's in-app purchase history for that app.  It is a **signed** and **encrypted** file which is stored *on the device* in the app's **main bundle**. The location of the receipt is given by the URL **`Bundle.main.appStoreReceiptURL`**. 

When an app is first installed the receipt will be **missing**. A new receipt will be issued automatically by the App Store when:

- An in-app **purchase** succeeds
- The app is **updated** (a receipt is issued for the new version)
- Previous in-app purchases are **restored**

Receipts have the following structure:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%2012.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%2012.png)

The containing structure for the receipt is a **PKCS #7** **`struct`**. PKCS #7  is a common cryptographic data format that OpenSSL handles for us. 

The **Payload** part of the receipt contains zero or more **Attributes** in ASN.1 format (another common crypto format that OpenSSL works with). Each attribute is a record of an in-app purchase. 

We use the **Certificate Chain** and **Signature** to validate that the receipt was genuinely issued by  Apple.

## When should you validate the Receipt?

You should validate the app's receipt:

- On **start-up**
Your app should keep a "fallback" list of successfully purchased product ids that's stored either in **UserDefaults** (easy to work with, less secure) or the **Keychain** (less easy to work with, more secure). This list will be useful if the receipt is missing and there's no network connection allowing a fresh one to be requested from the App Store. At start up validate the receipt and then compare the fallback list against the IAP records in the receipt. If they differ, reset the fallback list to match the receipt
- When a **purchase** succeeds 
A new receipt will be issued automatically by the App Store when a purchase is successfully completed. The new receipt will be available in the app bundle when  **`paymentQueue(_:updatedTransactions:)`** is called by StoreKit
- When purchases are **restored**
This appears to the app like a succession of purchases. You should validate the receipt when the final transaction is completed (see **`paymentQueue(_:updatedTransactions:)`**)
- Edge cases
This includes when the storefront changes (e.g. the user changes from the US to UK App Store) and when rights to an IAP are revoked by the App Store (e.g. the App Store has issued a refund), etc.

## Overview of the steps to validate a receipt

Although actual implementation details will vary, the same basic procedure is adopted by all apps. For example, the steps taken by **`IAPHelper`** (see [IAPDemo Example]() below) when validating a receipt are as follows:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%2013.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%2013.png)

We'll go through an example exactly how the validation process is accomplished in the [IAPDemo Example]()  below.

## Key StoreKit Features

The following are the most important  **`StoreKit`** protocols, classes and methods you'll encounter:

**Name**

---

**`SKPaymentQueue`**

---

**`SKProduct`**

---

**`SKPayment`**

---

**`SKProductsRequest(
  productIdentifiers:)`**

---

**`SKPaymentQueue.default().add()`**

---

**`restoreCompletedTransactions()`**

---

**`productsRequest(
  _:didReceive:)`**

---

**`requestDidFinish(_:)`**

---

**`SKReceiptRefreshRequest()`**

---

**`paymentQueue(
  _:updatedTransactions:)`**

---

**Notes**

---

Allows us to observe **`StoreKit`** transactions

---

Defines a product (id, title, etc.)

---

Wrap an **`SKProduct`** in an **`SKPayment`** object when purchasing

---

Request localized product info from app store. Note that doing a product request does not result in a fresh receipt

---

Purchase a product using: 
**`SKPaymentQueue.default().
  add(SKPayment(product: myProduct))`**

---

Restore previously made purchases with: 
**`SKPaymentQueue.default().
  restoreCompletedTransactions()`**

---

Called when localized product information is returned by the App Store. When this method returns **`StoreKit`** will immediately call **`requestDidFinish(_:)`.**
Protocol: **`SKProductsRequestDelegate`**

---

Called for both **`SKProductsRequest(productIdentifiers:)`** (request product info) and **`SKReceiptRefreshRequest()`** (request receipt fresh). Protocol: `**SKRequestDelegate**`

---

Ask the App Store to issue new receipt. **`requestDidFinish(_:)`** called when receipt available

---

Receive notifications when payments are successful, fail, are restored, etc. Protocol: `**SKPaymentTransactionObserver**`

---

# IAPDemo Example

The IAPDemo example provides a more complete, real-world treatment of handling in-app purchases. 

## IAPHelper

todo

## OpenSSL

IAPHelper uses [OpenSSL](https://www.openssl.org) to validate the App Store receipt and read its contents. Building OpenSSL for iOS is not totally straightforward. To make getting started easier, IAPDemo (todo: link) contains pre-built OpenSSL binaries that were built using version 1.1.1 of OpenSSL. 

The OpenSSL binaries **`libcrypto.a`** and **`libssl.a`** need to work in the following environments:

**Device**

---

Simulator

Device

Any iOS Device (Archive)

**Build on Intel Mac (x86_64)**

---

Y (x86_64)

Y (arm64)

Y (arm64)

**Build on M1 Mac (arm64)**

---

N (arm64)

Y (arm64)

Y (arm64)

As you can see from the above table, everything works as anticipated, except in the case of building with Xcode on an M1 Mac for running on the simulator. At the time of writing (a week after the first M1 Macs became available in November 2020) isn't totally clear. If we intend only to support recent devices on iOS 13 and higher, in theory our OpenSSL binaries only need to support two architectures in a "fat" or Universal Binary: x86 64-bit and ARM 64-bit.

The included builds of the OpenSSL binaries contain the following architectures as shown by using the **`lipo`** utility:

```
% lipo -info libcrypto.a 
Architectures in the fat file: libcrypto.a are: armv7 armv7s **x86_64 arm64** 

% lipo -info libssl.a 
Architectures in the fat file: libssl.a are: armv7 armv7s **x86_64 arm64** 
```

Our IAPDemo app only supports devices running **`iOS 13`** and higher. So IAPDemo supports the iPhone 6s upwards. 

The `arm64` 64-bit ARM CPU architecture has been used since the iPhone 5S and iPad Air, Air 2 and Pro, with the A7 and later chips. The `armv7s` 32-bit architecture is used in Apple's A6 and A6X chips on iPhone 5, iPhone 5C and iPad 4. The `armv7`  32-bit architecture is an older variant of the 32-bit ARM CPU.

If we build on an M1 Mac for the simulator we get the following error: 

**`libcrypto.a(tasn_typ.o), building for iOS Simulator, but linking in object file built for iOS, for architecture arm64`** 

Currently, I can't find a solution to this issue. I wonder if it's because the OpenSSL binaries were built for iOS arm64, which is in some way different for the arm64 architecture which the simulator running on the M1 Mac expects?  Note that if you build on an M1 Mac for a real device then everything builds, links and running as expected. The issue is purely with the simulator.

It is possible to build for the simulator on an M1 Mac if you exclude the arm64 architecture for simulator builds:

![In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%2014.png](In-App%20Purchases%20with%20Xcode%2012%20and%20iOS%2014%204178e05ca4154424ac1d6e44c5e38e39/Untitled%2014.png)

However, when you run the app on the simulator there are issues. The most notably one is that the **`Bundle.main.appStoreReceiptURL`** property, which points to the location of the App Store receipt, is always nil.

Until a solution is found you will need to build and deploy IAPDemo to a real device if you use an M1-based Mac.

## Loading and Reading the Receipt

todo

## Validating the Receipt

todo

## Reading In-App Purchase Records

todo

# Future Enhancements

- IAPHelper support for subscriptions
- A example of server-based (off device) receipt validation
- Using a service like RevenueCate for receipt validation



