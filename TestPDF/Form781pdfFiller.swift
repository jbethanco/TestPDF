//
//  PDFThing.swift
//  TestPDF
//
//  Created by John Bethancourt on 12/16/20.
//

import UIKit
import PDFKit

class Form781pdfFiller: ObservableObject{
    
    @Published var url : URL!
    @Published var statusMessage = "Waiting"
    var readyToFill = false
    
    var pageAnnotationDictionaries = [[String : CGPoint]]() // an array of string : point dictionaries
    
    var formsData = [Form781Data]()
    
    let blankPDFpath: String!
    //let blankPDF: PDFDocument!
    
    init(){
        print(#function)
        let path = Bundle.main.path(forResource: "fillable781", ofType: "pdf")
        //let pdf = PDFDocument(url: URL(fileURLWithPath: path!))
        self.url = URL(fileURLWithPath: path!)
         
         
        blankPDFpath = path
        prepareForFilling()
        
    }
    
    /// Talking out loud:
    /// Prepares the class for filling the form by generating a dictionary of field origin cartesian coordinates.
    ///
    /// Because the only way to immediately access an individual form annoation (field) is by the
    /// "page.getAnnotation(at: CGPoint)" method, it is impossible to get the fields by fieldname
    /// without looping through every field and matching the field name O(n) where n is every field
    /// in the entire form. We could fill all fields in one swoop, but that still requires going through
    /// every field when typically only a handful are filled out. There are 401 fields on the front of the form
    /// so this preperation changes n from 401 to 1.
    ///
    /// This method is run an instantiation and makes a dictionary of keys with the field name containing
    /// the origins CGPoint of the field. This allows us to get a field by name, because we can immediatly
    /// have access to the origin via the dictionary. This preperation takes a few milliseconds, but will
    /// only happen once during the app lifetime.
    ///
    /// IMPERATIVE: When creating the pdf, the form fields must not overlap at all.
    /// For example, when creating the form the first time, serial and unit charged fields were overlapping.
    /// This caused the unit charged field to somehow get pulled as the serial field.
    ///
    /// We could hardcode the field origins, but if we edit the form or get a new form, we will have to do it
    /// again. No fun.
    ///
    /// Was thinking to make this a global singleton in order to run prepare for filling just once, because I thought it would take more time.
    /// It doesn't take long.
    /// Most likely course forward is to make this an extension on a Form781 object. So it can be called simply such as
    ///
    /// let form781 = Form781Object()
    /// //fill out the form 781 and then call:
    /// let pdf = form781.pdf()
    ///
    ///
    private func prepareForFilling(){
        
        DispatchQueue.global(qos: .userInitiated).async{
            
            //get path of the fillable form
            guard let path = self.blankPDFpath,
                  let pdf = PDFDocument(url: URL(fileURLWithPath: path)),
                  pdf.pageCount > 0 else{
                return
            }
            
            // go through each page and make the annotations [FieldName : CGPoint (origin)] dictionary
            for i in 0..<pdf.pageCount{
                
                var annotationDictionary = [String : CGPoint]()
                let page = pdf.page(at: i)
                
                // go through every annotation on the page and fill the dictionary with the field name and origin
                for annotation in page!.annotations{
                    annotationDictionary[annotation.fieldName!] = annotation.bounds.origin
                    
                }
                //add page annotation dictionary
                self.pageAnnotationDictionaries.append(annotationDictionary)
                
            }
            //print(self.pageAnnotationDictionaries[1])
            self.readyToFill = true
        }
    }
    
     
    
    func fillOutPDF(with formData: Form781Data){
        if !readyToFill {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async{
            
            NSLog("start %@", #function)
            DispatchQueue.main.async {
                self.url = URL(fileURLWithPath: self.blankPDFpath)
                self.statusMessage = "Filling"
            }
            
            guard let path = self.blankPDFpath,
                  let pdf = PDFDocument(url: URL(fileURLWithPath: path)),
                  pdf.pageCount > 0 else{
                return
            }
            
            let page0 = pdf.page(at:0)
            
            let page0dict = self.pageAnnotationDictionaries[0]
            
            page0?.annotation(at: page0dict["date"]!)?          .setText(formData.date)
            page0?.annotation(at: page0dict["mds"]!)?           .setText(formData.mds)
            page0?.annotation(at: page0dict["serial"]!)?        .setText(formData.serialNumber)
            page0?.annotation(at: page0dict["unit_charged"]!)?  .setText(formData.unitCharged)
            page0?.annotation(at: page0dict["harm_location"]!)? .setText(formData.harmLocation)
            page0?.annotation(at: page0dict["flight_auth"]!)?   .setText(formData.flightAuthNum)
            page0?.annotation(at: page0dict["issuing_unit"]!)?  .setText(formData.issuingUnit)
            
            //Fill out flight data section
            //max 6 even if flights somehow contains more
            for i in 0..<min(formData.flights.count, 6) {
                page0?.annotation(at: page0dict["mission_number_\(i)"]!)?   .setText(formData.flights[i].missionNumber)
                page0?.annotation(at: page0dict["mission_symbol_\(i)"]!)?   .setText(formData.flights[i].missionSymbol)
                page0?.annotation(at: page0dict["from_icao_\(i)"]!)?        .setText(formData.flights[i].fromICAO)
                page0?.annotation(at: page0dict["to_icao_\(i)"]!)?          .setText(formData.flights[i].toICAO)
                page0?.annotation(at: page0dict["take_off_time_\(i)"]!)?    .setText(formData.flights[i].takeOffTime)
                page0?.annotation(at: page0dict["land_time_\(i)"]!)?        .setText(formData.flights[i].landTime)
                page0?.annotation(at: page0dict["total_time_\(i)"]!)?        .setText(formData.flights[i].totalTime)
                page0?.annotation(at: page0dict["touch_go_\(i)"]!)?         .setText(formData.flights[i].touchAndGo)
                page0?.annotation(at: page0dict["full_stop_\(i)"]!)?        .setText(formData.flights[i].fullStop)
                page0?.annotation(at: page0dict["total_\(i)"]!)?            .setText(formData.flights[i].totalLandings)
                page0?.annotation(at: page0dict["sorties_\(i)"]!)?          .setText(formData.flights[i].sorties)
                page0?.annotation(at: page0dict["special_use_\(i)"]!)?      .setText(formData.flights[i].specialUse)
                
            }
            
            //Fill out crew member section
            //zeroeth to max on front page
            for i in 0..<min(formData.crewMembers.count, 15){
                page0?.annotation(at: page0dict["organization_\(i)"]!)?         .setText(formData.crewMembers[i].flyingOrganization)
                page0?.annotation(at: page0dict["ssan_\(i)"]!)?                 .setText(formData.crewMembers[i].ssnLast4)
                page0?.annotation(at: page0dict["last_name_\(i)"]!)?            .setText(formData.crewMembers[i].lastName)
                page0?.annotation(at: page0dict["flight_auth_\(i)"]!)?          .setText(formData.crewMembers[i].flightAuthDutyCode)
                page0?.annotation(at: page0dict["ft_prim_\(i)"]!)?              .setText(formData.crewMembers[i].primary)
                page0?.annotation(at: page0dict["ft_sec_\(i)"]!)?               .setText(formData.crewMembers[i].secondary)
                page0?.annotation(at: page0dict["ft_instr_\(i)"]!)?             .setText(formData.crewMembers[i].instructor)
                page0?.annotation(at: page0dict["ft_eval_\(i)"]!)?              .setText(formData.crewMembers[i].evaluator)
                page0?.annotation(at: page0dict["ft_other_\(i)"]!)?             .setText(formData.crewMembers[i].other)
                page0?.annotation(at: page0dict["ft_total_time_\(i)"]!)?        .setText(formData.crewMembers[i].time)
                page0?.annotation(at: page0dict["ft_total_srty_\(i)"]!)?        .setText(formData.crewMembers[i].srty)
                page0?.annotation(at: page0dict["fc_night_\(i)"]!)?             .setText(formData.crewMembers[i].nightPSIE)
                page0?.annotation(at: page0dict["fc_ins_\(i)"]!)?               .setText(formData.crewMembers[i].insPIE)
                page0?.annotation(at: page0dict["fc_sim_ins_\(i)"]!)?           .setText(formData.crewMembers[i].simIns)
                page0?.annotation(at: page0dict["fc_nvg_\(i)"]!)?               .setText(formData.crewMembers[i].nvg)
                page0?.annotation(at: page0dict["fc_combat_time_\(i)"]!)?       .setText(formData.crewMembers[i].combatTime)
                page0?.annotation(at: page0dict["fc_combat_srty_\(i)"]!)?       .setText(formData.crewMembers[i].combatSrty)
                page0?.annotation(at: page0dict["fc_combat_spt_time_\(i)"]!)?   .setText(formData.crewMembers[i].combatSptTime)
                page0?.annotation(at: page0dict["fc_combat_spt_srty_\(i)"]!)?   .setText(formData.crewMembers[i].combatSptSrty)
                page0?.annotation(at: page0dict["resv_status_\(i)"]!)?          .setText(formData.crewMembers[i].resvStatus)
                
            }
            print(formData.crewMembers.count)
            if formData.crewMembers.count > 14{
                let page1 = pdf.page(at:1)
                let page1dict = self.pageAnnotationDictionaries[1]
                
                
                for i in 15..<min(formData.crewMembers.count, 35){
                    
                    page1?.annotation(at: page1dict["organization_\(i)"]!)?         .setText(formData.crewMembers[i].flyingOrganization)
                    page1?.annotation(at: page1dict["ssan_\(i)"]!)?                 .setText(formData.crewMembers[i].ssnLast4)
                    page1?.annotation(at: page1dict["last_name_\(i)"]!)?            .setText(formData.crewMembers[i].lastName)
                    page1?.annotation(at: page1dict["flight_auth_\(i)"]!)?          .setText(formData.crewMembers[i].flightAuthDutyCode)
                    page1?.annotation(at: page1dict["ft_prim_\(i)"]!)?              .setText(formData.crewMembers[i].primary)
                    page1?.annotation(at: page1dict["ft_sec_\(i)"]!)?               .setText(formData.crewMembers[i].secondary)
                    page1?.annotation(at: page1dict["ft_instr_\(i)"]!)?             .setText(formData.crewMembers[i].instructor)
                    page1?.annotation(at: page1dict["ft_eval_\(i)"]!)?              .setText(formData.crewMembers[i].evaluator)
                    page1?.annotation(at: page1dict["ft_other_\(i)"]!)?             .setText(formData.crewMembers[i].other)
                    page1?.annotation(at: page1dict["ft_total_time_\(i)"]!)?        .setText(formData.crewMembers[i].time)
                    page1?.annotation(at: page1dict["ft_total_srty_\(i)"]!)?        .setText(formData.crewMembers[i].srty)
                    page1?.annotation(at: page1dict["fc_night_\(i)"]!)?             .setText(formData.crewMembers[i].nightPSIE)
                    page1?.annotation(at: page1dict["fc_ins_\(i)"]!)?               .setText(formData.crewMembers[i].insPIE)
                    page1?.annotation(at: page1dict["fc_sim_ins_\(i)"]!)?           .setText(formData.crewMembers[i].simIns)
                    page1?.annotation(at: page1dict["fc_nvg_\(i)"]!)?               .setText(formData.crewMembers[i].nvg)
                    page1?.annotation(at: page1dict["fc_combat_time_\(i)"]!)?       .setText(formData.crewMembers[i].combatTime)
                    page1?.annotation(at: page1dict["fc_combat_srty_\(i)"]!)?       .setText(formData.crewMembers[i].combatSrty)
                    page1?.annotation(at: page1dict["fc_combat_spt_time_\(i)"]!)?   .setText(formData.crewMembers[i].combatSptTime)
                    page1?.annotation(at: page1dict["fc_combat_spt_srty_\(i)"]!)?   .setText(formData.crewMembers[i].combatSptSrty)
                    page1?.annotation(at: page1dict["resv_status_\(i)"]!)?          .setText(formData.crewMembers[i].resvStatus)
                }
                
            }
            DispatchQueue.main.async {
                self.statusMessage = "Filled - Saving"
            }
            let data = pdf.dataRepresentation()
            //print(data)
            
            do {
                //let newPath = path.replacingOccurrences(of: "fillable", with: "filled")
                
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                var savePath = paths[0]
                savePath = savePath.appendingPathComponent("filled781.pdf")
                
                try data?.write(to: savePath)
                
                DispatchQueue.main.async {
                    self.url = savePath
                    self.statusMessage = "Saved"
                }
            }catch{
                print("Complete Failure.")
                DispatchQueue.main.async {
                    self.statusMessage = "Failed"
                }
                
            }
            
        }
        NSLog("saved")
        
        
    }
    func normalTestData() -> Form781Data{
        
        let date =  "23 Sep 2020"
        let mds = "SMC017A"
        let serialNumber = "99-0009"
        let unitCharged = "437 AW (HQ AMC) / DKFX"
        let harmLocation = "JB Charleston"
        let flightAuthNum = "20-0539"
        let issuingUnit = "0016AS"
        
        let flightA = Flight(flightSeq: "a", missionNumber: "", missionSymbol: "Q1", fromICAO: "KCHS", toICAO: "KCHS", takeOffTime: "1800", landTime: "2100", totalTime: "3.0", touchAndGo: "", fullStop: "4", totalLandings: "4", sorties: "1", specialUse: "")
    
        let crewMember1 = CrewMember(lastName: "Bertram", firstName: "Gilfoyle", ssnLast4: "1234", flightAuthDutyCode: "IP B5", flyingOrganization: "0016", primary: "1.5", secondary: nil, instructor: "1.5", evaluator: nil, other: "", time: "3.0", srty: "1", nightPSIE: "2.0", insPIE: "", simIns: nil, nvg: "2.0", combatTime: "", combatSrty: nil, combatSptTime: "", combatSptSrty: nil, resvStatus: "")
        
        let crewMember2 = CrewMember(lastName: "Chugtai", firstName: "Dinesh", ssnLast4: "1345", flightAuthDutyCode: "IP BJ", flyingOrganization: "0016", primary: "1.5", secondary: nil, instructor: "1.5", evaluator: nil, other: "", time: "3.0", srty: "1", nightPSIE: "2.0", insPIE: "", simIns: nil, nvg: "2.0", combatTime: "", combatSrty: nil, combatSptTime: "", combatSptSrty: nil, resvStatus: "1")
        
        let crewMember3 = CrewMember(lastName: "LongLastName", firstName: "Monica", ssnLast4: "5322", flightAuthDutyCode: "IP BZ", flyingOrganization: "1234", primary: "1.1", secondary: "2.2", instructor: "3.3", evaluator: "4.4", other: "5.5", time: "0.0", srty: "9", nightPSIE: "6.6", insPIE: "7.7", simIns: "8.8", nvg: "0.0", combatTime: "3.3", combatSrty: "4.4", combatSptTime: "5.5", combatSptSrty: "6.6", resvStatus: "33")
        
        let form = Form781Data(date: date, mds: mds, serialNumber: serialNumber, unitCharged: unitCharged, harmLocation: harmLocation, flightAuthNum: flightAuthNum, issuingUnit: issuingUnit, flights: [flightA], crewMembers: [crewMember1, crewMember2, crewMember3])
        
        return form
        
        
    }
    func fullTestData() -> Form781Data{
        
        let lastNames = ["Anderson", "Bernard", "Connor", "Daniels", "Engram", "Fredericks", "Goddard", "Harrison", "Ingraham", "Jacobson", "Kimmel", "Lucas", "Maryweather", "Nelson", "Osborne", "Pettersen", "Quesenberry", "Reese", "Stein", "Truman", "Underwood", "Victoria", "Wetherspoon", "X", "Young", "Zellman", "Angelos", "Barry", "Caldera", "Davidson", "Elfman", "Franks", "Goodman", "Hanks", "Ivy", "Jalrobi", "Keller", "Look", "Morrison", "Nelly", "Oglethorpe", "Prince", "Qui"]
        
        let icaos = ["RJTY", "KLTS", "KO79", "RJSM", "RJTF", "PHIK", "PHHI", "PHDH", "PHNL", "KBOF", "KADW", "KCHS", "KFFO", "KVPS", "KLSV", "KSPS", "KWRB", "KDOV", "KPAM", "KMCF", "KEND", "KLRF", "KMXF", "KSSC", "KTIK", "KCOF", "KLFI", "KGSB", "KBIX", "KBAD", "KHMN", "KVAD", "KBKF", "KEDW", "KRND", "KIAB", "KOFF", "KSZL", "KLUF", "KDMA", "KSUU", "KCVS", "KDYS", "KLTS", "KHIF", "KRCA", "PAED", "KBAB", "KSKA", "KVGB", "KMUP", "KRDR", "KAGR", "KMIB", "KINS", "KSEQ", "PAEI", "1MS8", "PGUA", "KFEW", "KGFA", "9L2", "0000", "T70"]
        
        var date =  "23 Sep 2020"
        var mds = "SMC017A"
        var serialNumber = "99-0009"
        var unitCharged = "437 AW (HQ AMC) / DKFX"
        var harmLocation = "JB Charleston"
        var flightAuthNum = "20-0539"
        var issuingUnit = "0016AS"
        
        var form = Form781Data(date: date, mds: mds, serialNumber: serialNumber, unitCharged: unitCharged, harmLocation: harmLocation, flightAuthNum: flightAuthNum, issuingUnit: issuingUnit, flights: [Flight](), crewMembers: [CrewMember]())
        
        let flightA = Flight(flightSeq: "a", missionNumber: "", missionSymbol: "Q1", fromICAO: "KCHS", toICAO: "KCHS", takeOffTime: "1800", landTime: "2100", totalTime: "3.0", touchAndGo: "", fullStop: "4", totalLandings: "4", sorties: "1", specialUse: "")
        
        form.flights.append(flightA)
        
        let crewMember1 = CrewMember(lastName: "Bertram", firstName: "Gilfoyle", ssnLast4: "1234", flightAuthDutyCode: "IP B5", flyingOrganization: "0016", primary: "1.5", secondary: nil, instructor: "1.5", evaluator: nil, other: "", time: "3.0", srty: "1", nightPSIE: "2.0", insPIE: "", simIns: nil, nvg: "2.0", combatTime: "", combatSrty: nil, combatSptTime: "", combatSptSrty: nil, resvStatus: "")
        
        let crewMember2 = CrewMember(lastName: "Chugtai", firstName: "Dinesh", ssnLast4: "1345", flightAuthDutyCode: "IP BJ", flyingOrganization: "0016", primary: "1.5", secondary: nil, instructor: "1.5", evaluator: nil, other: "", time: "3.0", srty: "1", nightPSIE: "2.0", insPIE: "", simIns: nil, nvg: "2.0", combatTime: "", combatSrty: nil, combatSptTime: "", combatSptSrty: nil, resvStatus: "1")
        
        let crewMember3 = CrewMember(lastName: "LongLastName", firstName: "Monica", ssnLast4: "5322", flightAuthDutyCode: "IP BZ", flyingOrganization: "1234", primary: "1.1", secondary: "2.2", instructor: "3.3", evaluator: "4.4", other: "5.5", time: "0.0", srty: "9", nightPSIE: "6.6", insPIE: "7.7", simIns: "8.8", nvg: "0.0", combatTime: "3.3", combatSrty: "4.4", combatSptTime: "5.5", combatSptSrty: "6.6", resvStatus: "33")
        
        form.crewMembers = [crewMember1, crewMember2, crewMember3]
        
        formsData = [form]
        
        date =  "24 Sep 2021"
        mds = "SMC019A"
        serialNumber = "99-1119"
        unitCharged = "225 ADS (HQ PACAF) / ALWAYS BLUE"
        harmLocation = "JB Pearl Harbor - Hickam"
        flightAuthNum = "SIM"
        issuingUnit = "0016AS"
        
        var form2Flights = [Flight]()
        var form2 = Form781Data(date: date, mds: mds, serialNumber: serialNumber, unitCharged: unitCharged, harmLocation: harmLocation, flightAuthNum: flightAuthNum, issuingUnit: issuingUnit, flights: [Flight](), crewMembers: [CrewMember]())
        
         
        
        for i in 0..<6{
            
            let flight = Flight(flightSeq: "a", missionNumber: "mn\(i)", missionSymbol: "Q\(i)", fromICAO: icaos[i], toICAO: icaos[icaos.count - 1 - i], takeOffTime: "180\(i)", landTime: "210\(i)", totalTime: "\(Double(i) * 1.0)", touchAndGo: "z\(i)", fullStop: "\(i)", totalLandings: "\(i)", sorties: "\(i)", specialUse: "\(i)")
            
            form2Flights.append(flight)
            
        }
        
        form2.flights = form2Flights
        
        var t = 0.0
        for i in 0..<35{
            let social = String(format: "%04d", i)
            var res = i % 6 //resvStatus is 1, 2, 3, 4, or 33 or blank
            if res == 5 {
                res = 33
            }
            let resvStatus = res == 0 ? "" : "\(res)"
            
            let crewMember = CrewMember(lastName: lastNames[i], firstName: "Bill", ssnLast4: social, flightAuthDutyCode: "DC \(i)", flyingOrganization: "1234", primary: String(format: "%.1f", t + 0.1), secondary: String(format: "%.1f", t + 0.2), instructor: String(format: "%.1f", t + 0.3), evaluator: String(format: "%.1f", t + 0.4), other: String(format: "%.1f", t + 0.5), time: String(format: "%.1f", t + 0.6), srty: String(format: "%.1f", t + 0.7), nightPSIE: String(format: "%.1f", t + 0.8), insPIE: String(format: "%.1f", t + 0.9), simIns: String(format: "%.1f", t + 1.0), nvg: String(format: "%.1f", t + 1.1), combatTime: String(format: "%.1f", t + 1.2), combatSrty: String(format: "%.1f", t + 1.3), combatSptTime: String(format: "%.1f", t + 1.4), combatSptSrty: String(format: "%.1f", t + 1.5), resvStatus: resvStatus)
            
            form2.crewMembers.append(crewMember)
            t += 1.0
        }
        
        formsData.append(form2)
        
        return formsData[1]
    }
    
}

extension PDFAnnotation{
    func setText(_ string: String?){
        let page = self.page
        page?.removeAnnotation(self)
        self.setValue(string ?? "", forAnnotationKey: .widgetValue)
        page?.addAnnotation(self)
    }
}
