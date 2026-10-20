//
//  DonorDetailView.swift
//  PanelAdmin
//

import SwiftUI

struct DonorDetailView: View
{
    let donorId: Int
    let months: Int
    
    @State private var viewModel = DonorDetailViewModel()
    
    var body: some View
    {
        Group
        {
            switch viewModel.state
            {
                case .loading:
                    ProgressView()
                
                case .loggedOut(let message):
                    ContentUnavailableView(
                        "Sin sesión",
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text(message)
                    )
                
                case .error(let message):
                    ContentUnavailableView
                    {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Reintentar")
                        {
                            Task { await viewModel.load(id: donorId, months: months) }
                        }
                    }
                
                case .ready(let donor):
                    content(donor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.secondaryBackgroundColor)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .task
        {
            await viewModel.load(id: donorId, months: months)
        }
    }
    
    private func content(_ donor: DonorDetail) -> some View
    {
        ScrollView
        {
            VStack(alignment: .leading, spacing: 24)
            {
                HStack(spacing: 14)
                {
                    Text(donor.name)
                        .font(.system(size: 34))
                        .bold()
                        .foregroundColor(Constants.neutralColor)
                    
                    RiskPill(riskStatus: donor.riskStatus, prefix: "Riesgo ")
                    
                    chip(
                        donor.isActive ? "Activo" : "Inactivo",
                        color: donor.isActive ? Constants.primaryColor : Constants.warningColor
                    )
                }
                
                Divider()
                
                HStack(alignment: .top, spacing: 32)
                {
                    VStack(alignment: .leading, spacing: 24)
                    {
                        contactSection(donor)
                        historySection(donor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 24)
                    {
                        upcomingSection(donor.upcoming)
                        pledgeSection(donor.pledge)
                        activitySection(donor.activity)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
        }
    }
    
    private func contactSection(_ donor: DonorDetail) -> some View
    {
        VStack(alignment: .leading, spacing: 10)
        {
            sectionTitle("Contacto")
            infoRow("Teléfono", donor.phone.isEmpty ? "—" : donor.phone)
            infoRow("Dirección", donor.address.isEmpty ? "—" : donor.address)
        }
    }
    
    private func historySection(_ donor: DonorDetail) -> some View
    {
        VStack(alignment: .leading, spacing: 10)
        {
            sectionTitle("Historial")
            
            HStack(spacing: 12)
            {
                statCard(DonorFormat.money(donor.stats.lifetimeTotal), label: "Total donado")
                statCard(DonorFormat.money(donor.stats.windowTotal), label: "En los últimos \(donor.months) meses")
            }
            
            HStack(spacing: 12)
            {
                statCard("\(donor.stats.donationCount)", label: "Donaciones")
                statCard(DonorFormat.date(donor.stats.firstDonationDate), label: "Primera donación")
            }
        }
    }
    
    private func upcomingSection(_ upcoming: UpcomingContact?) -> some View
    {
        VStack(alignment: .leading, spacing: 10)
        {
            sectionTitle("Próximo contacto")
            
            if let upcoming
            {
                let isCall = upcoming.kind == "CALL"
                infoRow("Tipo", isCall ? DonorFormat.callType(upcoming.type) : "Recolección")
                infoRow(isCall ? "Telefonista" : "Recolector", upcoming.userName)
                infoRow("Fecha", DonorFormat.dateAndHour(upcoming.date))
            }
            else
            {
                Text("Nada agendado.")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func pledgeSection(_ pledge: DonorPledge?) -> some View
    {
        VStack(alignment: .leading, spacing: 10)
        {
            sectionTitle("Promesa mensual")
            
            if let pledge
            {
                infoRow("Estado", DonorFormat.pledgeStatus(pledge.status))
                infoRow("Monto", "\(DonorFormat.money(pledge.amount)) al mes")
                infoRow("Forma de pago", DonorFormat.paymentMethod(pledge.paymentMethod))
                infoRow("Campaña", pledge.campaign ?? "—")
                infoRow("Desde", DonorFormat.date(pledge.startDate))
                infoRow("Próxima cuota", pledge.status == "ACTIVE" ? DonorFormat.date(pledge.nextInstallmentDate) : "—")
                infoRow("Telefonista", pledge.telefonistaName)
                infoRow("Recolector", pledge.recolectorName)
            }
            else
            {
                Text("No tiene promesa mensual.")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func activitySection(_ activity: [DonorActivity]) -> some View
    {
        VStack(alignment: .leading, spacing: 10)
        {
            sectionTitle("Actividad reciente")
            
            if activity.isEmpty
            {
                Text("Sin actividad todavía.")
                    .foregroundColor(.gray)
            }
            
            ForEach(activity.prefix(5), id: \.key)
            { item in
                activityRow(item)
            }
        }
    }
    
    private func sectionTitle(_ title: String) -> some View
    {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .kerning(1)
            .foregroundColor(.gray)
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View
    {
        HStack(alignment: .top, spacing: 12)
        {
            Text(label)
                .foregroundColor(.gray)
                .frame(width: 150, alignment: .leading)
            
            Text(value)
                .foregroundColor(Constants.neutralColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 16))
    }
    
    private func statCard(_ value: String, label: String) -> some View
    {
        VStack(alignment: .leading, spacing: 2)
        {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(Constants.neutralColor)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .cornerRadius(12)
    }
    
    private func chip(_ text: String, color: Color) -> some View
    {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundColor(color)
            .background(color.opacity(0.14))
            .cornerRadius(8)
    }
    
    private func activityRow(_ item: DonorActivity) -> some View
    {
        let isPending = item.status == "PENDING"
        var icon = "mappin.and.ellipse"
        var color = isPending ? Constants.primaryColor : Color.gray
        
        if item.kind == "DONATION"
        {
            icon = "dollarsign"
            color = Constants.moneyColor
        }
        else if item.kind == "CALL"
        {
            icon = "phone"
        }
        
        return HStack(alignment: .top, spacing: 12)
        {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.14))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2)
            {
                Text(DonorFormat.activityTitle(item))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Constants.neutralColor)
                
                Text(DonorFormat.activityDetail(item))
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(DonorFormat.shortDate(item.date))
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack
    {
        DonorDetailView(donorId: 1, months: 6)
    }
}
