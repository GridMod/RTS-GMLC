# sets wd if sourced
setwd(dirname(sys.frame(1)$ofile))
library(data.table)

# read in DA files
da.reg1 <- fread("Melted_APS_2020.csv")
da.reg2 <- fread("Melted_NEVP_2020.csv")
da.reg3 <- fread("Melted_LDWP_2020.csv")

# read in RT files
rt.reg1 <- fread("Melted_RT_APS_Promod_2020.csv")
rt.reg2 <- fread("Melted_RT_NEVP_Promod_2020.csv")
rt.reg3 <- fread("Melted_RT_LDWP_Promod_2020.csv")

# DA: fix columns
da.reg1[,c("V1", "Hour", "Minutes") := NULL]
da.reg1[,Period := 1:24, by = .(Year, Month, Day)]
setnames(da.reg1, "Load", "1")

da.reg2[,c("V1", "Hour", "Minutes") := NULL]
da.reg2[,Period := 1:24, by = .(Year, Month, Day)]
setnames(da.reg2, "Load", "2")

da.reg3[,c("V1", "Hour", "Minutes") := NULL]
da.reg3[,Period := 1:24, by = .(Year, Month, Day)]
setnames(da.reg3, "Load", "3")

# DA: combine
da.load <- Reduce(function(...) merge(..., all = TRUE), 
                  list(da.reg1, da.reg2, da.reg3))

# RT: fix columns and combin
rt.reg1[,c("V1", "Hour", "Minutes") := NULL]
rt.reg1[,Period := 1:288, by = .(Year, Month, Day)]
setnames(rt.reg1, "Load", "1")

rt.reg2[,c("V1", "Hour", "Minutes") := NULL]
rt.reg2[,Period := 1:288, by = .(Year, Month, Day)]
setnames(rt.reg2, "Load", "2")

rt.reg3[,c("V1", "Hour", "Minutes") := NULL]
rt.reg3[,Period := 1:288, by = .(Year, Month, Day)]
setnames(rt.reg3, "Load", "3")

# RT: combine
rt.load <- Reduce(function(...) merge(..., all = TRUE), 
                  list(rt.reg1, rt.reg2, rt.reg3))

# write out
write.csv(da.load, 
          "DA_hourly.csv", 
          row.names = FALSE, 
          quote = FALSE)

write.csv(rt.load, 
          "RT_5min.csv", 
          row.names = FALSE, 
          quote = FALSE)