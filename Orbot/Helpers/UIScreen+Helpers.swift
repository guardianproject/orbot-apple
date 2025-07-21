//
//  UIScreen+Helpers.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 07.12.21.
//

import UIKit

extension UIScreen {

    func setBrightness(_ value: CGFloat, animated: Bool) {
        guard animated else {
            brightness = value
            return
        }

        _brightnessQueue.cancelAllOperations()

        let step: CGFloat = 0.04 * ((value > brightness) ? 1 : -1)

        _brightnessQueue.addOperations(stride(from: brightness, through: value, by: step).map({ [weak self] (value) -> Operation in
            let op = BlockOperation()

            op.addExecutionBlock { [weak op] in
                if !(op?.isCancelled ?? true) {
                    Thread.sleep(forTimeInterval: 1 / 60)

                    DispatchQueue.main.async {
                        self?.brightness = value
                    }
                }
            }

            return op
        }), waitUntilFinished: false)
    }
}

private let _brightnessQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1

    return queue
}()
