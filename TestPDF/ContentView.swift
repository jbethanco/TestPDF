//
//  ContentView.swift
//  TestPDF
//
//  Created by John Bethancourt on 12/16/20.
//

import SwiftUI
import PDFKit

struct ContentView: View {
    
    var body: some View{
        NavigationView{
            VStack{
                NavigationLink( destination: PDFFillerView(),
                                label: {
                                    Text("PDF Filler Demo")
                                })
                    .padding()
                NavigationLink( destination: DoTheDateView(),
                                label: {
                                    Text("Form Time Test")
                                        .foregroundColor(Color.blue)
                                })
                    .padding()
                Spacer()
            }
            .navigationBarTitle("Menu")
        }
        .navigationViewStyle(StackNavigationViewStyle()) //required to prevent split view on iPad
    }
}



struct PDFFillerView: View {
    
    @ObservedObject  var filler = Form781pdfFiller()
    @State private var isSharing: Bool = false
    @State private var isPrinting: Bool = false
    let statusColors : [String: Color] = ["Filling": .red, "Waiting": .black, "Filled - Saving": .purple, "Saved": .blue, "Failed": .orange]
    
    
    var body: some View {
        let fullData = filler.fullTestData()
        let normData = filler.normalTestData()
        
        VStack {
            
            HStack{
                Spacer()
                Button {
                    filler.fillOutPDF(with: normData)
                } label: {
                    Text("Fill With Normal Data")
                }
                .padding()
                Spacer()
                Button {
                    filler.fillOutPDF(with: fullData)
                } label: {
                    Text("Fill With Full Data")
                }
                .padding()
                Spacer()
                
                Button {
                    self.isSharing = true
                } label: {
                    HStack{
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    
                }
                .padding()
                
                Button {
                    self.printPDF()
                } label: {
                    HStack{
                        Image(systemName: "printer")
                        Text("Print")
                    }
                    
                }
                
                .sheet(isPresented: $isSharing, onDismiss: nil, content: {
                    ActivityViewController(activityItems: [filler.url!])
                })
                
                Spacer()
            } //HStack
            
            HStack{
                
                Text(filler.statusMessage)
                    .font(.caption)
                    .foregroundColor(statusColors[filler.statusMessage])
                    .padding()
                
                ProgressView()
                    .opacity(filler.statusMessage == "Filling" ? 1.0 : 0.0)
                
                Spacer()
            } //HStack - status
            
            PDFRepView(url:$filler.url)
                .padding(3)
            
        } // VStack
        .navigationBarTitle("PDF Filler Demo")
    }
    func printPDF(){
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = filler.url.lastPathComponent
        printInfo.outputType = .grayscale
        
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.showsNumberOfCopies = true
        printController.printingItem = filler.url
        printController.present(animated: true, completionHandler: nil)
    }
    
}

struct DoTheDateView: View {
    @State private var takeOffTime = Date()
    @State private var landTime = Date()
    @State private var lastname = String()
    var body: some View{
        VStack{
            Text("Form Test")
            Form {
                TextField("Last Name", text: $lastname)
                
                DatePicker("Take Off Time", selection: $takeOffTime, displayedComponents: .hourAndMinute)
                    .environment(\.locale, .init(identifier: "en_GB"))
                    .datePickerStyle(CompactDatePickerStyle())
                
                DatePicker("Land Time", selection: $landTime, displayedComponents: .hourAndMinute)
                    .environment(\.locale, .init(identifier: "en_US"))
                    .datePickerStyle(CompactDatePickerStyle())
            }
        }
        
        .navigationBarTitle("Form Entry Test")
    }
    
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        Group {
            ContentView()
                .padding()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (9.7-inch)"))
                .previewDisplayName("iPad Pro (9.7-inch)")
            DoTheDateView()
                .padding()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (9.7-inch)"))
                .previewDisplayName("iPad Pro (9.7-inch)")
        }
    }
}

//PDF View

struct PDFRepView : UIViewRepresentable {
    
    @Binding var url: URL
    
    func makeUIView(context: Context) -> UIView {
        
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let pdfView = uiView as! PDFView
        pdfView.document = PDFDocument(url: url)
    }
    
}

//Share Stuff View

struct ActivityViewController: UIViewControllerRepresentable {
    
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.excludedActivityTypes = [.postToWeibo, .postToFlickr, .postToTwitter, .postToVimeo, .postToFacebook, .postToTencentWeibo, .markupAsPDF, .assignToContact, .openInIBooks, .saveToCameraRoll]
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
    
}


/*
 In terminal run:
 xcrun simctl list devicetypes
 
 Gives available device types for swift ui preview
 
 iPhone 4s (com.apple.CoreSimulator.SimDeviceType.iPhone-4s)
 iPhone 5 (com.apple.CoreSimulator.SimDeviceType.iPhone-5)
 iPhone 5s (com.apple.CoreSimulator.SimDeviceType.iPhone-5s)
 iPhone 6 Plus (com.apple.CoreSimulator.SimDeviceType.iPhone-6-Plus)
 iPhone 6 (com.apple.CoreSimulator.SimDeviceType.iPhone-6)
 iPhone 6s (com.apple.CoreSimulator.SimDeviceType.iPhone-6s)
 iPhone 6s Plus (com.apple.CoreSimulator.SimDeviceType.iPhone-6s-Plus)
 iPhone SE (1st generation) (com.apple.CoreSimulator.SimDeviceType.iPhone-SE)
 iPhone 7 (com.apple.CoreSimulator.SimDeviceType.iPhone-7)
 iPhone 7 Plus (com.apple.CoreSimulator.SimDeviceType.iPhone-7-Plus)
 iPhone 8 (com.apple.CoreSimulator.SimDeviceType.iPhone-8)
 iPhone 8 Plus (com.apple.CoreSimulator.SimDeviceType.iPhone-8-Plus)
 iPhone X (com.apple.CoreSimulator.SimDeviceType.iPhone-X)
 iPhone Xs (com.apple.CoreSimulator.SimDeviceType.iPhone-XS)
 iPhone Xs Max (com.apple.CoreSimulator.SimDeviceType.iPhone-XS-Max)
 iPhone Xʀ (com.apple.CoreSimulator.SimDeviceType.iPhone-XR)
 iPhone 11 (com.apple.CoreSimulator.SimDeviceType.iPhone-11)
 iPhone 11 Pro (com.apple.CoreSimulator.SimDeviceType.iPhone-11-Pro)
 iPhone 11 Pro Max (com.apple.CoreSimulator.SimDeviceType.iPhone-11-Pro-Max)
 iPhone SE (2nd generation) (com.apple.CoreSimulator.SimDeviceType.iPhone-SE--2nd-generation-)
 iPhone 12 mini (com.apple.CoreSimulator.SimDeviceType.iPhone-12-mini)
 iPhone 12 (com.apple.CoreSimulator.SimDeviceType.iPhone-12)
 iPhone 12 Pro (com.apple.CoreSimulator.SimDeviceType.iPhone-12-Pro)
 iPhone 12 Pro Max (com.apple.CoreSimulator.SimDeviceType.iPhone-12-Pro-Max)
 iPod touch (7th generation) (com.apple.CoreSimulator.SimDeviceType.iPod-touch--7th-generation-)
 iPad 2 (com.apple.CoreSimulator.SimDeviceType.iPad-2)
 iPad Retina (com.apple.CoreSimulator.SimDeviceType.iPad-Retina)
 iPad Air (com.apple.CoreSimulator.SimDeviceType.iPad-Air)
 iPad mini 2 (com.apple.CoreSimulator.SimDeviceType.iPad-mini-2)
 iPad mini 3 (com.apple.CoreSimulator.SimDeviceType.iPad-mini-3)
 iPad mini 4 (com.apple.CoreSimulator.SimDeviceType.iPad-mini-4)
 iPad Air 2 (com.apple.CoreSimulator.SimDeviceType.iPad-Air-2)
 iPad Pro (9.7-inch) (com.apple.CoreSimulator.SimDeviceType.iPad-Pro--9-7-inch-)
 iPad Pro (12.9-inch) (1st generation) (com.apple.CoreSimulator.SimDeviceType.iPad-Pro)
 iPad (5th generation) (com.apple.CoreSimulator.SimDeviceType.iPad--5th-generation-)
 iPad Pro (12.9-inch) (2nd generation) (com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---2nd-generation-)
 iPad Pro (10.5-inch) (com.apple.CoreSimulator.SimDeviceType.iPad-Pro--10-5-inch-)
 iPad (6th generation) (com.apple.CoreSimulator.SimDeviceType.iPad--6th-generation-)
 iPad (7th generation) (com.apple.CoreSimulator.SimDeviceType.iPad--7th-generation-)
 iPad Pro (11-inch) (1st generation) (com.apple.CoreSimulator.SimDeviceType.iPad-Pro--11-inch-)
 iPad Pro (12.9-inch) (3rd generation) (com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---3rd-generation-)
 iPad Pro (11-inch) (2nd generation) (com.apple.CoreSimulator.SimDeviceType.iPad-Pro--11-inch---2nd-generation-)
 iPad Pro (12.9-inch) (4th generation) (com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---4th-generation-)
 iPad mini (5th generation) (com.apple.CoreSimulator.SimDeviceType.iPad-mini--5th-generation-)
 iPad Air (3rd generation) (com.apple.CoreSimulator.SimDeviceType.iPad-Air--3rd-generation-)
 iPad (8th generation) (com.apple.CoreSimulator.SimDeviceType.iPad--8th-generation-)
 iPad Air (4th generation) (com.apple.CoreSimulator.SimDeviceType.iPad-Air--4th-generation-)
 Apple TV (com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p)
 Apple TV 4K (com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-4K)
 Apple TV 4K (at 1080p) (com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-1080p)
 Apple Watch - 38mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-38mm)
 Apple Watch - 42mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-42mm)
 Apple Watch Series 2 - 38mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-2-38mm)
 Apple Watch Series 2 - 42mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-2-42mm)
 Apple Watch Series 3 - 38mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-3-38mm)
 Apple Watch Series 3 - 42mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-3-42mm)
 Apple Watch Series 4 - 40mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-4-40mm)
 Apple Watch Series 4 - 44mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-4-44mm)
 Apple Watch Series 5 - 40mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-5-40mm)
 Apple Watch Series 5 - 44mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-5-44mm)
 Apple Watch SE - 40mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-SE-40mm)
 Apple Watch SE - 44mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-SE-44mm)
 Apple Watch Series 6 - 40mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-6-40mm)
 Apple Watch Series 6 - 44mm (com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-6-44mm)
 */
