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

enum CalculatorMode: String, CaseIterable {
    case basic = "基础"
    case science = "科学"
    case notes = "数学笔记"
    case convert = "转换"
}

struct CalculatorRootView: View {
    @StateObject private var engine = CalculatorEngine()
    @State private var showTools = false
    @State private var mode: CalculatorMode = .basic

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                HStack(spacing: 0) {
                    CalculatorView(engine: engine, mode: $mode, showTools: $showTools)
                        .frame(width: proxy.size.width)
                    ToolsView(showTools: $showTools)
                        .frame(width: proxy.size.width)
                }
                .offset(x: showTools ? -proxy.size.width : 0)
                .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.88), value: showTools)
                .gesture(
                    DragGesture(minimumDistance: 28)
                        .onEnded { value in
                            if value.translation.width < -70 { showTools = true }
                            if value.translation.width > 70 { showTools = false }
                        }
                )
            }
        }
    }
}

struct CalculatorView: View {
    @ObservedObject var engine: CalculatorEngine
    @Binding var mode: CalculatorMode
    @Binding var showTools: Bool

    private let basicPortrait: [[CalcKey]] = [
        [.backspace, .clear, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .minus],
        [.one, .two, .three, .plus],
        [.sign, .zero, .dot, .equals]
    ]

    private let basicLandscape: [[CalcKey]] = [
        [.seven, .eight, .nine, .backspace, .divide],
        [.four, .five, .six, .clear, .multiply],
        [.one, .two, .three, .percent, .minus],
        [.sign, .zero, .dot, .equals, .plus]
    ]

    private let sciencePortrait: [[CalcKey]] = [
        [.leftParen, .rightParen, .memoryClear, .memoryPlus],
        [.second, .square, .cube, .power],
        [.reciprocal, .sqrt, .cubeRoot, .root],
        [.factorial, .sin, .cos, .tan],
        [.random, .sinh, .cosh, .tanh],
        [.backspace, .clear, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .minus],
        [.one, .two, .three, .plus],
        [.sign, .zero, .dot, .equals]
    ]

    private let scienceLandscape: [[CalcKey]] = [
        [.leftParen, .rightParen, .memoryClear, .memoryPlus, .memoryMinus, .memoryRecall, .backspace, .clear, .percent, .divide],
        [.second, .square, .cube, .power, .exp, .pow10, .seven, .eight, .nine, .multiply],
        [.reciprocal, .sqrt, .cubeRoot, .root, .ln, .log10, .four, .five, .six, .minus],
        [.factorial, .sin, .cos, .tan, .e, .ee, .one, .two, .three, .plus],
        [.random, .sinh, .cosh, .tanh, .pi, .degree, .sign, .zero, .dot, .equals]
    ]

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width > proxy.size.height
            let science = mode == .science
            let rows = science ? (wide ? scienceLandscape : sciencePortrait) : (wide ? basicLandscape : basicPortrait)
            let columns = rows.first?.count ?? 4
            let outer: CGFloat = wide ? 74 : 38
            let gap: CGFloat = wide ? 18 : 16
            let displayBase: CGFloat = wide ? 118 : (science ? 118 : 260)
            let keyHeight: CGFloat = science ? (wide ? 70 : 76) : (wide ? 112 : 96)
            let topInset: CGFloat = wide ? 56 : 82

            VStack(spacing: 0) {
                topBar(wide: wide)
                    .padding(.horizontal, outer)
                    .padding(.top, topInset)

                Spacer(minLength: wide ? 16 : 28)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(engine.expression.isEmpty ? " " : engine.expression)
                        .font(.system(size: wide ? 26 : 28, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.42))
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)
                    Text(engine.display)
                        .font(.system(size: wide ? 76 : 92, weight: .light, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.22)
                }
                .frame(maxWidth: .infinity, minHeight: displayBase, alignment: .bottomTrailing)
                .padding(.horizontal, outer)

                if science { Text("Rad").font(.system(size: 24)).foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, outer).padding(.bottom, 10) }

                VStack(spacing: gap) {
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        HStack(spacing: gap) {
                            ForEach(rows[rowIndex]) { key in
                                Button { tap(key) } label: {
                                    KeyLabel(key: key, science: science)
                                        .frame(maxWidth: .infinity, minHeight: keyHeight, maxHeight: keyHeight)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, outer)
                .padding(.bottom, wide ? 34 : 38)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: mode) { newMode in
                if newMode == .convert { showTools = true }
            }
        }
    }

    private func topBar(wide: Bool) -> some View {
        HStack {
            RoundIconButton(systemName: "clock", size: wide ? 56 : 58) { }
            Spacer()
            Menu {
                Button { mode = .basic; showTools = false } label: { Label("基础", systemImage: "plus.slash.minus") }
                Button { mode = .science; showTools = false } label: { Label("科学", systemImage: "function") }
                Button { mode = .notes; showTools = false } label: { Label("数学笔记", systemImage: "pencil.and.outline") }
                Divider()
                Button { mode = .convert; showTools = true } label: { Label("转换", systemImage: "arrow.left.arrow.right") }
            } label: {
                RoundIconButtonContent(systemName: "square.grid.2x2", size: wide ? 56 : 58)
            }
        }
    }

    private func tap(_ key: CalcKey) {
        if key == .degree { return }
        engine.tap(key)
    }
}

struct KeyLabel: View {
    let key: CalcKey
    let science: Bool

    var body: some View {
        Text(key.title)
            .font(.system(size: fontSize, weight: .regular, design: .rounded))
            .foregroundStyle(key.foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(key.background, in: RoundedRectangle(cornerRadius: science ? 26 : 44, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: science ? 26 : 44, style: .continuous).stroke(.white.opacity(0.05), lineWidth: 1))
    }

    private var fontSize: CGFloat {
        if science { return key.smallText ? 24 : 28 }
        return key.smallText ? 34 : 42
    }
}

struct RoundIconButton: View {
    let systemName: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) { RoundIconButtonContent(systemName: systemName, size: size) }
            .buttonStyle(.plain)
    }
}

struct RoundIconButtonContent: View {
    let systemName: String
    let size: CGFloat

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.white.opacity(0.13), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.08), lineWidth: 1))
    }
}

enum CalcKey: String, Identifiable, Hashable {
    case clear = "AC", sign = "+/-", percent = "%"
    case divide = "÷", multiply = "×", minus = "−", plus = "+", equals = "="
    case dot = ".", backspace = "⌫"
    case zero = "0", one = "1", two = "2", three = "3", four = "4", five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case leftParen = "(", rightParen = ")", memoryClear = "mc", memoryPlus = "m+", memoryMinus = "m−", memoryRecall = "mr"
    case second = "2ⁿᵈ", square = "x²", cube = "x³", power = "xʸ", exp = "eˣ", pow10 = "10ˣ"
    case reciprocal = "1/x", sqrt = "²√x", cubeRoot = "³√x", root = "ʸ√x", ln = "ln", log10 = "log₁₀"
    case factorial = "x!", sin = "sin", cos = "cos", tan = "tan", e = "e", ee = "EE"
    case random = "Rand", sinh = "sinh", cosh = "cosh", tanh = "tanh", pi = "π", degree = "Deg"

    var id: String { rawValue }
    var title: String { rawValue }
    var number: String? {
        switch self {
        case .zero: return "0"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        default: return nil
        }
    }

    var background: Color {
        switch self {
        case .divide, .multiply, .minus, .plus, .equals:
            return Color(red: 1.0, green: 0.58, blue: 0.02)
        case .clear, .percent, .backspace, .memoryRecall:
            return Color(red: 0.42, green: 0.42, blue: 0.43)
        default:
            return Color(red: 0.18, green: 0.18, blue: 0.18)
        }
    }

    var foreground: Color { .white }
    var smallText: Bool { title.count > 2 || self == .backspace || self == .sign }
}

final class CalculatorEngine: ObservableObject {
    @Published var display = "0"
    @Published var expression = ""

    private var stored: Double?
    private var pending: CalcKey?
    private var entering = false
    private var memory: Double = 0

    func tap(_ key: CalcKey) {
        if let number = key.number { input(number); return }
        switch key {
        case .clear: clear()
        case .dot: dot()
        case .backspace: backspace()
        case .sign: unary("neg") { -$0 }
        case .percent: unary("%") { $0 / 100 }
        case .divide, .multiply, .minus, .plus, .power: setOperator(key)
        case .equals: equals()
        case .sqrt: unary("√") { $0 < 0 ? .nan : sqrt($0) }
        case .cubeRoot: unary("³√") { $0 < 0 ? -pow(-$0, 1.0 / 3.0) : pow($0, 1.0 / 3.0) }
        case .square: unary("x²") { $0 * $0 }
        case .cube: unary("x³") { $0 * $0 * $0 }
        case .reciprocal: unary("1/x") { $0 == 0 ? .nan : 1 / $0 }
        case .sin: unary("sin") { sin($0) }
        case .cos: unary("cos") { cos($0) }
        case .tan: unary("tan") { tan($0) }
        case .sinh: unary("sinh") { Foundation.sinh($0) }
        case .cosh: unary("cosh") { Foundation.cosh($0) }
        case .tanh: unary("tanh") { Foundation.tanh($0) }
        case .ln: unary("ln") { $0 <= 0 ? .nan : log($0) }
        case .log10: unary("log") { $0 <= 0 ? .nan : log10($0) }
        case .exp: unary("eˣ") { Foundation.exp($0) }
        case .pow10: unary("10ˣ") { pow(10, $0) }
        case .factorial: unary("x!") { factorial($0) }
        case .pi: setImmediate(Double.pi, expression: "π")
        case .e: setImmediate(M_E, expression: "e")
        case .random: setImmediate(Double.random(in: 0..<1), expression: "Rand")
        case .memoryClear: memory = 0
        case .memoryPlus: memory += current
        case .memoryMinus: memory -= current
        case .memoryRecall: setImmediate(memory, expression: "mr")
        default: break
        }
    }

    private func input(_ number: String) {
        if !entering || display == "0" || display == "错误" {
            display = number
            entering = true
        } else {
            display = grouped(raw + number)
        }
    }

    private func dot() {
        if !entering || display == "错误" { display = "0."; entering = true; return }
        if !raw.contains(".") { display = raw + "." }
    }

    private func backspace() {
        guard entering, display != "错误" else { clear(); return }
        var value = raw
        value.removeLast()
        display = value.isEmpty || value == "-" ? "0" : grouped(value)
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
        let rhs = current
        let result = apply(op, base, rhs)
        expression = "\(clean(base)) \(op.title) \(clean(rhs))"
        pending = nil
        stored = result.isFinite ? result : nil
        entering = false
        display = clean(result)
    }

    private func unary(_ label: String, _ transform: (Double) -> Double) {
        let value = current
        let result = transform(value)
        expression = "\(label)(\(clean(value)))"
        display = clean(result)
        entering = true
    }

    private func setImmediate(_ value: Double, expression: String) {
        self.expression = expression
        display = clean(value)
        entering = true
    }

    private func clear() {
        display = "0"
        expression = ""
        stored = nil
        pending = nil
        entering = false
    }

    private var raw: String { display.replacingOccurrences(of: ",", with: "") }
    private var current: Double { Double(raw) ?? 0 }

    private func apply(_ op: CalcKey, _ lhs: Double, _ rhs: Double) -> Double {
        switch op {
        case .plus: return lhs + rhs
        case .minus: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide: return rhs == 0 ? .nan : lhs / rhs
        case .power: return pow(lhs, rhs)
        default: return rhs
        }
    }

    private func factorial(_ value: Double) -> Double {
        guard value >= 0, value <= 170, value.rounded() == value else { return .nan }
        if value == 0 { return 1 }
        return (1...Int(value)).map(Double.init).reduce(1, *)
    }

    private func clean(_ value: Double) -> String {
        if !value.isFinite { return "错误" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func grouped(_ value: String) -> String {
        if value.hasSuffix(".") { return clean(Double(value.dropLast()) ?? 0) + "." }
        return clean(Double(value) ?? 0)
    }
}

struct ToolsView: View {
    @Binding var showTools: Bool
    @State private var selected: ToolKind = .length
    @State private var value = "1"
    @State private var from: LengthUnit = .meter
    @State private var to: LengthUnit = .kilometer

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 26)]

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width > proxy.size.height
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack {
                        Button { showTools = false } label: { RoundIconButtonContent(systemName: "chevron.left", size: 54) }
                            .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, wide ? 48 : 70)

                    Text("更多")
                        .font(.system(size: wide ? 58 : 64, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(ToolKind.allCases) { item in
                            Button { selected = item } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: item.symbol)
                                        .font(.system(size: 28, weight: .semibold))
                                    Text(item.title)
                                        .font(.system(size: 18, weight: .medium))
                                }
                                .foregroundStyle(selected == item ? .black : .white)
                                .frame(maxWidth: .infinity, minHeight: 104)
                                .background(selected == item ? Color.white.opacity(0.86) : Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    conversionCard
                }
                .padding(.horizontal, wide ? 78 : 28)
                .padding(.bottom, 54)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
        }
    }

    private var conversionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(selected.title)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            if selected == .length {
                Field("数值", text: $value)
                HStack(spacing: 14) {
                    LengthMenu("从", selection: $from)
                    LengthMenu("到", selection: $to)
                }
                Result("结果", value: lengthResult)
            } else {
                Result("状态", value: "已加入入口")
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var lengthResult: String {
        let meters = (Double(value) ?? 0) * from.meters
        return "\(short(meters / to.meters)) \(to.symbol)"
    }

    private func short(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 8
        return formatter.string(from: NSNumber(value: value)) ?? "-"
    }
}

enum ToolKind: String, CaseIterable, Identifiable {
    case currency, length, weight, area, tax, loan, people, uppercase, time, volume, base, temperature, speed, bmi
    var id: String { rawValue }
    var title: String {
        switch self {
        case .currency: return "汇率转换"
        case .length: return "长度转换"
        case .weight: return "重量转换"
        case .area: return "面积转换"
        case .tax: return "个税计算"
        case .loan: return "房贷计算"
        case .people: return "称呼计算"
        case .uppercase: return "大写数字"
        case .time: return "时间转换"
        case .volume: return "体积转换"
        case .base: return "进制转换"
        case .temperature: return "温度转换"
        case .speed: return "速度转换"
        case .bmi: return "BMI 计算"
        }
    }
    var symbol: String {
        switch self {
        case .currency: return "yensign.circle"
        case .length: return "ruler"
        case .weight: return "scalemass"
        case .area: return "square.dashed"
        case .tax: return "doc.text"
        case .loan: return "house"
        case .people: return "person.2"
        case .uppercase: return "textformat.123"
        case .time: return "clock"
        case .volume: return "cube"
        case .base: return "number.square"
        case .temperature: return "thermometer"
        case .speed: return "speedometer"
        case .bmi: return "figure.stand"
        }
    }
}

enum LengthUnit: String, CaseIterable, Identifiable {
    case millimeter, centimeter, meter, kilometer, inch, foot, mile, nauticalMile
    var id: String { rawValue }
    var title: String {
        switch self {
        case .millimeter: return "毫米"
        case .centimeter: return "厘米"
        case .meter: return "米"
        case .kilometer: return "千米"
        case .inch: return "英寸"
        case .foot: return "英尺"
        case .mile: return "英里"
        case .nauticalMile: return "海里"
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
        case .mile: return "mi"
        case .nauticalMile: return "nmi"
        }
    }
    var meters: Double {
        switch self {
        case .millimeter: return 0.001
        case .centimeter: return 0.01
        case .meter: return 1
        case .kilometer: return 1000
        case .inch: return 0.0254
        case .foot: return 0.3048
        case .mile: return 1609.344
        case .nauticalMile: return 1852
        }
    }
}

struct Field: View {
    let title: String
    @Binding var text: String
    init(_ title: String, text: Binding<String>) { self.title = title; self._text = text }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(.white.opacity(0.58))
            TextField(title, text: $text)
                .keyboardType(.decimalPad)
                .font(.system(size: 30, weight: .regular, design: .rounded))
                .foregroundStyle(.white)
                .padding(14)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

struct LengthMenu: View {
    let title: String
    @Binding var selection: LengthUnit
    init(_ title: String, selection: Binding<LengthUnit>) { self.title = title; self._selection = selection }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(.white.opacity(0.58))
            Picker(title, selection: $selection) {
                ForEach(LengthUnit.allCases) { Text($0.title).tag($0) }
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
    init(_ title: String, value: String) { self.title = title; self.value = value }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(size: 17, weight: .medium)).foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
        }
    }
}
