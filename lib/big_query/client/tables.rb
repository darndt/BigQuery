
# Module to handle table actions
# https://developers.google.com/bigquery/docs/tables
module BigQuery
  class Client
    module Tables
      ALLOWED_FIELD_TYPES = ['STRING', 'INTEGER', 'FLOAT', 'BOOLEAN', 'RECORD', 'TIMESTAMP']
      ALLOWED_FIELD_MODES = ['NULLABLE', 'REQUIRED', 'REPEATED']

      # Lists the tables
      #
      # @param dataset [String] dataset to look for
      # @return [Hash] json api response
      def tables(datasetId)
        response = api({
          :api_method => @bq.tables.list,
          :parameters => {"datasetId" => datasetId}
        })

        response['tables'] || []
      end

      # Lists the tables returnning only the tableId
      #
      # @param dataset [String] dataset to look for
      # @return [Hash] json api response
      def tables_formatted(datasetId)
        tables(datasetId).map { |t| t['tableReference']['tableId'] }
      end

      # Returns all rows of table data
      #
      # @param tableId [String] id of the table to look for
      # @param dataset [String] dataset to look for
      # @return [Hash] json api response
      def table_data(datasetId, tableId)
        response = api(api_method: @bq.tabledata.list,
                       parameters: { 'datasetId' => datasetId,
                                     'tableId' => tableId })
        response['rows'] || []
      end

      # insert row into table
      #
      # @param tableId [String] table id to insert into
      # @param opts [Hash] field value hash to be inserted
      # @return [Hash]
      def insert(datasetId, tableId, opts)
        if opts.class == Array
          body = { 'rows' => opts = opts.map{|x| {"json" => x}} }
        else
          body = { 'rows' => [{ 'json' => opts }] }
        end

        api(
          api_method: @bq.tabledata.insert_all,
          parameters: { 'tableId' => tableId,
                        'datasetId' => datasetId },
          body_object: body
        )
      end

      # Creating a new table
      #
      # @param tableId [String] table id to insert into
      # @param schema [Hash] name => opts hash for the schema
      #
      # examples:
      #
      # @bq.create_table('new_table', id: { type: 'INTEGER', mode: 'required' })
      # @bq.create_table('new_table', price: { type: 'FLOAT' })
      def create_table(datasetId, tableId, schema={})
        api(
          api_method: @bq.tables.insert,
          parameters: { "datasetId" => datasetId },
          body_object: { "tableReference" => {
                            "tableId" => tableId,
                            "projectId" => @project_id,
                            "datasetId" => datasetId
                          },
                          "schema" => schema
                          # "schema" => {
                          #   "fields" => validate_schema(schema)
                          #   "fields" => validate_schema(schema)
                          # }
                        }
        )
      end

      def create_table2(datasetId, config={})
        api(
          api_method: @bq.tables.insert,
          parameters: { "datasetId" => datasetId },
          body_object: config
        )
      end

      # Deletes the given tableId
      #
      # @param tableId [String] table id to insert into
      def delete_table(datasetId, tableId)
        api(api_method: @bq.tables.delete,
            parameters: { 'tableId' => tableId,
                          'datasetId' => datasetId }
        )
      end

      # Describe the schema of the given tableId
      #
      # @param tableId [String] table id to describe
      # @param dataset [String] dataset to look for
      # @return [Hash] json api response
      def describe_table(datasetId, tableId)
        api(
          api_method: @bq.tables.get,
          parameters: { 'tableId' => tableId,
                        'datasetId' => datasetId }
        )
      end

      protected

      # Translate given schema to a one understandable by bigquery
      #
      # @param [Hash] schema like { field_nane => { type: 'TYPE', mode: 'MODE' }, ... }
      # @return [Array<Hash>]
      def validate_schema(schema)
        fields = []
        schema.map do |name, options|
          type = (ALLOWED_FIELD_TYPES & [options[:type].to_s]).first
          mode = (ALLOWED_FIELD_MODES & [options[:mode].to_s]).first
          field = { "name" => name.to_s, "type" => type }
          field["mode"] = mode if mode
          if field["type"] == 'RECORD'
            field["fields"] = validate_schema(options[:fields])
          end
          fields << field
        end
        fields
      end
    end
  end
end
