#export populated tables to one excel workbook

#uses (from master):
# output.wb.name 
# copy.workbook.elsewhere (T/F)
# copy.destination (needed if copy.workbook.elsewhere is TRUE)

#---------------EXPORTING---------------
#Requires latest version of Java. Alternatively, can export to .csv files and 
#merge them into an excel sheet manually

sheets.list <- list(Objects = Objects.sheet, 
                    Categories = Categories.sheet, 
                    Memberships = Memberships.sheet,
                    Attributes = Attributes.sheet, 
                    Properties = Properties.sheet, 
                    Reports = Reports.sheet)


# create workbook
workbook.to.export <- createWorkbook()

invisible(lapply(names(sheets.list), 
                 function(x) addWorksheet(workbook.to.export, x)))

invisible(lapply(names(sheets.list), 
                 function(x) writeData(workbook.to.export, 
                                       sheet = x, 
                                       as.data.frame(sheets.list[[x]]),
                                       rowNames = FALSE)))

# write out workbook
saveWorkbook(workbook.to.export, 
             file.path(outputfiles.dir, output.wb.name),
             overwrite = TRUE)
