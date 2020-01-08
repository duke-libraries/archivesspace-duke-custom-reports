class AccessionAccessionsLackingExtentLinearFeet < AbstractReport
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
    accession.identifier as accession_number,
    accession.title,
    extent.number,
    enumeration_value.value
    FROM
    accession
        LEFT JOIN
    extent ON accession.id = extent.accession_id
        LEFT JOIN
    enumeration_value ON extent.extent_type_id = enumeration_value.id
    WHERE
    repo_id = 2
        AND accession.accession_date >= #{db.literal(@from.split(' ')[0].gsub('-', ''))}
        AND accession.accession_date <= #{db.literal(@to.split(' ')[0].gsub('-', ''))}
        AND NOT enumeration_value.value LIKE '%linear%'"
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
  end

  def identifier_field
    :accession_number
  end

  def page_break
    false
  end
end