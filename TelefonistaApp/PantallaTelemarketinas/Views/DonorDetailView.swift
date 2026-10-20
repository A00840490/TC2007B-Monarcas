//
//  DonorDetailView.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import SwiftUI

struct DonorDetailView: View {
    var call: Call

    let service = CallService()

    @State private var detail: DonorDetail? = nil
    @State private var history: [HistoryItem] = []
    @State private var loadFailed = false

    @State private var newNote = ""
    @State private var showEmptyError = false
    @State private var noteAdded = false

    func loadDetail() {
        loadFailed = false
        Task {
            do {
                detail = try await service.getDonor(id: call.donor.id)
                history = detail?.history ?? []
            } catch {
                print("Error: \(error)")
                loadFailed = true
            }
        }
    }

    func addNote() {
        if newNote.isEmpty {
            showEmptyError = true
            noteAdded = false
            return
        }

        Task {
            do {
                let item = try await service.addNote(donorId: call.donor.id, note: newNote)
                history.insert(item, at: 0)
                newNote = ""
                noteAdded = true
            } catch {
                print("Error: \(error)")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if loadFailed {
                    Text("No pudimos cargar el detalle")
                        .foregroundColor(Constants.redColor)
                        .padding(40)
                    Button {
                        loadDetail()
                    } label: {
                        Text("Reintentar")
                            .frame(width: 240)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Constants.secondaryColor)
                    .frame(maxWidth: .infinity)
                } else if let detail = detail {

                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(detail.nickname == "" ? detail.name : detail.nickname)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Constants.neutralColor)
                            Text(detail.phone)
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(Constants.secondaryColor)
                            Text(detail.name)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Constants.neutralColor)
                            HStack {
                                Text(riskText(detail.risk))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(riskColor(detail.risk))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(riskColor(detail.risk).opacity(0.15))
                                    .cornerRadius(16)
                                if detail.campaign != "" {
                                    Text("Campaña: \(detail.campaign)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Constants.secondaryColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Constants.secondaryColor.opacity(0.15))
                                        .cornerRadius(16)
                                }
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            if detail.pledge > 0 {
                                Text("Monto acordado")
                                    .font(.system(size: 15))
                                    .foregroundColor(Constants.grayTextColor)
                                Text("$\(Int(detail.pledge))")
                                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                                    .foregroundColor(Constants.moneyColor)
                                Text("MXN al mes")
                                    .font(.system(size: 15))
                                    .foregroundColor(Constants.grayTextColor)
                            } else {
                                Text("Sin monto acordado")
                                    .font(.system(size: 15))
                                    .foregroundColor(Constants.grayTextColor)
                            }
                        }
                    }
                    .padding(20)
                    .background(Constants.cardColor)
                    .cornerRadius(10)

                    VStack(alignment: .leading) {
                        Text("Datos de contacto")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Constants.neutralColor)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Teléfono de casa / oficina")
                                        .font(.system(size: 15))
                                        .foregroundColor(Constants.grayTextColor)
                                    Text(detail.officePhone)
                                        .foregroundColor(Constants.neutralColor)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                VStack(alignment: .leading) {
                                    Text("Email")
                                        .font(.system(size: 15))
                                        .foregroundColor(Constants.grayTextColor)
                                    Text(detail.email)
                                        .foregroundColor(Constants.neutralColor)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Divider()

                            VStack(alignment: .leading) {
                                Text("Dirección")
                                    .font(.system(size: 15))
                                    .foregroundColor(Constants.grayTextColor)
                                Text(detail.address)
                                    .foregroundColor(Constants.neutralColor)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Constants.cardColor)
                        .cornerRadius(10)
                    }

                    VStack(alignment: .leading) {
                        Text("Objetivo de la llamada")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Constants.neutralColor)
                        Text(call.goal)
                            .foregroundColor(Constants.neutralColor)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Constants.cardColor)
                            .cornerRadius(10)
                    }

                    VStack(alignment: .leading) {
                        Text("Historial")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Constants.neutralColor)

                        VStack(alignment: .leading, spacing: 0) {
                            if history.isEmpty {
                                Text("Aún no hay registros")
                                    .foregroundColor(Constants.grayTextColor)
                                    .padding(40)
                            }
                            ForEach(history) { item in
                                HistoryRowView(item: item)
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Constants.cardColor)
                        .cornerRadius(10)
                    }

                    VStack(alignment: .leading) {
                        Text("Bitácora")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Constants.neutralColor)

                        TextField("Escribe una nota", text: $newNote)
                            .padding(20)
                            .background(Constants.cardColor)
                            .cornerRadius(10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(showEmptyError ? Constants.redColor : Color.clear, lineWidth: 2)
                            }
                            .onChange(of: newNote) { oldValue, newValue in
                                showEmptyError = false
                            }

                        if showEmptyError {
                            Label("Escribe una nota antes de agregarla.", systemImage: "exclamationmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(Constants.redColor)
                        }

                        Button {
                            addNote()
                        } label: {
                            Text("Agregar nota")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Constants.secondaryColor)

                        if noteAdded {
                            Label("Nota agregada a la bitácora.", systemImage: "checkmark.circle.fill")
                                .foregroundColor(Constants.greenColor)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Constants.greenColor.opacity(0.15))
                                .cornerRadius(10)
                        }
                    }

                } else {
                    ProgressView("Cargando información del donante…")
                        .frame(maxWidth: .infinity)
                        .padding(40)
                }
            }
            .padding(20)
        }
        .background(Constants.secondaryBackgroundColor)
        .navigationTitle("Detalle del donante")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDetail()
        }
    }
}

#Preview {
    let previewDonor = CallDonor(id: 1, name: "Roberto Gómez Fernández", nickname: "Don Roberto",
                                 phone: "81 2234 5567", campaign: "Padrinazgo mensual",
                                 risk: "MEDIUM", pledge: 300)
    let previewCall = Call(id: 1, time: "", hour: "10:35", status: "PENDING",
                           state: "Próxima", result: "", goal: "Confirmar renovación",
                           donor: previewDonor)
    NavigationStack {
        DonorDetailView(call: previewCall)
    }
}
