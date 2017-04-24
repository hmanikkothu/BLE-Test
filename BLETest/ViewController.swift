//
//  ViewController.swift
//  BLETest
//
//  Created by Hari on 4/23/17.
//  Copyright © 2017 Hari. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var manager : CBCentralManager?
    var lePeripheral: CBPeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let centralQueue = DispatchQueue(label: "com.hk", attributes: [])
        manager = CBCentralManager(delegate: self, queue: centralQueue)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func reconnect(_ sender: Any) {
        //self.lePeripheral
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("powerdOn")
            scanForDevices()
        case .poweredOff:
            print ("powerOff")
        case .unsupported:
            print ("unsupported")
        default:
            print ("defalt:\(central.state)")
        }
    }

    func scanForDevices() {
        if let cm = manager {
            //"TailorToys PowerUp"
            cm.scanForPeripherals(withServices: [CBUUID(string: "F000FFC0-0451-4000-B000-000000000000")], options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Name: \(peripheral.name)");
        print("Data: \(advertisementData)")
        
        self.lePeripheral = peripheral;
        central.connect(peripheral, options: nil)
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\(peripheral.name) Connected")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("\(peripheral.name) Failed to connect")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("\(peripheral.name) Disconnected")
        central.connect(peripheral, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services  = peripheral.services as [CBService]! {
            for service in services {
                print ("Services: \(service.description)")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics as [CBCharacteristic]! {
            for characteristic in characteristics {
                print ("Charateristic: \(characteristic)")
                
                //battery level
                if (characteristic.uuid.uuidString == "2A19") {
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (characteristic.uuid.uuidString == "2A19") {
            
            print ("Battery Level: \(characteristic.value)")
            
            if let e = error {
                print("ERROR didUpdateValue \(e)")
                return
            }
            guard let data = characteristic.value else { return }
            print("Battery Level is \(UInt8(data:data))")
        }
    }
}

// Data Extensions:
protocol DataConvertible {
    init(data:Data)
    var data:Data { get }
}

extension DataConvertible {
    init(data:Data) {
        guard data.count == MemoryLayout<Self>.size else {
            fatalError("data size (\(data.count)) != type size (\(MemoryLayout<Self>.size))")
        }
        self = data.withUnsafeBytes { $0.pointee }
    }
    
    var data:Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension UInt8:DataConvertible {}
extension UInt16:DataConvertible {}
extension UInt32:DataConvertible {}
extension Int32:DataConvertible {}
extension Int64:DataConvertible {}
extension Double:DataConvertible {}
extension Float:DataConvertible {}

