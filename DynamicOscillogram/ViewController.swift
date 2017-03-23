//
//  ViewController.swift
//  DynamicOscillogram
//
//  Created by Jace on 23/03/17.
//  Copyright © 2017年 WangJace. All rights reserved.
//

import UIKit
import CorePlot

struct HeartRate {
    var time: Int
    var value: Int
}

class ViewController: UIViewController {

    @IBOutlet weak var hostingView: CPTGraphHostingView!
    var plot: CPTScatterPlot?     // 波形图
    var dataSource: [HeartRate] = [HeartRate]()     // 数据源
    var timer: Timer?
    var xLocation: Int = 0     // x轴的原点值
    var tempX = 0
    var yMin: Int = 40     // y轴最小值
    var yMax: Int = 100    // y轴最大值

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(addHeartRate), userInfo: nil, repeats: true)
        timer?.fire()
    }

    // 添加心率值
    func addHeartRate() {
        // 随机产生一个值，模拟心率值
        let temp: Int = 40 + Int(arc4random()%(10+arc4random()%100))
        guard let graph = hostingView.hostedGraph else {
            return
        }

        let plotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        let xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
        let yRange = plotSpace.yRange.mutableCopy() as! CPTMutablePlotRange

        // 限制最多显示20个心率值，当超出这个心率值的时候删除第一个值
        if dataSource.count > 20 {
            dataSource.remove(at: 0)
            dataSource.append(HeartRate(time: tempX, value: temp))
            xLocation += 10
            // 当从dataSource删除一个值的时候，修改x轴的原点值
            xRange.location = NSNumber.init(value: xLocation)
        }
        else {
            dataSource.append(HeartRate(time: tempX, value: temp))
        }
        // 心率值的递增时长为10s
        tempX += 10

        // 每次新增一个心率值的时候都需要重新计算最大值和最小值
        var max: Int = 80
        var min: Int = 80
        for heartRate in dataSource {
            if max < heartRate.value {
                max = heartRate.value
            }

            if min > heartRate.value {
                min = heartRate.value
            }
        }

        // 当最大值或最小值发生改变时，修改y轴的原点值和y轴的数值长度
        if yMax != max+20 || yMin != min-20 {
            yMax = max+20
            yMin = min-20

            yRange.location = NSNumber.init(value: yMin)
            yRange.length = NSNumber.init(value: yMax - yMin)
        }

        plotSpace.xRange = xRange
        plotSpace.yRange = yRange
        graph.add(plotSpace)
        // 重载波形图
        plot?.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let graph = hostingView.hostedGraph else {
            setPlot()
            return
        }
        graph.frame = hostingView.bounds;
    }

    func setPlot() {
        let graph = CPTXYGraph.init(frame: hostingView.bounds);
        graph.paddingTop = 0;
        graph.paddingBottom = 0;
        graph.paddingLeft = 0;
        graph.paddingRight = 0;

        let textStyle = CPTMutableTextStyle()
        textStyle.fontSize = 20
        textStyle.fontName = "HelveticaNeue-Bold"
        textStyle.color = CPTColor.white()
        graph.titleTextStyle = textStyle
        graph.title = "波形图"
        graph.axisSet = nil

        graph.apply(CPTTheme(named: CPTThemeName.plainBlackTheme))

        let plotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        let xRange = plotSpace.xRange.mutableCopy() as! CPTMutablePlotRange
        let yRange = plotSpace.yRange.mutableCopy() as! CPTMutablePlotRange
        xRange.location = NSNumber.init(value: 0)
        xRange.length = NSNumber.init(value: 190)
        yRange.location = NSNumber.init(value: 40)
        yRange.length = NSNumber.init(value: 100)
        plotSpace.xRange = xRange
        plotSpace.yRange = yRange
        graph.add(plotSpace)

        hostingView.hostedGraph = graph

        plot = CPTScatterPlot()
        plot?.dataSource = self
        plot?.delegate = self
        plot?.identifier = "HeartRate" as (NSCoding & NSCopying & NSObjectProtocol)?

        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 2
        lineStyle.lineColor = CPTColor.red()
        plot?.dataLineStyle = lineStyle
        plot?.interpolation = .curved
        
        graph.add(plot!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: CPTScatterPlotDataSource, CPTScatterPlotDelegate {
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return UInt(dataSource.count)
    }

    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        if plot.identifier?.description == "HeartRate" {
            let heartRate = dataSource[Int(idx)]
            if fieldEnum == UInt(CPTScatterPlotField.X.rawValue) {
                return heartRate.time
            }
            else {
                return heartRate.value
            }
        }
        return 0
    }
}

