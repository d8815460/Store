//
//  PFProductTableViewCell.swift
//  Store
//
//  Created by 駿逸 陳 on 2016/7/11.
//  Copyright © 2016年 Ayi. All rights reserved.
//

import UIKit
import ParseUI

class PFProductTableViewCell: PFTableViewCell {

    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var productImage: PFImageView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureProduct(product: PFObject) {
        self.productImage.file = (product.object(forKey: "image") as! PFFile)
        self.productImage.loadInBackground()
        
        self.priceLabel.text = "$\(product.object(forKey: "price")!)"
        
        self.productNameLabel.text = (product.object(forKey: "description") as! String)
    }
    
    
}
