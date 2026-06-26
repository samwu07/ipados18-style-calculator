import SwiftUI

@main
struct CalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            CalculatorRootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct CalculatorRootView: View {
    @StateObject private var engine = CalculatorEngine()
    @State private var showTools = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                HStack(spacing: 0) {
                    CalculatorView(engine: engine)
                        .frame(width: proxy.size.width)
                    ToolsView()
                        .frame(width: proxy.size.width)
                }
                .offset(x: showTools ? -proxy.size.width : 0)
                .animation(.interactiveSpring(response: 0.36, dampingFraction: 0.86), value: showTools)
                .gesture(
                    DragGesture(minimumDistance: 28)
                        .onEnded { value in
                            if value.translation.width < -80 { showTools = true }
                            if value.translation.width > 80 { showTools = false }
                        }
                )

                Button {
                    showTools.toggle()
                } label: {
                    Image(systemName: showTools ? "xmark" : "square.grid.2x2")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .padding(.top, 14)
                .padding(.trailing, 20)
            }
        }
    }
}

struct CalculatorView: View {
    @ObservedObject var engine: CalculatorEngine

    private let portrait: [[CalcKey]] = [
        [.clear, .sign, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .minus],
        [.one, .two, .three, .plus],
        [.zero, .dot, .backspace, .equals]
    ]

    private let landscape: [[CalcKey]] = [
        [.clear, .sign, .percent, .divide, .sqrt, .square],
        [.seven, .eight, .nine, .multiply, .reciprocal, .pi],
        [.four, .five, .six, .minus, .empty, .empty],
        [.one, .two, .three, .plus, .empty, .empty],
        [.zero, .dot, .backspace, .equals, .empty, .empty]
    ]

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width > proxy.size.height
            let rows = wide ? landscape : portrait
            let side: CGFloat = wide ? 42 : 22
            let gap: CGFloat = wide ? 14 : 12

            VStack(spacing: 18) {
                Spacer(minLength: 58)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(engine.expression.isEmpty ? " " : engine.expression)
                        .font(.system(size: wide ? 28 : 24, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)

                    Text(engine.display)
                        .font(.system(size: wide ? 82 : 76, weight: .light, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.26)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, side)

                VStack(spacing: gap) {
                    ForEach(rows.indices, id: \.self) { row in
                        HStack(spacing: gap) {
                            ForEach(rows[row]) { key in
                                if key == .empty {
                                    Color.clear.aspectRatio(1.32, contentMode: .fit)
                                } else {
                                    Button { engine.tap(key) } label: {
                                        Text(key.title)
                                            .font(.system(size: key.smallText ? 24 : 32, weight: .medium, design: .rounded))
                                            .foregroundStyle(key.foreground)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.55)
                                            .frame(maxWidth: .infinity)
                                            .aspectRatio(1.32, contentMode: .fit)
                                            .background(key.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, side)
                .padding(.bottom, wide ? 26 : 34)
            }
        }
    }
}

enum CalcKey: String, Identifiable, Hashable {
    case clear = "AC", sign = "+/-", percent = "%"
    case divide = "÷", multiply = "×", minus = "−", plus = "+", equals = "="
    case dot = ".", backspace = "⌫", sqrt = "√", square = "x²", reciprocal = "1/x", pi = "π", empty = ""
    case zero = "0", one = "1", two = "2", three = "3", four = "4", five = "5", six = "6", seven = "7", eight = "8", nine = "9"

    var id: String { rawValue }
    var title: String { rawValue }
    var number: String? { "0123456789".contains(rawValue) ? rawValue : nil }

    var background: Color {
        switch self {
        case .divide, .multiply, .minus, .plus, .equals:
            return Color(red: 1.0, green: 0.62, blue: 0.05)
        case .clear, .sign, .percent:
            return Color(red: 0.64, green: 0.64, blue: 0.66)
        case .sqrt, .square, .reciprocal, .pi:
            return Color(red: 0.18, green: 0.18, blue: 0.19)
        default:
            return Color(red: 0.28, green: 0.28, blue: 0.30)
        }
    }

    var foreground: Color {
        switch self {
        case .clear, .sign, .percent: return .black
        default: return .white
        }
    }

    var smallText: Bool {
        switch self {
        case .clear, .sign, .backspace, .reciprocal: return true
        default: return false
        }
    }
}

final class CalculatorEngine: ObservableObject {
    @Published var display = "0"
    @Published var expression = ""

    private var stored: Double?
    private var pending: CalcKey?
    private var entering = false

    func tap(_ key: CalcKey) {
        if let number = key.number { input(number); return }
        switch key {
        case .clear: clear()
        case .dot: dot()
        case .backspace: backspace()
        case .sign: unary { -$0 }
        case .percent: unary { $0 / 100 }
        case .sqrt: unary { sqrt($0) }
        case .square: unary { $0 * $0 }
        case .reciprocal: unary { $0 == 0 ? .nan : 1 / $0 }
        case .pi: display = clean(Double.pi); entering = true
        case .divide, .multiply, .minus, .plus: setOperator(key)
        case .equals: equals()
        default: break
        }
    }

    private func input(_ number: String) {
        if !entering || display == "0" || display == "错误" {
            display = number
            entering = true
        } else {
            display += number
        }
    }

    private func dot() {
        if !entering || display == "错误" {
            display = "0."
            entering = true
        } else if !display.contains(".") {
            display += "."
        }
    }

    private func setOperator(_ key: CalcKey) {
        let value = current
        if let op = pending, let base = stored, entering {
            stored = apply(op, base, value)
            display = clean(stored ?? 0)
        } else {
            stored = value
        }
        pending = key
        entering = false
        expression = "\(clean(stored ?? 0)) \(key.title)"
    }

    private func equals() {
        guard let op = pending, let base = stored else { return }
        let result = apply(op, base, current)
        if result.isFinite {
            display = clean(result)
            expression = ""
            stored = result
        } else {
            display = "错误"
            expression = ""
            stored = nil
        }
        pending = nil
        entering = false
    }

    private func unary(_ transform: (Double) -> Double) {
        let result = transform(current)
        if result.isFinite {
            display = clean(result)
        } else {
            display = "错误"
            stored = nil
            pending = nil
        }
        entering = true
    }

    private func backspace() {
        guard entering, display != "错误" else { clear(); return }
        display.removeLast()
        if display.isEmpty || display == "-" { display = "0"; entering = false }
    }

    private func clear() {
        display = "0"
        expression = ""
        stored = nil
        pending = nil
        entering = false
    }

    private var current: Double { Double(display) ?? 0 }

    private func apply(_ op: CalcKey, _ lhs: Double, _ rhs: Double) -> Double {
        switch op {
        case .plus: return lhs + rhs
        case .minus: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide: return rhs == 0 ? .nan : lhs / rhs
        default: return rhs
        }
    }

    private func clean(_ value: Double) -> String {
        if value.isNaN || !value.isFinite { return "错误" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 10
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

struct ToolsView: View {
    @State private var tool: Tool = .unit
    @State private var unitValue = "1"
    @State private var fromUnit: UnitChoice = .meter
    @State private var toUnit: UnitChoice = .kilometer
    @State private var loan = "1000000"
    @State private var years = "30"
    @State private var rate = "3.5"
    @State private var price = "299"
    @State private var discount = "8"
    @State private var taxBase = "100"
    @State private var taxRate = "13"

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width > proxy.size.height
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("更多")
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 68)

                    Picker("工具", selection: $tool) {
                        ForEach(Tool.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch tool {
                    case .unit:
                        ToolCard {
                            Field("数值", text: $unitValue)
                            HStack(spacing: 12) {
                                UnitMenu("从", selection: $fromUnit)
                                UnitMenu("到", selection: $toUnit)
                            }
                            Result("结果", value: unitResult)
                        }
                    case .loan:
                        ToolCard {
                            Field("贷款金额", text: $loan)
                            Field("贷款年限", text: $years)
                            Field("年利率 %", text: $rate)
                            Result("等额本息月供", value: loanResult)
                        }
                    case .discount:
                        ToolCard {
                            Field("原价", text: $price)
                            Field("折扣", text: $discount)
                            Result("折后价", value: money((Double(price) ?? 0) * (Double(discount) ?? 0) / 10))
                        }
                    case .tax:
                        ToolCard {
                            Field("税前金额", text: $taxBase)
                            Field("税率 %", text: $taxRate)
                            Result("含税金额", value: money((Double(taxBase) ?? 0) * (1 + (Double(taxRate) ?? 0) / 100)))
                        }
                    }
                }
                .padding(.horizontal, wide ? 70 : 24)
                .padding(.bottom, 50)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .background(Color.black)
        }
    }

    private var unitResult: String {
        let value = Double(unitValue) ?? 0
        let meters = value * fromUnit.multiplier
        return "\(short(meters / toUnit.multiplier)) \(toUnit.symbol)"
    }

    private var loanResult: String {
        let principal = Double(loan) ?? 0
        let months = (Double(years) ?? 0) * 12
        let monthlyRate = (Double(rate) ?? 0) / 100 / 12
        guard principal > 0, months > 0 else { return "无法计算" }
        if monthlyRate == 0 { return money(principal / months) }
        let factor = pow(1 + monthlyRate, months)
        return money(principal * monthlyRate * factor / (factor - 1))
    }

    private func short(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "-"
    }

    private func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "-"
    }
}

enum Tool: String, CaseIterable, Identifiable {
    case unit, loan, discount, tax
    var id: String { rawValue }
    var title: String {
        switch self {
        case .unit: return "换算"
        case .loan: return "房贷"
        case .discount: return "折扣"
        case .tax: return "税费"
        }
    }
}

enum UnitChoice: String, CaseIterable, Identifiable {
    case millimeter, centimeter, meter, kilometer, inch, foot
    var id: String { rawValue }
    var name: String {
        switch self {
        case .millimeter: return "毫米"
        case .centimeter: return "厘米"
        case .meter: return "米"
        case .kilometer: return "千米"
        case .inch: return "英寸"
        case .foot: return "英尺"
        }
    }
    var symbol: String {
        switch self {
        case .millimeter: return "mm"
        case .centimeter: return "cm"
        case .meter: return "m"
        case .kilometer: return "km"
        case .inch: return "in"
        case .foot: return "ft"
        }
    }
    var multiplier: Double {
        switch self {
        case .millimeter: return 0.001
        case .centimeter: return 0.01
        case .meter: return 1
        case .kilometer: return 1000
        case .inch: return 0.0254
        case .foot: return 0.3048
        }
    }
}

struct ToolCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 18) { content }
            .padding(18)
            .background(Color(red: 0.10, green: 0.10, blue: 0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct Field: View {
    let title: String
    @Binding var text: String
    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.58))
            TextField(title, text: $text)
                .keyboardType(.decimalPad)
                .font(.system(size: 30, weight: .regular, design: .rounded))
                .foregroundStyle(.white)
                .padding(14)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

struct UnitMenu: View {
    let title: String
    @Binding var selection: UnitChoice
    init(_ title: String, selection: Binding<UnitChoice>) {
        self.title = title
        self._selection = selection
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.58))
            Picker(title, selection: $selection) {
                ForEach(UnitChoice.allCases) { Text($0.name).tag($0) }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .tint(.white)
        }
    }
}

struct Result: View {
    let title: String
    let value: String
    init(_ title: String, value: String) {
        self.title = title
        self.value = value
    }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
        }
    }
}
