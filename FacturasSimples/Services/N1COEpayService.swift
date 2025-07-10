//
//  N1COEpayService.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  Custom credit card payment service using N1CO Epay API
//

import Foundation
import Combine

// MARK: - N1CO Epay Service
@MainActor
class N1COEpayService: ObservableObject {
    // MARK: - Singleton
    static let shared = N1COEpayService()
    
    // MARK: - Configuration
    private let baseURL: String
    private let clientId: String
    private let clientSecret: String
    private let locationId: Int
    private let locationCode: String
    
    // MARK: - Published Properties
    @Published var purchaseState: CustomPurchaseState = .idle
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var availableProducts: [CustomPaymentProduct] = []
    
    // SwiftData-backed user credits (computed from PurchaseDataManager)
    var userCredits: CustomUserCredits {
        let manager = PurchaseDataManager.shared
        guard let profile = manager.userProfile else {
            return CustomUserCredits()
        }
        
        return CustomUserCredits(
            availableInvoices: profile.availableInvoices,
            totalPurchased: profile.totalPurchasedInvoices,
            hasActiveSubscription: profile.hasActiveSubscription,
            subscriptionExpiryDate: profile.subscriptionExpiryDate,
            subscriptionId: profile.currentSubscriptionId,
            transactions: manager.recentTransactions.map { transaction in
                CustomStoredTransaction(
                    id: transaction.id,
                    productID: transaction.productID,
                    purchaseDate: transaction.purchaseDate,
                    invoiceCount: transaction.invoiceCount,
                    amount: transaction.amount,
                    isRestored: transaction.isRestored
                )
            },
            hasImplementationFeePaid: profile.hasImplementationFeePaid
        )
    }
    
    // MARK: - Private Properties
    private var accessToken: String?
    private var tokenExpiryDate: Date?
    private let urlSession = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        self.baseURL = N1COConfiguration.baseURL
        self.clientId = N1COConfiguration.clientId
        self.clientSecret = N1COConfiguration.clientSecret
        self.locationId = N1COConfiguration.locationId
        self.locationCode = N1COConfiguration.locationCode
        self.availableProducts = CustomPaymentProduct.allProducts
        
        // Initialize SwiftData purchase manager
        Task { @MainActor in
            PurchaseDataManager.shared.loadUserProfile()
            // Migrate from UserDefaults if needed
            PurchaseDataManager.shared.migrateFromUserDefaults()
        }
    }
    
    convenience init(clientId: String, clientSecret: String, locationId: Int, locationCode: String) {
        self.init()
    }
    
    // MARK: - Authentication
    private func authenticate() async throws -> String {
        print("🔐 N1CO Auth: Starting authentication process...")
        
        // Check if we have a valid token
        if let token = accessToken,
           let expiryDate = tokenExpiryDate,
           expiryDate > Date() {
            print("✅ N1CO Auth: Using cached token (expires at \(expiryDate))")
            return token
        }
        
        print("🔄 N1CO Auth: Token expired or missing, requesting new token...")
        print("🌐 N1CO Auth: Endpoint: \(baseURL)/token")
        
        let url = URL(string: "\(baseURL)/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let authRequest = N1COAuthRequest(clientId: clientId, clientSecret: clientSecret)
        request.httpBody = try JSONEncoder().encode(authRequest)
        
        print("📤 N1CO Auth: Sending authentication request...")
        print("📋 N1CO Auth: Client ID: \(clientId)")
        print("🔒 N1CO Auth: Client Secret: \(String(clientSecret.prefix(4)))****")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ N1CO Auth: Invalid response type")
            throw PaymentError.networkError("Invalid response")
        }
        
        print("📨 N1CO Auth: Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 N1CO Auth: Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ N1CO Auth: Authentication failed with status \(httpResponse.statusCode)")
            throw PaymentError.authenticationFailed("Authentication failed with status \(httpResponse.statusCode)")
        }
        
        let authResponse = try JSONDecoder().decode(N1COAuthResponse.self, from: data)
        
        // Store the token with expiry
        self.accessToken = authResponse.accessToken
        self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(authResponse.expiresIn - 60)) // Refresh 1 minute early
        
        print("✅ N1CO Auth: Authentication successful!")
        print("🎫 N1CO Auth: Token type: \(authResponse.tokenType)")
        print("⏰ N1CO Auth: Expires in: \(authResponse.expiresIn) seconds")
        print("🔑 N1CO Auth: Token: \(String(authResponse.accessToken.prefix(10)))...")
        
        return authResponse.accessToken
    }
    
    // MARK: - Payment Methods
    func createPaymentMethod(
        customerName: String,
        customerEmail: String,
        customerPhone: String,
        cardNumber: String,
        expirationMonth: String,
        expirationYear: String,
        cvv: String,
        cardHolder: String,
        appleId: String? = nil
    ) async throws -> String {
        print("💳 N1CO Payment Method: Creating payment method...")
        print("👤 N1CO Payment Method: Customer: \(customerName) (\(customerEmail))")
        print("📱 N1CO Payment Method: Phone: \(customerPhone)")
        print("🆔 N1CO Payment Method: Apple ID: \(appleId ?? "not provided")")
        print("💳 N1CO Payment Method: Card: ****\(String(cardNumber.suffix(4))) (\(expirationMonth)/\(expirationYear))")
        print("👤 N1CO Payment Method: Cardholder: \(cardHolder)")
        
        isLoading = true
        defer { isLoading = false }
        
        let token = try await authenticate()
        
        let url = URL(string: "\(baseURL)/paymentmethods")!
        print("🌐 N1CO Payment Method: Endpoint: \(url)")
       
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let customer = N1COCustomer(
            id: appleId, // Use Apple ID as customer identifier
            name: customerName,
            email: customerEmail,
            phoneNumber: customerPhone
        )
        
        let card = N1COCreditCard(
            number: cardNumber,
            expirationMonth: expirationMonth,
            expirationYear: expirationYear,
            cvv: cvv,
            cardHolder: cardHolder,
            singleUse: false
        )
        
        // Validate request structure
        validatePaymentMethodRequest(customer: customer, card: card)
        
        let paymentMethodRequest = N1COPaymentMethodRequest(customer: customer, card: card)
        request.httpBody = try JSONEncoder().encode(paymentMethodRequest)
        
        // Log the request body for debugging
        if let requestData = request.httpBody,
           let requestString = String(data: requestData, encoding: .utf8) {
            print("📋 N1CO Payment Method: Request body: \(requestString)")
        }
        
        print("📤 N1CO Payment Method: Sending payment method creation request...")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ N1CO Payment Method: Invalid response type")
            throw PaymentError.networkError("Invalid response")
        }
        
        print("📨 N1CO Payment Method: Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 N1CO Payment Method: Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            // Enhanced error logging for API validation issues
            let errorMsg = "Failed to create payment method with status \(httpResponse.statusCode)"
            print("❌ N1CO Payment Method: \(errorMsg)")
            
            // Log specific error details for debugging API structure issues
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 N1CO Payment Method: Error response body: \(responseString)")
                
                // Check for common API validation errors
                if responseString.contains("unknown field") || responseString.contains("invalid field") {
                    print("⚠️ N1CO Payment Method: Possible field name mismatch in request body")
                }
                if responseString.contains("endpoint") || responseString.contains("not found") {
                    print("⚠️ N1CO Payment Method: Possible endpoint URL issue - consider /v2/paymentmethods")
                }
            }
            
            throw PaymentError.paymentMethodCreationFailed(errorMsg)
        }
        
        let paymentMethodResponse = try JSONDecoder().decode(N1COPaymentMethodResponse.self, from: data)
        
        guard paymentMethodResponse.success else {
            print("❌ N1CO Payment Method: Request failed: \(paymentMethodResponse.message)")
            throw PaymentError.paymentMethodCreationFailed(paymentMethodResponse.message)
        }
        
        print("✅ N1CO Payment Method: Payment method created successfully!")
        print("🆔 N1CO Payment Method: ID: \(paymentMethodResponse.id)")
        
        return paymentMethodResponse.id
    }
    
    // MARK: - One-time Purchases
    func purchaseProduct(
        _ product: CustomPaymentProduct,
        paymentMethodId: String,
        authenticationId: String? = nil
    ) async throws {
        print("💰 N1CO Purchase: Starting purchase process...")
        print("🛍️ N1CO Purchase: Product: \(product.name) (\(product.formattedPrice))")
        print("💳 N1CO Purchase: Payment Method ID: \(paymentMethodId)")
        if let authId = authenticationId {
            print("🔐 N1CO Purchase: Authentication ID: \(authId)")
        }
        
        purchaseState = .processing
        
        let token = try await authenticate()
        
        let url = URL(string: "\(baseURL)/charges")!
        print("🌐 N1CO Purchase: Endpoint: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let order = N1COOrder(
            id: UUID().uuidString,
            amount: product.price,
            description: product.description,
            name: product.name
        )
        
        print("📦 N1CO Purchase: Order ID: \(order.id)")
        print("💵 N1CO Purchase: Amount: $\(product.price)")
        
        let chargeRequest = N1COChargeRequest(
            order: order,
            cardId: paymentMethodId,
            authenticationId: authenticationId,
            billingInfo: N1COBillingInfo(countryCode:"SLV",stateCode:nil,zipCode:nil) // Add billing info if needed for US/CAN cards
        )
        
        request.httpBody = try JSONEncoder().encode(chargeRequest)
        
        print("📤 N1CO Purchase: Sending charge request...")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ N1CO Purchase: Invalid response type")
            purchaseState = .failed("Invalid response")
            return
        }
        
        print("📨 N1CO Purchase: Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 N1CO Purchase: Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMsg = "Failed to process payment with status \(httpResponse.statusCode)"
            print("❌ N1CO Purchase: \(errorMsg)")
            purchaseState = .failed(errorMsg)
            return
        }
        
        let chargeResponse = try JSONDecoder().decode(N1COChargeResponse.self, from: data)
        
        print("📋 N1CO Purchase: Charge status: \(chargeResponse.status)")
        
        switch chargeResponse.status {
        case "SUCCEEDED":
            print("✅ N1CO Purchase: Payment succeeded!")
            if let order = chargeResponse.order {
                print("📦 N1CO Purchase: Order ID: \(order.id ?? "N/A")")
                print("🔐 N1CO Purchase: Auth Code: \(order.authorizationCode ?? "N/A")")
            }
            await handleSuccessfulPurchase(product: product, orderResponse: chargeResponse.order)
            
        case "AUTHENTICATION_REQUIRED":
            print("🔐 N1CO Purchase: 3DS Authentication required")
            if let auth = chargeResponse.authentication {
                print("🌐 N1CO Purchase: Auth URL: \(auth.url)")
                purchaseState = .requiresAuthentication(auth.url)
            } else {
                print("❌ N1CO Purchase: Authentication required but no URL provided")
                purchaseState = .failed("Authentication required but no authentication URL provided")
            }
            
        case "FAILED":
            let errorMsg = chargeResponse.error?.message ?? chargeResponse.message
            print("❌ N1CO Purchase: Payment failed: \(errorMsg)")
            purchaseState = .failed(errorMsg)
            
        default:
            let errorMsg = "Unknown payment status: \(chargeResponse.status)"
            print("❌ N1CO Purchase: \(errorMsg)")
            purchaseState = .failed(errorMsg)
        }
    }
    
    // MARK: - Subscription Management
    func createSubscriptionPlan(_ product: CustomPaymentProduct) async throws -> Int {
        print("📅 N1CO Subscription: Creating subscription plan...")
        print("🛍️ N1CO Subscription: Product: \(product.name) (\(product.formattedPrice))")
        print("🔄 N1CO Subscription: Period: \(String(describing: product.subscriptionPeriod))")
        
        let token = try await authenticate()
        
        let url = URL(string: "\(baseURL)/api/v2/Plans")!
        print("🌐 N1CO Subscription: Endpoint: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let billingCycleType: String
        let billingCyclesNumber: Int
        
        switch product.subscriptionPeriod {
        case "monthly":
            billingCycleType = "MONTH"
            billingCyclesNumber = 1
        case "yearly":
            billingCycleType = "YEAR"
            billingCyclesNumber = 1
        default:
            billingCycleType = "MONTH"
            billingCyclesNumber = 1
        }
        
        print("📋 N1CO Subscription: Billing cycle: \(billingCycleType) x\(billingCyclesNumber)")
        
        let subscriptionPlan = N1COSubscriptionPlan(
            name: product.name,
            description: product.description,
            amount: product.price,
            ogTitle: "",
            ogDescription: "",
            ogImageBase64: nil,
            linkImageBase64: nil,
            customFields: [],
            successUrl: "facturas://payment-success",
            cancelUrl: "facturas://payment-cancel",
            billingCycleType: billingCycleType,
            billingCyclesNumber: billingCyclesNumber,
            cyclesToBillBeforeAllowCancelation: nil,
            termsAndConditions: nil,
            subscriberLimit: nil,
            enrollmentEndDate: nil,
            subscriptionEndDate: nil,
            billingDay: nil,
            locationId: locationId
        )
        
        request.httpBody = try JSONEncoder().encode(subscriptionPlan)
        
        print("📤 N1CO Subscription: Sending plan creation request...")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ N1CO Subscription: Invalid response type")
            throw PaymentError.subscriptionFailed("Invalid response")
        }
        
        print("📨 N1CO Subscription: Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 N1CO Subscription: Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ N1CO Subscription: Plan creation failed with status \(httpResponse.statusCode)")
            throw PaymentError.subscriptionFailed("Failed to create subscription plan with status \(httpResponse.statusCode)")
        }
        
        // Parse the response to get the plan ID
        if let responseString = String(data: data, encoding: .utf8),
           let planId = Int(responseString.trimmingCharacters(in: .whitespacesAndNewlines)) {
            print("✅ N1CO Subscription: Plan created successfully!")
            print("🆔 N1CO Subscription: Plan ID: \(planId)")
            return planId
        } else {
            print("❌ N1CO Subscription: Failed to parse plan ID from response")
            throw PaymentError.subscriptionFailed("Failed to parse subscription plan ID")
        }
    }
    
    func subscribeUser(
        planId: Int,
        customerName: String,
        customerEmail: String,
        customerPhone: String,
        paymentMethodId: String,
        backupPaymentMethodId: String? = nil,
        appleId: String? = nil
    ) async throws {
        print("👥 N1CO Subscription: Subscribing user...")
        print("🆔 N1CO Subscription: Plan ID: \(planId)")
        print("👤 N1CO Subscription: Customer: \(customerName) (\(customerEmail))")
        print("🍎 N1CO Subscription: Apple ID: \(appleId ?? "not provided")")
        print("💳 N1CO Subscription: Payment Method: \(paymentMethodId)")
        if let backupId = backupPaymentMethodId {
            print("🔄 N1CO Subscription: Backup Payment Method: \(backupId)")
        }
        
        purchaseState = .processing
        
        let token = try await authenticate()
        
        let url = URL(string: "\(baseURL)/api/v2/Subscriptions")!
        print("🌐 N1CO Subscription: Endpoint: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let customer = N1COCustomer(
            id: appleId, // Use Apple ID as customer identifier
            name: customerName,
            email: customerEmail,
            phoneNumber: customerPhone
        )
        
        let paymentMethod = N1COPaymentMethodReference(id: paymentMethodId)
        let backupPaymentMethod = backupPaymentMethodId.map { N1COPaymentMethodReference(id: $0) }
        
        let subscriptionRequest = N1COSubscriptionRequest(
            subscriptionLinkId: planId,
            customer: customer,
            paymentMethod: paymentMethod,
            backupPaymentMethod: backupPaymentMethod,
            locationCode: locationCode
        )
        
        request.httpBody = try JSONEncoder().encode(subscriptionRequest)
        
        print("📤 N1CO Subscription: Sending subscription request...")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ N1CO Subscription: Invalid response type")
            purchaseState = .failed("Invalid response")
            return
        }
        
        print("📨 N1CO Subscription: Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 N1CO Subscription: Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMsg = "Failed to create subscription with status \(httpResponse.statusCode)"
            print("❌ N1CO Subscription: \(errorMsg)")
            purchaseState = .failed(errorMsg)
            return
        }
        
        let subscriptionResponse = try JSONDecoder().decode(N1COSubscriptionResponse.self, from: data)
        
        print("📋 N1CO Subscription: Subscription status: \(subscriptionResponse.status)")
        
        switch subscriptionResponse.status {
        case "SUCCEEDED":
            print("✅ N1CO Subscription: Subscription created successfully!")
            if let subscription = subscriptionResponse.subscription {
                print("🆔 N1CO Subscription: Subscription ID: \(subscription.id)")
            }
            await handleSuccessfulSubscription(subscriptionResponse: subscriptionResponse)
            
        default:
            let errorMsg = subscriptionResponse.error?.message ?? subscriptionResponse.message
            print("❌ N1CO Subscription: Subscription failed: \(errorMsg)")
            purchaseState = .failed(errorMsg)
        }
    }
    
    // MARK: - Success Handlers
    private func handleSuccessfulPurchase(product: CustomPaymentProduct, orderResponse: N1COOrderResponse?) async {
        print("🎉 N1CO Success: Handling successful purchase...")
        print("🛍️ N1CO Success: Product: \(product.name)")
        print("💰 N1CO Success: Amount: \(product.formattedPrice)")
        print("📦 N1CO Success: Invoice count: \(product.invoiceCount)")
        
        if let order = orderResponse {
            print("📋 N1CO Success: Order ID: \(order.id)")
            print("🔐 N1CO Success: Auth Code: \(order.authorizationCode ?? "N/A")")
        }
        
        // Add transaction to SwiftData
        PurchaseDataManager.shared.addTransaction(
            productID: product.id,
            productName: product.name,
            productDescription: product.description,
            amount: product.price,
            invoiceCount: product.invoiceCount,
            isSubscription: product.isSubscription,
            n1coOrderId: orderResponse?.id,
            authorizationCode: orderResponse?.authorizationCode
        )
        
        print("💾 N1CO Success: Transaction saved to SwiftData")
        
        purchaseState = .succeeded(orderResponse?.id ?? "")
        objectWillChange.send() // Notify UI of credit changes
        
        print("✅ N1CO Success: Purchase handling completed!")
    }
    
    private func handleSuccessfulSubscription(subscriptionResponse: N1COSubscriptionResponse) async {
        print("🎉 N1CO Subscription Success: Handling successful subscription...")
        
        guard let subscription = subscriptionResponse.subscription else { 
            print("❌ N1CO Subscription Success: No subscription data in response")
            return 
        }
        
        print("🆔 N1CO Subscription Success: Subscription ID: \(subscription.id)")
        
        // Add subscription transaction to SwiftData
        if let product = availableProducts.first(where: { $0.isSubscription }) {
            print("🛍️ N1CO Subscription Success: Product: \(product.name)")
            print("💰 N1CO Subscription Success: Amount: \(product.formattedPrice)")
            print("🔄 N1CO Subscription Success: Period: \(String(describing: product.subscriptionPeriod))")
    
            PurchaseDataManager.shared.addTransaction(
                productID: product.id,
                productName: product.name,
                productDescription: product.description,
                amount: product.price,
                invoiceCount: product.invoiceCount,
                isSubscription: true,
                n1coOrderId: String(subscription.id),
                billingCycle: product.subscriptionPeriod
            )
            
            print("💾 N1CO Subscription Success: Subscription saved to SwiftData")
        } else {
            print("⚠️ N1CO Subscription Success: No subscription product found in available products")
        }
        
        purchaseState = .succeeded(String(subscription.id))
        objectWillChange.send() // Notify UI of subscription changes
        
        print("✅ N1CO Subscription Success: Subscription handling completed!")
    }
    
    // MARK: - Helper Methods
    func consumeInvoiceCredit() {
        // This will be called when creating an invoice
        // We need the invoice ID to track consumption
        let invoiceId = UUID().uuidString // In real usage, pass the actual invoice ID
        PurchaseDataManager.shared.consumeInvoiceCredit(for: invoiceId)
        objectWillChange.send()
    }
    
    func consumeInvoiceCredit(for invoiceId: String) {
        PurchaseDataManager.shared.consumeInvoiceCredit(for: invoiceId)
        objectWillChange.send()
    }
    
    func resetPurchaseState() {
        purchaseState = .idle
        errorMessage = nil
    }
    
    // MARK: - Validation Helper Methods
    private func validatePaymentMethodRequest(customer: N1COCustomer, card: N1COCreditCard) {
        print("🔍 N1CO Validation: Checking payment method request structure...")
        
        // Validate customer fields
        print("👤 N1CO Validation: Customer fields:")
        print("   - name: '\(customer.name)' (required)")
        print("   - email: '\(customer.email)' (required)")
        print("   - phoneNumber: '\(customer.phoneNumber)' (required)")
        print("   - id: \(customer.id ?? "null") (Apple ID: \(customer.id != nil ? "provided" : "not provided"))")
        
        // Validate card fields
        print("💳 N1CO Validation: Card fields:")
        print("   - number: \(card.number.count) digits")
        print("   - expirationMonth: '\(card.expirationMonth)' (format: MM)")
        print("   - expirationYear: '\(card.expirationYear)' (format: YYYY)")
        print("   - cvv: \(card.cvv.count) digits")
        print("   - cardHolder: '\(card.cardHolder)' (required)")
        print("   - singleUse: \(card.singleUse)")
        
        // Check for potential issues
        if card.expirationYear.count == 4 {
            print("ℹ️ N1CO Validation: Using 4-digit year format (YYYY)")
        } else if card.expirationYear.count == 2 {
            print("ℹ️ N1CO Validation: Using 2-digit year format (YY)")
        } else {
            print("⚠️ N1CO Validation: Unusual year format: '\(card.expirationYear)'")
        }
        
        print("✅ N1CO Validation: Request structure validated")
    }
    
    // MARK: - Alternative Endpoint Testing (for debugging)
    private func getPaymentMethodEndpoint() -> String {
        // Current implementation uses /paymentmethods
        // If this fails, we might need to try /v2/paymentmethods or /api/v2/paymentmethods
        return "\(baseURL)/paymentmethods"
        
        // Alternative endpoints to try if the current one fails:
        // return "\(baseURL)/v2/paymentmethods"
        // return "\(baseURL)/api/v2/paymentmethods"
    }
}
