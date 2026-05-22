import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var subjects: [SubjectModel] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var newTitle = ""
    @State private var newDescription = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(hex: "#1a1625").ignoresSafeArea()

            Group {
                if isLoading && subjects.isEmpty {
                    ProgressView("Загрузка...")
                        .tint(Color(hex: "#7c3aed"))
                        .foregroundColor(.white)
                } else if subjects.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#7c3aed"))
                        Text("Нет предметов")
                            .font(.title3)
                            .foregroundColor(.white)
                        Text("Нажмите + чтобы добавить предмет")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#a78bfa"))
                    }
                } else {
                    List {
                        ForEach(subjects) { subject in
                            NavigationLink(destination: SubjectDetailView(subject: subject)) {
                                SubjectRow(subject: subject)
                            }
                            .listRowBackground(Color(hex: "#1e1830"))
                            .listRowSeparatorTint(Color(hex: "#2d2450"))
                        }
                        .onDelete(perform: deleteSubjects)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Мои предметы")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color(hex: "#7c3aed"))
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addSubjectSheet
        }
        .task { await loadSubjects() }
        .refreshable { await loadSubjects() }
    }

    private var addSubjectSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1a1625").ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(spacing: 14) {
                        AppTextField(placeholder: "Название предмета", text: $newTitle, icon: "book")
                        AppTextField(placeholder: "Описание (необязательно)", text: $newDescription, icon: "text.alignleft")
                    }
                    .padding(.horizontal, 24)

                    Button {
                        Task { await addSubject() }
                    } label: {
                        Text("Добавить")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(newTitle.isEmpty ? Color.gray : Color(hex: "#7c3aed"))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .disabled(newTitle.isEmpty)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Новый предмет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        newTitle = ""; newDescription = ""
                        showAddSheet = false
                    }
                    .foregroundColor(Color(hex: "#a78bfa"))
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadSubjects() async {
        guard let userId = auth.user?.id else { return }
        isLoading = true
        do {
            let result = try await APIService.shared.getSubjects(userId: userId)
            await MainActor.run { subjects = result; isLoading = false }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
        }
    }

    private func addSubject() async {
        guard let userId = auth.user?.id else { return }
        do {
            let s = try await APIService.shared.createSubject(
                title: newTitle,
                description: newDescription.isEmpty ? nil : newDescription,
                userId: userId
            )
            await MainActor.run {
                subjects.append(s)
                newTitle = ""; newDescription = ""
                showAddSheet = false
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func deleteSubjects(at offsets: IndexSet) {
        let ids = offsets.map { subjects[$0].id }
        subjects.remove(atOffsets: offsets)
        Task {
            for id in ids {
                try? await APIService.shared.deleteSubject(id: id)
            }
        }
    }
}

struct SubjectRow: View {
    let subject: SubjectModel

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#2d1f4e"))
                    .frame(width: 44, height: 44)
                Text(String(subject.title.prefix(1)).uppercased())
                    .font(.headline.bold())
                    .foregroundColor(Color(hex: "#a78bfa"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title)
                    .font(.headline)
                    .foregroundColor(.white)
                if let desc = subject.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(Color(hex: "#a78bfa"))
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
