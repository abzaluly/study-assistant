import Foundation

enum APIError: Error, LocalizedError {
    case serverError(Int, String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .serverError(let code, let msg):
            return "Ошибка \(code): \(msg)"
        case .decodingError(let msg):
            return "Ошибка данных: \(msg)"
        }
    }
}

class APIService {
    static let shared = APIService()

    // MARK: - Configuration
    // Simulator: http://localhost:8000/api
    // Real device: замени на IP своего Mac (узнай через: ipconfig getifaddr en0)
    #if targetEnvironment(simulator)
    var baseURL = "http://localhost:8000/api"
    #else
    var baseURL = "http://192.168.1.139:8000/api"
    #endif

    var token: String? {
        get { UserDefaults.standard.string(forKey: "jwt_token") }
        set { UserDefaults.standard.set(newValue, forKey: "jwt_token") }
    }

    // MARK: - Helpers

    private func request(_ path: String, method: String = "GET", body: Data? = nil) -> URLRequest {
        let url = URL(string: baseURL + path)!
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        req.httpBody = body
        return req
    }

    private func fetch<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        let req = request(path, method: method, body: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "Нет ответа"
            throw APIError.serverError(http.statusCode, msg)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = try JSONEncoder().encode(["email": email, "password": password])
        return try await fetch("/auth/login", method: "POST", body: body)
    }

    func register(name: String, email: String, password: String, age: Int?, interests: [String], level: String) async throws -> AuthResponse {
        var dict: [String: Any] = [
            "name": name, "email": email, "password": password,
            "student_level": level, "interests": interests
        ]
        if let a = age { dict["age"] = a }
        let body = try JSONSerialization.data(withJSONObject: dict)
        return try await fetch("/auth/register", method: "POST", body: body)
    }

    // MARK: - Subjects

    func getSubjects(userId: String) async throws -> [SubjectModel] {
        try await fetch("/subjects?user_id=\(userId)")
    }

    func createSubject(title: String, description: String?, userId: String) async throws -> SubjectModel {
        var dict: [String: Any] = ["title": title, "user_id": userId]
        if let d = description { dict["description"] = d }
        let body = try JSONSerialization.data(withJSONObject: dict)
        return try await fetch("/subjects/", method: "POST", body: body)
    }

    func deleteSubject(id: String) async throws {
        let req = request("/subjects/\(id)", method: "DELETE")
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Lectures

    func getLectures(subjectId: String) async throws -> [LectureModel] {
        try await fetch("/lectures?subject_id=\(subjectId)")
    }

    func createLecture(title: String, subjectId: String) async throws -> LectureModel {
        let dict: [String: Any] = ["subject_id": subjectId, "title": title, "order_index": 0]
        let body = try JSONSerialization.data(withJSONObject: dict)
        return try await fetch("/lectures/", method: "POST", body: body)
    }

    func deleteLecture(id: String) async throws {
        let req = request("/lectures/\(id)", method: "DELETE")
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Materials

    func getMaterials(lectureId: String) async throws -> [MaterialModel] {
        try await fetch("/materials?lecture_id=\(lectureId)")
    }

    func uploadMaterial(lectureId: String, sourceLabel: String, fileData: Data, fileName: String) async throws -> MaterialModel {
        let url = URL(string: baseURL + "/materials/upload")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        if let t = token { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }

        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func append(_ string: String) { body.append(string.data(using: .utf8)!) }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"lecture_id\"\r\n\r\n")
        append("\(lectureId)\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"source_label\"\r\n\r\n")
        append("\(sourceLabel)\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"type\"\r\n\r\n")
        append("pdf\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        append("Content-Type: application/pdf\r\n\r\n")
        body.append(fileData)
        append("\r\n--\(boundary)--\r\n")

        req.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw APIError.serverError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode(MaterialModel.self, from: data)
    }

    // MARK: - AI

    func analyzeNotes(lectureId: String, userId: String, interests: [String]) async throws -> AnalyzeResponse {
        let dict: [String: Any] = ["lecture_id": lectureId, "user_id": userId, "interests": interests]
        let body = try JSONSerialization.data(withJSONObject: dict)
        return try await fetch("/ai/analyze-notes", method: "POST", body: body)
    }

    func explain(lectureId: String, question: String, userId: String, interests: [String], history: [[String: String]]) async throws -> ExplainResponse {
        let dict: [String: Any] = [
            "lecture_id": lectureId, "question": question,
            "user_id": userId, "interests": interests, "chat_history": history
        ]
        let body = try JSONSerialization.data(withJSONObject: dict)
        return try await fetch("/ai/explain", method: "POST", body: body)
    }

    // MARK: - Quizzes

    func generateQuiz(lectureId: String, weakAreas: [String], interests: [String]) async throws -> GeneratedQuizResponse {
        let dict: [String: Any] = [
            "lecture_id": lectureId, "weak_areas": weakAreas,
            "interests": interests, "num_questions": 10
        ]
        let body = try JSONSerialization.data(withJSONObject: dict)
        return try await fetch("/quizzes/generate", method: "POST", body: body)
    }

    func getQuizzes(lectureId: String) async throws -> [QuizListItem] {
        try await fetch("/quizzes?lecture_id=\(lectureId)")
    }

    func getQuizQuestions(quizId: String) async throws -> GeneratedQuizResponse {
        try await fetch("/quizzes/\(quizId)/questions")
    }

    func submitAttempt(quizId: String, userId: String, answers: [String]) async throws -> QuizAttemptResult {
        let dict: [String: Any] = ["quiz_id": quizId, "user_id": userId, "answers": answers]
        let body = try JSONSerialization.data(withJSONObject: dict)
        return try await fetch("/quizzes/attempt", method: "POST", body: body)
    }
}
