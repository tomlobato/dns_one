module Backend; class BackendDB
    def initialize conf
        @query = conf.delete :query
        @conf = conf
        setup_db
    end

    def find dom_name, tries = 1
        return if tries > 3

        res = nil
    
        begin
            # http://jakeyesbeck.com/2016/02/14/ruby-threads-and-active-record-connections/
            ActiveRecord::Base.connection_pool.with_connection do
                sql = build_query dom_name
                res = ActiveRecord::Base.connection.execute sql
            end

        rescue ActiveRecord::StatementInvalid => e
            Log.e "Query error. Trying to reconnect. Details:\n#{e.desc}"
            # http://geoff.evason.name/2015/01/18/postgres-ssl-connection-has-been-closed-unexpectedly
            ActiveRecord::Base.connection.reconnect! 
            find dom_name, (tries+1)

        rescue => e
            Log.exc e
        end

        first_record = res&.first
        record_values = first_record&.values
        record_values&.first
    end

    def allow_cache
        true
    end

    private

    def build_query dom_name
        @query.sub '$domain', dom_name
    end

    def setup_db
        ActiveRecord::Base.logger = Log.logger

        gem_name = { 
            'postgresql' => 'pg',
            'mysql'      => 'mysql',
            'mysql2'     => 'mysql2'
        }[ @conf[:adapter] ]
          
        unless gem_name
            Util.die "Database adapter '#{@conf[:adapter]}' not supported. Aborting."
        end

        begin
            require gem_name.to_s

        rescue LoadError => e
            Util.die "Error loading database dependency.\nMake sure #{gem_name} it is installed, if it is not, install with 'gem install #{gem_name}'\nError Details: #{e.desc}"
        rescue => e
            Util.die "Error loading database dependency.\n#{e.desc}"
        end

        ActiveRecord::Base.establish_connection @conf
    end
  
end; end
