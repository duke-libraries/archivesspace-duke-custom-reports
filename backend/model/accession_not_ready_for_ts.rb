class AccessionNotReadyForTs < AbstractReport
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
    info[:total_count] = results.count
    results
  end

  def query_string
    "SELECT 
    accession.identifier as accession_number,
    accession.title as title,
    extent.number,
    ev_2.value as extent_type,
    ev_1.value as curator,
    (CASE
          WHEN user_defined.boolean_2 <> 0 THEN 'yes'
          ELSE 'no'
     END) as ready_for_ts
    FROM
    accession
        LEFT JOIN
        user_defined ON accession.id = user_defined.accession_id
        LEFT JOIN
        enumeration_value ev_1 ON user_defined.enum_1_id = ev_1.id
        LEFT JOIN
        extent ON accession.id = extent.accession_id
        LEFT JOIN
        enumeration_value ev_2 ON extent.extent_type_id = ev_2.id
    WHERE
        user_defined.boolean_2 = 0
        AND repo_id = 2
        AND accession.accession_date >= #{db.literal(@from.split(' ')[0].gsub('-', ''))}
        AND accession.accession_date <= #{db.literal(@to.split(' ')[0].gsub('-', ''))}
    ORDER BY ev_1.value"
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