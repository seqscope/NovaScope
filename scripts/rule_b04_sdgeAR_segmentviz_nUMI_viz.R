# Load necessary libraries
library(ggplot2)
library(optparse)
library(RColorBrewer)
library("tidyverse")

option_list <- list(
  make_option(c("-i", "--input"), type = "character", default = NULL, help = "Input CSV file path", metavar = "character"),
  make_option(c("-o", "--output"), type = "character", default = NULL, help = "Output plot file path", metavar = "character"),
  make_option(c("-u", "--title"), type = "character", default = NULL, help = "Title of the figure"),
  make_option(c("-y", "--yaxis"), type = "character", default = "count", help = "The y axis label: count, percentage, or space", metavar = "character")
)
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)
#opt$input<-"/nfs/turbo/umms-leeju/nova/v2/analysis/n8-htwlw-t03c-mouse-5d3eb/n8-htwlw-t03c-mouse-5d3eb-default/segment/n8-htwlw-t03c-mouse-5d3eb-default.gn.filtered.10x.segmentviz.tsv"
#opt$output<-"/nfs/turbo/umms-leeju/nova/v2/analysis/n8-htwlw-t03c-mouse-5d3eb/n8-htwlw-t03c-mouse-5d3eb-default/segment/n8-htwlw-t03c-mouse-5d3eb-default.gn.filtered.10x.segmentviz_3.png" 
#opt$title<-"n8-htwlw-t03c-mouse-5d3eb-default_10x_filtered"
#opt$yaxis<-"space"



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

message(paste0("Reading the input file from: "), opt$input)

df <- read.csv(opt$input,sep="\t") 
df$hex_width<-factor(df$hex_width, levels = c("d_12", "d_18", "d_24", "d_36", "d_48", "d_72", "d_96", "d_120"))


if (opt$yaxis == "count") {
  ymax <- max(df$nhex)
  yticks <- c(0, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000,  1000000,  2000000, 5000000, 10000000)
  yticks <- yticks[0:(length(yticks[yticks <= ymax])+1)]
  ylab <- "Number of Hexagons"
  
  p <- ggplot(df,  aes(x = nUMI_cutoff, y = nhex, color = hex_width)) + #facet_wrap(~data, scales = "free_y") +
    geom_line(size = 1) +
    geom_point(size = 2) +
    scale_y_log10(breaks = sort(unique(yticks)), labels = as.character(sort(unique(yticks))))
} else if (opt$yaxis == "proportion") {
  yticks <- c(0,10, 20, 30, 40, 50, 60, 70, 80, 90, 100)
  ylab <- "Proportion of Hexagons (%)"
  
  df_max<-df%>%
    group_by(hex_width)%>%
    summarise(max_nhex = max(nhex))%>%
    ungroup()%>%
    as.data.frame()
  
  p<-df%>%
    left_join(df_max, by = c("hex_width" = "hex_width"))%>%
    mutate(hex_percentage = nhex/max_nhex*100)%>%
    mutate(hex_percentage = as.integer(hex_percentage))%>%
    ggplot(aes(x = nUMI_cutoff, y = hex_percentage, color = hex_width)) +
    geom_line(size = 1) +
    geom_point(size = 2) +
    scale_y_continuous(breaks = yticks, labels = as.character(yticks)) +
    # define y range
    coord_cartesian(ylim = c(0, 100))
}else if(opt$yaxis == "space"){
  df<-df%>%
    mutate(width_int = as.integer(gsub("d_", "", hex_width)))%>%
    mutate(hex_space = (nhex*0.5 * sqrt(3) * width_int * width_int)/1e6)
  
  ymax <- max(df$hex_space)
  if (ymax > 30) {
    yticks <- c(0, 5, 10, 15, 20, 30,  40, 50, 60, 70, 80, 90, 100, 200, 300, 500)
  }else{
    yticks <- c(0, 1, 2, 3, 4, 5, 7, 10, 15, 20, 25, 30)
  }
  yticks <- yticks[0:(length(yticks[yticks <= ymax])+1)]
  ylab <- "Total area in mm^2"
  
  p<-ggplot(df, aes(x = nUMI_cutoff, y = hex_space, color = hex_width)) +
    geom_line(size = 1) +
    geom_point(size = 2)+
    scale_y_continuous(breaks = yticks, labels = as.character(yticks))+
    coord_cartesian(ylim = c(0, max(yticks)))
}else {
  stop("Invalid y-axis option. Please choose 'count', 'percentage', or 'space'.", call. = FALSE)
}

p2<-p+
  scale_x_log10(breaks = sort(unique(df$nUMI_cutoff)), labels = as.character(sort(unique(df$nUMI_cutoff)))) +
  scale_color_manual(values = color_palette) +  # Use the custom color palette
  theme_minimal() +
  labs(title = opt$title,
       x = "nUMI Cutoffs",
       y = ylab,
       color = "Hexagon Widths") +
  theme_wc()

# print out the location of the output for the user
message(paste0("Writing the output file to: "), opt$output)
ggsave(opt$output, plot = p2, width = 10, height = 5, dpi = 300)
