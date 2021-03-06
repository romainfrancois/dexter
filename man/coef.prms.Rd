% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/enorm.R
\name{coef.prms}
\alias{coef.prms}
\title{extract enorm item parameters}
\usage{
\method{coef}{prms}(object, ...)
}
\arguments{
\item{object}{an enorm parameters object, generated by the function \code{\link{fit_enorm}}}

\item{...}{further arguments to coef, the following are currently supported;
\describe{
 \item{bayes_hpd_b}{width of Bayesian highest posterior density interval around mean_beta, 
 value must be between 0 and 1, default is 0.95 }  
}}
}
\value{
Depends on the calibration method:
\describe{
\item{for CML}{a data.frame with columns: item_id, item_score, beta, SE_b}
\item{for Bayes}{a data.frame with columns: item_id, item_score, mean_beta, SD_beta, -bayes_hpd_b_left-, -bayes_hpd_b_right-}
}
}
\description{
extract enorm item parameters
}
