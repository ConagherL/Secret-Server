select  
    c.ComputerName as Computer,  -- The name of the computer
    ca.AccountName as Account,  -- The name of the account on the computer
    sit.ScanItemTemplateName as [Scan Template],  -- The name of the scan item template applied
    c.ComputerVersion as [OS],  -- The operating system version of the computer
    c.DistinguishedName as Container,  -- The LDAP distinguished name of the computer's container
    s.SecretID,  -- The ID of the secret associated with the account, if any
    s.SecretName,  -- The name of the secret associated with the account, if any
    c.LastPolledDate as [Last Scanned],  -- The date when the computer was last scanned
    case when ca.HasLocalAdminRights like '1' then 'Yes' else 'No' End as [Is Local Admin],  -- Indicates if the account has local admin rights
    case when ca.IsLocalAdministrator like '1' then 'Yes' else 'No' End as [Has Admin Rights],  -- Indicates if the account is a local administrator
    DATEDIFF(DAY, ca.PasswordLastSet, GETDATE()) AS [Days Since PWD Change],  -- The number of days since the password was last changed
    CASE  -- Describes the password expiration status of the account
        WHEN ca.PasswordExpirationStatus = '0' THEN 'Unknown'
        WHEN ca.PasswordExpirationStatus = '1' THEN 'Normal'
        WHEN ca.PasswordExpirationStatus = '2' THEN 'DoesNotExpire'
        WHEN ca.PasswordExpirationStatus = '3' THEN 'MustChangeOnNextLogin'
        WHEN ca.PasswordExpirationStatus = '4' THEN 'Expired'
    END as 'Expiration Status',
    ds.Name as [Discovery Source],  -- The name of the discovery source that identified the computer
    case when s.SecretID is NULL then 'Unmanaged' else 'Managed' End as [Status]  -- Indicates if the account is managed or unmanaged based on the presence of a secret
from tbComputer c
left join tbComputerAccount ca on ca.ComputerId = c.ComputerId  -- Joins with the computer account table
left join tbDiscoverySource ds on c.DiscoverySourceId = ds.DiscoverySourceId  -- Joins with the discovery source table
left join tbScanItemTemplate sit on c.ScanItemTemplateId = sit.ScanItemTemplateId  -- Joins with the scan item template table
LEFT JOIN tbSecret s ON ca.ComputerAccountId = s.ComputerAccountId  -- Joins with the secrets table to determine managed status
where ds.Active = 1 and ds.Name like '%' + #CUSTOMTEXT + '%'  -- Filters for active discovery sources and a customizable text filter for discovery source names
