<-- Code is still in progress

SELECT 
    CONCAT('Secret Server Address: ', c.CustomURL) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'To be decomminsioned or scaled down post migration' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbConfiguration c

UNION ALL

SELECT 
    CONCAT('Secret Server Version: ', "Version") AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Version should be latest or within versions supported by the migration tool or code' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT TOP 1 (v.VersionNumber) AS "Version"
    FROM tbversion v
    ORDER BY Upgraded DESC, v.VersionNumber DESC
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Number of Web Servers: ', COUNT(NodeId)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Decomminsion web nodes as needed POST migration' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbNode n

UNION ALL

SELECT 
    CONCAT('Number of Domains: ', COUNT(DomainId)) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Total count of AD domains to migrate.' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbDomain d
WHERE d.Active = 1

UNION ALL

SELECT 
    CONCAT('Integrated Windows Auth: ', CASE WHEN c.IntegratedWindowsAuthentication = 0 THEN 'FALSE' WHEN c.IntegratedWindowsAuthentication = 1 THEN 'TRUE' ELSE NULL END) AS [Result],
    'Pre and Post' AS [Pre-Post],
    '' AS [Status],
    'IWA is not supported in SSC. Customer needs to update code to utilize SDK or some other mechinsim' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbConfiguration c

UNION ALL

SELECT 
    CONCAT('SAML Enabled: ', CASE WHEN sc.Enabled = 0 THEN 'FALSE' WHEN sc.Enabled = 1 THEN 'TRUE' ELSE NULL END) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Create new SAML provider for SSC. Do not re use exsiting configuration' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbSamlConfiguration sc

UNION ALL

SELECT 
    CONCAT('Number of Users: ', COUNT(UserId)) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Total number of combined local/AD users. This must match 1 for 1 or permission issues will arise' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbuser u
WHERE u.Enabled = 1

UNION ALL

SELECT 
    CONCAT('Number of Domain Users: ', COUNT(UserId)) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Total number of AD users. This must match 1 for 1 or permission issues will arise' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbuser u
WHERE u.Enabled = 1 AND u.DomainId IS NOT NULL

UNION ALL

SELECT 
    CONCAT('Number of Local Users: ', COUNT(UserId)) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Total number of local users. This must match 1 for 1 or permission issues will arise' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbuser u
WHERE u.Enabled = 1 AND u.DomainId IS NULL

UNION ALL

SELECT 
    CONCAT('Number of Application Accounts: ', COUNT(UserId)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Total number of application accounts. Accounts to be configured with same configuration/permissions' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbuser u
WHERE u.Enabled = 1 AND u.IsApplicationAccount = 1

UNION ALL

SELECT 
    CONCAT('Number of Active Users in the last 6 months: ', COUNT(*)) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Customer should reconsile users for migration. Migration only migrates permissions for active users' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT *
    FROM tbUser
    WHERE LastLogin >= DATEADD(MONTH, -6, GETDATE())
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Number of Sites: ', COUNT(SiteId)) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Site duplication must be done on destination tmeplate. Local site is changed to default atuomatically' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbSite si
WHERE si.Active = 1

UNION ALL

SELECT 
    CONCAT('Engines in Site ', SiteName, ':', COUNT(EngineId) OVER (PARTITION BY SITENAME)) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Total engine count per each site. Customer should have duplicated licensing requirement and engines should match what was exsiting' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbEngine E
    JOIN tbSite S ON S.SiteId = E.SiteId
WHERE E.ActivationStatus = 1

UNION ALL

SELECT 
    CONCAT('Allow Duplicate Secrets: ', CASE WHEN c.AllowDuplicateSecretNames = 0 THEN 'FALSE' WHEN c.AllowDuplicateSecretNames = 1 THEN 'TRUE' ELSE NULL END) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Check if duplicate secrets are allowed. It is recommended duplicate secrets ARE not allowed. Cleanup up duplicate secrets is required' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbConfiguration c

UNION ALL


SELECT 
    CONCAT('Require Folder for Secrets: ', CASE WHEN c.RequireFolderForSecret = 0 THEN 'FALSE' WHEN c.RequireFolderForSecret = 1 THEN 'TRUE' ELSE NULL END) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'As best practice and to mimic customers enviroment, this value should be TRUE' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbConfiguration c

UNION ALL

SELECT 
    CONCAT('Number of Secrets: ', COUNT(SecretID)) AS [Result],
    'Migration' AS [Pre-Post],
    '' AS [Status],
    'Total count of "Active" secrets in the customers enviroment' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbSecret s
WHERE s.Active = 1

UNION ALL

SELECT 
    CONCAT('Duplicate Secret Count: ', COUNT(*)) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Total count of duplicated secrets. Each duplicated secret should be unique' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT s.SecretID AS [SecretID],
        ISNULL(f.FolderPath, 'No folder assigned') AS [Folder Path],
        s.secretname AS [Secret Name],
        st.secrettypename AS [Type]
    FROM tbsecret s
        JOIN (
            SELECT SecretName,
                COUNT(SecretName) AS [Total]
            FROM tbsecret t
            WHERE t.active = 1
            GROUP BY SecretName
            HAVING COUNT(SecretName) > 1
        ) t ON s.SecretName = t.SecretName
        LEFT JOIN tbfolder f ON s.folderid = f.folderid
        INNER JOIN tbsecrettype st ON s.secrettypeid = st.secrettypeid
    WHERE s.active = 1
    GROUP BY s.SecretName,
        f.FolderPath,
        s.FolderId,
        s.SecretID,
        st.secrettypename
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Secrets Without Folders: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted secrets without folders for organization' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT s.SecretId,
        s.SecretName as [Secret],
        st.SecretTypeName as [Template],
        CASE
            WHEN s.FolderId IS NULL THEN 'No Folder'
        END AS [Folder]
    FROM tbSecret s
        INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
    WHERE s.FolderId IS NULL
        AND s.Active = 1
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Secrets Without Owners: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted secrets without owners for reassignment' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT DISTINCT s.SecretID AS [SecretID],
        ISNULL(f.FolderPath, 'No folder assigned') AS [Folder Path],
        s.SecretName AS [Secret Name]
    FROM vGroupSecretPermissions gsp
        INNER JOIN tbUserGroup ug ON gsp.GroupId = ug.GroupID
        INNER JOIN tbuser u ON ug.UserID = u.UserId
        INNER JOIN tbSecret s ON gsp.SecretId = s.SecretId
        LEFT JOIN tbFolder f ON s.FolderId = f.FolderID
        INNER JOIN tbGroup g ON ug.GroupID = g.GroupID
    WHERE s.Active = 1
        AND u.Enabled = 1
        AND (
            s.SecretID NOT IN (
                SELECT gsp2.SecretID
                FROM vGroupSecretPermissions gsp2
                    INNER JOIN tbgroup g2 ON gsp2.GroupId = g2.GroupID
                    INNER JOIN tbUserGroup ug2 ON gsp2.GroupId = ug2.GroupID
                    INNER JOIN tbuser u2 ON ug2.UserID = u2.UserId
                WHERE gsp2.OwnerPermission = 1
                    AND u2.Enabled = 1
            )
        )
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Secrets Using Inactive Templates: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted secrets using inactive templates for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT s.created AS [Created],
        s.secretname AS [Secret Name],
        ISNULL(f.FolderPath, 'No folder assigned') AS [Folder Path]
    FROM tbsecret s
        LEFT JOIN tbfolder f ON s.folderid = f.folderid
        INNER JOIN tbSecretType st ON s.SecretTypeID = st.SecretTypeID
    WHERE st.Active = 0
        AND s.Active = 1
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Secrets in Personal Subfolders: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted secrets in personal subfolders for consolidation' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT s.SecretID AS [ID],
        s.secretname AS [Secret Name],
        f.folderpath AS [Location]
    FROM tbsecret s
        INNER JOIN tbfolder f ON s.folderid = f.folderid
    WHERE s.Active = 1
        AND f.FolderPath LIKE '%PERSONAL Folders\%\%'
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Secrets in Inactive Personal Folders: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted secrets in inactive personal folders for cleanup' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT s.secretid AS [SecretId],
        s.secretname AS [Secret Name],
        f.folderpath AS [Location]
    FROM tbfolder f
        INNER JOIN tbsecret s ON s.FolderId = f.FolderID
        INNER JOIN tbUser u ON f.UserId = u.UserId
    WHERE f.FolderPath LIKE '%PERSONAL Folders\%'
        AND s.Active = 1
        AND u.Enabled = 0
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Number of Policies: ', COUNT(SecretPolicyId)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted active policies for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbSecretPolicy p
WHERE p.Active = 1

UNION ALL

SELECT 
    CONCAT('Direct Policy Assignments: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted direct policy assignments for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT s.SecretId AS [Secret ID],
        s.SecretName AS [Secret Name],
        ISNULL(f.FolderPath, 'No folder assigned') AS [Folder Path],
        sp.SecretPolicyName AS [Policy]
    FROM tbSecret s
        LEFT JOIN tbfolder f ON s.FolderId = f.FolderID
        INNER JOIN tbSecretPolicy sp ON s.SecretPolicyId = sp.SecretPolicyId
    WHERE s.Active = 1
        AND s.EnableInheritSecretPolicy = 0
        AND s.SecretPolicyId IS NOT NULL
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Discovery Enabled: ', CASE WHEN dc.EnableDiscovery = 0 THEN 'FALSE' WHEN dc.EnableDiscovery = 1 THEN 'TRUE' ELSE NULL END) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Check if discovery is enabled' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbDiscoveryConfiguration dc

UNION ALL

SELECT 
    CONCAT('Discovery Sources: ', COUNT(DiscoverySourceId)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted active discovery sources' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT ds.DiscoverySourceId
    FROM tbDiscoverySource ds
    WHERE ds.Active = 1
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Discovery Import Rules: ', COUNT(DiscoveryImportRuleId)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted active discovery import rules' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT dr.DiscoveryImportRuleId
    FROM tbDiscoveryImportRule dr
    WHERE dr.Active = 1
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Password Rotation Enabled: ', CASE WHEN c.EnablePasswordChanging = 0 THEN 'FALSE' WHEN c.EnablePasswordChanging = 1 THEN 'TRUE' ELSE NULL END) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Check if password rotation is enabled' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbConfiguration c

UNION ALL

SELECT 
    CONCAT('Heartbeat globally enabled: ', CASE WHEN c.[EnableHeartBeat] = 0 THEN 'FALSE' WHEN c.[EnableHeartBeat] = 1 THEN 'TRUE' ELSE NULL END) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Check if heartbeat is globally enabled' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM [tbConfiguration] c

UNION ALL

SELECT 
    CONCAT('Modified Templates: ', COUNT(DISTINCT CAST("Template ID" AS INT))) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted modified templates for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT a.DateRecorded AS [Date],
        a.ItemId AS [Template ID],
        a.Action AS [Event],
        st.SecretTypeName AS [Template],
        a.Notes AS [Notes]
    FROM tbAudit a
        INNER JOIN tbUser u ON a.UserId = u.UserId
        INNER JOIN tbSecretType st ON a.ItemId = st.SecretTypeID
    WHERE (
            st.Active = 1
            AND a.AuditTypeId = 3
            AND a.Notes LIKE 'Field%'
        )
        AND NOT EXISTS (
            SELECT b.Action
            FROM tbAudit b
            WHERE b.itemid = a.itemid
                AND b.Action LIKE '%EATE%'
        )
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Custom Templates: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted custom templates for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT DISTINCT a.DateRecorded AS [Date],
        u.DisplayName AS [Display Name],
        a.Action AS [Event],
        st.SecretTypeName AS [Template],
        a.ItemId AS [Template ID]
    FROM tbAudit a
        INNER JOIN tbUser u ON a.UserId = u.UserId
        INNER JOIN tbSecretType st ON a.ItemId = st.SecretTypeID
    WHERE st.Active = 1
        AND (
            a.AuditTypeID = 3
            AND a.Action LIKE '%EATE%'
        )
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Custom Scripts: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted custom scripts for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT DISTINCT a.DateRecorded AS [Date],
        u.DisplayName AS [Display Name],
        a.Action AS [Event],
        sc.Name AS [Script],
        sct.Name AS [Script Type]
    FROM tbAudit a
        INNER JOIN tbUser u ON a.UserId = u.UserId
        INNER JOIN tbScript sc ON a.ItemId = sc.ScriptId
        INNER JOIN tbScriptType sct ON sc.ScriptTypeId = sct.ScriptTypeId
    WHERE sc.Active = 1
        AND (
            a.AuditTypeID = 5
            AND a.Action LIKE '%EATE%'
        )
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Custom Launchers: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted custom launchers for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT DISTINCT a.DateRecorded AS [Date],
        u.DisplayName AS [Display Name],
        a.Action AS [Event],
        lt.Name AS [Launcher]
    FROM tbAudit a
        INNER JOIN tbUser u ON a.UserId = u.UserId
        INNER JOIN tbLauncherType lt ON a.ItemId = lt.LauncherTypeId
    WHERE lt.Active = 1
        AND (
            a.AuditTypeID = 4
            AND a.Action LIKE '%EATE%'
        )
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Custom Password Changers: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted custom password changers for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT DISTINCT pta.Date AS [Date],
        u.DisplayName AS [Display Name],
        pta.Action AS [Event],
        pt.Name AS [Password Changer]
    FROM tbPasswordTypeAudit pta
        INNER JOIN tbUser u ON pta.UserId = u.UserId
        INNER JOIN tbPasswordType pt ON pta.PasswordTypeId = pt.PasswordTypeId
    WHERE pt.Active = 1
        AND pta.Action LIKE '%EATE%'
        AND pta.Notes NOT LIKE '%Pass%'
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Custom Password Requirements: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted custom password requirements for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT DISTINCT pra.Date AS [Date],
        u.DisplayName AS [Display Name],
        pra.Action AS [Event],
        pr.Name AS [Password Requirement]
    FROM tbPasswordRequirementAudit pra
        INNER JOIN tbUser u ON pra.UserId = u.UserId
        INNER JOIN tbPasswordRequirement pr ON pra.PasswordRequirementId = pr.PasswordRequirementId
    WHERE pra.Action LIKE '%EATE%'
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Custom Character Sets: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted custom character sets for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT DISTINCT csa.Date AS [Date],
        u.DisplayName AS [Display Name],
        csa.Action AS [Event],
        cs.Name AS [Character Set]
    FROM tbCharacterSetAudit csa
        INNER JOIN tbUser u ON csa.UserId = u.UserId
        INNER JOIN tbCharacterSet cs ON csa.CharacterSetId = cs.CharacterSetId
    WHERE csa.Action LIKE '%EATE%'
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Active Secrets With Files: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted active secrets with files for migration' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT [SecretItemID]
    FROM [tbSecretItem] [si]
        JOIN [tbSecretField] [sf] ON [si].[SecretFieldID] = [sf].[SecretFieldID]
        JOIN [tbFileAttachment] [fa] ON [si].[FileAttachmentId] = [fa].[FileAttachmentId]
        JOIN [tbSecret] [s] ON [si].[SecretID] = [s].[SecretID]
    WHERE [sf].[IsFile] = 1
        AND [s].[Active] = 1
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Categorized Lists: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted categorized lists for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbCategorizedList

UNION ALL

SELECT 
    CONCAT('Active SDK Accounts: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted active SDK accounts for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT *
    FROM [tbSdkClientAccount]
    WHERE [Revoked] <> 1
) AS [Result]

UNION ALL

SELECT 
    CONCAT('SDK Unique Client IPs: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted SDK unique client IPs for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT DISTINCT IpAddress
    FROM tbSdkClientAccount
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Custom SQL Reports: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted custom SQL reports for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT *
    FROM [tbCustomReport]
    WHERE [IsStandardReport] <> 1
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Event Subscriptions: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted event subscriptions for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbEventSubscription

UNION ALL

SELECT 
    CONCAT('Workflows: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted workflows for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbWorkflowTemplate

UNION ALL

SELECT 
    CONCAT('Teams: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted teams for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbTeam

UNION ALL

SELECT 
    CONCAT('Session Recording Enabled: ', CASE WHEN c.EnableSessionRecording = 0 THEN 'FALSE' WHEN c.EnableSessionRecording = 1 THEN 'TRUE' ELSE NULL END) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Check if session recording is enabled' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbConfiguration c

UNION ALL

SELECT 
    CONCAT('Advanced Session Recording Enabled: ', CASE WHEN asr.Enabled = 0 THEN 'FALSE' WHEN asr.Enabled = 1 THEN 'TRUE' ELSE NULL END) AS [Result],
    'Pre' AS [Pre-Post],
    '' AS [Status],
    'Check if advanced session recording is enabled' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM tbAdvancedSessionRecordingConfiguration asr

UNION ALL

SELECT 
    CONCAT('Quantum Locks: ', COUNT(*)) AS [Result],
    'POST' AS [Pre-Post],
    '' AS [Status],
    'Total count of Quantum Locks. Update configuration POST migration' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM [tbDoubleLock]

UNION ALL

SELECT 
    CONCAT('Folders with leading or trailing spaces: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted folders with leading or trailing spaces for cleanup' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT foldername,
        FolderPath,
        f.folderid
    FROM tbfolder f
    WHERE foldername LIKE ' %'
        OR foldername LIKE '% '
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Secrets with leading or trailing spaces: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted secrets with leading or trailing spaces for cleanup' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT secretname,
        FolderPath
    FROM tbsecret s
        JOIN tbfolder f ON f.FolderID = s.folderid
    WHERE secretname LIKE ' %'
        OR secretname LIKE '% '
) AS [Result]

UNION ALL

SELECT 
    CONCAT('Secrets with OTP Codes added: ', COUNT(*)) AS [Result],
    'Post' AS [Pre-Post],
    '' AS [Status],
    'Counted secrets with OTP codes added for review' AS [Migration Notes],
    '' AS [Consultants Notes]
FROM (
    SELECT f.folderpath,
        SecretName,
        t.SecretTypeName AS [Template]
    FROM tbSecret s
        JOIN tbFolder f ON f.FolderID = s.FolderId
        JOIN tbSecretType t ON t.SecretTypeID = s.SecretTypeID
        LEFT JOIN tbSecretOneTimePasswordSettings otp ON otp.SecretId = s.SecretID
    WHERE s.active = 1
        AND otp.Enabled = 1
) AS [Result]
