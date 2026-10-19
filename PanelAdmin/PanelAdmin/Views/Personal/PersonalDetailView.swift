//
//  PersonalDetailView.swift
//  PanelAdmin
//

import SwiftUI

/// One figure of the person's performance.
struct PersonalStat: Identifiable
{
    let label: String
    let value: String
    var id: String { label }
}

/// A telefonista's or recolector's screen. It opens from the list of Personal
/// with the NavigationStack's push; "‹ Personal" goes back. From here the admin
/// schedules a call (telefonista) or a collection (recolector) for a donor.
struct PersonalDetailView: View
{
    let role: PersonalViewModel.Role
    let staffId: Int
    let name: String
    /// Window chosen in the list.
    let months: Int
    let stats: [PersonalStat]
    let rate: Int
    let rateColor: Color
    
    /// Call or collection being scheduled in a sheet.
    @State private var scheduling: ScheduleKind?
    /// Shown after something was scheduled.
    @State private var confirmation: String?
    
    private var kind: ScheduleKind
    {
        role == .telefonistas ? .call : .collection
    }
    
    var body: some View
    {
        ScrollView
        {
            VStack(alignment: .leading, spacing: 24)
            {
                HStack(spacing: 14)
                {
                    Text(name)
                        .font(.system(size: 34))
                        .bold()
                        .foregroundColor(Constants.neutralColor)
                    
                    RatePill(
                        rate: rate,
                        color: rateColor,
                        prefix: role == .telefonistas ? "Confirmación " : "Éxito "
                    )
                    
                    chip(
                        role == .telefonistas ? "Telefonista" : "Recolector",
                        color: Constants.primaryColor
                    )
                    
                    Spacer()
                    
                    Button
                    {
                        confirmation = nil
                        scheduling = kind
                    } label: {
                        Label(
                            kind.title,
                            systemImage: role == .telefonistas ? "phone" : "mappin.and.ellipse"
                        )
                        .font(.system(size: 17, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Constants.primaryColor)
                }
                
                Divider()
                
                if let confirmation
                {
                    Label(confirmation, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Constants.moneyColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Constants.moneyColor.opacity(0.12))
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 10)
                {
                    Text("DESEMPEÑO · ÚLTIMOS \(months) MESES")
                        .font(.system(size: 13, weight: .semibold))
                        .kerning(1)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12)
                    {
                        ForEach(stats)
                        { stat in
                            statCard(stat)
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.secondaryBackgroundColor)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $scheduling)
        { kind in
            ScheduleContactSheet(kind: kind, staffId: staffId, staffName: name, months: months)
            {
                confirmation = kind == .call ? "Llamada agendada." : "Recolección agendada."
            }
        }
    }
    
    private func statCard(_ stat: PersonalStat) -> some View
    {
        VStack(alignment: .leading, spacing: 2)
        {
            Text(stat.value)
                .font(.system(size: 20, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(Constants.neutralColor)
            
            Text(stat.label)
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
}

#Preview {
    NavigationStack
    {
        PersonalDetailView(
            role: .telefonistas,
            staffId: 1,
            name: "María Benavides Gómez",
            months: 3,
            stats: [
                PersonalStat(label: "Llamadas realizadas", value: "72"),
                PersonalStat(label: "Confirmadas", value: "55"),
                PersonalStat(label: "Tasa de confirmación", value: "76%")
            ],
            rate: 76,
            rateColor: Constants.moneyColor
        )
    }
}
