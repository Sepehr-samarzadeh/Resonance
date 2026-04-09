//  ContentView.swift
//  Created by Sepehr on 07/04/2026.

import SwiftUI
import MusicKit

struct ContentView: View {
    @State private var isSheetpresented: Bool = false
    var body: some View {
        VStack{
            HStack{
                Button{
                    isSheetpresented.toggle()
                }label: {
                    Text("run sheet")
                        .foregroundStyle(Color.white)
                        .padding(10)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
            }
            .sheet(isPresented: $isSheetpresented){
                MusicChartView()
            }
         
            
            
            makeBtn(btnText: "testResponse", color: .green)
            
            
            Button{
                print("button tapped")
                Task {
                    await checkAuthorization()
                }
            }label: {
                Text("check authorization")
                    .foregroundStyle(Color.white)
                    .padding(10)
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
    }
    
    func checkAuthorization() async {
        let status = await MusicAuthorization.request()
        
        switch status {
        case .authorized:
            print("Authorized")
            
        case .denied:
            print("Denied")
            
        case .restricted:
            print("Restricted")
            
        case .notDetermined:
            print("Not determined")
            
        @unknown default:
            print("Unknown state")
        }
    }
    
    func fetchMyData() async throws {
        let url = URL(string: "https://api.music.apple.com/v1/me/library/albums")!
        let urlRequest = URLRequest(url: url)
        
        let request = MusicDataRequest(urlRequest: urlRequest)
        let response = try await request.response()
        
        print(response.description)
    }
    func makeBtn(btnText: String,color: Color) -> some View {
        Button{
            Task {try await fetchany()}
        }label: {
            Text(btnText)
                .foregroundStyle(.white)
                .padding(10)
                .background(color)
                .cornerRadius(10)
        }
        
    }
    func fetchany() async throws {
        let request = MusicCatalogChartsRequest(
            kinds: [.dailyGlobalTop],
            types: [Song.self]
        )
        let response = try await request.response()
        print("\(response.playlistCharts)")
    }
}

#Preview {
    ContentView()
}
