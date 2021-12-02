

import UIKit
import PhotosUI
import SQLite3

class AddViewController: UIViewController,UIPickerViewDelegate,UIPickerViewDataSource, UIImagePickerControllerDelegate,UINavigationControllerDelegate,PHPickerViewControllerDelegate{

    //layout properties
    
    @IBOutlet weak var txtNo: UITextField!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtGender: UITextField!
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var txtMyClass: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtAddr: UITextField!
   
    
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
    
    
    //新增資料按鈕
    @IBAction func buttonInsert(_ sender: UIButton) {
        //step 1.新增資料庫資料
        
        //準備Insert用的SQL指令

        let sql:String="insert into student(no,name,gender,picture,phone,address,email,myclass) values(?,?,?,?,?,?,?,?);"
        
        //將SQL指令轉換成C語言的字元陣列
        let cSql = sql.cString(using: .utf8)!
        
        //宣告儲存新增結果的指標
        var statement:OpaquePointer?
        
        //準備查詢(第三個參數若為正數則限定SQL指令的長度，若為負數則不限SQL指令的長度。第四個和第六個參數為預留參數，目前沒有作用。)
        
        if sqlite3_prepare_v3(db, cSql, -1, 0, &statement, nil) == SQLITE_OK
        {
            
            //準備綁定到第1個問號的資料(文字型態)
            let no = txtNo.text!.cString(using: .utf8)!
            sqlite3_bind_text(statement, 1, no, -1, nil)
            
            
            //準備綁定到第2個問號的資料(文字型態)
            let name = txtName.text!.cString(using: .utf8)!
            //將資料綁到update指令(參數一)的第一個問號(參數二)，指定介面上的姓名資料(參數三)，且不指定資料長度(參數四為負數)，參數五為預留欄位目前沒有作用
            sqlite3_bind_text(statement, 2, name, -1, nil)
            
            //準備綁定到第3個問號的資料(picker)
            let gender = pkvGender.selectedRow(inComponent: 0)
            sqlite3_bind_int(statement, 3, Int32(gender))
            
            //準備綁定到第4個問號的資料(圖片)
            let imgData:Data = imgPicture.image!.jpegData(compressionQuality: 0.8)!
            //將照片綁到第4個問號(參數二)，指定照片的位元資訊(參數三)，及檔案長度(參數四)，，參數五為預留欄位目前沒有作用
            sqlite3_bind_blob(statement, 4, (imgData as NSData).bytes, Int32(imgData.count), nil)
            
            //準備綁定到第5個問號的資料(文字型態)
            let phone = txtPhone.text!.cString(using: .utf8)!
            sqlite3_bind_text(statement, 5, phone, -1, nil)
            
            //準備綁定到第6個問號的資料(文字型態)
            let address = txtAddr.text!.cString(using: .utf8)!
            sqlite3_bind_text(statement, 6, address, -1, nil)
            
            //準備綁定到第7個問號的資料(文字型態)
            let email = txtEmail.text!.cString(using: .utf8)!
            sqlite3_bind_text(statement, 7, email, -1, nil)
            
            //準備綁定到第8個問號的資料(文字型態)
            let myclass = txtMyClass.text!.cString(using: .utf8)!
            sqlite3_bind_text(statement, 8, myclass, -1, nil)
            
            
            //執行新增如果不成功
            if sqlite3_step(statement) != SQLITE_DONE{
                //提示新增失敗訊息
                //初始化訊息視窗
                let alertController = UIAlertController(title: "資料庫訊息", message: "資料新增失敗!", preferredStyle: .alert)
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
            print("新增:Connect DataBase statement fail!!")
            return
        }
        
        if statement != nil{
            //關閉連線資料集
            sqlite3_finalize(statement!)
        }
        
        
        //step 2.更新離線資料集(從介面直接取得已更新的資料，重設上一頁離線資料集的當筆資料)
        myTableVc.arrTable.append(Student(
            no: txtNo.text!,
            name: txtName.text!,
            gender: pkvGender.selectedRow(inComponent: 0),
            picture: imgPicture.image?.jpegData(compressionQuality: 0.8),
            phone: txtPhone.text!,
            address: txtAddr.text!,
            email: txtEmail.text!,
            myclass: txtMyClass.text!))
        
        //step 2-1. 執行陣列排序(以學號排序)
        //myTableVc.arrTable.sorted(using: )
        myTableVc.arrTable.sort {
            student1, student2
             in
            return student1.no < student2.no
        }
        
        //step 3.重整上一頁表格資料
        myTableVc.tableView.reloadData()
        
        //step 4.提示新增成功訊息
        //step 4-1.初始化訊息視窗
        let alertController = UIAlertController(title: "資料庫訊息", message: "新增成功", preferredStyle: .alert)
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
        
        //設背景色
        self.view.backgroundColor = .systemMint
        
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
