# creates empty data.tables, to be populated with data, each of which 
# corresponds to one of the worksheets that are required by Plexos when it 
# imports Excel workbooks 

#---------------create empty tables of character columns---------------

#create empty character tables, one for each worksheet, for PLEXOS's 
#required Excel document format
Objects.sheet <- data.table(class = character(), 
                            name = character(), 
                            category = character(), 
                            description =  character())

Categories.sheet <- data.table(category_id = character(), 
                               class = character(), 
                               category = character(), 
                               rank = character(), 
                               class_id = character(), 
                               name = character())

Memberships.sheet <- data.table(parent_class = character(), 
                                child_class = character(), 
                                collection = character(), 
                                parent_object = character(), 
                                child_object = character())

Attributes.sheet <- data.table(name = character(), 
                               class = character(), 
                               attribute = character(), 
                               value = character())

Properties.sheet <- if (plexos.version == 7) {
    
    data.table(parent_class = character(),	
               child_class = character(),	
               collection = character(), 
               parent_object = character(),	
               child_object = character(), 
               property = character(), 
               band_id = character(),	
               value = character(),	
               units = character(),	
               date_from = character(), 
               date_to = character(),	
               pattern = character(), 
               action = character(),
               variable = character(),	
               filename = character(),	
               scenario = character(), 
               memo = character(),	
               period_type_id = character())
} else {
    
    # include escalator and condition but not action
    data.table(parent_class = character(),	
               child_class = character(),	
               collection = character(), 
               parent_object = character(),	
               child_object = character(), 
               property = character(), 
               band_id = character(),	
               value = character(),	
               units = character(),	
               date_from = character(), 
               date_to = character(),	
               pattern = character(), 
               escalator = character(),	
               condition = character(),	
               variable = character(),	
               filename = character(),	
               scenario = character(), 
               memo = character(),	
               period_type_id = character())
    
}

Reports.sheet <- data.table(object = character(), 
                            parent_class = character(), 
                            child_class = character(), 
                            collection = character(), 
                            property = character(), 
                            phase_id = character(), 
                            report_period = character(), 
                            report_summary = character(), 
                            report_statistics = character(), 
                            report_samples = character())
