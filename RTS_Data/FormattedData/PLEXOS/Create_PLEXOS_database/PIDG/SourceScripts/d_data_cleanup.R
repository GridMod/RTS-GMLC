# clean data to allow the final export to import to Plexos/run with no errors

#------------------------------------------------------------------------------|
# Optional inputs ----
#------------------------------------------------------------------------------|

# retire plants from the "units_retired" file. This means: delete them 
# completely from the database, since they will not 
# requires that no two objects have the same name (mabye should put in a 
# check for this)
if (exists('units.to.delete.files')) {
  for (fname in units.to.delete.files) {
      
      to.delete <- read_data(fname)

      if (is.data.table(to.delete)) {
          
        message(sprintf("... deleting units in  %s", fname))
        
        Objects.sheet <- Objects.sheet[!(name %in% to.delete[,Object])]
        Properties.sheet <- Properties.sheet[!(child_object %in% to.delete[,Object]) &
                                             !(parent_object %in% to.delete[,Object])]
        Memberships.sheet <- 
          Memberships.sheet[!(child_object %in% to.delete[,Object]) & 
                              !(parent_object %in% to.delete[,Object])]
      }
  }
    
} else {
   message(">>  units.to.delete.file does not exist ... skipping")
}


#------------------------------------------------------------------------------|
# Alphabetize all categories ----
#------------------------------------------------------------------------------|

cat.by.class <- unique(Objects.sheet[!is.na(category),.(class, category)])

# order categories by class and category
setorder(cat.by.class, class, category)

# add rank of each category by class
cat.by.class[,rank := 1:.N, by = 'class']

# add this to categories .sheet so categories will be alphabetized
cat.to.categories <- initialize_table(Categories.sheet, nrow(cat.by.class), 
  list(class = cat.by.class$class, category = cat.by.class$category, 
  rank = cat.by.class$rank))
  
Categories.sheet <- merge_sheet_w_table(Categories.sheet, cat.to.categories)

# clean up
rm(cat.by.class, cat.to.categories)




