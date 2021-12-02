

import UIKit

class MyCell: UITableViewCell {

    
    @IBOutlet weak var imgPicture: UIImageView!
    
    @IBOutlet weak var labNo: UILabel!
    @IBOutlet weak var labName: UILabel!
    @IBOutlet weak var labGender: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //<方法二:>取圖片的四邊圓角為圖片的一半寬度，即形成圓形圖片
        //PS.<方法一:>在MyTableViewController類別tableView datasource事件
        imgPicture.layer.cornerRadius = imgPicture.bounds.width / 2
        //設背景色
        self.contentView.backgroundColor = .systemCyan
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
