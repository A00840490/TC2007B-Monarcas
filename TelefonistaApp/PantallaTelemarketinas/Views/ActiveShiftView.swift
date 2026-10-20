//
//  ActiveShiftView.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import SwiftUI

struct ActiveShiftView: View {
    let service = CallService()

    @State private var calls: [Call] = []
    @State private var pending: [Call] = []
    @State private var i = 0
    @State private var loading = true
    @State private var errorMessage = ""

    @State private var callStarted = false
    @State private var startTime = Date()

    @State private var result = "NO_ANSWER"
    @State private var amountText = ""
    @State private var collectionDate = Date()
    @State private var rescheduleDate = Date()
    @State private var notes = ""
    @State private var showSavedAlert = false

    @State private var showOverdue = false
    @State private var showUpcoming = false
    @State private var showFinished = false

    func filteredCalls() -> [Call] {
        if showOverdue == false && showUpcoming == false && showFinished == false {
            return calls
        }
        var list: [Call] = []
        for call in calls {
            if showOverdue && call.state == "Vencida" {
                list.append(call)
            } else if showUpcoming && call.state == "Próxima" {
                list.append(call)
            } else if showFinished && call.state == "Terminada" {
                list.append(call)
            }
        }
        return list
    }

    func count(state: String) -> Int {
        var total = 0
        for call in calls {
            if call.state == state {
                total += 1
            }
        }
        return total
    }

    func loadCalls() {
        Task {
            do {
                calls = try await service.getCalls()
                pending = []
                for call in calls {
                    if call.status == "PENDING" {
                        pending.append(call)
                    }
                }
                if i >= pending.count {
                    i = 0
                }
                errorMessage = ""
            } catch {
                print("Error: \(error)")
                errorMessage = "No se pudieron cargar las llamadas."
            }
            loading = false
        }
    }

    func saveResult() {
        var realTime = Date()
        if callStarted {
            realTime = startTime
        }

        var acceptedDate = ""
        if result == "ACCEPTED" {
            acceptedDate = apiDate(collectionDate)
        }

        var newDate = ""
        if result == "RESCHEDULED" {
            newDate = apiDate(rescheduleDate)
        }

        let body = CallResultRequest(
            result: result,
            notes: notes,
            calledAt: apiDate(realTime),
            amount: Double(amountText) ?? 0,
            collectionDate: acceptedDate,
            rescheduleDate: newDate
        )

        Task {
            do {
                try await service.saveResult(callId: pending[i].id, result: body)
                callStarted = false
                result = "NO_ANSWER"
                amountText = ""
                notes = ""
                showSavedAlert = true
                loadCalls()
            } catch {
                print("Error: \(error)")
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if loading {
                        ProgressView("Cargando llamadas…")
                            .frame(maxWidth: .infinity)
                            .padding(40)
                    } else if errorMessage != "" {
                        Text(errorMessage)
                            .foregroundColor(Constants.redColor)
                            .padding(40)
                    } else if calls.isEmpty {
                        Text("No tienes llamadas para hoy")
                            .foregroundColor(Constants.grayTextColor)
                            .padding(40)
                    } else if pending.isEmpty {
                        Text("Completaste todas tus llamadas de hoy")
                            .foregroundColor(Constants.greenColor)
                            .padding(40)
                    } else {
                        currentCallCard

                        if callStarted {
                            recordCard
                        }

                    }
                }
                .padding(20)
            }
            .frame(maxWidth: 540)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cola del turno")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Constants.neutralColor)

                    HStack {
                        FilterButton(title: "Vencidas", isOn: $showOverdue)
                        FilterButton(title: "Próximas", isOn: $showUpcoming)
                        FilterButton(title: "Terminadas", isOn: $showFinished)
                    }

                    VStack(spacing: 0) {
                        if filteredCalls().isEmpty {
                            Text("No hay llamadas con este filtro")
                                .foregroundColor(Constants.grayTextColor)
                                .padding(40)
                        }
                        ForEach(filteredCalls()) { call in
                            NavigationLink {
                                DonorDetailView(call: call)
                            } label: {
                                CallRowView(call: call)
                            }
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Constants.cardColor)
                    .cornerRadius(10)
                }
                .padding(20)
            }
        }
        .background(Constants.secondaryBackgroundColor)
        .onAppear {
            loadCalls()
        }
        .alert("Resultado de la llamada guardado", isPresented: $showSavedAlert) {
            Button("OK") {}
        }
    }

    var currentCallCard: some View {
        VStack(alignment: .leading) {
            Text("Llamada actual")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Constants.neutralColor)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Llamada \(i + 1) de \(pending.count) pendientes")
                        .foregroundColor(Constants.neutralColor)
                    Spacer()
                    Button {
                        if i > 0 {
                            i -= 1
                            callStarted = false
                            result = "NO_ANSWER"
                            amountText = ""
                            notes = ""
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 44, height: 44)
                            .background(Constants.grayBoxColor)
                            .clipShape(Circle())
                    }
                    Button {
                        if i < pending.count - 1 {
                            i += 1
                            callStarted = false
                            result = "NO_ANSWER"
                            amountText = ""
                            notes = ""
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 44, height: 44)
                            .background(Constants.grayBoxColor)
                            .clipShape(Circle())
                    }
                }
                .tint(Constants.secondaryColor)

                ProgressView(value: Double(count(state: "Terminada")), total: Double(calls.count))
                    .tint(Constants.primaryColor)
                Text("\(count(state: "Terminada")) de \(calls.count) completadas")
                    .font(.system(size: 15))
                    .foregroundColor(Constants.grayTextColor)

                Divider()

                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(pending[i].donor.nickname == "" ? pending[i].donor.name : pending[i].donor.nickname)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Constants.neutralColor)
                        Text(pending[i].donor.phone)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(Constants.secondaryColor)
                        Text(pending[i].donor.name)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Constants.neutralColor)
                        Text(riskText(pending[i].donor.risk))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(riskColor(pending[i].donor.risk))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(riskColor(pending[i].donor.risk).opacity(0.15))
                            .cornerRadius(16)
                        if pending[i].donor.campaign != "" {
                            Text("Campaña: \(pending[i].donor.campaign)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Constants.secondaryColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Constants.secondaryColor.opacity(0.15))
                                .cornerRadius(16)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        if pending[i].donor.pledge > 0 {
                            Text("Monto acordado")
                                .font(.system(size: 15))
                                .foregroundColor(Constants.grayTextColor)
                            Text("$\(Int(pending[i].donor.pledge))")
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

                Divider()

                Text("Objetivo de la llamada")
                    .font(.system(size: 15))
                    .foregroundColor(Constants.grayTextColor)
                Text(pending[i].goal)
                    .foregroundColor(Constants.neutralColor)

                HStack {
                    Button {
                        startTime = Date()
                        callStarted = true
                    } label: {
                        Text(callStarted ? "Llamada en curso" : "Comenzar llamada")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(callStarted ? Constants.greenColor : Constants.secondaryColor)

                    NavigationLink {
                        DonorDetailView(call: pending[i])
                    } label: {
                        Text("Ver detalle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(Constants.secondaryColor)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Constants.cardColor)
            .cornerRadius(10)
        }
    }

    var recordCard: some View {
        VStack(alignment: .leading) {
            Text("Registro de la llamada")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Constants.neutralColor)

            VStack(alignment: .leading, spacing: 24) {
                Picker("Resultado", selection: $result) {
                    Text("No contestó").tag("NO_ANSWER")
                    Text("Rechazó").tag("DECLINED")
                    Text("Aceptó").tag("ACCEPTED")
                    Text("Reagendar").tag("RESCHEDULED")
                }
                .pickerStyle(.segmented)

                if result == "ACCEPTED" {
                    HStack {
                        Text("Monto")
                        TextField("$0", text: $amountText)
                        Text("MXN")
                            .foregroundColor(Constants.grayTextColor)
                    }
                    DatePicker("Fecha de recolección", selection: $collectionDate,
                               in: Date()..., displayedComponents: .date)
                    DatePicker("Hora de recolección", selection: $collectionDate,
                               displayedComponents: .hourAndMinute)
                }

                if result == "RESCHEDULED" {
                    DatePicker("Reagendar para", selection: $rescheduleDate,
                               in: Date()..., displayedComponents: .date)
                }

                TextField("Nota de la llamada", text: $notes)
                    .padding(.top, 20)
            }
            .foregroundColor(Constants.neutralColor)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Constants.cardColor)
            .cornerRadius(10)

            Text("\(notes.count)/1000")
                .font(.system(size: 15))
                .foregroundColor(Constants.grayTextColor)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Button {
                saveResult()
            } label: {
                Text("Guardar resultado")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.secondaryColor)
        }
    }
}

#Preview {
    NavigationStack {
        ActiveShiftView()
    }
}
