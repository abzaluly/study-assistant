import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var name = ""
    @State private var selectedLevel = "beginner"
    @State private var selectedInterests: Set<String> = []
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    let levels = [("beginner", "Начинающий"), ("intermediate", "Средний"), ("advanced", "Продвинутый")]
    let allInterests = ["спорт", "музыка", "кино", "игры", "технологии", "наука", "путешествия", "кулинария"]

    var body: some View {
        ZStack {
            Color(hex: "#1a1625").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Avatar
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#7c3aed"), Color(hex: "#4f46e5")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 88, height: 88)
                            Text(String((auth.user?.name ?? "?").prefix(1)).uppercased())
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text(auth.user?.name ?? "")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Text(auth.user?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#a78bfa"))
                    }
                    .padding(.top, 20)

                    // Edit section
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Имя").font(.caption).foregroundColor(Color(hex: "#a78bfa"))
                            AppTextField(placeholder: "Ваше имя", text: $name, icon: "person")
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Уровень знаний").font(.caption).foregroundColor(Color(hex: "#a78bfa"))
                            HStack(spacing: 8) {
                                ForEach(levels, id: \.0) { level in
                                    Button {
                                        selectedLevel = level.0
                                    } label: {
                                        Text(level.1)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedLevel == level.0 ? Color(hex: "#7c3aed") : Color(hex: "#251e35"))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Интересы").font(.caption).foregroundColor(Color(hex: "#a78bfa"))
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 8) {
                                ForEach(allInterests, id: \.self) { interest in
                                    Button {
                                        if selectedInterests.contains(interest) {
                                            selectedInterests.remove(interest)
                                        } else {
                                            selectedInterests.insert(interest)
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            if selectedInterests.contains(interest) {
                                                Image(systemName: "checkmark").font(.caption2)
                                            }
                                            Text(interest).font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(selectedInterests.contains(interest) ? Color(hex: "#2d1f4e") : Color(hex: "#251e35"))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedInterests.contains(interest) ? Color(hex: "#7c3aed") : Color(hex: "#3d2e5e"), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "#1e1830"))
                    .cornerRadius(16)

                    if let err = errorMessage {
                        Text(err).foregroundColor(.red).font(.caption)
                    }

                    if showSuccess {
                        Label("Сохранено!", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }

                    Button {
                        Task { await saveProfile() }
                    } label: {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Сохранить изменения")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color(hex: "#7c3aed"))
                    .cornerRadius(14)
                    .disabled(isSaving)

                    Button {
                        auth.logout()
                    } label: {
                        Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color(hex: "#2d0e0e"))
                            .cornerRadius(14)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Профиль")
        .onAppear { loadUser() }
    }

    private func loadUser() {
        guard let user = auth.user else { return }
        name = user.name
        selectedLevel = user.student_level
        selectedInterests = Set(user.interests)
    }

    private func saveProfile() async {
        guard let user = auth.user else { return }
        isSaving = true
        errorMessage = nil

        let url = URL(string: APIService.shared.baseURL + "/auth/profile/\(user.id)")!
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = APIService.shared.token { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }

        let dict: [String: Any] = [
            "name": name,
            "student_level": selectedLevel,
            "interests": Array(selectedInterests)
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: dict)

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let updated = try JSONDecoder().decode(UserModel.self, from: data)
            await MainActor.run {
                auth.updateUser(updated)
                isSaving = false
                showSuccess = true
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { showSuccess = false }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}
