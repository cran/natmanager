#' Update the `natmanager` package itself.
#'
#' @param source Location from which to obtain a newer version of natmanager.
#'   Defaults to GITHUB since this may well have a newer version than the CRAN
#'   package repository.
#' @param ... extra arguments to pass to \code{\link[remotes]{install_github}}
#'   or \code{\link[remotes]{install_cran}}.
#' @param upgrade.dependencies Whether to install dependencies of natmanager.
#'   See the \code{upgrade} argument of \code{\link[remotes]{install_github}}
#'   for details. The default will go ahead and always do this is as necessary.
#' @importFrom utils browseURL packageVersion
#' @export
#' @seealso \code{\link{install}}
#' @examples
#' \dontrun{
#' natmanager::selfupdate()
#' }
selfupdate <- function(source = c('GITHUB', 'CRAN'),
                       upgrade.dependencies='always', ...) {
  source <- match.arg(source)

  oldVersion=utils::packageVersion('natmanager')

  # use personal PAT or bundled one if that fails
  withr::local_envvar(c(GITHUB_PAT=check_pat(create = FALSE),
                        R_REMOTES_NO_ERRORS_FROM_WARNINGS=TRUE))
  # only use source packages if essential
  withr::local_options(list(install.packages.compile.from.source='never'))

  if (source == 'CRAN') {
    remotes::install_cran('natmanager', ...)
  } else {
    remotes::install_github('natverse/natmanager',
                            upgrade=upgrade.dependencies, ...)
  }

  newVersion=utils::packageVersion('natmanager')

  if(newVersion>oldVersion) {
    if(isTRUE(Sys.getenv("RSTUDIO")=="1")  &&
       isTRUE(requireNamespace('rstudioapi', quietly=TRUE))) {
      res=utils::askYesNo("Can I restart R?")
      if (isTRUE(res)) {
        message("Thank you! You can run natmanager::install() after restarting!")
        rstudioapi::restartSession()
        stop("", call. = F)
      } else{
        stop("OK! But you must restart R before running natmanager::install() again!",
             call. = FALSE)
      }
    } else {
      stop("You must restart R before running natmanager::install() again!",
           call. = FALSE)
    }
  }
}

github_version <- function(repo='natverse/natmanager') {
  tryCatch({
    u=sprintf('https://raw.githubusercontent.com/%s/master/DESCRIPTION', repo)
    con <- curl::curl(u)
    on.exit(close(con))
    ver.str=read.dcf(con, fields = 'Version')
    package_version(ver.str)
  }, error=function(e) NA)
}

github_newer <- function() {
  remote=github_version('natverse/natmanager')
  if(is.na(remote)) return(NA)
  local=utils::packageVersion('natmanager')
  remote>local
}

smartselfupdate <- function(...) {
  if (isTRUE(github_newer()) && interactive()) {
    res = utils::askYesNo(
      paste0("There is a newer version of natmanager. Would you like to update",
      " (recommended!)"),
      default = TRUE
    )
    if (isTRUE(res))
      selfupdate(...)
  }
}