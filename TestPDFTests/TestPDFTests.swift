//  TestPDFTests.swift
//  TestPDFTests
//
//  Created by John Bethancourt on 12/19/20.
//  Copyright © 2020 Glotech
//

import XCTest

@testable import TestPDF

class TestPDFTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
         
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testPrepareForFilling() throws {
        
        measure {
            _ = Form781pdfFiller()
        }
        
    }
    
    func testPrepareForFillingAndFilling() throws {
        
        let filler1 = Form781pdfFiller()
        let testFullData = filler1.fullTestData()
        
        measure {
            let filler = Form781pdfFiller()
            filler.fillOutPDF(with: testFullData)
            // Put the code you want to measure the time of here.
        }
    }

    func testFillingFormFull() throws {
        
        let filler = Form781pdfFiller()
        let testFullData = filler.fullTestData()
 
        measure {
            filler.fillOutPDF(with: testFullData)
            // Put the code you want to measure the time of here.
        }
         
        
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testFillingFormNormal() throws {
        
        let filler2 = Form781pdfFiller()
        
         let normalData = filler2.normalTestData()
        measure {
            filler2.fillOutPDF(with: normalData)
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    

}
