# Load necessary libraries
library(ggplot2)
library(optparse)
library(RColorBrewer)
library("tidyverse")

option_list <- list(
  make_option(c("-i", "--input"), type = "character", default = NULL, help = "Input CSV file path", metavar = "character"),
  make_option(c("-o", "--output"), type = "character", default = NULL, help = "Output plot file path", metavar = "character"),
  make_option(c("-u", "--title"), type = "character", default = NULL, help = "Title of the figure")
)
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

#opt$input<-"n9-hgc2m-b06-07c-mouse-714e6-default.gn.den_raw.hexagon_nUMI.10x.tsv"

# extract title when it is NULL
if (is.null(opt$title)) {
  opt$title <- basename(opt$input) %>%
    gsub(".tsv", "", .)%>%
    gsub(".hexagon_nUMI", "", .) 
}

if (is.null(opt$input)) {
  print_help(opt_parser)
  stop("Input file paths are required.", call. = FALSE)
}

if (is.null(opt$output)){
  opt$output<-opt$input%>%
    gsub(".tsv", ".png", .)
}

theme_wc <- function(base_size = 14) {
  theme_bw(base_size = base_size) %+replace%
    theme(
      plot.title = element_text(size = rel(1), margin = margin(0,0,5,0), hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = rel(0.70), hjust = 0.5),
      #axis
      axis.title = element_text(size = rel(0.85)),
      axis.text = element_text(size = rel(0.70)),
      #legend
      legend.title = element_text(size = rel(0.85)),
      legend.text = element_text(size = rel(0.70)),
      legend.key = element_rect(fill = "transparent", colour = NA),
      legend.key.size = unit(1.5, "lines"),
      legend.background = element_rect(fill = "transparent", colour = NA),
      #text
      text=element_text(family="DejaVu Sans", colour = "black")
    )
}

#color_palette <- brewer.pal(9, "Blues")  
#df <- read.csv(opt$input,sep="\t")%>%
#  as_tibble()%>%
#  pivot_longer(c(nhex, nhex_qc), 
#               names_to ="data", 
#               values_to = "nhex")%>%
#  as.data.frame()

# Generate a base palette and avoid the white
base_palette <- brewer.pal(9, "Set3")
color_palette <- colorRampPalette(base_palette[3:9])(8)

df <- read.csv(opt$input,sep="\t") 
df$hex_width<-factor(df$hex_width, levels = c("d_12", "d_18", "d_24", "d_36", "d_48", "d_72", "d_96", "d_120"))


ymax <- max(df$nhex)
yticks <- c(1, 5, 10, 20, 50, 100, 200, 500, 1000, 5000, 10000, 100000, 1000000, 10000000)
yticks <- yticks[yticks <= ymax]


p <- ggplot(df,  aes(x = nUMI_cutoff, y = nhex, color = hex_width)) + #facet_wrap(~data, scales = "free_y") +
  geom_line(size = 1) +
  geom_point(size = 2) +
  scale_x_log10(breaks = sort(unique(df$nUMI_cutoff)), labels = as.character(sort(unique(df$nUMI_cutoff)))) +
  scale_y_log10(breaks = sort(unique(yticks)), labels = as.character(sort(unique(yticks)))) +
  scale_color_manual(values = color_palette) +  # Use the custom color palette
  labs(title = opt$title,
       x = "nUMI Cutoffs",
       y = "Num of Hexagons",
       color = "Hexagon Widths") +
  theme_minimal() +
  theme_wc()


ggsave(opt$output, plot = p, width = 10, height = 5, dpi = 300)
