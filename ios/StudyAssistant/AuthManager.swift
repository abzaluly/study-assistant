import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var user: UserModel?
    @Published var isLoggedIn: Bool = false

    init() {
        loadFromStorage()
    }

    func login(token: String, user: UserModel) {
        APIService.shared.token = token
        UserDefaults.standard.set(try? JSONEncoder().encode(user), forKey: "current_user")
        self.user = user
        self.isLoggedIn = true
    }

    func logout() {
        APIService.shared.token = nil
        UserDefaults.standard.removeObject(forKey: "current_user")
        UserDefaults.standard.removeObject(forKey: "jwt_token")
        user = nil
        isLoggedIn = false
    }

    func updateUser(_ updated: UserModel) {
        user = updated
        UserDefaults.standard.set(try? JSONEncoder().encode(updated), forKey: "current_user")
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: "current_user"),
              let saved = try? JSONDecoder().decode(UserModel.self, from: data),
              APIService.shared.token != nil else { return }
        user = saved
        isLoggedIn = true
    }
}
