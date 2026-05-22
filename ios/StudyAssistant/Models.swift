import Foundation

// MARK: - Auth
struct UserModel: Codable, Identifiable {
    let id: String
    var name: String
    var email: String
    var age: Int?
    var interests: [String]
    var student_level: String
}

struct AuthResponse: Codable {
    let token: String
    let user: UserModel
}

// MARK: - Subjects
struct SubjectModel: Codable, Identifiable {
    let id: String
    var title: String
    var description: String?
}

// MARK: - Lectures
struct LectureModel: Codable, Identifiable {
    let id: String
    var title: String
    var order_index: Int
    var subject_id: String
}

// MARK: - Materials
struct MaterialModel: Codable, Identifiable {
    let id: String
    var source_label: String
    var original_filename: String?
    var type: String?
}

// MARK: - AI Analysis
struct AnalyzeResponse: Codable {
    var understanding_estimate: Double
    var explanation: String
    var missing_topics: [String]
    var incomplete_topics: [IncompleteTopic]
    var weak_areas: [String]
    var recommendations: [String]
    var key_concepts: [KeyConcept]
    var completed_note_text: String?

    struct IncompleteTopic: Codable {
        var topic: String
        var issue: String
    }

    struct KeyConcept: Codable {
        var term: String
        var simple_explanation: String
        var example_with_interests: String?
        var importance: String?
        var svg: String?
    }
}

struct ExplainResponse: Codable {
    var answer: String
    var svg: String?
}

// MARK: - Quizzes
struct QuizListItem: Codable, Identifiable {
    let id: String
    var title: String
    var attempts_count: Int
    var best_score: Int
}

struct QuizQuestionModel: Codable, Identifiable {
    let id: String
    var question: String
    var options: [String]
    var correct_answer: String
    var explanation: String
    var topic: String?
    var difficulty: String?
}

struct GeneratedQuizResponse: Codable {
    var quiz_id: String
    var title: String
    var questions: [QuizQuestionModel]
}

struct QuizAttemptResult: Codable {
    var score: Double
    var correct: Int
    var total: Int
    var percentage: Int
    var results: [QuestionResult]

    struct QuestionResult: Codable {
        var question: String
        var your_answer: String
        var correct_answer: String
        var is_correct: Bool
        var explanation: String
        var options: [String]
    }
}
