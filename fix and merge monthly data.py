import csv
import datetime 

out = open("output.csv", "w", newline='')
first = True
rows = []
for i in range(2010,2020):
    for j in range (1,13):
        filename = open(str(i)+"_"+str(j)+".csv", "r")
        csv_reader = csv.reader(filename)
        header = next(csv_reader)
        # adding header only the first time
        if first:
            rows.append(header)
            first = False
        for row in csv_reader:
            # split by '-' so we can check if the months place is correct.
            split_arr = row[0].split('-')
            # find month, day, year column.
            month = 0
            # on the edge case that the day and month are the same, then day will just be its default value (1)
            # which will always be the case because the year is never in the middle
            day = 1
            year = 0
            for k in range(len(split_arr)):
                # check if it's 4 digits AKA the year
                if len(split_arr[k]) == 4:
                    year = k
                # check if it's the month, i.e. number on the file
                elif int(split_arr[k]) == j:
                    month = k
                # otherwise it's the day.
                else: 
                    day = k
            # convert the individual day/month/years into ints
            day_int = int(split_arr[day])
            month_int = int(split_arr[month])
            year_int = int(split_arr[year])
            # transform into datetime
            dt = datetime.datetime(year=year_int, month=month_int, day=day_int)
            # format as first 10 chars of string
            row[0] = str(dt)[:10]
            # get the seconds so we can use the numeric value in stata
            row.append(int((dt-datetime.datetime(1970,1,1)).total_seconds()))
            rows.append(row)

#writing the results
writer = csv.writer(out)
for row in rows:
    writer.writerow(row)
