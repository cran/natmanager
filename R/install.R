#' Install natverse packages from GitHub
#'
#' @description \code{install} allows you to install one of two collections of
#'   nat packages
#'
#'   \itemize{
#'
#'   \item \code{core} a minimal install that can help users to get started with
#'   nat and already solve many problems (the default)
#'
#'   \item \code{natverse} a powerful "batteries included" distribution with all
#'   mature packages in the natverse.
#'
#'   }
#'
#'   Since the \code{natverse} option will install many packages from GitHub,
#'   you need to have a GitHub account and personal access token (GITHUB_PAT).
#'   Install will check to see if you have a \code{GITHUB_PAT} already and, if
#'   not, walk you through the steps of setting one up. A fall-back PAT is built
#'   into the package but we strongly recommend that you sign up to GitHub and
#'   get your own if you start using the natverse regularly.
#'
#' @param collection The collection of natverse packages that you would like to
#'   install. The current options are \code{core}, the default, or
#'   \code{natverse}. See Description for more information.
#' @param pkgs A character vector of package names specifying natverse packages
#'   to install. When present overrides the \code{collection} argument.
#' @param method Whether to use the \code{\link{pak}} (now the default) or
#'   \code{\link[remotes]{install_github}} package for installation.
#' @param dependencies Which dependencies you want to install. The default value
#'   (\code{TRUE}) will install all dependencies, \code{NA} will install only
#'   hard (essential) dependencies, while \code{F} will not install any
#'   dependencies (not recommended). See \code{pak::\link[pak]{pkg_install}} or
#'   \code{\link[remotes]{install_github}} for further details.
#' @param upgrade.dependencies Whether to upgrade dependencies of requested
#'   packages See the \code{upgrade} argument of
#'   \code{pak::\link[pak]{pkg_install}} or
#'   \code{\link[remotes]{install_github}} for details. The default value
#'   (\code{FALSE}) will do the minimum amount to enable you to install the
#'   package(s) you have requested. In contrast \code{TRUE} will go ahead and
#'   upgrade all dependencies to the latest version; pak will potentially
#'   install source packages to do this.
#' @param ... extra arguments to pass to \code{pak::\link[pak]{pkg_install}} or
#'   \code{remotes::\link[remotes]{install_github}}.
#' @importFrom utils install.packages
#' @importFrom usethis ui_info
#' @export
#' @examples
#' \dontrun{
#' # install core packages to try out the core natverse
#' if(is.interactive()) {
#' natmanager::install('core')
#' }
#' # Full "batteries included" installation with all packages
#' if(is.interactive()) {
#' natmanager::install('natverse')
#' # same but upgrading all dependencies to latest version
#' natmanager::install('natverse', upgrade.dependencies = T)
#' }
#' # Install natverse, non-natverse package
#' # for natverse packages no need to specify the repo
#' if(is.interactive()) {
#' natmanager::install(pkgs=c('nat.jrcbrains','flyconnectome/hemibrainr'))
#' }
#' }
install <- function(collection = c('core', 'natverse'), pkgs=NULL,
                    dependencies = TRUE,
                    upgrade.dependencies=FALSE,
                    method=c("pak", "remotes"), ...) {

  collection=match.arg(collection)
  if(is.null(pkgs)) {
    pkgs <- if(collection=="core")
      c("nat", "nat.nblast", "nat.templatebrains")
    else
      "natverse"
    repos = paste0("natverse/", pkgs)
  } else {
    collection=NULL
    # assume natverse org if pkg specification missing org
    has_org=grepl("^[^@]+/", pkgs)
    repos=ifelse(has_org, pkgs, paste0('natverse/', pkgs))
  }

  if(!system_requirements_ok())
    return(invisible(FALSE))

  # use personal PAT or bundled one if that fails
  envvars = c(
    GITHUB_PAT = check_pat(create = FALSE),
    R_REMOTES_NO_ERRORS_FROM_WARNINGS = TRUE
  )
  # can help with permissions errors when updating loaded libraries
  if(isTRUE(.Platform$OS.type == "windows"))
    envvars = c(envvars, R_REMOTES_STANDALONE = TRUE)
  withr::local_envvar(envvars)
  # only use source packages if essential
  withr::local_options(list(install.packages.compile.from.source='never'))
  # withr::local_options(list(install.packages.check.source='no'))

  # Update if necessary and stop the rest of the update process if we had to
  if(smartselfupdate()) return(invisible(NULL))
  method=match.arg(method)
  res <- if(method=='pak') {
    pak::pkg_install(repos,
                     upgrade = upgrade.dependencies,
                     dependencies = dependencies, ...)
  } else {
  remotes::install_github(
    repos,
    dependencies = dependencies,
    upgrade = upgrade.dependencies,
    ...
  )
  }

  if(isTRUE(collection=='core')) {
    ui_info("Load the core nat package with {ui_code('library(nat)')}")
    ui_todo("To install the full natverse in future do {ui_code('natmanager::install(\"natverse\")')}")
  } else if(isTRUE(collection=='natverse')){
    ui_info("Load the full natverse with {ui_code('library(natverse)')}")
  }

  invisible(res)
}
