//
//  ViewController.swift
//  RadonExample
//
//  Created by Bas van Kuijck on 12/07/2018.
//  Copyright © 2018 E-sites. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let image = Radon.images.assets.icons.ironMan
        
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 50, y: 50, width: 100, height: 100)
        self.view.addSubview(imageView)
    }

}

