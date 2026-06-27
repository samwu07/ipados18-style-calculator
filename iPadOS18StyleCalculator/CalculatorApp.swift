import SwiftUI

@main struct CalculatorApp: App { var body: some Scene { WindowGroup { CalculatorRootView().preferredColorScheme(.dark) } } }

enum Mode: String { case basic = "基础", science = "科学", notes = "数学笔记", convert = "转换" }

struct CalculatorRootView: View {
    @StateObject private var engine = CalculatorEngine()
    @State private var tools = false
    @State private var mode: Mode = .basic
    var body: some View {
        GeometryReader { g in
            HStack(spacing: 0) {
                CalculatorView(engine: engine, mode: $mode, tools: $tools).frame(width: g.size.width)
                ToolsView(tools: $tools).frame(width: g.size.width)
            }
            .offset(x: tools ? -g.size.width : 0)
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.88), value: tools)
            .gesture(DragGesture(minimumDistance: 28).onEnded { v in
                if v.translation.width < -70 { tools = true }
                if v.translation.width > 70 { tools = false }
            })
            .background(Color.black.ignoresSafeArea())
        }
    }
}

struct CalculatorView: View {
    @ObservedObject var engine: CalculatorEngine
    @Binding var mode: Mode
    @Binding var tools: Bool

    let basicP: [[K]] = [[.bs,.ac,.pct,.div],[.n7,.n8,.n9,.mul],[.n4,.n5,.n6,.sub],[.n1,.n2,.n3,.add],[.sign,.n0,.dot,.eq]]
    let basicL: [[K]] = [[.n7,.n8,.n9,.bs,.div],[.n4,.n5,.n6,.ac,.mul],[.n1,.n2,.n3,.pct,.sub],[.sign,.n0,.dot,.eq,.add]]
    let sciP: [[K]] = [[.lp,.rp,.mc,.mp],[.sec,.sq,.cube,.pow],[.rec,.sqrt,.cbrt,.root],[.fact,.sin,.cos,.tan],[.rand,.sinh,.cosh,.tanh],[.bs,.ac,.pct,.div],[.n7,.n8,.n9,.mul],[.n4,.n5,.n6,.sub],[.n1,.n2,.n3,.add],[.sign,.n0,.dot,.eq]]
    let sciL: [[K]] = [[.lp,.rp,.mc,.mp,.mm,.mr,.bs,.ac,.pct,.div],[.sec,.sq,.cube,.pow,.exp,.pow10,.n7,.n8,.n9,.mul],[.rec,.sqrt,.cbrt,.root,.ln,.log10,.n4,.n5,.n6,.sub],[.fact,.sin,.cos,.tan,.e,.ee,.n1,.n2,.n3,.add],[.rand,.sinh,.cosh,.tanh,.pi,.deg,.sign,.n0,.dot,.eq]]

    var body: some View {
        GeometryReader { g in
            let wide = g.size.width > g.size.height
            let narrow = g.size.width < 700
            let sci = mode == .science
            let rows = sci ? (wide ? sciL : sciP) : (wide ? basicL : basicP)
            let outer = max(narrow ? 26.0 : 62.0, min(wide ? 74.0 : 38.0, g.size.width * 0.075))
            let gap = max(10.0, min(wide ? 18.0 : 16.0, g.size.width * 0.018))
            let top = max(wide ? 40.0 : 54.0, min(wide ? 56.0 : 82.0, g.size.height * 0.075))
            let displayH = displayHeight(g.size, sci, wide, narrow)
            let keyH = keyHeight(g.size, rows.count, displayH, top, gap, sci, wide, narrow)
            let scroll = sci && (!wide || g.size.height < 780)
            VStack(spacing: 0) {
                topBar(wide).padding(.horizontal, outer).padding(.top, top)
                Spacer(minLength: wide ? 8 : 12)
                VStack(alignment: .trailing, spacing: 8) {
                    Text(engine.expr.isEmpty ? " " : engine.expr).font(.system(size: wide ? 25 : 26, design: .rounded)).foregroundStyle(.white.opacity(0.42)).lineLimit(1).minimumScaleFactor(0.45)
                    Text(engine.display).font(.system(size: wide ? 76 : 86, weight: .light, design: .rounded)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.22)
                }.frame(maxWidth: .infinity, minHeight: displayH, alignment: .bottomTrailing).padding(.horizontal, outer)
                if sci { Text("Rad").font(.system(size: wide ? 24 : 22)).foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, outer).padding(.bottom, 8) }
                if scroll {
                    ScrollView(.vertical, showsIndicators: false) { pad(rows, max(58, min(keyH, 76)), gap, sci).padding(.horizontal, outer).padding(.bottom, 28) }
                } else {
                    pad(rows, keyH, gap, sci).padding(.horizontal, outer).padding(.bottom, wide ? 28 : 28)
                }
            }
        }
    }

    func displayHeight(_ s: CGSize, _ sci: Bool, _ wide: Bool, _ narrow: Bool) -> CGFloat {
        if wide { return max(86, min(132, s.height * 0.20)) }
        if sci { return max(70, min(120, s.height * 0.12)) }
        return max(narrow ? 120 : 160, min(narrow ? 190 : 250, s.height * (narrow ? 0.19 : 0.27)))
    }
    func keyHeight(_ s: CGSize, _ rows: Int, _ display: CGFloat, _ top: CGFloat, _ gap: CGFloat, _ sci: Bool, _ wide: Bool, _ narrow: Bool) -> CGFloat {
        let reserved = top + display + (sci ? 38 : 10) + 34 + CGFloat(max(rows - 1, 0)) * gap
        let available = max(44, (s.height - reserved) / CGFloat(rows))
        let ideal: CGFloat = sci ? (wide ? 70 : 76) : (wide ? (narrow ? 78 : 112) : (narrow ? 78 : 96))
        return max(sci ? 54 : 58, min(ideal, available))
    }
    func pad(_ rows: [[K]], _ h: CGFloat, _ gap: CGFloat, _ sci: Bool) -> some View {
        VStack(spacing: gap) { ForEach(rows.indices, id: \.self) { r in HStack(spacing: gap) { ForEach(rows[r]) { k in Button { engine.tap(k) } label: { KeyView(k: k, sci: sci).frame(maxWidth: .infinity, minHeight: h, maxHeight: h) }.buttonStyle(.plain) } } } }
    }
    func topBar(_ wide: Bool) -> some View {
        HStack { RoundIcon(systemName: "clock", size: wide ? 56 : 58) {}; Spacer(); Menu {
            Button { mode = .basic; tools = false } label: { Label("基础", systemImage: "plus.slash.minus") }
            Button { mode = .science; tools = false } label: { Label("科学", systemImage: "function") }
            Button { mode = .notes; tools = false } label: { Label("数学笔记", systemImage: "pencil.and.outline") }
            Divider(); Button { mode = .convert; tools = true } label: { Label("转换", systemImage: "arrow.left.arrow.right") }
        } label: { RoundIconContent(systemName: "square.grid.2x2", size: wide ? 56 : 58) } }
    }
}

struct KeyView: View { let k: K; let sci: Bool; var body: some View { Text(k.t).font(.system(size: sci ? (k.small ? 22 : 28) : (k.small ? 32 : 42), design: .rounded)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.55).frame(maxWidth: .infinity, maxHeight: .infinity).background(k.bg, in: RoundedRectangle(cornerRadius: sci ? 24 : 42, style: .continuous)).overlay(RoundedRectangle(cornerRadius: sci ? 24 : 42, style: .continuous).stroke(.white.opacity(0.05), lineWidth: 1)) } }
struct RoundIcon: View { let systemName: String; let size: CGFloat; let action: () -> Void; var body: some View { Button(action: action) { RoundIconContent(systemName: systemName, size: size) }.buttonStyle(.plain) } }
struct RoundIconContent: View { let systemName: String; let size: CGFloat; var body: some View { Image(systemName: systemName).font(.system(size: size * 0.42, weight: .medium)).foregroundStyle(.white).frame(width: size, height: size).background(Color.white.opacity(0.13), in: Circle()).overlay(Circle().stroke(.white.opacity(0.08), lineWidth: 1)) } }

enum K: String, Identifiable { case ac="AC", sign="+/-", pct="%", div="÷", mul="×", sub="−", add="+", eq="=", dot=".", bs="⌫", n0="0", n1="1", n2="2", n3="3", n4="4", n5="5", n6="6", n7="7", n8="8", n9="9", lp="(", rp=")", mc="mc", mp="m+", mm="m−", mr="mr", sec="2ⁿᵈ", sq="x²", cube="x³", pow="xʸ", exp="eˣ", pow10="10ˣ", rec="1/x", sqrt="²√x", cbrt="³√x", root="ʸ√x", ln="ln", log10="log₁₀", fact="x!", sin="sin", cos="cos", tan="tan", e="e", ee="EE", rand="Rand", sinh="sinh", cosh="cosh", tanh="tanh", pi="π", deg="Deg"; var id: String { rawValue }; var t: String { rawValue }; var num: String? { rawValue.count == 1 && "0123456789".contains(rawValue) ? rawValue : nil }; var bg: Color { [.div,.mul,.sub,.add,.eq].contains(self) ? Color(red:1,green:0.58,blue:0.02) : ([.ac,.pct,.bs,.mr].contains(self) ? Color(red:0.42,green:0.42,blue:0.43) : Color(red:0.18,green:0.18,blue:0.18)) }; var small: Bool { t.count > 2 || self == .bs || self == .sign } }

final class CalculatorEngine: ObservableObject {
    @Published var display = "0"; @Published var expr = ""; private var stored: Double?; private var pending: K?; private var entering = false; private var mem = 0.0
    var raw: String { display.replacingOccurrences(of: ",", with: "") }; var cur: Double { Double(raw) ?? 0 }
    func tap(_ k: K) { if let n = k.num { input(n); return }; switch k { case .ac: clear(); case .dot: dot(); case .bs: back(); case .sign: unary("neg") { -$0 }; case .pct: unary("%") { $0/100 }; case .div,.mul,.sub,.add,.pow: op(k); case .eq: equals(); case .sqrt: unary("√") { $0 < 0 ? .nan : sqrt($0) }; case .cbrt: unary("³√") { $0 < 0 ? -Foundation.pow(-$0, 1/3) : Foundation.pow($0, 1/3) }; case .sq: unary("x²") { $0*$0 }; case .cube: unary("x³") { $0*$0*$0 }; case .rec: unary("1/x") { $0 == 0 ? .nan : 1/$0 }; case .sin: unary("sin") { sin($0) }; case .cos: unary("cos") { cos($0) }; case .tan: unary("tan") { tan($0) }; case .sinh: unary("sinh") { Foundation.sinh($0) }; case .cosh: unary("cosh") { Foundation.cosh($0) }; case .tanh: unary("tanh") { Foundation.tanh($0) }; case .ln: unary("ln") { $0 <= 0 ? .nan : log($0) }; case .log10: unary("log") { $0 <= 0 ? .nan : log10($0) }; case .exp: unary("eˣ") { Foundation.exp($0) }; case .pow10: unary("10ˣ") { Foundation.pow(10,$0) }; case .fact: unary("x!") { fact($0) }; case .pi: set(Double.pi,"π"); case .e: set(Foundation.exp(1),"e"); case .rand: set(Double.random(in: 0..<1),"Rand"); case .mc: mem = 0; case .mp: mem += cur; case .mm: mem -= cur; case .mr: set(mem,"mr"); default: break } }
    func input(_ n: String) { display = (!entering || display == "0" || display == "错误") ? n : group(raw+n); entering = true }
    func dot() { if !entering || display == "错误" { display="0."; entering=true } else if !raw.contains(".") { display=raw+"." } }
    func back() { guard entering, display != "错误" else { clear(); return }; var v=raw; v.removeLast(); display = v.isEmpty || v == "-" ? "0" : group(v) }
    func op(_ k: K) { if let p=pending, let s=stored, entering { stored=apply(p,s,cur); display=clean(stored ?? 0) } else { stored=cur }; pending=k; entering=false; expr="\(clean(stored ?? 0)) \(k.t)" }
    func equals() { guard let p=pending, let s=stored else { return }; let r=cur, ans=apply(p,s,r); expr="\(clean(s)) \(p.t) \(clean(r))"; pending=nil; stored=ans.isFinite ? ans:nil; entering=false; display=clean(ans) }
    func unary(_ name: String, _ f: (Double)->Double) { let v=cur, r=f(v); expr="\(name)(\(clean(v)))"; display=clean(r); entering=true }
    func set(_ v: Double, _ e: String) { expr=e; display=clean(v); entering=true }
    func clear() { display="0"; expr=""; stored=nil; pending=nil; entering=false }
    func apply(_ k: K,_ a: Double,_ b: Double) -> Double { switch k { case .add: return a+b; case .sub: return a-b; case .mul: return a*b; case .div: return b == 0 ? .nan : a/b; case .pow: return Foundation.pow(a,b); default: return b } }
    func fact(_ v: Double) -> Double { guard v >= 0, v <= 170, v.rounded() == v else { return .nan }; return v == 0 ? 1 : (1...Int(v)).map(Double.init).reduce(1,*) }
    func clean(_ v: Double) -> String { if !v.isFinite { return "错误" }; let f=NumberFormatter(); f.numberStyle=.decimal; f.usesGroupingSeparator=true; f.groupingSeparator=","; f.maximumFractionDigits=10; return f.string(from:NSNumber(value:v)) ?? "\(v)" }
    func group(_ s: String) -> String { s.hasSuffix(".") ? clean(Double(s.dropLast()) ?? 0)+"." : clean(Double(s) ?? 0) }
}

struct ToolsView: View {
    @Binding var tools: Bool; @State private var tool: Tool = .length; @State private var a="1"; @State private var b="1"; @State private var from=0; @State private var to=1
    let cols=[GridItem(.adaptive(minimum:118),spacing:22)]
    var body: some View { GeometryReader { g in let wide=g.size.width>g.size.height; ScrollView { VStack(alignment:.leading,spacing:24) { HStack { Button { tools=false } label:{ RoundIconContent(systemName:"chevron.left",size:54) }.buttonStyle(.plain); Spacer() }.padding(.top,wide ? 46:64); Text("更多").font(.system(size:wide ? 54:60,weight:.semibold,design:.rounded)).foregroundStyle(.white); LazyVGrid(columns:cols,spacing:24){ ForEach(Tool.allCases){ x in Button{ tool=x; from=0; to=min(1,x.units.count-1) } label:{ VStack(spacing:10){ Image(systemName:x.icon).font(.system(size:27,weight:.semibold)); Text(x.title).font(.system(size:17,weight:.medium)).multilineTextAlignment(.center) }.foregroundStyle(tool==x ? .black:.white).frame(maxWidth:.infinity,minHeight:100).background(tool==x ? Color.white.opacity(0.86):Color.white.opacity(0.10),in:RoundedRectangle(cornerRadius:8,style:.continuous)) }.buttonStyle(.plain) } }; card }.padding(.horizontal,wide ? 76:28).padding(.bottom,54).frame(minHeight:g.size.height,alignment:.top) }.background(Color.black) } }
    var card: some View { VStack(alignment:.leading,spacing:18){ Text(tool.title).font(.system(size:26,weight:.semibold,design:.rounded)).foregroundStyle(.white); switch tool.kind { case .unit: Field(tool == .base ? "数值" : "数值", text:$a); HStack(spacing:14){ MenuPick("从",tool.units,$from); MenuPick("到",tool.units,$to) }; Result("结果", value: unitResult); case .bmi: Field("体重 kg",text:$a); Field("身高 cm",text:$b); Result("BMI",value:bmi); case .loan: Field("贷款金额",text:$a); Field("年利率 %",text:$b); Result("30年月供",value:loan); case .tax: Field("税前金额",text:$a); Field("税率 %",text:$b); Result("含税金额",value:money(num(a)*(1+num(b)/100))); case .discount: Field("原价",text:$a); Field("折扣",text:$b); Result("折后价",value:money(num(a)*num(b)/10)); case .upper: Field("数字",text:$a); Result("大写",value:upper(Int(num(a)))) } }.padding(20).background(Color.white.opacity(0.09),in:RoundedRectangle(cornerRadius:8,style:.continuous)) }
    var unitResult: String { if tool == .temperature { return "\(short(temp(num(a)))) \(tool.units[safe:to]?.symbol ?? "")" }; if tool == .base { return base(a) }; let f=tool.units[safe:from] ?? tool.units[0], t=tool.units[safe:to] ?? tool.units[0]; return "\(short(num(a)*f.factor/t.factor)) \(t.symbol)" }
    func temp(_ v: Double)->Double{ let f=tool.units[safe:from]?.symbol ?? "C", t=tool.units[safe:to]?.symbol ?? "F"; let c = f=="F" ? (v-32)*5/9 : (f=="K" ? v-273.15:v); return t=="F" ? c*9/5+32 : (t=="K" ? c+273.15:c) }
    func base(_ s:String)->String{ let f=Int(tool.units[safe:from]?.factor ?? 10), t=Int(tool.units[safe:to]?.factor ?? 2); guard let v=Int(s.trimmingCharacters(in:.whitespacesAndNewlines),radix:f) else { return "无法转换" }; return String(v,radix:t).uppercased() }
    var bmi:String{ let w=num(a), m=num(b)/100; return w>0 && m>0 ? short(w/(m*m)) : "无法计算" }
    var loan:String{ let p=num(a), r=num(b)/100/12, m=360.0; guard p>0 else { return "无法计算" }; if r==0 { return money(p/m) }; let f=Foundation.pow(1+r,m); return money(p*r*f/(f-1)) }
    func num(_ s:String)->Double{ Double(s.replacingOccurrences(of:",",with:"")) ?? 0 }
    func short(_ v:Double)->String{ let f=NumberFormatter(); f.numberStyle=.decimal; f.usesGroupingSeparator=true; f.maximumFractionDigits=8; return f.string(from:NSNumber(value:v)) ?? "-" }
    func money(_ v:Double)->String{ let f=NumberFormatter(); f.numberStyle=.decimal; f.usesGroupingSeparator=true; f.maximumFractionDigits=2; f.minimumFractionDigits=2; return f.string(from:NSNumber(value:v)) ?? "-" }
    func upper(_ v:Int)->String{ let d=["零","壹","贰","叁","肆","伍","陆","柒","捌","玖"], u=["","拾","佰","仟","万","拾","佰","仟","亿"]; let cs=Array(String(max(0,v))).compactMap{Int(String($0))}; var r=""; for (i,x) in cs.enumerated(){ let ui=cs.count-i-1; r += d[x] + (x==0 ? "" : u[min(ui,u.count-1)]) }; while r.contains("零零"){ r=r.replacingOccurrences(of:"零零",with:"零") }; r=r.trimmingCharacters(in:CharacterSet(charactersIn:"零")); return r.isEmpty ? "零" : r }
}

enum Tool:String,CaseIterable,Identifiable{ case length,weight,area,volume,temperature,speed,time,base,bmi,loan,tax,discount,upper; var id:String{rawValue}; enum Kind{case unit,bmi,loan,tax,discount,upper}; var kind:Kind{ switch self{case .bmi:return .bmi; case .loan:return .loan; case .tax:return .tax; case .discount:return .discount; case .upper:return .upper; default:return .unit} }; var title:String{ [ .length:"长度转换",.weight:"重量转换",.area:"面积转换",.volume:"体积转换",.temperature:"温度转换",.speed:"速度转换",.time:"时间转换",.base:"进制转换",.bmi:"BMI 计算",.loan:"房贷计算",.tax:"税费计算",.discount:"折扣计算",.upper:"大写数字" ][self]! }; var icon:String{ [ .length:"ruler",.weight:"scalemass",.area:"square.dashed",.volume:"cube",.temperature:"thermometer",.speed:"speedometer",.time:"clock",.base:"number.square",.bmi:"figure.stand",.loan:"house",.tax:"doc.text",.discount:"tag",.upper:"textformat.123" ][self]! }; var units:[U]{ switch self{case .length:return [U("毫米","mm",0.001),U("厘米","cm",0.01),U("米","m",1),U("千米","km",1000),U("英寸","in",0.0254),U("英尺","ft",0.3048),U("英里","mi",1609.344),U("海里","nmi",1852)]; case .weight:return [U("克","g",0.001),U("千克","kg",1),U("吨","t",1000),U("磅","lb",0.45359237),U("盎司","oz",0.028349523125)]; case .area:return [U("平方米","m²",1),U("平方千米","km²",1000000),U("平方厘米","cm²",0.0001),U("公顷","ha",10000),U("英亩","acre",4046.8564224)]; case .volume:return [U("毫升","ml",0.001),U("升","L",1),U("立方米","m³",1000),U("加仑","gal",3.785411784)]; case .temperature:return [U("摄氏度","C",1),U("华氏度","F",1),U("开尔文","K",1)]; case .speed:return [U("米/秒","m/s",1),U("千米/时","km/h",0.2777777778),U("英里/时","mph",0.44704),U("节","kn",0.5144444444)]; case .time:return [U("秒","s",1),U("分钟","min",60),U("小时","h",3600),U("天","d",86400)]; case .base:return [U("二进制","2",2),U("八进制","8",8),U("十进制","10",10),U("十六进制","16",16)]; default:return [U("数值","",1)]} } }
struct U:Identifiable{ let id=UUID(); let title:String; let symbol:String; let factor:Double; init(_ t:String,_ s:String,_ f:Double){title=t;symbol=s;factor=f} }
struct Field:View{ let title:String; @Binding var text:String; init(_ title:String,text:Binding<String>){self.title=title;_text=text}; var body:some View{ VStack(alignment:.leading,spacing:8){ Text(title).font(.system(size:15,weight:.medium)).foregroundStyle(.white.opacity(0.58)); TextField(title,text:$text).keyboardType(.numbersAndPunctuation).font(.system(size:30,design:.rounded)).foregroundStyle(.white).padding(14).background(Color.white.opacity(0.08),in:RoundedRectangle(cornerRadius:8,style:.continuous)) } } }
struct MenuPick:View{ let title:String; let opts:[U]; @Binding var sel:Int; init(_ title:String,_ opts:[U],_ sel:Binding<Int>){self.title=title;self.opts=opts;_sel=sel}; var body:some View{ VStack(alignment:.leading,spacing:8){ Text(title).font(.system(size:15,weight:.medium)).foregroundStyle(.white.opacity(0.58)); Picker(title,selection:$sel){ ForEach(opts.indices,id:\.self){ Text(opts[$0].title).tag($0) } }.pickerStyle(.menu).frame(maxWidth:.infinity).padding(14).background(Color.white.opacity(0.08),in:RoundedRectangle(cornerRadius:8,style:.continuous)).tint(.white) } } }
struct Result:View{ let title:String; let value:String; init(_ t:String,value:String){title=t;self.value=value}; var body:some View{ HStack(alignment:.firstTextBaseline){ Text(title).font(.system(size:17,weight:.medium)).foregroundStyle(.white.opacity(0.6)); Spacer(); Text(value).font(.system(size:32,weight:.semibold,design:.rounded)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.42) } } }
extension Array{ subscript(safe i:Int)->Element?{ indices.contains(i) ? self[i] : nil } }
