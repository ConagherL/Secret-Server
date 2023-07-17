DECLARE @DiscoverySource AS VARCHAR(100)=#CUSTOMTEXT
select csl.status, csl.computerid, c.ComputerName, count(csl.Status) as numberoferrors
from tbComputerScanLog csl, tbComputer c
where 
   csl.Success = 0
and
   csl.ComputerId in (select ComputerId from tbComputer where DiscoverySourceId in (select DiscoverySourceId from tbDiscoverySource where Name = @DiscoverySource)) 
AND
   csl.ScanDate between #STARTDATE and #ENDDATE 
and
   csl.DiscoveryItemScannerId in (select dis.DiscoveryItemScannerId from tbDiscoverySource ds, tbDiscoveryItemScanner dis where ds.Name = @DiscoverySource and 
    dis.DiscoveryScannerId = ds.DiscoveryScannerId)
AND
   c.ComputerName in (select ComputerName from tbComputer where ComputerId = csl.ComputerId) 
group by 
   csl.ComputerId,
   c.ComputerName,
   csl.Status,
   csl.DiscoveryItemScannerId
order by 
   csl.ComputerId, c.ComputerName, csl.Status
