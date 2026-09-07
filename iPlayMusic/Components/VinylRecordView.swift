//
//  VinylRecordView.swift
//  iPlayMusic
//
//  Created by Shiv on 04/09/26.
//

import SwiftUI

struct VinylRecordView: View {

    let artworkURL: URL?
    let isPlaying: Bool

    @State private var rotation: Double = 0

    var body: some View {
        GeometryReader { proxy in

            let size = min(proxy.size.width, proxy.size.height)

            ZStack {

                // MARK: - Main Vinyl
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.42, green: 0.22, blue: 0.07),
                                Color(red: 0.95, green: 0.68, blue: 0.25),
                                Color(red: 0.60, green: 0.32, blue: 0.08),
                                Color(red: 1.00, green: 0.78, blue: 0.38),
                                Color(red: 0.48, green: 0.24, blue: 0.06),
                                Color(red: 0.90, green: 0.58, blue: 0.18),
                                Color(red: 0.42, green: 0.22, blue: 0.07)
                            ]),
                            center: .center
                        )
                    )
                    .overlay {

                        // MARK: - Vinyl Grooves
                        VinylGrooves()
                            .clipShape(Circle())
                    }
                    .overlay {

                        // Metallic highlight
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.55),
                                        .clear,
                                        .black.opacity(0.35),
                                        .white.opacity(0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(
                        color: .black.opacity(0.5),
                        radius: 18,
                        x: 0,
                        y: 10
                    )

                // MARK: - Outer Inner Ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.5),
                                Color.white.opacity(0.35),
                                Color.black.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size * 0.035
                    )
                    .frame(width: size * 0.48)
                    .opacity(0.8)

                // MARK: - Center Label
                ZStack {

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.78, blue: 0.38),
                                    Color(red: 0.66, green: 0.39, blue: 0.10),
                                    Color(red: 0.34, green: 0.17, blue: 0.04)
                                ],
                                center: .center,
                                startRadius: 2,
                                endRadius: size * 0.20
                            )
                        )

                    // Song thumbnail
                    if let artworkURL {

                        AsyncImage(url: artworkURL) { phase in
                            switch phase {

                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()

                            default:
                                VinylDefaultArtwork()
                            }
                        }
                        .frame(
                            width: size * 0.30,
                            height: size * 0.30
                        )
                        .clipShape(Circle())

                    } else {
                        VinylDefaultArtwork()
                            .frame(
                                width: size * 0.30,
                                height: size * 0.30
                            )
                    }

                    // Thumbnail dark overlay / label feel
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .clear,
                                    .black.opacity(0.12),
                                    .black.opacity(0.35)
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: size * 0.18
                            )
                        )
                        .frame(width: size * 0.30)

                    // Center ring
                    Circle()
                        .stroke(
                            Color.black.opacity(0.45),
                            lineWidth: 2
                        )
                        .frame(width: size * 0.31)

                    Circle()
                        .stroke(
                            Color.white.opacity(0.30),
                            lineWidth: 1
                        )
                        .frame(width: size * 0.325)
                }
                .frame(
                    width: size * 0.34,
                    height: size * 0.34
                )

                // MARK: - Center Spindle
                ZStack {

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.75),
                                    Color.black.opacity(0.7),
                                    Color.black
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: size * 0.025
                            )
                        )

                    Circle()
                        .fill(Color.black.opacity(0.85))
                        .frame(width: size * 0.018)
                }
                .frame(
                    width: size * 0.045,
                    height: size * 0.045
                )
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onChange(of: isPlaying) {
                if isPlaying {
                    startRotation()
                }
            }
            .onAppear {

                if isPlaying {
                    startRotation()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Rotation

    private func startRotation() {
        withAnimation(
            .linear(duration: 7)
            .repeatForever(autoreverses: false)
        ) {
            rotation += 360
        }
    }
}

#Preview {
    VinylRecordView(artworkURL: URL(string: "https://c.saavncdn.com/598/Saiyaara-Hindi-2025-20250703061754-500x500.jpg"), isPlaying: true)
}


// MARK: - Vinyl Grooves

struct VinylGrooves: View {

    var body: some View {

        Canvas { context, size in

            let center = CGPoint(
                x: size.width / 2,
                y: size.height / 2
            )

            let maxRadius = min(
                size.width,
                size.height
            ) / 2

            // Fine vinyl grooves
            stride(
                from: maxRadius * 0.36,
                through: maxRadius * 0.96,
                by: maxRadius * 0.012
            )
            .forEach { radius in

                let rect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )

                var path = Path()
                path.addEllipse(in: rect)

                context.stroke(
                    path,
                    with: .color(
                        Color.white.opacity(
                            radius.truncatingRemainder(
                                dividingBy: 8
                            ) < 4
                            ? 0.10
                            : 0.035
                        )
                    ),
                    lineWidth: 0.65
                )
            }

            // Dark grooves
            stride(
                from: maxRadius * 0.38,
                through: maxRadius * 0.94,
                by: maxRadius * 0.025
            )
            .forEach { radius in

                let rect = CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )

                var path = Path()
                path.addEllipse(in: rect)

                context.stroke(
                    path,
                    with: .color(
                        Color.black.opacity(0.13)
                    ),
                    lineWidth: 0.8
                )
            }
        }
    }
}


// MARK: - Default Center Artwork

struct VinylDefaultArtwork: View {

    var body: some View {

        ZStack {

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.68, blue: 0.25),
                            Color(red: 0.48, green: 0.24, blue: 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "music.note")
                .font(.system(size: 42, weight: .medium))
                .foregroundColor(.black.opacity(0.55))
        }
    }
}
