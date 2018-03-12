library(RODBC)

db = odbcConnect("mysql_driver_64", uid="root", pwd="mypassword")
sqlQuery(db, "USE ma_charity_full")


# -------------------Quick View of all tables--------------------

query_assignment_view = "SELECT * FROM assignment2 WHERE (calibration = 1)"
assign_view = sqlQuery(db, query_assignment_view)
View(assign_view) 

query_actions_view = "SELECT * FROM actions LIMIT 100 "
actions_view = sqlQuery(db, query_actions_view)
View(actions_view) 

query_acts_view = "SELECT * FROM acts "
acts_view = sqlQuery(db, query_acts_view)
View(acts_view) 

query_channels_view = "SELECT * FROM channels LIMIT 100 "
channels_view = sqlQuery(db, query_channels_view)
View(channels_view) 

query_contacts_view = "SELECT * FROM contacts LIMIT 100 "
contacts_view = sqlQuery(db, query_contacts_view)
View(contacts_view) 

query_payment_methods_view = "SELECT * FROM payment_methods LIMIT 100 "
payment_methods_view = sqlQuery(db, query_payment_methods_view)
View(payment_methods_view) 

query_prefixes_view = "SELECT * FROM prefixes LIMIT 100 "
prefixes_view = sqlQuery(db, query_prefixes_view)
View(prefixes_view) 

# ---------------------------------------------------------------------------
#max(acts_view$act_date)

#   group the donnors according to time:
# s1: 2015-2017
# s2: 2010-2015
# s3: 2000-2010
# s4: -2000
# NOTE: "campaign_id is NULL" has been removed

query4 = "SELECT ass.contact_id,
ass.calibration,
ass.donation, 
ass.amount AS 'targetamount',

seg1.freq_s1,
seg1.sum_s1,
seg2.freq_s2,
seg2.sum_s2,
seg3.freq_s3,
seg3.sum_s3,
seg4.freq_s4,
seg4.sum_s4,

at.total_amount,
at.avg_amount,
at.max_amount,
at.min_amount,
at.frequency,
at.last_act,
at.recency,

p.PA_count,
p.PA_amount,
d.DO_count,
d.DO_amount,


chma.ch_MA,
chww.ch_WW,
chst.ch_ST,
chte.ch_TE,
chev.ch_EV,
chqu.ch_QU,

pch.p_CH,
ppr.p_PR,
pcb.p_CB,
pvi.p_VI,
pes.p_ES,
pqu.p_QU,


c.prefix,
c.zip_code,
c.active

FROM assignment2 ass

LEFT JOIN (SELECT contact_id,
SUM(amount) AS 'sum_s1',
COUNT(amount) AS 'freq_s1'
FROM acts
WHERE (campaign_id IS NOT NULL)
AND (act_date >='2015-01-01')
AND (act_date <='2017-12-31')
AND (campaign_id != 'C189')
GROUP BY 1) AS seg1
ON ass.contact_id = seg1.contact_id

LEFT JOIN (SELECT contact_id,
SUM(amount) AS 'sum_s2',
COUNT(amount) AS 'freq_s2'
FROM acts
WHERE (campaign_id IS NOT NULL)
AND (act_date >='2010-01-01')
AND (act_date <='2014-12-31')
GROUP BY 1) AS seg2
ON ass.contact_id = seg2.contact_id

LEFT JOIN (SELECT contact_id,
SUM(amount) AS 'sum_s3',
COUNT(amount) AS 'freq_s3'
FROM acts
WHERE (campaign_id IS NOT NULL)
AND (act_date >='2000-01-01')
AND (act_date <='2009-12-31')
GROUP BY 1) AS seg3
ON ass.contact_id = seg3.contact_id

LEFT JOIN (SELECT contact_id,
SUM(amount) AS 'sum_s4',
COUNT(amount) AS 'freq_s4'
FROM acts
WHERE (campaign_id IS NOT NULL)
AND (act_date <='1999-12-31')
GROUP BY 1) AS seg4
ON ass.contact_id = seg4.contact_id

LEFT JOIN (SELECT contact_id,
SUM(amount) AS 'total_amount',
CEILING(AVG(amount)) AS 'avg_amount',
MAX(amount) AS 'max_amount',
MIN(amount) AS 'min_amount',
COUNT(amount) AS 'frequency',
MAX(act_date) AS 'last_act',
DATEDIFF(20121101, MAX(act_date))/ 365 AS 'recency'

FROM acts 
WHERE campaign_id IS NOT NULL
GROUP BY 1) AS at 
ON ass.contact_id = at.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'PA_count',
SUM(amount) AS'PA_amount'
FROM acts
WHERE (act_type_id LIKE 'PA') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS p
ON ass.contact_id = p.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'DO_count',
SUM(amount) AS 'DO_amount'
FROM acts
WHERE (act_type_id LIKE 'DO') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS d
ON ass.contact_id = d.contact_id



LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'ch_MA'
FROM acts 
WHERE (channel_id LIKE 'MA') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS chma
ON ass.contact_id = chma.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'ch_WW'
FROM acts 
WHERE (channel_id LIKE 'WW') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS chww
ON ass.contact_id = chww.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'ch_ST'
FROM acts 
WHERE (channel_id LIKE 'ST') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS chst
ON ass.contact_id = chst.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'ch_TE'
FROM acts 
WHERE (channel_id LIKE 'TE') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS chte
ON ass.contact_id = chte.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'ch_EV'
FROM acts 
WHERE (channel_id LIKE 'EV') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS chev
ON ass.contact_id = chev.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'ch_QU'
FROM acts 
WHERE (channel_id LIKE 'QU') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS chqu
ON ass.contact_id = chqu.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'p_CH'
FROM acts 
WHERE (payment_method_id LIKE 'CH') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS pch
ON ass.contact_id = pch.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'p_PR'
FROM acts 
WHERE (payment_method_id LIKE 'PR') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS ppr
ON ass.contact_id = ppr.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'p_CB'
FROM acts 
WHERE (payment_method_id LIKE 'CB') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS pcb
ON ass.contact_id = pcb.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'p_VI'
FROM acts 
WHERE (payment_method_id LIKE 'VI') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS pvi
ON ass.contact_id = pvi.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'p_ES'
FROM acts 
WHERE (payment_method_id LIKE 'ES') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS pes
ON ass.contact_id = pes.contact_id

LEFT JOIN (SELECT contact_id,
COUNT(*) AS 'p_QU'
FROM acts 
WHERE (payment_method_id LIKE 'QU') AND (campaign_id IS NOT NULL)
GROUP BY 1) AS pqu
ON ass.contact_id = pqu.contact_id

LEFT JOIN (SELECT id, prefix_id As prefix, zip_code, active
FROM contacts
GROUP BY 1) AS c
ON ass.contact_id = c.id 

GROUP BY 1
"


all_features = sqlQuery(db, query4)
View(all_features)                   


odbcClose(db)

