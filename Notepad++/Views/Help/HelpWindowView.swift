//
//  HelpWindowView.swift
//  Notepad++
//
//  The in-app Help window: a searchable table of contents on the left and the
//  selected topic on the right. Content comes from HelpContent.
//

import SwiftUI

struct HelpWindowView: View {
    @State private var selectedTopicID: String?
    @State private var query: String = ""

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTopicID) {
                ForEach(HelpSection.allCases) { section in
                    let items = HelpContent.topics(in: section, matching: query)
                    if !items.isEmpty {
                        Section(section.rawValue) {
                            ForEach(items) { topic in
                                Text(topic.title).tag(topic.id)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 240)
        } detail: {
            if let topic = HelpContent.topic(id: selectedTopicID) {
                HelpDetailView(topic: topic)
            } else {
                HelpEmptySelectionView(hasQuery: !query.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("Notepad++ Help")
        .searchable(text: $query, placement: .sidebar, prompt: "Search help")
        .onAppear {
            if selectedTopicID == nil {
                selectedTopicID = HelpContent.topics.first?.id
            }
        }
        .onChange(of: query) { _, _ in
            // If the current selection is filtered out, move to the first remaining match so the
            // detail pane never shows a topic the sidebar no longer lists.
            let stillVisible = HelpSection.allCases
                .flatMap { HelpContent.topics(in: $0, matching: query) }
                .contains { $0.id == selectedTopicID }
            if !stillVisible {
                selectedTopicID = HelpSection.allCases
                    .flatMap { HelpContent.topics(in: $0, matching: query) }
                    .first?.id
            }
        }
        .frame(minWidth: 720, minHeight: 460)
    }
}

// MARK: - Detail

private struct HelpDetailView: View {
    let topic: HelpTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(topic.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 2)

                ForEach(Array(topic.blocks.enumerated()), id: \.offset) { _, block in
                    HelpBlockView(block: block)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .textSelection(.enabled)
        }
    }
}

private struct HelpBlockView: View {
    let block: HelpBlock

    var body: some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 8)

        case .paragraph(let text):
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

        case .bullets(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\u{2022}")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text(item)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .shortcuts(let rows):
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.action)
                            .font(.body)
                        Spacer(minLength: 24)
                        Text(row.keys)
                            .font(.body.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    if index < rows.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Empty selection

private struct HelpEmptySelectionView: View {
    let hasQuery: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: hasQuery ? "magnifyingglass" : "questionmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(hasQuery ? "No help topics match your search." : "Select a topic from the list.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
