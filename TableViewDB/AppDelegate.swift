import UIKit
import SQLite3

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    //宣告資料庫連線指標
    fileprivate var db:OpaquePointer?
    //提供其他頁面取得資料庫連線的方法
    func getDB()->OpaquePointer{
        return db!
    }
    
    //應用程式啟動完成時
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //取得應用程式正在使用的檔案管理員
        let filemanager = FileManager.default
        //在Bundle裡找到檔名為 mydatabase 副檔名為 db3
        //因為預設是唯讀，要寫入要再扣到非唯讀的目錄下
        let sourceDB = Bundle.main.path(forResource: "mydatabase", ofType: "db3")!
        print("資料庫來源路徑: \(sourceDB)")
        print("App的家目錄 : \(NSHomeDirectory())")
        //定義資料庫存放的目的地路徑在App的家目錄的 Documents資料夾中，重新命名為mydb.db3
        let destinationDB = NSHomeDirectory() + "/Documents/mydb.db3"
        //當目的地資料庫檔案不存在時
        if !filemanager.fileExists(atPath: destinationDB)
        {
                //從來源資料庫將檔案複製進目的地資料庫
            try! filemanager.copyItem(atPath: sourceDB, toPath: destinationDB)
        }
        
        //開啟資料庫連線，並且存入db所在記憶體位置
        if sqlite3_open(destinationDB, &db) == SQLITE_OK{
            print("資料庫 connect ok(成功)!")
        }else{
            print("資料庫 connecti fail(失敗)!")
        }
                
        return true
    }
    
    //應用程式終止時觸發
    func applicationWillTerminate(_ application: UIApplication) {
        print("應用程式終止!!")
        sqlite3_close_v2(db)
    }
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

