import SwiftUI
import WebKit
import UniformTypeIdentifiers

// MARK: - SVG WebView
struct SVGWebView: UIViewRepresentable {
    let svgContent: String

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.isScrollEnabled = false
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>body{margin:0;background:transparent;display:flex;justify-content:center;align-items:center;}svg{max-width:100%;height:auto;}</style>
        </head><body>\(svgContent)</body></html>
        """
        wv.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL, String) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL, String) -> Void
        init(onPick: @escaping (URL, String) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url, url.lastPathComponent)
        }
    }
}

// MARK: - Lecture Detail View

enum LectureTab: String, CaseIterable {
    case materials = "Материалы"
    case analysis = "Анализ"
    case chat = "Чат"
    case quiz = "Тест"

    var icon: String {
        switch self {
        case .materials: return "paperclip"
        case .analysis: return "brain"
        case .chat: return "bubble.left.and.bubble.right"
        case .quiz: return "checkmark.circle"
        }
    }
}

struct LectureDetailView: View {
    let lecture: LectureModel
    @EnvironmentObject var auth: AuthManager
    @State private var selectedTab: LectureTab = .materials

    var body: some View {
        ZStack {
            Color(hex: "#1a1625").ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom tab bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(LectureTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation { selectedTab = tab }
                            } label: {
                                VStack(spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: tab.icon)
                                            .font(.caption)
                                        Text(tab.rawValue)
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .foregroundColor(selectedTab == tab ? Color(hex: "#7c3aed") : Color(hex: "#a78bfa").opacity(0.6))

                                    Rectangle()
                                        .fill(selectedTab == tab ? Color(hex: "#7c3aed") : Color.clear)
                                        .frame(height: 2)
                                }
                            }
                        }
                    }
                }
                .background(Color(hex: "#1e1830"))

                Divider().background(Color(hex: "#2d2450"))

                // Tab content
                switch selectedTab {
                case .materials:
                    MaterialsTabView(lecture: lecture)
                case .analysis:
                    AnalysisTabView(lecture: lecture)
                case .chat:
                    ChatTabView(lecture: lecture)
                case .quiz:
                    QuizTabView(lecture: lecture)
                }
            }
        }
        .navigationTitle(lecture.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Materials Tab

struct MaterialsTabView: View {
    let lecture: LectureModel
    @EnvironmentObject var auth: AuthManager
    @State private var materials: [MaterialModel] = []
    @State private var isLoading = false
    @State private var uploadingLabel: String?
    @State private var showPicker = false
    @State private var pendingLabel: String = "lecture"
    @State private var errorMessage: String?

    var lectureMaterials: [MaterialModel] { materials.filter { $0.source_label == "lecture" } }
    var noteMaterials: [MaterialModel] { materials.filter { $0.source_label == "note" } }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let err = errorMessage {
                    Text(err).foregroundColor(.red).font(.caption).padding()
                }

                // Upload lecture
                UploadCard(
                    title: "Материал лекции",
                    icon: "doc.fill",
                    color: "#4f46e5",
                    files: lectureMaterials,
                    isUploading: uploadingLabel == "lecture"
                ) {
                    pendingLabel = "lecture"
                    showPicker = true
                }

                // Upload notes
                UploadCard(
                    title: "Мой конспект",
                    icon: "pencil.and.list.clipboard",
                    color: "#059669",
                    files: noteMaterials,
                    isUploading: uploadingLabel == "note"
                ) {
                    pendingLabel = "note"
                    showPicker = true
                }
            }
            .padding(20)
        }
        .task { await loadMaterials() }
        .sheet(isPresented: $showPicker) {
            DocumentPicker { url, name in
                Task { await upload(url: url, name: name, label: pendingLabel) }
            }
        }
    }

    private func loadMaterials() async {
        isLoading = true
        do {
            let result = try await APIService.shared.getMaterials(lectureId: lecture.id)
            await MainActor.run { materials = result; isLoading = false }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    private func upload(url: URL, name: String, label: String) async {
        await MainActor.run { uploadingLabel = label }
        do {
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let material = try await APIService.shared.uploadMaterial(lectureId: lecture.id, sourceLabel: label, fileData: data, fileName: name)
            await MainActor.run {
                materials.append(material)
                uploadingLabel = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                uploadingLabel = nil
            }
        }
    }
}

struct UploadCard: View {
    let title: String
    let icon: String
    let color: String
    let files: [MaterialModel]
    let isUploading: Bool
    let onUpload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: color))
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if isUploading {
                    ProgressView().tint(Color(hex: color))
                } else {
                    Button(action: onUpload) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: color))
                    }
                }
            }

            if files.isEmpty {
                Text("Файл не загружен")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#a78bfa").opacity(0.6))
            } else {
                ForEach(files) { file in
                    HStack(spacing: 8) {
                        Image(systemName: "doc.fill")
                            .foregroundColor(Color(hex: color))
                            .font(.caption)
                        Text(file.original_filename ?? "PDF файл")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#a78bfa"))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    .padding(10)
                    .background(Color(hex: "#251e35"))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#1e1830"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#2d2450"), lineWidth: 1))
    }
}

// MARK: - Analysis Tab

struct AnalysisTabView: View {
    let lecture: LectureModel
    @EnvironmentObject var auth: AuthManager
    @State private var result: AnalyzeResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let err = errorMessage {
                    Text(err).foregroundColor(.red).font(.caption).padding()
                }

                if let result = result {
                    // Score
                    VStack(spacing: 8) {
                        Text("Уровень понимания")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#a78bfa"))

                        ZStack {
                            Circle()
                                .stroke(Color(hex: "#2d2450"), lineWidth: 8)
                                .frame(width: 100, height: 100)
                            Circle()
                                .trim(from: 0, to: result.understanding_estimate)
                                .stroke(Color(hex: "#7c3aed"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(result.understanding_estimate * 100))%")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }

                        Text(result.explanation)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#a78bfa"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(Color(hex: "#1e1830"))
                    .cornerRadius(16)

                    // Missing topics
                    if !result.missing_topics.isEmpty {
                        AnalysisSection(title: "Пропущенные темы", icon: "xmark.circle.fill", color: "#ef4444") {
                            ForEach(result.missing_topics, id: \.self) { topic in
                                BulletRow(text: topic, color: "#ef4444")
                            }
                        }
                    }

                    // Weak areas
                    if !result.weak_areas.isEmpty {
                        AnalysisSection(title: "Слабые места", icon: "exclamationmark.triangle.fill", color: "#f59e0b") {
                            ForEach(result.weak_areas, id: \.self) { area in
                                BulletRow(text: area, color: "#f59e0b")
                            }
                        }
                    }

                    // Recommendations
                    if !result.recommendations.isEmpty {
                        AnalysisSection(title: "Рекомендации", icon: "lightbulb.fill", color: "#10b981") {
                            ForEach(result.recommendations, id: \.self) { rec in
                                BulletRow(text: rec, color: "#10b981")
                            }
                        }
                    }

                    // Key concepts
                    if !result.key_concepts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(Color(hex: "#7c3aed"))
                                Text("Ключевые концепции")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }

                            ForEach(result.key_concepts, id: \.term) { concept in
                                ConceptCard(concept: concept)
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "#1e1830"))
                        .cornerRadius(16)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 56))
                            .foregroundColor(Color(hex: "#7c3aed"))
                        Text("Загрузите лекцию и конспект\nна вкладке «Материалы»")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#a78bfa"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                }

                Button {
                    Task { await analyze() }
                } label: {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Label("Анализировать конспект", systemImage: "wand.and.stars")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color(hex: "#7c3aed"))
                .cornerRadius(14)
                .disabled(isLoading)

                Spacer(minLength: 20)
            }
            .padding(20)
        }
    }

    private func analyze() async {
        isLoading = true
        errorMessage = nil
        do {
            let interests = auth.user?.interests ?? []
            let userId = auth.user?.id ?? ""
            let r = try await APIService.shared.analyzeNotes(lectureId: lecture.id, userId: userId, interests: interests)
            await MainActor.run { result = r; isLoading = false }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
        }
    }
}

struct AnalysisSection<Content: View>: View {
    let title: String
    let icon: String
    let color: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(Color(hex: color))
                Text(title).font(.headline).foregroundColor(.white)
            }
            content
        }
        .padding(16)
        .background(Color(hex: "#1e1830"))
        .cornerRadius(16)
    }
}

struct BulletRow: View {
    let text: String
    let color: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Color(hex: color)).frame(width: 6, height: 6).padding(.top, 6)
            Text(text).font(.subheadline).foregroundColor(Color(hex: "#a78bfa"))
        }
    }
}

struct ConceptCard: View {
    let concept: AnalyzeResponse.KeyConcept
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { withAnimation { isExpanded.toggle() } } label: {
                HStack {
                    Text(concept.term)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color(hex: "#a78bfa"))
                        .font(.caption)
                }
            }

            if isExpanded {
                Text(concept.simple_explanation)
                    .font(.caption)
                    .foregroundColor(Color(hex: "#a78bfa"))

                if let example = concept.example_with_interests {
                    Text(example)
                        .font(.caption)
                        .foregroundColor(Color(hex: "#60a5fa"))
                        .padding(10)
                        .background(Color(hex: "#1a1625"))
                        .cornerRadius(8)
                }

                if let svg = concept.svg, !svg.isEmpty {
                    SVGWebView(svgContent: svg)
                        .frame(height: 180)
                        .cornerRadius(12)
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#251e35"))
        .cornerRadius(12)
    }
}

// MARK: - Chat Tab

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
    var svg: String?
}

struct ChatTabView: View {
    let lecture: LectureModel
    @EnvironmentObject var auth: AuthManager
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: "#7c3aed"))
                                Text("Задайте вопрос по материалу лекции")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#a78bfa"))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                        }

                        ForEach(messages) { msg in
                            ChatBubble(message: msg)
                                .id(msg.id)
                        }

                        if isLoading {
                            HStack {
                                ProgressView().tint(Color(hex: "#7c3aed"))
                                Text("Думаю...")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#a78bfa"))
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("loading")
                        }
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation { proxy.scrollTo(messages.last?.id) }
                }
            }

            // Input bar
            HStack(spacing: 12) {
                TextField("Вопрос по лекции...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(Color(hex: "#251e35"))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#3d2e5e"), lineWidth: 1))

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(inputText.isEmpty || isLoading ? Color.gray : Color(hex: "#7c3aed"))
                }
                .disabled(inputText.isEmpty || isLoading)
            }
            .padding(12)
            .background(Color(hex: "#1e1830"))
        }
    }

    private func sendMessage() async {
        let question = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        inputText = ""

        let userMsg = ChatMessage(role: "user", content: question)
        await MainActor.run { messages.append(userMsg); isLoading = true }

        let history = messages.dropLast().map { ["role": $0.role, "content": $0.content] }
        do {
            let resp = try await APIService.shared.explain(
                lectureId: lecture.id,
                question: question,
                userId: auth.user?.id ?? "",
                interests: auth.user?.interests ?? [],
                history: history
            )
            await MainActor.run {
                messages.append(ChatMessage(role: "assistant", content: resp.answer, svg: resp.svg))
                isLoading = false
            }
        } catch {
            await MainActor.run {
                messages.append(ChatMessage(role: "assistant", content: "Ошибка: \(error.localizedDescription)"))
                isLoading = false
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    var isUser: Bool { message.role == "user" }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
            HStack {
                if isUser { Spacer(minLength: 60) }

                Text(message.content)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(isUser ? Color(hex: "#7c3aed") : Color(hex: "#251e35"))
                    .cornerRadius(16)

                if !isUser { Spacer(minLength: 60) }
            }

            if let svg = message.svg, !svg.isEmpty, !isUser {
                SVGWebView(svgContent: svg)
                    .frame(height: 160)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Quiz Tab

struct QuizTabView: View {
    let lecture: LectureModel
    @EnvironmentObject var auth: AuthManager
    @State private var quizzes: [QuizListItem] = []
    @State private var isGenerating = false
    @State private var activeQuiz: GeneratedQuizResponse?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let err = errorMessage {
                    Text(err).foregroundColor(.red).font(.caption).padding()
                }

                Button {
                    Task { await generateQuiz() }
                } label: {
                    if isGenerating {
                        HStack {
                            ProgressView().tint(.white)
                            Text("Генерирую тест...").foregroundColor(.white)
                        }
                    } else {
                        Label("Создать новый тест (AI)", systemImage: "wand.and.stars")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color(hex: "#7c3aed"))
                .cornerRadius(14)
                .disabled(isGenerating)

                if !quizzes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Мои тесты")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(quizzes) { quiz in
                            QuizListRow(quiz: quiz) {
                                Task { await loadAndStartQuiz(id: quiz.id) }
                            }
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .task { await loadQuizzes() }
        .sheet(item: $activeQuiz) { quiz in
            QuizView(quiz: quiz)
        }
    }

    private func loadQuizzes() async {
        do {
            let result = try await APIService.shared.getQuizzes(lectureId: lecture.id)
            await MainActor.run { quizzes = result }
        } catch {}
    }

    private func generateQuiz() async {
        isGenerating = true
        errorMessage = nil
        do {
            let quiz = try await APIService.shared.generateQuiz(
                lectureId: lecture.id,
                weakAreas: [],
                interests: auth.user?.interests ?? []
            )
            await MainActor.run {
                activeQuiz = quiz
                isGenerating = false
                quizzes.insert(QuizListItem(id: quiz.quiz_id, title: quiz.title, attempts_count: 0, best_score: 0), at: 0)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }

    private func loadAndStartQuiz(id: String) async {
        do {
            let quiz = try await APIService.shared.getQuizQuestions(quizId: id)
            await MainActor.run { activeQuiz = quiz }
        } catch {}
    }
}

struct QuizListRow: View {
    let quiz: QuizListItem
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "#7c3aed"))
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(quiz.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                HStack(spacing: 12) {
                    Label("\(quiz.attempts_count) попыток", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#a78bfa"))
                    if quiz.best_score > 0 {
                        Label("Лучший: \(quiz.best_score)%", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#f59e0b"))
                    }
                }
            }

            Spacer()

            Button(action: onStart) {
                Text("Начать")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#7c3aed"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#2d1f4e"))
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color(hex: "#1e1830"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#2d2450"), lineWidth: 1))
    }
}
