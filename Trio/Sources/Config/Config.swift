import Foundation
import SwiftDate

enum Config {
    static let treatWarningsAsErrors = true
    static let withSignPosts = false
    static let loopInterval = 3.minutes.timeInterval
    /// A loop-kapu (canStartNewLoop) MINIMUM ideje két ciklus között. A Linx CGM ~3 percenként
    /// ad új mintát, de a fázis csúszhat (egy minta néha 2:50-kor érkezik az előző loop után).
    /// Ha a kapu pontosan 3 perc (loopInterval) lenne, az ilyen minta elveszne és kimaradna egy
    /// ciklus (~6 perc). A küszöböt a Linx-periódus ALÁ (2,5 perc) állítjuk, így MINDEN ~3 perces
    /// minta megbízhatóan loopot indít. A 3 perces ütem marad a CÉL; csak a fáziscsúszást nyeljük el.
    static let loopGateMinimumInterval: TimeInterval = 150 // 2,5 perc
    static let eхpirationInterval = 10.minutes.timeInterval
}
