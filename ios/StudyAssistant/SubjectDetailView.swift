import SwiftUI

struct SubjectDetailView: View {
    let subject: SubjectModel
    @State private var lectures: [LectureModel] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var newTitle = ""

    var body: some View {
        ZStack {
            Color(hex: "#1a1625").ignoresSafeArea()

            Group {
                if isLoading && lectures.isEmpty {
                    ProgressView("Загрузка...")
                        .tint(Color(hex: "#7c3aed"))
                        .foregroundColor(.white)
                } else if lectures.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 56))
                            .foregroundColor(Color(hex: "#7c3aed"))
                        Text("Нет лекций")
                            .font(.title3)
                            .foregroundColor(.white)
                        Text("Добавьте первую лекцию")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#a78bfa"))
                    }
                } else {
                    List {
                        ForEach(Array(lectures.enumerated()), id: \.element.id) { idx, lecture in
                            NavigationLink(destination: LectureDetailView(lecture: lecture)) {
                                LectureRow(lecture: lecture, index: idx + 1)
                            }
                            .listRowBackground(Color(hex: "#1e1830"))
                            .listRowSeparatorTint(Color(hex: "#2d2450"))
                        }
                        .onDelete(perform: deleteLectures)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle(subject.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color(hex: "#7c3aed"))
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addLectureSheet
        }
        .task { await loadLectures() }
        .refreshable { await loadLectures() }
    }

    private var addLectureSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1a1625").ignoresSafeArea()
                VStack(spacing: 20) {
                    AppTextField(placeholder: "Название лекции", text: $newTitle, icon: "doc.text")
                        .padding(.horizontal, 24)

                    Button {
                        Task { await addLecture() }
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
            .navigationTitle("Новая лекция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { newTitle = ""; showAddSheet = false }
                        .foregroundColor(Color(hex: "#a78bfa"))
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadLectures() async {
        isLoading = true
        do {
            let result = try await APIService.shared.getLectures(subjectId: subject.id)
            await MainActor.run { lectures = result; isLoading = false }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    private func addLecture() async {
        do {
            let l = try await APIService.shared.createLecture(title: newTitle, subjectId: subject.id)
            await MainActor.run {
                lectures.append(l)
                newTitle = ""
                showAddSheet = false
            }
        } catch {}
    }

    private func deleteLectures(at offsets: IndexSet) {
        let ids = offsets.map { lectures[$0].id }
        lectures.remove(atOffsets: offsets)
        Task {
            for id in ids { try? await APIService.shared.deleteLecture(id: id) }
        }
    }
}

struct LectureRow: View {
    let lecture: LectureModel
    let index: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#2d1f4e"))
                    .frame(width: 44, height: 44)
                Text("\(index)")
                    .font(.headline.bold())
                    .foregroundColor(Color(hex: "#7c3aed"))
            }
            Text(lecture.title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
