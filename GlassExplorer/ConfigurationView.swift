//
//  Created by ktiays on 2025/6/10.
//  Copyright (c) 2025 ktiays. All rights reserved.
// 

import UIKit
import SwiftUI
import Observation

struct ConfigurationView: View {
    
    @Bindable var configuration: GlassConfiguration
    
    let glassView: UIView
    
    init(_ configuration: GlassConfiguration, glassView: UIView) {
        _configuration = .init(configuration)
        self.glassView = glassView
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Glass Properties") {
                    HStack {
                        Text("Variant")
                        Spacer()
                        Stepper("\(configuration.variant)", value: $configuration.variant, in: 0...10)
                    }
                    
                    HStack {
                        Text("Size")
                        Spacer()
                        Stepper("\(configuration.size)", value: $configuration.size, in: 0...5)
                    }
                }
                
                Section("Display Effects") {
                    Toggle("Content Lensing", isOn: $configuration.isContentLensingEnabled)
                    Toggle("Highlights Display Angle", isOn: $configuration.highlightsDisplayAngle)
                    Toggle("Boost White Point", isOn: $configuration.boostWhitePoint)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Smoothness")
                            Spacer()
                            Text(String(format: "%.2f", configuration.smoothness))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $configuration.smoothness, in: 0...1, step: 0.01)
                    }
                }
                
                Section("Exclusions") {
                    Toggle("Excluding Platter", isOn: $configuration.excludingPlatter)
                    Toggle("Excluding Foreground", isOn: $configuration.excludingForeground)
                    Toggle("Excluding Shadow", isOn: $configuration.excludingShadow)
                    Toggle("Excluding Control Lensing", isOn: $configuration.excludingControlLensing)
                    Toggle("Excluding Control Displacement", isOn: $configuration.excludingControlDisplacement)
                }
                
                Section("Layout") {
                    Toggle("Flexible", isOn: $configuration.flexible)
                    Toggle("Allows Grouping", isOn: $configuration.allowsGrouping)
                    
                    HStack {
                        Text("Flex Variant")
                        Spacer()
                        Stepper("\(configuration.flexVariant)", value: $configuration.flexVariant, in: 0...5)
                    }
                }
                
                NavigationLink("Advanced Filter Settings") {
                    AdvancedGlassFilterConfigurationView(glassView: glassView)
                        .navigationTitle("Advanced Filter Settings")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Glass Configuration")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

@Observable
final class GlassConfiguration {
    
    var variant: Int = 1
    var size: Int = 0
    
    var isContentLensingEnabled: Bool = false
    var highlightsDisplayAngle: Bool = false
    var excludingPlatter: Bool = false
    var excludingForeground: Bool = false
    var excludingShadow: Bool = false
    var excludingControlLensing: Bool = false
    var excludingControlDisplacement: Bool = false
    var flexible: Bool = false
    var flexVariant: Int = 0
    var boostWhitePoint: Bool = false
    var allowsGrouping: Bool = false
    var smoothness: Double = 0.0
}

protocol GlassFilterInputItem: Sendable {
    
    associatedtype Value
    associatedtype TweakerView: View
    
    var key: String { get }
    
    func makeTweakerView(with binding: Binding<Value>) -> TweakerView
    
    func read(from filter: CAFilter) -> Value
    func write(_ value: Value, to filter: CAFilter)
    
    func format(_ value: Value) -> String
    
    @MainActor
    func _makeTweakerView(with glassView: UIView,
                          currentValue: Any?,
                          onChange: @escaping @MainActor (Any) -> Void) -> AnyView
    
    func _formatValue(_ value: Any) -> String
}

@MainActor
private func backdropLayer(from glassView: UIView) -> CALayer? {
    let multiLayerRoot = glassView.layer.superlayer
    let glassGroupViewLayer = multiLayerRoot?.sublayers?.last?.sublayers?.first
    let materialProviderLayer = glassGroupViewLayer?.sublayers?.first
    let backdropLayer = materialProviderLayer?.sublayers?.first
    
    return backdropLayer
}

extension GlassFilterInputItem {
    
    @MainActor
    func _makeTweakerView(with glassView: UIView,
                          currentValue: Any?,
                          onChange: @escaping @MainActor (Any) -> Void) -> AnyView {
        let binding = Binding {
            if let currentValue {
                return currentValue as! Value
            }
            
            guard let backdropLayer = backdropLayer(from: glassView),
                  let filter = backdropLayer.filters?.first as? CAFilter else {
                return read(from: .init())
            }
            return read(from: filter)
        } set: { newValue in
            guard let backdropLayer = backdropLayer(from: glassView),
                  let filter = backdropLayer.filters?.first as? CAFilter else {
                return
            }
            backdropLayer.filters = []
            write(newValue, to: filter)
            backdropLayer.filters = [filter]
            onChange(newValue)
        }
        return AnyView(makeTweakerView(with: binding))
    }
    
    func _formatValue(_ value: Any) -> String {
        return format(value as! Value)
    }
}

struct GlassFilterNumberInputItem: GlassFilterInputItem {
    
    typealias Value = Double
    
    let key: String
    let minimumValue: Double
    let maximumValue: Double
    let step: Double
    
    init(key: String, minimumValue: Double, maximumValue: Double, step: Double = 1) {
        self.key = key
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        self.step = step
    }
    
    func makeTweakerView(with binding: Binding<Double>) -> some View {
        Slider(value: binding, in: minimumValue...maximumValue, step: step)
    }
    
    func read(from filter: CAFilter) -> Double {
        guard let number = filter.value(forKey: key) as? NSNumber else {
            return 0
        }
        return number.doubleValue
    }
    
    func write(_ value: Double, to filter: CAFilter) {
        filter.setValue(NSNumber(value: value), forKey: key)
    }
    
    func format(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }
}

struct AdvancedGlassFilterConfigurationView: View {
    
    private struct ItemView: View {
        
        let glassView: UIView
        let filter: CAFilter
        let item: any GlassFilterInputItem
        
        @State private var setValue: Any?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.key)
                    Spacer()
                    Text(item._formatValue(setValue ?? item.read(from: filter)))
                        .foregroundColor(.secondary)
                        .monospaced()
                }
                item._makeTweakerView(with: glassView, currentValue: setValue) {
                    setValue = $0
                }
            }
        }
    }
    
    private static let inputs: [any GlassFilterInputItem] = [
        GlassFilterNumberInputItem(key: "inputInnerRefractionAmount", minimumValue: -200, maximumValue: 200),
        GlassFilterNumberInputItem(key: "inputInnerRefractionHeight", minimumValue: 0, maximumValue: 100),
        GlassFilterNumberInputItem(key: "inputOuterRefractionAmount", minimumValue: -200, maximumValue: 200),
        GlassFilterNumberInputItem(key: "inputOuterRefractionHeight", minimumValue: 0, maximumValue: 100),
        GlassFilterNumberInputItem(key: "inputBleedAmount", minimumValue: 0, maximumValue: 200),
        GlassFilterNumberInputItem(key: "inputBleedBlurRadius", minimumValue: 0, maximumValue: 200),
        GlassFilterNumberInputItem(key: "inputBleedOpacity", minimumValue: 0, maximumValue: 1, step: 0.01),
        GlassFilterNumberInputItem(key: "inputBlurDistance0", minimumValue: -200, maximumValue: 200),
        GlassFilterNumberInputItem(key: "inputBlurDistance1", minimumValue: -200, maximumValue: 200),
        GlassFilterNumberInputItem(key: "inputBlurDistance2", minimumValue: -200, maximumValue: 200),
        GlassFilterNumberInputItem(key: "inputBlurDistance3", minimumValue: -200, maximumValue: 200),
        GlassFilterNumberInputItem(key: "inputBlurDistance4", minimumValue: -200, maximumValue: 200),
        GlassFilterNumberInputItem(key: "inputBlurOpacity0", minimumValue: 0, maximumValue: 1, step: 0.01),
        GlassFilterNumberInputItem(key: "inputBlurOpacity1", minimumValue: 0, maximumValue: 1, step: 0.01),
        GlassFilterNumberInputItem(key: "inputBlurOpacity2", minimumValue: 0, maximumValue: 1, step: 0.01),
        GlassFilterNumberInputItem(key: "inputBlurOpacity3", minimumValue: 0, maximumValue: 1, step: 0.01),
        GlassFilterNumberInputItem(key: "inputBlurOpacity4", minimumValue: 0, maximumValue: 1, step: 0.01),
        GlassFilterNumberInputItem(key: "inputBlurRadius", minimumValue: 0, maximumValue: 100),
    ]
    
    let glassView: UIView
    
    var body: some View {
        if let backdropLayer = backdropLayer(from: glassView),
           let filter = backdropLayer.filters?.first as? CAFilter {
            List(Self.inputs, id: \.key) { input in
                ItemView(glassView: glassView, filter: filter, item: input)
            }
        } else {
            Text("Not Applicable")
        }
    }
}

@objc
class ConfigurationHostingController: UIViewController {
    
    let configuration = GlassConfiguration()
    @objc weak var glassView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let hostingController = UIHostingController(rootView: ConfigurationView(configuration, glassView: glassView!))
        hostingController.view.backgroundColor = .clear
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func updateProperties() {
        glassView?._glassEffect = nil
        let glass: _UIViewGlass = .init(
            variant: configuration.variant,
            size: configuration.size,
            smoothness: configuration.smoothness
        )
        glass.flexible = configuration.flexible
        glass._flexVariant = configuration.flexVariant
        glass.contentLensing = configuration.isContentLensingEnabled
        glass.highlightsDisplayAngle = configuration.highlightsDisplayAngle
        glass.excludingPlatter = configuration.excludingPlatter
        glass.excludingForeground = configuration.excludingForeground
        glass.excludingShadow = configuration.excludingShadow
        glass.excludingControlLensing = configuration.excludingControlLensing
        glass.excludingControlDisplacement = configuration.excludingControlDisplacement
        glass.boostWhitePoint = configuration.boostWhitePoint
        glass.allowsGrouping = configuration.allowsGrouping
        let glassEffect = UIGlassEffect(glass: glass)
        glassView?._glassEffect = glassEffect
    }
}
