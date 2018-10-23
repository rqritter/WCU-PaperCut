# PaperCut Installation Settings for WCU <!-- omit in toc -->

### Notes <!-- omit in toc -->
- Updated: 10/23/2018
- Author: Richie Ritter
- https://github.com/rqritter/WCU-PaperCut

### Contents
- [PaperCut Application Server Post install Settings](#papercut-application-server-post-install-settings)
    - [Changes to Applcation Server settings files](#changes-to-applcation-server-settings-files)
        - [1. C:\Program Files\PaperCut MF\server\server.properties](#1-cprogram-filespapercut-mfserverserverproperties)
        - [2. C:\Program Files\PaperCut MF\server\custom\service.conf](#2-cprogram-filespapercut-mfservercustomserviceconf)
    - [Changes to Payment Gateway settings files (for CBORD)](#changes-to-payment-gateway-settings-files-for-cbord)
        - [1. C:\Program Files\PaperCut MF\server\lib-ext\ext-payment-gateway-cbord-dx.properties](#1-cprogram-filespapercut-mfserverlib-extext-payment-gateway-cbord-dxproperties)
- [Print Server Settings](#print-server-settings)

## PaperCut Application Server Post install Settings
MS failover Cluster named `papercut.wcu.edu`  
Virtual Applcation Server is `postscript.wcu.edu`  
Nodes are `courier.wcu.edu` and `copperplate.wcu.edu`  

### Changes to Applcation Server settings files

#### 1. C:\Program Files\PaperCut MF\server\server.properties

- Use Incommon Certificate
  - Create a keystore with the certificate pair and chain (For more information, see the KB article: https://www.papercut.com/kb/Main/SSLWithKeystoreExplorer)
  - Set Papercut to use the certificate
    ```
    ### SSL Key/Certificate ###
    # Custom SSL keystore example (recommend placing in the custom directory)
    server.ssl.keystore=custom/papercut-keystore
    server.ssl.keystore-password=[see secret server]
    server.ssl.key-password=[same as keystore password]
    ```
- Disable CSRF checks (needed for clustering)
  - Un-comment "server.csrf-check.validate-request-origin" and set to "N"  
    `server.csrf-check.validate-request-origin=N`
- Use External SQL Database
  - Comment out internal DB  
    `#database.type=Internal` 
  - Add Settings For SQL Server
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

- Increase the share of memory avalable to PaperCut. (For more information, see the KB article: https://www.papercut.com/kb/Main/IncreaseMaxMemoryUsage)  
  - Add the following new line to the file  
    `wrapper.java.additional.6=-XX:DefaultMaxRAMFraction=2`

### Changes to Payment Gateway settings files (for CBORD)

#### 1. C:\Program Files\PaperCut MF\server\lib-ext\ext-payment-gateway-cbord-dx.properties

- Enable CBORD Payment Gateway  
  `cbord-dx.enabled=Y`
- Set the CBORD server type to ODYSSEY  
  `cbord-dx.server.type=ODYSSEY`
- Specify the CBORD server IP Address  
  `cbord-dx.server.host=152.30.33.42`
- Specify the CBORD server port  
  `cbord-dx.server.port=3785` 
- Disable SSL/TLS connection to the CBORD server  
  `cbord-dx.server.ssl=N`
- Specify the --two digit-- Terminal Address to use when connecting to the CBORD server  
  `cbord-dx.location=01`
- Specify the CBORD code map (We are using "5" to indicate Cat Cash)  
  `cbord-dx.code-map=5` 
- Set a CBORD operator identifier (Required, but can be any 4 digit number)  
  `cbord-dx.operator=3141`
- Tell CBORD we are sending card numbers (instructed to set to "Y" by CBORD support)  
  `cbord-dx.sending-card-numbers=Y`
- Disable manual transfer (we are using "on-demand" instead)  
  `cbord-dx.manual-transfer.enabled=N`
- Enable on-demand transfer   
  `cbord-dx.on-demand-transfer.enabled=Y`

## Print Server Settings
F5 Load Balancer is acting as `printserver.wcu.edu`  
Backend servers are `serif.wcu.edu`, `helvetica.wcu.edu`, `palatino.wcu.edu`  
