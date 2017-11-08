# RTS_GMLC.m

By default RTS_GMLC.m file represents a peak load flow case with all renewable gneration diabled. 
The MATPOWER-out.txt file contains the standard MATPOWER output for the following commands:
```matlab
mpc = loadcase('RTS_GMLC.m')
rundcpf(mpc)
runpf(mpc)
rundcopf(mpc)
runopf(mpc)
```

## To generate `RTS_GMLC.m` from the data in the SourceData folder:
run:
```
python cli.py
```


