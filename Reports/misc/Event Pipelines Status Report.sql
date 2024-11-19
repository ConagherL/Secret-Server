  SELECT p.EventPipelineName AS 'Pipleline Name', a.StartDateTime AS 'Start Date/Time', a.EndDateTime AS 'End Date/Time', 
  CASE
	WHEN a.status = 0 THEN 'Failed'
	WHEN a.status = 1 THEN 'Successfully' 
	END AS 'Execution Status', a.Notes as 'Additional Information'
  
  FROM tbEventPipeline p
    INNER JOIN tbEventPipelineActivity a
	ON a.EventPipelineId = p.EventPipelineId

  ORDER BY p.EventPipelineName, a.StartDateTime ASC
	
