class AccessionListOfAcquiredAccessions < AbstractReport
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
      accession.id,
      accession.identifier as accession_number,
      accession.title,
      accession.accession_date,
      extent.number,
      ev4.value AS extent_type,
      extent.container_summary,
      ev3.value AS acquisition_type,
      ev2.value AS research_center,
      ev1.value AS primary_collector,
      accession.content_description,
      accession.provenance,
      accession.general_note,
      accession.access_restrictions_note,
      accession.use_restrictions_note,
      user_defined.real_1 AS 'appraisal_value',
      (CASE
          WHEN user_defined.boolean_2 <> 0 THEN 'yes'
          ELSE 'no'
      END) AS 'ready_for_ts?',
      (CASE
          WHEN user_defined.boolean_1 <> 0 THEN 'yes'
          ELSE 'no'
      END) AS 'electronic media',
      user_defined.integer_1 AS 'aleph_order_number',
      accession.created_by,
      ev5.value AS processing_priority,
      ev6.value AS processing_status,
      collection_management.processing_hours_total AS 'total_processing_hours'
      FROM
      accession
          LEFT JOIN
      collection_management ON accession.id = collection_management.accession_id
          LEFT JOIN
      user_defined ON accession.id = user_defined.accession_id
          LEFT JOIN
      enumeration_value ev2 ON user_defined.enum_2_id = ev2.id
          LEFT JOIN
      enumeration_value ev3 ON accession.acquisition_type_id = ev3.id
          LEFT JOIN
      enumeration_value ev1 ON user_defined.enum_1_id = ev1.id
          LEFT JOIN
      extent ON accession.id = extent.accession_id
          LEFT JOIN
      enumeration_value ev4 ON extent.extent_type_id = ev4.id
          LEFT JOIN
      enumeration_value ev5 ON collection_management.processing_priority_id = ev5.id
          LEFT JOIN
      enumeration_value ev6 ON collection_management.processing_status_id = ev6.id
      WHERE
      accession.accession_date > #{db.literal(@from.split(' ')[0].gsub('-', ''))}
          AND accession.accession_date < #{db.literal(@to.split(' ')[0].gsub('-', ''))}
          AND repo_id = 2
      ORDER BY accession.identifier"
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