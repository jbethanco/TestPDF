//  Form781data.swift
//  TestPDF
//
//  Created by John Bethancourt on 12/18/20.
//  Copyright © 2020 Glotech
//

import Foundation

struct Form781Data: Codable {
    
    var date: String
    var mds: String
    var serialNumber: String
    var unitCharged: String
    var harmLocation: String
    var flightAuthNum: String
    var issuingUnit: String
    var grandTotalTime: Double?
    var grandTotalTouchAndGo: Int?
    var grandTotalFullStop: Int?
    var grandTotalLandings: Int?
    var grandTotalSorties: Int?
    
    var flights: [Flight]
    var crewMembers: [CrewMember]
    
}

struct Flight: Codable {
    
    var flightSeq: String
    var missionNumber: String
    var missionSymbol: String
    var fromICAO: String
    var toICAO: String
    var takeOffTime: String
    var landTime: String
    var totalTime: String
    var touchAndGo: String
    var fullStop: String
    var totalLandings: String
    var sorties: String
    var specialUse: String
    
}

struct CrewMember: Codable {
    
    var lastName: String
    var firstName: String
    var ssnLast4: String
    var flightAuthDutyCode: String
    var flyingOrganization: String
    var primary: String?
    var secondary: String?
    var instructor: String?
    var evaluator: String?
    var other: String?
    var time: String?
    var srty: String?
    var nightPSIE: String?
    var insPIE: String?
    var simIns: String?
    var nvg: String?
    var combatTime: String?
    var combatSrty: String?
    var combatSptTime: String?
    var combatSptSrty: String?
    var resvStatus: String?
    
}
