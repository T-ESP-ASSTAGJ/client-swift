//
//  ReportPostSheetView.swift
//  jamly
//
//  Created by REVERSS on 16/04/2026.
//

import SwiftUI

struct ReportPostSheetView: View {
    let post: Post
    @Binding var isReported: Bool

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PostViewModel()

    @State private var selectedReason: ReportReason?
    @State private var message: String = ""
    @State private var showingSuccessBanner = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                postHeader

                Divider()
                    .padding(.top, 20)

                reportForm
            }
            .navigationTitle("Report post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Label("close", systemImage: "xmark")
                    }
                }
            }
            .overlay(alignment: .top) {
                if showingSuccessBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Report submitted!")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .task {
                viewModel.fetchReportReasons()
            }
            .onChange(of: viewModel.reportSuccess) { success in
                guard success else { return }
                isReported = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showingSuccessBanner = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation(.easeOut(duration: 0.3)) {
                        showingSuccessBanner = false
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    dismiss()
                }
            }
            .onChange(of: viewModel.alreadyReported) { already in
                guard already else { return }
                isReported = true
                dismiss()
            }
        }
    }

    // MARK: - Post Header

    private var postHeader: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: post.backImage)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(post.track.title)
                    .font(.headline)
                    .textCase(.uppercase)
                Text(post.track.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }

    // MARK: - Report Form

    private var reportForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Why are you reporting this post?")
                        .font(.headline)

                    if viewModel.reportReasons.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(viewModel.reportReasons, id: \.key) { reason in
                            Button {
                                selectedReason = reason
                            } label: {
                                HStack {
                                    Text(reason.label)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedReason?.key == reason.key {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedReason?.key == reason.key
                                            ? Color.blue.opacity(0.08)
                                            : Color(.secondarySystemBackground))
                                )
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional details (optional)")
                        .font(.headline)

                    TextField("Describe the issue...", text: $message, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .lineLimit(3...6)
                }

                if let error = viewModel.reportError {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Button {
                    guard let reason = selectedReason else { return }
                    Task {
                        await viewModel.reportPost(postId: post.id, reason: reason.key, message: message)
                    }
                } label: {
                    Group {
                        if viewModel.isReportLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Submit report")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selectedReason == nil ? Color.gray.opacity(0.4) : Color.red)
                    .foregroundStyle(.white)
                    .cornerRadius(14)
                }
                .disabled(selectedReason == nil || viewModel.isReportLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
    }
}
