//
//  WelcomeView.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var selectedTab: String
    var onLogout: () -> Void

    let service = CallService()

    @State private var calls: [Call] = []
    @State private var name = ""
    @State private var errorMessage = ""

    func count(state: String) -> Int {
        var total = 0
        for call in calls {
            if call.state == state {
                total += 1
            }
        }
        return total
    }

    func loadData() {
        Task {
            do {
                let profile = try await service.getProfile()
                name = profile.name
                calls = try await service.getCalls()
                errorMessage = ""
            } catch {
                print("Error: \(error)")
                if service.sessionExpired {
                    onLogout()
                }
                errorMessage = "No se pudieron cargar las llamadas."
            }
        }
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    onLogout()
                } label: {
                    Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .tint(Constants.secondaryColor)
            }
            .padding(20)

            Spacer()

            Image(systemName: "cross.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Constants.secondaryColor)
                .cornerRadius(10)
                .padding(.bottom, 22)

            Text(todayText())
                .font(.system(size: 15))
                .foregroundColor(Constants.grayTextColor)
                .padding(.bottom, 10)

            Text("Buenos días, \(name)")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Constants.neutralColor)
                .padding(.bottom, 30)

            HStack {
                VStack {
                    Text("\(calls.count)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Constants.neutralColor)
                    Text("Asignadas")
                        .font(.system(size: 15))
                        .foregroundColor(Constants.grayTextColor)
                }
                .padding(.vertical, 16)
                .frame(width: 132)
                .background(Constants.grayBoxColor)
                .cornerRadius(10)
                VStack {
                    Text("\(count(state: "Próxima"))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Constants.neutralColor)
                    Text("Próximas")
                        .font(.system(size: 15))
                        .foregroundColor(Constants.grayTextColor)
                }
                .padding(.vertical, 16)
                .frame(width: 132)
                .background(Constants.grayBoxColor)
                .cornerRadius(10)
                VStack {
                    Text("\(count(state: "Vencida"))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Constants.neutralColor)
                    Text("Vencidas")
                        .font(.system(size: 15))
                        .foregroundColor(Constants.grayTextColor)
                }
                .padding(.vertical, 16)
                .frame(width: 132)
                .background(Constants.grayBoxColor)
                .cornerRadius(10)
            }
            .padding(.bottom, 34)

            if errorMessage != "" {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Constants.redColor)
                    .padding(.bottom, 20)
            }

            Button {
                selectedTab = "Turno"
            } label: {
                Text("Iniciar turno")
                    .frame(width: 240)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.secondaryColor)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.secondaryBackgroundColor)
        .onAppear {
            loadData()
        }
    }
}

#Preview {
    WelcomeView(selectedTab: .constant("Inicio"), onLogout: {})
}
