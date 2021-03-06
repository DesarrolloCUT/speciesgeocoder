#!/usr/bin/env Rscript
# Created by Daniele Silvestro on 29/05/2014
# Thanks to Martha Serrano-Serrano and Ruud Scharn
require(methods)

pkload <- function(x)
{
  if (!suppressMessages(require(x,character.only = TRUE)))
  {
    install.packages(x,dep=TRUE, repos='http://cran.us.r-project.org')
    if(!require(x,character.only = TRUE)) stop("Package not found")
  }
}
pkload("optparse")
####################################################################################
option_list <- list(

    make_option("--r", type="integer", default=100,
        help="Number of replicates [default %default]"),

    make_option("--c", type="integer", default=100,
        help="Number of random samples per replicate [default %default]"),

    make_option("--s", type="integer", default=60,
        help="Max run time for 1 stochastic map [default %default]."),

    make_option("--m", default="SYM",
        help="Model: 'ER','SYM','ARD' [default %default]."),

    make_option("--o", default="migration_plot",
        help="Name output file (pdf) [default %default]."),

    make_option("--t", default=0,
        help="if t>0 map trait [default %default]."),

    make_option("--d", default=F,type="logical",
        help="Verbose [default %default]."),

    make_option("--b", default=1,type="integer",
        help="Adjust bin size [default %default].")

    )

parser_object <- OptionParser(usage = "Usage: %prog [Working directory] [SpecieGeoCoder table] [Tree] Options]", 
option_list=option_list, description="")
opt <- parse_args(parser_object, args = commandArgs(trailingOnly = TRUE), positional_arguments=TRUE)

if (length(opt$args) < 3){
   cat("Error message: At least one of the input files is missing has not been specified.\n\n"); print_help(parser_object); quit(status=1)
}

wd=        opt$args[1]     #  "/Users/daniele/Desktop/map_migration_time/"
tbl_file=  opt$args[2]     #  "three_states.txt"   # "SGC_table.txt"  # "CAHighlands_SA.txt"
tree_file= opt$args[3]     #  "1birdtree.nex"
out_file=sprintf("%s.pdf", opt$options$o)
out_table=sprintf("%s.txt", opt$options$o)
out_file_rel=sprintf("%s_relative.txt", opt$options$o)
out_table_rel=sprintf("%s_relative.txt", opt$options$o)
n_rep=opt$options$r
map_model=opt$options$m
max_run_time=opt$options$s 
verbose=opt$options$d
no_char=opt$options$t
agegap=opt$options$b 

print(verbose)

if (verbose==T){
	library(ape)
	library(phytools)
	library(geiger)
	}else{
		pkload("ape")
		pkload("phytools")
		pkload("geiger")
	}


####################################################################################
setwd(wd)
tbl= read.table(tbl_file,header=T,stringsAsFactors=F) # , sep="\t"
area_name=colnames(tbl)
tree_obj <- read.nexus(tree_file)



#pdf(file=out_file,width=10, height=7)

#############################################################################################################
if (class(tree_obj)=="multiPhylo"){current_tree=tree_obj[[1]]
}else{current_tree=tree_obj}

branchtimes = branching.times(current_tree)
maxmilcatogories = ceiling(max(branchtimes)/agegap)
milgaps_mod=matrix(ncol=2, nrow=maxmilcatogories, 0)
colnames(milgaps_mod)=c("time","tot_brl")
milgaps_mod[,1]=1:maxmilcatogories*agegap

v=branchtimes
for(i in 1:length(milgaps_mod[,2])){
        s=milgaps_mod[i,1]        # time start
        e=milgaps_mod[i,1]-agegap # time end
        l1= length(v[v>s])*agegap + min(length(v[v>s]),1)*agegap
        l2= sum(v[v>e & v<s] -e)
	if (l1==0){l2 = l2*2} # root
        milgaps_mod[i,2]=l1+l2
}

#############################################################################################################

F_calc <- function(res2){
	M_ages=NULL 
	for (i in 1:100){		
		# draw rand uniform numbers
		M_age=runif(n=length(res2[,1]),max=res2$age0,min=res2$age1)
		h1=hist(M_age, breaks=bins,plot=F)
		h1$counts = h1$counts/milgaps_mod[,2] #Make h1$counts relative to the total branchlenths
		M_ages= rbind(M_ages,h1$counts)
	}
	x=as.data.frame(M_ages)   #q <- apply(x, 2, summary) #x=as.data.frame(M_ages)
	m <- apply(x, 2, min)     #m = q[2,] #m <- apply(x, 2, min)
	M <- apply(x, 2, max)     #M = q[5,] #M <- apply(x, 2, max)
	a <- apply(x, 2, mean)    #a = q[3,] #a <- apply(x, 2, mean)
	age=-h1$mids 
	return(as.data.frame(cbind(m,M,a,age)))		
}

G_calc <- function(res2){
	M_ages=NULL 
	for (i in 1:100){		
		# draw rand uniform numbers
		M_age=runif(n=length(res2[,1]),max=res2$age0,min=res2$age1)
		h1=hist(M_age, breaks=bins,plot=F)
		M_ages= rbind(M_ages,h1$counts)
	}
	x=as.data.frame(M_ages)   #q <- apply(x, 2, summary) #x=as.data.frame(M_ages)
	m <- apply(x, 2, min)     #m = q[2,] #m <- apply(x, 2, min)
	M <- apply(x, 2, max)     #M = q[5,] #M <- apply(x, 2, max)
	a <- apply(x, 2, mean)    #a = q[3,] #a <- apply(x, 2, mean)
	age=-h1$mids 
	return(as.data.frame(cbind(m,M,a,age)))		
}

F_plot <- function(L,title="Relative migrations through time",y_lim_M=10){
	plot(L$age,L$a,type = 'n', ylim = c(0, y_lim_M), xlim = c(min(L$age),0), ylab = 'Relative migration events', xlab = 'Ma',main=title)
	polygon(c(L$age, rev(L$age)), c(L$M, rev(L$m)), col = "#E5E4E2", border = NA)
	lines(y=L$a, x=L$age, col = "#504A4B", border = NULL)
}

G_plot <- function(L,title="Migrations through time",y_lim_MB=10){
	plot(L$age,L$a,type = 'n', ylim = c(0, y_lim_MB), xlim = c(min(L$age),0), ylab = 'migration events', xlab = 'Ma',main=title)
	polygon(c(L$age, rev(L$age)), c(L$M, rev(L$m)), col = "#E5E4E2", border = NA)
	lines(y=L$a, x=L$age, col = "#504A4B", border = NULL)
}

run_SM <- function(tree, trait,max_run){
	setTimeLimit(cpu = Inf, elapsed = max_run, transient = T)
	if (verbose==T){
		map=make.simmap(tree, trait[,1],pi="estimated",model=map_model)
		}else{map=suppressMessages(make.simmap(tree, trait[,1],pi="estimated",model=map_model))}
	return(map)
}

####################################################################################
RES=list()
effective_rep=0
y_lim_M=0
y_lim_MB=0

for (replicate in 1:n_rep){

	if (class(tree_obj)=="multiPhylo"){
		S=sample(length(tree_obj),1)
		current_tree=tree_obj[[S]]
	}else{
		current_tree=tree_obj
		S=1
	}
	
	cat("\nreplicate:", replicate, "tree:", S, "\t")
	#print(no_char)
	
	# resample widespread taxa (not allowed in SM) to randomly assign one area
	trait=data.frame()
	taxa=vector()
	j=1
	for (i in 1:length(tbl[,1]) ){
		if (no_char==0) {
			state = which(tbl[i,] == 1)-1 # 
			if (length(state)>0){
				trait[j,1]=state[sample(length(state),1)]
				taxa[j]=tbl[i,1]
				j=j+1	
		}
		}else{
			trait[i,1]=tbl[i,no_char+1]
			taxa[i]=tbl[i,1]
		}
	}


	rownames(trait)=taxa
	if (no_char==0){
		min_state=1
		no_potential_states=length(tbl[1,])-1
		}else{
			min_state=min(trait[,1])
			no_potential_states=max(trait[,1])
		}
	
	if (length(taxa)==0) {stop("\nAll taxa have empty ranges!\n")}
		
	# prune tree to match taxa in the table
	if (verbose==T){
		treetrait <- treedata(current_tree,trait)
		}else{ treetrait <- suppressWarnings(treedata(current_tree,trait)) }
	tree <- treetrait$phy
	trait <- treetrait$data
	if (length(trait)==0) {stop("\nNo matching taxa!\n")}
	
	branchtimes= branching.times(tree)
	bins=(0:maxmilcatogories)*agegap
	

	map=NULL
	if (verbose==F){
		sink(file=out_table,type = c("output", "message"))
		}else{cat(sprintf("\nfound %s matching taxa\n", length(trait)))}
	if (replicate==1){
		map=run_SM(tree, trait,Inf) #map=make.simmap(tree, trait[,1],pi="estimated",model=map_model)
		}else{
			tryCatch({ # stochastic mapping | stop after max_run_time
				map=run_SM(tree, trait,max_run_time)
			}
				,error = function(e) {NULL}
				)
		}
	if (verbose==F){sink(file=NULL)}
	setTimeLimit(cpu = Inf, elapsed = Inf, transient = T)
	
	if (!is.null(map)){
		# make table migration times
		res=data.frame()
		effective_rep=effective_rep+1
		j=1
		for (i in 1:length(map$maps)){ 
		    y=map$maps[[i]]
		    if (identical(names(y[1]), names(y[length(y)]))==F) {
		    	res[j,1]=i
			res[j,2]=branchtimes[[as.character(tree$edge[i,1])]] 
			if (tree$edge[i,][2]<=length(tree$tip.label)) { 
			      res[j,3]=0   # when branch finish in a tip (at present zero age)
			      } else { 
			      res[j,3]=branchtimes[[as.character(tree$edge[i,2])]]
			      } 
			res[j,4]=names(y[1])
			res[j,5]=names(y[length(y)])
			j = j+1
			} 
		}
		colnames(res)=c("edge", "age0", "age1","from","to")
	
		# calc mean, 95% CI relative migration events
		RES_temp=list()
		RES_temp[[1]]=F_calc(res)
		i=1
		y_lim_M=max(y_lim_M,max(RES_temp[[1]]$M))
		
		directions=as.vector("global")
		for (f in min_state:no_potential_states){
			for (t in min_state:no_potential_states) {
				if  (f != t) {
					i = i+1
					#cat("\n",f,t,replicate)
					res2=res[res$from==f & res$to==t,]
					RES_temp[[i]]=F_calc(res2)
					relmig=round(y_lim_M,digits = 4)
					if (no_char==0){
						directions[i]=sprintf("Relative migrations through time: %s -> %s (%s)",area_name[f+1],area_name[t+1],length(res2[,1]))
						}else{directions[i]=sprintf("Transition: %s -> %s (%s)",f,t,length(res2[,1]))}
				}
			}
		}
		## average results over SMs
		if (replicate==1){
			RES=RES_temp
			}else{
				for (i in 1:length(RES)){RES[[i]]=RES[[i]]+ RES_temp[[i]]}
			}	
		# calc mean, 95% CI migration events
		RES_temp=list()
		RES_temp[[1]]=G_calc(res)
		i=1
		y_lim_MB=max(y_lim_MB,max(RES_temp[[1]]$M))
		
		directionsB=as.vector("global")
		for (f in min_state:no_potential_states){
			for (t in min_state:no_potential_states) {
				if  (f != t) {
					i = i+1
					#cat("\n",f,t,replicate)
					res2=res[res$from==f & res$to==t,]
					RES_temp[[i]]=G_calc(res2)
					mig=y_lim_MB
					if (no_char==0){
						directionsB[i]=sprintf("Migrations through time: %s -> %s (%s)",area_name[f+1],area_name[t+1],length(res2[,1]))
						}else{directionsB[i]=sprintf("Transition: %s -> %s (%s)",f,t,length(res2[,1]))}
				}
			}
		}
		## average results over SMs
		if (replicate==1){
			RESB=RES_temp
			}else{
				for (i in 1:length(RESB)){RESB[[i]]=RESB[[i]]+ RES_temp[[i]]}
			}
	}else{cat("Time limit reached!")}
}

cat(sprintf("# Headers: min, max, and average (m, M, a) number of migration events through time (age) averaged over %s stochastic maps.\n", effective_rep),file=out_table)
cat(sprintf("# Headers: min, max, and average (m, M, a) relative number of migration events through time (age) averaged over %s stochastic maps.\n", effective_rep),file=out_table_rel)

# make plots/output table
pdf(file=out_file_rel,width=10, height=7)
for (i in 1:length(RES)){
	counts=RES[[i]]/effective_rep
	F_plot(counts,directions[i],y_lim_M)
	cat(sprintf("# Table %s (%s).\n",i,directions[i]), file=out_table_rel,append = T)
	row.names(counts)=paste0(row.names(counts), sep="_",rep(directions[i], length(counts[,1])))
	if (i==1){
		suppressWarnings(write.table(counts, file=out_table_rel,append = T,sep="\t",row.names=T,col.names=T))
		}else{suppressWarnings(write.table(counts, file=out_table_rel,append = T,sep="\t",row.names=T,col.names=F))}
	
}
suppressMessages(dev.off())

pdf(file=out_file,width=10, height=7)
for (i in 1:length(RESB)){
	counts=RESB[[i]]/effective_rep
	G_plot(counts,directionsB[i],y_lim_MB)
	cat(sprintf("# Table %s (%s).\n",i,directionsB[i]), file=out_table,append = T)
	row.names(counts)=paste0(row.names(counts), sep="_",rep(directionsB[i], length(counts[,1])))
	if (i==1){
		suppressWarnings(write.table(counts, file=out_table,append = T,sep="\t",row.names=T,col.names=T))
		}else{suppressWarnings(write.table(counts, file=out_table,append = T,sep="\t",row.names=T,col.names=F))}
	
}

suppressMessages(dev.off())










