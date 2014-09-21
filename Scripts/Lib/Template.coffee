class Template
    @fetch: ( name, raw = no ) ->
        return unless isString name

        contents = $( "script[type='template']##{name}" ).text()
        return if raw then contents else combyne contents

    @load: ( name, options ) ->
        return Template.fetch( name ).render options