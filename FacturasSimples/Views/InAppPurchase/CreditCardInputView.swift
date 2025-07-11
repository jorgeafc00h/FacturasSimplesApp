//
//  CreditCardInputView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 1/14/25.
//  Credit card input form for N1CO Epay payments
//

import SwiftUI
import WebKit
import Combine

struct CreditCardInputView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreditCardInputViewModel()
    @AppStorage("userID") private var userID: String = ""
    
    let product: CustomPaymentProduct
    let onPaymentSuccess: () -> Void
    
    // MARK: - State
    @State private var isProcessing = false
    @State private var showingAuthenticationSheet = false
    @State private var authenticationURL: String = ""
    
    @State private var paymentMethodId: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Product Summary
                    productSummarySection
                    
                    // Credit Card Form
                    creditCardFormSection
                    
                    // Customer Information
                    customerInfoSection
                    
                    // Payment Button
                    paymentButtonSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Pago con Tarjeta")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .disabled(isProcessing)
        .sheet(isPresented: $showingAuthenticationSheet) {
            ThreeDSAuthenticationView(url: authenticationURL) { success, capturedAuthId in
                showingAuthenticationSheet = false
                if success, let paymentId = paymentMethodId {
                    // Complete the payment with the authenticationId
                    Task {
                        await complete3DSPayment( paymentMethodId: paymentId)
                    }
                } else {
                    // Authentication failed or cancelled
                    isProcessing = false
                    if !success {
                        viewModel.errorMessage = "Autenticación 3DS fallida. Por favor, intenta nuevamente."
                    }
                }
            }
        }
        .alert("Error de Pago", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Información de Pago")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Todos los datos están protegidos con encriptación SSL")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Product Summary Section
    private var productSummarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Resumen de Compra")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Product Icon
                Image(systemName: product.isSubscription ? "crown.fill" : "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(product.isSubscription ? .purple : .blue)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(product.isSubscription ? Color.purple.opacity(0.1) : Color.blue.opacity(0.1))
                    )
                
                // Product Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if !product.isImplementationFee {
                        Text(product.invoiceCountText)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.formattedPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if product.isSubscription {
                        Text(product.subscriptionText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Credit Card Form Section
    private var creditCardFormSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Información de la Tarjeta")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Card Number
                VStack(alignment: .leading, spacing: 4) {
                    Text("Número de Tarjeta")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("1234 5678 9012 3456", text: $viewModel.cardNumber)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.cardNumber) { _, newValue in
                            viewModel.formatCardNumber(newValue)
                        }
                }
                
                // Cardholder Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nombre del Tarjetahabiente")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("JUAN PEREZ", text: $viewModel.cardholderName)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textInputAutocapitalization(.characters)
                }
                
                // Expiry and CVV
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fecha de Vencimiento")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("MM/YY", text: $viewModel.expiryDate)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: viewModel.expiryDate) { _, newValue in
                                viewModel.formatExpiryDate(newValue)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CVV")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("123", text: $viewModel.cvv)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: viewModel.cvv) { _, newValue in
                                viewModel.formatCVV(newValue)
                            }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Customer Info Section
    private var customerInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Información del Cliente")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Customer Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nombre Completo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Juan Pérez", text: $viewModel.customerName)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textInputAutocapitalization(.words)
                }
                
                // Email
                VStack(alignment: .leading, spacing: 4) {
                    Text("Correo Electrónico")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("juan@ejemplo.com", text: $viewModel.customerEmail)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                
                // Phone
                VStack(alignment: .leading, spacing: 4) {
                    Text("Teléfono")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("+503 7720 2044", text: $viewModel.customerPhone)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.phonePad)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Payment Button Section
    private var paymentButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: processPayment) {
                ZStack {
                    // Background with animated gradient
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: product.isSubscription ? 
                                    [Color.purple, Color.purple.opacity(0.8)] :
                                    [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .overlay(
                            // Animated shimmer effect when processing
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: isProcessing ? 300 : -300)
                                .animation(
                                    isProcessing ? 
                                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false) : 
                                        .default,
                                    value: isProcessing
                                )
                                .opacity(isProcessing ? 1 : 0)
                        )
                    
                    // Content
                    HStack(spacing: 12) {
                        if isProcessing {
                            // Custom loading animation
                            HStack(spacing: 4) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(isProcessing ? 1.2 : 0.8)
                                        .animation(
                                            Animation.easeInOut(duration: 0.6)
                                                .repeatForever()
                                                .delay(Double(index) * 0.2),
                                            value: isProcessing
                                        )
                                }
                            }
                            
                            Text("Procesando...")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .opacity(isProcessing ? 0.9 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: isProcessing)
                        } else {
                            Image(systemName: product.isSubscription ? "crown.fill" : "creditcard.fill")
                                .foregroundColor(.white)
                                .scaleEffect(1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isProcessing)
                            
                            Text(product.isSubscription ? "Suscribirse Ahora" : "Pagar Ahora")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(isProcessing ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isProcessing)
                }
                .shadow(
                    color: (product.isSubscription ? Color.purple : Color.blue).opacity(isProcessing ? 0.5 : 0.3), 
                    radius: isProcessing ? 8 : 4, 
                    x: 0, 
                    y: isProcessing ? 4 : 2
                )
                .animation(.easeInOut(duration: 0.3), value: isProcessing)
            }
            .disabled(!viewModel.isFormValid || isProcessing)
            .scaleEffect((!viewModel.isFormValid || isProcessing) ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isFormValid)
            
            // Security Notice
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                Text("Pago seguro con encriptación SSL N1CO")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Terms and Privacy
            Text("Al proceder, aceptas nuestros términos y condiciones")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Process Payment
    private func processPayment() {
        Task {
            await MainActor.run {
                isProcessing = true
            }
            
            do {
                // Create payment method
                let createdPaymentMethodId = try await N1COEpayService.shared.createPaymentMethod(
                    customerName: viewModel.customerName,
                    customerEmail: viewModel.customerEmail,
                    customerPhone: viewModel.customerPhone,
                    cardNumber: viewModel.cardNumber.replacingOccurrences(of: " ", with: ""),
                    expirationMonth: viewModel.expirationMonth,
                    expirationYear: viewModel.expirationYear,
                    cvv: viewModel.cvv,
                    cardHolder: viewModel.cardholderName,
                    appleId: userID.isEmpty ? nil : userID
                )
                
                // Store payment method ID for potential 3DS completion
                paymentMethodId = createdPaymentMethodId
                
                // Process payment based on product type
                if product.isSubscription {
                    // Create subscription plan and subscribe user
                    let planId = try await N1COEpayService.shared.createSubscriptionPlan(product)
                    
                    try await N1COEpayService.shared.subscribeUser(
                        planId: planId,
                        customerName: viewModel.customerName,
                        customerEmail: viewModel.customerEmail,
                        customerPhone: viewModel.customerPhone,
                        paymentMethodId: createdPaymentMethodId,
                        appleId: userID.isEmpty ? nil : userID
                    )
                } else {
                    // Process one-time purchase (first attempt, no authenticationId)
                    try await N1COEpayService.shared.purchaseProduct(
                        product,
                        paymentMethodId: createdPaymentMethodId
                    )
                }
                
                // Handle payment state
                await handlePaymentState()
                
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    @MainActor
    private func handlePaymentState() async {
        switch N1COEpayService.shared.purchaseState {
        case .succeeded:
            // Keep loading for a brief moment to show success state
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            isProcessing = false
            onPaymentSuccess()
            dismiss()
            
        case .requiresAuthentication(let url):
            isProcessing = false
            authenticationURL = url
            // Extract authenticationId from the URL if needed

            showingAuthenticationSheet = true
            
        case .failed(let message):
            isProcessing = false
            viewModel.errorMessage = message
            
        case .processing:
            // Keep loading animation running
            break
            
        default:
            isProcessing = false
            break
        }
    }
    
    // MARK: - 3DS Completion
    @MainActor
    private func complete3DSPayment(paymentMethodId: String) async {
        isProcessing = true
        
        do {
            // Complete the payment with the authenticationId
            try await N1COEpayService.shared.purchaseProduct(
                product,
                paymentMethodId: paymentMethodId
            )
            
            // Handle the final payment state
            await handlePaymentState()
            
        } catch {
            isProcessing = false
            viewModel.errorMessage = "Error al completar el pago: \(error.localizedDescription)"
            print("❌ [3DS Complete] Error completing payment: \(error)")
        }
    }
}

// MARK: - ViewModel
@MainActor
class CreditCardInputViewModel: ObservableObject {
    // Card fields (cardNumber and cvv are not stored for security)
    @Published var cardNumber = ""
    @AppStorage("cardholderName") var cardholderName = ""
    @AppStorage("expiryDate") var expiryDate = ""
    @Published var cvv = ""
    
    // Customer fields
    @AppStorage("customerName") var customerName = ""
    @AppStorage("customerEmail") var customerEmail = ""
    @AppStorage("customerPhone") var customerPhone = ""
    
    // State
    @Published var errorMessage: String?
    
    var isFormValid: Bool {
        return !cardNumber.isEmpty &&
               !cardholderName.isEmpty &&
               !expiryDate.isEmpty &&
               !cvv.isEmpty &&
               !customerName.isEmpty &&
               !customerEmail.isEmpty &&
               !customerPhone.isEmpty &&
               isValidEmail(customerEmail) &&
               cardNumber.replacingOccurrences(of: " ", with: "").count >= 13 &&
               expiryDate.count == 5 &&
               cvv.count >= 3
    }
    
    var expirationMonth: String {
        return String(expiryDate.prefix(2))
    }
    
    var expirationYear: String {
        return "20" + String(expiryDate.suffix(2))
    }
    
    func formatCardNumber(_ input: String) {
        let digits = input.replacingOccurrences(of: " ", with: "")
        let limited = String(digits.prefix(16))
        
        var formatted = ""
        for (index, char) in limited.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(char)
        }
        
        cardNumber = formatted
    }
    
    func formatExpiryDate(_ input: String) {
        let digits = input.replacingOccurrences(of: "/", with: "")
        let limited = String(digits.prefix(4))
        
        if limited.count >= 2 {
            expiryDate = String(limited.prefix(2)) + "/" + String(limited.dropFirst(2))
        } else {
            expiryDate = limited
        }
    }
    
    func formatCVV(_ input: String) {
        cvv = String(input.prefix(4))
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
    }
}

// MARK: - 3DS Authentication View
struct ThreeDSAuthenticationView: View {
    let url: String
    let onCompletion: (Bool, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var authenticationData: (success: Bool, authenticationId: String?)? = nil
    @State private var showCompletarButton = false
    
    var body: some View {
        NavigationView {
            ZStack {
                WebView(url: url) { success, authenticationId, status in
                    // Store the authentication data but don't auto-complete
                    authenticationData = (success: success, authenticationId: authenticationId)
                    
                    // Show the Completar button after receiving authentication data
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCompletarButton = true
                    }
                    
                    print("🎯 [3DS UI] Authentication data received - Success: \(success), AuthID: \(authenticationId ?? "nil"), Status: \(status ?? "nil")")
                }
                
                // Completar button overlay
                if showCompletarButton {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                print("🔘 [UI] Completar button tapped")
                                if let data = authenticationData {
                                    onCompletion(data.success, data.authenticationId)
                                } else {
                                    onCompletion(false, nil)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Completar")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.green)
                                        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                            }
                            .scaleEffect(showCompletarButton ? 1.0 : 0.8)
                            .opacity(showCompletarButton ? 1.0 : 0.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showCompletarButton)
                            
                            Spacer()
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .navigationTitle("Verificación de Seguridad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        onCompletion(false, nil)
                    }
                }
            }
        }
    }
}

// MARK: - WebView for 3DS
struct WebView: UIViewRepresentable {
    let url: String
    let onCompletion: (Bool, String?, String?) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        // Add message handler for authentication results
        contentController.add(context.coordinator, name: "authenticationResult")
        configuration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        if let url = URL(string: url) {
            print("🌐 [3DS WebView] Loading authentication URL: \(url)")
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🌐 [3DS Navigation] Started loading: \(webView.url?.absoluteString ?? "unknown")")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("🌐 [3DS Navigation] Finished loading: \(webView.url?.absoluteString ?? "unknown")")
            
            // Enhanced JavaScript to capture 3DS authentication messages
            let jsCode = """
                console.log("🔧 [3DS Setup] Initializing message listener for 3DS authentication");
                
                // Add an event listener to capture messages from the iframe
                window.addEventListener("message", function (event) {
                    console.log(" [3DS Message] Received message from origin:", event.origin);
                    console.log(" [3DS Message] Raw data:", event.data);
                    
                    // Check if the event origin is from the trusted 3DS source
                    if (event.origin === "https://front-3ds.h4b.dev" || event.origin.includes("h4b.dev") || event.origin === "https://front-3ds-sandbox.n1co.com") {
                        try {
                            // Parse the JSON data received from the iframe
                            var dataMessage;
                            if (typeof event.data === 'string') {
                                dataMessage = JSON.parse(event.data);
                            } else {
                                dataMessage = event.data;
                            }
                            
                            // Access the properties of the dataMessage object
                            var messageType = dataMessage.MessageType;
                            var status = dataMessage.Status;
                            var authenticationId = dataMessage.AuthenticationId;
                            var orderId = dataMessage.OrderId;
                            var orderAmount = dataMessage.OrderAmount;
                            
                            // Log captured data for debugging
                            console.log(" [3DS Data] Message Type:", messageType);
                            console.log(" [3DS Data] Status:", status);
                            console.log(" [3DS Data] Authentication ID:", authenticationId);
                            console.log(" [3DS Data] Order ID:", orderId);
                            console.log(" [3DS Data] Order Amount:", orderAmount);
                            
                            // Check if this is an authentication completion message
                            if (messageType === 'authentication.complete') {
                                console.log("🎯 [3DS Complete]----------------------- Authentication completed with status:", status);
                                
                                // Send result to native Swift code
                                window.webkit.messageHandlers.authenticationResult.postMessage({
                                    success: status === 'SUCCESS',
                                    status: status,
                                    authenticationId: authenticationId,
                                    orderId: orderId,
                                    orderAmount: orderAmount,
                                    messageType: messageType
                                });
                            } else {
                                console.log("ℹ️ [3DS Info] Received non-completion message type:", messageType);
                            }
                        } catch (error) {
                            console.error("❌ [3DS Error] Failed to parse message data:", error);
                            console.error("❌ [3DS Error] Raw data was:", event.data);
                        }
                    } else {
                        console.log("⚠️ [3DS Security] Ignoring message from untrusted origin:", event.origin);
                    }
                });
                
                console.log("✅ [3DS Setup] Message listener setup complete");
            """
            
            webView.evaluateJavaScript(jsCode) { result, error in
                if let error = error {
                    print("❌ [3DS JavaScript] Error injecting script: \(error.localizedDescription)")
                } else {
                    print("✅ [3DS JavaScript] Message listener script injected successfully")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ [3DS Navigation] Failed to load: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ [3DS Navigation] Failed provisional navigation: \(error.localizedDescription)")
        }
        
        // Handle messages from JavaScript
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print("📱 [3DS Native] Received message from JavaScript: \(message.name)")
            
            if message.name == "authenticationResult" {
                guard let body = message.body as? [String: Any] else {
                    print("❌ [3DS Native] Invalid message body format")
                    return
                }
                
                let success = body["success"] as? Bool ?? false
                let status = body["status"] as? String ?? "UNKNOWN"
                let authenticationId = body["authenticationId"] as? String
                let orderId = body["orderId"] as? String
                let orderAmount = body["orderAmount"] as? String
                let messageType = body["messageType"] as? String
                
                print("🎯 [3DS Result] Authentication result:")
                print("  - Success: \(success)")
                print("  - Status: \(status)")
                print("  - Authentication ID: \(authenticationId ?? "nil")")
                print("  - Order ID: \(orderId ?? "nil")")
                print("  - Order Amount: \(orderAmount ?? "nil")")
                print("  - Message Type: \(messageType ?? "nil")")
                
                // Pass the result to the parent with all three parameters
                // The parent will handle showing the Completar button
                DispatchQueue.main.async {
                    self.parent.onCompletion(success, authenticationId, status)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CreditCardInputView(
        product: CustomPaymentProduct.bundle100,
        onPaymentSuccess: {}
    )
}
