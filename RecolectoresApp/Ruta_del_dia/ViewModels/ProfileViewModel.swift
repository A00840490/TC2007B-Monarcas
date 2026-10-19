//
//  ProfileViewModel.swift
//  Ruta_del_dia
//
//  Creado por Alumno el 19/10/2026
//

import Foundation
import Observation
import CaritasAuth

@Observable
class ProfileViewModel {

    enum ProfileState: Equatable {
        case loading
        case ready(UserProfile)
        case loggedOut(String)
        case error(String)
    }

    var state: ProfileState = .loading

    private let userService: UserService
    private let cache: ProfileCache
    private let sessionStore: SessionStore

    init(
        userService: UserService = UserService(),
        cache: ProfileCache = ProfileCache(),
        sessionStore: SessionStore = SessionStore(key: APIConfig.auth.sessionKey)
    ) {
        self.userService = userService
        self.cache = cache
        self.sessionStore = sessionStore
    }

    func loadProfile(force: Bool = false) async {
        guard let token = sessionStore.readToken() else {
            cache.clear()
            state = .loggedOut("No hay una sesión iniciada.")
            return
        }

        if !force, let profile = cache.profile(forToken: token) {
            state = .ready(profile)
            return
        }

        if case .ready = state {} else { state = .loading }

        do {
            let profile = try await userService.getProfile(token: token)
            cache.save(profile, token: token)
            state = .ready(profile)
        } catch UserServiceError.sesionInvalida {
            cache.clear()
            state = .loggedOut("Tu sesión expiró. Inicia sesión de nuevo.")
        } catch {
            print("Error al cargar el perfil: \(error)")
            state = .error("No se pudo cargar el perfil.")
        }
    }

    func logOut() {
        cache.clear()
        sessionStore.clear()
        state = .loggedOut("Cerraste sesión.")
    }
}