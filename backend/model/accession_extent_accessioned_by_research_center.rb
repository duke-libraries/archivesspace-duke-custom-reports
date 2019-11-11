class AccessionExtentAccessionedByResearchCenter < AbstractReport
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
    enumeration_value.value AS 'Research Center',
    COUNT(*) AS 'Total accessions measured in linear feet',
    ROUND(SUM(extent.number), 2) AS 'Linear feet'
FROM
    accession
        LEFT JOIN
    extent ON accession.id = extent.accession_id
        LEFT JOIN
    user_defined on accession.id = user_defined.accession_id
        LEFT JOIN
    enumeration_value ON user_defined.enum_2_id = enumeration_value.id
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
GROUP BY enumeration_value.value;"
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