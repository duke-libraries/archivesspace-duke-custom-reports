class AccessionExtentAccessionedLinearFeetByQuarter < AbstractReport
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
      COUNT(*) AS 'Total accessions measured in linear feet',
      COUNT(CASE
          WHEN accession.identifier LIKE '%ua%' THEN 1
          ELSE NULL
      END) AS Count_UAAccessions,
      ROUND(SUM(CASE
          WHEN accession.identifier LIKE '%ua%' THEN extent.number
          ELSE 0
          END),
          2) AS 'UA Linear feet',
      COUNT(CASE
        WHEN accession.identifier NOT LIKE '%ua%' THEN 1
        ELSE NULL
    END) AS Count_OtherAccessions,
      ROUND(SUM(CASE
                WHEN accession.identifier NOT LIKE '%ua%' THEN extent.number
                ELSE 0
            END),
            2) AS 'Other Linear feet',
      ROUND(SUM(extent.number), 2) AS 'Total Linear feet'
    FROM
        accession
            LEFT JOIN
                extent ON accession.id = extent.accession_id
    WHERE
        (extent_type_id IN (SELECT 
            id
        FROM
            enumeration_value
        WHERE
            LOWER(value) LIKE '%linear%'))
            and accession_date >= #{db.literal(@from.split(' ')[0].gsub('-', ''))} 
            and accession_date <= #{db.literal(@to.split(' ')[0].gsub('-', ''))}
            and repo_id = 2
    GROUP BY Quarter(accession.accession_date), YEAR(accession.accession_date)
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