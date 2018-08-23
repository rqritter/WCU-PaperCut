# PaperCut Application Server Post install Settings
Using a MS failover Cluster named `papercut.wcu.edu`  
Virtual Applcation Server is `postscript.wcu.edu`  
Nodes are `courier.wcu.edu` and `copperplate.wcu.edu`  

### Changes to Applcation Server settings files

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
#### 2. C:\Program Files\PaperCut MF\server\custom\service.conf

* Increase the share of memory avalable to PaperCut. (For more information, see the KB article: https://www.papercut.com/kb/Main/IncreaseMaxMemoryUsage)  
  * Add the following new line to the file
    ```
    wrapper.java.additional.6=-XX:DefaultMaxRAMFraction=2
    ```
### Changes to Payment Gateway settings files (for CBORD)

#### 3. C:\Program Files\PaperCut MF\server\lib-ext\ext-payment-gateway-cbord-dx.properties

* Enable CBORD Payment Gateway
    ```
    cbord-dx.enabled=Y
    ```
* Set the CBORD server type to ODYSSEY
    ```
    cbord-dx.server.type=ODYSSEY
    ```
 * Specify the CBORD server IP Address
    ```
    cbord-dx.server.host=152.30.33.42
    ```
 * Specify the CBORD server port
    ```
    cbord-dx.server.port=3785
    ``` 
 * Disable SSL/TLS connection to the CBORD server
    ```
    cbord-dx.server.ssl=N
    ```
 * Specify the (*two digit*) Terminal Address to use when connecting to the CBORD server
    ```
    cbord-dx.location=01
    ```  
    
