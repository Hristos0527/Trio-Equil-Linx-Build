import CoreBluetooth
import Foundation

public protocol LinxScannerDelegate: AnyObject {
    /// Új, dekódolható mérés érkezett a megadott (vagy bármelyik, ha nincs
    /// szűrés) szenzortól.
    func linxScanner(_ scanner: LinxScanner, didRead reading: LinxGlucoseReading)
    /// A szkenner állapota változott (log/diagnosztika).
    func linxScanner(_ scanner: LinxScanner, didUpdateStatus status: String)
    /// A scanner kéri az aktuális kalibrációt a dekódoláshoz.
    func calibrationForLinxScanner(_ scanner: LinxScanner) -> LinxCalibration
    /// A scanner kéri a beállított szenzor-sorozatszámot (nil = bármelyik).
    func sensorSerialForLinxScanner(_ scanner: LinxScanner) -> String?
    /// Hatótávon belül érzékelt Linx szenzor (a kiválasztó listához).
    /// advName = a hirdetett teljes név ("LinX-..."), rssi = jelerősség.
    func linxScanner(_ scanner: LinxScanner, didDiscoverDeviceNamed advName: String, rssi: Int)
}

public final class LinxScanner: NSObject {
    public weak var delegate: LinxScannerDelegate?

    /// A Linx szenzor által hirdetett service-UUID (16-bit SIG: 181F).
    public static let linxServiceUUID = CBUUID(string: "181F")

    /// A gyártói ID a manufacturer data első 2 bájtja, little-endian (Nordic).
    private let expectedManufacturerID: UInt16 = 0x0059

    private var central: CBCentralManager?
    private var lastSeen: [UUID: Date] = [:]

    public private(set) var isScanning: Bool = false

    override public init() {
        super.init()
        ensureCentral()
    }

    /// A CBCentralManager LUSTA, egyszeri létrehozása.
    /// Fontos: CGM törlés→újra-hozzáadás után az új LinxCGMManager új scannert
    /// hoz létre. Ha ilyenkor azonnal új CBCentralManager-t csinálnánk ugyanazzal
    /// a State Restoration ID-vel, miközben a régi belső BLE-állapot még "él",
    /// a CoreBluetooth összezavarodhat és hibás állapotba (akár .unsupported-szerű)
    /// kerülhet. Ezért biztosítjuk, hogy mindig csak EGY managerünk legyen, és
    /// az átmeneti (.unknown/.resetting) állapotokat türelmesen kezeljük.
    private func ensureCentral() {
        guard central == nil else { return }
        // NINCS State Restoration ID: így a manager minden alkalommal tisztán
        // jön létre, és a CGM törlés→újra-hozzáadás sosem akad össze.
        // (A Loop a pumpa-kommunikáció miatt amúgy is gyakran ébren tartja az
        //  appot, így a háttér-olvasás a gyakorlatban továbbra is működik.)
        central = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }

    public func resumeScanning() {
        ensureCentral()
        switch central?.state {
        case .poweredOn:
            startScan()
        case .none,
             .some(.resetting),
             .some(.unknown):
            // Átmeneti állapot — a centralManagerDidUpdateState úgyis elindítja
            // a scant, amint .poweredOn lesz. Itt nem kell tenni semmit.
            notify("Bluetooth starting...")
        default:
            break
        }
    }

    private func startScan() {
        guard let central = central, central.state == .poweredOn else { return }
        // HÁTTÉR-BARÁT scan: konkrét service-UUID-ra szűrünk (181F).
        central.scanForPeripherals(
            withServices: [Self.linxServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        isScanning = true
        notify("Scan fut (181F)...")
    }

    /// A scan leállítása és a manager elengedése (CGM törlésekor hívjuk).
    /// Ez biztosítja, hogy a régi CBCentralManager felszabaduljon, mielőtt
    /// egy újra-hozzáadás új managert hozna létre ugyanazzal a restore ID-vel.
    public func stop() {
        if let central = central, central.state == .poweredOn, isScanning {
            central.stopScan()
        }
        isScanning = false
        central?.delegate = nil
        central = nil
    }

    private func notify(_ s: String) {
        delegate?.linxScanner(self, didUpdateStatus: s)
    }
}

// MARK: - CBCentralManagerDelegate

extension LinxScanner: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            notify("Bluetooth ON — scan starting (181F)")
            startScan()
        case .poweredOff:
            isScanning = false
            notify("Bluetooth is off")
        case .unauthorized:
            notify("No Bluetooth permission")
        case .unsupported:
            notify("Device does not support BLE")
        case .resetting:
            // A BLE-rendszer épp újraindul (pl. CGM törlés→újra-hozzáadás után).
            // NEM végleges hiba — várunk, amíg .poweredOn lesz.
            isScanning = false
            notify("Bluetooth restarting, waiting...")
        case .unknown:
            notify("Bluetooth state loading...")
        @unknown default:
            notify("Bluetooth state: \(central.state.rawValue)")
        }
    }

    public func centralManager(
        _: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let advName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? peripheral.name ?? ""

        // Manufacturer data kiolvasása
        guard let mfg = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }

        let bytes = [UInt8](mfg)
        let mfgID: UInt16 = bytes.count >= 2
            ? UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
            : 0

        // Biztonsági szűrés: csak Nordic (0x0059) 27-bájtos Linx csomag.
        guard mfgID == expectedManufacturerID, bytes.count == 27 else { return }

        // Kiválasztó lista: CSAK olyan eszközt jelentünk a UI-nak, aminek a
        // nevében szerepel a "Linx" (más BT-eszköz sosem). Ez a sorozatszám-
        // szűrés ELŐTT fut, hogy minden hatótávon belüli Linx megjelenjen.
        if advName.lowercased().contains("linx") {
            delegate?.linxScanner(self, didDiscoverDeviceNamed: advName, rssi: RSSI.intValue)
        }

        // Sorozatszám-szűrés: ha a felhasználó megadott egyet, csak azt fogadjuk.
        if let wanted = delegate?.sensorSerialForLinxScanner(self),
           !wanted.isEmpty
        {
            // Részleges egyezés is elég (a hirdetett név "LinX-2222296PN2" formátum).
            if !advName.isEmpty, !advName.contains(wanted) {
                return
            }
        }

        // Throttle: 1 mp eszközönként
        let now = Date()
        if let last = lastSeen[peripheral.identifier], now.timeIntervalSince(last) < 1.0 {
            return
        }
        lastSeen[peripheral.identifier] = now

        // Dekódolás az aktuális kalibrációval
        let cal = delegate?.calibrationForLinxScanner(self) ?? LinxCalibration()
        if let reading = LinxDecoder.decode(manufacturerData: mfg, advName: advName, calibration: cal) {
            delegate?.linxScanner(self, didRead: reading)
        }
    }
}
