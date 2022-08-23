/* 
.PURPOSE
Pull the Item name/display name along with assigned Metadata details

MetadataTypeId	MetadataFieldId	ItemId	ItemName	    MetadataTypeName	MetadataFieldName	ItemValue
3	            1	            3	    ABC Company	    Folder	            Purpose	            Sample Company Folder Structure
1	            2	            4	    Sync API        Account	            User	            Expires	2021-07-29 22:00:00
1	            1	            4	    Sync API        Account	            User	            Purpose	API Account used by the sync process to access prod
2	            1	            2	    Test Secret AD	Secret	            Purpose	            Test Secret
3	            4	            3	    ABC Company	    Folder	            Owner	            Secret Server Admin
1	            3	            4	    Sync API        Account	            User	            DoNotDelete	TRUE
4	            2	            5	    Sync Group	    Group	            Expires	            2021-07-29 22:00:00
4	            1	            5	    Sync Group	    Group	            Purpose	            Group used to control access for sync process from prod
*/
SELECT 
    mfs.MetadataFieldSectionId
    ,mfs.MetadataFieldSectionName
    ,mid.MetadataTypeId
    ,mt.MetadataTypeName
    ,mid.MetadataFieldId
    ,mf.MetadataFieldName
    ,mid.ItemId
    ,CASE mt.MetadataTypeId
        WHEN 1 THEN u.DisplayName
        WHEN 2 THEN s.SecretName
        WHEN 3 THEN f.FolderName
        WHEN 4 THEN g.GroupName
    END AS ItemName
    ,CASE mf.MetadataFieldTypeId
        WHEN 1 THEN mid.ValueString
        WHEN 2 THEN IIF(mid.ValueBit = 1, 'TRUE', 'FALSE')
        WHEN 3 THEN CONVERT(VARCHAR(50), mid.ValueNumber)
        WHEN 4 THEN CONVERT(VARCHAR(25), mid.ValueDateTime, 120)
        WHEN 5 THEN (SELECT DisplayName FROM tbUser WHERE UserId = mid.ValueInt)
    END AS [ItemValue]
    -- ,mid.ValueString
    -- ,mid.ValueBit
    -- ,mid.ValueNumber
    -- ,mid.ValueDateTime
    -- ,mid.ValueInt
    -- ,mfs.MetadataFieldSectionName
FROM tbMetadataItemData AS mid
INNER JOIN tbMetadataType AS mt on mt.MetadataTypeId = mid.MetadataTypeId
INNER JOIN tbMetadataField AS mf ON mf.MetadataFieldId = mid.MetadataFieldId
INNER JOIN tbMetadataFieldSection AS mfs ON mfs.MetadataFieldSectionId = mf.MetadataFieldSectionId
LEFT JOIN tbFolder AS f ON f.FolderId = mid.ItemId
LEFT JOIN tbSecret AS s ON s.SecretId = mid.ItemId
LEFT JOIN tbGroup AS g ON g.GroupId = mid.ItemId
LEFT JOIN tbUser AS u ON u.UserId = mid.ItemId
-- WHERE mf.MetadataFieldId = 1