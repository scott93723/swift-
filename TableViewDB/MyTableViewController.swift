//深色模式與淺色模式的顏色設定教學：https://www.appcoda.com.tw/dark-mode-ios13/
import UIKit
import SQLite3

struct Student{
    var no:String = ""
    var name:String = ""
    var gender:Int = 0    //男:0,女:1
    var picture:Data?
    var phone:String = ""
    var address:String = ""
    var email:String = ""
    var myclass:String = ""
}

class MyTableViewController: UITableViewController {

    //宣告資料庫連線指標
    var db:OpaquePointer?
    
    //記錄單筆學生資料
    var strucRow = Student()
    //存放從資料庫查詢到的學生資料(此陣列為『離線資料集』)
    var arrTable = [Student]()
    
    //MARK: --自定函式
    //查詢資料庫函式。存到離線資料集
    func getDataFromTable()
    {
        //先清空資料陣列
        arrTable.removeAll()
        
        //準備查詢用的SQL指令
        let sql:String = "select no,name,gender,picture,phone,address,email,myclass from student order by no"

        //將SQL指令轉換成C語言的字元陣列
        
        let cSql = sql.cString(using: .utf8)!
        //宣告儲存查詢結果的指標
        var statement:OpaquePointer?
        
        //準備查詢(第三個參數若為正數則限定SQL指令的長度，若為負數則不限SQL指令的長度。第四個和第六個參數為預留參數，目前沒有作用。)
        
        if sqlite3_prepare_v3(db, cSql, -1, 0, &statement, nil) == SQLITE_OK
        {
            print("資料庫查詢指令執行成功！")
            //往下讀取『連線資料集』(statement)中的一筆資料
            while sqlite3_step(statement) == SQLITE_ROW
            {
                //讀取當筆資料的每一欄
                // no 屬性是c語言的char[]，故要再處理
                let no = sqlite3_column_text(statement!, 0)!
                let strNo = String(cString: no)
                strucRow.no = strNo
                
                let name = sqlite3_column_text(statement!, 1)!
                let strName = String(cString: name)
                strucRow.name = strName
                
                print("學號：\(strNo)，姓名：\(strName)")
                
                let gender = Int(sqlite3_column_int(statement!, 2))
                strucRow.gender = gender
                
                var imgData:Data!
                //如果有讀取到檔案的位元資料
                if let totalBytes = sqlite3_column_blob(statement!, 3)
                {
                    //讀取檔案長度
                    let fileLength = Int(sqlite3_column_bytes(statement!, 3))
                    //將檔案的位元和檔案長度初始化成為Data
                    imgData = Data.init(bytes: totalBytes, count: fileLength)
                }
                else    //當找不到照片 (NULL)
                {
                    imgData = UIImage(named: "mh")!.jpegData(compressionQuality: 0.8)
                }
                //將大頭照的Data存入結構成員
                strucRow.picture = imgData
                
                
                let phone = sqlite3_column_text(statement!, 4)!
                let strphone = String(cString: phone)
                strucRow.phone = strphone
                
                let address = sqlite3_column_text(statement!, 5)!
                let straddress = String(cString: address)
                strucRow.address = straddress
                
                let email = sqlite3_column_text(statement!, 6)!
                let stremail = String(cString: email)
                strucRow.email = stremail
                
                let myclass = sqlite3_column_text(statement!, 7)!
                let strmyclass = String(cString: myclass)
                strucRow.myclass = strmyclass
                
                //將整筆資料加入arrTable陣列
                arrTable.append(strucRow)
            }
            
            //如果有取得資料
            if statement != nil{
                //則關閉SQL連線資料集
                sqlite3_finalize(statement!)
            }
        }
        else
        {
            print("查詢資料庫指令fail !!")
        }
        
        //回主執行序
        DispatchQueue.main.async{
            //重新載入tableView
            self.tableView.reloadData()
        }
    }
    
    
    
    
    //MARK: -- Target Action
    //導覽列的編輯按鈕
    @objc func buttonEditAction(_ sender:UIBarButtonItem){
        //print("編輯按鈕被按下 !!")
        
        if self.tableView.isEditing{
            //讓表格取消編輯狀態
            self.tableView.isEditing=false
            //更改按鈕文字
            self.navigationItem.leftBarButtonItem?.title="編輯"
        }else{
            //讓表格進入編輯狀態
            self.tableView.isEditing=true
            //更改按鈕文字
            self.navigationItem.leftBarButtonItem?.title="取消"
        }
    }
    
     //導覽列的新增按鈕
    @objc func buttonAddAction(_ sender:UIBarButtonItem){
        if let addVC =  self.storyboard?.instantiateViewController(withIdentifier: "AddViewController") as? AddViewController{
            self.show(addVC, sender: nil)
            
            addVC.myTableVc = self
            
        }
    }
    
    //由下拉更新元件呼叫觸發事件
    @objc func handleRefresh(){
        
        //Step1.重新讀取實際的資料庫資料，並且填入離線資料集（arrTable）
        getDataFromTable()
        //Step 2.要求表格更新資料(重新執行tableview datasource三個事件)
        self.tableView.reloadData()
        //Step 3.停止下拉的動畫特效
        self.tableView.refreshControl?.endRefreshing()
        
    }
    
    
    //MARK: -- View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //取得資料庫連線
        db = (UIApplication.shared.delegate as! AppDelegate).getDB()
        
        //取得global佇列(使用 次佇列執行查詢資料庫 以免資料量太大)
        let global = DispatchQueue.global()
        global.async{
            //執行查詢資料庫(call funtion)
            self.getDataFromTable()
        }
        
        
        
        //在最上方的導覽列左右側各增加一個按鈕(左:編輯,右:新增)
        
        //為本地化語系做按鈕
        let strEdit = NSLocalizedString("Edit", tableName: "InfoPlist", bundle: Bundle.main, value: "", comment: "")
        let strAddNew  = NSLocalizedString("AddNew", tableName: "InfoPlist", bundle: Bundle.main, value: "", comment: "")
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: strEdit, style: .plain, target: self, action: #selector(buttonEditAction(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: strAddNew, style: .plain, target: self, action: #selector(buttonAddAction(_:)))
        
        //設定導覽列的背景圖片
        //navigationController?.navigationBar.setBackgroundImage(UIImage(named: "title"), for: .default)    //ios 15已不能用此語法
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .cyan
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
 
//        self.navigationController?.navigationBar.scrollEdgeAppearance?.backgroundImage=UIImage(named: "title")
        
        //準備下拉更新元件
        self.tableView.refreshControl = UIRefreshControl()
        //當下拉更新元件出現時(觸發valueChanged事件)，綁定執行事件
        self.tableView.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        self.tableView.refreshControl?.attributedTitle = NSAttributedString("更新中....")
    }
    

    
    // MARK: - Table view data source
    //表格有幾段
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    //每一段表格有幾列
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        //section從0開始計算;若多段就不同cell，用下面程式
//        if section == 0{
//            return 1
//        }else if  section == 1{
//            return 3
//        }
        //print("詢問第幾個 \(section) 段表格有幾列")
        return arrTable.count
    }

    
    //提供每一段每一列
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //print("詢問第 \(indexPath.section) 段,第 \(indexPath.row) 列的儲存格")
        
        //注意: 使用自訂儲存格時，必須完成自定cell class 的轉型
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath) as! MyCell
        //<方法一:>取圖片的四邊圓角為圖片的一半寬度，即形成圓形圖片 ps.<方法二:>在MyCell類別
        cell.imgPicture.layer.cornerRadius = cell.imgPicture.bounds.width / 2

        // Configure the cell...
        cell.imgPicture.image = UIImage(data: arrTable[indexPath.row].picture!)
        cell.labNo.text = arrTable[indexPath.row].no
        cell.labName.text = arrTable[indexPath.row].name
        if arrTable[indexPath.row].gender == 0 {
            cell.labGender.text = "男"
        }else if arrTable[indexPath.row].gender == 1{
            cell.labGender.text = "女"
        }else{
            cell.labGender.text = "不告訴你"
        }
        
        
        
        /*  預設 UITableViewCell 用以下程式
         
        //方法一:IOS 14 之前的系統預設儲存格用法
//        cell.imageView?.image=UIImage(data: arrTable[indexPath.row].picture!)
//        cell.textLabel?.text = arrTable[indexPath.row].name
//        cell.detailTextLabel?.text=arrTable[indexPath.row].no

        
        //方法二:IOS 15 之後的系統預設儲存格用法
        //宣告儲存內容設定的物件
        var content = cell.defaultContentConfiguration()
        //逐一設定儲存格物件內容
        content.image = UIImage(data: arrTable[indexPath.row].picture!)
        content.text = arrTable[indexPath.row].name
        content.secondaryText = arrTable[indexPath.row].no
        //將儲存格物件設定的內容給儲存格
        cell.contentConfiguration = content
         */
        
        return cell
    }
 
    //MARK: -- Table View Delegate
    
    //回傳 tableView cell 高度
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 150
//    }
    
    
    //<方法一> 哪一個儲存格被點選
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("『 \(arrTable[indexPath.row]) 』被點選......")
        
//        if let indexPath = tableView.indexPathsForSelectedRows{
//            print("『 \(list[indexPath.row].1) 』被點選......")
//        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    

//====================== 表格刪除相關作業(新版 課本7-9) ============================
    //以下事件會取代 7-5 舊版的刪除事件
    
    //table view cell 左滑動事件
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let goAction = UIContextualAction(style: .normal, title: "更多") { action, view, completingHandler in
            //按鈕按下去要做的事情寫這
            completingHandler(true)
        }
        goAction.backgroundColor = .blue
    
        let delAction = UIContextualAction(style: .destructive, title: "刪除") { action, view, completionHandler in
            //刪除資料
            completionHandler(true)
            
            //step 1:先刪除資料庫資料
            
            //準備『刪除』用的SQL指令
            let sql:String="delete from student where no = ?;"
            
            //將SQL指令轉換成C語言的字元陣列
            let cSql = sql.cString(using: .utf8)!
            
            //宣告儲存刪除結果的指標
            var statement:OpaquePointer?
            
            //準備查詢(第三個參數若為正數則限定SQL指令的長度，若為負數則不限SQL指令的長度。第四個和第六個參數為預留參數，目前沒有作用。)
            
            if sqlite3_prepare_v3(self.db, cSql, -1, 0, &statement, nil) == SQLITE_OK
            {
                
                //準備綁定到第1個問號的資料(文字型態)
                let no = self.arrTable[indexPath.row].no.cString(using: .utf8)!
                sqlite3_bind_text(statement, 1, no, -1, nil)
                
                
                
                //執行刪除如果不成功
                if sqlite3_step(statement) != SQLITE_DONE{
                    //提示刪除失敗訊息
                    //初始化訊息視窗
                    let alertController = UIAlertController(title: "資料庫訊息", message: "資料刪除失敗!", preferredStyle: .alert)
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
                print("刪除 : Connect DataBase statement fail!!")
                return
            }
            
            if statement != nil{
                //關閉連線資料集
                sqlite3_finalize(statement!)
            }
            
            
            
            //step 2:刪除陣列資料
            self.arrTable.remove(at: indexPath.row)
            print("刪除後的陣列:\(self.arrTable)")
            // Delete the row from the data source
            //step 3:刪除儲存格
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        //設定按鈕組合
        let config = UISwipeActionsConfiguration(actions: [goAction,delAction])
        //是否可以滑動到底(true可以滑到底只顯示一個按鈕)
        config.performsFirstActionWithFullSwipe = false
        //回傳按鈕組合
        return config
    }
    
    //==================== 表格刪除相關作業(新版 課本7-9) end =====================
    
    
    
    //======================== 表格移動相關作業 ================================
    //表格 cell 改變位置 (用 moveRowAt)
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        
        //Step 1: 移除陣列原始位置的元素。直接加在新的位置
        arrTable.insert(arrTable.remove(at: fromIndexPath.row), at: to.row)
        
        //確認交換過後的陣列位置
        for (index,item) in arrTable.enumerated(){
            print("\(index):\(item)")
        }
        print("-----------------------")
        
        //Step 2: 將list更新至資料庫
        
    }

    //允許哪一個儲存格可以被拖移
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        
        //讓所有儲存格都可以拖移
        return true
    }
    
    //==============================================================
    
    
    
//    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
//        //如果不允許特定儲存格進行編輯
//        if indexPath.row == 1{
//            //回傳 none
//            return .none
//        }else{
//            //允計編輯回傳delete or insert(通常不使用insert)
//            return .delete
//        }
//
//    }

    
    
    
    // MARK: - Navigation
    //導覽線換頁時，會觸發此function
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        let detailVC = segue.destination as! DetailViewController
        
        //通知下一頁目前本頁的記憶體位置(執行實體)
        detailVC.myTableVc = self
    }
    

}
