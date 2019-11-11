class AccessionLevel1AccessionedByQuarter < AbstractReport
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
    COUNT(*) AS 'Count of accessions processed to Level 1',
    COUNT(CASE
        WHEN accession.identifier LIKE '%ua%' THEN 1
        ELSE NULL
    END) AS Count_UAAccessions,
    ROUND(SUM(CASE
                WHEN accession.identifier LIKE '%ua%' THEN extent.number
                ELSE 0
            END),
            2) AS 'UA Level 1 Linear feet',
    COUNT(CASE
        WHEN accession.identifier NOT LIKE '%ua%' THEN 1
        ELSE NULL
    END) AS Count_RLAccessions,
    ROUND(SUM(CASE
                WHEN accession.identifier NOT LIKE '%ua%' THEN extent.number
                ELSE 0
            END),
            2) AS 'RL Level 1 Linear feet',
    ROUND(SUM(extent.number), 2) AS 'Total L1 Linear feet'
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
        AND collection_management.processing_status_id = 61145
GROUP BY Quarter(accession.accession_date), Year(accession.accession_date)
ORDER BY YEAR, Quarter"
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