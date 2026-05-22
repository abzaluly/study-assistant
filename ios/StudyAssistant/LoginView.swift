import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRegister = false

    var body: some View {
        ZStack {
            Color(hex: "#1a1625").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 64))
                            .foregroundStyle(Color(hex: "#7c3aed"))
                            .padding(.top, 60)

                        Text("Study Assistant")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text("AI-репетитор для студентов")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#a78bfa"))
                    }

                    VStack(spacing: 16) {
                        AppTextField(placeholder: "Email", text: $email, icon: "envelope")
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        AppTextField(placeholder: "Пароль", text: $password, icon: "lock", isSecure: true)
                    }
                    .padding(.horizontal, 24)

                    if let err = errorMessage {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        Button {
                            doLogin()
                        } label: {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Войти")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color(hex: "#7c3aed"))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)

                        Button("Нет аккаунта? Зарегистрироваться") {
                            showRegister = true
                        }
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#a78bfa"))
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
    }

    private func doLogin() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let resp = try await APIService.shared.login(email: email, password: password)
                await MainActor.run { auth.login(token: resp.token, user: resp.user) }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Reusable text field

struct AppTextField: View {
    var placeholder: String
    @Binding var text: String
    var icon: String
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#a78bfa"))
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color(hex: "#251e35"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#3d2e5e"), lineWidth: 1)
        )
    }
}

// MARK: - Color extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
