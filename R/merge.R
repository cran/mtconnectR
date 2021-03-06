
#' Merges all the data.frames in the list into single data.frame
#' 
#' @param DF_list is a list of data.frames. Each data.frame should be of type timestamp|value1|value2...
#' @param output_DF if TRUE, then returns output in the form of data.frame instead of data.table
#' @param use_list_names if TRUE, the names of the list are assigned the columns names
#' @param ignore_tz timezone error is ignored.
#' @param additional_ts an POSIXct vector of timestamps which needs to be added into the table.
#'  The values are repeated from the previous timestamp
#' @importFrom data.table setnames
#' @examples 
#' data("example_mtc_device")
#' mtc_device = merge(example_mtc_device)
#' df_1 = mtc_device[seq(1,17,2),]
#' df_2 = mtc_device[seq(2,17,2),]
#' merged_df = mergeTS(list(df_1,df_2))
#' @export
mergeTS <- function(DF_list, output_DF = T, use_list_names = F, additional_ts = .POSIXct(integer(0)), ignore_tz = F){
  
  DF_list =Filter(Negate(is.null), DF_list)
  if (length(DF_list) == 0) {
    warning(paste("You gave me a list with zero elements!"))
    return(NULL)
  }
  
  all_tz = lapply(DF_list, function(x) attr(x[["timestamp"]], "tzone"))
  all_tz = replace(all_tz, all_tz == "", 'UTC')
  all_tz = lapply(all_tz, function(x) ifelse(is.null(x), 'UTC', x)) %>% unlist()
  if (length(unique(all_tz)) != 1 & !ignore_tz)
    stop("Multiple time_zones present in input")
  
  all_timestamps = additional_ts
  for (i in setdiff(1:length(DF_list), additional_ts))
    all_timestamps = append(all_timestamps, DF_list[[i]][["timestamp"]])
  
  merged_data = data.table::data.table("timestamp" = sort(unique(all_timestamps), method = "quick"),key = "timestamp")
  
  for (i in length(DF_list):1){
    single_data = DF_list[[i]]
    
    non_ts_cols = setdiff(names(single_data), "timestamp")
    single_data = single_data[c("timestamp", non_ts_cols)]
    
    single_data = data.table::data.table(single_data, key = "timestamp")
    merged_data = single_data[merged_data, mult = "first", roll = T]
    if(ncol(merged_data) > 1) data.table::setnames(merged_data ,c("timestamp", paste0("V", 2:ncol(merged_data)))) 
  }
  
  if (!use_list_names)  valNames = unlist(sapply(DF_list, names)) else
    valNames = unlist(names(DF_list))
  
  valNames = valNames[valNames!="timestamp"]
  data.table::setnames(merged_data, c("timestamp", valNames))
  attributes(merged_data[["timestamp"]])$tzone = all_tz[1]
  if (output_DF == T) merged_data = data.frame(merged_data)
  merged_data
}
