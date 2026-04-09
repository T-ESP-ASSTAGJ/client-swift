//
//  OnboardingView.swift
//  jamly
//

import SwiftUI

// MARK: - Model

private struct OnboardingSlide: Identifiable {
    let id: Int
    let accentColors: [Color]
    let title: String
    let subtitle: String
}

// MARK: - Main View

struct OnboardingView: View {

    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var authManager: AuthManager
    @State private var currentPage = 0

    private let slides: [OnboardingSlide] = [
        .init(id: 0,
              accentColors: [.purple, .pink],
              title: "Bienvenue sur Jamly",
              subtitle: "Le réseau social qui fait vibrer ta musique."),
        .init(id: 1,
              accentColors: [.orange, .pink],
              title: "Partage tes coups de cœur",
              subtitle: "Publie le morceau du moment en quelques secondes."),
        .init(id: 2,
              accentColors: [.blue, .cyan],
              title: "Découvre de nouveaux sons",
              subtitle: "Explore les publications de tes amis et trouve ta prochaine obsession."),
        .init(id: 3,
              accentColors: [.purple, .blue],
              title: "Reste connecté",
              subtitle: "Likes, commentaires et messages, tout au même endroit."),
    ]

    private var current: OnboardingSlide { slides[currentPage] }
    private var isLastSlide: Bool { currentPage == slides.count - 1 }
    private var progress: CGFloat { CGFloat(currentPage + 1) / CGFloat(slides.count) }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {

                // Pagination pills
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentPage ? 32 : 20, height: 4)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.top, 20)

                // Title + subtitle
                VStack(spacing: 12) {
                    Text(current.title)
                        .font(.custom("Poppins-Bold", size: 32))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(current.subtitle)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 32)
                .animation(.easeInOut(duration: 0.25), value: currentPage)

                // Hero illustration (swipeable)
                TabView(selection: $currentPage) {
                    ForEach(slides) { slide in
                        OnboardingHero(slide: slide)
                            .tag(slide.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Next / Done button
                OnboardingNextButton(progress: progress, isLast: isLastSlide) {
                    if isLastSlide {
                        authManager.completeOnboarding()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                current.accentColors[0].opacity(0.45),
                                current.accentColors[1].opacity(0.30),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 420, height: 420)
                    .blur(radius: 130)
                    .offset(x: -120, y: 80)
                    .animation(.easeInOut(duration: 1.2), value: currentPage)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                current.accentColors[1].opacity(0.30),
                                current.accentColors[0].opacity(0.20),
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: 360, height: 360)
                    .blur(radius: 110)
                    .offset(x: geometry.size.width - 180, y: geometry.size.height - 480)
                    .animation(.easeInOut(duration: 1.2), value: currentPage)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Hero Illustrations

private struct OnboardingHero: View {

    let slide: OnboardingSlide
    @State private var pulse = false

    var body: some View {
        switch slide.id {
        case 0: welcomeHero
        case 1: publishHero
        case 2: discoverHero
        default: socialHero
        }
    }

    // MARK: Slide 0 — Brand mark

    private var welcomeHero: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: slide.accentColors.map { $0.opacity(0.35) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 280, height: 280)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: slide.accentColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 220, height: 220)
                .scaleEffect(pulse ? 1.04 : 1)
                .opacity(pulse ? 0.6 : 1)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)

            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 170, height: 170)
                .overlay {
                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                }

            VStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)

                Text("JAMLY")
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundStyle(.white)
                    .tracking(2)
            }
        }
        .onAppear { pulse = true }
    }

    // MARK: Slide 1 — Publication mock

    private var publishHero: some View {
        VStack(spacing: 0) {
            // Header — user
            HStack(spacing: 10) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: slide.accentColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Toi")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundStyle(.white)
                    Text("vient de partager")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "music.note")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay { Circle().stroke(Color.white.opacity(0.2), lineWidth: 1) }
            }
            .padding(14)

            // Cover area with playing badge
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: slide.accentColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 150)
                    .overlay {
                        Image(systemName: "music.quarternote.3")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }

                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Playing")
                        .font(.custom("Poppins-SemiBold", size: 10))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1) }
                .padding(12)
            }
            .padding(.horizontal, 14)

            // Track info row
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: slide.accentColors.reversed(),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Midnight Drive")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundStyle(.white)
                    Text("Arctic Synthwave")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "apple.logo")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(14)
        }
        .frame(width: 290)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: slide.accentColors.map { $0.opacity(0.15) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        }
    }

    // MARK: Slide 2 — Discover feed

    private var discoverHero: some View {
        VStack(spacing: 12) {
            trackRow(title: "Echoes", artist: "Lila Monroe", opacity: 0.50)
            trackRow(title: "Slow Dancer", artist: "Owen Wave", opacity: 0.78)
            trackRow(title: "Midnight Drive", artist: "Arctic Synthwave", opacity: 1)
        }
        .frame(width: 290)
    }

    private func trackRow(title: String, artist: String, opacity: Double) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: slide.accentColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundStyle(.white)
                Text(artist)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            Image(systemName: "play.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: Circle())
                .overlay { Circle().stroke(Color.white.opacity(0.2), lineWidth: 1) }
        }
        .padding(12)
        .frame(width: 290)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: slide.accentColors.map { $0.opacity(0.15) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        }
        .opacity(opacity)
    }

    // MARK: Slide 3 — Social interactions

    private var socialHero: some View {
        VStack(spacing: 14) {
            chatBubble(
                icon: "heart.fill",
                title: "Lila a aimé ton post",
                message: "Midnight Drive — Arctic Synthwave",
                isLeading: true
            )
            chatBubble(
                icon: "ellipsis.message.fill",
                title: "Marc",
                message: "Ce son est une tuerie 🔥",
                isLeading: false
            )
            chatBubble(
                icon: "music.note",
                title: "Sarah a partagé un morceau",
                message: "Echoes — Lila Monroe",
                isLeading: true
            )
        }
        .frame(width: 300)
    }

    private func chatBubble(icon: String, title: String, message: String, isLeading: Bool) -> some View {
        HStack(spacing: 0) {
            if !isLeading { Spacer(minLength: 0) }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: slide.accentColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(width: 250)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            }

            if isLeading { Spacer(minLength: 0) }
        }
    }
}

// MARK: - Next Button

private struct OnboardingNextButton: View {

    let progress: CGFloat
    let isLast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 3)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: progress)

                Circle()
                    .fill(Color.white)
                    .frame(width: 56, height: 56)

                Image(systemName: isLast ? "checkmark" : "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                    .animation(.easeInOut(duration: 0.2), value: isLast)
            }
        }
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    let userStore = UserStore()
    let authManager = AuthManager(userStore: userStore)

    OnboardingView()
        .environmentObject(userStore)
        .environmentObject(authManager)
}
