% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/shine.R
\name{iModels}
\alias{iModels}
\title{Interactive model display}
\usage{
iModels(db, booklet)
}
\arguments{
\item{db}{A handle to the database, i.e. the output of \code{create_new_project}
or \code{open_project}}

\item{booklet}{booklet_id of the booklet that will be shown}
}
\value{
An object that represents the application. Printing the object or passing it to \code{shiny::runApp} will run the app.
}
\description{
Opens up a shiny application with item statistics and interactive
plots for the Rasch and Interaction models
}
