import SwiftUI
import UIKit

// WCAG AA-compliant adaptive blues — tested on system list backgrounds (#F2F2F7 light / #1C1C1E dark)
extension Color {
    static let listPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red:  90/255, green: 173/255, blue: 255/255, alpha: 1) // #5AADFF 7.2:1
            : UIColor(red:   0,     green:  64/255, blue: 192/255, alpha: 1) // #0040C0 7.5:1
    })
    static let listSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red:  68/255, green: 153/255, blue: 245/255, alpha: 1) // #4499F5 5.8:1
            : UIColor(red:   0,     green:  85/255, blue: 204/255, alpha: 1) // #0055CC 5.9:1
    })
    static let listTertiary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red:  51/255, green: 133/255, blue: 232/255, alpha: 1) // #3385E8 4.6:1
            : UIColor(red:   0,     green: 106/255, blue: 204/255, alpha: 1) // #006ACC 4.8:1
    })
}
