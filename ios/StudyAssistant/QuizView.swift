import SwiftUI

extension GeneratedQuizResponse: Identifiable {
    var id: String { quiz_id }
}

struct QuizView: View {
    let quiz: GeneratedQuizResponse
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var answers: [String] = []
    @State private var showExplanation = false
    @State private var result: QuizAttemptResult?
    @State private var isSubmitting = false

    var currentQuestion: QuizQuestionModel { quiz.questions[currentIndex] }
    var isLast: Bool { currentIndex == quiz.questions.count - 1 }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1a1625").ignoresSafeArea()

                if let result = result {
                    ResultView(result: result, quizTitle: quiz.title) { dismiss() }
                } else {
                    questionView
                }
            }
            .navigationTitle(quiz.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(Color(hex: "#a78bfa"))
                }
            }
        }
    }

    private var questionView: some View {
        VStack(spacing: 0) {
            // Progress
            VStack(spacing: 8) {
                HStack {
                    Text("Вопрос \(currentIndex + 1) из \(quiz.questions.count)")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#a78bfa"))
                    Spacer()
                    Text("\(Int(Double(currentIndex) / Double(quiz.questions.count) * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "#7c3aed"))
                }
                ProgressView(value: Double(currentIndex), total: Double(quiz.questions.count))
                    .tint(Color(hex: "#7c3aed"))
                    .background(Color(hex: "#2d2450"))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            ScrollView {
                VStack(spacing: 20) {
                    // Question
                    Text(currentQuestion.question)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color(hex: "#1e1830"))
                        .cornerRadius(16)

                    // Options
                    VStack(spacing: 12) {
                        ForEach(currentQuestion.options, id: \.self) { option in
                            OptionButton(
                                option: option,
                                selected: selectedAnswer == option,
                                revealed: showExplanation,
                                correct: currentQuestion.correct_answer,
                                onTap: {
                                    if !showExplanation {
                                        selectedAnswer = option
                                    }
                                }
                            )
                        }
                    }

                    // Explanation
                    if showExplanation {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: selectedAnswer == currentQuestion.correct_answer ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(selectedAnswer == currentQuestion.correct_answer ? .green : .red)
                                Text(selectedAnswer == currentQuestion.correct_answer ? "Правильно!" : "Неправильно")
                                    .font(.headline)
                                    .foregroundColor(selectedAnswer == currentQuestion.correct_answer ? .green : .red)
                            }
                            Text(currentQuestion.explanation)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#a78bfa"))
                        }
                        .padding(16)
                        .background(Color(hex: "#1e1830"))
                        .cornerRadius(14)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // Bottom button
            VStack(spacing: 0) {
                Divider().background(Color(hex: "#2d2450"))

                if selectedAnswer != nil && !showExplanation {
                    Button {
                        withAnimation { showExplanation = true }
                    } label: {
                        Text("Проверить")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color(hex: "#7c3aed"))
                            .cornerRadius(14)
                    }
                    .padding(20)
                } else if showExplanation {
                    Button {
                        nextQuestion()
                    } label: {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text(isLast ? "Завершить тест" : "Следующий вопрос")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(isLast ? Color(hex: "#059669") : Color(hex: "#4f46e5"))
                                .cornerRadius(14)
                        }
                    }
                    .padding(20)
                    .disabled(isSubmitting)
                } else {
                    Color.clear.frame(height: 92)
                }
            }
            .background(Color(hex: "#1a1625"))
        }
    }

    private func nextQuestion() {
        answers.append(selectedAnswer ?? "")
        if isLast {
            Task { await submitQuiz() }
        } else {
            withAnimation {
                currentIndex += 1
                selectedAnswer = nil
                showExplanation = false
            }
        }
    }

    private func submitQuiz() async {
        isSubmitting = true
        do {
            let r = try await APIService.shared.submitAttempt(
                quizId: quiz.quiz_id,
                userId: auth.user?.id ?? "",
                answers: answers
            )
            await MainActor.run { result = r; isSubmitting = false }
        } catch {
            await MainActor.run { isSubmitting = false }
        }
    }
}

struct OptionButton: View {
    let option: String
    let selected: Bool
    let revealed: Bool
    let correct: String
    let onTap: () -> Void

    var optionLetter: String { String(option.prefix(1)) }
    var isCorrect: Bool { option.hasPrefix(correct) || option == correct }

    var bgColor: Color {
        if !revealed { return selected ? Color(hex: "#2d1f4e") : Color(hex: "#1e1830") }
        if isCorrect { return Color(hex: "#064e3b") }
        if selected && !isCorrect { return Color(hex: "#450a0a") }
        return Color(hex: "#1e1830")
    }

    var borderColor: Color {
        if !revealed { return selected ? Color(hex: "#7c3aed") : Color(hex: "#2d2450") }
        if isCorrect { return Color(hex: "#10b981") }
        if selected && !isCorrect { return Color(hex: "#ef4444") }
        return Color(hex: "#2d2450")
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(selected && !revealed ? Color(hex: "#7c3aed") : Color(hex: "#251e35"))
                        .frame(width: 32, height: 32)
                    Text(optionLetter)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }

                Text(option.dropFirst(2).trimmingCharacters(in: .whitespaces).isEmpty ? option : String(option.dropFirst(2)))
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Spacer()

                if revealed {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (selected ? "xmark.circle.fill" : ""))
                        .foregroundColor(isCorrect ? .green : .red)
                        .opacity(isCorrect || selected ? 1 : 0)
                }
            }
            .padding(14)
            .background(bgColor)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1.5))
        }
    }
}

struct ResultView: View {
    let result: QuizAttemptResult
    let quizTitle: String
    let onDismiss: () -> Void

    var scoreColor: Color {
        if result.percentage >= 80 { return .green }
        if result.percentage >= 60 { return Color(hex: "#f59e0b") }
        return .red
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: result.percentage >= 80 ? "trophy.fill" : result.percentage >= 60 ? "star.fill" : "arrow.clockwise")
                        .font(.system(size: 64))
                        .foregroundColor(scoreColor)

                    Text("\(result.percentage)%")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(scoreColor)

                    Text("\(result.correct) из \(result.total) правильно")
                        .font(.title3)
                        .foregroundColor(.white)

                    Text(result.percentage >= 80 ? "Отличный результат!" : result.percentage >= 60 ? "Хороший результат" : "Нужно повторить")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#a78bfa"))
                }
                .padding(30)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Детали")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(Array(result.results.enumerated()), id: \.offset) { idx, r in
                        ResultDetailRow(index: idx + 1, result: r)
                    }
                }
                .padding(20)
                .background(Color(hex: "#1e1830"))
                .cornerRadius(16)

                Button(action: onDismiss) {
                    Text("Закрыть")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color(hex: "#7c3aed"))
                        .cornerRadius(14)
                }
            }
            .padding(20)
        }
    }
}

struct ResultDetailRow: View {
    let index: Int
    let result: QuizAttemptResult.QuestionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: result.is_correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.is_correct ? .green : .red)
                Text("\(index). \(result.question)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
            if !result.is_correct {
                Text("Правильно: \(result.correct_answer)")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .padding(.leading, 28)
            }
        }
        .padding(10)
        .background(result.is_correct ? Color(hex: "#064e3b").opacity(0.4) : Color(hex: "#450a0a").opacity(0.4))
        .cornerRadius(10)
    }
}
