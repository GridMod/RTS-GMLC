# Basic code to pick key weeks

db = plexos_open("P:/Projects/CHP/Final Base Runs 20161205/Base RT")
int.gen = data.table(query_interval(db,'Generator','Generation',c("name","category")))
int.gen[, Type:=gen.type.mapping[name]]

# Find peak load week
int.gen[!Region%in%ignore.regions, .(value=sum(value)), by=.(scenario,time)][time==time[value==max(value)]]

# Find lowest net load
int.gen[!Type %in% re.types & !Region%in%ignore.regions, .(value=sum(value)), by=.(scenario,time)][time==time[value==min(value)]]

# Find highest daily ramp
int.gen[,day:=as.POSIXlt(time)[[8]]+1]
int.gen[!Type %in% re.types & !Region%in%ignore.regions, .(value=sum(value)), by=.(scenario,time,day)][, .(value=max(value)-min(value)), by=.(scenario,day)][value==max(value)]

# Find week closest to average
int.gen[, weekday:=as.POSIXlt(time)$wday]
int.gen[, hour:=as.POSIXlt(time)$hour]
net.gen = int.gen[!Type %in% re.types & !Region%in%ignore.regions, .(value=sum(value)), by=.(scenario,time,weekday,hour)]
avg.week = net.gen[, .(avg=mean(value)), by=.(scenario,weekday,hour)]
setkey(avg.week,scenario,weekday,hour)
setkey(net.gen,scenario,weekday,hour)
net.gen.avg = net.gen[avg.week]
net.gen.avg[, error:=(avg-value)]
net.gen.avg[, day:=as.POSIXlt(time)[[8]]+1]
net.gen.avg[, week:=floor(day/7)+1]
net.gen.avg[week==net.gen.avg[week<53, .(mse=sqrt(sum(error^2))),by=.(scenario,week)][mse==min(mse),week], ]

# Find highest price week
interval.region.price[!Region %in% ignore.regions & property == 'Price',][value==max(value), ]

# Find biggest misforecast
forecasts = dcast.data.table(da.rt.data[!Region%in%ignore.regions & Type %in% re.types],
                             scenario+time+Type~data,value.var='value',fun.aggregate = sum)
setnames(forecasts,c('DA Committed Capacity or \nForecasted Generation','RT Generation'),c('DA','RT'))
forecasts[,misforecast:=abs(DA-RT)]
forecasts[DA>0][misforecast==max(misforecast)]
