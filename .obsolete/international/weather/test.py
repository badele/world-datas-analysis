import csv
import os
from datetime import datetime


countries = ['AT','SI','HU','HR','BA','RS','RO']
wvars = ['tg','rr','sd']

for wvar in wvars:

    st_path = 'ECA_blend_' + wvar
    path = os.path.join(st_path, 'stations.txt')
    
    dct_station_info = {}
    dct_station_data = {}
    
    start_date = datetime.strptime('1991-01-01', '%Y-%m-%d')
    end_date = datetime.strptime('2015-12-31', '%Y-%m-%d')
    
    with open(path, 'r') as f:
        for line in f:
            cty = line[47:49]
            if cty in countries:
                s_id = line[0:5].strip().zfill(6)
                #s_id = (6 - len(s_id)) * '0' + s_id
                name = line[6:45].strip()
                dct_station_info[s_id] = (name, cty)
                dct_station_data[s_id] = []
    
    for key in dct_station_info.keys():
        st = wvar.upper() + '_STAID' + key + '.txt'
        path = os.path.join(st_path, st)
        data = False
        
        with open(path, 'r') as f:
            for line in f:
                if data:
                    d = datetime.strptime(line[14:22], '%Y%m%d')
                    q = int(line[29:34])
                    if q == 9:
                        v = last_d
                    else:
                        v = int(line[23:28])
                        if wvar == 'tg':
                            v *= 0.1
                        last_d = v
                    if d >= start_date and d <= end_date:
                        dct_station_data[key].append((d.date(), v))
                if line[0:5] == 'STAID':
                    data = True
                    
        name = dct_station_info[key][1] + ' ' + wvar.upper() + ' ' \
                + dct_station_info[key][0] + '.csv'
        path = os.path.join('data', name)

        with open(path, 'w') as f:
            writer = csv.writer(f, delimiter=';')
            writer.writerows(dct_station_data[key])
        