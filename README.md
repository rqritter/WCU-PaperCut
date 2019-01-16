# PaperCut Installation Settings for WCU

### Notes
- Updated: 10/23/2018
- Author: Richie Ritter

### Contents
- [PaperCut Installation Settings for WCU](#papercut-installation-settings-for-wcu)
    - [Notes](#notes)
    - [Contents](#contents)
  - [1. PaperCut Application Server](#1-papercut-application-server)
    - [Changes to Applcation Server configuration files](#changes-to-applcation-server-configuration-files)
      - [C:\Program Files\PaperCut MF\server\server.properties](#cprogram-filespapercut-mfserverserverproperties)
      - [C:\Program Files\PaperCut MF\server\custom\service.conf](#cprogram-filespapercut-mfservercustomserviceconf)
    - [Changes to Payment Gateway settings files (for CBORD)](#changes-to-payment-gateway-settings-files-for-cbord)
      - [C:\Program Files\PaperCut MF\server\lib-ext\ext-payment-gateway-cbord-dx.properties](#cprogram-filespapercut-mfserverlib-extext-payment-gateway-cbord-dxproperties)
    - [Customizations in PaperCut Application](#customizations-in-papercut-application)
      - [Options - General](#options---general)
      - [Options - Notifications](#options---notifications)
      - [Options - Admin Rights](#options---admin-rights)
      - [Options - Configuration Editor (Advanced)](#options---configuration-editor-advanced)
    - [Automation (Card ID imports/updates)](#automation-card-id-importsupdates)
    - [ADFS Setup](#adfs-setup)
  - [2. Secondary Print Servers](#2-secondary-print-servers)
    - [Changes to Print Server configuration files](#changes-to-print-server-configuration-files)
      - [C:\Program Files\PaperCut MF\providers\print\win\print-provider.conf](#cprogram-filespapercut-mfprovidersprintwinprint-providerconf)
    - [Registry changes to enable Print Server clustering](#registry-changes-to-enable-print-server-clustering)
      - [PowerShell commands](#powershell-commands)
      - [Detail of registry changes](#detail-of-registry-changes)
    - [Modify the local hosts file of the servers](#modify-the-local-hosts-file-of-the-servers)
  - [3. Mobility Print Server](#3-mobility-print-server)
    - [Changes to Mobility Print Server configuration files](#changes-to-mobility-print-server-configuration-files)
      - [C:\Program Files\PaperCut MF\..](#cprogram-filespapercut-mf)
  - [4. Web Print Sandbox Server](#4-web-print-sandbox-server)
    - [Changes to Applcation Server configuration files](#changes-to-applcation-server-configuration-files-1)
      - [C:\Program Files\PaperCut MF\..](#cprogram-filespapercut-mf-1)
  - [5. RightFax Server](#5-rightfax-server)
    - [Changes to Applcation Server configuration](#changes-to-applcation-server-configuration)
      - [Detail](#detail)

## 1. PaperCut Application Server
- MS failover Cluster named `papercut.wcu.edu`  
- Virtual Applcation Server is `postscript.wcu.edu`  
- Nodes are `courier.wcu.edu` and `copperplate.wcu.edu`  

### Changes to Applcation Server configuration files

#### C:\Program Files\PaperCut MF\server\server.properties

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
#### C:\Program Files\PaperCut MF\server\custom\service.conf

- Increase the share of memory avalable to PaperCut. (For more information, see the KB article: https://www.papercut.com/kb/Main/IncreaseMaxMemoryUsage)  
  - Add the following new line to the file  
    `wrapper.java.additional.6=-XX:DefaultMaxRAMFraction=2`

### Changes to Payment Gateway settings files (for CBORD)

#### C:\Program Files\PaperCut MF\server\lib-ext\ext-payment-gateway-cbord-dx.properties

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

### Customizations in PaperCut Application

#### Options - General
- TBD (document when we recieve new license)  

#### Options - Notifications
- TBD (document when we recieve new license)  

#### Options - Admin Rights
- TBD (document when we recieve new license)  

#### Options - Configuration Editor (Advanced)
- Set card reader converter to ASCII  
  `ext-device.card-no-converter=ascii-enc`
- TBD (document when we recieve new license)  

### Automation (Card ID imports/updates)
- Windows Task Scheduler runs `C:\Scripts\Update-CardNumbersFull.ps1` daily at 6:15 AM  
- Task is scheduled on both nodes, but only executes on the active node  
- Details can be found in the powershell script  

### ADFS Setup
- See KB Article: https://www.papercut.com/kb/Main/DeployPaperCutWithSAMLSingleSignOn  

## 2. Secondary Print Servers
- F5 Load Balancer is acting as `printserver.wcu.edu`  
- Backend servers are `serif.wcu.edu`, `helvetica.wcu.edu`, `palatino.wcu.edu`  
- Settings need to be done on each of the backend servers  

### Changes to Print Server configuration files

#### C:\Program Files\PaperCut MF\providers\print\win\print-provider.conf

- Define the name or IP address of the application server  
  `ApplicationServer=postscript.wcu.edu`
- Set the system name reported by the server (cluster FQDN)  
  `ServerName=printserver.wcu.edu`
- Change the name of the server used when binding to print queues (cluster FQDN)  
  `PrintServerName=\\printserver.wcu.edu`
- Change the SNMP Community string used to query the printers (see SecretServer for Actual SNMP Community string)  
  `SNMPCommunity=public`

### Registry changes to enable Print Server clustering
- Some of these are no longer needed but this was the configuration that we tested  
- i.e. `OptionalNames` does not do anything because `DisableStrictNameChecking` is enabled  

#### PowerShell commands
  - Run in an elevated PowerShell session
    ```
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Print -Name DnsOnWire -PropertyType DWord -Value 1
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name DisableLoopbackCheck -PropertyType DWord -Value 1
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0 -Name BackConnectionHostNames -PropertyType MultiString -Value ('printserver',' printserver.wcu.edu')
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters -Name DisableStrictNameChecking -PropertyType DWord -Value 1
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters -Name OptionalNames -PropertyType MultiString -Value printserver
    ```
#### Detail of registry changes

- HKLM\SYSTEM\CurrentControlSet\Control\Print  
  `DWORD: DnsOnWire = 1`
- HKLM\SYSTEM\CurrentControlSet\Control\Lsa  
  `DWORD: DisableLoopbackCheck = 1`
- HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0  
  `REG_MULTI_SZ: BackConnectionHostNames = ('printserver', 'printserver.wcu.edu')`
- HKLM\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters  
  `DWORD Value: DisableStrictNameChecking = 1`
- HKLM\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters  
  `Multi-String Value: OptionalNames = printserver`

### Modify the local hosts file of the servers
  - Add the **LOCAL SERVER IP** Address with cluster name and FQDN to the hosts file
    ```
    152.30.35.XX     printserver.wcu.edu
    152.30.35.XX     printserver
    ```

## 3. Mobility Print Server
- Mobility Print Server `wingding.wcu.edu`  
- Acts as DNS Server for `mobile-print.wcu.edu`  
- TBD  

### Changes to Mobility Print Server configuration files

#### C:\Program Files\PaperCut MF\..

## 4. Web Print Sandbox Server
- Server `sceptre.wcu.edu`  
- TBD  

### Changes to Applcation Server configuration files

#### C:\Program Files\PaperCut MF\..

## 5. RightFax Server
- Server `ditto.wcu.edu`  
- TBD  

### Changes to Applcation Server configuration

#### Detail
