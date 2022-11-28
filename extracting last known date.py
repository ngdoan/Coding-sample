import csv
import datetime

datafile = 'coviddates.csv'

#indices of the csv
date = 0
county = 1
zip_code = 2

#format of the date
date_format = "%Y-%m-%d"

# this is a dictionary that will store a tuple pair and a list in the format of {(date,zip) [col1cum,col2cum,...,col999cum]}
# cum is short for cumulative
zip_high_month = {}

# boolean so we can skip the first iteration
first = True

#headers for the output file
headers = ['month/yr','as_of_date','zip_code_tabulation_area','local_health_jurisdiction','county','vaccine_equity_metric_quartile','vem_source','age12_plus_population','age5_plus_population','persons_fully_vaccinated','persons_partially_vaccinated','percent_of_population_fully_vaccinated','percent_of_population_partially_vaccinated','percent_of_population_with_1_plus_dose','booster_recip_count','redacted']

#reading the datafile
with open(datafile, newline='') as csvfile:
    filereader = csv.reader(csvfile, delimiter=',', quotechar='|')
    for row in filereader:
        # here's where we skip the first line
        if first:
            first = False
            continue
        
        #get month and year
        curr_date = datetime.datetime.strptime(row[0], date_format)
        #get zip
        curr_zip = row[zip_code]

        #first occurance of curr_month_year
        if curr_zip not in zip_high_month:
            zip_high_month[curr_zip] = []
            zip_high_month[curr_zip].append(row[0])
        
        compare_date = datetime.datetime.strptime(zip_high_month[curr_zip][date], date_format) 
        # if the last saved date is less than or equal to current date
        if compare_date <= curr_date:
            for col in range(len(row)):
                zip_high_month[curr_zip] = row

# writing to output.csv
with open ('largest_dates_only.csv', 'w') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(headers)
    row_arr = []
    # for every key in the dictionary
    for key in zip_high_month:
        # we output the key in one column
        row_arr.append(key)
        # and then output the rest of the values in the other columns
        for val in zip_high_month[key]:
            row_arr.append(val)
        #then we write it
        writer.writerow(row_arr)
        row_arr = []
