class AccessionNewAndLevel1AccessionedByQuarter < AbstractReport
  register_report(
    params: [['from', Date, 'The start of report range'],
             ['to', Date, 'The start of report range']]
  )

  def initialize(params, job, db)
    super

    from = params['from'] || Time.now.to_s
    to = params['to'] || Time.now.to_s

    @from = DateTime.parse(from).to_time.strftime('%Y-%m-%d %H:%M:%S')
    @to = DateTime.parse(to).to_time.strftime('%Y-%m-%d %H:%M:%S')

    info[:scoped_by_date_range] = "#{@from} & #{@to}"
  end

  def query
    results = db.fetch(query_string)
    #info[:total_count] = results.count
    results
  end

  def query_string
    "SELECT 
    YEAR(accession.accession_date) AS 'Year',
    QUARTER(accession.accession_date) AS 'Quarter',
    COUNT(CASE
        WHEN
            (accession.identifier LIKE '%ua%'
                AND collection_management.processing_status_id = 61153)
        THEN
            1
        ELSE NULL
    END) AS 'UA New-Unprocessed Count',
    ROUND(SUM(CASE
                WHEN
                    (accession.identifier LIKE '%ua%'
                        AND collection_management.processing_status_id = 61153)
                THEN
                    extent.number
                ELSE 0
            END),
            2) AS 'UA New-Unprocessed LF',
    COUNT(CASE
        WHEN
            (accession.identifier LIKE '%ua%'
                AND collection_management.processing_status_id = 61145)
        THEN
            1
        ELSE NULL
    END) AS 'UA L1 Count',
    ROUND(SUM(CASE
                WHEN
                    (accession.identifier LIKE '%ua%'
                        AND collection_management.processing_status_id = 61145)
                THEN
                    extent.number
                ELSE 0
            END),
            2) AS 'UA L1 LF',
    COUNT(CASE
        WHEN
            (accession.identifier NOT LIKE '%ua%'
                AND collection_management.processing_status_id = 61153)
        THEN
            1
        ELSE NULL
    END) AS 'RL New-Unprocessed Count',
    ROUND(SUM(CASE
                WHEN
                    (accession.identifier NOT LIKE '%ua%'
                        AND collection_management.processing_status_id = 61153)
                THEN
                    extent.number
                ELSE 0
            END),
            2) AS 'RL New-Unprocessed LF',
    COUNT(CASE
        WHEN
            (accession.identifier NOT LIKE '%ua%'
                AND collection_management.processing_status_id = 61145)
        THEN
            1
        ELSE NULL
    END) AS 'RL L1 Count',
    ROUND(SUM(CASE
                WHEN
                    (accession.identifier NOT LIKE '%ua%'
                        AND collection_management.processing_status_id = 61145)
                THEN
                    extent.number
                ELSE 0
            END),
            2) AS 'RL L1 LF',
    COUNT(CASE
        WHEN collection_management.processing_status_id = 61153 THEN 1
        ELSE NULL
    END) AS 'Total New-Unprocessed Count',
    ROUND(SUM(CASE
                WHEN collection_management.processing_status_id = 61153 THEN extent.number
                ELSE 0
            END),
            2) AS 'Total New-Unprocessed LF',
    COUNT(CASE
        WHEN collection_management.processing_status_id = 61145 THEN 1
        ELSE NULL
    END) AS 'Total L1 Count',
    ROUND(SUM(CASE
                WHEN collection_management.processing_status_id = 61145 THEN extent.number
                ELSE 0
            END),
            2) AS 'Total L1 LF',
    COUNT(*) AS 'Total Accessions Count (New and L1)',
    ROUND(SUM(extent.number), 2) AS 'Total LF (New and L1)'
FROM
    accession
        LEFT JOIN
    extent ON accession.id = extent.accession_id
        LEFT JOIN
    collection_management ON accession.id = collection_management.accession_id
WHERE
    (extent_type_id IN (SELECT 
            id
        FROM
            enumeration_value
        WHERE
            LOWER(value) LIKE '%linear%'))
        AND repo_id = 2
        AND accession.accession_date >= #{db.literal(@from.split(' ')[0].gsub('-', ''))}
        AND accession.accession_date <= #{db.literal(@to.split(' ')[0].gsub('-', ''))}
        AND (collection_management.processing_status_id = 61145
        OR collection_management.processing_status_id = 61153)
GROUP BY Quarter(accession.accession_date), YEAR(accession.accession_date)
ORDER BY YEAR , Quarter"
  end

#  def fix_row(row)
#    ReportUtils.fix_identifier_format(row, :accession_number)
#  end

#  def identifier_field
#    :accession_number
#  end

  def page_break
    false
  end
end