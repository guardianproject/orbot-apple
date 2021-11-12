//
//  ScanQrViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 14.01.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit
import AVFoundation

protocol ScanQrDelegate {

	func scanned(value: String?)
}

class ScanQrViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

	private var captureSession: AVCaptureSession?
	private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

	var delegate: ScanQrDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Scan QR Code", comment: "")

		view.backgroundColor = .systemGroupedBackground
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		startReading()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		stopReading()
	}


	// MARK: AVCaptureMetadataOutputObjectsDelegate

	/**
	BUGFIX: Signature of method changed in Swift 4, without notifications.
	No migration assistance either.

	See https://stackoverflow.com/questions/46639519/avcapturemetadataoutputobjectsdelegate-not-called-in-swift-4-for-qr-scanner
	*/
	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput
		metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

		if metadataObjects.count > 0,
			let metadata = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
			metadata.type == .qr {

			if let navC = navigationController {
				navC.popViewController(animated: true)

				delegate?.scanned(value: metadata.stringValue)
			}
		}
	}


	// MARK: Private Methods

	private func startReading() {

		if let captureDevice = AVCaptureDevice.default(for: .video) {
			do {
				let input = try AVCaptureDeviceInput(device: captureDevice)

				captureSession = AVCaptureSession()

				captureSession!.addInput(input)

				let captureMetadataOutput = AVCaptureMetadataOutput()
				captureSession!.addOutput(captureMetadataOutput)
				captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
				captureMetadataOutput.metadataObjectTypes = [.qr]

				videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)

				videoPreviewLayer!.videoGravity = .resizeAspectFill
				videoPreviewLayer!.frame = view.layer.bounds
				view.layer.addSublayer(videoPreviewLayer!)

				captureSession!.startRunning()

				return
			} catch {
				// Just fall thru to alert.
			}
		}

		let warning = UILabel(frame: .zero)
		warning.text = NSLocalizedString("Camera access was not granted or QR Code scanning is not supported by your device.",
										 comment: "")
		warning.translatesAutoresizingMaskIntoConstraints = false
		warning.numberOfLines = 0
		warning.textAlignment = .center
		warning.textColor = .secondaryLabel

		view.addSubview(warning)
		warning.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
		warning.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
		warning.topAnchor.constraint(equalTo: view.topAnchor, constant: 16).isActive = true
		warning.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16).isActive = true
	}

	private func stopReading() {
		captureSession?.stopRunning()
		captureSession = nil

		videoPreviewLayer?.removeFromSuperlayer()
		videoPreviewLayer = nil
	}
}
