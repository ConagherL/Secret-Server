SELECT
    ds.Name AS DiscoverySource, -- The name of the discovery source
    ou.Path AS OrganizationalUnit, -- The path of the organizational unit
    c.ComputerName AS HostName, -- The name of the computer
    c.ComputerVersion AS OperatingSystem, -- The operating system version of the computer
    ca.AccountName AS AccountName, -- The name of the account
    st.ScanItemTemplateName AS AccountType, -- The template name that defines the type of the account
    -- Determines the privilege level of the account based on the template ID and whether it is a local administrator
    CASE
        WHEN ca.ScanItemTemplateId = 13 AND ca.IsLocalAdministrator = 1 THEN 'Built-in Administrator'
        WHEN ca.ScanItemTemplateId = 13 AND ca.IsLocalAdministrator = 0 THEN 'Standard_User'
    END AS AccountPrivilege,
    -- Determines if the account has local admin rights based on the template ID and a flag indicating admin rights
    CASE
        WHEN ca.ScanItemTemplateId =13 AND ca.HasLocalAdminRights = 1 THEN 'Yes'
        WHEN ca.ScanItemTemplateId =13 AND ca.HasLocalAdminRights = 0 THEN 'No'
    END AS HasLocalAdminRights,
    -- Formats the date when the password was last set, or indicates it was never set
    CASE WHEN ca.PasswordLastSet IS NULL THEN 'Never'
        ELSE CONVERT(NVARCHAR,ca.PasswordLastSet)
    END AS PasswordLastSet,
    c.LastPolledDate AS LastScanned, -- The last date when the computer was scanned
    -- Identifies if a secret is managed for the account, or marks it as 'Unmanaged'
    CASE
        WHEN s.SecretName IS NULL THEN 'Unmanaged'
        ELSE s.SecretName
    END AS SecretName
-- Specifies the tables from which to retrieve the data, with the necessary joins to link related information
FROM tbComputer c
INNER JOIN tbComputerAccount ca ON ca.ComputerID = c.ComputerId
INNER JOIN tbOrganizationUnit ou ON c.OrganizationUnitId = ou.OrganizationUnitId
INNER JOIN tbScanItemTemplate st ON ca.ScanItemTemplateId = st.ScanItemTemplateId
INNER JOIN tbDiscoverySource ds ON c.DiscoverySourceId = ds.DiscoverySourceId
LEFT OUTER JOIN tbSecret s ON s.ComputerAccountId = ca.ComputerAccountId -- This left join ensures all accounts are listed, even those without a managed secret
-- Filters the results to only include active discovery sources and allows for a dynamic search term for discovery source names
WHERE ds.Active = 1 AND ds.Name LIKE '%' + #CUSTOMTEXT + '%'
-- Orders the results by computer name for easier navigation and review
ORDER BY c.ComputerName ASC
