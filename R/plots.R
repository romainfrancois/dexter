
##############################
my_layout <- function(npic, nr, nc) {
  if(npic==1) nr=nc=1
  nc = min(nc, 3)
  nc = min(nc, npic)
  nw = npic %/% nc + npic %% nc
  nr = min(nr, 3)
  nr = min(nr, nw)
  list(nr=nr, nc=nc)
}


# format string with named arguments
# @param f format string with named arguments prefixed by a dollar sign, formatting can be done with postfixing with : 
# @param arglist list with named arguments to interpolate in the format string. Use only alphanumerical characters in the names
# @return 
# formatted string
# @examples
# fstr('$bla, $b',list(bla='some string'))
# fstr('$bla:.1f, $b',list(bla=3.2423))
#
fstr = function(f, arglist)
{
  if(length(arglist)==0 || is.null(f) || f == '') return(f)
  f = gsub(paste0('\\$(?!(\\$|',paste0('(',names(arglist),')',collapse='|'),'))'),'$$', f, perl = TRUE)
  f = gsub('\\:(?!(\\.|\\:|(\\+\\.)))','::', f, perl=TRUE)
  rprintf(f,arglist)
}

qcolors = function(n, pal='Set1')
{
  npal = brewer.pal.info[rownames(brewer.pal.info) == pal,'maxcolors']
  step = ceiling(n/npal)
  ord = unlist(lapply(1:step, function(x) seq.int(x, by=step,length.out=npal)))
  ord = ord[ord<=n]
  colorRampPalette(brewer.pal(max(min(npal,n),3), pal))(n)[ord]
}


draw_curtains = function(qnt)
{
  if(!is.null(qnt))
  {
    usr = graphics::par('usr')
    graphics::rect(usr[1], usr[3], qnt[1], usr[2], col="#EEEEEE", border=NA,xpd=FALSE,lwd=0)
    graphics::rect(qnt[2], usr[3], usr[2], usr[4], col="#EEEEEE", border=NA,xpd=FALSE,lwd=0)
    # rect will sometimes cover the axis (redrawing the axis would probably solve this too)
    abline(h=usr[3])
    abline(v=usr[1])
  }
}



###################################################
#' Distractor plot
#'
#' Produce a diagnostic distractor plot for an item
#'
#'
#' @param dataSrc Data source: a dexter project db handle or a data.frame with columns: person_id, item_id, response, item_score
#' and optionally booklet_id
#' @param item The ID of the item to plot. A separate plot will be produced
#' for each booklet that contains the item, or an error message if the item ID
#' is not known. Each plot contains a non-parametric regression of each possible
#' response on the total score.
#' @param predicate An optional expression to subset data, if NULL all data is used
#' @param legend logical, whether to include the legend. default is TRUE
#' @param curtains 100*the tail probability of the sum scores to be shaded. Default is 10.
#' Set to 0 to have no curtains shown at all.
#' @param ... further arguments to plot.
#' @details 
#' Customization of title and subtitle can be done by using the arguments main and sub. 
#' These arguments can contain references to the variables item_id, booklet_id, item_position(only if dataSrc is a dexter db),
#' pvalue, rit and rir. References are made by prefixing these variables with a dollar sign. Variable names may be postfixed 
#' with a sprintf style format string, e.g. 
#' \code{distractor_plot(db, main='item: $item_id', sub='Item rest correlation: $rir:.2f')}
#' 
distractor_plot <- function(dataSrc, item, predicate=NULL, legend=TRUE, curtains=10, ...){  
  
  qtpredicate = eval(substitute(quote(predicate)))
  
  if(is.null(qtpredicate) && inherits(dataSrc,'DBIConnection'))
  {
    # cheat a little to make things faster
    qtpredicate = quote(booklet_id %in% booklets)
    env = new.env()
    env$booklets = dbGetQuery(dataSrc,'SELECT booklet_id FROM dxBooklet_design WHERE item_id=:item;',tibble(item=item))$booklet_id
  } else
  {
    env = caller_env()
  }
  
  # this uses the custom filter method on dx_resp_data objects
  respData = get_resp_data(dataSrc, qtpredicate = qtpredicate, extra_columns='response', env=env, summarised=FALSE) %>%
    filter(.data$item_id == item, .recompute_sumscores = FALSE )
  

  if (nrow(respData$design) == 0) stop(paste("Item", item, "not found in dataSrc."))
  
  default.args = list(sub = "Pval: $pvalue:.2f, Rit: $rit:.3f, Rir: $rir:.3f", 
                      xlab = "Sum score", ylab = "Proportion", cex.sub = 0.8, xaxs="i", bty="l")
  
  default.args$main = ifelse('item_position' %in% colnames(respData$design),
                             '$item_id, position $item_position in booklet $booklet_id',
                             '$item_id in booklet $booklet_id')
  
  user.args = list(...)
  
  if(any(c('nr','nc') %in% names(user.args)))
  {
    warning('Arguments `nr` and `nc` have been deprecated and are ignored, you can achieve the desired ',
               'result by using par(mfrow=c(nr,nc)).')
    user.args[['nc']] = NULL
    user.args[['nr']] = NULL
  }

  rsp_counts = respData$x %>%
    group_by(.data$booklet_id, .data$response, .data$item_score, .data$sumScore) %>%
    summarise(n = n()) %>% 
    ungroup() 

  rsp_colors = rsp_counts %>%
    group_by(.data$response) %>%
    summarise(n = sum(.data$n)) %>%
    ungroup() %>%
    arrange(desc(.data$n), .data$response) 
  # cannot make this a list since a response can be an empty string
  rsp_colors = rsp_colors %>% add_column(color = qcolors(nrow(rsp_colors)))
  
  max_score = max(rsp_counts$item_score)
  # statistics by booklet
  # join with design gets item position
  stats = respData$x %>%
    group_by(.data$booklet_id) %>% 
    summarise(pvalue = mean(.data$item_score)/max_score, 
              rit = cor(.data$item_score, .data$sumScore), 
              rir = cor(.data$item_score, .data$sumScore - .data$item_score),
              rng = max(.data$sumScore) - min(.data$sumScore),
              n=n()) %>%
    ungroup() %>%
    inner_join(respData$design, by='booklet_id') %>%
    arrange(.data$booklet_id)
    

  rsp_counts = split(rsp_counts, rsp_counts$booklet_id)

  # rng>1 is bugfix, density needs at least two distinct values
  stats %>%
    filter( .data$rng > 0 ) %>%
    rowwise() %>%
    do({
      st = as.list(.)
  
      y = rsp_counts[[as.character(st$booklet_id)]]
      
      plot.args = merge_arglists(user.args, 
                                  default=default.args,
                                  override=list(x = c(0,max(y$sumScore)), y = c(0,1), type="n"))
      
      plot.args$main = fstr(plot.args$main, st)
      plot.args$sub = fstr(plot.args$sub, st)

      bkl_scores = y %>% 
        group_by(.data$sumScore) %>% 
        summarise(n = sum(.data$n)) %>%
        ungroup() %>%
        arrange(.data$sumScore)
      
      qua = curtains/200
      qnt=NULL
      if(qua>0 && qua<.5) {
        qnt = quantile(rep(as.integer(bkl_scores$sumScore), bkl_scores$n), c(qua,1-qua))
      }

      do.call(plot, plot.args)
      draw_curtains(qnt)
      
      dAll = density(bkl_scores$sumScore, n = 51, weights = bkl_scores$n/sum(bkl_scores$n))
      N = sum(bkl_scores$n)
      
      # this generates the legend and has the  side effect of drawing the lines in the plot
      # filter(n() > 1)  is bugfix, density needs at least two values
      lgnd = y %>% 
        group_by(.data$response)  %>% 
        filter(n() > 1) %>%
        do({
          k = rsp_colors[rsp_colors$response == .$response[1],]$color
    
          dxi = density(.$sumScore, weights = .$n/sum(.$n),   n = 51,
                          bw = dAll$bw, from = min(dAll$x), to = max(dAll$x))
          yy = dxi$y/dAll$y * sum(.$n)/N
          graphics::lines(dAll$x, yy, co = k, lw = 2)
          tibble(col = k, resp = paste0(.$response[1]," (", .$item_score[1], ")"))
     
        })
      
      if(legend && length(lgnd$resp)>0)
      {
        graphics::legend("topleft", legend = as.character(lgnd$resp), 
                         lty = 1, col = lgnd$col, cex = 0.8,lwd=2, box.lty = 0)
      }
      tibble()
    })

  invisible(NULL)
}

#' Profile plot
#'
#'
#' @param dataSrc Data source: a dexter project db handle or a data.frame with columns: 
#' person_id, item_id, item_score and the item_property and the covariate of interest.
#' @param item_property The name of the item property defining the domains. 
#' The item property should have exactly two distinct values in your data
#' @param covariate name of the person property/covariate used to create the groups. 
#' There will be one line for each distinct value.
#' @param predicate An optional expression to filter data, if NULL all data is used
#' @param model "IM" (default) or "RM" where "IM" is the interaction model and 
#' "RM" the Rasch model. The interaction model is the default as it fits 
#' the data better or at least as good as the Rasch model.
#' @param x Which value of the item_property to draw on the x axis, if NULL, one is chosen automatically
#' @param ... further arguments to plot, many have useful defaults
#' @return Nothing interesting
#' @details 
#' Profile plots can be used to investigate whether two (or more) groups of respondents 
#' attain the same test score in the same way. The user must provide a  
#' (meaningful) classification of the items in two non-overlapping subsets such that 
#' the test score is the sum of the scores on the subsets. 
#' The plot shows the probabilities to obtain 
#' any combinations of subset scores with thin gray lines indicating the combinations 
#' that give the same test score. The thick lines connect the most likely 
#' combination for each test score in each group.
#' When applied to educational test data, the plots can be used to detect differences in the 
#' relative difficulty of (sets of) items for respondents that belong to different 
#' groups and are matched on the test score. This provides a content-driven way to 
#' investigate differential item functioning. 
#'
#' @examples
#' \dontrun{
#' db = start_new_project(verbAggrRules, "verbAggression.db", covariates=list(gender="<unknown>"))
#' add_booklet(db, verbAggrData, "agg")
#' add_item_properties(db, verbAggrProperties)
#' profile_plot(db, item_property='mode', covariate='gender')
#' 
#' close_project(db)
#' }
#' 
#' 
profile_plot <- function(dataSrc, item_property, covariate, predicate = NULL, model = "IM", x = NULL, ...) 
{
  if (model != "IM") model="RM"
  user.args = list(...)
  if(!inherits(dataSrc,'data.frame'))
  {
    item_property = tolower(item_property)
    covariate = tolower(covariate)
  }
  
  qtpredicate = eval(substitute(quote(predicate)))
  env = caller_env()
  respData = get_resp_data(dataSrc, qtpredicate, extra_columns = covariate, 
                           extra_design_columns=item_property, env = env) 
  
  # make sure we have an intersection
  if(length(unique(respData$design$booklet_id)) > 1)
  {
    common_items = Reduce(intersect, split(respData$design$item_id, respData$design$booklet_id))
    if(length(common_items) == 0) stop('The intersection of the items across booklets is empty')
    
    # we do it this convoluted way because we would loose the extra design columns otherwise
    respData$design = respData$design %>%
      distinct(.data$item_id, .keep_all=TRUE) %>%
      semi_join(tibble(item_id = common_items), by = 'item_id') %>%
      mutate(booklet_id='b')
    
    respData$x = respData$x %>%
      semi_join(respData$design, by='item_id') %>%
      group_by(.data$person_id) %>%
      mutate(sumScore = sum(.data$item_score), booklet_id = 'b') %>%
      ungroup()
  }
  
  if(nrow(respData$x) == 0) stop('no data to analyse')
  
  props = unique(respData$design[[item_property]])
  if(length(props) != 2)
    stop('this function needs an item_property with 2 unique values in your data')
  # order props to get the x and y axis right
  if(!is.null(x)) if(x %in% props) props = c(x, props[props!=x])
  
  
  # fit model
  models = by(respData$x, respData$x[[covariate]], function(rsp)
  {
    # statistics per item-score combination
    # if the score 0 does not occur for an item, it is added with sufI=0 and sufC=0
    
    ssIS = rsp %>%
      group_by(.data$item_id, .data$item_score) %>%
      summarise(sufI=n(), sufC_ = sum(.data$item_score * .data$sumScore)) %>%
      ungroup() %>%
      full_join(tibble(item_id=respData$design$item_id, item_score=0L), by = c("item_id","item_score")) %>%
      mutate(sufI = coalesce(.data$sufI, 0L), sufC_ = coalesce(.data$sufC_,0L)) %>%
      arrange(.data$item_id, .data$item_score)
    
    # statistics per item
    ssI = ssIS %>%
      group_by(.data$item_id) %>%
      summarise(nCat = n(), sufC = sum(.data$sufC_), item_maxscore = max(.data$item_score)) %>%
      ungroup() %>%
      mutate(first = cumsum(.data$nCat) - .data$nCat + 1L, last = cumsum(.data$nCat))  %>%
      arrange(.data$item_id)
    
    
    # theoretical max score on the test
    maxTestScore = sum(ssI$item_maxscore)
    
    # scoretab from 0:maxscore (including unachieved and impossible scores)
    scoretab = rsp %>%
      distinct(.data$person_id, .keep_all=TRUE) %>%
      group_by(.data$sumScore) %>%
      summarise(N=n()) %>%
      ungroup() %>%
      right_join(tibble(sumScore=0L:maxTestScore), by="sumScore") %>%
      mutate(N=coalesce(.data$N, 0L)) %>%
      arrange(.data$sumScore)
    
    
    list(est = EstIM(first=ssI$first, last=ssI$last, nCat=ssI$nCat, a=ssIS$item_score, 
                     sufI=ssIS$sufI, sufC=ssI$sufC, scoretab = scoretab$N),
         inputs = list(ssI = ssI, ssIS = ssIS))
  })
  
  
  tt = lapply(models, function(x)
  {
    A = c(1:nrow(x$inputs$ssI))[x$inputs$ssI$item_id %in% respData$design[respData$design[[item_property]]==props[1],]$item_id]
    B = c(1:nrow(x$inputs$ssI))[x$inputs$ssI$item_id %in% respData$design[respData$design[[item_property]]==props[2],]$item_id]
    SSTable(x, AB = list(A,B), model = model)
  })
  
  
  maxA = max(sapply(tt,function(x){ nrow(x$tbl)} ))-1
  maxB = max(sapply(tt,function(x){ ncol(x$tbl)} ))-1
  
  sg = data.frame(k=0:(maxA+maxB))
  
  default.args = list(asp=1, main="Profile plot", xlab=props[1], 
                      ylab=props[2],xlim=c(0,maxA),ylim=c(0,maxB),bty='l',xaxs="i")
  do.call(plot, 
          merge_arglists(user.args, 
                         default=default.args,
                         override=list(x=c(0,maxA), y=c(0,maxB),type="n")))
  
  # The timolines
  k = maxA + maxB
  sg$y0 = pmin(maxB,sg$k)
  sg$x0 = sg$k - sg$y0
  sg$x1 = pmin(maxA,sg$k)
  sg$y1 = sg$k - sg$x1
  graphics::segments(sg$x0, sg$y0, sg$x1, sg$y1, col="gray")
  
  graphics::text(0:maxA,0,0:maxA,cex=.6,col="lightgray")
  graphics::text(maxA,1:maxB,(maxA+1:maxB),cex=.6,col="lightgray")
  
  colors = qcolors(length(tt))
  
  for (i in seq_along(tt)) {
    ta = tt[[i]]$tbl
    y = tibble(
      value=as.vector(ta),
      Var1=as.integer(gl(nrow(ta),1,nrow(ta)*ncol(ta))),
      Var2=as.integer(gl(ncol(ta),nrow(ta),nrow(ta)*ncol(ta))),
      v = as.integer(gl(nrow(ta),1,nrow(ta)*ncol(ta))) + 
        as.integer(gl(ncol(ta),nrow(ta),nrow(ta)*ncol(ta)))
    )
    stp = y %>% 
      group_by(.data$v) %>%
      do(.[which.max(.$value),]-1)
    graphics::lines(stp$Var1, stp$Var2, col=colors[i], lw=2)
  }
  
  graphics::legend(x=0,y=maxB, 
                   legend=names(tt), 
                   lty=1, col=colors,
                   cex=.7, 
                   box.lty=0,
                   bg='white')
}

