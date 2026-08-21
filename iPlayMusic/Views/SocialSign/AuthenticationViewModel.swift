//
//  AuthenticationViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 31/07/26.
//

import Firebase
import GoogleSignIn
import AuthenticationServices
import FirebaseAuth
import Combine

enum SignInType: String, CaseIterable {
    case apple, google, email, anonymous, unknown
    
    var title: String {
        switch self {
        case .apple: return "apple.com"
        case .google: return "google.com"
        case .email: return "Email / Password"
        case .anonymous: return "anonymous"
        case .unknown: return "unknown"
        }
    }
}

enum LoginOption {
    case signInWithApple
    case signInWithGoogle
    case emailAndPassword(email: String, password: String)
}


class AuthenticationViewModel: NSObject, ObservableObject {
    
    var appState = StateManager.shared
    
    enum SignInState {
        case signedIn
        case signedOut
    }
    
    @Published var state: SignInState = .signedOut
    @Published var errorMessage: String = ""
    @Published var signInMethod: SignInType = .unknown
    @Published var restoreGoogleSignIn: Bool = false
    @Published var isLoading: Bool = false
    fileprivate var currentNonce: String?
    
    @Published var appleSingInChanged: Bool = false
    
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
        
    override init() {
        super.init()
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            restoreGoogleSignIn = true
        }
    }
    
    /// Master login function that will handle multiple login types depending on what the user chooses
    func login(with loginOption: LoginOption) async {
        switch loginOption {
        case .signInWithApple:
            signInWithApple()
        case let .emailAndPassword(email, password):
            await signInWithEmail(email: email, password: password)
        case .signInWithGoogle:
            await signInWithGoogle()
        }
    }
    
    /**
     Sign in with email and password with Firebase Authentication.
     - Parameter email
     - Parameter password
     - Returns: Completion handler.
     */
    @MainActor
    func signInWithEmail(email: String, password: String) async {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            self.state = .signedIn
            appState.isLoggedIn = true
            self.signInMethod = .email
        }
        catch {
            print(error.localizedDescription)
            self.errorMessage = error.localizedDescription
        }
    }
    
    /**
     Sign up with email and password with Firebase Authentication. Also signs in the user once the account is created.
     - Parameter email
     - Parameter password
     - Returns: Completion handler.
     */
    @MainActor
    func signUp(email: String, password: String) async {
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            self.state = .signedIn
            appState.isLoggedIn = true
            self.signInMethod = .email
        }
        catch {
            print(error.localizedDescription)
            self.errorMessage = error.localizedDescription
        }
    }
    
    /**
     Sign in the user with Firebase Authentication via Sign In with Google. Requires a Google account. Also handles the restoration of a user's session.
     - Parameter email
     - Parameter password
     - Returns: Completion handler.
     */
    @MainActor
    func signInWithGoogle() async {
        
        if !appState.isLoggedIn {
            GIDSignIn.sharedInstance.signOut()
        }
        
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            do {
                let result = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                print("Restoring previous session")
                await authenticateGoogleUser(for: result)
            }
            catch {
                print(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        } else {
            do {
                
#if os(iOS)
                guard let rootViewController = UIApplication.topViewController() else { return }
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
                GlobalLoader.shared.show()
                
#endif
                
#if os(macOS)
                guard let window = NSApplication.shared.windows.first else { return }
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
#endif
                
                
                guard let idToken = result.user.idToken?.tokenString else { return }
                
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
                
                try await handleGoogleSignIn(credential: credential)
            }
            catch {
                print(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Function that pairs with signInWithGoogle() and completes the authentication of a Google user.
    @MainActor
    func authenticateGoogleUser(for user: GIDGoogleUser?) async {
        guard let idToken = user?.idToken?.tokenString else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user?.accessToken.tokenString ?? "")
        
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
            self.state = .signedIn
            appState.isLoggedIn = true
            if let user = Auth.auth().currentUser {
                appState.uid = user.uid
            }
            self.signInMethod = .google
            updateAppState(with: authResult.user)
        }
        catch {
            print(error.localizedDescription)
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Function that signs in a user via the Sign in with Apple configuration
    @MainActor
    func signInWithAppleHandler(credential: OAuthCredential)  {
        Task {
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                do {
                    let linkedAuthResult = try await currentUser.link(with: credential)
                    updateAppState(with: linkedAuthResult.user)
                    signInMethod = .apple
                    appleSingInChanged.toggle()
                } catch let error as NSError  {
                    if error.code == AuthErrorCode.credentialAlreadyInUse.rawValue || error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        print("Error 17025: Account already exists. Signing in instead...")
                        if let updatedCredential =
                            error.userInfo[AuthErrorUserInfoUpdatedCredentialKey]
                            as? AuthCredential {
                            let authResult = try await Auth.auth().signIn(with: updatedCredential)
                            updateAppState(with: authResult.user)
                            signInMethod = .apple
                            appleSingInChanged.toggle()
                        }
                    } else {
                        GlobalLoader.shared.hide()
                        presentAlert(title: "Sign in failed", message: error.localizedDescription)
                        throw error
                    }
                }
            } else {
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)
                    updateAppState(with: authResult.user)
                    signInMethod = .apple
                    appleSingInChanged.toggle()
                } catch {
                    GlobalLoader.shared.hide()
                    presentAlert(title: "Sign in failed", message: error.localizedDescription)
                    throw error
                }
            }
        }
    }
    
    func handleGoogleSignIn(credential: AuthCredential) async throws {
        if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
            do {
                let linkedAuthResult = try await currentUser.link(with: credential)
                updateAppState(with: linkedAuthResult.user)
                signInMethod = .google
            } catch let error as NSError  {
                if error.code == AuthErrorCode.credentialAlreadyInUse.rawValue || error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    print("Error 17025: Account already exists. Signing in instead...")
                    let authResult = try await Auth.auth().signIn(with: credential)
                    updateAppState(with: authResult.user)
                    signInMethod = .google
                } else {
                    GlobalLoader.shared.hide()
                    presentAlert(title: "Sign in failed", message: error.localizedDescription)
                    throw error
                }
            }
        } else {
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                updateAppState(with: authResult.user)
                signInMethod = .google
            } catch {
                GlobalLoader.shared.hide()
                presentAlert(title: "Sign in failed", message: error.localizedDescription)
                throw error
            }
        }
    }
    
    /// signIn With Anonymously
    func signInWithAnonymously() async throws {
        do {
            let authResult = try await Auth.auth().signInAnonymously()
            updateAppState(with: authResult.user)
        } catch {
            presentAlert(title: "Sign in failed", message: error.localizedDescription)
            throw error
        }
    }
    
    private func updateAppState(with user: User) {
        state = .signedIn
        appState.isLoggedIn = true
        appState.isAnonymous = user.isAnonymous
        appState.uid = user.uid
    }
    
    /// Alert Method
    @MainActor
    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    /// Function that will user info
    func getCurrentUser() async -> User? {
        Auth.auth().currentUser
    }
    
    /// Function that will sign out the user for all authentication methods
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.state = .signedOut
            restoreGoogleSignIn = false
            appState.isLoggedIn = false
            self.appState.isAnonymous = false
            appState.uid.removeAll()
#if os(macOS)
            WindowManager.shared.closeWindow(id: .settings)
#endif
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteAccount() async throws -> User? {
        let user = Auth.auth().currentUser
        do {
            try await user?.delete()
            self.state = .signedOut
            self.restoreGoogleSignIn = false
            self.appState.isLoggedIn = false
            self.appState.isAnonymous = false
            self.appState.uid.removeAll()
            return user
        } catch {
            throw error
        }
    }
}

/// Extension that contains functions necessary for Sign in with Apple via Google Firebase
extension AuthenticationViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @MainActor
    func signInWithApple() {
        let nonce = String.randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce.sha256
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//        var window: UIWindow?
//        DispatchQueue.main.sync {
//            let scenes = UIApplication.shared.connectedScenes.first as? UIWindowScene
//            window = scenes?.windows.first
//        }
#if os(iOS)
        return UIApplication.topViewController()?.view.window ?? UIWindow()
#elseif os(macOS)
        return NSApplication.shared.windows.first ?? NSWindow()
        
#endif
//        return window ?? UIWindow()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                self.appleSingInChanged.toggle()
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                self.appleSingInChanged.toggle()
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                self.appleSingInChanged.toggle()
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            //             Initialize a Firebase credential.
            let credential = OAuthProvider.credential(providerID: .apple, idToken: idTokenString, rawNonce: nonce)
            
            //             Sign in with Firebase.
            self.signInWithAppleHandler(credential: credential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.appleSingInChanged.toggle()
        GlobalLoader.shared.hide()
        print("Sign in with Apple error: \(error)")
    }
}
