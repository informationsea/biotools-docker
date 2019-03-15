options(repos="http://cran.rstudio.com/")
install.packages(c("ggplot2", "dplyr", "tidyr", "BiocManager", "xlsx", "parallel", "RSQLite", "purrr", "GGally", "deconstructSigs", "RColorBrewer"))
BiocManager::install("DNAcopy", version = "3.8")
BiocManager::install("PureCN", version = "3.8")
