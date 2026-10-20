//
//  DonorAgendaPanel.swift
//  PanelAdmin
//

import SwiftUI

struct DonorAgendaPanel: View
{
    let viewModel: DonorsViewModel

    @State private var showFollowUps = false
    @State private var page = 0

    let pageSize = 5

    var body: some View
    {
        VStack(alignment: .leading, spacing: 0)
        {
            Picker("Panel", selection: $showFollowUps)
            {
                Text("Agenda").tag(false)
                Text("Por reprogramar").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)
            .padding(16)

            Divider()

            if showFollowUps
            {
                followUpList
            }
            else
            {
                agendaList
            }

            pager
        }
        .frame(maxWidth: .infinity)
        .background(.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
        .onChange(of: showFollowUps)
        {
            page = 0
        }
    }

    private var itemCount: Int
    {
        if showFollowUps
        {
            return viewModel.followUps?.items.count ?? 0
        }
        return viewModel.agenda?.items.count ?? 0
    }

    private var pageCount: Int
    {
        if itemCount == 0 { return 1 }
        return (itemCount + pageSize - 1) / pageSize
    }

    private var currentPage: Int
    {
        min(page, pageCount - 1)
    }

    private var pageAgenda: [AgendaItem]
    {
        let items = viewModel.agenda?.items ?? []
        return Array(items.dropFirst(currentPage * pageSize).prefix(pageSize))
    }

    private var pageFollowUps: [FollowUpItem]
    {
        let items = viewModel.followUps?.items ?? []
        return Array(items.dropFirst(currentPage * pageSize).prefix(pageSize))
    }

    @ViewBuilder
    private var agendaList: some View
    {
        if let error = viewModel.agendaError
        {
            errorMessage(error)
            {
                Task { await viewModel.loadAgenda() }
            }
        }
        else if let agenda = viewModel.agenda
        {
            if agenda.items.isEmpty
            {
                emptyMessage("Nada agendado en los próximos 7 días.")
            }

            ForEach(pageAgenda, id: \.key)
            { item in
                NavigationLink(value: DonorLink(id: item.donorId))
                {
                    agendaRow(item)
                }
                .buttonStyle(.plain)

                Divider()
            }
        }
        else
        {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        }
    }

    @ViewBuilder
    private var followUpList: some View
    {
        if let error = viewModel.followUpsError
        {
            errorMessage(error)
            {
                Task { await viewModel.loadFollowUps() }
            }
        }
        else if let followUps = viewModel.followUps
        {
            if followUps.items.isEmpty
            {
                emptyMessage("Nadie por reprogramar.")
            }

            ForEach(pageFollowUps, id: \.key)
            { item in
                NavigationLink(value: DonorLink(id: item.donorId))
                {
                    followUpRow(item)
                }
                .buttonStyle(.plain)

                Divider()
            }
        }
        else
        {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        }
    }

    private func agendaRow(_ item: AgendaItem) -> some View
    {
        let isCall = item.kind == "CALL"
        let color = item.isOverdue ? Constants.warningColor : Constants.primaryColor

        return row(
            icon: isCall ? "phone" : "mappin.and.ellipse",
            name: item.donorName,
            date: item.scheduledDate,
            status: item.isOverdue ? "Vencida" : nil,
            color: color
        )
    }

    private func followUpRow(_ item: FollowUpItem) -> some View
    {
        let isCall = item.kind == "CALL"

        return row(
            icon: isCall ? "phone.down" : "mappin.slash",
            name: item.donorName,
            date: item.scheduledDate,
            status: isCall ? "No contestó" : "Sin éxito",
            color: isCall ? Constants.warningColor : Constants.dangerColor
        )
    }

    private func row(icon: String, name: String, date: String, status: String?, color: Color) -> some View
    {
        HStack(spacing: 12)
        {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.14))
                .cornerRadius(8)

            Text(name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Constants.neutralColor)
                .lineLimit(1)

            Spacer()

            Text(DonorFormat.dateAndHour(date))
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 120, alignment: .trailing)

            HStack
            {
                if let status
                {
                    Text(status)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(color)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.14))
                        .clipShape(Capsule())
                }
            }
            .frame(width: 120)

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Constants.primaryColor)
                .frame(width: 34, height: 34)
                .background(Constants.primaryColor.opacity(0.12))
                .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .frame(height: DonorColumns.rowHeight)
        .contentShape(Rectangle())
    }

    private var pager: some View
    {
        HStack
        {
            Text("Página \(currentPage + 1) de \(pageCount)")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Spacer()

            pageButton("chevron.left", isDisabled: currentPage == 0)
            {
                page = currentPage - 1
            }

            pageButton("chevron.right", isDisabled: currentPage >= pageCount - 1)
            {
                page = currentPage + 1
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
    }

    private func pageButton(_ icon: String, isDisabled: Bool, action: @escaping () -> Void) -> some View
    {
        Button(action: action)
        {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 40, height: 40)
                .background(Constants.secondaryBackgroundColor)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .foregroundColor(Constants.neutralColor)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.35 : 1)
    }

    private func emptyMessage(_ text: String) -> some View
    {
        Text(text)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    private func errorMessage(_ text: String, retry: @escaping () -> Void) -> some View
    {
        VStack(spacing: 10)
        {
            Text(text)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button("Reintentar", action: retry)
                .tint(Constants.primaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
