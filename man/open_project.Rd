% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dexter.R
\name{open_project}
\alias{open_project}
\title{Open an existing project}
\usage{
open_project(db_name = "dexter.db", convert_old = NULL)
}
\arguments{
\item{db_name}{The name of the data base to be opened.}

\item{convert_old}{Ignored, this argument will be removed in a future version.}
}
\value{
A handle to the dexter project database.
}
\description{
Opens a database created by function \code{start_new_project}
}
