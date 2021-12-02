

import UIKit
import PhotosUI      //引入iOS15之後使用的相簿UI框架
//import CoreLocation  //引入核心定位框架
import MapKit        //引入地圖框架
import SQLite3


class DetailViewController: UIViewController,UIPickerViewDelegate,UIPickerViewDataSource, UIImagePickerControllerDelegate,UINavigationControllerDelegate,PHPickerViewControllerDelegate {
    
    
    //layout properties
    @IBOutlet weak var lblNo: UILabel!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtGender: UITextField!
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtTel: UITextField!
    @IBOutlet weak var txtMyClass: UITextField!
    @IBOutlet weak var txtAddr: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    
    
    //instance properties
    
    //宣告資料庫連線指標
    var db:OpaquePointer?
    //接收上一頁的執行實體(從 prepare function 從過來)
    weak var myTableVc:MyTableViewController!
    //紀錄上一頁被點選的row
    private var currentRow:Int = 0
    //紀錄目前處理中的學生資料
    var currentData = Student()
    //提供性別及班別滾輪的資料輸入介面
    var pkvGender:UIPickerView!
    var pkvClass:UIPickerView!
    //提供性別及班別滾輪的選擇資料
    let arrGender=["男","女"]
    let arrClass = ["手機程式設計","智能裝置開發","網頁程式設計"]
    //紀錄目前輸入元件的y軸底緣位置
    var currentObjectBottomYPoisition:CGFloat = 0
    
    //MARK: -自定函式
    //由通知中心在 [鍵盤彈出] 呼叫的函式
    @objc func keyboardWillShow(_ notification:Notification) {
        //print("鍵盤彈出.:\(notification.userInfo!)")
        
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue{
            //print("鍵盤高度：\(keyboardHeight.height)")
            
            //計算 可視高度 = 扣除鍵盤遮擋範圍之後的剩餘高度
            let visiableHeight = self.view.bounds.height - keyboardHeight.height
            
            //當鍵盤被遮住時，輸入元件的y軸底緣位置會大於可視的可視高度
            if currentObjectBottomYPoisition > visiableHeight{
                //向上位移 [y軸底緣位置] 與 [可視高度] 的差值
                //self.view.frame.origin.y = self.view.frame.origin.y - (currentObjectBottomYPoisition-visiableHeight)-10
                self.view.frame.origin.y -= currentObjectBottomYPoisition - visiableHeight + 10
            }
            
        }
        
    }
    
    
    //由通知中心在 [鍵盤收合] 呼叫的函式
    @objc func keyboardWillHide() {
        //print("鍵盤收合....")
        
        //將上移的畫面歸回原點
        self.view.frame.origin.y = 0
    }
    
    
    //MARK: -- Target Action
    //由虛擬鍵盤的return鍵觸發的事件
    @IBAction func didEndOnExit(_ sender: UITextField) {
        //不需實作即可收起鍵盤
        
    }
  
    //文字輸入框開始編輯時觸發(不同的鍵盤)
    @IBAction func editingDidBegin(_ sender: UITextField) {
        switch sender.tag{
            case 4:     //電話欄位
                sender.keyboardType = .numberPad
            case 6:     //Email欄位
                sender.keyboardType = .emailAddress
            default:    //其他種類的欄位
                sender.keyboardType = .default
        }
        
        //計算目前元件的
        currentObjectBottomYPoisition = sender.frame.origin.y + sender.frame.size.height
        
    }
    
    //相機按鈕
    @IBAction func buttonCamera(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else{
            print("本裝置無相機....")
            return
        }
        
        //如果可以使用相機，即產生影像挑選控制器
        let imagePicker = UIImagePickerController()
        //將影像挑選控制器 呈現
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        
        //開啟拍照介面
        //show(imagePicker, sender: nil)
        present(imagePicker,animated: true,completion: nil)
    }
    
    //相簿按鈕
    @IBAction func buttinPhotoAlbum(_ sender: UIButton) {
        
        //<方法一:>iOS 14以前的相簿取用方法
        /*
        //產生影像挑選控制器
        let imagePicker = UIImagePickerController()
        //將影像挑選控制器 呈現相簿
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        //開啟拍照介面
        show(imagePicker, sender: nil)
        */
        
        //<方法一:>iOS 15以後的相簿取用方法
        //設定挑選相簿時使用的組態
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = PHPickerFilter.images
        configuration.preferredAssetRepresentationMode = .current
        configuration.selection = .ordered
        //設定可選多張照片，0為不限張數，1為預設值
        //configuration.selectionLimit = 0
        let picker = PHPickerViewController(configuration: configuration)
        
        picker.delegate = self
        present(picker,animated: true,completion: nil)
    }
    
    
    //撥打(電話)按鈕
    //要實機測試
    @IBAction func buttonCall(_ sender: UIButton) {
        
        if let phoneNumbe = txtTel.text
        {
            let url = URL(string: "tel://\(phoneNumbe)")
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
    }
    
    //導航到特定地址的按鈕
    @IBAction func buttonNaviToAddress(_ sender: UIButton) {
        //初始化地理資訊編碼器
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(txtAddr.text!)
        {
            placemarks, error
             in
            //無錯誤，表示地址順利編碼成經緯度資訊
            if error == nil{
                //是否可以取得經緯度資訊
                if placemarks != nil {
                    //step 1.
                    //(第一層)取得地址對應的緯度資訊標示
                    let toPlaceMark = placemarks!.first!
                    //(第二層)將經緯度資訊的位置標示轉換成導航地圖上的目的地的大頭針
                    let toPin = MKPlacemark(placemark: toPlaceMark)
                    //(第三層)產生導航地圖上導亢終點的大頭針
                    let destMapItem = MKMapItem(placemark: toPin)
                    
                    //setp 2. 設定導航為開車模式
                    let navOption = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                    //setp 3. 使用(第三層)開啟導航地圖
                    destMapItem.openInMaps(launchOptions: navOption)
                }
            }else{
                print("地址解碼錯誤: \(error!.localizedDescription)")
            }
        }
        
    }
    
    
    //修改資料按鈕
    @IBAction func buttonUpdate(_ sender: UIButton) {
        //step 1.更新資料庫資料
        
        //準備update用的SQL指令
        let sql:String="update student set name=?,gender=?,picture=?,phone=?,address=?,email=?,myclass=? where no=?;"
        
        //將SQL指令轉換成C語言的字元陣列
        let cSql = sql.cString(using: .utf8)!
        
        //宣告儲存更新結果的指標
        var statement:OpaquePointer?
        
        //準備查詢(第三個參數若為正數則限定SQL指令的長度，若為負數則不限SQL指令的長度。第四個和第六個參數為預留參數，目前沒有作用。)
        
        if sqlite3_prepare_v3(db, cSql, -1, 0, &statement, nil) == SQLITE_OK
        {
            //準備綁定到第一個問號的資料(文字型態)
            let name = txtName.text!.cString(using: .utf8)!
            //將資料綁到update指令(參數一)的第一個問號(參數二)，指定介面上的姓名資料(參數三)，且不指定資料長度(參數四為負數)，參數五為預留欄位目前沒有作用
            sqlite3_bind_text(statement, 1, name, -1, nil)
            
            //準備綁定到第二個問號的資料(picker)
            let gender = pkvGender.selectedRow(inComponent: 0)
            sqlite3_bind_int(statement, 2, Int32(gender))
            
            //準備綁定到第三個問號的資料(圖片)
            let imgData:Data = imgPicture.image!.jpegData(compressionQuality: 0.8)!
            //將照片綁到第三個問號(參數二)，指定照片的位元資訊(參數三)，及檔案長度(參數四)，，參數五為預留欄位目前沒有作用
            sqlite3_bind_blob(statement, 3, (imgData as NSData).bytes, Int32(imgData.count), nil)
            
            //準備綁定到第四個問號的資料(文字型態)
            let phone = txtTel.text!.cString(using: .utf8)!
            sqlite3_bind_text(statement, 4, phone, -1, nil)
            
            //準備綁定到第五個問號的資料(文字型態)
            let address = txtAddr.text!.cString(using: .utf8)!
            sqlite3_bind_text(statement, 5, address, -1, nil)
            
            //準備綁定到第六個問號的資料(文字型態)
            let email = txtEmail.text!.cString(using: .utf8)!
            sqlite3_bind_text(statement, 6, email, -1, nil)
            
            //準備綁定到第七個問號的資料(文字型態)
            let myclass = txtMyClass.text!.cString(using: .utf8)!
            sqlite3_bind_text(statement, 7, myclass, -1, nil)
            
            //準備綁定到第8個問號的資料(文字型態)
            let no = lblNo.text!.cString(using: .utf8)!
            sqlite3_bind_text(statement, 8, no, -1, nil)
            
            //執行update指令如果不成功
            if sqlite3_step(statement) != SQLITE_DONE{
                //提示修改失敗訊息
                //初始化訊息視窗
                let alertController = UIAlertController(title: "資料庫訊息", message: "資料修改失敗!", preferredStyle: .alert)
                //初始化訊息視窗使用按鈕
                let okAction = UIAlertAction(title: "確定", style: .default, handler: nil)
                //將按鈕加入訊息視窗
                alertController.addAction(okAction)
                //顯示訊息視窗
                self.present(alertController, animated: true, completion: nil)
                //關閉連線資料集
                sqlite3_finalize(statement!)
                //直接離開
                return
            }
        }
        else
        {
            print("Update: Connect DataBase statement fail!!")
            return
        }
        
        if statement != nil{
            //關閉連線資料集
            sqlite3_finalize(statement!)
        }
        
        //step 2.更新SQLite3資料集(從介面直接取得已更新的資料，重設上一頁離線資料集的當筆資料)
        myTableVc.arrTable[currentRow] = Student(
            no: lblNo.text!,
            name: txtName.text!,
            gender: pkvGender.selectedRow(inComponent: 0),
            picture: imgPicture.image?.jpegData(compressionQuality: 0.8),
            phone: txtTel.text!,
            address: txtAddr.text!,
            email: txtEmail.text!,
            myclass: txtMyClass.text!)
        
        //step 3.重整上一頁表格資料
        myTableVc.tableView.reloadData()
        
        //step 4.提示修改成功訊息
        //step 4-1.初始化訊息視窗
        let alertController = UIAlertController(title: "資料庫訊息", message: "修改成功", preferredStyle: .alert)
        //step 4-2.初始化訊息視窗使用按鈕
        let okAction = UIAlertAction(title: "確定", style: .default, handler: nil)
        //step 4-3.將按鈕加入訊息視窗
        alertController.addAction(okAction)
        //step 4-4.顯示訊息視窗
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    
    //MARK: -- view Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //取得資料庫連線
        db = (UIApplication.shared.delegate as! AppDelegate).getDB()
        
        //設view背景色
        self.view.backgroundColor = .systemCyan
        
        //上一頁哪個cell被點選
        currentRow = myTableVc.tableView.indexPathForSelectedRow!.row
        //接收上一頁的陣列紀錄當筆資料
        currentData = myTableVc.arrTable[currentRow]
        //print("上一頁的\(currentRow) 被點選......")
        
        lblNo.text =  currentData.no
        txtName.text = currentData.name
        
        if currentData.gender == 0{
            txtGender.text = "男"
        }else{
            txtGender.text = "女"
        }
        
        if let picture = currentData.picture{
            imgPicture.image = UIImage(data: picture)
        }
        
        txtTel.text = currentData.phone
        txtMyClass.text = currentData.myclass
        txtEmail.text = currentData.email
        txtAddr.text = currentData.address
        
        
        //建立 性別與班別 的滾輪，讓tag的索引值與textfield的tag對應
        pkvGender = UIPickerView()
        pkvGender.tag = 2
        
        pkvClass = UIPickerView()
        pkvClass.tag = 5
        
        //指定在此類別實作pickerView相關代理事件
        pkvGender.delegate = self
        pkvGender.dataSource = self
        
        pkvClass.delegate = self
        pkvClass.dataSource = self
        
        //將 性別與班別 的輸入鍵盤替換為pickerView
        txtGender.inputView = pkvGender
        txtMyClass.inputView = pkvClass
        
        //選定目前資料所在的 性別 滾輪位置
        pkvGender.selectRow(currentData.gender, inComponent: 0, animated: false)
        
        //選定目前資料所在的 班別 滾輪位置
        for (index,item) in arrClass.enumerated(){
            if item == currentData.myclass {
                pkvClass.selectRow(index, inComponent: 0, animated: false)
                break   //比對到符合資料即離開迴圈
            }
        }
        
        
        //取得此App通知中心的實體
        let notificationCenter = NotificationCenter.default
        //註冊虛擬鍵盤彈出的通知
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        //註冊虛擬鍵盤收合通知
        notificationCenter.addObserver(self,selector: #selector(keyboardWillHide),name: UIResponder.keyboardWillHideNotification,object: nil)
        
    }
    
    //MARK: -- Touch Event
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print("觸碰開始!!!")
        //結束編輯狀態，收起鍵盤
        self.view.endEditing(true)
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        print("觸碰中移動 !!!\(touches.first!.location(in: self.view))")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        print("觸碰結束 !!!")
    }
    
    
    
    //MARK: -- UIPickerViewDataSource
    //滾輪有幾段
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //每一段滾輪有幾行
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag{
            case 2: //性別
                return arrGender.count
            case 5: //班別
                return arrClass.count
            default:
                return 1
        }
    }
    
    
    //MARK: -- UIPickerViewDelegate
    //詢問每一段每一列要呈現文字
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        switch pickerView.tag{
            case 2: //性別
                return arrGender[row]
            case 5: //班別
                return arrClass[row]
            default:
                return "X"
        }
    }
    
    
    //pickerView被選定時觸發
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch pickerView.tag{
            case 2: //性別
                txtGender.text = arrGender[row]
            case 5: //班別
                txtMyClass.text = arrClass[row]
            default:
                 break
        }
    }
    

    //MARK: -- UIImagePickerControllerDelegate
    //注意:iOS15之後只會有"相機" 使用此代理事件(iOS14之前相機和相簿都使用此事件)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("info: \(info)")
        
        //從字典中取得拍下來的照片
        let image = info[.originalImage] as! UIImage
        //將取得的照片直接顯示在畫面上
        imgPicture.image = image
        //退掉 image picker(退掉相機或相簿畫面)
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    
    //MARK: - PHPickerViewControllerDelegate
    //注意:iOS15之後只會有相簿使用此代理事件
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

        print("挑選到的照片: \(results)")
        
        if let itemProvider = results.first?.itemProvider{
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier){
                itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) {
                    data, error
                     in
                    //如果沒有取得照片就離開
                    guard let photoData = data else{
                        return
                    }
                    //將取到的照片呈現在畫面上
                    //(因為上面是閉包組data所以要後台組資料要show要用DispatchQueue)
                    DispatchQueue.main.async {
                        self.imgPicture.image = UIImage(data: photoData)
                        //(退掉相機或相簿畫面)
                        picker.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
