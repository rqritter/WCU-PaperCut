# PaperCut Application Server Post install Settings
Using a MS failover Cluster named `papercut.wcu.edu`  
Virtual Applcation Server is `postscript.wcu.edu`  
Nodes are `courier.wcu.edu` and `copperplate.wcu.edu`  

### Changes to settings files

#### 1. C:\Program Files\PaperCut MF\server\server.properties

* Disable CSRF checks (needed for clustering)
  * Un-comment "server.csrf-check.validate-request-origin" and set to "N"
  ```
  server.csrf-check.validate-request-origin=N
  ```
  
* Use External SQL Database
  * Comment out internal DB
  ```
    #database.type=Internal
  ``` 
  * Add Settings For SQL Server
  
  ```
    # WCU MS SQLServer connection
    # IMPORTANT: The username below is a SQL Server user, not a Windows user.
    database.type=SQLServer
    database.driver=net.sourceforge.jtds.jdbc.Driver
    database.url=jdbc:jtds:sqlserver://ThamesAG.wcu.edu/papercut
    database.username=Papercut.sa
    database.password=[see secret server]
  ```
