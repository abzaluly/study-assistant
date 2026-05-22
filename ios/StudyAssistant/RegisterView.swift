import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var ageText = ""
    @State private var selectedLevel = "beginner"
    @State private var selectedInterests: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    let levels = [("beginner", "Начинающий"), ("intermediate", "Средний"), ("advanced", "Продвинутый")]
    let allInterests = ["спорт", "музыка", "кино", "игры", "технологии", "наука", "путешествия", "кулинария"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1a1625").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 14) {
                            AppTextField(placeholder: "Имя", text: $name, icon: "person")
                            AppTextField(placeholder: "Email", text: $email, icon: "envelope")
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            AppTextField(placeholder: "Пароль", text: $password, icon: "lock", isSecure: true)
                            AppTextField(placeholder: "Возраст (необязательно)", text: $ageText, icon: "number")
                                .keyboardType(.numberPad)
                        }
                        .padding(.horizontal, 24)

                        // Level picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Уровень знаний")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(levels, id: \.0) { level in
                                        Button {
                                            selectedLevel = level.0
                                        } label: {
                                            Text(level.1)
                                                .font(.subheadline)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(selectedLevel == level.0 ? Color(hex: "#7c3aed") : Color(hex: "#251e35"))
                                                .foregroundColor(.white)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedLevel == level.0 ? Color.clear : Color(hex: "#3d2e5e"), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }

                        // Interests
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Интересы (для персонализации примеров)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                                ForEach(allInterests, id: \.self) { interest in
                                    Button {
                                        if selectedInterests.contains(interest) {
                                            selectedInterests.remove(interest)
                                        } else {
                                            selectedInterests.insert(interest)
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            if selectedInterests.contains(interest) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color(hex: "#7c3aed"))
                                            }
                                            Text(interest)
                                                .font(.subheadline)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedInterests.contains(interest) ? Color(hex: "#2d1f4e") : Color(hex: "#251e35"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedInterests.contains(interest) ? Color(hex: "#7c3aed") : Color(hex: "#3d2e5e"), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        if let err = errorMessage {
                            Text(err)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button {
                            doRegister()
                        } label: {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Зарегистрироваться")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color(hex: "#7c3aed"))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                        .disabled(isLoading || name.isEmpty || email.isEmpty || password.isEmpty)

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Регистрация")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(Color(hex: "#a78bfa"))
                }
            }
        }
    }

    private func doRegister() {
        isLoading = true
        errorMessage = nil
        let age = Int(ageText)
        Task {
            do {
                let resp = try await APIService.shared.register(
                    name: name, email: email, password: password,
                    age: age, interests: Array(selectedInterests), level: selectedLevel
                )
                await MainActor.run {
                    auth.login(token: resp.token, user: resp.user)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
