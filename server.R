library(shiny)
library(tidyverse)
library(stringdist)
library(stringr)
library(shinyjs)
library(shinycssloaders)
library(readxl)
library(writexl)
library(rmarkdown)
library(markdown)




read_uploaded_table <- function(path, name) {
  ext <- tolower(tools::file_ext(name))
  
  if (ext %in% c("csv")) {
    read.csv(path, header = TRUE, stringsAsFactors = FALSE)
    
  } else if (ext %in% c("txt")) {
    read.delim(path, header = TRUE, stringsAsFactors = FALSE)
    
  } else if (ext %in% c("xlsx", "xls")) {
    as.data.frame(readxl::read_excel(path))
    
  } else {
    stop("Unsupported file type: ", ext)
    
  }
}

select_typocorrectiondata <- function(df, keep_typocorrectiondata = FALSE) {
  if (isTRUE(keep_typocorrectiondata)) {
    df %>%
      dplyr::select(
        starts_with("Corrected."),
        starts_with("Pos.Dist."),
        starts_with("Trial.Dist."),
        starts_with("Multiple.Match.")
      )
  } else {
    df %>%
      dplyr::select(starts_with("Corrected."))
  }
}

# Read default stopword list
default_stopwords <- read.csv("Default_Stopword_List.csv") %>% dplyr::pull(Stopword)

# One set of DT options used everywhere (consistent behavior)
dt_opts <- list(
  scrollX = TRUE,
  dom = '<"dt-top d-flex justify-content-between align-items-center"lf>rtip',
  lengthMenu = c(5, 10, 25, 50, 100),
  pageLength = 10
)


by_position_lv <- function(stimuli, 
                           responses, 
                           distance_method = "lv",  
                           designated_stopword = "skip"){
  
  
  # Check if the lengths of stimuli and responses are compatible for a one-to-one comparison
  if(length(stimuli) != length(responses)){
    abort(
      "stimulus and response lengths",
      message = paste("The length of stimuli is not equal to length of responses?\n",
                      "Stimuli:", 
                      paste(stimuli, collapse = ", "), 
                      "\n",
                      "Responses:", 
                      paste(responses, collapse = ", "))
    )
  } else {
    distances <- rep(NA, length(stimuli))
    for(i in 1:length(stimuli)){
      if(responses[i] == toupper(designated_stopword) | responses[i] == tolower(designated_stopword)){
        distances[i] <- NA
      } else {
        # calculated_distance <- stringdist(stimuli[i], responses[i], method = distance_method)
        # distances[i] <- if (calculated_distance <= autocorrect_tolerance) calculated_distance else NA
        distances[i] <- stringdist(stimuli[i], responses[i], method = distance_method)
      }
    }
    
    return(distances)
  }
}


closest_words_lv <- function(stimuli, 
                             responses, 
                             distance_method = "lv", 
                             autocorrect_tolerance, 
                             designated_stopword = "skip", 
                             stopword_replacement, 
                             keep_uncorrected = TRUE) {
  
  # Check if the lengths of stimuli and responses are compatible for a one-to-one comparison
  if (length(stimuli) != length(responses)) {
    stop(
      paste("The length of stimuli does not equal the length of responses.\n",
            "Stimuli:", paste(stimuli, collapse = ", "), "\n",
            "Responses:", paste(responses, collapse = ", "))
    )
  }
  
  # Initialize a vector for closest words based on the length of responses
  # Start closest_words with the original responses
  distances <- rep(Inf, length(responses))
  closest_words <- rep(NA, length(responses))
  multiple_matches <- rep(NA, length(responses))
  
  for (i in 1:length(responses)) {
    # When the response is a stopword
    if (responses[i] == toupper(designated_stopword) | responses[i] == tolower(designated_stopword)){
      distances[i] <- NA
      if (stopword_replacement == "replace") {
        closest_words[i] <- designated_stopword
      }
      else if (stopword_replacement == "remove") {
        closest_words[i] <- NA
      }
    }
    # When the response is NOT a stopword
    else {
      # Initialize vectors for distances and closest words for each response
      # Note that this is in the loop of responses
      distances_for_each_response <- rep(Inf, length(stimuli))
      
      for (k in 1:length(stimuli)) {
        distances_for_each_response[k] <- stringdist(
          stimuli[k], 
          responses[i], 
          method = distance_method
          )
      }
      
      # When multiple matches of the closest words (with minimum distance) are detected
      # && When that distance value is less than tolerance
      if(sum(distances_for_each_response == min(distances_for_each_response)) > 1 &&
         min(distances_for_each_response) <= autocorrect_tolerance){
        distances[i] <- NA
        multiple_matches[i] <- TRUE
        closest_words[i] <- if (keep_uncorrected) responses[i] else NA
      }
      
      # When no stimuli are close enough
      else if (all(distances_for_each_response > autocorrect_tolerance)) {
        distances[i] <- NA
        multiple_matches[i] <- FALSE
        closest_words[i] <- if (keep_uncorrected) responses[i] else NA
      }
      
      
      # Else
      # The closest word and its distance are saved
      else {
        distances[i] <- min(distances_for_each_response)
        closest_words[i] <- stimuli[which.min(distances_for_each_response)]
        multiple_matches[i] <- FALSE
      }
    }
  }
  # Return a list with matched closest words and their distances
  return(c(closest_words, distances, multiple_matches))
}


spell_correction <- function(data, 
                             stimulus_name, 
                             response_name,
                             distance_method = "lv", # see stringdist::stringdist
                             autocorrect_tolerance = 1, # or other options
                             case_conversion = "all_to_lower", # or "all_to_upper" or "none"
                             whitespace_removal = "remove_start_and_end", # or "none"
                             stopword_replacement = c("replace", "remove", "none"),
                             stopword_list, 
                             designated_stopword = "skip", 
                             keep_uncorrected = TRUE,
                             keep_typocorrectiondata = FALSE
                             ){
  
  print("CALLED: spell_correction")
  
  df <- data
  
  # Case Converstion
  # print("CASE CONVERSION")
  if(case_conversion == "all_to_lower"){
    df <- df %>%
      mutate(across(starts_with(stimulus_name), ~ tolower(.x))) %>%
      mutate(across(starts_with(response_name), ~ tolower(.x)))
    
    stopword_list <- tolower(stopword_list)
    
  } else if (case_conversion == "all_to_upper"){
    df <- df %>%
      mutate(across(starts_with(stimulus_name), ~ toupper(.x))) %>%
      mutate(across(starts_with(response_name), ~ toupper(.x)))
    
    stopword_list <- toupper(stopword_list)
  }
  
  # Whitespace Removal
  # print("WHITESPACE REMOVAL")
  if(whitespace_removal == "remove_start_and_end"){
    df <- df %>%
      mutate(across(starts_with(response_name), ~ str_trim(.x)))
  }
  
  # Stopword Replacement
  # print("STOPWORD REPLACEMENT")
  if(stopword_replacement == "replace" | stopword_replacement == "remove"){
    df <- df %>%
      mutate(across(starts_with(response_name), ~ if_else(.x %in% stopword_list, designated_stopword, .x)))
  }
  
  # Distance Calculation
  all_rows <- vector("list", nrow(df))
  
  for(i in seq_len(nrow(df))){
    
    row_df <- df[i,]
    
    row_stimuli <- row_df %>% 
      select(starts_with(stimulus_name)) %>% 
      as.matrix() %>% 
      as.character()
    
    row_responses <- row_df %>% 
      select(starts_with(response_name)) %>% 
      as.matrix() %>% 
      as.character()
    
    BP <- by_position_lv(stimuli = row_stimuli, 
                         responses = row_responses,
                         distance_method = distance_method,
                         designated_stopword = designated_stopword)
    
    WT <- closest_words_lv(stimuli = row_stimuli, 
                           responses = row_responses,
                           distance_method = distance_method, 
                           autocorrect_tolerance = autocorrect_tolerance,
                           designated_stopword = designated_stopword, 
                           stopword_replacement = stopword_replacement,
                           keep_uncorrected = keep_uncorrected)
    
    row_result <- cbind(row_df, rbind(BP), rbind(WT))
    
    colnames(row_result) <- c(
      paste0("Prep.", colnames(row_df)),
      paste0("Pos.Dist.", 1:length(row_stimuli)),
      paste0("Corrected.", response_name, ".", 1:length(row_stimuli)),
      paste0("Trial.Dist.", 1:length(row_stimuli)),
      paste0("Multiple.Match.", 1:length(row_stimuli))
    )
    
    all_rows[[i]] <- row_result  # store after renaming
  }
  
  all_result <- dplyr::bind_rows(all_rows)  # outside the loop
  all_result
}

function(input, output, session) {
  
  data <- reactive({
    req(input$originalfile)
    read_uploaded_table(input$originalfile$datapath, input$originalfile$name)
  })
  
  
  has_run <- reactiveVal(FALSE)
  
  result_data <- reactiveVal(NULL)
  
  observeEvent(input$execute_typo_error_check, {
    has_run(TRUE)
    
    # compute once, store once
    tol <- as.integer(input$autocorrect_tolerance)
    stopwords <- character(0)
    
    if (input$stopword_replacement %in% c("replace", "remove")) {
      if (input$dataSource == "default") {
        stopwords <- default_stopwords
      } else if (input$dataSource == "upload") {
        req(input$stopwordfile)
        sw_df <- read_uploaded_table(input$stopwordfile$datapath, input$stopwordfile$name)
        stopwords <- sw_df %>% dplyr::pull(Stopword)
      }
    }
    
    result_data(spell_correction(
      data = data(),
      stimulus_name = input$stimulus_name,
      response_name = input$response_name,
      autocorrect_tolerance = tol,
      distance_method = input$distance_method,
      case_conversion = input$case_conversion,
      whitespace_removal = input$whitespace_removal,
      stopword_replacement = input$stopword_replacement,
      stopword_list = stopwords,
      designated_stopword = input$designated_stopword,
      keep_uncorrected = input$keep_uncorrected
    ))
    
    nav_select("data_viewer", "Corrected Data")
    shinyjs::delay(100, shinyjs::runjs("window.scrollTo({top: 0, behavior: 'smooth'})"))
  })
  
  
  
  # DT outputs
  
  output$head <- DT::renderDT({
    DT::datatable(
      data(),
      class = "table table-sm table-striped",
      rownames = FALSE,
      options = dt_opts
    )
  })
  
  output$preprocessed <- DT::renderDT({
    
    req(has_run())
    res <- result_data()
    
    DT::datatable(
      res %>% dplyr::select(starts_with("Prep.")),
      class = "table table-sm table-striped",
      rownames = FALSE,
      options = dt_opts
    )
  })
  
  output$checked <- DT::renderDT({
    
    req(has_run())
    res <- result_data()
    
    checked_data <- select_typocorrectiondata(
      res,
      keep_typocorrectiondata = input$keep_typocorrectiondata
      
    )
    
    DT::datatable(
      checked_data,
      class = "table table-sm table-striped",
      rownames = FALSE,
      options = dt_opts
    )
  })

  
  # Download handler
  output$download_data <- downloadHandler(

  filename = function() {
    req(has_run())
    req(input$originalfile)

    base <- tools::file_path_sans_ext(input$originalfile$name)

    ext <- switch(
      input$download_format,
      xlsx = "xlsx",
      csv  = "csv",
      txt  = "txt"
    )

    paste0("Checked_", base, ".", ext)
  },

  content = function(file) {
    
    req(has_run())
    res <- result_data()
    
    out_df <- cbind(
      data(),
      select_typocorrectiondata(res, 
                             keep_typocorrectiondata = input$keep_typocorrectiondata)
    )

    switch(
      input$download_format,

      xlsx = {
        writexl::write_xlsx(out_df, path = file)
      },

      csv = {
        write.csv(out_df, file, row.names = FALSE, fileEncoding = "UTF-8")
      },

      txt = {
        # Tab-delimited text
        write.table(
          out_df,
          file = file,
          sep = "\t",
          row.names = FALSE,
          quote = FALSE
        )
      }
    )
  }
)
}
