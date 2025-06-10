//
//  Created by ktiays on 2025/6/10.
//  Copyright (c) 2025 ktiays. All rights reserved.
// 

import UIKit
import SwiftUI
import Observation

struct ConfigurationView: View {
    
    @Bindable var configuration: GlassConfiguration
    
    init(_ configuration: GlassConfiguration) {
        _configuration = .init(configuration)
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

@objc
class ConfigurationHostingController: UIViewController {
    
    let configuration = GlassConfiguration()
    @objc weak var glassView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let hostingController = UIHostingController(rootView: ConfigurationView(configuration))
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
