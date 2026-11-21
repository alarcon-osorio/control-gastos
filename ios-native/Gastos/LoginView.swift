import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var nombre = ""
    @State private var modoRegistro = false
    @State private var mostrarPassword = false
    @State private var emailAnterior = ""
    @State private var passwordAnterior = ""
    @State private var emailAutofill = false
    @State private var passwordAutofill = false
    @State private var autoLoginYaSolicitado = false
    @FocusState private var campoEnfocado: Campo?

    private enum Campo { case nombre, email, password }

    private var formularioValido: Bool {
        let emailOk = email.contains("@") && email.contains(".")
        let passOk = password.count >= 6
        let nombreOk = !modoRegistro || !nombre.trimmingCharacters(in: .whitespaces).isEmpty
        return emailOk && passOk && nombreOk
    }

    var body: some View {
        ZStack {
            // Fondo con gradiente azul -> morado
            LinearGradient(
                colors: [
                    Color(red: 0.357, green: 0.525, blue: 0.898),
                    Color(red: 0.482, green: 0.184, blue: 0.969)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Burbujas decorativas
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 10)
                .offset(x: -140, y: -260)
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 260, height: 260)
                .blur(radius: 10)
                .offset(x: 160, y: 300)

            ScrollView {
                VStack(spacing: 28) {
                    encabezado
                    tarjetaFormulario
                    pieAyuda
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onChange(of: modoRegistro) { _ in
            auth.mensaje = nil
            emailAutofill = false
            passwordAutofill = false
            autoLoginYaSolicitado = false
        }
        .onChange(of: email) { nuevo in
            detectarAutofillEmail(nuevo)
        }
        .onChange(of: password) { nuevo in
            detectarAutofillPassword(nuevo)
        }
    }

    // MARK: - Encabezado
    private var encabezado: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.18))
                    .frame(width: 84, height: 84)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.white.opacity(0.35), lineWidth: 1)
                    )
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)

            Text("Gastos")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(modoRegistro ? "Crea tu cuenta para empezar" : "Bienvenido de nuevo")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    // MARK: - Tarjeta del formulario
    private var tarjetaFormulario: some View {
        VStack(spacing: 18) {
            if modoRegistro {
                campoTexto(
                    titulo: "Nombre",
                    icono: "person.fill",
                    texto: $nombre,
                    campo: .nombre,
                    contentType: .name,
                    capitalizacion: .words
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            campoTexto(
                titulo: "Email",
                icono: "envelope.fill",
                texto: $email,
                campo: .email,
                contentType: modoRegistro ? .emailAddress : .username,
                capitalizacion: .never,
                teclado: .emailAddress
            )

            campoPassword

            if let mensaje = auth.mensaje {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(mensaje)
                }
                .font(.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }

            botonPrincipal

            botonSecundario
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 24, y: 12)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: modoRegistro)
    }

    // MARK: - Campo de texto genérico
    private func campoTexto(
        titulo: String,
        icono: String,
        texto: Binding<String>,
        campo: Campo,
        contentType: UITextContentType? = nil,
        capitalizacion: TextInputAutocapitalization = .never,
        teclado: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icono)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            TextField(titulo, text: texto)
                .textContentType(contentType)
                .textInputAutocapitalization(capitalizacion)
                .keyboardType(teclado)
                .autocorrectionDisabled()
                .focused($campoEnfocado, equals: campo)
                .submitLabel(campo == .password ? .go : .next)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(campoEnfocado == campo ? Color.accentColor : .clear, lineWidth: 1.5)
        )
    }

    // MARK: - Campo de contraseña
    private var campoPassword: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Group {
                if mostrarPassword {
                    TextField("Contraseña", text: $password)
                } else {
                    SecureField("Contraseña", text: $password)
                }
            }
            .textContentType(modoRegistro ? .newPassword : .password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($campoEnfocado, equals: .password)
            .submitLabel(.go)
            .onSubmit { enviar() }

            Button {
                mostrarPassword.toggle()
            } label: {
                Image(systemName: mostrarPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(campoEnfocado == .password ? Color.accentColor : .clear, lineWidth: 1.5)
        )
    }

    // MARK: - Botón principal
    private var botonPrincipal: some View {
        Button(action: enviar) {
            ZStack {
                if auth.cargando {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(modoRegistro ? "Crear cuenta" : "Iniciar sesión")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.357, green: 0.525, blue: 0.898),
                                Color(red: 0.482, green: 0.184, blue: 0.969)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .opacity(formularioValido && !auth.cargando ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!formularioValido || auth.cargando)
    }

    // MARK: - Botón secundario
    private var botonSecundario: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                modoRegistro.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Text(modoRegistro ? "¿Ya tienes cuenta?" : "¿No tienes cuenta?")
                    .foregroundStyle(.secondary)
                Text(modoRegistro ? "Inicia sesión" : "Regístrate")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pie de ayuda
    private var pieAyuda: some View {
        Text("Al continuar aceptas los términos y la política de privacidad.")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
    }

    // MARK: - Autofill
    private func detectarAutofillEmail(_ nuevo: String) {
        let delta = nuevo.count - emailAnterior.count
        emailAnterior = nuevo
        if delta > 3 && nuevo.contains("@") {
            emailAutofill = true
        } else if delta == 1 {
            emailAutofill = false
        }
        evaluarAutoLogin()
    }

    private func detectarAutofillPassword(_ nuevo: String) {
        let anterior = passwordAnterior
        let delta = nuevo.count - anterior.count
        passwordAnterior = nuevo

        let esAutofill = (anterior.isEmpty && nuevo.count >= 6) || delta > 1
        if esAutofill {
            passwordAutofill = true
        } else if delta == 1 {
            passwordAutofill = false
        }

        evaluarAutoLogin()
    }

    private func evaluarAutoLogin() {
        guard emailAutofill,
              passwordAutofill,
              !modoRegistro,
              formularioValido,
              !auth.cargando,
              !autoLoginYaSolicitado,
              !auth.autenticado else { return }

        emailAutofill = false
        passwordAutofill = false
        autoLoginYaSolicitado = true
        enviar()
    }

    // MARK: - Acción
    private func enviar() {
        guard formularioValido, !auth.cargando else { return }
        campoEnfocado = nil
        auth.mensaje = nil
        Task {
            if modoRegistro {
                _ = await auth.registrar(nombre: nombre, email: email, password: password)
            } else {
                _ = await auth.login(email: email, password: password)
            }
        }
    }
}
