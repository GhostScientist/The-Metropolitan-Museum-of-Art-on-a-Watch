//
//  EnhancedArtworkDetailView.swift
//  The Met for VisionOS
//
//  Created by Dakota Kim on 1/20/25.
//

import SwiftUI
// Remove unused RealityKit import
// import RealityKit
import AuthenticationServices
import TheMetUtilities

struct EnhancedArtworkDetailView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    
    let objectDetails: ObjectDetails
    
    @State private var selectedTab = 0
    @State private var rotationAngle: Double = 0
    @State private var showShareOptions = false
    @State private var isImageHovered = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Left side - Image
                ZStack {
                    if !objectDetails.primaryImage.isEmpty {
                        Button {
                            openWindow(id: "image-viewer", value: objectDetails.primaryImage)
                        } label: {
                            AsyncImage(url: URL(string: objectDetails.primaryImage)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(scale)
                                    .offset(offset)
                                    .gesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                scale = value
                                            }
                                            .onEnded { _ in
                                                withAnimation {
                                                    scale = 1.0
                                                }
                                            }
                                    )
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                offset = value.translation
                                            }
                                            .onEnded { _ in
                                                withAnimation {
                                                    offset = .zero
                                                }
                                            }
                                    )
                            } placeholder: {
                                ProgressView()
                                    .scaleEffect(2.0)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(isImageHovered ? Color.white : Color.clear, lineWidth: 2)
                                    .padding()
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isImageHovered = hovering
                            }
                        }
                        
                        // Zoom controls
                        if isImageHovered {
                            VStack {
                                Spacer()
                                
                                HStack {
                                    Button(action: {
                                        openWindow(id: "image-viewer", value: objectDetails.primaryImage)
                                    }) {
                                        Label("View in 3D", systemImage: "viewfinder")
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        showShareOptions = true
                                    }) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .confirmationDialog("Share Artwork", isPresented: $showShareOptions) {
                                        if let url = URL(string: "https://www.metmuseum.org") {
                                            ShareLink(item: url) {
                                                Label("Share Link", systemImage: "link")
                                            }
                                        }
                                        
                                        if let imageUrl = URL(string: objectDetails.primaryImage) {
                                            ShareLink(item: imageUrl) {
                                                Label("Share Image", systemImage: "photo")
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                    } else {
                        VStack {
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                            
                            Text("No image available")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding()
                
                // Right side - Details
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title and basic info
                        VStack(alignment: .leading, spacing: 10) {
                            Text(objectDetails.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if !objectDetails.artistDisplayName.isEmpty {
                                Text(objectDetails.artistDisplayName)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !objectDetails.artistDisplayBio.isEmpty {
                                Text(objectDetails.artistDisplayBio)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text(objectDetails.objectDate)
                                    .font(.headline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                
                                if !objectDetails.culture.isEmpty {
                                    Text(objectDetails.culture)
                                        .font(.headline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.5))
                        
                        // Tabs for different information sections
                        VStack(alignment: .leading, spacing: 15) {
                            // Tab selector
                            HStack(spacing: 20) {
                                TabButton(title: "Details", isSelected: selectedTab == 0) {
                                    withAnimation {
                                        selectedTab = 0
                                    }
                                }
                                
                                TabButton(title: "Description", isSelected: selectedTab == 1) {
                                    withAnimation {
                                        selectedTab = 1
                                    }
                                }
                                
                                TabButton(title: "Provenance", isSelected: selectedTab == 2) {
                                    withAnimation {
                                        selectedTab = 2
                                    }
                                }
                            }
                            .padding(.bottom, 10)
                            
                            // Tab content
                            switch selectedTab {
                            case 0:
                                // Details tab
                                VStack(alignment: .leading, spacing: 15) {
                                    DetailRow(title: "Department", content: objectDetails.department)
                                    
                                    if !objectDetails.medium.isEmpty {
                                        DetailRow(title: "Medium", content: objectDetails.medium)
                                    }
                                    
                                    if !objectDetails.dimensions.isEmpty {
                                        DetailRow(title: "Dimensions", content: objectDetails.dimensions)
                                    }
                                    
                                    if !objectDetails.period.isEmpty {
                                        DetailRow(title: "Period", content: objectDetails.period)
                                    }
                                }
                                
                            case 1:
                                // Description tab
                                VStack(alignment: .leading, spacing: 15) {
                                    if !objectDetails.objectName.isEmpty {
                                        DetailRow(title: "Object Type", content: objectDetails.objectName)
                                    }
                                    
                                    if !objectDetails.creditLine.isEmpty {
                                        DetailRow(title: "Credit Line", content: objectDetails.creditLine)
                                    }
                                }
                                
                            case 2:
                                // Provenance tab
                                VStack(alignment: .leading, spacing: 15) {
                                    // Remove provenance check as it doesn't exist in ObjectDetails
                                }
                                
                            default:
                                EmptyView()
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.5))
                        
                        // Action buttons
                        VStack(spacing: 15) {
                            if let url = URL(string: "https://www.metmuseum.org") {
                                Button {
                                    UIApplication.shared.open(url)
                                } label: {
                                    Label("View on Met Website", systemImage: "safari")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Button {
                                // Add to favorites or collection
                            } label: {
                                Label("Add to Collection", systemImage: "heart")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                // Toggle immersive view
                                let imageUrl = objectDetails.primaryImage
                                if !imageUrl.isEmpty {
                                    openWindow(id: "image-viewer", value: imageUrl)
                                }
                            } label: {
                                Label("View in 3D Space", systemImage: "cube")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(objectDetails.primaryImage.isEmpty)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding()
            }
            
            // Close button
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding()
                    
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.secondary.opacity(0.2) : Color.clear)
                .foregroundColor(isSelected ? .primary : .secondary)
                .clipShape(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct DetailRow: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(content)
                .font(.body)
        }
    }
}

#Preview {
    // Create a mock view with placeholder data
    Text("Preview not available - ObjectDetails requires proper initialization")
        .padding()
} 