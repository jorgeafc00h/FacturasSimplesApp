//
//  ExternalPaymentView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 7/22/25.
//

import SwiftUI

struct ExternalPaymentView: View {
    let product: CustomPaymentProduct
    let onSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var invoiceService = InvoiceServiceClient()
    @State private var isGeneratingLink = false
    @State private var generatedPaymentURL: String?
    @State private var showingPaymentWebView = false
    @State private var isCheckingStatus = false
    @State private var paymentCheckTimer: Timer?
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    // Check if there's a stored order ID on view appear
    @State private var hasStoredOrderId = false
    
    // Get email prefix from stored user email
    @AppStorage("storedEmail") private var userEmail: String = ""
    
    private var emailPrefix: String {
        if userEmail.contains("@") {
            return String(userEmail.split(separator: "@").first ?? "user")
        }
        return userEmail.isEmpty ? "user" : userEmail
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                headerSection
                actionButtonsSection
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .navigationTitle("Portal de Compras")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        stopPaymentStatusCheck()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaymentWebView) {
            if let paymentURL = generatedPaymentURL,
               let url = URL(string: paymentURL) {
                ExternalPaymentWebView(
                    url: url,
                    onDismiss: {
                        showingPaymentWebView = false
                        startPaymentStatusCheck()
                    }
                )
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                showErrorAlert = false
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .onDisappear {
            stopPaymentStatusCheck()
        }
        .onAppear {
            // Check if there's a stored order ID from a previous session
            hasStoredOrderId = InvoiceServiceClient.getCurrentOrderId() != nil
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Portal de Compras")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Serás redirigido a nuestro portal seguro donde podrás ver todos los productos disponibles y completar tu compra")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if isCheckingStatus {
                VStack(spacing: 16) {
                    Button(action: {
                        if generatedPaymentURL != nil {
                            showingPaymentWebView = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "safari.fill")
                            Text("Abrir Portal de Compras")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    
                    // Manual refresh button
                    Button(action: {
                        Task {
                            await checkPaymentStatus()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Verificar Estado del Pago")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                                .background(Color.blue.opacity(0.05))
                        )
                    }
                    
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Verificando estado del pago...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            } else {
                Button(action: openPaymentPortal) {
                    HStack {
                        if isGeneratingLink {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "cart.fill")
                        }
                        Text(isGeneratingLink ? "Abriendo portal..." : "Ir al Portal de Compras")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isGeneratingLink)
                
                // Show option to check previous payment if there's a stored order ID
                if hasStoredOrderId && !isCheckingStatus {
                    Button(action: {
                        Task {
                            await checkPaymentStatus()
                        }
                    }) {
                        HStack {
                            Image(systemName: "creditcard.and.123")
                            Text("Verificar Pago Anterior")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, lineWidth: 1)
                                .background(Color.orange.opacity(0.05))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func openPaymentPortal() {
        isGeneratingLink = true
        
        // Simulate a brief delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let paymentURL = InvoiceServiceClient.generatePaymentURL(
                emailPrefix: emailPrefix,
                isProduction: true
            )
            
            generatedPaymentURL = paymentURL
            isGeneratingLink = false
            
            print("🔗 ExternalPaymentView: Generated payment URL: \(paymentURL)")
            
            // Automatically open the payment portal
            showingPaymentWebView = true
        }
    }
    
    private func startPaymentStatusCheck() {
        guard generatedPaymentURL != nil else { return }
        
        isCheckingStatus = true
        
        // Check payment status every 10 seconds
        paymentCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task {
                await checkPaymentStatus()
            }
        }
        
        // Also do an immediate check
        Task {
            await checkPaymentStatus()
        }
    }
    
    private func stopPaymentStatusCheck() {
        paymentCheckTimer?.invalidate()
        paymentCheckTimer = nil
        isCheckingStatus = false
    }
    
    @MainActor
    private func checkPaymentStatus() async {
        do {
            // Use the stored order ID from InvoiceServiceClient
            let statusResponse = try await invoiceService.getPaymentStatus(
                orderId: nil, // Will use stored order ID
                isProduction: true
            )
            
            print("💳 ExternalPaymentView: Payment type: \(statusResponse.type ?? "unknown")")
            print("💳 ExternalPaymentView: Payment description: \(statusResponse.description ?? "none")")
            
            if statusResponse.isPaymentCompleted {
                // Payment successful!
                print("✅ ExternalPaymentView: Payment completed successfully!")
                print("💳 ExternalPaymentView: Credits to add: \(statusResponse.creditsToAdd)")
                if let paidAmount = statusResponse.paidAmountString {
                    print("💰 ExternalPaymentView: Paid amount: \(paidAmount)")
                }
                
                stopPaymentStatusCheck()
                
                // Add a small delay to ensure credit processing completes
                // before dismissing the view and calling onSuccess
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onSuccess()
                    dismiss()
                }
            } else if statusResponse.isPaymentFailed {
                // Payment failed
                print("❌ ExternalPaymentView: Payment failed")
                stopPaymentStatusCheck()
                errorMessage = "El pago no pudo ser procesado. Por favor, intenta nuevamente."
                showErrorAlert = true
            } else if statusResponse.isOrderNotFound {
                // Order not found means still in progress (404 response)
                print("⏳ ExternalPaymentView: Order still in progress")
                // Continue checking - this is normal for pending payments
            }
            // Continue checking if status is pending or not found
            
        } catch {
            print("❌ ExternalPaymentView: Error checking payment status: \(error)")
            // Don't show error for status checks, just continue checking
        }
    }
}

// MARK: - External Payment Web View
struct ExternalPaymentWebView: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let webViewController = ExternalPaymentWebViewController(url: url, onDismiss: onDismiss)
        let navController = UINavigationController(rootViewController: webViewController)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No updates needed
    }
}

import WebKit

class ExternalPaymentWebViewController: UIViewController, WKNavigationDelegate {
    private let url: URL
    private let onDismiss: () -> Void
    private var webView: WKWebView!
    
    init(url: URL, onDismiss: @escaping () -> Void) {
        self.url = url
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        setupNavigationBar()
        loadPaymentURL()
    }
    
    private func setupWebView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Portal de Compras"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
    }
    
    private func loadPaymentURL() {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @objc private func doneButtonTapped() {
        onDismiss()
        dismiss(animated: true)
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Update title with page title
        webView.evaluateJavaScript("document.title") { [weak self] result, error in
            if let title = result as? String, !title.isEmpty {
                DispatchQueue.main.async {
                    self?.title = title
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ ExternalPaymentWebView: Failed to load payment page: \(error)")
    }
}

#Preview {
    ExternalPaymentView(
        product: CustomPaymentProduct(
            id: "test",
            name: "Paquete de 100 Facturas", 
            description: "Ideal para empresas medianas",
            invoiceCount: 100,
            price: 25.00,
            formattedPrice: "$25.00",
            isPopular: false,
            productType: .consumable,
            isImplementationFee: false,
            subscriptionPeriod: nil,
            specialOfferText: nil
        ),
        onSuccess: {
            print("Payment success!")
        }
    )
}
