## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = FALSE)
library(dexter)
library(latticeExtra)
fq = c(10,12,30,20,40,24,15,18,14)
fq=matrix(fq,3,3)
attr(fq,"dimnames")=list(c(0,1,2),c(0,1,2))
den = matrix(c(10,32,85,32,85,42,85,42,14),3,3)

blues=function (n, h = 221, c. = c(80, 0), l = c(30, 90), power = 1.5, 
          fixup = TRUE, gamma = NULL, alpha = 1, ...) 
{
  if (!is.null(gamma)) 
    warning("'gamma' is deprecated and has no effect")
  if (n < 1L) 
    return(character(0L))
  c <- rep(c., length.out = 2L)
  l <- rep(l, length.out = 2L)
  power <- rep(power, length.out = 2L)
  rval <- seq(1, 0, length = n)
  rval <- hex(polarLUV(L = l[2L] - diff(l) * rval^power[2L], 
                       C = c[2L] - diff(c) * rval^power[1L], H = h[1L]), fixup = fixup, 
              ...)
  if (!missing(alpha)) {
    alpha <- pmax(pmin(alpha, 1), 0)
    alpha <- format(as.hexmode(round(alpha * 255 + 1e-04)), 
                    width = 2L, upper.case = TRUE)
    rval <- paste(rval, alpha, sep = "")
  }
  return(rval)
}

reds=
function (n, h = 11, c. = c(80, 5), l = c(35, 95), power = 0.6, 
          fixup = TRUE, gamma = NULL, alpha = 1, ...) 
{
  if (!is.null(gamma)) 
    warning("'gamma' is deprecated and has no effect")
  if (n < 1L) 
    return(character(0L))
  c <- rep(c., length.out = 2L)
  l <- rep(l, length.out = 2L)
  power <- rep(power, length.out = 2L)
  rval <- seq(1, 0, length = n)
  rval <- hex(polarLUV(L = l[2L] - diff(l) * rval^power[2L], 
                       C = c[2L] - diff(c) * rval^power[1L], H = h[1L]), fixup = fixup, 
              ...)
  if (!missing(alpha)) {
    alpha <- pmax(pmin(alpha, 1), 0)
    alpha <- format(as.hexmode(round(alpha * 255 + 1e-04)), 
                    width = 2L, upper.case = TRUE)
    rval <- paste(rval, alpha, sep = "")
  }
  return(rval)
}

## ---- figProf, echo=FALSE, results="hide"--------------------------------
db = open_project("verbalAggression.db")
profile_plot(db, 1, 'mode', 'Gender')

## ----frq, echo=FALSE-----------------------------------------------------
matrix(fq,3,3)

## ---- fig1, echo=FALSE---------------------------------------------------
cloud(fq, panel.3d.cloud = panel.3dbars,
      xbase = 0.4, ybase = 0.4, zlim = c(0, max(fq)),
      scales = list(arrows = FALSE, just = "right"), xlab = "A", ylab = "B",
      col.facet =  "tan",
      screen = list(z = 40, x = -30))

## ---- fig2, echo=FALSE, fig.show='hold'----------------------------------
joint = prop.table(fq)

cloud(joint, panel.3d.cloud = panel.3dbars,
      xbase = 0.4, ybase = 0.4, zlim = c(0, 1),
      scales = list(arrows = FALSE, just = "right"), xlab = "A", ylab = "B",
      col.facet =  "skyblue", alpha.facet=.7,
      screen = list(z = 40, x = -30))

conditional = prop.table(fq,1)
co = rep(c('skyblue1','pink1','springgreen1'),3)

cloud(conditional, panel.3d.cloud = panel.3dbars,
      xbase = 0.4, ybase = 0.4, zlim = c(0, 1),
      scales = list(arrows = FALSE, just = "right"), xlab = "A", ylab = "B",
      col.facet =  co, alpha.facet=.7,
      screen = list(z = 40, x = -30))

## ---- fig3, echo=FALSE---------------------------------------------------
special = fq / den
j = 6-c(1,2,3,2,3,4,3,4,5)
pa=blues(5)
sp=pa[j]
cloud(special, panel.3d.cloud = panel.3dbars,
      xbase = 0.4, ybase = 0.4, zlim = c(0, 1),
      scales = list(arrows = FALSE, just = "right"), xlab = "A", ylab = "B",
      col.facet =  sp, alpha.facet=.7,
      screen = list(z = 40, x = -30))

## ---- fig4, echo=FALSE, fig.show='hold'----------------------------------
pa=reds(5)
hi = c(1,4,5,6,9)
sp[hi] = pa[j[hi]]

cloud(special, panel.3d.cloud = panel.3dbars,
      xbase = 0.4, ybase = 0.4, zlim = c(0, 1),
      scales = list(arrows = FALSE, just = "right"), xlab = "A", ylab = "B",
      col.facet =  sp, alpha.facet=.7,
      screen = list(z = 40, x = -30))

d = expand.grid(0:2,0:2)
plot(d, xlab = "A", ylab = "B",  xlim=c(0,2), ylim=c(0,2), asp=1, pch=15,
     cex=2.5, col=sp)
lines(0:1,1:0,col="gray")
lines(1:2,2:1,col="gray")
lines(c(0,2),c(2,0),col="gray")
lines(c(0,0,1,2,2), c(0,1,1,1,2), col=3, lwd=4)
