SELECT Distinct
  v_R_System.Netbios_Name0
  ,v_R_System.Full_Domain_Name0
  ,v_GS_PC_BIOS.SerialNumber0
  ,v_GS_COMPUTER_SYSTEM.UserName0
  ,v_GS_COMPUTER_SYSTEM.Manufacturer0
   ,CASE
  WHEN v_GS_COMPUTER_SYSTEM.Manufacturer0  LIKE 'Lenovo' THEN
  v_GS_COMPUTER_SYSTEM_PRODUCT.Version0
  ELSE v_GS_COMPUTER_SYSTEM.Model0
  END AS model
,CASE
WHEN v_GS_OPERATING_SYSTEM.Caption0 LIKE 'Windows 10%' THEN 'Windows 10'
WHEN v_GS_OPERATING_SYSTEM.Caption0 LIKE 'Windows 7%' THEN 'Windows 7'
ELSE 'Autre'
END AS OperatingSystem
  ,v_GS_OPERATING_SYSTEM.OSArchitecture0
  ,v_GS_OPERATING_SYSTEM.MUILanguages0
  ,v_GS_OPERATING_SYSTEM.BuildNumber0
  ,v_GS_OPERATING_SYSTEM.Version0
  ,v_GS_OPERATING_SYSTEM.LastBootUpTime0
  ,v_GS_OPERATING_SYSTEM.InstallDate0
  ,v_GS_LOGICAL_DISK.DeviceID0
  ,v_GS_LOGICAL_DISK.Size0
  ,v_GS_LOGICAL_DISK.FreeSpace0
  ,v_GS_X86_PC_MEMORY.TotalPhysicalMemory0
,CASE 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '1' THEN 'Virtual' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '2' THEN 'Server' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '3' THEN 'Desktop' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '4' THEN 'Desktop'
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '5' THEN 'Desktop'
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '6' THEN 'Desktop'
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '7' THEN 'Desktop' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '8' THEN 'Laptop' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '9' THEN 'Laptop' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '10' THEN 'Laptop' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '11' THEN 'Laptop' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '12' THEN 'Laptop' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '13' THEN 'Desktop'  
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '14' THEN 'Laptop' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '15' THEN 'Desktop'
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '16' THEN 'Desktop'
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '17' THEN 'Server'
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '18' THEN 'Laptop' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '19' THEN 'Server' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '20' THEN 'Server' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '21' THEN 'Laptop' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '22' THEN 'Server' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '23' THEN 'Server' 
  WHEN v_GS_SYSTEM_ENCLOSURE.chassistypes0 LIKE '24' THEN 'Server' 
 ELSE 'Unknown'
 END
  ,v_R_System.Client0
  ,v_R_System.User_Name0
  ,v_R_System.Last_Logon_Timestamp0
  ,v_CH_ClientSummary.LastSW
  ,v_CH_ClientSummary.LastHW
  ,v_CH_ClientSummary.LastPolicyRequest
  ,v_CH_ClientSummary.LastActiveTime
  ,v_CH_ClientSummary.LastHealthEvaluation
  ,v_GS_NETWORK_ADAPTER_CONFIGURATION.IPAddress0
  ,v_GS_NETWORK_ADAPTER_CONFIGURATION.IPSubnet0
  ,v_GS_NETWORK_ADAPTER_CONFIGURATION.DefaultIPGateway0
FROM
  v_R_System
  INNER JOIN v_FullCollectionMembership
    ON v_R_System.ResourceID = v_FullCollectionMembership.ResourceID
  LEFT OUTER JOIN v_GS_PC_BIOS
    ON v_R_System.ResourceID = v_GS_PC_BIOS.ResourceID
  LEFT OUTER JOIN v_GS_COMPUTER_SYSTEM
    ON v_R_System.ResourceID = v_GS_COMPUTER_SYSTEM.ResourceID
  LEFT OUTER JOIN v_GS_OPERATING_SYSTEM
    ON v_R_System.ResourceID = v_GS_OPERATING_SYSTEM.ResourceID
  LEFT OUTER JOIN v_GS_LOGICAL_DISK
    ON v_R_System.ResourceID = v_GS_LOGICAL_DISK.ResourceID
  LEFT OUTER JOIN v_GS_COMPUTER_SYSTEM_PRODUCT
    ON v_R_System.ResourceID = v_GS_COMPUTER_SYSTEM_PRODUCT.ResourceID
  LEFT OUTER JOIN v_GS_X86_PC_MEMORY
    ON v_R_System.ResourceID = v_GS_X86_PC_MEMORY.ResourceID
  LEFT OUTER JOIN v_GS_SYSTEM_ENCLOSURE
    ON v_R_System.ResourceID = v_GS_SYSTEM_ENCLOSURE.ResourceID
  LEFT OUTER JOIN v_CH_ClientSummary
    ON v_R_System.ResourceID = v_CH_ClientSummary.ResourceID
LEFT OUTER JOIN v_GS_NETWORK_ADAPTER_CONFIGURATION
    ON v_R_System.ResourceID = v_GS_NETWORK_ADAPTER_CONFIGURATION.ResourceID
WHERE
  v_FullCollectionMembership.CollectionID = @Collection