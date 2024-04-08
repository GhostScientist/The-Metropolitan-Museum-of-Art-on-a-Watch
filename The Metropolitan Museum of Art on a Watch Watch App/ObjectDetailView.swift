//
//  ObjectDetailView.swift
//  The Metropolitan Museum of Art on a Watch Watch App
//
//  Created by Dakota Kim on 4/2/24.
//

import SwiftUI
import AuthenticationServices

struct ObjectDetailView: View {
    let objectDetails: ObjectDetails
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    if !objectDetails.primaryImage.isEmpty {
                        NavigationLink(destination: ImageInspectView(imageURL: objectDetails.primaryImage)) {
                            AsyncImage(url: URL(string: objectDetails.primaryImage)) { image in
                                image
                                
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                
                            } placeholder: {
                                ProgressView()
                            }
                            .cornerRadius(10.0)
                        }.buttonStyle(PlainButtonStyle())
                    } else {
                        VStack {
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                            
                            Text("No image for this option")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .cornerRadius(10.0)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(objectDetails.title)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        if !objectDetails.artistDisplayBio.isEmpty {
                            Text(objectDetails.artistDisplayBio)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading) {
                            Text("Date:")
                                .fontWeight(.bold)
                            Text(objectDetails.objectDate)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        
                        Divider()
                        
                        VStack(alignment: .leading) {
                            Text("Medium:")
                                .fontWeight(.bold)
                            Text(objectDetails.medium)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        
                        Divider()
                        
                        VStack(alignment: .leading) {
                            Text("Dimensions:")
                                .fontWeight(.bold)
                            Text(objectDetails.dimensions)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        
                        Divider()
                        
                        VStack(alignment: .leading) {
                            Text("Department:")
                                .fontWeight(.bold)
                            Text(objectDetails.department)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        
                        if !objectDetails.culture.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading) {
                                Text("Culture:")
                                    .fontWeight(.bold)
                                Text(objectDetails.culture)
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                        
                        if !objectDetails.period.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading) {
                                Text("Period:")
                                    .fontWeight(.bold)
                                Text(objectDetails.period)
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                        
                        if !objectDetails.geographyType.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading) {
                                Text("\(objectDetails.geographyType):")
                                    .fontWeight(.bold)
                                Text("\(objectDetails.city), \(objectDetails.country)")
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading) {
                            Text("Credit Line:")
                                .fontWeight(.bold)
                            Text(objectDetails.creditLine)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        
                        if !objectDetails.objectURL.isEmpty {
                            Button {
                                guard let url = URL(string: objectDetails.objectURL) else { return }
                                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "") { _,_ in
                                }
                                session.prefersEphemeralWebBrowserSession = true
                                session.start()
                            } label: {
                                Text("View More Details")
                                
                            }
                        }
                        
                    }
                }
                .padding()
            }
        }
        
        .containerBackground(.blue.gradient, for: .navigation)
        .navigationBarTitle(objectDetails.artistDisplayName)
    }
}

struct ImageInspectView: View {
    let imageURL: String
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .cornerRadius(10.0)
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .onTapGesture(count: 2) {
                        print("Double tapped!")
                        withAnimation(.spring()) {
                            scale = 1.0
                            offset = .zero
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    offset = .zero
                                }
                            }
                        
                    )
            } placeholder: {
                ProgressView()
            }
            
            HStack {
                Button(action: {
                    withAnimation {
                        scale = max(scale - 0.5, 1.0)
                    }
                }) {
                    Image(systemName: "minus")
                }
                
                Button(action: {
                    withAnimation {
                        scale = min(scale + 0.5, 5.0)
                    }
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
