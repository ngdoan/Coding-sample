rm(list = ls())
options(scipen=999)

packages <- c("dplyr","janitor","readxl","stringr","lubridate","openxlsx","tidyr")

#lapply(packages, install.packages, character.only = TRUE)
lapply(packages, library, character.only = TRUE)

folder <- "[insert path]"
input <- paste0(folder, "Data/")
output <- paste0(folder, "Exhibits/Exhibit 3-4/Output/")

input_data <- read_excel(paste0(input, "redacted.xlsx"), skip = 1) %>% clean_names()

revenues <- input_data %>% 
  filter(!is.na(studio_name),
         pricing_tier == "Tier 3",
         studio_name != "redacted",
         brand == "redacted") %>% 
  select(studio_name,soft_open_date,24:69) %>% 
  gather(key=key,value=value,contains("x4")) %>% 
  mutate(key=as.numeric(str_extract(key,"[:digit:]+")),
         date = make_date(2019,1,31) + key-43496) %>% 
  group_by(studio_name) %>% 
  filter(date >= soft_open_date) %>% 
  mutate(month = row_number()) %>% 
  ungroup()  

pre_post_covid <- revenues %>%
  filter(date >= make_date(2020,1,1) & date <= make_date(2020,9,30)) %>% 
  filter(date <= make_date(2020,4,1) | date >= make_date(2020,7,1)) %>% 
  group_by(studio_name) %>% 
  summarise(pre_post_covid_avg = mean(value, na.rm = T)) %>% 
  ungroup()

covid_adj <- revenues %>% 
  left_join(pre_post_covid, by = "studio_name") %>% 
  mutate(covid_adj = ifelse(date >= make_date(2020,4,1) & date <= make_date(2020,6,30),pre_post_covid_avg,value)) 

diff_from_covid_adj <- covid_adj %>% 
  group_by(date) %>% 
  summarise(raw_avg_rev = mean(value, na.rm = T),
            covid_adj_avg_rev = mean(covid_adj, na.rm = T)) %>% 
  ungroup() %>% 
  filter(date >= make_date(2020,4,1) & date <= make_date(2020,6,30)) %>% 
  mutate(deflate_factor = raw_avg_rev/covid_adj_avg_rev)%>% 
  mutate(match_date = floor_date(date, "month"),
         pricing_tier = "Tier 3") %>% 
  select(5:6,1:4)

by_month <- covid_adj %>% 
  group_by(month) %>% 
  summarise(mean_rev = mean(covid_adj, na.rm = T)) %>% 
  ungroup() %>% 
  filter(month <= 25)

output_list <- list("Exhibit 3-4 Output A" = by_month, "Exhibit 3-4 Output B" = diff_from_covid_adj)
write.xlsx(output_list, paste0(output,"2022.11.23 - Exhibit 3-4 Output.xlsx"), overwrite = T)


