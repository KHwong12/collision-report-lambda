# We need a writeable directory, usually /tmp
temporary_directory <- Sys.getenv("TMPDIR", "/tmp")

# The function passed to lambda
report <- function(serial_no) {

  outfile <- file.path(
    temporary_directory,
    paste0("collision_", serial_no, "_", as.integer(Sys.time()), ".html")
  )
  on.exit(unlink(outfile)) # delete file when we're done

  logger::log_debug("Rendering", outfile)
  rmarkdown::render(
    "/lambda/collision-report.Rmd",
    params = list(COLLISION_SERIAL_NO = serial_no),
    envir = new.env(),
    intermediates_dir = temporary_directory,
    output_file = outfile
  )
  logger::log_debug("Rendering complete for", outfile)

  html_string <- readChar(outfile, file.info(outfile)$size)

  # html_response only available in v1.2.0, not yet available in cran v1.1.0
  lambdr::html_response(html_string, content_type = "text/html")
}

logger::log_formatter(logger::formatter_paste)
logger::log_threshold(logger::DEBUG)

# Manual setting of config arg is required for local testing
# see https://lambdr.mdneuzerling.com/reference/start_lambda.html for details
lambdr::start_lambda(config = lambdr::lambda_config(handler = report))
