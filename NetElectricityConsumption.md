Net Electricity Consumption
================

Visualization of electricity production by balcony power station and net
electricity usage, measured by electricity meter.

<div>

by <a href="mailto:firstname.lastname@outlook.com">Konstantin</a> on
2025-07-31 16:01:35.23406

</div>

``` r
# load packages
library(conflicted)
library(dplyr)
library(ggplot2)
library(knitr)
library(readxl)
library(purrr)
library(tibble)
library(tidyr)

# solve package conflicts
# conflict_scout()
conflicts_prefer(dplyr::filter(), dplyr::lag(), .quiet = TRUE)

# set knitr options
opts_chunk$set(fig.path = file.path("img", .Platform$file.sep))
```

## Data prep

``` r
# electricity meter
fnam_em <- file.path("data", "electricity_meter.csv")

# power station
fnam_ps <- list.files("data", pattern = "power-station", full.names = TRUE)
```

Import electricity net consumption from file

data/electricity_meter.csv.

Import electricity production from files

- data/20250731_power-station.xlsx

``` r
# electricity measure
df_em <- read.csv(fnam_em) %>% 
  as_tibble() %>% 
  mutate(
    dt    = as.Date(dt, format = "%Y-%m-%d"),
    dttm  = as.POSIXct(paste(dt, tm), format = "%Y-%m-%d %H:%M"),
    aux   = as.double(dttm) / (3600 * 24),
    tdif  = aux - lag(aux),
    usage = kwh - lag(kwh),
    avgu  = usage / tdif
  ) %>% 
  select(dt, avgu)

# power station
df_ps <- 
  map_df(
    fnam_ps,
    .f = \(f) {
      #-- f <- fnam_ps[1]
      read_xlsx(f) %>% 
        mutate(
          dt   = as.Date(`Updated Time`, format = "%Y/%m/%d"),
          prod = as.double(`Production-Today(kWh)`)
        ) %>% 
        select(dt, prod)
    }
  )
```

**Process** data

- create data with average electricity usage by date
- combine both data, electricity net usage and electricity production

``` r
# get date range
dt_range <- range(df_em$dt)

# em grid with average net electricity usage
df_em_grid <- 
  tibble(dt = seq(dt_range[1], dt_range[2], by = "d")) %>% 
  left_join(
    y = df_em %>% select(dt, avgu) %>% filter(!is.na(avgu)),
    by = join_by(dt)
  ) %>% 
  fill(avgu, .direction = "up")

df_all <- 
  full_join(x = df_ps, y = df_em_grid, by = join_by(dt)) %>% 
  pivot_longer(cols = c(prod, avgu), names_to = "cat", values_to = "kwh") %>% 
  mutate(
    cat = factor(cat, levels = c("avgu", "prod"), labels = c("average net usage", "produced"))
  ) %>% 
  filter(!is.na(kwh))
```

## Evaluation

``` r
df_all %>% 
  ggplot(mapping = aes(x = dt, y = kwh, group = cat, fill = cat)) + 
  geom_hline(yintercept = 2000/365) + 
  annotate(
    geom = "text",
    x = max(df_all$dt), y = 2000/365, label = "average yearly usage",
    hjust = 1.1, vjust = -.2
  ) + 
  geom_col(position = position_dodge(preserve = "single")) + 
  scale_y_continuous(
    sec.axis = dup_axis(name = NULL, breaks = round(2000/365, 2))
  ) + 
  labs(x = NULL, y = "kWh", fill = NULL) + 
  theme_minimal() + 
  theme(legend.position = "bottom")
```

![](img//viz-1.png)<!-- -->
