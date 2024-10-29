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
                VStack(alignment: .center) {
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
                            }.padding()
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
                        
                        ObjectInfoSection(title: "Date", content: objectDetails.objectDate)
                        
                        Divider()
                        
                        ObjectInfoSection(title: "Medium", content: objectDetails.medium)
                        
                        Divider()
                        
                        ObjectInfoSection(title: "Dimensions", content: objectDetails.dimensions)
                        
                        Divider()
                        
                        ObjectInfoSection(title: "Department", content: objectDetails.department)
                        
                        if !objectDetails.culture.isEmpty {
                            Divider()
                            ObjectInfoSection(title: "Culture", content: objectDetails.culture)
                        }
                        
                        if !objectDetails.period.isEmpty {
                            Divider()
                            ObjectInfoSection(title: "Period", content: objectDetails.period)
                        }
                        
                        if !objectDetails.geographyType.isEmpty {
                            Divider()
                            ObjectInfoSection(
                                title: objectDetails.geographyType,
                                content: "\(objectDetails.city), \(objectDetails.country)"
                            )
                        }
                        
                        Divider()
                        
                        ObjectInfoSection(title: "Credit Line", content: objectDetails.creditLine)
                        
                        if !objectDetails.objectURL.isEmpty {
                            VStack {
                                Button {
                                    guard let url = URL(string: objectDetails.objectURL) else { return }
                                    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "") { _,_ in
                                    }
                                    session.prefersEphemeralWebBrowserSession = true
                                    session.start()
                                } label: {
                                    Text("View More Details")
                                }
                                ShareLink(items: [URL(string: objectDetails.objectURL)!]) {
                                    Label("Share", systemImage: "paperplane.fill")
                                }
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


