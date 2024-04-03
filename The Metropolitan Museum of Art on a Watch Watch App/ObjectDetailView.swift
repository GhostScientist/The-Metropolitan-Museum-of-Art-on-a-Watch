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
                }
                
                Text(objectDetails.title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                
                if !objectDetails.artistDisplayBio.isEmpty {
                    Text(objectDetails.artistDisplayBio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(objectDetails.objectDate)
                    .font(.subheadline)
                
                Text("Medium: \(objectDetails.medium)")
                    .font(.subheadline)
                
                Text("Dimensions: \(objectDetails.dimensions)")
                    .font(.subheadline)
                
                Text("Department: \(objectDetails.department)")
                    .font(.subheadline)
                
                if !objectDetails.culture.isEmpty {
                    Text("Culture: \(objectDetails.culture)")
                        .font(.subheadline)
                }
                
                if !objectDetails.period.isEmpty {
                    Text("Period: \(objectDetails.period)")
                        .font(.subheadline)
                }
                
                if !objectDetails.geographyType.isEmpty {
                    Text("\(objectDetails.geographyType): \(objectDetails.city), \(objectDetails.country)")
                        .font(.subheadline)
                }
                
                Text("Credit Line: \(objectDetails.creditLine)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !objectDetails.objectURL.isEmpty {
                    Button {
                        guard let url = URL(string: objectDetails.objectURL) else { return }
                        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "") { _,_ in
                        }
                        session.prefersEphemeralWebBrowserSession = true
                        session.start()
                    } label: {
                        Text("View on The Met website")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }.buttonBorderShape(.roundedRectangle(radius: 10))
                }
                
                
            }
            .padding()
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
