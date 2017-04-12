pacman::p_load(ggplot2,data.table,zoo)

DA_load = data.table(read.csv('DA_hourly.csv'))
names(DA_load) = c('Year','Month','Day','Period','R1_DA','R2_DA','R3_DA')
RT_load = data.table(read.csv('RT_5min.csv'))
names(RT_load) = c('Year','Month','Day','Period','R1_RT','R2_RT','R3_RT')

DA_load[,Period:=(Period-1)*12+1]

Load = merge(RT_load,DA_load,by=c('Year','Month','Day','Period'),all.x = T)
Load[,TSTAMP := as.POSIXct(strptime(sprintf('%02i-%02i-%02i 00:00:00',Year,Month,Day),"%Y-%m-%d %H:%M:%S"))+300*(Period-1)]

Load = Load[, lapply(.SD, na.locf), .SDcols = names(Load)]
Load[,R1_ERR := R1_RT - R1_DA]
Load[,R2_ERR := R2_RT - R2_DA]
Load[,R3_ERR := R3_RT - R3_DA]

Load = melt(Load,id.vars = c('Year','Month','Day','Period','TSTAMP'))

Load[,Region:=tstrsplit(variable,'_',keep=1)]
Load[,Resolution:=tstrsplit(variable,'_',keep=2)]

ggplot(Load[Month==11 & Day <4 & Resolution == 'ERR']) + 
  geom_line(aes(x=TSTAMP,y=value,colour = Resolution, group=variable),alpha=.6) + 
  facet_grid('Region~.',scales = 'fixed') +
  ylab('Regional Load Error (MW)')

ggplot(Load[Resolution != 'ERR']) + 
  geom_line(aes(x=TSTAMP,y=value,colour = Resolution, group=variable),alpha=.6) + 
  facet_grid('Region~.',scales = 'fixed') +
  ylab('Regional Load (MW)')